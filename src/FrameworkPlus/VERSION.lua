local MarketplaceService = game:GetService("MarketplaceService")

local Settings = require(script.Parent:WaitForChild("Settings"))

local VERSION = {}

VERSION.appVersion = "v0.0.1"
VERSION.latestVersion = nil :: string?

function VERSION.getLatestVersion(): string?
	local id = Settings.DevelopmentPlaceId
	if type(id) ~= "number" or id == 0 then
		return nil
	end

	if VERSION.latestVersion ~= nil then
		return VERSION.latestVersion
	end

	local tries = Settings.VersionFetchTries
	local delay = Settings.VersionFetchDelay

	for _ = 1, tries do
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id)
		end)
		if ok and info and type(info.Name) == "string" then
			local placeName = info.Name
			local pattern = Settings.MarketplaceNamePattern
			local latest = string.match(placeName, pattern)
			if latest then
				latest = latest:gsub("%s+", "")
			end
			VERSION.latestVersion = latest
			return latest
		end
		task.wait(delay)
	end

	return nil
end

function VERSION.isUpToDate(): boolean
	local latest = VERSION.getLatestVersion()
	return latest ~= nil and latest == VERSION.appVersion
end

return VERSION