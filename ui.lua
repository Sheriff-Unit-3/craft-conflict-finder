local ccf = craft_conflict_finder
ccf.ui = {}
local elem = respec.elements

--------------------------------
-- Common
--------------------------------

local function get_craft_grid_elements(recipe, w, h)
	local spacing = 0.05
	local iw = w / 3 - spacing
	local ih = h / 3 - spacing
	local res = {}
	for y = 1, 3 do
		for x = 1, 3 do
			local recipeEntry = recipe[(y - 1) * 3 + x]
			if recipeEntry ~= nil then
				local itemAndGrpInfo = ccf.get_item_for_group_or_item(recipeEntry)
				local tooltip
				if itemAndGrpInfo.isGroup then
					tooltip = recipeEntry
				else
					tooltip = ItemStack(itemAndGrpInfo.item):get_description()
				end

				local elemId = "cgimg_" .. x .. y
				local def = { id = elemId, w = iw, h = ih, item = itemAndGrpInfo.item, tooltip = tooltip }

				if y == 1 then
					def.alignTop = true
				else
					def.below = "cgimg_1" .. (y - 1)
				end
				if x > 1 then
					def.after = "cgimg_" .. (x - 1) .. y
				end
				if x < 3 then
					def.marginEnd = spacing
				end
				if y < 3 then
					def.marginBottom = spacing
				end

				res[#res + 1] = elem.ItemButton(def)
				if itemAndGrpInfo.isGroup then
					res[#res + 1] = elem.Label({
						text = "G",
						centerHor = elemId,
						centerVer = elemId,
					})
				end
			end -- end nil check of recipeEntry
		end
	end
	return res
end

--------------------------------
-- Conflicts pages UI
--------------------------------
local NUM_CONFLICT_ICONS_PER_ROW = 7
local CONFLICT_ICON_SIZE = 1
local CONFLCIT_ICON_SPACING = 0.2
local CONFLICT_CONTAINER_W = NUM_CONFLICT_ICONS_PER_ROW * CONFLICT_ICON_SIZE
	+ (NUM_CONFLICT_ICONS_PER_ROW - 1) * CONFLCIT_ICON_SPACING

local STATE_FILTER_TEXT = "filtxt"
local STATE_RECIPE_IDX = "recidx"

