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
	You can use it to load json files and provide default values in case
	the user has not set them or they are invalid (i.e. unmatching type).
	This simply returns the handy function to parse configs.
]]

-- compares if all values in "json" are comfortable to "defaultValues"
-- and returns json modified in a way that all values comfort default
-- (i.e. have the same type)
local function comfortJson(json, default)
	for key, vDefault in pairs(default) do
		local vJson = json[key]
		
		-- json does not define this value: We do it.
		if not vJson then
			json[key] = vDefault
		else -- json does define this value, validate it
			local tJson, tDefault = type(vJson), type(vDefault)

			-- Different types?
			if tJson ~= tDefault then
				-- Try to fix it?
				if tDefault == 'table' then
					vJson = { vJson } -- other languages would call this... boxing! hahaha!
				elseif tDefault == 'string' then -- lua has some nasty things for strings.
					vJson = tostring(vJson)
				elseif tDefault == 'number' and tonumber(vJson) then -- json does check for this, but we're just humans
					vJson = tonumber(vJson)
				else -- Nope, we can't save it. It's something really odd.
					vJson = vDefault
				end
				
				json[key] = vJson -- now comfy?
			end
			
			-- Is it necessary to sub-validate this table?
			if tDefault == 'table' then
				json[key] = comfortJson(vJson, vDefault) -- I guess we could do this iterative, but I doubt anyone is going to stack config levels. Or causes cycles.
			end
		end
	end
	
	return json
end

return function(jsonUri, default)
	-- Try to load the json.
	local success, json = pcall(radiant.resources.load_json, jsonUri)
	
	-- If we can't load it, skip
	if not success or not json then
		return false, default
	end
	
	-- Return the validated json
	return true, comfortJson(json, default)
end