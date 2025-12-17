require "ISUI/ISPanel"

local UI_BORDER_SPACING = 10
local LIST_FAVICON_SIZE = 16

ISWidgetRecipesPanel = ISPanel:derive("ISWidgetRecipesPanel");

function ISWidgetRecipesPanel:initialise()
    ISPanel.initialise(self);
end

function ISWidgetRecipesPanel:createChildren()
    ISPanel.createChildren(self);

    local styleCell = "S_TableLayoutCell_Pad2";

    self.recipeTable = ISXuiSkin.build(self.xuiSkin, "S_TableLayout_Main", ISTableLayout, 0, 0, 10, 10, nil, nil, styleCell);
    self.recipeTable.drawDebugLines = self.drawDebugLines;
    self.recipeTable:addColumnFill(nil);
    self.recipeTable:initialise();
    self.recipeTable:instantiate();
    self:addChild(self.recipeTable);

    self:createRecipeFilterPanel(self.recipeTable);
    self:createRecipeListPanel(self.recipeTable);
    self:createRecipeIconPanel(self.recipeTable);

    self.starUnsetTexture = getTexture("media/ui/inventoryPanes/FavouriteNo.png")
    self.starSetTexture = getTexture("media/ui/inventoryPanes/FavouriteYes.png")
end

function ISWidgetRecipesPanel:OnFilterAll(filter)
    if self.recipeListPanel then
        self.recipeListPanel.enabledShowAllFilter = filter;
        if self.callbackTarget and self.callbackTarget.refreshRecipeList then
            self.callbackTarget:refreshRecipeList()
        end
    end
end

function ISWidgetRecipesPanel:createRecipeFilterPanel(_parentTable)
    self.recipeFilterPanel = ISWidgetRecipeFilterPanel:new(0, 0, 10, 10, self.callbackTarget); 
    if self.xuiSkin then self.recipeFilterPanel.xuiSkin = self.xuiSkin; end
    self.recipeFilterPanel.parent = self;

    self.recipeFilterPanel.searchInfoText = getText("IGUI_CraftingWindow_SearchRecipes");
    self.recipeFilterPanel.showAllVersionTickbox = self.showAllVersionTickbox;
    self.recipeFilterPanel.needFilterCombo = self.needFilterCombo;
    self.recipeFilterPanel.needSortCombo = self.needSortCombo;
    
    self.recipeFilterPanel:initialise();
    self.recipeFilterPanel:instantiate();

    if self.recipeFilterPanel.setHandCraftPanelTarget then
        self.recipeFilterPanel:setHandCraftPanelTarget(self.callbackTarget) 
    end

    self.recipeFilterPanelRow = _parentTable:addRow(nil);
    _parentTable:setElement(0, self.recipeFilterPanelRow:index(), self.recipeFilterPanel);
end

function ISWidgetRecipesPanel:createRecipeListPanel(_parentTable)
    self.recipeListPanelRow = _parentTable:addRowFill(nil);

    self.recipeListPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetRecipeListPanel, 0, 0, 10, 10, self.player, self.logic, self);
    self.recipeListPanel.expandToFitTooltip = self.expandToFitTooltip;
    self.recipeListPanel.wrapTooltipText = self.wrapTooltipText;
    self.recipeListPanel.ignoreSurface = self.ignoreSurface;
    self.recipeListPanel.ignoreLightIcon = self.ignoreLightIcon;
    self.recipeListPanel:initialise();
    self.recipeListPanel:instantiate();

    _parentTable:setElement(0, self.recipeListPanelRow:index(), self.recipeListPanel);
    _parentTable:cell(0, self.recipeListPanelRow:index()).padding = 0;
end

