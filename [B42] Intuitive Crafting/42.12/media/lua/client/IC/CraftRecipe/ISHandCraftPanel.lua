require "ISUI/ISPanel"

local Reflection = require("Starlit/utils/Reflection")

local PARTIAL_MATCH_UPDATE_DELAY = 0.500

ISHandCraftPanel = ISPanel:derive("ISHandCraftPanel");

if not ISHandCraftPanel.persistentSettings then
    ISHandCraftPanel.persistentSettings = {
        manualSelectInputs = false,
        filterCanCraftEnabled = true,
        filterPartialMatchEnabled = false,
        filterGivesXPEnabled = false
    }
end

function ISHandCraftPanel:initialise()
	ISPanel.initialise(self);
end

function ISHandCraftPanel:createChildren()
    ISPanel.createChildren(self);
    log(DebugType.CraftLogic, "=== CREATING HANDCRAFT PANEL ===")

    local styleCell = "S_TableLayoutCell_Pad5";
    self.rootTable = ISXuiSkin.build(self.xuiSkin, "S_TableLayout_Main", ISTableLayout, 0, 0, 10, 10, nil, nil, styleCell);
    self.rootTable:addRowFill(nil); self.rootTable:initialise(); self.rootTable:instantiate();
    self:addChild(self.rootTable);

    if self.leftHandedMode then
        self:createRecipeCategoryColumn(); self:createRecipesColumn();
        self:createRecipePanel(); self:createInventoryPanel();
    else
        self:createInventoryPanel(); self:createRecipePanel();
        self:createRecipesColumn(); self:createRecipeCategoryColumn();
    end

    if self.recipesPanel and self.recipesPanel.recipeFilterPanel then
        if self.recipesPanel.recipeFilterPanel.canCraftTickbox then
            self.recipesPanel.recipeFilterPanel.canCraftTickbox.selected[1] = self.filterCanCraftEnabled
        end
        if self.recipesPanel.recipeFilterPanel.partialMatchTickbox then
            self.recipesPanel.recipeFilterPanel.partialMatchTickbox.selected[1] = self.filterPartialMatchEnabled
        end
        if self.recipesPanel.recipeFilterPanel.xpTickbox then
            self.recipesPanel.recipeFilterPanel.xpTickbox.selected[1] = self.filterGivesXPEnabled
        end
    end

    local viewMode = self.logic:getSelectedRecipeStyle();
    if (viewMode == "grid") then self.recipeListMode = false; else self.recipeListMode = true; end
    self:setRecipeListMode(self.recipeListMode);
    self:refreshRecipeList();
end

function ISHandCraftPanel:createRecipeCategoryColumn()
    self.recipeCategories = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetRecipeCategories, 0, 0, 10, 10);
    self.recipeCategories.callbackTarget = self;
    self.recipeCategories:initialise(); self.recipeCategories:instantiate();
    self.recipeCategories:populateCategoryList()
    local column = self.rootTable:addColumn(nil);
    self.rootTable:setElement(column:index(), 0, self.recipeCategories);
end

function ISHandCraftPanel:onDoubleClick(item)
    if self.recipePanel.craftControl.buttonCraft.enable then
        self.recipePanel.craftControl:startHandcraft(false);
    end
end

function ISHandCraftPanel:createRecipesColumn()
    self.recipesPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetRecipesPanel, 0, 0, 10, 10, self.player, self.craftBench, self.isoObject, self.logic, self);
    self.recipesPanel.needSortCombo = true;
    self.recipesPanel.needFilterCombo = true; self.recipesPanel.wrapTooltipText = true;
    self.recipesPanel:initialise(); self.recipesPanel:instantiate();
    self.recipesPanel.noTooltip = true; self.recipesPanel.needSortCombo = true;
    if self.recipesPanel.recipeListPanel and self.recipesPanel.recipeListPanel.recipeListPanel then
        self.recipesPanel.recipeListPanel.recipeListPanel:setOnMouseDoubleClick(self, ISHandCraftPanel.onDoubleClick)
    end
    local column = self.rootTable:addColumnFill(nil);
    self.rootTable:setElement(column:index(), 0, self.recipesPanel);
end

