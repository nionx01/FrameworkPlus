local RunService = game:GetService("RunService")
local Settings = require(script.Parent:WaitForChild("Settings"))

local Guard = {}

function Guard.clientPrecheck(cfg: table): (boolean, string?)
	if not RunService:IsClient() then
		return false, "ClientStartSystem must run on client"
	end
	if cfg.RunContext ~= "Client" then
		return false, "System RunContext is not Client"
	end
	if Settings.RequireHandshake then
		if type(cfg.HandshakePath) ~= "string" or cfg.HandshakePath == "" then
			return false, "Settings.RequireHandshake=true but system Config.HandshakePath missing"
		end
	end
	return true
end

function Guard.validToken(token: any): boolean
	return type(token) == "string" and token:sub(1, 3) == "FP|"
end
return Guard