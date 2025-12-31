local RunService = game:GetService("RunService")

local Settings = require(script.Parent:WaitForChild("Settings"))
local Utils = require(script.Parent:WaitForChild("Utils"))

local Guard = {}

function Guard.serverOnly(): (boolean, string?)
	if not RunService:IsServer() then
		return false, Settings.PrintPrefix .. "Server-only function called on client"
	end
	return true, nil
end

function Guard.clientOnly(): (boolean, string?)
	if not RunService:IsClient() then
		return false, Settings.PrintPrefix .. "Client-only function called on server"
	end
	return true, nil
end

function Guard.requireCallerScript(callerScript: Instance?): (boolean, string?)
	if Settings.RequireHandshake and (callerScript == nil) then
		return false, Settings.PrintPrefix .. "Settings.RequireHandshake=true, so you must pass (script) as first argument."
	end
	return true, nil
end

function Guard.isAllowedCallerTemplate(templatePath: string): (boolean, string?)
	local allowed = Settings.AllowedCallerTemplates
	if type(allowed) == "table" and #allowed > 0 then
		for _, v in ipairs(allowed) do
			if v == templatePath then
				return true, nil
			end
		end
		return false, Settings.PrintPrefix .. ("Caller template blocked: %s"):format(templatePath)
	end
	return true, nil
end

function Guard.validToken(token: any): boolean
	if not Settings.RequireToken then return true end
	return type(token) == "string" and Utils.startsWith(token, "FP|")
end

return Guard