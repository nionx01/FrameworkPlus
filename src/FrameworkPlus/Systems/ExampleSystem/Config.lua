local Config = {}

Config.SystemName = "ExampleSystem"
Config.PrintPrefix = "[ExampleSystem] "
Config.RunContext = "Client"

-- Only allow calls from this template path:
Config.HandshakePath = "StarterPlayer.StarterPlayerScripts.StarterCharacterSystemCaller"
return Config