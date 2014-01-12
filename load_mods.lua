--[=============================================================================[
The MIT License (MIT)

Copyright (c) 2014 RepeatPan
excluding parts that were written by Radiant Entertainment.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]=============================================================================]

-- Localizing.
local type = type

-- Handles mod loading.
local log = rp.logf

function log_error(text, ...)
	return log('[ERROR] ' .. text, ...)
end

function log_info(text, ...)
	return log('[INFO] ' .. text, ...)
end

function log_warning(text, ...)
	return log('[WARNING] ' .. text, ...)
end

local CONFIG = rp.CONFIG
local VERSION = rp.constants.VERSION

-- Loading status of a mod. This is accessible by reading a `mod.status`
-- I would probably do quite a few things for the bit library now. And proper enums.
local LoadingStatus = {
	AVAILABLE = 'available', -- We have found this mod and will attempt to load it (later).
	LOADING = 'loading', -- We are currently loading this mod (somewhere in the callstack)
	LOADED = 'loaded', -- We have already loaded this mod
	FAILED = 'failed', -- We tried to load this mod, but it failed
	SKIPPED = 'skipped', -- We skipped this (not-RP) mod. A manifest might still exist.
	DISABLED = 'disabled', -- We skipped this mod because we've disabled it
	CONFLICTED = 'conflicted' -- We conflicted with another mod
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
	log()
	
	-- List of mods that have been disabled in the config. mod_name => true
	local disabled_mods = {}
	
	for k, v in pairs(CONFIG.disabled_mods) do
		disabled_mods[v] = true
	end
	
	local function get_mod(mod_name, source)
		-- Try to get the manifest json
		local many_successes, manifest = rp.run_safe(radiant.resources.load_manifest, mod_name) -- many json, wow, much successes, amazing, many configs
		
		-- No manifest means a bad time.
		-- It means that stonehearth *likely* hasn't loaded the mod either, so we're not going to bother.
		if not many_successes or not manifest then
			return nil
		end
		
		-- Set our status already.
		local status = LoadingStatus.AVAILABLE
		
		-- If the mod is disabled *or* has no rp entry in its manifest, we'll skip it
		if disabled_mods[mod_name] then
			log_info('Skip %s (disabled)', mod_name)
			status = LoadingStatus.DISABLED
		elseif not manifest.rp then
			log_info('Skip %s (no rp manifest found)', mod_name)
			status = LoadingStatus.SKIPPED
		end
		
		return { manifest = manifest, source = source, status = status, name = mod_name } -- "name" is kinda redundant but I'll allow it
	end
	
	log('Checking directories...')
	log()
	
	-- Check all directories
	for mod_name in io.popen('dir /B /A:D mods'):lines() do
		-- Not disabled?
		local mod = get_mod(mod_name, ModSource.DIRECTORY)
		
		if mod then
			mods[mod_name] = mod
			log('Found %s as rp mod (DIR)', mod_name)
		end
	end
	
	log()
	log('Checking smod files...')
	log()
	
	-- And then all smods.
	for mod_name in io.popen('dir /B "mods\\*.smod'):lines() do
		mod_name = mod_name:sub(0, #mod_name - 5)
		local mod = get_mod(mod_name, ModSource.SMOD_ARCHIVE)
		
		if mod then
			mods[mod_name] = mod
			log('Found %s as rp mod (SMOD)', mod_name)
		end
	end

	log()
	log('Built list of possible mods. Do advanced manifest magic...')
	log()
	
	for mod_name, mod in pairs(mods) do
		-- If a mod is available, it has a rp tag.
		if mod.status == LoadingStatus.AVAILABLE then
			local before, conflicts = mod.manifest.rp.before, mod.manifest.rp.conflicts
			
			-- Are we not playing along well with other mods?
			if conflicts then
				if type(conflicts) ~= 'table' then
					conflicts = { conflicts }
				end
				
				for _, other in pairs(conflicts) do
					local other_mod = mods[other]
					if other_mod and other_mod.status == LoadingStatus.AVAILABLE then
						log_error('Conflict: %s says it is not compatible with %s!', mod_name, other)
						mod.status = LoadingStatus.CONFLICTED
						break -- we can't get more disabled.
					end
				end
			end
			
			-- Does it define "before"? Are we not conflicted?
			if before and mod.status == LoadingStatus.AVAILABLE then
				if type(before) ~= 'table' then
					before = { before }
				end
				
				-- Go for it.
				for _, other in pairs(before) do
					-- Check if said mod exists
					local other_mod = mods[other]
					
					-- It does!
					if other_mod and other_mod.status == LoadingStatus.AVAILABLE then
						local rp = other_mod.manifest.rp
						-- Make sure the field exists
						rp.requested = rp.requested or {}
						
						-- Make sure the other field is a table. I really feel like we
						-- should drop string support.
						if type(rp.requested) ~= 'table' then
							rp.requested = { rp.requested }
						end
						
						-- Insert it.
						table.insert(rp.requested, mod_name)
						log_info('Injected %s as request of %s', mod_name, other)
					end
				end
			end
		end
	end
	
	-- List of mods that are (still) available. mod_name => mod_data
	local available_mods = {}
	
	-- Attempts to load said mod
	local function load_mod(name, mod)
		log()
		mod = mod or mods[name]
		
		if not mod then
			log_error('Cannot load mod %q: Not found in mod list.', name)
			return false
		end
		
		if mod.status == LoadingStatus.LOADED then
			return true
		end
		
		-- Failed or skipped mods do not count.
		if mod.status == LoadingStatus.FAILED or mod.status == LoadingStatus.SKIPPED or mod.status == LoadingStatus.CONFLICTED or mod.status == LoadingStatus.DISABLED then
			log_error('Cannot load %q: status is %s', name, tostring(mod.status))
			return false
		elseif mod.status == LoadingStatus.LOADING then
			log_error('Cycle found! Attempted to load %q /again/', name)
			return false
		end
		
		log('Attempting to load %s (source %s)...', name, tostring(mod.source))
		mod.status = LoadingStatus.LOADING
		
		local rpm = mod.manifest.rp
		
		-- Version requirement?
		if tonumber(rpm.required_version) and tonumber(rpm.required_version) > VERSION then
			log_error('Cannot load %q: Required RP version is %d, installed is %d', name, rpm.required_version, VERSION)
			available_mods[name] = nil
			mod.status = LoadingStatus.FAILED
			return false
		end
		
		-- Requirements?
		local requirement = rpm.required
		if requirement then
			log('Parse requirements for %s...', name)
			if type(requirement) ~= 'table' then
				requirement = { requirement }
			end
			
			for k, required in pairs(requirement) do
				log('Attempt to load requirement %s for %s', required, name)
				if not load_mod(required) then
					log_error('Cannot load %q: Required mod %q is missing/not loading/disabled', name, required)
					mod.status = LoadingStatus.FAILED
					available_mods[name] = nil
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
				if not load_mod(requestee) then
					log_info('Requested mod %s for %s not found.', requestee, name)
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
			
			local success_one, success_two = rp.run_safe(_host.require, _host, name .. '.' .. init)
			
			if success_two == nil then
				log_warning('%s reported nil; either the mod is not properly written or there was an error. Check stonehearth.log to be sure.', name)
				success_two = true
			end
			
			if success_one and success_two then
				mod.status = LoadingStatus.LOADED
				log('Successfully loaded %s', name)
				return true
			else
				mod.status = LoadingStatus.FAILED
				available_mods[name] = nil
				log_error('Loading %s failed: %s', name, tostring(success_two))
				return false
			end
		else
			log_info('No init file for %q found.', name)
		end
		
		-- Nothing to load.
		mod.status = LoadingStatus.LOADED
		return true
	end
	
	-- Provide a copy of the mod table that reflects our current status, but does not allow modifying it.
	-- (We don't want others to (accidentally) mess around with the mod loading process.)
	do		
		local all_mods = {}
		-- They both are loaded, kind of.
		mods.radiant.status = LoadingStatus.LOADED
		mods.stonehearth.status = LoadingStatus.LOADED
		
		for k, v in pairs(mods) do
			-- Simple put: Allow reading, disallow changing anything that is present in the original.
			-- Basically, a proxy-table. I've seen read-only tables somewhere else, but they were probably userdata.
			local m = setmetatable({}, { __index = function(_, key) return v[key] end, __newindex = function(_, key, value) if not rawget(v, key) then rawset(_, key, value) end end })
			all_mods[k] = m
			if m.status == LoadingStatus.AVAILABLE or m.status == LoadingStatus.SKIPPED or m.status == LoadingStatus.LOADED then
				available_mods[k] = m
			end
		end

		rp.all_mods, rp.available_mods = all_mods, available_mods
	end
	
	log()
	log("Start loading the mods...")
	log()
	
	for mod_name, data in pairs(mods) do
		log_info('Loading %s returned %s', mod_name, tostring(load_mod(mod_name, data)))
	end
	
	log()
	log("We're past mod loading and all is well.")
end