function ISHandCraftPanel:createInventoryPanel()
    self.inventoryPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISCraftInventoryPanel, 0, 0, 10, 10, self.player, self.logic);
    self.inventoryPanel:initialise(); self.inventoryPanel:instantiate();
    local column = self.rootTable:addColumn(nil);
    self.rootTable:setElement(column:index(), 0, self.inventoryPanel);
    self.inventoryPanelColumn = column;
    self.inventoryPanelColumn.visible = self.logic:shouldShowManualSelectInputs();
end

function ISHandCraftPanel:createRecipePanel()
    self.recipePanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISCraftRecipePanel, 0, 0, 10, 10, self.player, self.logic);
    self.recipePanel:initialise(); self.recipePanel:instantiate();
    self.recipePanelColumn = self.rootTable:addColumn(nil);
    self.rootTable:setElement(self.recipePanelColumn:index(), 0, self.recipePanel);
end

function ISHandCraftPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width =math.max(self.minimumWidth, _preferredWidth or 0); local height =math.max(self.minimumHeight, _preferredHeight or 0);
    if self.rootTable then
        self.rootTable:setX(0); self.rootTable:setY(0);
        self.rootTable:calculateLayout(width, height);
        width = math.max(width, self.rootTable:getWidth());
        height = math.max(height, self.rootTable:getHeight());
    end
    self:setWidth(width); self:setHeight(height); self.tooltipRecipe = nil;
end

function ISHandCraftPanel:onResize() ISUIElement.onResize(self) end
function ISHandCraftPanel:prerender()
    ISPanel.prerender(self);
    if self.tooltipCounter>0 then self.tooltipCounter = self.tooltipCounter-UIManager.getSecondsSinceLastUpdate(); end
    self:updateTooltip();
end
function ISHandCraftPanel:render()
    ISPanel.render(self);
    if ISEntityUI.drawDebugLines or self.drawDebugLines then
        self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 0, 1, 0);
    end
end

function ISHandCraftPanel:update()
    ISPanel.update(self);
    if self.logic:isCraftActionInProgress() then return; end
    if self.updateTimer > 0 then self.updateTimer = self.updateTimer - 1; end

    local newIsoObject = self.isoObject

    if self.craftBench then
        newIsoObject = self.isoObject
    else
        newIsoObject = ISEntityUI.FindCraftSurface(self.player, 2);
    end

    local surfaceChanged = self.isoObject ~= newIsoObject

    if surfaceChanged then
        self.isoObject = newIsoObject;
        if self.parent then self.parent.isoObject = self.isoObject; end
        self.logic:setIsoObject(self.isoObject);
        self.updateTimer = 0;
        if self.filterPartialMatchEnabled then
             self.needsRecipeListUpdate = true
             if not self.partialMatchUpdateTimer or self.partialMatchUpdateTimer <=0 then
                self.partialMatchUpdateTimer = PARTIAL_MATCH_UPDATE_DELAY
             end
        else
            self:refreshRecipeList()
        end
    end

    if ISHandCraftPanel.drawDirty and self.updateTimer == 0 then
        ISHandCraftPanel.drawDirty = false;
        if self.filterPartialMatchEnabled then
            self.needsRecipeListUpdate = true
            if not self.partialMatchUpdateTimer or self.partialMatchUpdateTimer <= 0 then
                self.partialMatchUpdateTimer = PARTIAL_MATCH_UPDATE_DELAY
            end
        else
            self:refreshRecipeList();
        end
        self.logic:autoPopulateInputs();
        self.logic:refresh();
        if self.recipesPanel and self.recipesPanel.recipeListPanel and self.recipesPanel.recipeListPanel.recipeListPanel and
           self.recipesPanel.recipeListPanel.recipeListPanel.items and #self.recipesPanel.recipeListPanel.recipeListPanel.items < 100 then
            self.updateTimer = 1; else self.updateTimer = 10;
        end
    end

    if self.filterPartialMatchEnabled then
        if self.partialMatchUpdateTimer and self.partialMatchUpdateTimer > 0 then
            self.partialMatchUpdateTimer = self.partialMatchUpdateTimer - UIManager.getSecondsSinceLastUpdate()
        end
        if self.needsRecipeListUpdate and (not self.partialMatchUpdateTimer or self.partialMatchUpdateTimer <= 0) then
            self:refreshRecipeList()
            self.needsRecipeListUpdate = false
            self.partialMatchUpdateTimer = nil
        end
    end
end

