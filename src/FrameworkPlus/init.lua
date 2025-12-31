-- ReplicatedStorage.Module.FrameworkPlus
local RunService = game:GetService("RunService")

local FrameworkPlus = {}

local Runtime = require(script:WaitForChild("Runtime"))
local Settings = require(script:WaitForChild("Settings"))
local Utils = require(script:WaitForChild("Utils"))

-- =========================================================
-- Internal helpers
-- =========================================================

local function fail(msg: string)
	return false, msg
end

local function isNonEmptyString(v: any): boolean
	return type(v) == "string" and v ~= ""
end

-- =========================================================
-- SERVER
-- =========================================================

-- Optional manual start (Runtime also auto-starts if Settings.AutoServerStart = true)
function FrameworkPlus:ServerStart()
	return Runtime.ServerStart()
end

-- =========================================================
-- CLIENT
-- =========================================================

-- Usage (client):
-- FrameworkPlus:ClientStartSystem("SystemName", { Player=..., Camera=..., CallerScript=script })
function FrameworkPlus:ClientStartSystem(systemName: string, opts: any?)
	opts = opts or {}

	if not isNonEmptyString(systemName) then
		return fail("[FrameworkPlus] ClientStartSystem: systemName must be a non-empty string")
	end

	-- Accept callerScript from opts OR fall back to this module's script (works but handshake may require explicit CallerScript)
	local callerScript = opts.CallerScript or script

	-- Runtime.ClientStartSystem(callerScript, systemName, opts)
	return Runtime.ClientStartSystem(callerScript, systemName, opts)
end

function FrameworkPlus:ClientStopSystem(systemName: string)
	if not isNonEmptyString(systemName) then
		return fail("[FrameworkPlus] ClientStopSystem: systemName must be a non-empty string")
	end
	return Runtime.ClientStopSystem(systemName)
end

function FrameworkPlus:IsSystemRunning(systemName: string): boolean
	if not isNonEmptyString(systemName) then
		return false
	end
	return Runtime.IsSystemRunning(systemName)
end

-- =========================================================
-- UNIVERSAL (nice to have)
-- =========================================================

-- StartSystem picks the correct runtime based on context.
-- Right now your framework systems are "Client" systems, but this makes it future-proof.
--
-- Usage:
-- FrameworkPlus:StartSystem("FirstPersonCameraSystem", { CallerScript = script, Player = ..., Camera = ... })
function FrameworkPlus:StartSystem(systemName: string, opts: any?)
	opts = opts or {}

	if not isNonEmptyString(systemName) then
		return fail("[FrameworkPlus] StartSystem: systemName must be a non-empty string")
	end

	if RunService:IsClient() then
		return self:ClientStartSystem(systemName, opts)
	end

	-- Server: if you ever add Server systems later, you can extend Runtime with ServerStartSystem
	-- For now, we just ensure server runtime is started (token remote bound).
	if Settings.AutoServerStart then
		Runtime.ServerStart()
	end

	return fail("[FrameworkPlus] StartSystem called on Server, but this framework currently starts Client systems only")
end

-- Quick debugging helper (client-safe)
function FrameworkPlus:DescribeCaller(callerScript: any): string
	return Utils.describeCaller(callerScript)
end

return FrameworkPlus