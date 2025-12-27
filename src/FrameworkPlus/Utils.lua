local Utils = {}

function Utils.clampAnglePi(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

function Utils.templateCallerPathFromScript(callerScript: Instance): string
	local full = callerScript:GetFullName()
	full = full:gsub("^Players%.[^%.]+%.PlayerScripts%.", "StarterPlayer.StarterPlayerScripts.")
	full = full:gsub("^Players%.[^%.]+%.StarterPlayerScripts%.", "StarterPlayer.StarterPlayerScripts.")
	return full
end

function Utils.startsWith(s: string, prefix: string): boolean
	return s:sub(1, #prefix) == prefix
end

return Utils