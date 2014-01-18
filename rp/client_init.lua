local rp = require('api')
-- Load our mods.
local LM = require('load_mods')
local lm = LM()
rp.CONFIG = nil
-- Load the mods
lm:load_mods()