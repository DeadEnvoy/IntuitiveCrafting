require "ISUI/ISPanelJoypad"

local FONT_HGT_SEARCH = getTextManager():getFontHeight(UIFont.Medium);
local FONT_HGT_SMALL_TEXT = getTextManager():getFontHeight(UIFont.Small);
local UI_GENERAL_SPACING = 5
local BUTTON_HGT_SEARCH = FONT_HGT_SEARCH + 6

ISWidgetRecipeFilterPanel = ISPanelJoypad:derive("ISWidgetRecipeFilterPanel");

function ISWidgetRecipeFilterPanel:initialise()
	ISPanelJoypad.initialise(self);
end

function ISWidgetRecipeFilterPanel:createChildren()
    ISPanelJoypad.createChildren(self);

    local fontHeight = -1;

    self.entryBox = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISTextEntryBox, "", 0, 0, 10, BUTTON_HGT_SEARCH);
    self.entryBox.font = UIFont.NewSmall;
    self.entryBox:initialise();
    self.entryBox:instantiate();
    self.entryBox.onTextChange = ISWidgetRecipeFilterPanel.onTextChange;
    self.entryBox.target = self;
    self.entryBox:setClearButton(true);
    self.entryBox.javaObject:setCentreVertically(true);
    self:addChild(self.entryBox);

    if self.needFilterCombo then
        self.filterTypeCombo = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISComboBox, 0, 0, 10, BUTTON_HGT_SEARCH, self, ISWidgetRecipeFilterPanel.OnClickFilterType);
        self.filterTypeCombo.font = UIFont.NewSmall;
        self.filterTypeCombo:initialise();
        self.filterTypeCombo:instantiate();
        self.filterTypeCombo.target = self;
        self.filterTypeCombo.doRepaintStencil = true
        self:addChild(self.filterTypeCombo);
        self:populateComboList();
    end

    if self.needSortCombo then
        self.sortCombo = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISComboBox, 0, 0, 10, BUTTON_HGT_SEARCH, self, ISWidgetRecipeFilterPanel.OnClickSortType);
        self.sortCombo.font = UIFont.NewSmall;
        self.sortCombo:initialise();
        self.sortCombo:instantiate();
        self.sortCombo.target = self;
        self.sortCombo.doRepaintStencil = true
        self:addChild(self.sortCombo);
        self:populateSortList();
    end

    self.searchHackLabel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISLabel, 0, 0, fontHeight, self.searchInfoText, 0.3, 0.3, 0.3, 1, UIFont.NewSmall, true)
    self.searchHackLabel:initialise();
    self.searchHackLabel:instantiate();
    self:addChild(self.searchHackLabel);

    self.buttonGrid = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISButton, 0, 0, BUTTON_HGT_SEARCH, BUTTON_HGT_SEARCH, nil)
    self.buttonGrid.image = getTexture("media/ui/craftingMenus/Icon_Grid.png");
    self.buttonGrid.target = self;
    self.buttonGrid.onclick = ISWidgetRecipeFilterPanel.onButtonClick;
    self.buttonGrid.enable = true;
    self.buttonGrid:initialise();
    self.buttonGrid:instantiate();
    self:addChild(self.buttonGrid);

    self.buttonList = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISButton, 0, 0, BUTTON_HGT_SEARCH, BUTTON_HGT_SEARCH, nil)
    self.buttonList.image = getTexture("media/ui/craftingMenus/Icon_List.png");
    self.buttonList.target = self;
    self.buttonList.onclick = ISWidgetRecipeFilterPanel.onButtonClick;
    self.buttonList.enable = true;
    self.buttonList:initialise();
    self.buttonList:instantiate();
    self:addChild(self.buttonList);

    if self.needFilterCombo then
        local filterPanelObject = self

        local initialShowAllState = false
        if self.callbackTarget then
            if self.callbackTarget.recipesPanel and self.callbackTarget.recipesPanel.recipeListPanel then
                initialShowAllState = self.callbackTarget.recipesPanel.recipeListPanel.enabledShowAllFilter
            elseif self.callbackTarget.persistentSettings then
                 initialShowAllState = self.callbackTarget.persistentSettings.showAllFilterEnabled or false
            end
        end

        if self.showAllVersionTickbox then
            self.tickbox = ISTickBox:new(0, 0, 15, FONT_HGT_SMALL_TEXT, "tickbox",
                filterPanelObject,
                function(targetInstance, clickedOption, enabled)
                    if filterPanelObject and type(filterPanelObject.OnShowAllClick) == "function" then
                        filterPanelObject:OnShowAllClick(clickedOption, enabled)
                    end
                end)
            if self.xuiSkin then self.tickbox.xuiSkin = self.xuiSkin end
            self.tickbox.parent = self;
            self.tickbox:initialise();
            self.tickbox:instantiate();
            self.tickbox.selected[1] = initialShowAllState;
            self.tickbox:addOption(getText("IGUI_CraftingFilters_ShowAllVersion"));
            self:addChild(self.tickbox);
        end

        local initialCanCraftState = false
        if self.callbackTarget and self.callbackTarget.filterCanCraftEnabled ~= nil then
            initialCanCraftState = self.callbackTarget.filterCanCraftEnabled
        end

        self.canCraftTickbox = ISTickBox:new(0, 0, 15, FONT_HGT_SMALL_TEXT, "canCraftTickbox",
            filterPanelObject,
            function(targetInstance, clickedOption, enabled)
                if filterPanelObject and type(filterPanelObject.OnCanCraftClick) == "function" then
                    filterPanelObject:OnCanCraftClick(clickedOption, enabled)
                end
            end)
        if self.xuiSkin then self.canCraftTickbox.xuiSkin = self.xuiSkin end
        self.canCraftTickbox.parent = self;
        self.canCraftTickbox:initialise();
        self.canCraftTickbox:instantiate();
        self.canCraftTickbox.selected[1] = initialCanCraftState;
        self.canCraftTickbox:addOption(getText("IGUI_CraftingFilters_CanCraft"));
        self:addChild(self.canCraftTickbox);

        local initialPartialMatchState = false
        if self.callbackTarget and self.callbackTarget.filterPartialMatchEnabled ~= nil then
            initialPartialMatchState = self.callbackTarget.filterPartialMatchEnabled
        end

        self.partialMatchTickbox = ISTickBox:new(0, 0, 15, FONT_HGT_SMALL_TEXT, "partialMatchTickbox",
            filterPanelObject,
            function(targetInstance, clickedOption, enabled)
                if filterPanelObject and type(filterPanelObject.OnPartialMatchClick) == "function" then
                    filterPanelObject:OnPartialMatchClick(clickedOption, enabled)
                end
            end)
        if self.xuiSkin then self.partialMatchTickbox.xuiSkin = self.xuiSkin end
        self.partialMatchTickbox.parent = self;
        self.partialMatchTickbox:initialise();
        self.partialMatchTickbox:instantiate();
        self.partialMatchTickbox.selected[1] = initialPartialMatchState;
        self.partialMatchTickbox:addOption(getText("IGUI_CraftingFilters_PartialMatch"));
        self:addChild(self.partialMatchTickbox);

        local initialGivesXPState = false
        if self.callbackTarget and self.callbackTarget.filterGivesXPEnabled ~= nil then
            initialGivesXPState = self.callbackTarget.filterGivesXPEnabled
        end

        self.xpTickbox = ISTickBox:new(0, 0, 15, FONT_HGT_SMALL_TEXT, "xpTickbox",
            filterPanelObject,
            function(targetInstance, clickedOption, enabled)
                if filterPanelObject and type(filterPanelObject.OnGivesXPClick) == "function" then
                    filterPanelObject:OnGivesXPClick(clickedOption, enabled)
                end
            end)
        if self.xuiSkin then self.xpTickbox.xuiSkin = self.xuiSkin end
        self.xpTickbox.parent = self;
        self.xpTickbox:initialise();
        self.xpTickbox:instantiate();
        self.xpTickbox.selected[1] = initialGivesXPState;
        self.xpTickbox:addOption(getText("IGUI_CraftingFilters_GivesXP"));
        self:addChild(self.xpTickbox);
    end

    self.joypadButtonsY = {}
    self.joypadButtons = {}
    self.joypadIndexY = 1
    self.joypadIndex = 1

    local firstRowButtons = {self.entryBox}
    if self.filterTypeCombo then table.insert(firstRowButtons, self.filterTypeCombo) end
    if self.sortCombo then table.insert(firstRowButtons, self.sortCombo) end
    table.insert(firstRowButtons, self.buttonGrid)
    table.insert(firstRowButtons, self.buttonList)
    self:insertNewLineOfButtons(unpack(firstRowButtons))

    if self.needFilterCombo then
        local secondRowButtons = {}
        if self.showAllVersionTickbox and self.tickbox then table.insert(secondRowButtons, self.tickbox) end
        if self.canCraftTickbox then table.insert(secondRowButtons, self.canCraftTickbox) end
        if self.partialMatchTickbox then table.insert(secondRowButtons, self.partialMatchTickbox) end
        if self.xpTickbox then table.insert(secondRowButtons, self.xpTickbox) end
        if #secondRowButtons > 0 then
            self:insertNewLineOfButtons(unpack(secondRowButtons))
        end
    end
