local Utils = {}

function Utils.safeRequire(mod: ModuleScript): (boolean, any)
	return pcall(require, mod)
end

function Utils.runtimeToTemplatePath(full: string): string
	full = full:gsub("^Players%.[^%.]+%.PlayerScripts%.", "StarterPlayer.StarterPlayerScripts.")
	full = full:gsub("^Workspace%.[^%.]+%.", "StarterPlayer.StarterPlayerScripts.")
	return full
end

function Utils.log(msg: string, cfg: table?, serverTag: boolean?)
	local prefix = "[FrameworkPlus] "
	if cfg and type(cfg.PrintPrefix) == "string" and cfg.PrintPrefix ~= "" then
		prefix = cfg.PrintPrefix
	end
	if serverTag then
		print(prefix .. msg)
	else
		print(prefix .. msg)
	end
end
return Utils
