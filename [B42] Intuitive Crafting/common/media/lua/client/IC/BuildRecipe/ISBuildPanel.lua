require "ISUI/ISPanel"

local Reflection = require("Starlit/utils/Reflection")

ISBuildPanel = ISPanel:derive("ISBuildPanel");

if not ISBuildPanel.persistentSettings then
    ISBuildPanel.persistentSettings = {
        showAllFilterEnabled = false,
        filterCanCraftEnabled = true,
        filterPartialMatchEnabled = false,
        filterGivesXPEnabled = false
    }
end

function ISBuildPanel:initialise()
	ISPanel.initialise(self);
end

function ISBuildPanel:OnCloseWindow()
    self.buildEntity = nil;
    if self.player then
        getCell():setDrag(nil, self.player:getPlayerNum());
    end
end

function ISBuildPanel:createChildren()
    ISPanel.createChildren(self);

    local styleCell = "S_TableLayoutCell_Pad5";
    self.rootTable = ISXuiSkin.build(self.xuiSkin, "S_TableLayout_Main", ISTableLayout, 0, 0, 10, 10, nil, nil, styleCell);
    self.rootTable.drawDebugLines = self.drawDebugLines;
    self.rootTable:addRowFill(nil);
    self.rootTable:initialise();
    self.rootTable:instantiate();
    self:addChild(self.rootTable);

    self:createRecipeCategoryColumn();
    self:createRecipesColumn();
    self:createRecipePanel();
    self:createInventoryPanel();

    if self.recipesPanel and self.recipesPanel.recipeListPanel then
        self.recipesPanel.recipeListPanel.enabledShowAllFilter = ISBuildPanel.persistentSettings.showAllFilterEnabled
    end
    if self.recipesPanel and self.recipesPanel.recipeFilterPanel then
        if self.recipesPanel.recipeFilterPanel.tickbox then
            self.recipesPanel.recipeFilterPanel.tickbox.selected[1] = ISBuildPanel.persistentSettings.showAllFilterEnabled
        end
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
    if (viewMode == "grid") then
        self.recipeListMode = false;
    else
        self.recipeListMode = true;
    end

    self:setRecipeListMode(self.recipeListMode);
    self:updateContainers();
    self:refreshList();
end

function ISBuildPanel:refreshList()
    local currentRecipe = self.logic:getRecipe();
    local list = self.logic:getAllBuildableRecipes();
    self.logic:setRecipes(list);
    self:ReselectRecipeOrFirst(currentRecipe);
end

function ISBuildPanel:ReselectRecipeOrFirst(_recipe)
    local recipeFoundInOldList = false
    local scrollingListBox = nil
    if self.recipesPanel and self.recipesPanel.recipeListPanel and self.recipesPanel.recipeListPanel.recipeListPanel then
        scrollingListBox = self.recipesPanel.recipeListPanel.recipeListPanel
    end

    if self.recipesPanel then
        if self.recipesPanel.recipeListMode then
            if scrollingListBox and scrollingListBox.items then
                for i = 1, #scrollingListBox.items do
                    if scrollingListBox.items[i].item == _recipe then
                        recipeFoundInOldList = true;
                        break;
                    end
                end
            end
        else
            if self.recipesPanel.recipeIconPanel and self.recipesPanel.recipeIconPanel.sourceDataList and self.recipesPanel.recipeIconPanel.sourceDataList:contains(_recipe) then
                recipeFoundInOldList = true;
            end
        end
    end

    local finalSelectedRecipe = _recipe
    if not recipeFoundInOldList then
        finalSelectedRecipe = nil
    end

    if not finalSelectedRecipe and self.recipesPanel then
        if self.recipesPanel.recipeListMode then
            if scrollingListBox and scrollingListBox.items and #scrollingListBox.items > 0 then
                finalSelectedRecipe = scrollingListBox.items[1].item
            end
        else
            if self.recipesPanel.recipeIconPanel and self.recipesPanel.recipeIconPanel.sourceDataList and self.recipesPanel.recipeIconPanel.sourceDataList:size() > 0 then
                finalSelectedRecipe = self.recipesPanel.recipeIconPanel.sourceDataList:get(0)
            end
        end
    end

    if finalSelectedRecipe then
        local selectedIndexInNewList = -1
        if self.recipesPanel then
            if self.recipesPanel.recipeListMode then
                if self.recipesPanel.recipeListPanel then
                    self.recipesPanel.recipeListPanel:setSelectedData(finalSelectedRecipe);
                    if scrollingListBox and scrollingListBox.ensureVisible and scrollingListBox.items then
                        for i = 1, #scrollingListBox.items do
                            if scrollingListBox.items[i].item == finalSelectedRecipe then
                                selectedIndexInNewList = i
                                break
                            end
                        end
                        if selectedIndexInNewList ~= -1 then
                           scrollingListBox:ensureVisible(selectedIndexInNewList)
                        end
                    end
                end
            else
                if self.recipesPanel.recipeIconPanel then
                    self.recipesPanel.recipeIconPanel:setSelectedData(finalSelectedRecipe);
                end
            end
        end

        if finalSelectedRecipe ~= self.logic:getRecipe() then
            self.logic:setRecipe(finalSelectedRecipe);
        end
    elseif scrollingListBox then
        scrollingListBox.selected = 0
    end