end

function ISWidgetRecipeFilterPanel:populateComboList()
    if not self.filterTypeCombo then return end
    self.filterTypeCombo:clear();
    self.filterTypeCombo:addOptionWithData(getText("IGUI_FilterType_RecipeName"), "RecipeName")
    self.filterTypeCombo:addOptionWithData(getText("IGUI_FilterType_InputName"), "InputName")
    self.filterTypeCombo:addOptionWithData(getText("IGUI_FilterType_OutputName"), "OutputName")
    local tooltipMap = {};
    tooltipMap[getText("IGUI_FilterType_RecipeName")] = getText("IGUI_FilterType_RecipeNameTooltip");
    tooltipMap[getText("IGUI_FilterType_InputName")] = getText("IGUI_FilterType_InputNameTooltip");
    tooltipMap[getText("IGUI_FilterType_OutputName")] = getText("IGUI_FilterType_OutputNameTooltip");
    self.filterTypeCombo:setToolTipMap(tooltipMap);
    self.filterTypeCombo:setWidthToOptions(50);
end

function ISWidgetRecipeFilterPanel:populateSortList()
    if not self.sortCombo then return end
    self.sortCombo:clear();
    self.sortCombo:addOptionWithData(getText("IGUI_SortType_RecipeName"), "RecipeName")
    self.sortCombo:addOptionWithData(getText("IGUI_SortType_LastUsed"), "LastUsed")
    self.sortCombo:addOptionWithData(getText("IGUI_SortType_MostUsed"), "MostUsed")
    local tooltipMap = {};
    tooltipMap[getText("IGUI_SortType_RecipeName")] = getText("IGUI_SortType_RecipeNameTooltip");
    tooltipMap[getText("IGUI_SortType_LastUsed")] = getText("IGUI_SortType_LastUsedTooltip");
    tooltipMap[getText("IGUI_SortType_MostUsed")] = getText("IGUI_SortType_MostUsedTooltip");
    self.sortCombo:setToolTipMap(tooltipMap);
    self.sortCombo:setWidthToOptions(50);
    if self.callbackTarget and self.callbackTarget.logic and type(self.callbackTarget.logic.getRecipeSortMode) == "function" then
        local sortMode = self.callbackTarget.logic:getRecipeSortMode();
        self.sortCombo:selectData(sortMode);
    end
