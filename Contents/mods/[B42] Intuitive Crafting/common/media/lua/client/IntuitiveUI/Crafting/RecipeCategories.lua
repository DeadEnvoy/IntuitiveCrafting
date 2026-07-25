require "Entity/ISUI/CraftRecipe/ISHandCraftPanel"
require "Entity/ISUI/CraftRecipe/ISWidgetRecipeCategories"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local ICON_SIZE, FONT_SCALE = FONT_HGT_SMALL, FONT_HGT_SMALL / 19
local UI_BORDER_SPACING, MIN_LIST_BOX_WIDTH = 10, 125 * FONT_SCALE

local MERGED_CATEGORIES = {
	["Ammo"] = "Ammunition",
	["Weapons"] = "Weaponry",
	["Skill Journal"] = "Miscellaneous",
	["Packings"] = "Packing"
}

local function getMergedCategorySet(categoryName)
    local set = {}; set[categoryName] = true
    
    local hasChildren = false
    for child, parent in pairs(MERGED_CATEGORIES) do
        if parent == categoryName then
            set[child] = true; hasChildren = true
        end
    end
    
    return set, hasChildren
end

local function getIconSuffix()
	if FONT_HGT_SMALL >= 38 then return "_32"
	elseif FONT_HGT_SMALL >= 33 then return "_32"
	elseif FONT_HGT_SMALL >= 26 then return "_24"
	elseif FONT_HGT_SMALL >= 19 then return "_24"
	else return "_16" end
end

local original_createChildren = ISWidgetRecipeCategories.createChildren
function ISWidgetRecipeCategories:createChildren()
	original_createChildren(self)

	self.recipeCategoryPanel.itemheight = math.max(FONT_HGT_SMALL, ICON_SIZE) + UI_BORDER_SPACING * 2;

	self.recipeCategoryPanel.doDrawItem = function(listbox, y, item, alt)
		if not item.height then item.height = listbox.itemheight end

		if item.height <= 0 then
			return y + item.height
		end

		if (y + listbox:getYScroll() + listbox.itemheight < 0) or (y + listbox:getYScroll() >= listbox.height) then
			return y + item.height
		end

		local textColor = item.textColor or listbox.textColor
		
		if listbox.selected == item.index then
			listbox:drawSelection(0, y, listbox:getWidth(), item.height-1);
			textColor = item.selectedTextColor or listbox.selectedTextColor
		elseif (listbox.mouseoverselected == item.index) and listbox:isMouseOver() and not listbox:isMouseOverScrollBar() then
			listbox:drawMouseOverHighlight(0, y, listbox:getWidth(), item.height-1);
		end

		listbox:drawRectBorder(0, y, listbox:getWidth(), item.height, 0.5, listbox.borderColor.r, listbox.borderColor.g, listbox.borderColor.b);

		local textX, textY = UI_BORDER_SPACING, y + (item.height - FONT_HGT_SMALL) / 2

		if item.icon then
			local iconY = y + (item.height - ICON_SIZE) / 2
			listbox:drawTextureScaled(item.icon, textX, iconY, ICON_SIZE, ICON_SIZE, 1, 1, 1, 1)
			textX = textX + ICON_SIZE + (UI_BORDER_SPACING / 2)
		end

		listbox:drawText(item.text, textX, textY, textColor.r, textColor.g, textColor.b, textColor.a, listbox.font);
		
		return y + item.height
	end
end

function ISWidgetRecipeCategories:populateCategoryList()
	self.recipeCategoryPanel:clear()

	local allKey = "IGUI_RecipeCategories_ALL"; local allText = getText(allKey)
	if allText == allKey then allText = "-- ALL --" end
	self.recipeCategoryPanel:addItem(allText, "")

	local favKey = "IGUI_RecipeCategories_Favourites"; local favText = getText(favKey)
	if favText == favKey then favText = "Favourites" end
	self.recipeCategoryPanel:addItem(favText, "*")

	local itemFav = self.recipeCategoryPanel.items[2]
	local favIconPath = "media/ui/craftingMenus/categories/Icon_Favourites" .. getIconSuffix() .. ".png"
	itemFav.icon = getTexture(favIconPath); if not itemFav.icon then
		itemFav.icon = getTexture("media/ui/craftingMenus/categories/None.png")
	end

	local currentCategoryFilterFound = self.selectedCategory == ""

	if self.selectedCategory == "*" then
		self.recipeCategoryPanel.selected = 2
		currentCategoryFilterFound = true
	end

	local categories = self.callbackTarget:getCategoryList()
	if not categories or categories:isEmpty() then
		if not currentCategoryFilterFound then
			self:onCategoryChanged("")
		end
		return
	end

	local luaCategories = {}
	
	for i = 0, categories:size() - 1 do
		local categoryName = categories:get(i)
		if not MERGED_CATEGORIES[categoryName] then
			table.insert(luaCategories, categoryName)
		end
	end

	local customOrder = {
		["Outdoors"] = 1, ["Medical"] = 2, ["Cooking"] = 3, ["Survival"] = 4, ["Farming"] = 5, ["Fishing"] = 6, ["Tailoring"] = 7,
		["Carving"] = 8, ["Carpentry"] = 9, ["Barricades"] = 10, ["Furniture"] = 11, ["Wall Coverings"] = 12, ["Masonry"] = 13,
		["Knapping"] = 14, ["Blacksmithing"] = 15, ["Welding"] = 16, ["Tools"] = 17, ["Repair"] = 18, ["Mechanical"] = 19, ["Armoring"] = 20,
		["Assembly"] = 21, ["Armor"] = 22, ["Weaponry"] = 23, ["Ammunition"] = 24, ["Blade"] = 25, ["Metalworking"] = 26, ["Electrical"] = 27,
		["Recycling"] = 28, ["Cookware"] = 29, ["Pottery"] = 30, ["Glassmaking"] = 31, ["Packing"] = 32, ["Miscellaneous"] = 33
	}
	
	local miscOrder = customOrder.Miscellaneous

	table.sort(luaCategories, function(a, b)
		local orderA = customOrder[a]
		local orderB = customOrder[b]

		if orderA and orderB then
			return orderA < orderB
		end

		if orderA then
			return orderA < miscOrder
		end
		
		if orderB then
			return not (orderB < miscOrder)
		end
		
		return a < b
	end)

	for _, categoryName in ipairs(luaCategories) do
		local translationKey = "IGUI_RecipeCategories_" .. categoryName:gsub(" ", "_"); local displayText = getText(translationKey)

		if displayText == translationKey then
			displayText = string.upper(string.sub(categoryName, 1, 1)) .. string.sub(categoryName, 2, string.len(categoryName))
		end
		
		local item = self.recipeCategoryPanel:addItem(displayText, categoryName)

		local iconPath = "media/ui/craftingMenus/categories/Icon_" .. categoryName:gsub(" ", "_") .. getIconSuffix() .. ".png"
		item.icon = getTexture(iconPath); if not item.icon then
			item.icon = getTexture("media/ui/craftingMenus/categories/None.png")
		end

		if categoryName == self.selectedCategory then
			self.recipeCategoryPanel.selected = item.itemindex
			currentCategoryFilterFound = true
		end
	end

	if not currentCategoryFilterFound then
		self:onCategoryChanged("")
	end

	if categories:size() > 0 then
		self.isInitialised = true
	end