end

function ISBuildPanel:createInventoryPanel()
    self.inventoryPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISCraftInventoryPanel, 0, 0, 10, 10, self.player, self.logic);
    self.inventoryPanel:initialise();
    self.inventoryPanel:instantiate();

    local column = self.rootTable:addColumn(nil);
    self.rootTable:setElement(column:index(), 0, self.inventoryPanel);

    self.inventoryPanelColumn = column;
    self.inventoryPanelColumn.visible = self.logic:shouldShowManualSelectInputs();
end

function ISBuildPanel:createRecipePanel()
    self.craftRecipePanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISBuildRecipePanel, 0, 0, 10, 10, self.player, self.logic);
    self.craftRecipePanel:initialise(); self.craftRecipePanel:instantiate();
    local column = self.rootTable:addColumn(nil);
    self.rootTable:setElement(column:index(), 0, self.craftRecipePanel);
end

function ISBuildPanel:createRecipeCategoryColumn()
    self.categoryColumn = self.rootTable:addColumn(nil);
    self.recipeCategories = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetRecipeCategories, 0, 0, 10, 10);
    self.recipeCategories.callbackTarget = self;
    self.recipeCategories:initialise(); self.recipeCategories:instantiate();
    self.rootTable:setElement(self.categoryColumn:index(), 0, self.recipeCategories);
end

function ISBuildPanel:onDoubleClick(item)
    if self.craftRecipePanel and self.craftRecipePanel.craftControl and self.craftRecipePanel.craftControl.buttonCraft and self.craftRecipePanel.craftControl.buttonCraft.enable then
        ISBuildWindow.instance:createBuildIsoEntity();
    end
end

function ISBuildPanel:createRecipesColumn()
    self.recipeColumn = self.rootTable:addColumnFill(nil);
    self.recipesPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetRecipesPanel, 0, 0, 10, 10, self.player, self.craftBench, self.isoObject, self.logic, self);
    self.recipesPanel.ignoreLightIcon = true; 
    self.recipesPanel.wrapTooltipText = true;

    self.recipesPanel.showAllVersionTickbox = true;
    self.recipesPanel.needSortCombo = true;
    self.recipesPanel.needFilterCombo = true;

    self.recipesPanel.ignoreSurface = true;
    self.recipesPanel:initialise(); self.recipesPanel:instantiate();
    self.recipesPanel.noTooltip = true;
    if self.recipesPanel.recipeListPanel and self.recipesPanel.recipeListPanel.recipeListPanel then
        self.recipesPanel.recipeListPanel.recipeListPanel:setOnMouseDoubleClick(self, ISBuildPanel.onDoubleClick)
    end
    self.rootTable:setElement(self.recipeColumn:index(), 0, self.recipesPanel);
    self.rootTable:cell(self.recipeColumn:index(), 0).padding = 0;
end

function ISBuildPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);
    if self.rootTable then
        self.rootTable:setX(0); self.rootTable:setY(0);
        self.rootTable:calculateLayout(width, height);
        width = math.max(width, self.rootTable:getWidth());
        height = math.max(height, self.rootTable:getHeight());
    end
    self:setWidth(width); self:setHeight(height);
end

function ISBuildPanel:onResize() ISUIElement.onResize(self) end
function ISBuildPanel:prerender() ISPanel.prerender(self); end
function ISBuildPanel:render()
    ISPanel.render(self);
    if ISEntityUI.drawDebugLines or self.drawDebugLines then
        self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 0, 1, 0);
    end
end

function ISBuildPanel:update()
    ISPanel.update(self);
    local surfaceChanged = self:hasPlayerMoved();
    if surfaceChanged then
        self:updateContainers();
        self:sortRecipeList();
    end
    if ISBuildPanel.drawDirty then
        self:updateContainers();
        ISBuildPanel.drawDirty = false;
    end
end

function ISBuildPanel:hasPlayerMoved()
    if not self.player then return false end
    local square = self.player:getCurrentSquare();
    if not square then return false; end
    if not self.playerLastSquare then self.playerLastSquare = square; end
    if self.playerLastSquare:getX() ~= square:getX() then self.playerLastSquare = square; return true; end
    if self.playerLastSquare:getY() ~= square:getY() then self.playerLastSquare = square; return true; end
    if self.playerLastSquare:getZ() ~= square:getZ() then self.playerLastSquare = square; return true; end
    return false;
end

function ISBuildPanel:updateContainers()
    local containers = ISInventoryPaneContextMenu.getContainers(self.player);
    self.logic:setContainers(containers);
    self.logic:refresh();
    if self.recipesPanel then self.recipesPanel:updateContainers(containers); end
    if self.filterCanCraftEnabled or self.filterPartialMatchEnabled or self.filterGivesXPEnabled then
        self:filterRecipeList()
    end
end


function ISBuildPanel:setRecipeListMode(_useListMode)
    if self.recipesPanel then self.recipesPanel:setRecipeListMode(_useListMode); end
    self.logic:setSelectedRecipeStyle(_useListMode and "list" or "grid");
    self:onUpdateRecipeList(self.logic:getRecipeList());
    self:ReselectRecipeOrFirst(self.logic:getRecipe())
end

function ISBuildPanel:getSelectedRecipe() return self.logic:getRecipe(); end
function ISBuildPanel:setRecipeList(_recipeList) self.logic:setRecipes(_recipeList); end
function ISBuildPanel:setRecipes(_recipeQueryOrList) self.logic:setRecipes(_recipeQueryOrList); end
function ISBuildPanel:onRecipeChanged(_recipe) if self.recipesPanel then self.recipesPanel:onRecipeChanged(_recipe); end end

function ISBuildPanel:setRecipeFilter(_filterString, _filterMode)
    self._filterString = _filterString; self._filterMode = _filterMode;
    self:filterRecipeList();
end

function ISBuildPanel:filterRecipeList()
    local effectiveFilterString = self._filterString
    if self._filterMode and self._filterString and self._filterString ~= "" then
        effectiveFilterString = self._filterString .. "-@-" .. self._filterMode;
    end
    self.logic:filterRecipeList(effectiveFilterString, self._categoryString);
    self:onUpdateRecipeList(self.logic:getRecipeList())
end

function ISBuildPanel:setSortMode(_sortMode)
    self.logic:setRecipeSortMode(_sortMode);
    self:sortRecipeList();
end

function ISBuildPanel:sortRecipeList()
    self.logic:sortRecipeList();
    self:onUpdateRecipeList(self.logic:getRecipeList())
end

function ISBuildPanel:onCategoryChanged(_category)
    self._categoryString = _category;
    self:filterRecipeList();
    self:ReselectRecipeOrFirst(self.logic:getRecipe());
end

function ISBuildPanel:onUpdateContainers()
    self:createBuildIsoEntity(true)
    if self.filterCanCraftEnabled or self.filterPartialMatchEnabled or self.filterGivesXPEnabled then
        self:filterRecipeList()
    end