function ISHandCraftPanel:refreshRecipeList()
    if self:updateContainers() then
        if self.recipeQuery then self.logic:setRecipes(CraftRecipeManager.queryRecipes(self.recipeQuery));
        elseif self.craftBench then self.logic:setRecipes(self.craftBench:getRecipes());
        else self.logic:setRecipes(ScriptManager.instance:getAllRecipes()); end
        if getDebugOptions():getBoolean("Cheat.Recipe.SeeAll") then self.logic:setRecipes(ScriptManager.instance:getAllCraftRecipes()) end
        self:filterRecipeList()
    end
end

function ISHandCraftPanel:updateContainers(_forceRefresh)
    local containers = ISInventoryPaneContextMenu.getContainers(self.player);
    if self.logic:setContainers(containers) or _forceRefresh then
        self.tooltipLogic:setContainers(containers);
        if self.recipesPanel then self.recipesPanel:updateContainers(containers); end
        if self.inventoryPanel then self.inventoryPanel:updateContainers(containers); end
        return true
    end
    return false
end

function ISHandCraftPanel:updateTooltip()
    if self:getSelectedRecipe()==self.tooltipRecipe or (not self.tooltipRecipe) then self:deactivateTooltip(); return; end
    if self.activeTooltip and (self:getSelectedRecipe()==self.activeTooltip.recipe) then self:deactivateTooltip(); return; end
    local titleOnly = self.tooltipCounter>0;
    if self.activeTooltip then self.activeTooltip:setRecipe(self.tooltipRecipe, titleOnly);
    else
        self.tooltipLogic:setRecipe(self.tooltipRecipe);
        self.activeTooltip = ISCraftRecipeTooltip.activateToolTipFor(self.recipesPanel, self.player, self.tooltipRecipe, self.tooltipLogic, true, titleOnly);
    end
end
function ISHandCraftPanel:deactivateTooltip()
    if self.activeTooltip then ISCraftRecipeTooltip.deactivateToolTipFor(self.recipesPanel); self.activeTooltip = nil; end
end
function ISHandCraftPanel:getSelectedRecipe() return self.logic:getRecipe(); end
function ISHandCraftPanel:setRecipeList(_recipeList) self.logic:setRecipes(_recipeList); end
function ISHandCraftPanel:setRecipes(_recipeQueryOrList) self.logic:setRecipes(_recipeQueryOrList); end

function ISHandCraftPanel:onRecipeChanged(_recipe)
    if self.recipesPanel then self.recipesPanel:onRecipeChanged(_recipe); end
    if self.inventoryPanelColumn then self.inventoryPanelColumn.visible = self.logic:shouldShowManualSelectInputs() and self.logic:getRecipe() ~= nil; end
    if self.recipePanelColumn then self.recipePanelColumn.visible = self.logic:getRecipe() ~= nil; end
    self:xuiRecalculateLayout();
end

function ISHandCraftPanel:recipeGivesXP(recipe)
    if not recipe or not recipe.getXPAwardCount or recipe:getXPAwardCount() == 0 then return false end
    for i = 0, recipe:getXPAwardCount() - 1 do
        local XPAward = recipe:getXPAward(i)
        if XPAward then
            local skillPerk = Reflection.getField(XPAward, "perk"); local xpAmount = Reflection.getField(XPAward, "amount")
            if skillPerk and xpAmount and xpAmount > 0 then return true end
        end
    end
    return false
end

function ISHandCraftPanel:onUpdateRecipeList(_recipeListFromEvent)
    local recipeListToDisplay = ArrayList.new(); if _recipeListFromEvent then recipeListToDisplay:addAll(_recipeListFromEvent) end
    if self.filterCanCraftEnabled then
        local canCraftRecipes = ArrayList.new()
        for i = 0, recipeListToDisplay:size() - 1 do local recipe = recipeListToDisplay:get(i) if self:canPlayerCraftRecipe(recipe) then canCraftRecipes:add(recipe) end end
        recipeListToDisplay = canCraftRecipes
    end
    if self.filterPartialMatchEnabled then
        local partialMatchRecipes = ArrayList.new()
        for i = 0, recipeListToDisplay:size() - 1 do local recipe = recipeListToDisplay:get(i) if self:hasAnyRequiredItem(recipe) then partialMatchRecipes:add(recipe) end end
        recipeListToDisplay = partialMatchRecipes
    end
    if self.filterGivesXPEnabled then
        local givesXPRecipes = ArrayList.new()
        for i = 0, recipeListToDisplay:size() - 1 do local recipe = recipeListToDisplay:get(i) if self:recipeGivesXP(recipe) then givesXPRecipes:add(recipe) end end
        recipeListToDisplay = givesXPRecipes
    end
    if self.recipesPanel then self.recipesPanel:onUpdateRecipeList(recipeListToDisplay) end
    if self.recipeCategories then self.recipeCategories:populateCategoryList() end
