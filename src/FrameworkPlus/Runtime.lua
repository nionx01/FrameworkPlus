local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Settings = require(script.Parent:WaitForChild("Settings"))
local Utils = require(script.Parent:WaitForChild("Utils"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local Runtime = {}

local REMOTES_FOLDER_NAME = "Remotes"
local REQUEST_TOKEN_NAME = "FrameworkPlus_RequestToken"

local runningSystems: {[string]: any} = {}

local function getFrameworkRoot(): Instance
	return script.Parent
end

local function getSystemsFolder(): Folder
	local root = getFrameworkRoot()
	local f = root:FindFirstChild("Systems")
	assert(f and f:IsA("Folder"), "[FrameworkPlus] Missing Folder: Systems")
	return f
end

local function getRemotesFolderServer(): Folder
	local root = getFrameworkRoot()
	local remotes = root:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotes and remotes:IsA("Folder") then
		return remotes
	end
	remotes = Instance.new("Folder")
	remotes.Name = REMOTES_FOLDER_NAME
	remotes.Parent = root
	return remotes
end

local function getRemotesFolderClient(): Folder?
	local root = getFrameworkRoot()
	local remotes = root:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotes and remotes:IsA("Folder") then
		return remotes
	end
	return nil
end

local function ensureRemoteFunctionServer(): RemoteFunction
	local remotes = getRemotesFolderServer()
	local rf = remotes:FindFirstChild(REQUEST_TOKEN_NAME)
	if rf and rf:IsA("RemoteFunction") then
		return rf
	end
	rf = Instance.new("RemoteFunction")
	rf.Name = REQUEST_TOKEN_NAME
	rf.Parent = remotes
	return rf
end

local function getRemoteFunctionClient(): RemoteFunction?
	local remotes = getRemotesFolderClient()
	if not remotes then return nil end
	local rf = remotes:FindFirstChild(REQUEST_TOKEN_NAME)
	if rf and rf:IsA("RemoteFunction") then
		return rf
	end
	return nil
end

local function resolveSystem(systemName: string): (ModuleScript?, table | string)
	local systems = getSystemsFolder()
	local sys = systems:FindFirstChild(systemName)
	if not sys or not sys:IsA("Folder") then
		return nil, ("System '%s' not found (expected Folder)"):format(systemName)
	end

	local initMod = sys:FindFirstChild("init")
	if not initMod or not initMod:IsA("ModuleScript") then
		return nil, ("System '%s' missing ModuleScript 'init'"):format(systemName)
	end

	local cfgMod = sys:FindFirstChild("Config")
	if not cfgMod or not cfgMod:IsA("ModuleScript") then
		return nil, ("System '%s' missing ModuleScript 'Config'"):format(systemName)
	end

	local ok, cfg = Utils.safeRequire(cfgMod)
	if not ok then
		return nil, ("System '%s' Config require failed: %s"):format(systemName, tostring(cfg))
	end
	if type(cfg) ~= "table" then
		return nil, ("System '%s' Config must return a table"):format(systemName)
	end

	return initMod, cfg
end

local function mintToken(systemName: string): string
	return ("FP|%s|%s"):format(systemName, HttpService:GenerateGUID(false))
end

function Runtime.ServerStart(): boolean
	assert(RunService:IsServer(), "[FrameworkPlus] Runtime.ServerStart must run on server")

	local rf = ensureRemoteFunctionServer()

	rf.OnServerInvoke = function(plr: Player, systemName: any, callerFullName: any)
		if type(systemName) ~= "string" or systemName == "" then
			return false, "Invalid systemName"
		end
		if Settings.RequireHandshake and (type(callerFullName) ~= "string" or callerFullName == "") then
			return false, "Handshake required but callerFullName missing"
		end

		local initMod, cfgOrErr = resolveSystem(systemName)
		if not initMod then
			return false, cfgOrErr
		end
		local cfg = cfgOrErr :: table

		if cfg.RunContext ~= "Client" then
			return false, ("System '%s' RunContext must be 'Client'"):format(systemName)
		end

		if Settings.RequireHandshake then
			local callerTemplate = Utils.runtimeToTemplatePath(callerFullName)
			local expected = tostring(cfg.HandshakePath)
			if callerTemplate ~= expected then
				return false, ("Handshake blocked. Expected '%s' got '%s'"):format(expected, callerTemplate)
			end
		end

		return true, mintToken(systemName)
	end

	Utils.log("ServerStart OK", nil, true)
	return true
end


function Runtime.GetCallerPathTemplate(callerScript: Instance): string
	return Utils.runtimeToTemplatePath(callerScript:GetFullName())
end

function Runtime.ClientStartSystem(systemName: string, payload: any?): (boolean, string?)
	assert(RunService:IsClient(), "[FrameworkPlus] Runtime.ClientStartSystem must run on client")

	payload = payload or {}
	local player: Player = payload.Player or Players.LocalPlayer
	local camera: Camera = payload.Camera or workspace.CurrentCamera

	local callerFullName: string? = nil
	if Settings.RequireHandshake then
		local callerScript: Instance? = payload.CallerScript
		if callerScript == nil then
			return false, "Settings.RequireHandshake=true, so you must pass { CallerScript = script }"
		end
		callerFullName = callerScript:GetFullName()
	end

	if runningSystems[systemName] then
		return true
	end

	local initMod, cfgOrErr = resolveSystem(systemName)
	if not initMod then
		return false, cfgOrErr
	end
	local cfg = cfgOrErr :: table

	local okLocal, errLocal = Guard.clientPrecheck(cfg)
	if not okLocal then
		return false, errLocal
	end

	local rf = getRemoteFunctionClient()
	if not rf then
		return false, "RemoteFunction missing. Did the server call FrameworkPlus.ServerStart()?"
	end

	local attempts = 0
	local success: boolean = false
	local tokenOrErr: any = nil

	while attempts < Settings.TokenMaxAttempts do
		attempts += 1
		local okInvoke, s, t = pcall(function()
			return rf:InvokeServer(systemName, callerFullName)
		end)

		if okInvoke and s == true and type(t) == "string" then
			success = true
			tokenOrErr = t
			break
		end

		-- keep last error
		if okInvoke and s == false then
			tokenOrErr = t
		elseif not okInvoke then
			tokenOrErr = s
		end

		task.wait(Settings.TokenRetryDelay)
	end

	if not success then
		return false, tostring(tokenOrErr)
	end

	local token: string = tokenOrErr

	local okReq, sysModuleOrErr = Utils.safeRequire(initMod)
	if not okReq then
		return false, ("System '%s' init require failed: %s"):format(systemName, tostring(sysModuleOrErr))
	end
	local sysModule = sysModuleOrErr

	if type(sysModule) ~= "table" or type(sysModule.Start) ~= "function" then
		return false, ("System '%s' init must return table with Start(player,camera,token)"):format(systemName)
	end

	local okStart, startRes = pcall(function()
		return sysModule.Start(player, camera, token)
	end)

	if not okStart then
		return false, ("System '%s' Start error: %s"):format(systemName, tostring(startRes))
	end
	if startRes == false then
		return false, ("System '%s' Start returned false"):format(systemName)
	end

	runningSystems[systemName] = sysModule
	Utils.log(("Loaded (%d/%d): %s"):format(1, 1, systemName), cfg, false)

	return true
end

function Runtime.ClientStopSystem(systemName: string): boolean
	local sys = runningSystems[systemName]
	if not sys then return true end
	if type(sys.Stop) == "function" then
		pcall(sys.Stop)
	end
	runningSystems[systemName] = nil
	return true
end

return Runtime