local Config = require(script.Parent:WaitForChild("Config"))
local Guard = require(script.Parent.Parent.Parent:WaitForChild("Guard"))

local System = {}
local running = false

function System.Start(player, camera, token)
	if running then return true end
	if not Guard.validToken(token) then
		warn((Config.PrintPrefix or "[ExampleSystem] ") .. "Blocked: must start via FrameworkPlus token.")
		return false
	end

	running = true
	print((Config.PrintPrefix or "[ExampleSystem] ") .. "Started.")
	return true
end

function System.Stop()
	if not running then return end
	running = false
	print((Config.PrintPrefix or "[ExampleSystem] ") .. "Stopped.")
end
return System