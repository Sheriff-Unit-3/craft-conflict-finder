craft_conflict_finder = {}

craft_conflict_finder.MODNAME = core.get_current_modname() or "craft_conflict_finder"
craft_conflict_finder.MODPATH = core.get_modpath(craft_conflict_finder.MODNAME)

dofile(craft_conflict_finder.MODPATH .. "/settings.lua")
dofile(craft_conflict_finder.MODPATH .. "/groupimg.lua")
dofile(craft_conflict_finder.MODPATH .. "/logic.lua")
dofile(craft_conflict_finder.MODPATH .. "/commands.lua")
