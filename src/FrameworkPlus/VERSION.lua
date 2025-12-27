--!strict
local MarketplaceService = game:GetService("MarketplaceService")

local Settings = require(script.Parent:WaitForChild("Settings"))

local VERSION = {}

VERSION.appVersion = "v0.0.1"
VERSION.latestVersion = nil :: string?

local function fetchPlaceName(placeId: number): string?
	-- IMPORTANT:
	-- placeId MUST be a PlaceId (asset id), NOT UniverseId
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(placeId)
	end)

	if not success then
		warn("[FrameworkPlus.VERSION] GetProductInfoAsync failed")
		return nil
	end

	if type(info) ~= "table" or type(info.Name) ~= "string" then
		warn("[FrameworkPlus.VERSION] Invalid product info returned")
		return nil
	end

	return info.Name
end

function VERSION.getLatestVersion(): string?
	local placeId = Settings.DevelopmentPlaceId
	if type(placeId) ~= "number" or placeId <= 0 then
		warn("[FrameworkPlus.VERSION] DevelopmentPlaceId missing or invalid")
		return nil
	end

	-- Cache
	if VERSION.latestVersion ~= nil then
		return VERSION.latestVersion
	end

	local tries = Settings.VersionFetchTries or 6
	local delaySec = Settings.VersionFetchDelay or 1

	for _ = 1, tries do
		local placeName = fetchPlaceName(placeId)
		if placeName then
			local pattern = Settings.MarketplaceNamePattern or "^FrameworkPlus%s*(.*)$"
			local extracted = string.match(placeName, pattern)

			if extracted then
				extracted = extracted:gsub("%s+", "")
			end

			VERSION.latestVersion = extracted
			return extracted
		end

		task.wait(delaySec)
	end

	warn("[FrameworkPlus.VERSION] Failed to fetch latest version after retries")
	return nil
end

function VERSION.getAppVersion(): string
	return VERSION.appVersion
end

function VERSION.isUpToDate(): boolean
	local latest = VERSION.getLatestVersion()
	return latest ~= nil and latest == VERSION.appVersion
end
return VERSION