end

function ISWidgetRecipeFilterPanel:OnShowAllClick(clickedOption, enabled)
    if self.callbackTarget and self.callbackTarget.OnFilterAll and type(self.callbackTarget.OnFilterAll) == "function" then
        self.callbackTarget:OnFilterAll(enabled);
    end
end

function ISWidgetRecipeFilterPanel:OnCanCraftClick(clickedOption, enabled)
    if self.callbackTarget and self.callbackTarget.onCanCraftFilterChanged and type(self.callbackTarget.onCanCraftFilterChanged) == "function" then
        self.callbackTarget:onCanCraftFilterChanged(enabled);
    end
end

function ISWidgetRecipeFilterPanel:OnPartialMatchClick(clickedOption, enabled)
    if self.callbackTarget and self.callbackTarget.onPartialMatchFilterChanged and type(self.callbackTarget.onPartialMatchFilterChanged) == "function" then
        self.callbackTarget:onPartialMatchFilterChanged(enabled);
    end
end

function ISWidgetRecipeFilterPanel:OnGivesXPClick(clickedOption, enabled)
    if self.callbackTarget and self.callbackTarget.onGivesXPFilterChanged and type(self.callbackTarget.onGivesXPFilterChanged) == "function" then
        self.callbackTarget:onGivesXPFilterChanged(enabled);
    end
