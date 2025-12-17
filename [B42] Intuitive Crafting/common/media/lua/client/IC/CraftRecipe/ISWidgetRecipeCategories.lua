require "ISUI/ISPanel"

local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 19; 
local UI_BORDER_SPACING = 10
local MIN_LIST_BOX_WIDTH = 125 * FONT_SCALE;
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local CATEGORY_ICON_SIZE = FONT_HGT_SMALL 

local ITEM_PADDING_HORIZONTAL = UI_BORDER_SPACING

ISWidgetRecipeCategories = ISPanel:derive("ISWidgetRecipeCategories");

ISWidgetRecipeCategories.PREDEFINED_CATEGORY_ORDER = {
    "Outdoors",
    "Medical",
    "Cooking",
    "Survival",
    "Farming",
    "Fishing",
    "Tailoring",
    
    "Carving",
    "Carpentry",
    "Furniture",
    "Masonry",
    "Knapping",
    "Blacksmithing",
    "Welding",
    
    "Tools",
    "Repair",
    "Mechanical",
    "Armoring",
    "Assembly",
    
    "Armor",
    "Weaponry",
    "Ammunition",
    "Blade",
    
    "Metalworking",
    "Electrical",
    "Recycling",
    
    "Cookware",
    "Pottery",
    "Glassmaking",
    
    "Packing",
    "SkillJournal",
    
    "Miscellaneous"
}


local defaultCategoryIconPath = "media/ui/craftingMenus/categories/None.png"
local categoryIconBasePath = "media/ui/craftingMenus/categories/"

local iconSizeSuffixes = {
    [16] = "_16",
    [19] = "_24",
    [26] = "_24",
    [33] = "_32",
    [38] = "_32",
}
local availableIconSuffixSizes = { "_32", "_24", "_16" }

local function normalizeCategoryToKeyPart(categoryName)
    if categoryName == nil then
        return "Unknown" 
    end
    local key = tostring(categoryName)
    key = key:match("^%s*(.-)%s*$")
    if key == nil or #key == 0 then
        return "Unknown" 
    end
    key = key:gsub("%s+", "")
    if #key > 0 then
        key = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
    else
        return "Unknown"
    end
    key = key:gsub("[^%w_]+", "") 
    if #key == 0 then
        return "Unknown" 
    end
    return key
end

function ISWidgetRecipeCategories:initialise()
    ISPanel.initialise(self);
end

function ISWidgetRecipeCategories:createChildren()
    ISPanel.createChildren(self);
    self.recipeCategoryPanel = ISScrollingListBox:new(0, 0, self.listBoxWidth or MIN_LIST_BOX_WIDTH, 0);
    self.recipeCategoryPanel:initialise();
    self.recipeCategoryPanel:instantiate();
    self.recipeCategoryPanel.itemheight = math.max(FONT_HGT_SMALL, CATEGORY_ICON_SIZE) + ITEM_PADDING_HORIZONTAL * 2; 
    self.recipeCategoryPanel.selected = 0;
    self.recipeCategoryPanel.font = UIFont.Small
    self.recipeCategoryPanel.drawBorder = true
    self.recipeCategoryPanel:setOnMouseDownFunction(self, self.onCategoryChanged);
    self.recipeCategoryPanel.drawDebugLines = self.drawDebugLines;

    self.recipeCategoryPanel.doDrawItem = function(_self, _y, _item, _alt)
        local yActual = _self:getYScroll() + _y;
        if yActual > _self.height or (yActual + _self.itemheight) < 0 then
            return _y + _self.itemheight;
        end
        if _self.selected == _item.index then
            _self:drawSelection(0, _y, _self:getWidth(), _self.itemheight - 1);
        elseif (_self.mouseoverselected == _item.index) and _self:isMouseOver() and not _self:isMouseOverScrollBar() then
            _self:drawMouseOverHighlight(0, _y, _self:getWidth(), _self.itemheight - 1);
        end
        _self:drawRectBorder(0, _y, _self:getWidth(), _self.itemheight, 0.5, _self.borderColor.r, _self.borderColor.g, _self.borderColor.b);
        local currentX = ITEM_PADDING_HORIZONTAL; 
        local iconY = _y + (_self.itemheight - CATEGORY_ICON_SIZE) / 2;
        if _item.iconTexture and _item.value ~= "" then 
            _self:drawTextureScaledAspect(_item.iconTexture, currentX, iconY, CATEGORY_ICON_SIZE, CATEGORY_ICON_SIZE, 1.0, 1, 1, 1);
            currentX = currentX + CATEGORY_ICON_SIZE + ITEM_PADDING_HORIZONTAL; 
        end
        local textY = _y + (_self.itemheight - FONT_HGT_SMALL) / 2;
        _self:drawText(_item.text, currentX, textY, 1,1,1,1, _self.font);
        return _y + _self.itemheight;
    end
    self:addChild(self.recipeCategoryPanel);
