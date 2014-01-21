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
- Adds a new config entry that may be defined called "unmovable". If set to true, the component cannot be moved once placed.
]]

local PIP = rp.load_stonehearth_component('place_item.placeable_item_proxy')

local old_extend = PIP.extend

function PIP:extend(json)
	if json then
		self._rp_unmovable = json.unmovable
	end
	
	return old_extend(self, json)
end

function PIP:_create_full_sized_entity()
  self._full_sized_entity = radiant.entities.create_entity(self._data.full_sized_entity_uri)
	
	-- If we can be moved
	if not self._rp_unmovable then
		self._full_sized_entity:add_component("stonehearth:placed_item"):set_proxy(self._entity)
	end
	
  local proxy_faction = radiant.entities.get_faction(self._entity)
  self._full_sized_entity:add_component("unit_info"):set_faction(proxy_faction)
end

return true