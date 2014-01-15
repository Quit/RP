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


local boolean_table = 
{
	[0] = false,
	["0"] = false,
	["false"] = false,
	["no"] = false,
	
	[1] = true,
	["1"] = true,
	["true"] =  true,
	["yes"] = true
}

local comfort_table
local function comfort_values(given, default)
	local given_type, default_type = type(given), type(default)
	
	-- Not compatible?
	if given_type ~= default_type then
		if default_type == 'table' then
			return comfort_table({ given }, default)
		elseif default_type == 'string' then
			return tostring(given)
		elseif default_type == 'number' and tonumber(given) then
			return tonumber(given)
		elseif default_type == 'boolean' and boolean_table[given] ~= nil then
			return boolean_table[given]
		else
			return default -- This will already be properly aligned
		end
	end
	
	if default_type == 'table' then
		return comfort_table(given, default)
	end
	
	return given
end

-- compares if all values in "json" are comfortable to "defaultValues"
-- and returns json modified in a way that all values comfort default
-- (i.e. have the same type)
function comfort_table(given, default)
	for key, default_value in pairs(default) do
		local given_value = given[key]
		
		-- json does not define this value: We do it.
		if given_value == nil then
			given[key] = default_value
		else -- json does define this value, validate it
			given[key] = comfort_values(given_value, default_value)
		end
	end
	
	return given
end

-- We could use `radiant.util.get_config` buuuuut
-- since we're wrapping this in a helper class, we kind of can't.
-- This will return the *whole* config table, as seen in `default`.
function rp.load_config(default)
	local mod_name = __get_current_module_name(3)
	
	-- Try to load config/[modname].json
	local json_loaded, json = pcall(radiant.resources.load_json, 'config/' .. mod_name .. '.json')
	
	-- Comfort it to the default values
	json = comfort_values(json or {}, default)
	
	-- Try to load the user settings
	local user_settings = _host:get_config('mods.' .. __get_current_module_name(3))
	
	-- Try to comfort the user_settings to json (which, by now, is our new default)
	if user_settings then
		json = comfort_table(user_settings, json)
	end
	
	return json, json_loaded or user_settings ~= nil
end

function rp.get_config(str, default)
	if type(str) ~= 'string' then
		error("bad argument #1 to 'get_config' (string expected, got " .. type(str) .. ")")
	end
	
	return comfort_values(_host:get_config('mods.' .. __get_current_module_name(3)  .. '.' .. str), default)
end