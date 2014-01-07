-- Handles mod loading.
local log = rp.logf
local CONFIG = rp.CONFIG

-- Loading status of a mod. This is accessible by reading a `mod.status`
local LoadingStatus = {
	AVAILABLE = 'available', -- We have found this mod and will attempt to load it (later). You should never see this status externally.
	LOADING = 'loading', -- We are currently loading this mod (somewhere in the callstack)
	LOADED = 'loaded', -- We have already loaded this mod
	FAILED = 'failed', -- We tried to load this mod, but it failed
	SKIPPED = 'skipped', -- We skipped this (not-RP) mod. A manifest might still exist.
}

local ModSource = {
	DIRECTORY = 'DIR',
	SMOD_ARCHIVE = 'SMOD'
}

-- The naming does not quite fit into Radiant's naming scheme.
-- However, they technically are struct-ish classes, so... hell, if I knew.
-- "rp.mod_loading_status" sounds like a function to me. The only "struct"
-- I have seen was in log.lua, which was local too. But it was called Log!
-- I'll take this as EVIDENCE for CamelCasing.
--
-- Technically, I guess they'd be constants, too.
rp.constants.mod_status = LoadingStatus
rp.constants.mod_source = ModSource

function rp.load_mods()
	-- Mods contains a hash table of mods that are RP-enabled
	-- otherMods contains a list of mods that are installed, but not RP.
	local mods = {}
	
	rp.load_mods = nil
	log('Start mod loader...')
	
	local disabledMods = {}
	
	for k, v in pairs(CONFIG.disabled_mods) do
		disabledMods[v] = true
	end
	
	local function getMod(modName, source)
		-- Try to get the manifest json
		local manySuccesses, manifest = rp.run_safe(radiant.resources.load_manifest, modName) -- many json, wow, much successes, amazing, many configs
		
		-- No manifest means a bad time.
		-- It means that stonehearth *likely* hasn't loaded the mod either, so we're not going to bother.
		if not manySuccesses or not manifest then
			return nil
		end
		
		-- Set our status already.
		local status = LoadingStatus.AVAILABLE
		
		-- If the mod is disabled *or* has no rp entry in its manifest, we'll skip it
		if disabledMods[modName] or not manifest.rp then
			log('Skip %s (ignored or no rp manifest)', modName)
			
			status = LoadingStatus.SKIPPED
		end
		
		return { manifest = manifest, source = source, status = status, name = modName } -- "name" is kinda redundant but I'll allow it
	end
	
	log('Checking directories...')
	-- Check all directories
	for modName in io.popen('dir /B /A:D mods'):lines() do
		-- Not disabled?
		local mod = getMod(modName, ModSource.DIRECTORY)
		
		if mod then
			mods[modName] = mod
			log('Found %s as rp mod (DIR)', modName)
		end
	end
	
	log('Checking smod files...')
	-- And then all smods.
	for modName in io.popen('dir /B "mods\\*.smod'):lines() do
		local mod = getMod(modName, ModSource.SMOD_ARCHIVE)
		
		if mod then
			mods[modName] = mod
			log('Found %s as rp mod (DIR)', modName)
		end
	end

	log('Built list of possible mods. Start loading process...')

	-- Attempts to load said mod
	local function loadMod(name, mod)
		mod = mod or mods[name]
		
		if not mod then
			log('Cannot load mod %q: Not found in mod list.', name)
			return false
		end
		
		if mod.status == LoadingStatus.LOADED then
			return true
		end
		
		-- Failed or skipped mods do not count.
		if mod.status == LoadingStatus.FAILED or mod.status == LoadingStatus.SKIPPED then
			log('Cannot load %q: status is %s', name, tostring(mod.status))
			return false
		elseif mod.status == LoadingStatus.LOADING then
			log('Cycle found! Attempted to load %q /again/', name)
			mod.status = LoadingStatus.FAILED
			return false
		end
		
		log('Attempting to load %s (source %s)...', name, tostring(mod.source))
		mod.status = LoadingStatus.LOADING
		
		local rpm = mod.manifest.rp
		
		-- Requirements?
		local requirement = rpm.required
		if requirement then
			log('Parse requirements for %s...', name)
			if type(requirement) ~= 'table' then
				requirement = { requirement }
			end
			
			for k, required in pairs(requirement) do
				log('Attempt to load requirement %s for %s', required, name)
				if not loadMod(required) then
					log('Cannot load %q: Required mod %q is missing/not loading/disabled', name, required)
					mod.status = LoadingStatus.FAILED
					return false
				end
				
				log('%s successfully loaded for %s', required, name)
			end
		end
		
		local requested = rpm.requested
		if requested then
			log('Parse requested mods for %s...', name)
			if type(requested) ~= 'table' then
				requested = { requested }
			end
			
			for k, requestee in pairs(requested) do
				log('Attempt to load request %s', requestee, name)
				if not loadMod(requestee) then
					log('Requested mod %s for %s not found.', requestee, name)
				else
					log('%s successfully loaded for %s', requestee, name)
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
				mod.status = LoadingStatus.LOADED
				log('Successfully loaded %s', name)
				return true
			else
				mod.status = LoadingStatus.FAILED
				return false
			end
		else
			log('No init file for %q found.', name)
		end
		
		-- Nothing to load.
		mod.status = LoadingStatus.LOADED
		return true
	end
		
	for modName, data in pairs(mods) do
		log('Loading %s returned %s', modName, tostring(loadMod(modName, data)))
	end
	
	log()
	log("We're past mod loading and all is well.")
	
	-- Save it in rp.
	rp.available_mods = mods
end