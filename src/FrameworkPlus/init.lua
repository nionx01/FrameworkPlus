local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = require(script:WaitForChild("Runtime"))

local FrameworkPlus = {}

-- Expose version/info if you want
FrameworkPlus.VERSION = require(script:WaitForChild("VERSION"))

-- Server boot (creates/owns remotes inside FrameworkPlus.Remotes)
function FrameworkPlus.ServerStart()
	return Runtime.ServerStart()
end

-- Client start system (auto-handshake path; no manual CallerPath needed)
function FrameworkPlus.ClientStartSystem(systemName: string, payload: table?)
	return Runtime.ClientStartSystem(systemName, payload)
end

-- Convenience: return Systems folder
function FrameworkPlus.GetSystemsFolder()
	return script:WaitForChild("Systems")
end

-- Convenience: return Remotes folder
function FrameworkPlus.GetRemotesFolder()
	return script:WaitForChild("Remotes")
end
return FrameworkPlus
