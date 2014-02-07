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
QUERY faction / rp:propose_citizen_name { gender = .., proposals = {} }: Allows mods to propose a name { name = ..., priority = ... }; the highest priority one wins.
EVENT radiant.events / rp:faction_created { faction = ..., kingdom = ... }: Fired whenever this faction is first created
QUERY faction / rp:propose_citizen_gender { proposals = {} }: Allows mods to specify a gender for a newly created citizen. Weird balancing tricks go here. { gender = ..., priority = ... }
QUERY faction / rp:propose_citizen_kind { gender = ..., proposals = {} }: Allow mods to specify a certain model for a newly created citizen { entity_id = ..., priority = ... }
EVENT faction / rp:citizen_created { gender = ..., entity_id = ..., object = ... }: Fired when a citizen was created using these arguments
]]

local faction = rp.load_stonehearth_service('population.population_faction')

-- Patch the initialiser
local old_init = faction.__user_init

function faction:__user_init(faction, kingdom, ...)
	-- Call the old constructor
	local ret = { old_init(self, faction, kingdom, ...) }
	
	-- Subscribe to... ourselves.
	radiant.events.listen(self, 'rp:propose_citizen_name', self, self._rp_propose_default_citizen_name)
	radiant.events.listen(self, 'rp:propose_citizen_gender', self, self._rp_propose_default_citizen_gender)
	radiant.events.listen(self, 'rp:propose_citizen_kind', self, self._rp_propose_default_citizen_kind)
	
	-- Fire an event that declares this faction as initialised
	radiant.events.trigger(radiant.events, 'rp:faction_created', { faction = faction, kingdom = kingdom, object = self })
	
	-- In case we had any return values, return them now. I don't think this will ever happen but hey safe programming or something.
	return unpack(ret)
end

-- Save the old generator
faction._rp_default_name_generator = faction.generate_random_name

-- Propose a default name with priority 0
function faction:_rp_propose_default_citizen_name(event)
	local name = self:_rp_default_name_generator(event.gender)
	
	table.insert(event.proposals, { priority = 0, name = name })
end

function faction:_rp_propose_default_citizen_gender(event)
	local gender
	
  if not self._always_one_girl_hack then
    gender = "female"
    self._always_one_girl_hack = true
  elseif math.random(1, 2) == 1 then
    gender = "male"
  else
    gender = "female"
  end
	
	table.insert(event.proposals, { priority = 0, gender = gender })
end

function faction:_rp_propose_default_citizen_kind(event)
	local entities = self._data[event.gender .. "_entities"]
  local kind = entities[math.random(#entities)]
	
	table.insert(event.proposals, { priority = 0, entity_id = kind })
end

-- Fires an event to request name proposals; picks the higehst priority one
function faction:generate_random_name(gender)
	-- Create our request table
	local proposals = {}
	radiant.events.trigger(self, 'rp:propose_citizen_name', { gender = gender, proposals = proposals })
	
	-- Return the best's proposal.
	return rp.get_best_proposal(proposals, 'name').name
end

-- Fires so many requests and events it's hard to believe
function faction:create_new_citizen()
	-- Get the gender.
  local proposals = {}
	
	radiant.events.trigger(self, 'rp:propose_citizen_gender', { proposals = proposals })

	local gender = rp.get_best_proposal(proposals, 'gender').gender
	
	-- Get the entity kind
	proposals = {}
	radiant.events.trigger(self, 'rp:propose_citizen_kind', { gender = gender, proposals = proposals })
	
	local kind = rp.get_best_proposal(proposals, 'entity_id').entity_id

	-- Create the citizen using the data we've collected
  local citizen = radiant.entities.create_entity(kind)
	
	-- Set it up.
  citizen:add_component("unit_info"):set_faction(self._faction_name)
  self:_set_citizen_initial_state(citizen, gender)
	
	-- Trigger a post-creation event
	radiant.events.trigger(self, "rp:citizen_created", { gender = gender, entity_id = kind, object = citizen })
	
	-- Insert it into our table.
	table.insert(self._citizens, citizen)
	
	-- Return said citizen.
  return citizen
end

return true