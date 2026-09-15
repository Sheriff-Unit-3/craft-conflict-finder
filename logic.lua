local shapedCraftConflicts = {}
local shapelessCraftConflicts = {}
local cookConflicts = {}

--[[
  swappable tables format:
  item_name = {
    input = ItemStack,
    outputs = { ItemStack, ItemStack, ItemStack }
  }
--]]

local swappableShaped = {}
local swappableShapeless = {}
local swappableCook = {}

-- needed because aliases exist and can be used in recipes
local function get_actual_name(itemName)
	return ItemStack(itemName):to_string()
end

----------------------------------------------------------------
-- Recipe processing
----------------------------------------------------------------

local function pad_and_compact_recipe_items(recipeItems, recipeWidth)
	local newItems = {}

	-- replace nil entires with empty string
	if recipeWidth == 1 then
		newItems[1] = recipeItems[1]
		newItems[4] = recipeItems[2]
		newItems[7] = recipeItems[3]
	elseif recipeWidth == 2 then
		newItems[1] = recipeItems[1]
		newItems[2] = recipeItems[2]
		newItems[4] = recipeItems[3]
		newItems[5] = recipeItems[4]
		newItems[7] = recipeItems[5]
		newItems[8] = recipeItems[6]
	else
		for i = 1, 9 do
			newItems[i] = recipeItems[i]
		end
	end

	-- fill in missing pieces and actual names
	for i = 1, 9 do
		if newItems[i] == nil then
			newItems[i] = ""
		else
			newItems[i] = get_actual_name(newItems[i])
		end
	end

	-- compact empty rows
	if newItems[1] == "" and newItems[2] == "" and newItems[3] == "" then
		if newItems[4] == "" and newItems[5] == "" and newItems[6] == "" then
			-- two empty rows
			newItems[1] = newItems[7]
			newItems[2] = newItems[8]
			newItems[3] = newItems[9]
			newItems[7] = ""
			newItems[8] = ""
			newItems[9] = ""
		else
			-- one empty row
			newItems[1] = newItems[4]
			newItems[2] = newItems[5]
			newItems[3] = newItems[6]
			newItems[4] = newItems[7]
			newItems[5] = newItems[8]
			newItems[6] = newItems[9]
			newItems[7] = ""
			newItems[8] = ""
			newItems[9] = ""
		end
	end
	-- compact empty columns
	if newItems[1] == "" and newItems[4] == "" and newItems[7] == "" then
		if newItems[2] == "" and newItems[5] == "" and newItems[8] == "" then
			-- two empty columns
			newItems[1] = newItems[3]
			newItems[4] = newItems[6]
			newItems[7] = newItems[9]
			newItems[3] = ""
			newItems[6] = ""
			newItems[9] = ""
		else
			-- one empty column
			newItems[1] = newItems[2]
			newItems[4] = newItems[5]
			newItems[7] = newItems[8]
			newItems[2] = newItems[3]
			newItems[5] = newItems[6]
			newItems[8] = newItems[9]
			newItems[3] = ""
			newItems[6] = ""
			newItems[9] = ""
		end
	end

	return newItems
end

-- returns a single string value as the key, where items are separated by |
local function make_shapeless_recipe_key(recipe)
	local items = {}
	for _, item in ipairs(recipe) do
		table.insert(items, item)
	end
	table.sort(items)
	return table.concat(items, "|")
end

local function make_width_recipe_key(recipe, width)
	local items = {}
	for _, item in ipairs(recipe) do
		table.insert(items, item or "")
	end
	return "" .. width .. "|" .. table.concat(items, "|")
end

local function append_if_not_present(list, item)
	for _, v in ipairs(list) do
		if v == item then
			return
		end
	end
	table.insert(list, item)
end

local function process_shaped_recipe(itemName, itemRecipe, itemRecipeWidth)
	itemRecipeWidth = itemRecipeWidth or 3
	local newShapedKey = make_width_recipe_key(itemRecipe, itemRecipeWidth)
	if shapedCraftConflicts[newShapedKey] ~= nil then
		-- conflicted detected, just add it to that recipes list of outputs
		append_if_not_present(shapedCraftConflicts[newShapedKey], itemName)
		return
	end
	-- if we got here, it's not a conflict recipe (yet), add new entry
	shapedCraftConflicts[newShapedKey] = { itemName }
	shapedCraftConflicts[newShapedKey].recipe = itemRecipe
end

local function process_shapeless_recipe(itemName, itemRecipe)
	local newShapelessKey = make_shapeless_recipe_key(itemRecipe)
	if shapelessCraftConflicts[newShapelessKey] ~= nil then
		-- conflicted detected, just add it to that recipes list of outputs
		append_if_not_present(shapelessCraftConflicts[newShapelessKey], itemName)
		return
	end
	-- if we got here, it's not a conflict recipe (yet), add new entry
	shapelessCraftConflicts[newShapelessKey] = { itemName }
	shapelessCraftConflicts[newShapelessKey].recipe = itemRecipe
end