end

function ISWidgetRecipeFilterPanel:onButtonClick(_button)
    if self.buttonGrid and _button==self.buttonGrid then
        if self.callbackTarget and self.callbackTarget.setRecipeListMode then self.callbackTarget:setRecipeListMode(false) end;
    elseif self.buttonList and _button==self.buttonList then
        if self.callbackTarget and self.callbackTarget.setRecipeListMode then self.callbackTarget:setRecipeListMode(true) end;
    end
end

function ISWidgetRecipeFilterPanel:OnClickFilterType(box)
    local mode = nil;
    if box:getSelected() > 1 then
        mode = box.options[box:getSelected()].data;
    end
    if box.parent.entryBox.target.callbackTarget and box.parent.entryBox.target.callbackTarget.setRecipeFilter then
        box.parent.entryBox.target.callbackTarget:setRecipeFilter(box.parent.entryBox:getInternalText(), mode);
    end
end

function ISWidgetRecipeFilterPanel:OnClickSortType(box)
    local mode = nil;
    if box:getSelected() > 0 then
        mode = box.options[box:getSelected()].data;
    end
    if box.parent.entryBox.target.callbackTarget and box.parent.entryBox.target.callbackTarget.setSortMode then
        box.parent.entryBox.target.callbackTarget:setSortMode(mode);
    end
end

function ISWidgetRecipeFilterPanel.onTextChange(box)
    if not box then return; end
    local mode = nil;
    if box.parent.filterTypeCombo and box.parent.filterTypeCombo:getSelected() > 1 then
        mode = box.parent.filterTypeCombo.options[box.parent.filterTypeCombo:getSelected()].data;
    end
    local currentSearchText = box:getInternalText()
    if currentSearchText ~= box.target.searchInfoText then
        if currentSearchText ~= box.target.searchText then
            if box.target.callbackTarget and box.target.callbackTarget.setRecipeFilter then
                box.target.callbackTarget:setRecipeFilter(currentSearchText, mode);
            end
        end
    elseif currentSearchText == "" and box.target.searchText ~= "" then
         if box.target.callbackTarget and box.target.callbackTarget.setRecipeFilter then
            box.target.callbackTarget:setRecipeFilter("", mode);
         end
    end
    box.target.searchText = currentSearchText
end

function ISWidgetRecipeFilterPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);

    local CHECKBOX_BOX_SIZE = FONT_HGT_SMALL_TEXT;
    local CHECKBOX_TEXT_GAP = UI_GENERAL_SPACING;
    local CHECKBOX_SPACING_AFTER = 15;

    local testHeight = self.entryBox:getHeight()+(self.margin*2);
    if self.tickbox or self.canCraftTickbox or self.partialMatchTickbox or self.xpTickbox then
        testHeight = testHeight + FONT_HGT_SMALL_TEXT + 3;
    end
    height = math.max(height, testHeight);

    local entryBoxWidth = getTextManager():MeasureStringX(UIFont.NewSmall, self.searchHackLabel.name) + ((UI_GENERAL_SPACING+1)*2);
    local testWidth = self.margin + entryBoxWidth + (self.buttonGrid:getWidth() + UI_GENERAL_SPACING+1 + self.buttonList:getWidth() + UI_GENERAL_SPACING+1) + self.margin;
    if self.filterTypeCombo then
        testWidth = testWidth +  self.filterTypeCombo:getWidth() + ((UI_GENERAL_SPACING+1));
    end
    if self.sortCombo then
        testWidth = testWidth + self.sortCombo:getWidth() + ((UI_GENERAL_SPACING+1));
    end
    width = math.max(width, testWidth);

    local buttonX = width - (self.buttonGrid:getWidth() + UI_GENERAL_SPACING+1 + self.buttonList:getWidth() + UI_GENERAL_SPACING+1);
    self.buttonGrid:setX(buttonX);
    self.buttonGrid:setY(UI_GENERAL_SPACING+1);

    self.buttonList:setX(buttonX + self.buttonGrid:getWidth() + UI_GENERAL_SPACING+1);
    self.buttonList:setY(UI_GENERAL_SPACING+1);

    local searchWidth = buttonX - ((UI_GENERAL_SPACING+1)*2);
    if self.filterTypeCombo then
        searchWidth = searchWidth - (self.filterTypeCombo:getWidth() + UI_GENERAL_SPACING);
    end
    if self.sortCombo then
        searchWidth = searchWidth - (self.sortCombo:getWidth() + UI_GENERAL_SPACING);
    end

    local comboX = UI_GENERAL_SPACING+1 + searchWidth + UI_GENERAL_SPACING;
    if self.filterTypeCombo then
        self.filterTypeCombo:setX(comboX)
        self.filterTypeCombo:setY(UI_GENERAL_SPACING+1)
        comboX = comboX + self.filterTypeCombo:getWidth() + UI_GENERAL_SPACING;
    end
    if self.sortCombo then
        self.sortCombo:setX(comboX)
        self.sortCombo:setY(UI_GENERAL_SPACING+1)
    end

    self.entryBox:setX(UI_GENERAL_SPACING+1);
    self.entryBox:setY(UI_GENERAL_SPACING+1)
    self.entryBox:setWidth(searchWidth);

    self.searchHackLabel:setX(self.entryBox:getX()+4);
    self.searchHackLabel.originalX = self.searchHackLabel:getX();
    local y = self.entryBox:getY() + (self.entryBox:getHeight()/2);
    y = y - self.searchHackLabel:getHeight()/2;
    self.searchHackLabel:setY(y);

    local currentTickboxX = self.entryBox:getX();
    local tickboxY = self.entryBox:getY() + self.entryBox:getHeight() + 3;

    if self.tickbox then
        local text = getText("IGUI_CraftingFilters_ShowAllVersion");
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, text);
        local actualCheckboxWidth = CHECKBOX_BOX_SIZE + CHECKBOX_TEXT_GAP + textWidth;

        self.tickbox:setX(currentTickboxX);
        self.tickbox:setY(tickboxY);
        self.tickbox:setWidth(actualCheckboxWidth);

        currentTickboxX = currentTickboxX + actualCheckboxWidth + CHECKBOX_SPACING_AFTER;
    end
    if self.canCraftTickbox then
        local text = getText("IGUI_CraftingFilters_CanCraft");
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, text);
        local actualCheckboxWidth = CHECKBOX_BOX_SIZE + CHECKBOX_TEXT_GAP + textWidth;

        self.canCraftTickbox:setX(currentTickboxX);
        self.canCraftTickbox:setY(tickboxY);
        self.canCraftTickbox:setWidth(actualCheckboxWidth);

        currentTickboxX = currentTickboxX + actualCheckboxWidth + CHECKBOX_SPACING_AFTER;
    end
    if self.partialMatchTickbox then
        local text = getText("IGUI_CraftingFilters_PartialMatch");
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, text);
        local actualCheckboxWidth = CHECKBOX_BOX_SIZE + CHECKBOX_TEXT_GAP + textWidth;

        self.partialMatchTickbox:setX(currentTickboxX);
        self.partialMatchTickbox:setY(tickboxY);
        self.partialMatchTickbox:setWidth(actualCheckboxWidth);

        currentTickboxX = currentTickboxX + actualCheckboxWidth + CHECKBOX_SPACING_AFTER;
    end
    if self.xpTickbox then
        local text = getText("IGUI_CraftingFilters_GivesXP");
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, text);
        local actualCheckboxWidth = CHECKBOX_BOX_SIZE + CHECKBOX_TEXT_GAP + textWidth;

        self.xpTickbox:setX(currentTickboxX);
        self.xpTickbox:setY(tickboxY);
        self.xpTickbox:setWidth(actualCheckboxWidth);
    end


    self:setWidth(width);
    self:setHeight(height);