end

function ISWidgetRecipeCategories:calculateLayout(_preferredWidth, _preferredHeight)
    local desiredWidth;
    local scrollbarWidth = 0;
    if self.recipeCategoryPanel.vscroll then
        scrollbarWidth = self.recipeCategoryPanel.vscroll:getWidth();
    end
    if self.autoWidth and self.recipeCategoryPanel.items and #self.recipeCategoryPanel.items > 0 then
        local biggestItemContentWidth = 0;
        for i,v in pairs(self.recipeCategoryPanel.items) do
            local currentItemWidth = ITEM_PADDING_HORIZONTAL; 
            if v.iconTexture and v.value ~= "" then 
                currentItemWidth = currentItemWidth + CATEGORY_ICON_SIZE + ITEM_PADDING_HORIZONTAL; 
            end
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, v.text)
            currentItemWidth = currentItemWidth + textWidth;
            currentItemWidth = currentItemWidth + ITEM_PADDING_HORIZONTAL; 
            if currentItemWidth > biggestItemContentWidth then
                biggestItemContentWidth = currentItemWidth;
            end
        end
        desiredWidth = biggestItemContentWidth;
        desiredWidth = desiredWidth + scrollbarWidth; 
    else
        desiredWidth = self.listBoxWidth or MIN_LIST_BOX_WIDTH;
        if self.listBoxWidth then
            desiredWidth = desiredWidth + scrollbarWidth;
        end
    end
    desiredWidth = math.max(desiredWidth, MIN_LIST_BOX_WIDTH + scrollbarWidth);
    self:setWidth(desiredWidth);
    self.recipeCategoryPanel:setWidth(self:getWidth())
    if self.recipeCategoryPanel.vscroll then
        self.recipeCategoryPanel.vscroll:setX(self.recipeCategoryPanel:getWidth()-scrollbarWidth);
    end
    self:setHeight(_preferredHeight);
    self:setInternalHeight(_preferredHeight);
end

function ISWidgetRecipeCategories:onResize()
    ISUIElement.onResize(self)
end

function ISWidgetRecipeCategories:prerender()
    ISPanel.prerender(self);
    if self.recipeCategoryPanel and self.recipeCategoryPanel.vscroll then
        self.recipeCategoryPanel.vscroll:setHeight(self.recipeCategoryPanel.height);
    end
end

function ISWidgetRecipeCategories:render()
    ISPanel.render(self);
end

function ISWidgetRecipeCategories:update()
    ISPanel.update(self);
end

function ISWidgetRecipeCategories:setInternalHeight(_height)
    if self.recipeCategoryPanel then
        self.recipeCategoryPanel:setHeight(_height);
    end
end

function ISWidgetRecipeCategories:getIconPathWithSuffix(baseFileName, suffix)
    return categoryIconBasePath .. "Icon_" .. baseFileName .. (suffix or "") .. ".png"
end

function ISWidgetRecipeCategories:getCategoryIcon(categoryKey)
    if categoryKey == "" or string.lower(tostring(categoryKey)) == "all" then
        return nil
    end
    local normalizedKey = tostring(categoryKey)
    normalizedKey = normalizedKey:gsub("%s+", "") 
    if #normalizedKey > 0 then
        normalizedKey = string.upper(string.sub(normalizedKey, 1, 1)) .. string.sub(normalizedKey, 2)
    else
        normalizedKey = "Unknown"
    end
    normalizedKey = normalizedKey:gsub("[^%w_]+", "") 
    local targetSuffix = iconSizeSuffixes[FONT_HGT_SMALL]
    if targetSuffix then
        local potentialIconPath = self:getIconPathWithSuffix(normalizedKey, targetSuffix)
        local texture = getTexture(potentialIconPath)
        if texture and texture:getWidth() > 0 and texture:getHeight() > 0 then return texture end
    end
    for _, suffix in ipairs(availableIconSuffixSizes) do
        if suffix ~= targetSuffix then 
            local potentialIconPath = self:getIconPathWithSuffix(normalizedKey, suffix)
            local texture = getTexture(potentialIconPath)
            if texture and texture:getWidth() > 0 and texture:getHeight() > 0 then return texture end
        end
    end
    local basePath = self:getIconPathWithSuffix(normalizedKey, nil) 
    local texture = getTexture(basePath)
    if texture and texture:getWidth() > 0 and texture:getHeight() > 0 then return texture end
    return getTexture(defaultCategoryIconPath); 
end

