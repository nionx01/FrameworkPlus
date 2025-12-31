local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Settings = require(script.Parent:WaitForChild("Settings"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Utils = require(script.Parent:WaitForChild("Utils"))

local Runtime = {}
local runningSystems: {[string]: boolean} = {}

-- Client-side stats (server cannot know which client systems started successfully)
local startedCount = 0
local failedCount = 0

-- Internal state (prevents double-binding)
local _serverStarted = false
local _remoteBound = false

local REMOTES_FOLDER_NAME = "Remotes"
local REQUEST_TOKEN_REMOTE_NAME = "FrameworkPlus_RequestToken"

-- =========================================================
-- Error helpers
-- =========================================================

local function withTrace(msg: string): string
	if not Settings.ErrorTracebacks then
		return msg
	end
	return msg .. "\n" .. debug.traceback("", 2)
end

local function fail(msg: string): (boolean, string)
	return false, withTrace(msg)
end

local function debugPrint(...)
	if Settings.Debug then
		print("[FrameworkPlus:Debug]", ...)
	end
end

-- =========================================================
-- SYSTEM COUNT / STATUS
-- =========================================================

local function getSystemsFolder(): Folder
	local f = script.Parent:FindFirstChild("Systems")
	assert(f and f:IsA("Folder"), "[FrameworkPlus] Missing FrameworkPlus.Systems folder")
	return f
end

local function countSystemsTotal(): number
	local folder = getSystemsFolder()
	local total = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			total += 1
		end
	end
	return total
end

local function countRunning(): number
	local n = 0
	for _, v in pairs(runningSystems) do
		if v == true then
			n += 1
		end
	end
	return n
end

function Runtime.GetStatus()
	local total = countSystemsTotal()
	local running = countRunning()
	return {
		Total = total,
		Running = running,
		Started = startedCount,
		Failed = failedCount,
	}
end

local function statusLine(side: "Server" | "Client"): string
	local s = Runtime.GetStatus()
	return ("%s Systems: %d total | Running: %d | Started: %d | Failed: %d")
		:format(side, s.Total, s.Running, s.Started, s.Failed)
end

local function shouldPrintStatus(side: "Server" | "Client"): boolean
	if Settings.PrintStatus == false then
		return false
	end
	if side == "Server" and Settings.PrintServerStatus == false then
		return false
	end
	if side == "Client" and Settings.PrintClientStatus == false then
		return false
	end
	return true
end

local function printStatus(side: "Server" | "Client")
	if not shouldPrintStatus(side) then
		return
	end
	print("[FrameworkPlus] " .. statusLine(side))
end

-- =========================================================
-- REMOTES
-- =========================================================

local function getRemotesFolder(): Folder?
	local f = script.Parent:FindFirstChild(REMOTES_FOLDER_NAME)
	if f and f:IsA("Folder") then
		return f
	end
	if not Settings.AutoCreateRemotes then
		return nil
	end
	f = Instance.new("Folder")
	f.Name = REMOTES_FOLDER_NAME
	f.Parent = script.Parent
	return f
end

local function ensureRequestTokenRemote(): RemoteFunction?
	local remotes = getRemotesFolder()
	if not remotes then
		return nil
	end
	local rf = remotes:FindFirstChild(REQUEST_TOKEN_REMOTE_NAME)
	if rf and rf:IsA("RemoteFunction") then
		return rf
	end
	if not Settings.AutoCreateRemotes then
		return nil
	end
	rf = Instance.new("RemoteFunction")
	rf.Name = REQUEST_TOKEN_REMOTE_NAME
	rf.Parent = remotes
	return rf
end

-- =========================================================
-- SYSTEM RESOLVE
-- =========================================================

local function resolveSystem(systemName: string): (ModuleScript?, any)
	local sys = getSystemsFolder():FindFirstChild(systemName)
	if not sys or not sys:IsA("ModuleScript") then
		return nil, ("System '%s' not found"):format(systemName)
	end

	local cfgMod = sys:FindFirstChild("Config")
	if not cfgMod or not cfgMod:IsA("ModuleScript") then
		return nil, ("System '%s' missing Config module"):format(systemName)
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

-- =========================================================
-- PUBLIC
-- =========================================================

function Runtime.IsSystemRunning(systemName: string): boolean
	return runningSystems[systemName] == true
end

-- =========================================================
-- SERVER: token service / handshake gate
-- =========================================================

local function bindServerRemote()
	if _remoteBound then
		return true
	end

	local rf = ensureRequestTokenRemote()
	if not rf then
		return false
	end

	rf.OnServerInvoke = function(_plr, systemNameAny: any, callerTemplateAny: any)
		if type(systemNameAny) ~= "string" or systemNameAny == "" then
			return false, "Invalid systemName"
		end
		if type(callerTemplateAny) ~= "string" or callerTemplateAny == "" then
			return false, "Invalid callerTemplate"
		end

		local systemName = systemNameAny :: string
		local callerTemplate = callerTemplateAny :: string

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

		if Settings.RequireHandshake and Settings.RequireHandshakePath then
			local expected = cfg.HandshakePath
			if type(expected) ~= "string" or expected == "" then
				return false, ("System '%s' has invalid HandshakePath"):format(systemName)
			end

			if not Utils.pathsMatch(expected, callerTemplate) then
				return false, ("Handshake blocked. Expected '%s' got '%s'"):format(tostring(expected), tostring(callerTemplate))
			end
		end

		return true, mintToken(systemName)
	end

	_remoteBound = true
	return true
end

function Runtime.ServerStart(): (boolean, string?)
	local okS, errS = Guard.serverOnly()
	if not okS then
		return false, errS
	end

	if _serverStarted then
		-- Print status anyway if enabled (helps debugging)
		printStatus("Server")
		return true, nil
	end

	local okBind = bindServerRemote()
	if not okBind then
		return fail("[FrameworkPlus] Missing RequestToken RemoteFunction (AutoCreateRemotes disabled?)")
	end

	_serverStarted = true

	print("➕FrameworkPlus Started")
	printStatus("Server")

	return true, nil
end

-- =========================================================
-- CLIENT
-- =========================================================

local function ensureServerStartedIfPossible()
	-- Edge case safety for testing
	if RunService:IsServer() then
		if Settings.AutoServerStart and not _serverStarted then
			Runtime.ServerStart()
		end
	end
end

function Runtime.ClientStartSystem(callerScript: Instance, systemName: string, opts: any?): (boolean, string?)
	local okC, errC = Guard.clientOnly()
	if not okC then
		failedCount += 1
		printStatus("Client")
		return false, errC
	end

	ensureServerStartedIfPossible()

	if type(systemName) ~= "string" or systemName == "" then
		failedCount += 1
		printStatus("Client")
		return fail("[FrameworkPlus] Invalid systemName")
	end

	if runningSystems[systemName] then
		printStatus("Client")
		return true, nil
	end

	local sys, cfgOrErr = resolveSystem(systemName)
	if not sys then
		failedCount += 1
		printStatus("Client")
		return fail(tostring(cfgOrErr))
	end

	local cfg = cfgOrErr
	if cfg.RunContext ~= "Client" then
		failedCount += 1
		printStatus("Client")
		return fail(("System '%s' is not Client"):format(systemName))
	end

	if Settings.RequireHandshake then
		local okCaller, errCaller = Guard.requireCallerScript(callerScript)
		if not okCaller then
			failedCount += 1
			printStatus("Client")
			return fail(tostring(errCaller))
		end
	end

	local rf = ensureRequestTokenRemote()
	if not rf then
		failedCount += 1
		printStatus("Client")
		return fail("[FrameworkPlus] Missing RequestToken RemoteFunction (did ServerStart run? AutoCreateRemotes disabled?)")
	end

	local callerTemplate, templateErr = Utils.templateCallerPathFromScript(callerScript)
	if not callerTemplate then
		failedCount += 1
		printStatus("Client")
		return fail("[FrameworkPlus] Caller template compute failed: " .. tostring(templateErr))
	end

	debugPrint("Caller template:", callerTemplate)

	local attempts = math.max(1, tonumber(Settings.TokenMaxAttempts) or 1)
	local delay = math.max(0, tonumber(Settings.TokenRetryDelay) or 0)

	local success = false
	local tokenOrErr: any = ""

	for _ = 1, attempts do
		local okInvoke, a, b = pcall(function()
			return rf:InvokeServer(systemName, callerTemplate)
		end)

		if okInvoke then
			success = (a == true)
			tokenOrErr = b
			if success then
				break
			end
		else
			tokenOrErr = a
		end

		if delay > 0 then
			task.wait(delay)
		end
	end

	if not success then
		failedCount += 1
		printStatus("Client")
		return fail(tostring(tokenOrErr))
	end

	local token = tokenOrErr

	local systemTable = require(sys)
	if type(systemTable) ~= "table" or type(systemTable.Start) ~= "function" then
		failedCount += 1
		printStatus("Client")
		return fail(("System '%s' missing Start(player,camera,token)"):format(systemName))
	end

	local player = (opts and opts.Player) or Players.LocalPlayer
	local camera = (opts and opts.Camera) or workspace.CurrentCamera

	local startedOk, startedRes = pcall(function()
		return systemTable.Start(player, camera, token)
	end)

	if not startedOk then
		failedCount += 1
		printStatus("Client")
		return fail(("System '%s' Start error: %s"):format(systemName, tostring(startedRes)))
	end

	if startedRes == false then
		failedCount += 1
		printStatus("Client")
		return fail(("System '%s' Start returned false"):format(systemName))
	end

	runningSystems[systemName] = true
	startedCount += 1

	printStatus("Client")
	return true, nil
end

function Runtime.ClientStopSystem(systemName: string): (boolean, string?)
	local okC, errC = Guard.clientOnly()
	if not okC then
		printStatus("Client")
		return false, errC
	end

	local sys, cfgOrErr = resolveSystem(systemName)
	if not sys then
		printStatus("Client")
		return fail(tostring(cfgOrErr))
	end

	local systemTable = require(sys)
	if type(systemTable) == "table" and type(systemTable.Stop) == "function" then
		pcall(systemTable.Stop)
	end

	runningSystems[systemName] = nil
	printStatus("Client")
	return true, nil
end

-- =========================================================
-- AUTO INIT (no manual ServerStart needed)
-- =========================================================

if RunService:IsServer() and Settings.AutoServerStart then
	task.defer(function()
		Runtime.ServerStart()
	end)
end

return Runtime