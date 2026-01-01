require "IntuitiveUI/RecipeCategories"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/CraftRecipe/ISWidgetRecipeFilterPanel"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall)
local UI_BORDER_SPACING, GAP = 5, 15

local function getVisualWidth(tickbox)
    if not tickbox or not tickbox.options[1] then return 0 end
    local text = tickbox.options[1]
    local font = tickbox.font or UIFont.Small
    local boxSize = tickbox.boxSize or tickbox.height
    local textGap = tickbox.textGap or 10
    local textWidth = getTextManager():MeasureStringX(font, text)
    return boxSize + textGap + textWidth
end

local original_ISHandCraftPanel_new = ISHandCraftPanel.new
function ISHandCraftPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = original_ISHandCraftPanel_new(self, x, y, width, height, player, craftBench, isoObject, recipeQuery)

    o.filterShowLearned = self.filterShowLearned ~= false  -- default: true
    o.filterHasMaterials = self.filterHasMaterials == true  -- default: false
    o.filterGrantsXP = self.filterGrantsXP == true -- default: false

    return o
end

local original_ISBuildPanel_new = ISBuildPanel.new
function ISBuildPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = original_ISBuildPanel_new(self, x, y, width, height, player, craftBench, isoObject, recipeQuery)

    o.filterShowLearned = self.filterShowLearned ~= false -- default: true
    o.filterHasMaterials = self.filterHasMaterials == true -- default: false
    o.filterGrantsXP = self.filterGrantsXP == true -- default: false

    return o
end

