craft_conflict_finder = {}

local ccf = craft_conflict_finder
local modpath = core.get_modpath(core.get_current_modname())

ccf.MODNAME = core.get_current_modname()
ccf.MODPATH = core.get_modpath(core.get_current_modname())

dofile(modpath .. "/settings.lua")
dofile(modpath .. "/groupimg.lua")
dofile(modpath .. "/logic.lua")
dofile(modpath .. "/ui.lua")
dofile(modpath .. "/commands.lua")