local function get_conflicts_page(state)
	local tabIndex = state.tabIndex
	local conflictsTable
	if tabIndex == 1 then
		conflictsTable = ccf.get_all_shaped_conflics()
	elseif tabIndex == 2 then
		conflictsTable = ccf.get_all_shapeless_conflics()
	elseif tabIndex == 3 then
		conflictsTable = ccf.get_all_cook_conflics()
	else
		return {}
	end

	local filterText = state[STATE_FILTER_TEXT .. tabIndex] or ""

	local entires = {}
	local lastId = ""
	local recipeIndex = state[STATE_RECIPE_IDX .. tabIndex] or 0
	local rowCounter = 1
	for i, oneConflictTable in ipairs(conflictsTable) do
		local oneConflictEntires = {}
		local recBtnDef = {
			id = "confrecbtn" .. i,
			w = 6,
			h = 0.6,
			text = "See Recipe for Item Conflicts " .. i,
			marginTop = 0.3,
			marginStart = 0.2,
			marginBottom = 0.1,
			onClick = function(ss, _)
				ss[STATE_RECIPE_IDX .. tabIndex] = i
			end,
		}
		if lastId == "" then
			recBtnDef.toTop = true
		else
			recBtnDef.below = lastId
		end

		oneConflictEntires[#oneConflictEntires + 1] = elem.Button(recBtnDef)
		local tmpLastId = recBtnDef.id

		local addThisConflictEntries = filterText == ""
		for j, itemStack in ipairs(oneConflictTable) do
			if not addThisConflictEntries then
				addThisConflictEntries = itemStack:to_string():find(filterText) ~= nil
					or itemStack:get_description():find(filterText) ~= nil
			end
			local itemImgDef = {
				id = "confimg" .. i .. "_" .. j,
				w = CONFLICT_ICON_SIZE,
				h = CONFLICT_ICON_SIZE,
				marginBottom = CONFLCIT_ICON_SPACING,
				marginStart = CONFLCIT_ICON_SPACING,
				item = itemStack:to_string(),
				tooltip = itemStack:get_name() .. "\n\n" .. itemStack:get_description(),
			}
			local row = math.floor(j / NUM_CONFLICT_ICONS_PER_ROW)
			local col = math.fmod(j, NUM_CONFLICT_ICONS_PER_ROW)
			if row == 0 then
				itemImgDef.below = recBtnDef.id
			else
				itemImgDef.below = "confimg" .. i .. "_" .. (j - NUM_CONFLICT_ICONS_PER_ROW + 1)
			end
			if col > 1 then
				itemImgDef.after = "confimg" .. i .. "_" .. (col - 1)
			end
			tmpLastId = itemImgDef.id
			oneConflictEntires[#oneConflictEntires + 1] = elem.ItemImage(itemImgDef)
		end
		if addThisConflictEntries then
			local boxColor = "#3A3A3F"
			if math.fmod(rowCounter, 2) == 1 then
				boxColor = "#2F2A2F"
			end
			local boxDef = {
				toStart = true,
				toEnd = true,
				alignTop = recBtnDef.id,
				alignBottom = tmpLastId,
				color = boxColor,
			}
			entires[#entires + 1] = elem.Box(boxDef)
			table.insert_all(entires, oneConflictEntires)
			lastId = tmpLastId
			rowCounter = rowCounter + 1
		end
	end

	local typetxt = "Shaped Crafting"
	if tabIndex == 2 then
		typetxt = "Shapeless Crafting"
	elseif tabIndex == 3 then
		typetxt = "Cooking"
	end
	local ret = {
		elem.Label({
			marginStart = 0.5,
			marginTop = 0.2,
			text = "Groups of " .. typetxt .. " items that have the same crafting recipe",
		}),
		elem.ScrollContainer({
			id = "conflcont",
			w = CONFLICT_CONTAINER_W,
			h = 11,
			toTop = true,
			toStart = true,
			marginTop = 1,
			elements = entires,
			pixelBorder = "#222222",
		}),
		elem.Field({
			id = "fieldfilter",
			below = "conflcont",
			marginStart = 0.2,
			label = "Search for conflict items",
			text = filterText,
			closeOnEnter = false,
			w = 4,
			h = 0.8,
			listener = function(ss, value, fields)
				if not fields["clearfilter"] then
					ss[STATE_FILTER_TEXT .. ss.tabIndex] = value
				end
			end,
		}),
		elem.Button({
			id = "clearfilter",
			w = 0.8,
			h = 0.8,
			after = "fieldfilter",
			alignBottom = "fieldfilter",
			text = "X",
			tooltip = "Clear Search",
			onClick = function(ss, _)
				ss[STATE_FILTER_TEXT .. ss.tabIndex] = nil
				return true
			end,
		}),
	}
	local recipeSize = 4
	if recipeIndex > 0 and conflictsTable[recipeIndex] and conflictsTable[recipeIndex].recipe then
		ret[#ret + 1] = elem.Label({
			id = "confrectitle",
			alignStart = "crftcon",
			marginTop = 2.5,
			marginStart = 0.2,
			marginBottom = 0.2,
			text = "Recipe for group " .. recipeIndex,
		})
		ret[#ret + 1] = elem.Container({
			w = recipeSize,
			h = recipeSize,
			id = "crftcon",
			pixelBorder = "#AAAACA",
			after = "conflcont",
			below = "confrectitle",
			toEnd = true,
			marginStart = 0.2,
			elements = get_craft_grid_elements(conflictsTable[recipeIndex].recipe, recipeSize, recipeSize),
		})
	end

	return ret
end

--------------------------------
-- Common ui
--------------------------------

local function get_page_content(state)
	return get_conflicts_page(state)
end

-- Form
local exchangerForm = respec.Form({
	ver = 3,
	w = 14,
	h = 13.5,
	paddings = { before = 0.25, after = 0.25, above = 0, below = 0.25 },
	reshowOnInteract = true,
}, function(istate)
	if istate.tabIndex == nil then
		istate.tabIndex = 1
	end
	local def = {
		elem.ListColors({
			target = "list",
			slotBg = "#555555",
			slotBorder = "#222222",
			slotBgHover = "#888888",
		}),
		elem.Tabs({
			id = "tabs",
			items = { "Shaped Craft Conflicts", "Shapeless Conflicts", "Cook Conflicts" },
			index = istate.tabIndex,
			listener = function(s, v, f)
				s.tabIndex = tonumber(v) or 1
				return true
			end,
		}),
	}
	local content = get_page_content(istate)
	table.insert_all(def, content)
	return def
end)

--------------------------------
-- Public Functions
--------------------------------

function ccf.ui.formspec()
	return exchangerForm
end