function ISWidgetRecipesPanel:createRecipeIconPanel(_parentTable)
    self.recipeIconPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISTiledIconPanel, 0, 0, 10, 10, self.player, nil, self.callbackTarget);
    self.recipeIconPanel.enableSearchBox = false;

    local recipesPanelInstance = self 

    self.recipeIconPanel.onRenderTile = function(_self_icon_list_box, _recipe, _x, _y, _width, _height, _mouseover)
        local craftRecipe = _recipe;
        if craftRecipe and craftRecipe:getIconTexture() then
            local a,r,g,b = 1.0,1.0,1.0,1.0;
            
            local currentPanelLogic = recipesPanelInstance.logic
            if not currentPanelLogic and recipesPanelInstance.callbackTarget then
                 currentPanelLogic = recipesPanelInstance.callbackTarget.logic
            end

            if currentPanelLogic and instanceof(currentPanelLogic, "BaseCraftingLogic") then
                local info = currentPanelLogic:getCachedRecipeInfo(craftRecipe);
                if info and (not info:isValid()) then
                    r = 0.3; g = 0.25; b = 0.25; a = 0.5;
                elseif info and (not info:isCanPerform()) then
                    r = 0.5; g = 0.5; b = 0.5;
                end
            end

            _self_icon_list_box:drawTextureScaledAspect(craftRecipe:getIconTexture(), _x, _y, _width, _height,  a, r, g, b);

            local favString = BaseCraftingLogic.getFavouriteModDataString(craftRecipe);
            local playerForFav = recipesPanelInstance.player
            if not playerForFav and recipesPanelInstance.callbackTarget then
                 playerForFav = recipesPanelInstance.callbackTarget.player
            end

            if playerForFav then
                local isFavourite = playerForFav:getModData()[favString] or false;
                if isFavourite then
                    _self_icon_list_box:drawTextureScaledAspect(recipesPanelInstance.starSetTexture, _x + _width - LIST_FAVICON_SIZE, _y, LIST_FAVICON_SIZE, LIST_FAVICON_SIZE, a, getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB());
                end
            end
        else
            _self_icon_list_box:drawRectBorderStatic(_x, _y, _width, _height, 1.0, 0.5, 0.5, 0.5);
        end
    end

    self.recipeIconPanel.onTileClicked = function (_self_icon_panel, _recipe) 
        if _self_icon_panel.callbackTarget and _self_icon_panel.callbackTarget.logic then
             _self_icon_panel.callbackTarget.logic:setRecipe(_recipe);
        end
    end

    self.recipeIconPanel.onTileMouseHover = function(_self_icon_panel, _recipe)
        recipesPanelInstance.tooltipRecipe = _recipe; 
        recipesPanelInstance.tooltipCounter = recipesPanelInstance.tooltipCounterTime;
    end

    self.recipeIconPanel.onPageScrolled = function(_self_icon_panel, _newPage) 
        recipesPanelInstance.tooltipCounter = (recipesPanelInstance.tooltipCounterTime*4);
    end

    self.recipeIconPanel.render = function(_self_icon_panel)
        ISTiledIconPanel.render(_self_icon_panel)
        _self_icon_panel:renderJoypadFocus()
    end

    self.recipeIconPanel:initialise();
    self.recipeIconPanel:instantiate();

    self.recipeIconPanelRow = _parentTable:addRowFill(nil);
    _parentTable:setElement(0, self.recipeIconPanelRow:index(), self.recipeIconPanel);
end

function ISWidgetRecipesPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);

    if self.recipeTable then
        self.recipeTable:calculateLayout(width, height);
        width = math.max(width, self.recipeTable:getWidth());
        height = math.max(height, self.recipeTable:getHeight());
    end
    
    if self.recipeListPanelRow and self.recipeListPanelRow.visible then
        if self.recipeListPanel then
            local cell = self.recipeTable:cellFor(self.recipeListPanel);
            if cell then 
                local cellHeight = cell:getHeight() - UI_BORDER_SPACING;
                local cellWidth = cell:getWidth() - UI_BORDER_SPACING;
                local cellX = cell:getX() + UI_BORDER_SPACING/2;
                local cellY = UI_BORDER_SPACING/2;
                self.recipeListPanel:setInternalDimensions(cellX, cellY, cellWidth, cellHeight);
            end
        end
    end

    self:setWidth(width);
    self:setHeight(height);
    self.tooltipRecipe = nil;
end

function ISWidgetRecipesPanel:onResize()
    ISUIElement.onResize(self)
end

