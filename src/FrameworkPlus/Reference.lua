local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(script.Parent:WaitForChild("Settings"))

local Reference = {}

function Reference.addToReplicatedStorage()
	local existing = ReplicatedStorage:FindFirstChild(Settings.ReferenceObjectName)
	if existing then
		return false
	end

	local ov = Instance.new("ObjectValue")
	ov.Name = Settings.ReferenceObjectName
	ov.Value = script.Parent
	ov.Parent = ReplicatedStorage
	return ov
end

function Reference.getObject()
	return ReplicatedStorage:FindFirstChild(Settings.ReferenceObjectName)
end
return Reference