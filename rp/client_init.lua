local rp = require('api')
-- Load our mods.
local LM = require('load_mods')
local lm = LM()
rp.CONFIG = nil

-- HAAACKS
local client = _radiant.client

local old_capture_input = client.capture_input
rp.keyboard_input_disabled = false

local function patch_on_input(input_capture)
	local on_input = input_capture.on_input
	
	function input_capture:on_input(callback)
		return on_input(self, 
			function(event, ...)
				if event.type == client.Input.KEYBOARD and rp.keyboard_input_disabled then
					return true
				end
				return callback(event, ...)
			end
			)
	end
end

function client.capture_input(...)
	local ret = old_capture_input(...)
	
	patch_on_input(ret)
	return ret
end

local old_is_key_down = client.is_key_down
function client.is_key_down(key)
	if rp.keyboard_input_disabled then
		return false
	end
	
	return old_is_key_down(key)
end

-- Load the mods
lm:load_mods()
