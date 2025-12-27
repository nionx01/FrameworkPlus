local Runtime = require(script:WaitForChild("Runtime"))

local FrameworkPlus = {}

-- SERVER: call once on server boot
function FrameworkPlus.ServerStart(): (boolean, string?)
	return Runtime.ServerStart()
end

-- CLIENT: easiest usage:
-- FrameworkPlus.ClientStartSystem(script, "ExampleSystem")
-- FrameworkPlus.ClientStartSystem(script, "ExampleSystem", { Player = ..., Camera = ... })
function FrameworkPlus.ClientStartSystem(callerScript: Instance, systemName: string, opts: any?): (boolean, string?)
	return Runtime.ClientStartSystem(callerScript, systemName, opts)
end

function FrameworkPlus.ClientStopSystem(systemName: string): (boolean, string?)
	return Runtime.ClientStopSystem(systemName)
end

function FrameworkPlus.IsSystemRunning(systemName: string): boolean
	return Runtime.IsSystemRunning(systemName)
end

return FrameworkPlus