end

function ISWidgetRecipeFilterPanel:onResize()
    ISUIElement.onResize(self)
end

function ISWidgetRecipeFilterPanel:prerender()
    ISPanelJoypad.prerender(self);
    if self.entryBox:isFocused() or (self.entryBox:getText() and #self.entryBox:getText()>0) then
        self.searchHackLabel:setVisible(false);
    else
        self.searchHackLabel:setVisible(true);
    end
end

function ISWidgetRecipeFilterPanel:render()
    ISPanelJoypad.render(self);
    self:renderJoypadFocus()
end

function ISWidgetRecipeFilterPanel:update()
    ISPanelJoypad.update(self);
end

function ISWidgetRecipeFilterPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self:restoreJoypadFocus(joypadData)
end

function ISWidgetRecipeFilterPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self.entryBox:unfocus()
    self:clearJoypadFocus()
end

function ISWidgetRecipeFilterPanel:setHandCraftPanelTarget(target)
    self.callbackTarget = target
    if self.needSortCombo then
        self:populateSortList()
    end

    if self.callbackTarget then
        if self.tickbox then
            local initialShowAllState = false
            if self.callbackTarget.recipesPanel and self.callbackTarget.recipesPanel.recipeListPanel then
                 initialShowAllState = self.callbackTarget.recipesPanel.recipeListPanel.enabledShowAllFilter
            elseif self.callbackTarget.persistentSettings then
                 initialShowAllState = self.callbackTarget.persistentSettings.showAllFilterEnabled or false
            end
            self.tickbox.selected[1] = initialShowAllState
        end
        if self.canCraftTickbox then
            self.canCraftTickbox.selected[1] = self.callbackTarget.filterCanCraftEnabled or false
        end
        if self.partialMatchTickbox then
            self.partialMatchTickbox.selected[1] = self.callbackTarget.filterPartialMatchEnabled or false
        end
        if self.xpTickbox then
            self.xpTickbox.selected[1] = self.callbackTarget.filterGivesXPEnabled or false
        end
    end
end

function ISWidgetRecipeFilterPanel:new(x, y, width, height)
    local o = ISPanelJoypad.new(self, x, y, width, height);
    o.callbackTarget = nil;
    o.backgroundColor = {r=0, g=0, b=0, a=0};
    o.paddingTop = 2;
    o.paddingBottom = 2;
    o.paddingLeft = 2;
    o.paddingRight = 2;
    o.marginTop = 5;
    o.marginBottom = 5;
    o.marginLeft = 5;
    o.marginRight = 5;
    o.margin = UI_GENERAL_SPACING;
    o.searchText = "";
    o.autoFillContents = false;
    o.isAutoFill = false;
    o.isAutoFillX = false;
    o.isAutoFillY = false;
    return o
end