local System = {}
local running = false

local function validToken(token: any): boolean
	return type(token) == "string" and token:sub(1, 3) == "FP|"
end

function System.Start(_player: Player?, _camera: Camera?, token: any)
	if running then return true end
	if not validToken(token) then return false end
	running = true
	print("[ExampleSystem] STARTED")
	return true
end

function System.Stop()
	if not running then return end
	running = false
	print("[ExampleSystem] STOPPED")
end

return System