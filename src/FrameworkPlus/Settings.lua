local Settings = {}

----------------------------------------------------------------
-- CREDIT (DO NOT TOUCH IF YOU WANT BRAND CONSISTENCY)
----------------------------------------------------------------
Settings.BrandName = "FrameworkPlus"
Settings.Author = "@Ben1amyn77"
Settings.PrintPrefix = "[FrameworkPlus] "

----------------------------------------------------------------
-- SECURITY (ADVANCED)
-- If you don't understand this, don't change it.
----------------------------------------------------------------
Settings.RequireHandshake = true          -- requires callerScript on client
Settings.RequireToken = true              -- blocks direct system.Start without token

-- Only these caller templates are allowed to start ANY system (global allow list)
-- If empty, it relies on each system's Config.HandshakePath only.
Settings.AllowedCallerTemplates = {
	"StarterPlayer.StarterPlayerScripts.StarterCharacterSystemCaller",
}

----------------------------------------------------------------
-- TOKEN RETRY (CLIENT)
----------------------------------------------------------------
Settings.TokenMaxAttempts = 5
Settings.TokenRetryDelay = 1

----------------------------------------------------------------
-- REMOTES (INSIDE FrameworkPlus)
----------------------------------------------------------------
Settings.RemotesFolderName = "Remotes"
Settings.RequestTokenRemoteName = "FrameworkPlus_RequestToken"

----------------------------------------------------------------
-- VERSION CHECK (OPTIONAL)
-- Put your "development place id" here if you want auto-checking.
----------------------------------------------------------------
Settings.DevelopmentPlaceId = 842795303887392
Settings.MarketplaceNamePattern = "^FrameworkPlus%s*(.*)$"
Settings.VersionFetchTries = 8
Settings.VersionFetchDelay = 1

return Settings