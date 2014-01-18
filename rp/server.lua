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

-- For the real server, see waaay below

-- * radiant.entities.create_entity proxy,
-- + rp.set_entity_proxy(oldEnt, newEnt): Will instead of creating oldEnt create an entity of type newEnt. If newEnt is a func, it is to return the new entity name as string and will have the old entity name as first parameter
-- + rp.is_entity_proxied(entName): Return the string that entName has been proxied with (or nil)

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
	local old_create = radiant.entities.create_entity
	assert(type(old_create) == 'function')
	
	local proxy_table = {}
	
	function radiant.entities.create_entity(entity_name)
		local proxy = proxy_table[entity_name]
		
		-- Proxied?
		if proxy then
			-- If proxy is a function, call it and pass the original entName
			if type(proxy) == 'function' then
				local succ, new_name = pcall(proxy, entity_name)
				if not succ then
					rp.logf('Entity Creation proxy for %q (%s) failed: %s', entity_name, debug.getinfo(proxy).short_src, new_name)
					proxy = nil
				else
					-- Make sure it's a string.
					if type(new_name) ~= 'string' then
						rp.logf('Entity Creation proxy for %q (%s) failed: expected string as return value, but got %s', entity_name, debug.getinfo(proxy).short_src, type(new_name))
						proxy = nil
					else
						proxy = new_name
					end
				end
			end
		end
		
		-- Create the entity already.
		local ent = old_create(proxy or entity_name)
		
		-- Fire two events - one for the original class, one for the proxy.
		for _, id in pairs({ entity_name, proxy }) do
			if id then
				radiant.events.trigger(radiant.events, 'stonehearth:entity_created', {
					entity = ent, -- Entity that was spawned
					entity_id = id,
					original_entity_id = entity_name,
					proxy_entity_id = proxy
				})
			end
		end

		return ent
	end
	
	function rp.set_entity_proxy(old_name, new_name)
		local t = type(new_name)
		if t ~= 'string' and t ~= 'function' then
			error("bad argument #2 to 'set_entity_proxy' (function or string expected, got " .. type(new_name) .. ")")
		end
		
		proxy_table[old_name] = new_name
	end
	
	function rp.is_entity_proxied(entity_name)
		return proxy_table[entity_name]
	end
end

-- This is a kind-of-persistent-service-like-timey-wimey-thingy
local LM = require('load_mods')

local lm_service = LM()

local Server = class()

-- radiant.call('rp:log_server', [args ...])
function Server:log_server(session, response, ...)
	-- The bindings work too well.
	local t = { ... }

	local count = select('#', ...)	
	for i = 1, count do
		t[i] = tostring(t[i])
	end
	
	rp.log('[JS] ' .. table.concat(t, '\t'))
	
	response:resolve(true)
end

-- Returns the mod loader's data store
function Server:get_lm_data_store(session, response)
	return { data = lm_service:get_data_store() }
end

function Server:_load_mods(session, response)
	radiant.create_background_task('RP Mod Loading', function() lm_service:load_mods() end)
end

return Server