end

function ISBuildPanel:createBuildIsoEntity(dontSetDrag)
    local _player = self.player; local _info = self.logic:getSelectedBuildObject(); local _recipe = self.logic:getRecipe();
    if _info ~= nil and _recipe ~= nil then
        if self.buildEntity == nil or self.buildEntity.objectInfo ~= _info then
            local containers = ISInventoryPaneContextMenu.getContainers(self.player)
            self.buildEntity = ISBuildIsoEntity:new(_player, _info, 1, containers, self.logic);
            self.buildEntity.dragNilAfterPlace = false; self.buildEntity.blockAfterPlace = true;
            local inventory = _player:getInventory();
            self.buildEntity.equipBothHandItem = ISBuildPanel.getTool(_recipe:getToolBoth(), inventory);
            self.buildEntity.firstItem = ISBuildPanel.getTool(_recipe:getToolRight(), inventory);
            self.buildEntity.secondItem = ISBuildPanel.getTool(_recipe:getToolLeft(), inventory);
        end
        local cheat = self.player:isBuildCheat() or (self.logic and self.logic.craftCheat);
        local canBuild = self.logic:canPerformCurrentRecipe() or cheat;
        if self.logic:isCraftActionInProgress() then canBuild = false; end
        if isClient() then self.buildEntity.modData = { }; self.buildEntity:updateModData() end
        self.buildEntity.blockBuild = not canBuild;
        if not dontSetDrag then getCell():setDrag(self.buildEntity, _player:getPlayerNum()); end
    else
        self.buildEntity = nil; if _player then getCell():setDrag(nil, _player:getPlayerNum()); end
    end
end

function ISBuildPanel:updateManualInputs()
    if self.buildEntity then
        self.buildEntity:updateManualInputs(self.logic);
    end
end

function ISBuildPanel:recipeGivesXP(recipe)
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

function ISBuildPanel:onUpdateRecipeList(_recipeListFromEvent)
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
    
    if self.recipeCategories then
        self.recipeCategories:populateCategoryList(); 
    end
end

function ISBuildPanel:onManualSelectChanged(_manualSelectInputs)
    if _manualSelectInputs == false then
        self.logic:setShowManualSelectInputs(false);
        self.logic:setManualSelectInputScriptFilter(nil);
    end
end

function ISBuildPanel:onShowManualSelectChanged(_showManualSelectInputs)
    self.inventoryPanelColumn:setVisible(_showManualSelectInputs, true);
    local colWidth = 0;
    local cell = self.rootTable:cellFor(self.inventoryPanel);
    if cell then
        cell:calculateLayout(0,0);
        colWidth = cell.width;
    else
        colWidth = self.inventoryPanelColumn.width;
    end
    if _showManualSelectInputs then
        local root = self:xuiRootElement();
        if root then
            self:xuiRecalculateLayout(root:getWidth()+colWidth, root:getHeight(), true, not self.leftHandedMode);
        else
            self:xuiRecalculateLayout();
        end
    else
        self:xuiRecalculateLayout(-colWidth, nil, true, not self.leftHandedMode);
    end
end

function ISBuildPanel:onStopCraft()
    self:updateContainers();
    self.logic:sortRecipeList(); self.logic:refresh();
    self:xuiRecalculateLayout(); self:createBuildIsoEntity();
end

function ISBuildPanel:getCategoryList() return self.logic:getCategoryList(); end

function ISBuildPanel:OnFilterAll(enabled)
    if self.recipesPanel and self.recipesPanel.recipeListPanel then
        self.recipesPanel.recipeListPanel.enabledShowAllFilter = enabled
        ISBuildPanel.persistentSettings.showAllFilterEnabled = enabled
    end
    self:refreshList()
end

function ISBuildPanel:onCanCraftFilterChanged(enabled)
    if self.filterCanCraftEnabled ~= enabled then
        self.filterCanCraftEnabled = enabled;
        ISBuildPanel.persistentSettings.filterCanCraftEnabled = enabled
        self:filterRecipeList();
    end
end

