local Settings = {}

-- SECURITY
-- If true: caller MUST pass { CallerScript = script } and the server checks it.
Settings.RequireHandshake = true

-- TOKEN
Settings.TokenMaxAttempts = 5
Settings.TokenRetryDelay = 1

-- VERSION CHECK (advanced module uses this)
-- Put your own published “development place id” here later (optional).
Settings.DevelopmentPlaceId = 84279530388739 -- put your PLACE ID here

Settings.MarketplaceNamePattern = "^FrameworkPlus%s*(.*)$"

Settings.VersionFetchTries = 8
Settings.VersionFetchDelay = 1

-- Reference object name
Settings.ReferenceObjectName = "FrameworkPlusReference"

return Settings