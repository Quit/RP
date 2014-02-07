function radiant.mods.load(name)
	-- TODO: Properly respect the manifest's init script entries
	return radiant.mods.require(string.format('%s.%s_%s', name, name, (radiant.is_server and 'server' or 'client')))
end