function ISWidgetRecipesPanel:prerender()
    ISPanel.prerender(self);
    if self.tooltipCounter>0 then
        self.tooltipCounter = self.tooltipCounter-UIManager.getSecondsSinceLastUpdate();
    end
    self:updateTooltip();
end

function ISWidgetRecipesPanel:render()
    ISPanel.render(self);
end

function ISWidgetRecipesPanel:update()
    ISPanel.update(self);
end

function ISWidgetRecipesPanel:getActivePanel()
    return self.recipeListMode and self.recipeListPanel or self.recipeIconPanel;
end

function ISWidgetRecipesPanel:setRecipeListMode(_useListMode)
    ISCraftRecipeTooltip.deactivateToolTipFor(self.recipeListPanel);
    ISCraftRecipeTooltip.deactivateToolTipFor(self.recipeIconPanel);
    self.recipeListMode = _useListMode;
    self.recipeIconPanelRow:setVisible(not self.recipeListMode, true);
    self.recipeListPanelRow:setVisible(self.recipeListMode, true);
    self.recipeTable:xuiRecalculateLayout();
    self:xuiRecalculateLayout();
end

function ISWidgetRecipesPanel:onRecipeChanged(_recipe)
    local activePanel = self:getActivePanel();
    if activePanel then
        activePanel:setSelectedData(_recipe);
    end
    self:xuiRecalculateLayout();
end

function ISWidgetRecipesPanel:filterRecipeList()
    local activePanel = self:getActivePanel();
    if activePanel == self.recipeIconPanel then
        if self.recipeFilterPanel then
            activePanel:filterData(self.recipeFilterPanel.searchText); 
        end
    end
end

function ISWidgetRecipesPanel:onUpdateRecipeList(_recipeList)
    local activePanel = self:getActivePanel();
    if activePanel then
        activePanel:setDataList(_recipeList);
    end
end

function ISWidgetRecipesPanel:onRecipeItemMouseHover(_item)
    if self.noTooltip then return; end
    self.tooltipRecipe = _item and _item.item;
    self.tooltipCounter = self.tooltipCounterTime;
end

function ISWidgetRecipesPanel:onRecipeListPanelScrolled()
    self.tooltipCounter = (self.tooltipCounterTime*4);
end

function ISWidgetRecipesPanel:updateTooltip()
    if self.noTooltip then return; end
    if not self.tooltipRecipe then
        self:deactivateTooltip();
        return;
    end
    local titleOnly = self.tooltipCounter>0;
    if self.activeTooltip then
        self.activeTooltip:setRecipe(self.tooltipRecipe, titleOnly);
    else
        if self.tooltipLogic then
            self.tooltipLogic:setRecipe(self.tooltipRecipe);
            local activePanel = self:getActivePanel();
            self.activeTooltip = ISCraftRecipeTooltip.activateToolTipFor(activePanel, self.player, self.tooltipRecipe, self.tooltipLogic, true, titleOnly);
        end
    end
end

function ISWidgetRecipesPanel:updateContainers(_containers)
    if self.tooltipLogic then
        self.tooltipLogic:setContainers(_containers);
    end
end

function ISWidgetRecipesPanel:deactivateTooltip()
    if self.activeTooltip then
        local activePanel = self:getActivePanel();
        ISCraftRecipeTooltip.deactivateToolTipFor(activePanel);
        self.activeTooltip = nil;
    end
end

function ISWidgetRecipesPanel:getPlayer()
    return self.player;
end

function ISWidgetRecipesPanel:getLogic()
    return self.logic;
end

function ISWidgetRecipesPanel:new(x, y, width, height, player, craftBench, isoObject, logic, callbackTarget)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.player = player;
    o.logic = logic;
    o.callbackTarget = callbackTarget; 
    
    o.tooltipLogic = HandcraftLogic.new(player, craftBench, isoObject);
    o.tooltipCounterTime = 0;
    o.tooltipCounter = o.tooltipCounterTime;
    o.tooltipRecipe = nil;
    o.activeTooltip = nil;
    o.expandToFitTooltip = false;
    o.wrapTooltipText = false;
    
    return o
end