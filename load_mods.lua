-- Handles mod loading.
local Mods = {}

local log = rp.logf
local CONFIG = rp.CONFIG

function rp.load_mods()
	rp.load_mods = nil
	log('Start tiresome mod loading process (is_server %s).', tostring(radiant.is_server))
	
	local disabledMods = {}
	
	for k, v in pairs(CONFIG.disabled_mods) do
		disabledMods[v] = true
	end
	
	local function getManifest(modName)
		-- disabled mods have no manifest.
		if disabledMods[modName] then
			log('Skip %s (disabled in rp.json)', modName)
			return nil
		end
		
		-- Try to get the manifest json
		local _, manifest = rp.run_safe(radiant.resources.load_manifest, modName)
		if manifest and manifest.rp then
			return manifest
		end
		return nil
	end
	
	log('Start checking directories.')
	-- Check all directories
	for modName in io.popen('dir /B /A:D mods'):lines() do
		-- Not disabled?
		local manifest = getManifest(modName)
		if manifest then
			Mods[modName] = { source = 'dir', manifest = manifest }
			log('Found %s as rp mod (DIR)', modName)
		end
	end
	
	log('To boldly go where no smod file has gone before:')
	-- And then all smods.
	for modName in io.popen('dir /B "mods\\*.smod'):lines() do
		modName = modName:sub(0, #modName - 5)
		-- Not disabled?
		local manifest = getManifest(modName)
		if manifest then
			Mods[modName] = { source = 'dir', manifest = manifest }
			log('Found %s as rp mod (DIR)', modName)
		end
	end

	log('Processed possible mod files/directories; start shaking me booties.')
	
	-- Loading status of a mod.
	local LoadingStatus = {
		Loading = 1,
		Loaded = 2,
		Failed = 3
	}

	-- Attempts to load said mod
	local function loadMod(name, mod)
		mod = mod or Mods[name]
	
		if not mod then
			log('Cannot load mod %q: Not a rp mod or not available or something like that.', name)
			return false
		end
		
		if mod.loaded == LoadingStatus.Failed then
			return false
		elseif mod.loaded == LoadingStatus.Loading then
			log('Cycle found! Attempted to load %q /again/', name)
			mod.loaded = LoadingStatus.Failed
			return false
		elseif mod.loaded == LoadingStatus.Loaded then
			return true
		end
		
		log('Attempting to load %s...', name)
		mod.loaded = LoadingStatus.Loading
		
		local rpm = mod.manifest.rp
		
		-- Requirements?
		local requirement = rpm.required
		if requirement then
			log('Parse requirements for %s...', name)
			if type(requirement) ~= 'table' then
				requirement = { requirement }
			end
			
			for k, required in pairs(requirement) do
				if not loadMod(required) then
					log('Cannot load %q: Required mod %q is missing/not loading/disabled', name, required)
					mod.loaded = LoadingStatus.Failed
					return false
				end
			end
		end
		
		local requested = rpm.requested
		if requested then
			log('Parse requested mods for %s...', name)
			if type(requested) ~= 'table' then
				requested = { requested }
			end
			
			for k, requestee in pairs(requested) do
				if not loadMod(requestee) then
					log('Requested mod %s for %s not found.', requestee, name)
				end
			end
		end
		
		-- Attempt to load the init file, if existant
		local init
		
		if radiant.is_server then
			init = rpm.server_init
		else
			init = rpm.client_init
		end
		
		if init then
			log('Loading %s...', name)
			
			if init:find('.lua$') then
				init = init:sub(0, #init - 4)
			end
			
			if rp.run_safe(_host.require, _host, name .. '.' .. init) then
				mod.loaded = LoadingStatus.Loaded
				log('Successfully loaded %s', name)
				return true
			else
				mod.loaded = LoadingStatus.Failed
				return false
			end
		else
			log('No init file for %q found.', name)
		end
		
		-- Nothing to load.
		mod.loaded = LoadingStatus.Loaded
		return true
	end
		
	for modName, data in pairs(Mods) do
		log('Loading %s returned %s', modName, tostring(loadMod(modName, data)))
	end
end