end

function ISHandCraftPanel:onManualSelectChanged(_manualSelectInputs)
    if _manualSelectInputs == false then
        self.logic:setShowManualSelectInputs(false);
        self.logic:setManualSelectInputScriptFilter(nil);
    end
    ISHandCraftPanel.persistentSettings.manualSelectInputs = _manualSelectInputs;
end

function ISHandCraftPanel:onShowManualSelectChanged(_showManualSelectInputs)
    self.inventoryPanelColumn:setVisible(_showManualSelectInputs, true); local colWidth = 0;
    local cell = self.rootTable:cellFor(self.inventoryPanel);
    if cell then cell:calculateLayout(0,0); colWidth = cell.width; else colWidth = self.inventoryPanelColumn.width; end
    if _showManualSelectInputs then
        local root = self:xuiRootElement();
        if root then self:xuiRecalculateLayout(root:getWidth()+colWidth, root:getHeight(), true, not self.leftHandedMode);
        else self:xuiRecalculateLayout(); end
    else self:xuiRecalculateLayout(-colWidth, nil, true, not self.leftHandedMode); end
end

function ISHandCraftPanel:OnCloseWindow() if self.logic:shouldShowManualSelectInputs() then self:onShowManualSelectChanged(false); end end

function ISHandCraftPanel:onStopCraft()
    self:updateContainers(); self:refreshRecipeList();
    self.logic:sortRecipeList(); self.logic:refresh();
    self:xuiRecalculateLayout();
    if self.recipesPanel and self.recipesPanel.recipeListPanel and self.recipesPanel.recipeListPanel.recipeListPanel then
        if not self.logic:canPerformCurrentRecipe() then
            self.recipesPanel.recipeListPanel.recipeListPanel:setScrollHeight(0);
            if #self.recipesPanel.recipeListPanel.recipeListPanel.items > 0 then self.recipesPanel.recipeListPanel.recipeListPanel.selected = 1;
            else self.recipesPanel.recipeListPanel.recipeListPanel.selected = 0; end
        end
    end
    self.needsRecipeListUpdate = false
    self.partialMatchUpdateTimer = nil
end

function ISHandCraftPanel:getCategoryList() return self.logic:getCategoryList(); end

function ISHandCraftPanel:setRecipeFilter(_filterString, _filterMode)
    self._filterString = _filterString; self._filterMode = _filterMode;
    self:filterRecipeList();
    self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
end

function ISHandCraftPanel:setSortMode(_sortMode)
    self.logic:setRecipeSortMode(_sortMode);
    self:sortRecipeList();
    self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
end

function ISHandCraftPanel:filterRecipeList()
    local effectiveFilterString = self._filterString
    if self._filterMode and self._filterString and self._filterString ~= "" then
        effectiveFilterString = self._filterString .. "-@-" .. self._filterMode;
    end
    self.logic:filterRecipeList(effectiveFilterString, self._categoryString);
    self:onUpdateRecipeList(self.logic:getRecipeList())
end

function ISHandCraftPanel:sortRecipeList()
    self.logic:sortRecipeList();
    self:onUpdateRecipeList(self.logic:getRecipeList())
end

function ISHandCraftPanel:onCategoryChanged(_category)
    self._categoryString = _category;
    self:filterRecipeList();
    self.logic:checkValidRecipeSelected();
    self:onRecipeChanged(self.logic:getRecipe());
    self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
end

function ISHandCraftPanel:onCanCraftFilterChanged(enabled)
    if self.filterCanCraftEnabled ~= enabled then
        self.filterCanCraftEnabled = enabled;
        ISHandCraftPanel.persistentSettings.filterCanCraftEnabled = enabled;
        self:filterRecipeList();
        self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
    end
end

function ISHandCraftPanel:onPartialMatchFilterChanged(enabled)
    if self.filterPartialMatchEnabled ~= enabled then
        self.filterPartialMatchEnabled = enabled;
        ISHandCraftPanel.persistentSettings.filterPartialMatchEnabled = enabled;
        self:filterRecipeList();
        self.needsRecipeListUpdate = false
        self.partialMatchUpdateTimer = nil
    end
