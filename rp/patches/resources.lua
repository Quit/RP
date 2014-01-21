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
EVENT radiant.events / stonehearth:plant_marked_for_harvesting { entity }: Fired after a plant has been marked for harvesting.
EVENT stonehearth:renewable_resource_node (component) / stonehearth:resource_spawned {}: Fired after a resource was spawned (i.e. 1 harvesting occured)
]]

local RCH = rp.load_stonehearth_call_handler('resource_call_handler')

local old_harvest_plant = RCH.harvest_plant

function RCH:harvest_plant(session, response, plant, ...)
	local ret = { old_harvest_plant(self, session, response, plant, ...) }
	
	-- TODO: Attach this to some sort of service instead of radiant.events
	radiant.events.trigger(radiant.events, 'stonehearth:plant_marked_for_harvesting', { entity = plant })
	
	return unpack(ret)
end

local RRNC = rp.load_stonehearth_component('renewable_resource_node.renewable_resource_node')
local old_spawn_resource = RRNC.spawn_resource

function RRNC:spawn_resource(location, ...)
	local ret = { old_spawn_resource(self, ...) }
	
	radiant.events.trigger(self, 'stonehearth:resource_spawned', {})
	
	return unpack(ret)
end

return true