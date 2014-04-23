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
Adds a few events, with WGS being the world_generation service
QUERY WGS / rp:propose_blueprint_generator { async, seed, proposals } : Propose { priority, generator } to be used to create the world. generator is a function that returns the generator upon being called. The generator should not be created unless this function is called.
EVENT WGS / rp:blueprint_generator_chosen { generator }:  Generator was chosen to create the world; mess around with it *here*
EVENT WGS / rp:world_created { generator }: A world was created using that generator
EVENT WGS / rp:pre_world_creation { service }: Last chance to modify stuff before the world is created.
EVENT WGS / rp:on_world_creation { service }: Before any other event here is called, this is the entry point to modify stuff. For example, _rng. Not recommended.
EVENT WGS / rp:on_initialisation { async, game_seed }: Before initialisation gives mods the chance to modify seed and async state.
]]

-- WGS is a service, i.e. an instantiated object
local WGS = radiant.mods.load('stonehearth').world_generation

local BlueprintGenerator = radiant.mods.require('stonehearth.services.server.world_generation.blueprint_generator')

-- Proposes a new, default generator
local function propose_default_generator(_, event)
	table.insert(event.proposals, { priority = 0, generator = function() return BlueprintGenerator(event.rng) end })
end

-- Hook it up.
radiant.events.listen(WGS, 'rp:propose_blueprint_generator', WGS, propose_default_generator)

-- Overwrite create_world a tiny bit
local old_create_world = WGS.create_world

local old_initialize = WGS.initialize

function WGS:initialize(game_seed, async)
	-- No proposals, I'm mad right now.
	local t = { async = async, game_seed = game_seed }
	radiant.events.trigger(self, 'rp:on_initialisation', t)
	old_initialize(self, t.game_seed, t.async)
	
	radiant.events.trigger(self, 'rp:blueprint_generator_chosen', { generator = self.blueprint_generator })
end

local old_seed = WGS.set_seed
function WGS:set_seed(seed)
	local t = { seed = seed }
	radiant.events.trigger(self, 'rp:set_seed', t)
	return old_seed(self, t.seed)
end

function WGS:create_world()
	-- Call the pre-everything event.
	radiant.events.trigger(self, 'rp:on_world_creation', { service = self })
	
--~ 	local proposals = {}
--~ 	radiant.events.trigger(self, 'rp:propose_blueprint_generator', { rng = self._rng, proposals = proposals })
--~ 	
--~ 	-- Get the best generator.
--~   local wg = rp.get_best_proposal(proposals, 'generator').generator()
	
	-- Set it.
	self._blueprint_generator = wg
	
	-- Last chance to change stuff.
	radiant.events.trigger(self, 'rp:pre_world_creation', { service = self })
	
	-- Call the old function.
  old_create_world(self)
	
	radiant.events.trigger(self, 'rp:world_created', { generator = wg })
	
  return wg
end

--~ local set_blueprint = WGS.set_blueprint
--~ function WGS:set_blueprint(blueprint)
--~ 	print('blueprint: ', blueprint)
--~ 	
--~ 	
--~ 	return set_blueprint(self, blueprint)
--~ end

return true