local function process_cook_recipe(itemName, itemRecipe)
	local newCookKey = make_width_recipe_key(itemRecipe, 1)
	if cookConflicts[newCookKey] ~= nil then
		-- conflicted detected, just add it to that recipes list of outputs
		append_if_not_present(cookConflicts[newCookKey], itemName)
		return
	end
	-- if we got here, it's not a conflict recipe (yet), add new entry
	cookConflicts[newCookKey] = { itemName }
	cookConflicts[newCookKey].recipe = itemRecipe
end

local function process_recipe_for(itemName, recipe)
	if type(recipe) ~= "table" or not recipe.method or recipe.method == "fuel" then
		return
	end
	if recipe.output == "" then
		return
	end

	if recipe.method == "normal" then
		if recipe.width > 0 then
			local paddedItems = pad_and_compact_recipe_items(recipe.items, recipe.width)
			process_shaped_recipe(get_actual_name(recipe.output), paddedItems, 3) -- width always 3 due to our padding
		else
			process_shapeless_recipe(get_actual_name(recipe.output), recipe.items)
		end
	elseif recipe.method == "cooking" then
		process_cook_recipe(recipe.output, recipe.items)
	end
end

----------------------------------------------------------------
-- creating swappable tables
----------------------------------------------------------------

local function make_itemstack_list_from_items(items)
	local ret = {}
	for _, itemName in ipairs(items) do
		ret[#ret + 1] = ItemStack(itemName)
	end
	return ret
end

local function compile_swappable_table_and_get_trimmed(swappableTable, conlictsTable)
	local trimmedConflictsTable = {}
	for _, items in pairs(conlictsTable) do
		if #items > 1 then
			local itemstackList = make_itemstack_list_from_items(items)
			itemstackList.recipe = items.recipe
			trimmedConflictsTable[#trimmedConflictsTable + 1] = itemstackList
			for _, itemstack in ipairs(itemstackList) do
				if swappableTable[itemstack:get_name()] == nil then
					swappableTable[itemstack:get_name()] = {}
				end
				table.insert(swappableTable[itemstack:get_name()], itemstackList)
			end
		end
	end
	return trimmedConflictsTable
end

local function compile_swappable_tables_and_trim_conflicts()
	shapedCraftConflicts = compile_swappable_table_and_get_trimmed(swappableShaped, shapedCraftConflicts)
	shapelessCraftConflicts = compile_swappable_table_and_get_trimmed(swappableShapeless, shapelessCraftConflicts)
	cookConflicts = compile_swappable_table_and_get_trimmed(swappableCook, cookConflicts)
end

local function add_swapple_entry_into(swapTableOfTables, itemName, outputTable)
	for _, swapTable in ipairs(swapTableOfTables) do
		local result = {}
		local exchanges = {}
		for _, itemstack in ipairs(swapTable) do
			result.recipe = swapTable.recipe
			if itemstack:get_name() ~= itemName then
				exchanges[#exchanges + 1] = itemstack
			else
				result.input = itemstack
			end
		end
		result.exchanges = exchanges
		outputTable[#outputTable + 1] = result
	end
end

-- registration of callback

core.register_on_mods_loaded(function()
	for itemName, _ in pairs(core.registered_items) do
		local recipes = core.get_all_craft_recipes(itemName)
		if type(recipes) == "table" then
			for _, recipe in ipairs(recipes) do
				process_recipe_for(itemName, recipe)
			end
		end
	end
	compile_swappable_tables_and_trim_conflicts()

	-- core.after(10, function()
	--   core.debug("shaped conflicts = "..dump(swappableShaped))
	--   core.debug("shapeless conflicts = "..dump(swappableShapeless))
	--   core.debug("cook conflicts = "..dump(swappableCook))
	-- end)
end)

----------------------------------------------------------------
-- public functions
----------------------------------------------------------------

--[[ Returns a naturally indexed list of tables, each entry is:
```
  {
    recipe = {"", "", "" ...} -- 9 strings representing the recipe of the exchange item
    exchanges = {ItemStack, ItemStack}, -- list of items that can be exchanged
    input = ItemStack, -- the itemstack (with count) that needs to be taken to exchange
  }
```
if no entries are present, then no swappable items exist
]]
function craft_conflict_finder.get_swappable_items_for(itemStack)
	local itemName = itemStack:get_name()
	local shapedSwaps = swappableShaped[itemName] or {}
	local shapelessSwaps = swappableShapeless[itemName] or {}
	local cookSwaps = swappableCook[itemName] or {}

	local combinedRes = {}
	add_swapple_entry_into(shapedSwaps, itemName, combinedRes)
	add_swapple_entry_into(shapelessSwaps, itemName, combinedRes)
	add_swapple_entry_into(cookSwaps, itemName, combinedRes)

	return combinedRes
end

-- Returns a table of tables, where each entry is a group of ItemStacks representing a conflict group
-- Each entry also contains a .recipe field which is the common recipe for all items in that group
-- Note that modifying this table will result in problems!
function craft_conflict_finder.get_all_shaped_conflics()
	return shapedCraftConflicts
end

function craft_conflict_finder.get_all_shapeless_conflics()
	return shapelessCraftConflicts
end

function craft_conflict_finder.get_all_cook_conflics()
	return cookConflicts
end
