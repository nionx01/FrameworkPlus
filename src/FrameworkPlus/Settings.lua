local Settings = {}

----------------------------------------------------------------
-- SECURITY / BEHAVIOR
----------------------------------------------------------------
Settings.RequireHandshake = true              -- requires callerScript on client (Guard.requireCallerScript)
Settings.RequireHandshakePath = true          -- enforces Config.HandshakePath match (server-side check)
Settings.RequireToken = true                  -- systems should verify token (framework provides it)

-- If true, FrameworkPlus auto-starts server runtime when the module is required on server
Settings.AutoServerStart = true

-- If true, remote folder/function will be created automatically (recommended)
Settings.AutoCreateRemotes = true

-- If true, ONLY allowed caller templates may request tokens (Guard.allowlist)
Settings.StrictCallerAllowList = true

----------------------------------------------------------------
-- TOKEN RETRY (CLIENT)
----------------------------------------------------------------
Settings.TokenMaxAttempts = 5
Settings.TokenRetryDelay = 1

----------------------------------------------------------------
-- DEBUG / LOGGING
----------------------------------------------------------------
Settings.Debug = false
Settings.PrintStatus = false         		-- ALWAYS show status lines
Settings.PrintServerStatus = false   		-- server status line
Settings.PrintClientStatus = false   		-- client status line
Settings.ErrorTracebacks = true             -- include tracebacks in errors

return Settings