end

function ISWidgetRecipeCategories:calculateLayout(_preferredWidth, _preferredHeight)
    local biggestSize = 0
    for i, v in pairs(self.recipeCategoryPanel.items) do
        local currentSize = getTextManager():MeasureStringX(UIFont.Small, v.text)

        if v.icon then
            currentSize = currentSize + ICON_SIZE + (UI_BORDER_SPACING / 2)
        end

        if currentSize > biggestSize then
            biggestSize = currentSize
        end
    end

    local desiredWidth = biggestSize + (UI_BORDER_SPACING * FONT_SCALE) + UI_BORDER_SPACING

    if self.recipeCategoryPanel.vscroll then
        desiredWidth = desiredWidth + self.recipeCategoryPanel.vscroll:getWidth()
    end

    local newWidth = math.max(self.listBoxWidth or MIN_LIST_BOX_WIDTH, desiredWidth)

    self:setWidth(newWidth); self.recipeCategoryPanel:setWidth(self:getWidth())

    if self.recipeCategoryPanel.vscroll then
        self.recipeCategoryPanel.vscroll:setX(self.recipeCategoryPanel:getWidth() - self.recipeCategoryPanel.vscroll:getWidth())
    end

    self:setHeight(_preferredHeight); self:setInternalHeight(_preferredHeight)
end

local original_filterRecipeList = ISHandCraftPanel.filterRecipeList
function ISHandCraftPanel:filterRecipeList()
    local category = self._categoryString
    local _, isMerged = getMergedCategorySet(category)

    if isMerged then
        local filterStr = self._filterString
        if self._filterMode and filterStr and filterStr ~= "" then
            filterStr = filterStr .. "-@-" .. self._filterMode
        end

        self.logic:filterRecipeList(filterStr, nil, true)
        return
    end

    original_filterRecipeList(self)
end

function ISHandCraftPanel:onUpdateRecipeList(_recipeList)
    local category = self._categoryString
    local targetCategories, isMerged = getMergedCategorySet(category)

    local collection = _recipeList or self.logic:getRecipeList()

    if isMerged then
        local allRecipes = collection:getAllRecipes()
        local totalRecipes = allRecipes:size()
        local recipesToKeep = {}
        
        for i=0, totalRecipes-1 do
            local recipe = allRecipes:get(i)
            if recipe then
                local rCat = recipe:getCategory()
                if targetCategories[rCat] then
                    table.insert(recipesToKeep, recipe)
                end
            end
        end

        collection:clear()
        for _, recipe in ipairs(recipesToKeep) do
            collection:add(recipe)
        end

        local nodes = collection:getNodes()
        for i=0, nodes:size()-1 do
            local node = nodes:get(i)
            if node:getType() == CraftRecipeListNode.CraftRecipeListNodeType.GROUP then
                if node:getExpandedState() == CraftRecipeListNodeExpandedState.PARTIAL then
                    node:setExpandedState(CraftRecipeListNodeExpandedState.CLOSED)
                end
            end
        end
    end

    self.recipesPanel:onUpdateRecipeList(collection)

    if self.recipeCategories then
        self.recipeCategories:populateCategoryList()
    end
end

local original_sortRecipeList = ISHandCraftPanel.sortRecipeList
function ISHandCraftPanel:sortRecipeList()
    local category = self._categoryString
    local _, isMerged = getMergedCategorySet(category)
    
    if isMerged then
        self:filterRecipeList()
    else
        original_sortRecipeList(self)
    end
end