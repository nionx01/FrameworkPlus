local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reference = {}
Reference.objectName = "FrameworkPlusReference"

function Reference.add()
	local existing = ReplicatedStorage:FindFirstChild(Reference.objectName)
	if existing then
		return false
	end

	local ov = Instance.new("ObjectValue")
	ov.Name = Reference.objectName
	ov.Value = script.Parent
	ov.Parent = ReplicatedStorage
	return true
end

function Reference.get(): ObjectValue?
	local ov = ReplicatedStorage:FindFirstChild(Reference.objectName)
	if ov and ov:IsA("ObjectValue") then
		return ov
	end
	return nil
end

return Reference