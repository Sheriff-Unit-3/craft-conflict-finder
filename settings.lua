craft_conflict_finder.settings = {}
local settings = craft_conflict_finder.settings

local function get_bool(key, default)
	return core.settings:get_bool(key, default)
end

settings.command_all = get_bool("craft_conflict_finder.command_all", true)