end

function ISHandCraftPanel:onGivesXPFilterChanged(enabled)
    if self.filterGivesXPEnabled ~= enabled then
        self.filterGivesXPEnabled = enabled;
        ISHandCraftPanel.persistentSettings.filterGivesXPEnabled = enabled;
        self:filterRecipeList();
        self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
    end
end

function ISHandCraftPanel:canPlayerCraftRecipe(recipe)
    if not recipe then return false end; local player = self.player
    if recipe:needToBeLearn() and not player:isRecipeKnown(recipe, true) then return false end
    if recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do local requiredSkill = recipe:getRequiredSkill(i) if not CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, player) then return false end end
    end
    return true
end

function ISHandCraftPanel:hasAnyRequiredItem(recipe)
    if not recipe or not self.logic or not self.logic:getContainers() then return false end

    local tempLogic = HandcraftLogic.new(self.player, self.craftBench, self.isoObject)
    tempLogic:setContainers(self.logic:getContainers())
    tempLogic:setRecipe(recipe)

    for i = 0, recipe:getInputs():size() - 1 do
        local inputScript = recipe:getInputs():get(i)
        if not inputScript:isKeep() and not inputScript:isTool() then
            if inputScript:getResourceType() == ResourceType.Item then
                local possibleItems = inputScript:getPossibleInputItems()
                for itemIdx = 0, possibleItems:size() - 1 do
                    local item = possibleItems:get(itemIdx)
                    for containerIdx = 0, tempLogic:getContainers():size() - 1 do
                        local container = tempLogic:getContainers():get(containerIdx)
                        if container:getCountTypeRecurse(item:getFullName()) > 0 then
                            return true
                        end
                    end
                end
            elseif inputScript:getResourceType() == ResourceType.Fluid then
                if tempLogic:getInputUses(inputScript) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function ISHandCraftPanel:setRecipeListMode(_useListMode)
    if self.recipesPanel then self.recipesPanel:setRecipeListMode(_useListMode); end
    self.logic:setSelectedRecipeStyle(_useListMode and "list" or "grid");
    self:onUpdateRecipeList(self.logic:getRecipeList());
    self.needsRecipeListUpdate = false; self.partialMatchUpdateTimer = nil;
end

function ISHandCraftPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = ISPanel:new(x, y, width, height); setmetatable(o, self); self.__index = self
    o.background = false;
    
    local logicIsoObject = isoObject
    
    if craftBench then
        if craftBench.entity and instanceof(craftBench.entity, "IsoObject") then
            logicIsoObject = craftBench.entity
        elseif craftBench.getParent and instanceof(craftBench:getParent(), "IsoObject") then
            logicIsoObject = craftBench:getParent()
        end
    end
    
    o.logic = HandcraftLogic.new(player, craftBench, logicIsoObject);
    o.logic:setManualSelectInputs(ISHandCraftPanel.persistentSettings.manualSelectInputs);
    o.logic:addEventListener("onRecipeChanged", o.onRecipeChanged, o);
    o.logic:addEventListener("onUpdateRecipeList", o.onUpdateRecipeList, o);
    o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o);
    o.logic:addEventListener("onManualSelectChanged", o.onManualSelectChanged, o);
    o.logic:addEventListener("onStopCraft", o.onStopCraft, o);
    o.tooltipLogic = HandcraftLogic.new(player, craftBench, logicIsoObject);
    
    o.player = player;
    o.craftBench = craftBench;
    o.isoObject = logicIsoObject;
    o.recipeQuery = recipeQuery;
    o.leftHandedMode = true; o.recipeListMode = true;

    o.minimumWidth = 0;
    o.minimumHeight = 0;
    
    o.tooltipCounterTime = 0.75; o.tooltipCounter = o.tooltipCounterTime;
    o.tooltipRecipe = nil; o.activeTooltip = nil;
    o.updateTimer = 0; o._filterString = ""; o._filterMode = nil; o._categoryString = "";
    o.filterCanCraftEnabled = ISHandCraftPanel.persistentSettings.filterCanCraftEnabled
    o.filterPartialMatchEnabled = ISHandCraftPanel.persistentSettings.filterPartialMatchEnabled
    o.filterGivesXPEnabled = ISHandCraftPanel.persistentSettings.filterGivesXPEnabled
    o.partialMatchUpdateTimer = nil; o.needsRecipeListUpdate = false
    return o;
end