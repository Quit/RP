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

--[[ Overwriting default behaviour. 
	! Sets io.output: Now set to stonehearth_mod.log instead of ("inaccessible") cout (I guess?). On the server, this is stonehearth_mod(_server).log.
	! print(...): Redirects to use io.output instead. i.e. somewhere visible.
	+ rp.run_safe(func, ...): glorified pcall with error reporting. I guess I could call it prun. As a pun.
	+ rp.require_safe(mod_name): glorified pcall with evil magic to make require work. Or rather, magic so that pcall accepts require.
	+ rp.run_mod(module name): glorified pcall-require with error reporting.
	+ PrintTable(tbl): The naming is Garry's fault, mixed with "I'm too lazy". but alas, have
	+ print_table(tbl) (which is the same).
	+ table.show(tbl, name): Original author see below, used for PrintTable and actually quite handy.
	+ rp.list_mods(): Returns a table containing all mods that are currently available (by directory name)
	+ rp.load_stonehearth_service(servicename): In case you want to require() a service defined in stonehearth, but not exposed by the api.
	
	SERVER ONLY:
	! radiant.entities.create_entity(entName): Can be proxied using function below.
	! api.personal_serivce => api.personal_service
	! api.personal_service.get_new_personality now works past four members /without/ an infinite loop.
	+ rp.set_entity_proxy(oldEntName, newEntName): Instead of creating `oldEntName', an entity of type `newEntName' will be created. If newEntName is a function, it is called and passed oldEntName and its return value should be the new entity name.
	+ rp.is_entity_proxied(entName) returns if entName has been proxied (name of the new entity), returns nil otherwise
	+ rp.add_entity_created_hook(entName, func, ...): calls func(ent, ...) after an entity of type entName has been created, passing the entity first
]]

-- Require base stuff and overwrites that are somewhat independent-ish
require('base')

-- Our ridiculously inflated version
local VERSION = 2701

