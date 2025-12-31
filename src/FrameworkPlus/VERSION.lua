local MarketplaceService = game:GetService("MarketplaceService")

local VERSION = {}

----------------------------------------------------------------
-- CONFIG (SELF-CONTAINED)
----------------------------------------------------------------
VERSION.Config = {
	AppVersion = "v0.1.2",

	-- 0 disables Marketplace lookup
	DevelopmentPlaceId = 842795303887392,

	-- Extracts v1.2.3 or 1.2.3 from Name/Description
	VersionPattern = "(v?%d+%.%d+%.%d+)",

	FetchTries = 6,
	BaseDelay = 0.6,
	MaxDelay = 6,
	CacheTTL = 60,

	PreferDescription = false,

	-- Force latest version (disables Marketplace lookup if set)
	OverrideLatestVersion = nil, -- e.g. "v1.2.3"

	Debug = false,
}

----------------------------------------------------------------
-- CACHE
----------------------------------------------------------------
VERSION._cache = {
	latest = nil :: string?,
	lastFetch = 0 :: number,
	lastError = nil :: string?,
}

----------------------------------------------------------------
-- UTILS
----------------------------------------------------------------
local function dbg(...)
	if VERSION.Config.Debug then
		print("[FrameworkPlus:VERSION]", ...)
	end
end

local function now(): number
	return os.clock()
end

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeVersion(v: string?): string?
	if type(v) ~= "string" then return nil end
	v = trim(v):gsub("%s+", "")
	if v == "" then return nil end

	if not v:match("^v") and v:match("^%d") then
		v = "v" .. v
	end

	return v:match("^(v?%d+%.%d+%.%d+)")
end

local function parseSemver(v: string?): (number?, number?, number?)
	v = normalizeVersion(v)
	if not v then return nil end
	local a, b, c = v:match("^v?(%d+)%.(%d+)%.(%d+)$")
	if not a then return nil end
	return tonumber(a), tonumber(b), tonumber(c)
end

local function compareSemver(a: string?, b: string?): number
	local a1, a2, a3 = parseSemver(a)
	local b1, b2, b3 = parseSemver(b)
	if not a1 or not b1 then
		a, b = tostring(a or ""), tostring(b or "")
		if a == b then return 0 end
		return (a < b) and -1 or 1
	end
	if a1 ~= b1 then return (a1 < b1) and -1 or 1 end
	if a2 ~= b2 then return (a2 < b2) and -1 or 1 end
	if a3 ~= b3 then return (a3 < b3) and -1 or 1 end
	return 0
end

local function shouldUseCache(): boolean
	if not VERSION._cache.latest then return false end
	return (now() - VERSION._cache.lastFetch) < VERSION.Config.CacheTTL
end

local function setCache(v: string?, err: string?)
	VERSION._cache.latest = v
	VERSION._cache.lastError = err
	VERSION._cache.lastFetch = now()
end

local function extract(text: string?): string?
	if type(text) ~= "string" then return nil end
	local found = text:match(VERSION.Config.VersionPattern)
	return normalizeVersion(found)
end

-- Async-first, fallback to GetProductInfo if Async not available
local function getProductInfo(placeId: number)
	-- Prefer GetProductInfoAsync when present in the engine :contentReference[oaicite:4]{index=4}
	if typeof(MarketplaceService.GetProductInfoAsync) == "function" then
		return MarketplaceService:GetProductInfoAsync(placeId)
	end
	-- Fallback: GetProductInfo exists too :contentReference[oaicite:5]{index=5}
	return MarketplaceService:GetProductInfo(placeId)
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------
function VERSION.getLastError(): string?
	return VERSION._cache.lastError
end

function VERSION.getLatestVersion(forceRefresh: boolean?): string?
	-- Override mode
	if type(VERSION.Config.OverrideLatestVersion) == "string" and VERSION.Config.OverrideLatestVersion ~= "" then
		local v = normalizeVersion(VERSION.Config.OverrideLatestVersion)
		setCache(v, nil)
		return v
	end

	local id = tonumber(VERSION.Config.DevelopmentPlaceId) or 0
	if id <= 0 then
		setCache(nil, "DevelopmentPlaceId not set (or <= 0)")
		return nil
	end

	if not forceRefresh and shouldUseCache() then
		return VERSION._cache.latest
	end

	local lastErr: string? = nil

	for i = 1, VERSION.Config.FetchTries do
		local ok, infoOrErr = pcall(function()
			return getProductInfo(id)
		end)

		if ok and type(infoOrErr) == "table" then
			local info = infoOrErr
			local name = (type(info.Name) == "string") and info.Name or ""
			local desc = (type(info.Description) == "string") and info.Description or ""

			local latest = VERSION.Config.PreferDescription
				and (extract(desc) or extract(name))
				or (extract(name) or extract(desc))

			if latest then
				dbg("Latest version fetched:", latest)
				setCache(latest, nil)
				return latest
			end

			lastErr = "Version not found in Marketplace metadata (Name/Description)"
		else
			lastErr = tostring(infoOrErr)
		end

		local delay = math.min(VERSION.Config.MaxDelay, VERSION.Config.BaseDelay * (2 ^ (i - 1)))
		task.wait(delay + math.random() * 0.15)
	end

	setCache(nil, lastErr)
	return nil
end

function VERSION.isUpToDate(): (boolean, string?)
	local latest = VERSION.getLatestVersion(false)
	if not latest then
		return false, VERSION.getLastError()
	end

	local app = normalizeVersion(VERSION.Config.AppVersion)
	if not app then
		return false, "Invalid AppVersion in VERSION.Config.AppVersion"
	end

	return compareSemver(app, latest) >= 0, nil
end

function VERSION.isUpdateAvailable(): (boolean, string?)
	local latest = VERSION.getLatestVersion(false)
	if not latest then
		return false, VERSION.getLastError()
	end

	local app = normalizeVersion(VERSION.Config.AppVersion)
	if not app then
		return false, "Invalid AppVersion in VERSION.Config.AppVersion"
	end

	return compareSemver(app, latest) < 0, nil
end

return VERSION