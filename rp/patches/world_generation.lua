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
Adds a few events, with WGS being the world_generation service; WG = WorldGenerator
QUERY WGS / rp:propose_blueprint_generator { async, seed, proposals } : Propose { priority, generator } to be used to create the world. generator is a function that returns the generator upon being called. The generator should not be created unless this function is called.
EVENT WGS / rp:blueprint_generator_chosen { generator }:  Generator was chosen to create the world; mess around with it *here*
EVENT WGS / rp:world_created { generator }: A world was created using that generator.
]]

-- WGS is a service, i.e. an instantiated object
local WGS = radiant.mods.load('stonehearth').world_generation

local BlueprintGenerator = radiant.mods.require('stonehearth.services.world_generation.blueprint_generator')

-- Proposes a new, default generator
local function propose_default_generator(_, event)
	table.insert(event.proposals, { priority = 0, generator = function() return BlueprintGenerator(event.rng) end })
end

-- Hook it up.
radiant.events.listen(WGS, 'rp:propose_blueprint_generator', WGS, propose_default_generator)

-- Overwrite create_world a tiny bit
local old_create_world = WGS.create_world

function WGS:create_world()
	local proposals = {}
	radiant.events.trigger(self, 'rp:propose_blueprint_generator', { rng = self._rng, proposals = proposals })
	
	-- Get the best generator.
  local wg = rp.get_best_proposal(proposals, 'generator').generator()
	
	-- Allow mods to modify said generator.
	radiant.events.trigger(self, 'rp:blueprint_generator_chosen', { generator = wg })
	
	-- Set it.
	self._blueprint_generator = wg
	
	-- Call the old function.
  old_create_world(self)
	
	radiant.events.trigger(self, 'rp:world_created', { generator = wg })
	
  return wg
end

return true