function ISBuildPanel:onPartialMatchFilterChanged(enabled)
    if self.filterPartialMatchEnabled ~= enabled then
        self.filterPartialMatchEnabled = enabled;
        ISBuildPanel.persistentSettings.filterPartialMatchEnabled = enabled
        self:filterRecipeList();
    end
end

function ISBuildPanel:onGivesXPFilterChanged(enabled)
    if self.filterGivesXPEnabled ~= enabled then
        self.filterGivesXPEnabled = enabled;
        ISBuildPanel.persistentSettings.filterGivesXPEnabled = enabled;
        self:filterRecipeList();
    end
end

function ISBuildPanel:canPlayerCraftRecipe(recipe)
    if not recipe then return false end; local player = self.player
    if recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do local requiredSkill = recipe:getRequiredSkill(i) if not CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, player) then return false end end
    end
    return true
end

function ISBuildPanel:hasAnyRequiredItem(recipe)
    if not recipe or not self.logic or not self.logic:getContainers() then return false end
    
    local tempLogic = BuildLogic.new(self.player, self.craftBench, self.isoObject)
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

function ISBuildPanel.getTool(_info, _inventory)
    if _info then
        local inputScript = _info; local entryItems = inputScript:getPossibleInputItems(); local item = false;
        for m=0, entryItems:size()-1 do local itemType = entryItems:get(m):getFullName(); local result = _inventory:getAllTypeEvalRecurse(itemType, ISBuildIsoEntity.predicateMaterial);
            if result:size()>0 then item = result:get(0):getFullType(); break; end
        end
        if item then return item; end
    end
    return nil;
end

function ISBuildPanel.SetDragItem(item, playerNum)
    local realPlayerNum = playerNum + 1; local windowKey = "BuildWindow";
    if not ISEntityUI or not ISEntityUI.players[realPlayerNum] or not ISEntityUI.players[realPlayerNum].windows[windowKey] or not ISEntityUI.players[realPlayerNum].windows[windowKey].instance then return; end
    if item then
        if isJoypadFocusOnElementOrDescendant(playerNum, ISEntityUI.players[realPlayerNum].windows[windowKey].instance) then setJoypadFocus(playerNum, nil) end
        ISEntityUI.players[realPlayerNum].windows[windowKey].instance:setVisible(false)
    else
        ISEntityUI.players[realPlayerNum].windows[windowKey].instance:setVisible(true)
       if JoypadState.players[realPlayerNum] then JoypadState.players[realPlayerNum].focus = ISEntityUI.players[realPlayerNum].windows[windowKey].instance end
    end
end

function ISBuildPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = ISPanel:new(x, y, width, height); setmetatable(o, self); self.__index = self
    o.background = false;
    o.logic = BuildLogic.new(player, craftBench, isoObject);
    o.logic:addEventListener("onUpdateContainers", o.onUpdateContainers, o);
    o.logic:addEventListener("onRecipeChanged", o.onRecipeChanged, o);
    o.logic:addEventListener("onUpdateRecipeList", o.onUpdateRecipeList, o);
    o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o);
    o.logic:addEventListener("onManualSelectChanged", o.onManualSelectChanged, o);
    o.logic:addEventListener("onStopCraft", o.onStopCraft, o);

    o.player = player;
    o.craftBench = craftBench;
    o.isoObject = isoObject;
    o.recipeQuery = recipeQuery;
    o.leftHandedMode = true; o.recipeListMode = true;

    o.minimumWidth = 0;
    o.minimumHeight = 0;

    o.playerLastSquare = nil; o.drawDebugLines = false;
    ISBuildWindow.instance = o;
    o._filterString = ""; o._filterMode = nil; o._categoryString = "";
    o.filterCanCraftEnabled = ISBuildPanel.persistentSettings.filterCanCraftEnabled
    o.filterPartialMatchEnabled = ISBuildPanel.persistentSettings.filterPartialMatchEnabled
    o.filterGivesXPEnabled = ISBuildPanel.persistentSettings.filterGivesXPEnabled
    return o;
end

Events.SetDragItem.Add(ISBuildPanel.SetDragItem);