-- If RP has already been initialized, abort
-- In related news, >:[ this strict thing.
if rawget(_G, 'rp') then
	return rp
end

-- No need to bother strictlua. I feel this is a dirty hack, but then again, what here isn't.
rp = {}
local rp = rp -- err yes.
rp.constants = { VERSION = VERSION } -- We won't have too many constants, but eh.

local function write_to_log(text)
	radiant.log.write_('rploader', 0, text) -- TODO: Replace this with a proper logger once we figured out where they're logging to.
	print('[' .. os.date() .. '] ' .. text)
end

-- Normal logging, similar to print.
function rp.log(...)
	local count = select('#', ...)
	
	if count == 0 then
		print()
	end
	
	local t = { ... } 
	
	for i = 1, count do
		t[i] = tostring(t[i])
	end
	
	write_to_log(table.concat(t, '\t'))
end

-- /advanced/ logging, similar to printf.
function rp.logf(text, ...)
	if not text then
		print()
		return
	end
	
	-- would like lua5.2
	local success, formatted_text = pcall(string.format, text, ...)
	
	if not success then -- format error
		write_to_log(string.format('Invalid call to rp.logf(%q): %s', text, formatted_text))
		write_to_log(debug.traceback(2))
	else
		write_to_log(formatted_text)
	end
end

-- Now we can log.
rp.logf('Initializing RPLoader r%d (is_server %s)', VERSION, tostring(radiant.is_server))

-- Load the config tools.
require('config')

do
	-- And our own config.
	local CONFIG = {
		disabled_mods = {} -- list of disabled mods
	}
	
	-- Set it to rp.CONFIG, the _init files will get rid of it.
	rp.CONFIG = rp.load_config(CONFIG)
end

--[[ Little helpers and extensions.
	rp.run_safe(func, ...): Glorified pcall.
	rp.run_mod(modname): Glorified pcall with module reporting/requiring.
	PrintTable(tbl): Curse you, GMod.
]]
do
	--[[
		I feel like an explanation is necessary for this hack.
		pcall and xpcall set "=[C]" as caller value (and "pcall" as name).
		However, Radiant's implementation is just checking for @ (lua source).
		This means that pcall is treated like loadstring (which isn't really a fix).
		By (temporarily) patching __get_current_module_name, we allow pcall to pass.
		Even in nested environments! Can I get an Hey for nested environments!
	]]
	
	local patch_g_c_m_n, unpatch_g_c_m_n
	do
		local old__g_c_m_n = __get_current_module_name
		local fake_source = {}
		
		local function new__g_c_m_n(depth)
			local info = debug.getinfo(depth, "S")
			if not info.source then
				print("could not determine module file in radiant \"require\"")
				return nil
			end
			
			-- allow pcall to do its dirty require job
			if info.source == '=[C]' and info.name == "pcall" then
				return fake_source[#fake_source]
			end
			
			if info.source:sub(1, 1) ~= "@" then
				print("lua generated from loadstring() is not allowed to require.")
				return nil
			end
			
			local modname = info.source:match("@([^/\\]*)")
			modname = modname or info.source:match("@\\.[/\\]([^/\\]*)")
			if not modname then
				print(string.format("could not determine modname from source \"%s\"", info.source))
				return nil
			end
			return modname
		end
		
		function patch_g_c_m_n()
			-- Get the current source module, which should be... 3?
			table.insert(fake_source, debug.getinfo(3).source)
		
			-- Patch the old function.
			__get_current_module_name = new__g_c_m_n
		end
		
		function unpatch_g_c_m_n()
			__get_current_module_name = old__g_c_m_n
			table.remove(fake_source)
		end
	end
	
	-- run_require(mod_name)
	-- Requires said module and reports which module failed in case it does.
	function rp.require_safe(mod_name)
		rp.logf('Loading mod %q...', mod_name)
		
		local err
		
		patch_g_c_m_n()
		local ret = { xpcall(function() require(mod_name) end, function(ex) return debug.traceback(tostring(ex), 2) end) }
		unpatch_g_c_m_n()
		
		if not ret[1] then
			rp.logf('Error while loading %q: %s', mod_name, ret[2])
			return
		else
			rp.logf('Successfully ran %q', mod_name)
			table.remove(ret, 1)
			return unpack(ret)			
		end
	end
	
	-- run_safe(func, ...)
	-- Similar to pcall, but prints error as they happen. Returns the same thing as pcall otherwise.
	-- It's just for convenience!
	function rp.run_safe(func, ...)
		
		patch_g_c_m_n()
		local err
		local args = { ... }
		-- I want lua5.2. :|
		local ret = { xpcall(function() return func(unpack(args)) end, function(ex) return debug.traceback(tostring(ex), 4) end) }
		unpatch_g_c_m_n()
		
		if not ret[1] then
			rp.logf("run_safe(%s) failed: %s", debug.getinfo(func).short_src, ret[2])
		end
		
		return unpack(ret)
	end
	
	-- Hack. Haaack. Evil hack. OK.
	local function load_stonehearth_thing(name, error_message)
		local success, thing = pcall(_host.require, _host, 'stonehearth.' .. name)
		if not success or not thing then
			rp.logf(error_message, name, tostring(thing))
			return nil
		else
			return thing
		end
	end
	
	
	function rp.load_stonehearth_service(service_name)
		return load_stonehearth_thing('services.' .. service_name, 'Service %q could not be loaded: %s')
	end
	
	function rp.load_stonehearth_call_handler(handler_name)
		return load_stonehearth_thing('call_handlers.' .. handler_name, 'Call handler %q could not be loaded: %s')
	end
	
	-- Returns the best entry per-field, which allows to just define one field per proposal.
	-- While writing this function I realized I have no real use for it yet. Oh well.
	-- For example, calling get_best_proposal(tbl, 'name', 'entity_id') will return
	-- the highest available name and the highest available entity_id, although
	-- both can come from different proposals (if one proposal defined name,
	-- and the other entity_id)
	function rp.get_best_proposal(proposals, ...)
		-- Initialize
		local besties = {}
		for k, v in pairs({ ... }) do
			besties[v] = { priority = -math.huge, value = nil }
		end
		
		-- Go through the proposals
		for _, proposal in pairs(proposals) do
			-- Go through each of the fields we require
			for field, best in pairs(besties) do
				if proposal[field] ~= nil and proposal.priority > best.priority then
					best.priority, best.value = proposal.priority, proposal[field]
				end
			end
		end
		
		-- Reform
		local best = {}
		for k, v in pairs(besties) do
			best[k] = v.value
		end
		
		-- Return.
		return best
	end
end

rp.log('RPLoader initialized.')

return rp