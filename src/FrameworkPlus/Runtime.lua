local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Settings = require(script.Parent:WaitForChild("Settings"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Utils = require(script.Parent:WaitForChild("Utils"))

local Runtime = {}

local function getSystemsFolder(): Folder
	local f = script.Parent:FindFirstChild("Systems")
	assert(f and f:IsA("Folder"), Settings.PrintPrefix .. "Missing FrameworkPlus.Systems folder")
	return f
end

local function getRemotesFolder(): Folder
	local name = Settings.RemotesFolderName
	local f = script.Parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = script.Parent
	return f
end

local function ensureRequestTokenRemote(): RemoteFunction
	local remotes = getRemotesFolder()
	local n = Settings.RequestTokenRemoteName
	local rf = remotes:FindFirstChild(n)
	if rf and rf:IsA("RemoteFunction") then
		return rf
	end
	rf = Instance.new("RemoteFunction")
	rf.Name = n
	rf.Parent = remotes
	return rf
end

local function resolveSystem(systemName: string): (ModuleScript?, any)
	local sys = getSystemsFolder():FindFirstChild(systemName)
	if not sys or not sys:IsA("ModuleScript") then
		return nil, ("System '%s' not found"):format(systemName)
	end

	local cfgMod = sys:FindFirstChild("Config")
	if not cfgMod or not cfgMod:IsA("ModuleScript") then
		return nil, ("System '%s' missing Config.lua"):format(systemName)
	end

	local ok, cfg = pcall(require, cfgMod)
	if not ok then
		return nil, ("System '%s' Config require failed: %s"):format(systemName, tostring(cfg))
	end
	if type(cfg) ~= "table" then
		return nil, ("System '%s' Config must return a table"):format(systemName)
	end

	return sys, cfg
end

local function mintToken(systemName: string): string
	return ("FP|%s|%s"):format(systemName, HttpService:GenerateGUID(false))
end

local runningSystems: {[string]: boolean} = {}

function Runtime.IsSystemRunning(systemName: string): boolean
	return runningSystems[systemName] == true
end

function Runtime.ServerStart(): (boolean, string?)
	local okS, errS = Guard.serverOnly()
	if not okS then return false, errS end

	local rf = ensureRequestTokenRemote()

	rf.OnServerInvoke = function(_plr, systemName: any, callerTemplate: any)
		if type(systemName) ~= "string" or systemName == "" then
			return false, "Invalid systemName"
		end
		if type(callerTemplate) ~= "string" or callerTemplate == "" then
			return false, "Invalid callerTemplate"
		end

		local allowOk, allowErr = Guard.isAllowedCallerTemplate(callerTemplate)
		if not allowOk then
			return false, allowErr
		end

		local sys, cfgOrErr = resolveSystem(systemName)
		if not sys then
			return false, cfgOrErr
		end

		local cfg = cfgOrErr
		if cfg.RunContext ~= "Client" then
			return false, ("System '%s' must be Client"):format(systemName)
		end

		if Settings.RequireHandshake then
			local expected = cfg.HandshakePath
			if expected ~= callerTemplate then
				return false, ("Handshake blocked. Expected '%s' got '%s'"):format(tostring(expected), tostring(callerTemplate))
			end
		end

		return true, mintToken(systemName)
	end

	print(Settings.PrintPrefix .. "ServerStart OK")
	return true, nil
end

function Runtime.ClientStartSystem(callerScript: Instance, systemName: string, opts: any?): (boolean, string?)
	local okC, errC = Guard.clientOnly()
	if not okC then return false, errC end

	local okCaller, errCaller = Guard.requireCallerScript(callerScript)
	if not okCaller then return false, errCaller end

	if type(systemName) ~= "string" or systemName == "" then
		return false, Settings.PrintPrefix .. "Invalid systemName"
	end

	if runningSystems[systemName] then
		return true, nil
	end

	local sys, cfgOrErr = resolveSystem(systemName)
	if not sys then
		return false, cfgOrErr
	end

	local cfg = cfgOrErr
	if cfg.RunContext ~= "Client" then
		return false, ("System '%s' is not Client"):format(systemName)
	end

	local rf = ensureRequestTokenRemote()

	local callerTemplate = Utils.templateCallerPathFromScript(callerScript)

	local attempts = Settings.TokenMaxAttempts
	local delay = Settings.TokenRetryDelay

	local success = false
	local tokenOrErr = ""

	for _ = 1, attempts do
		local okInvoke, a, b = pcall(function()
			return rf:InvokeServer(systemName, callerTemplate)
		end)

		if okInvoke then
			success = a
			tokenOrErr = b
			if success then
				break
			end
		else
			tokenOrErr = tostring(a)
		end

		task.wait(delay)
	end

	if not success then
		return false, tostring(tokenOrErr)
	end

	local token = tokenOrErr

	local systemTable = require(sys)
	if type(systemTable) ~= "table" or type(systemTable.Start) ~= "function" then
		return false, ("System '%s' missing Start()"):format(systemName)
	end

	local player = (opts and opts.Player) or game:GetService("Players").LocalPlayer
	local camera = (opts and opts.Camera) or workspace.CurrentCamera

	local startedOk, startedRes = pcall(function()
		return systemTable.Start(player, camera, token)
	end)

	if not startedOk then
		return false, ("System '%s' Start error: %s"):format(systemName, tostring(startedRes))
	end

	if startedRes == false then
		return false, ("System '%s' Start returned false"):format(systemName)
	end

	runningSystems[systemName] = true
	return true, nil
end

function Runtime.ClientStopSystem(systemName: string): (boolean, string?)
	local okC, errC = Guard.clientOnly()
	if not okC then return false, errC end

	local sys, cfgOrErr = resolveSystem(systemName)
	if not sys then
		return false, cfgOrErr
	end

	local systemTable = require(sys)
	if type(systemTable) == "table" and type(systemTable.Stop) == "function" then
		pcall(systemTable.Stop)
	end

	runningSystems[systemName] = nil
	return true, nil
end

return Runtime