local original_createChildren = ISWidgetRecipeFilterPanel.createChildren
function ISWidgetRecipeFilterPanel:createChildren()
    original_createChildren(self)

    self.tickBoxShowLearned = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISTickBox, 0, 0, 15, FONT_HGT_SMALL, "tickbox", self, ISWidgetRecipeFilterPanel.onShowLearnedClick)
    self.tickBoxShowLearned:initialise()
    self.tickBoxShowLearned:instantiate()
    self.tickBoxShowLearned.selected[1] = self.callbackTarget.filterShowLearned
    self.tickBoxShowLearned:addOption(getText("IGUI_CraftingUI_ShowLearned"))
    self.tickBoxShowLearned.tooltip = getText("IGUI_CraftingUI_ShowLearned_tooltip")
    self:addChild(self.tickBoxShowLearned)

    self.tickBoxHasMaterials = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISTickBox, 0, 0, 15, FONT_HGT_SMALL, "tickbox", self, ISWidgetRecipeFilterPanel.onHasMaterialsClick)
    self.tickBoxHasMaterials:initialise()
    self.tickBoxHasMaterials:instantiate()
    self.tickBoxHasMaterials.selected[1] = self.callbackTarget.filterHasMaterials
    self.tickBoxHasMaterials:addOption(getText("IGUI_CraftingUI_HasMaterials"))
    self.tickBoxHasMaterials.tooltip = getText("IGUI_CraftingUI_HasMaterials_tooltip")
    self:addChild(self.tickBoxHasMaterials)

    self.tickBoxGrantsXP = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISTickBox, 0, 0, 15, FONT_HGT_SMALL, "tickbox", self, ISWidgetRecipeFilterPanel.onGrantsXPClick)
    self.tickBoxGrantsXP:initialise()
    self.tickBoxGrantsXP:instantiate()
    self.tickBoxGrantsXP.selected[1] = self.callbackTarget.filterGrantsXP
    self.tickBoxGrantsXP:addOption(getText("IGUI_CraftingUI_GrantsXP"))
    self.tickBoxGrantsXP.tooltip = getText("IGUI_CraftingUI_GrantsXP_tooltip")
    self:addChild(self.tickBoxGrantsXP)

    if self.joypadButtonsY and #self.joypadButtonsY > 0 then
        local row = self.joypadButtonsY[#self.joypadButtonsY]
        table.insert(row, self.tickBoxShowLearned)
        table.insert(row, self.tickBoxHasMaterials)
        table.insert(row, self.tickBoxGrantsXP)
    end
end

local original_calculateLayout = ISWidgetRecipeFilterPanel.calculateLayout
function ISWidgetRecipeFilterPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local widthNeeded = 0
    local alignTarget = self.showAllRecipeTickBox or self.tickBoxShowAllVersion

    if alignTarget and self.tickBoxShowLearned and self.tickBoxHasMaterials and self.tickBoxGrantsXP then
        local targetVisW = getVisualWidth(alignTarget)
        local showLearnedVisW = getVisualWidth(self.tickBoxShowLearned)
        local hasMaterialsVisW = getVisualWidth(self.tickBoxHasMaterials)
        local grantsXPVisW = getVisualWidth(self.tickBoxGrantsXP)
        
        local sortPartWidth = 0
        if self.sortComboLabel and self.sortComboLabel:isVisible() then
             sortPartWidth = self.width - self.sortComboLabel:getX()
        elseif self.sortCombo and self.sortCombo:isVisible() then
             sortPartWidth = self.width - self.sortCombo:getX()
        end
        if sortPartWidth <= 0 then sortPartWidth = 200 end

        local checkBoxesWidth = UI_BORDER_SPACING + targetVisW + GAP + showLearnedVisW + GAP + hasMaterialsVisW + GAP + grantsXPVisW
        widthNeeded = checkBoxesWidth + GAP + sortPartWidth
    end

    if not _preferredWidth or _preferredWidth < widthNeeded then
        _preferredWidth = widthNeeded
    end

    original_calculateLayout(self, _preferredWidth, _preferredHeight)

    if alignTarget then
        local y = alignTarget:getY()

        if self.sortCombo then
            local sortH = self.sortCombo:getHeight()
            local targetH = alignTarget:getHeight()
            local sortY = self.sortCombo:getY()
            
            y = sortY + (sortH / 2) - (targetH / 2)
        end
        
        alignTarget:setY(y)

        local x = alignTarget:getX() + getVisualWidth(alignTarget) + GAP

        self.tickBoxShowLearned:setX(x)
        self.tickBoxShowLearned:setY(y)
        self.tickBoxShowLearned:setWidth(getVisualWidth(self.tickBoxShowLearned))

        x = x + getVisualWidth(self.tickBoxShowLearned) + GAP
        self.tickBoxHasMaterials:setX(x)
        self.tickBoxHasMaterials:setY(y)
        self.tickBoxHasMaterials:setWidth(getVisualWidth(self.tickBoxHasMaterials))

        x = x + getVisualWidth(self.tickBoxHasMaterials) + GAP
        self.tickBoxGrantsXP:setX(x)
        self.tickBoxGrantsXP:setY(y)
        self.tickBoxGrantsXP:setWidth(getVisualWidth(self.tickBoxGrantsXP))
    end
    
    local maxY = 0
    for _, child in pairs(self.children) do
        if child:isVisible() then
            local bottom = child:getY() + child:getHeight()
            if bottom > maxY then maxY = bottom end
        end
    end
    self:setHeight(maxY + UI_BORDER_SPACING)
end

function ISWidgetRecipeFilterPanel:onShowLearnedClick(clickedOption, enabled)
    if self.callbackTarget then
        self.callbackTarget.filterShowLearned = enabled

        if self.callbackTarget.Type == "ISHandCraftPanel" then
            ISHandCraftPanel.filterShowLearned = enabled
        elseif self.callbackTarget.Type == "ISBuildPanel" then
            ISBuildPanel.filterShowLearned = enabled
        end

        if self.callbackTarget.refreshRecipeList then
            self.callbackTarget:refreshRecipeList(true)
        elseif self.callbackTarget.refreshList then
            self.callbackTarget:refreshList(true)
        end

        self.callbackTarget:filterRecipeList()
    end
end

function ISWidgetRecipeFilterPanel:onHasMaterialsClick(clickedOption, enabled)
    if self.callbackTarget then
        self.callbackTarget.filterHasMaterials = enabled

        if self.callbackTarget.Type == "ISHandCraftPanel" then
            ISHandCraftPanel.filterHasMaterials = enabled
        elseif self.callbackTarget.Type == "ISBuildPanel" then
            ISBuildPanel.filterHasMaterials = enabled
        end

        if self.callbackTarget.refreshRecipeList then
            self.callbackTarget:refreshRecipeList(true)
        elseif self.callbackTarget.refreshList then
            self.callbackTarget:refreshList(true)
        end

        self.callbackTarget:filterRecipeList()
    end
end

function ISWidgetRecipeFilterPanel:onGrantsXPClick(clickedOption, enabled)
    if self.callbackTarget then
        self.callbackTarget.filterGrantsXP = enabled

        if self.callbackTarget.Type == "ISHandCraftPanel" then
            ISHandCraftPanel.filterGrantsXP = enabled
        elseif self.callbackTarget.Type == "ISBuildPanel" then
            ISBuildPanel.filterGrantsXP = enabled
        end

        if self.callbackTarget.refreshRecipeList then
            self.callbackTarget:refreshRecipeList(true)
        elseif self.callbackTarget.refreshList then
            self.callbackTarget:refreshList(true)
        end

        self.callbackTarget:filterRecipeList()
    end
end

local function isRecipeShowLearned(logic, player, craftRecipe)
    if not player:isBuildCheat() then
        local cachedRecipeInfo = logic:getCachedRecipeInfo(craftRecipe)
        if cachedRecipeInfo and (not cachedRecipeInfo:isValid()) then
            return false
        elseif cachedRecipeInfo and (not cachedRecipeInfo:isCanPerform()) then
            return false
        end
    end
    return true
end

local function applyRecipeFilters(self, _recipeList)
    if self.filterShowLearned or self.filterHasMaterials or self.filterGrantsXP then
        local collection = _recipeList or self.logic:getRecipeList()
        local allRecipes = collection:getAllRecipes()
        local recipesToKeep = {}
        local totalCount = allRecipes:size()
        local player = self.player
        
        local availableTypes = {}
        if self.filterHasMaterials then
            local containers = ISInventoryPaneContextMenu.getContainers(player)
            for i=0, containers:size()-1 do
                local container = containers:get(i)
                local items = container:getItems()
                for j=0, items:size()-1 do
                    local item = items:get(j)
                    if not item:isEquipped() then
                        availableTypes[item:getFullType()] = true
                    end
                end
            end
        end

        for i=0, totalCount-1 do
            local recipe = allRecipes:get(i)
            if recipe then
                local failed = false

                if self.filterShowLearned then
                    if recipe:needToBeLearn() and not player:isRecipeKnown(recipe) then
                        failed = true
                    end

                    if not failed then
                        for j=0, recipe:getRequiredSkillCount()-1 do
                            local skill = recipe:getRequiredSkill(j)
                            if player:getPerkLevel(skill:getPerk()) < skill:getLevel() then
                                failed = true
                                break
                            end
                        end
                    end
                end

                if not failed and self.filterHasMaterials then
                    local found = false
                    local inputs = recipe:getInputs()
                    for j=0, inputs:size()-1 do
                        local input = inputs:get(j)
                        if not input:isAutomationOnly() then
                            local possibleItems = input:getPossibleInputItems()
                            for k=0, possibleItems:size()-1 do
                                local scriptItem = possibleItems:get(k)
                                if availableTypes[scriptItem:getFullName()] then
                                    found = true
                                    break
                                end
                            end
                        end
                        if found then break end
                    end
                    if not found then
                        failed = true
                    end
                end

                if not failed and self.filterGrantsXP then
                    if recipe:getXPAwardCount() <= 0 then
                        failed = true
                    end
                end

                if not failed then
                    table.insert(recipesToKeep, recipe)
                end
            end
        end

        collection:clear()
        for _, recipe in ipairs(recipesToKeep) do
            collection:add(recipe)
        end

        local selectedRecipe = self.logic:getRecipe()
        if not selectedRecipe and collection:getAllRecipes():size() > 0 then
            selectedRecipe = collection:getAllRecipes():get(0)
        end

        local nodes = collection:getNodes()
        for i=0, nodes:size()-1 do
            local node = nodes:get(i)
            if node:getType() == CraftRecipeListNode.CraftRecipeListNodeType.GROUP then
                local shouldExpand = false
                local children = node:getChildren()
                for j=0, children:size()-1 do
                    local child = children:get(j)
                    if child:getRecipe() == selectedRecipe then
                        shouldExpand = true
                        break
                    end
                end

                if shouldExpand then
                    if isRecipeShowLearned(self.logic, self.player, selectedRecipe) then
                        node:setExpandedState(CraftRecipeListNodeExpandedState.PARTIAL)
                    else
                        node:setExpandedState(CraftRecipeListNodeExpandedState.OPEN)
                    end
                else
                    node:setExpandedState(CraftRecipeListNodeExpandedState.CLOSED)
                end
            end
        end
    end
end

local original_onUpdateRecipeList = ISHandCraftPanel.onUpdateRecipeList
function ISHandCraftPanel:onUpdateRecipeList(_recipeList)
    applyRecipeFilters(self, _recipeList); original_onUpdateRecipeList(self, _recipeList)
end

local original_ISBuildPanel_onUpdateRecipeList = ISBuildPanel.onUpdateRecipeList
function ISBuildPanel:onUpdateRecipeList(_recipeList)
    applyRecipeFilters(self, _recipeList); original_ISBuildPanel_onUpdateRecipeList(self, _recipeList)
end