local rp = require('api')
-- Load our mods.
local LM = require('load_mods')
local lm = LM(false) -- we don't require an object (nor could we get one I think)
rp.CONFIG = nil
-- Load the mods
lm:load_mods()