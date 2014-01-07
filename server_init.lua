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

local rp = require('api')
local CONFIG = rp.CONFIG

-- * radiant.entities.create_entity proxy,
-- + rp.set_entity_proxy(oldEnt, newEnt): Will instead of creating oldEnt create an entity of type newEnt. If newEnt is a func, it is to return the new entity name as string and will have the old entity name as first parameter
-- + rp.is_entity_proxied(entName): Return the string that entName has been proxied with (or nil)
-- + rp.add_entity_created_hook(entName, func, ...): called whenever an entity of this type is created

do --[[ server sided lua fixes ]]
	-- Madames, Monsieurs de l'enterprise Radiant,
	-- Il n'est pas "serivce", c'est "service"
	-- xôxô EncorePoêle
	local api = radiant.mods.load('stonehearth')
	if api.personality_serivce then
		api.personality_service = api.personality_serivce
	end
end

-- create_entity and proxy friends
do
	local oldCreate = radiant.entities.create_entity
	assert(type(oldCreate) == 'function')
	
	local proxyTable = {}
	local postCreationHooks = {}
	
	local function callHook(func, args)
		func(unpack(args))
	end
	
	function radiant.entities.create_entity(entName)
		local proxy = proxyTable[entName]
		
		-- Proxied?
		if proxy then
			-- If proxy is a function, call it and pass the original entName
			if type(proxy) == 'function' then
				local succ, newName = pcall(proxy, entName)
				if not succ then
					rp.logf('Entity Creation proxy for %q (%s) failed: %s', entName, debug.getinfo(proxy).short_src, newName)
				else
					-- Make sure it's a string.
					if type(newName) ~= 'string' then
						rp.logf('Entity Creation proxy for %q (%s) failed: expected string as return value, but got %s', entName, debug.getinfo(proxy).short_src, type(newName))
					else
						entName = newName
					end
				end
			-- Otherwise, use it as a literal
			else
				entName = proxy
			end
		end
		
		-- Create the entity already.
		local ent = oldCreate(entName)
		
		-- Do we have to call hooks on this?
		local hooks = postCreationHooks[entName]
		
		if hooks then
			for k, v in pairs(hooks) do
				local succ, err = pcall(k, ent, unpack(v))
				if not succ then
					printf("Hook %s for %s failed: %s", tostring(debug.getinfo(k).short_src), entName, err)
				end
			end
		end
		
		return ent
	end
	
	function rp.set_entity_proxy(oldName, newName)
		local t = type(newName)
		if t ~= 'string' and t ~= 'function' then
			error("bad argument #2 to 'set_entity_proxy' (function or string expected, got " .. type(newName) .. ")")
		end
		
		proxyTable[oldName] = newName
	end
	
	function rp.is_entity_proxied(entName)
		return proxyTable[entName]
	end
	
	function rp.add_entity_created_hook(entName, func, ...)
		if type(func) ~= 'function' then
			error("bad argument #2 to 'add_entity_created_hook' (function expected, got " .. type(func) .. ")")
		end
		
		if not postCreationHooks[entName] then
			postCreationHooks[entName] = {}
		end
		
		postCreationHooks[entName][func] = { ... }
	end
end

-- Now, load the mods!
require('load_mods')
-- Delete the config.
rp.CONFIG = nil
rp.load_mods()