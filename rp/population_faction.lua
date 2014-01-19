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

--[[
Add a few events:
QUERY faction / stonehearth:propose_citizen_name { gender = .., proposals = {} }: Allows mods to propose a name { name = ..., priority = ... }; the highest priority one wins.
EVENT radiant.events / stonehearth:faction_created { faction = ..., kingdom = ... }: Fired whenever this faction is first created
]]

local faction = rp.load_stonehearth_service('population.population_faction')

-- Patch the initialiser
local old_init = faction.__user_init

function faction:__user_init(faction, kingdom, ...)
	-- Call the old constructor
	local ret = { old_init(self, faction, kingdom, ...) }
	
	-- Subscribe to... ourselves.
	radiant.events.listen(self, 'stonehearth:propose_citizen_name', self, self._rp_propose_default_name)
	
	-- Fire an event that declares this faction as initialised
	radiant.events.trigger(radiant.events, 'stonehearth:faction_created', { faction = faction, kingdom = kingdom, object = self })
	
	-- In case we had any return values, return them now. I don't think this will ever happen but hey safe programming or something.
	return unpack(ret)
end

-- Save the old generator
faction._rp_default_name_generator = faction.generate_random_name

-- Propose a default name with priority 0
function faction:_rp_propose_default_name(event)
	table.insert(event.proposals, { priority = 0, name = self:_rp_default_name_generator(event.gender) })
end

-- Fires an event to request name proposals; picks the higehst priority one
function faction:generate_random_name(gender)
	-- Create our request table
	local proposals = {}
	local t = { gender = gender, proposals = proposals }
	radiant.events.trigger(self, 'stonehearth:propose_citizen_name', t)
	
	-- Get the first entry already
	local best = t.proposals[1]
	local c = #proposals
	
	-- Search for a higher priority
	for i = 2, c do
		if proposals[i].priority > best.priority then
			best = proposals[i]
		end
	end
	
	-- Return the best priority's proposal
	return best.name
end

return true