function ISWidgetRecipeCategories:populateCategoryList()
    self.recipeCategoryPanel:clear()

    local orderMap = {}
    for i, keyInOrderList in ipairs(ISWidgetRecipeCategories.PREDEFINED_CATEGORY_ORDER) do
        orderMap[keyInOrderList] = i 
    end

    local otherCategoryDataList = {}
    local processedNormalizedKeys = {}

    local originalNameAll = "-- ALL --"
    local normalizedKeyAll = normalizeCategoryToKeyPart(originalNameAll)
    local translationKeyAll = "IGUI_RecipeCategories_" .. normalizedKeyAll
    local attemptedTranslationAll = getText(translationKeyAll)
    local displayNameAll = (attemptedTranslationAll ~= translationKeyAll) and attemptedTranslationAll or originalNameAll
    local allItem = self.recipeCategoryPanel:addItem(displayNameAll, "")
    allItem.iconTexture = nil
    processedNormalizedKeys[normalizedKeyAll] = true

    local originalNameFav = "Favourites"
    local normalizedKeyFav = normalizeCategoryToKeyPart(originalNameFav)
    local translationKeyFav = "IGUI_RecipeCategories_" .. normalizedKeyFav
    local attemptedTranslationFav = getText(translationKeyFav)
    local displayNameFav = (attemptedTranslationFav ~= translationKeyFav) and attemptedTranslationFav or originalNameFav
    local favItem = self.recipeCategoryPanel:addItem(displayNameFav, "*")
    favItem.iconTexture = self:getCategoryIcon("favourites")
    processedNormalizedKeys[normalizedKeyFav] = true

    local gameCategories = self.callbackTarget:getCategoryList()
    for i = 0, gameCategories:size()-1 do
        local categoryOriginalName = gameCategories:get(i)
        local normalizedLookupKey = normalizeCategoryToKeyPart(categoryOriginalName)

        if not processedNormalizedKeys[normalizedLookupKey] then 
            local defaultDisplayName = categoryOriginalName
            if categoryOriginalName and #categoryOriginalName > 0 then
                 defaultDisplayName = string.upper(string.sub(categoryOriginalName, 1, 1)) .. string.sub(categoryOriginalName, 2, string.len(categoryOriginalName));
            end

            local translationKey = "IGUI_RecipeCategories_" .. normalizedLookupKey
            local attemptedTranslation = getText(translationKey)
            local finalDisplayName = (attemptedTranslation ~= translationKey) and attemptedTranslation or defaultDisplayName
            
            local iconTexture = self:getCategoryIcon(categoryOriginalName)
            local orderIndex = orderMap[normalizedLookupKey]

            table.insert(otherCategoryDataList, {
                originalName = categoryOriginalName,
                displayName = finalDisplayName,
                icon = iconTexture,
                value = categoryOriginalName, 
                order = orderIndex,
                lookupKey = normalizedLookupKey
            })
            processedNormalizedKeys[normalizedLookupKey] = true
        end
    end

    local miscKey = normalizeCategoryToKeyPart("Miscellaneous")
    table.sort(otherCategoryDataList, function(a, b)
        local aOrder = a.order
        local bOrder = b.order
        local aIsMisc = (a.lookupKey == miscKey)
        local bIsMisc = (b.lookupKey == miscKey)

        if aIsMisc and not bIsMisc then return false end
        if not aIsMisc and bIsMisc then return true end
        if aIsMisc and bIsMisc then return false end 

        if aOrder and bOrder then
            return aOrder < bOrder
        elseif aOrder then
            return true 
        elseif bOrder then
            return false
        else 
            return a.displayName < b.displayName
        end
    end)

    for _, itemData in ipairs(otherCategoryDataList) do
        local item = self.recipeCategoryPanel:addItem(itemData.displayName, itemData.value)
        item.iconTexture = itemData.icon
    end
    
    local currentCategoryFilterFound = false
    local indexOfSelectedCategoryInPanel = -1

    for panelIndex = 1, #self.recipeCategoryPanel.items do
        local panelItem = self.recipeCategoryPanel.items[panelIndex]
        if panelItem.item == self.selectedCategory then 
            indexOfSelectedCategoryInPanel = panelIndex
            currentCategoryFilterFound = true
            break
        end
    end
    
    if currentCategoryFilterFound and indexOfSelectedCategoryInPanel > 0 then
        self.recipeCategoryPanel.selected = indexOfSelectedCategoryInPanel
    else
        self.recipeCategoryPanel.selected = 1 
        self:onCategoryChanged("")
    end
    
    if gameCategories:size() > 0 or #otherCategoryDataList > 0 then 
        self.isInitialised = true
    else 
        self.isInitialised = (#self.recipeCategoryPanel.items > 0)
    end
end


function ISWidgetRecipeCategories:onCategoryChanged(_itemValue, _itemUI)
    self.selectedCategory = _itemValue;
    self.callbackTarget:onCategoryChanged(_itemValue);
end

function ISWidgetRecipeCategories:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.isInitialised = false;
    o.autoWidth = true; 
    o.listBoxWidth = width; 
    return o;
end