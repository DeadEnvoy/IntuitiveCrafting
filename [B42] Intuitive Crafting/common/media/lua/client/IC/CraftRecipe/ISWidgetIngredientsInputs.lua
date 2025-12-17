require "ISUI/ISPanelJoypad"

local UI_BORDER_SPACING = 10
local TOGGLE_HGT = getTextManager():getFontHeight(UIFont.Medium);

ISWidgetIngredientsInputs = ISPanelJoypad:derive("ISWidgetIngredientsInputs");

function ISWidgetIngredientsInputs:initialise()
	ISPanelJoypad.initialise(self);
end

function ISWidgetIngredientsInputs:createChildren()
    ISPanelJoypad.createChildren(self);

    local recipe = self.logic and self.logic:getRecipe() or self.recipe;

    local fontHeight = -1;
    
    self.toolsLabel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISLabel, 0, 0, fontHeight, getText("IGUI_CraftingWindow_Tools") or "Tools", 1.0, 1.0, 1.0, 1, UIFont.Medium, true);
    self.toolsLabel:initialise();
    self.toolsLabel:instantiate();
    self:addChild(self.toolsLabel);
    
    self.materialsLabel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISLabel, 0, 0, fontHeight, getText("IGUI_CraftingWindow_Requires") or "Materials", 1.0, 1.0, 1.0, 1, UIFont.Medium, true);
    self.materialsLabel:initialise();
    self.materialsLabel:instantiate();
    self:addChild(self.materialsLabel);

    self.autoLabel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISLabel, 0, 0, fontHeight, getText("IGUI_CraftingWindow_ManualSelect"), 1.0, 1.0, 1.0, 1, UIFont.Small, true);
    self.autoLabel:initialise();
    self.autoLabel:instantiate();
    self:addChild(self.autoLabel);

    self.autoToggle = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetAutoToggle, 0, 0, TOGGLE_HGT, TOGGLE_HGT, true, self, ISWidgetIngredientsInputs.onAutoToggled);
    self.autoToggle.toggleState = self.logic:isManualSelectInputs();
    self.autoToggle:initialise();
    self.autoToggle:instantiate();
    self:addChild(self.autoToggle);
    
    self.toolsPanel = ISPanel:new(0, 0, 30, 10)
    self.toolsPanel.prerender = function(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
        end
        ISPanel.prerender(panel)
    end
    self.toolsPanel.render = function(panel)
        ISPanel.render(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:clearStencilRect()
        end
    end
    self.toolsPanel.onMouseWheel = function(panel, del)
        if panel:getScrollHeight() > panel:getHeight() then
            local newYScroll = panel:getYScroll() - (del * 40)
            local maxScroll = panel:getScrollHeight() - panel:getHeight()
            newYScroll = math.max(0, math.min(newYScroll, maxScroll))
            panel:setYScroll(newYScroll)
            return true
        end
        return false
    end
    self.toolsPanel.renderChildren = function(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
        end
        ISPanel.renderChildren(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:clearStencilRect()
        end
    end
    self.toolsPanel:initialise()
    self.toolsPanel:instantiate()
    self.toolsPanel:noBackground()
    self.toolsPanel:setScrollChildren(true)
    self:addChild(self.toolsPanel)
    
    self.materialsPanel = ISPanel:new(0, 0, 30, 10)
    self.materialsPanel.prerender = function(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
        end
        ISPanel.prerender(panel)
    end
    self.materialsPanel.render = function(panel)
        ISPanel.render(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:clearStencilRect()
        end
    end
    self.materialsPanel.onMouseWheel = function(panel, del)
        if panel:getScrollHeight() > panel:getHeight() then
            local newYScroll = panel:getYScroll() - (del * 40)
            local maxScroll = panel:getScrollHeight() - panel:getHeight()
            newYScroll = math.max(0, math.min(newYScroll, maxScroll))
            panel:setYScroll(newYScroll)
            return true
        end
        return false
    end
    self.materialsPanel.renderChildren = function(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
        end
        ISPanel.renderChildren(panel)
        if panel:getScrollHeight() > panel:getHeight() then
            panel:clearStencilRect()
        end
    end
    self.materialsPanel:initialise()
    self.materialsPanel:instantiate()
    self.materialsPanel:noBackground()
    self.materialsPanel:setScrollChildren(true)
    self:addChild(self.materialsPanel)
    
    self.tools = {};
    self.materials = {};
    self.inputs = {};

    self.hasTools = false;
    self.hasMaterials = false;

    local toolInputList = {};
    local materialInputList = {};

    for i=0,recipe:getInputs():size()-1 do
        local input = recipe:getInputs():get(i);
        if input:getCreateToItemScript() and (not input:isAutomationOnly()) then
            if input:isKeep() or input:isTool() then
                table.insert(toolInputList, input);
                self.hasTools = true;
            else
                table.insert(materialInputList, input);
                self.hasMaterials = true;
            end
        end
    end
    for i=0,recipe:getInputs():size()-1 do
        local input = recipe:getInputs():get(i);
        if (not input:getCreateToItemScript()) and (not input:isAutomationOnly()) then
            if input:isKeep() or input:isTool() then
                table.insert(toolInputList, input);
                self.hasTools = true;
            else
                table.insert(materialInputList, input);
                self.hasMaterials = true;
            end
        end
    end

    for i,v in ipairs(toolInputList) do
        self:addTool(v);
    end
    
    for i,v in ipairs(materialInputList) do
        self:addMaterial(v);
    end

    self.toolsLabel:setVisible(self.hasTools);
    self.toolsPanel:setVisible(self.hasTools);
    self.materialsLabel:setVisible(self.hasMaterials);
    self.materialsPanel:setVisible(self.hasMaterials);
end

function ISWidgetIngredientsInputs:addTool(_inputScript)
    local tool = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
    tool.interactiveMode = self.interactiveMode;
    tool:initialise();
    tool:instantiate();
    self.toolsPanel:addChild(tool);
    table.insert(self.tools, tool);
    table.insert(self.inputs, tool);
end

function ISWidgetIngredientsInputs:addMaterial(_inputScript)
    local material = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
    material.interactiveMode = self.interactiveMode;
    material:initialise();
    material:instantiate();
    self.materialsPanel:addChild(material);
    table.insert(self.materials, material);
    table.insert(self.inputs, material);
end

function ISWidgetIngredientsInputs:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);
    
    local minWidth = self.margin*2;
    local minHeight = self.margin;
    
    if self.hasTools then
        minWidth = math.max(minWidth, minWidth + self.toolsLabel:getWidth());
    end
    if self.hasMaterials then 
        minWidth = math.max(minWidth, minWidth + self.materialsLabel:getWidth());
    end
    
    local minItemWidth = 0;
    local minItemHeight = 0;
    
    for k,v in ipairs(self.tools) do
        v:calculateLayout(0,0);
        minItemWidth = math.max(minItemWidth, v:getWidth());
        minItemHeight = math.max(minItemHeight, v:getHeight());
    end
    
    for k,v in ipairs(self.materials) do
        v:calculateLayout(0,0);
        minItemWidth = math.max(minItemWidth, v:getWidth());
        minItemHeight = math.max(minItemHeight, v:getHeight());
    end
    
    local toolCols = 4;
    if #self.tools > 0 then
        local numRowsWith4Cols = math.ceil(#self.tools / 4);
        if numRowsWith4Cols > 2 then
            toolCols = 5;
        end
    end
    
    local materialCols = 4;
    if #self.materials > 0 then
        local numRowsWith4Cols = math.ceil(#self.materials / 4);
        if numRowsWith4Cols > 2 then
            materialCols = 5;
        end
    end
    
    local maxCols = math.max(toolCols, materialCols);
    
    local itemSpacingTotal = self.itemSpacing * (maxCols - 1);
    minWidth = math.max(minWidth, (self.itemMargin*2) + (minItemWidth*maxCols) + itemSpacingTotal + self.margin);
    
    local toolRows = #self.tools > 0 and math.max(1, math.ceil(#self.tools / toolCols)) or 0;
    local materialRows = #self.materials > 0 and math.max(1, math.ceil(#self.materials / materialCols)) or 0;
    
    local toolsContentHeight = 0;
    local toolsPanelHeight = 0;
    if self.hasTools and #self.tools > 0 then
        minHeight = minHeight + self.toolsLabel:getHeight() + self.margin;
        local toolRowsToShow = math.min(2, toolRows);
        local toolMargins = toolRowsToShow * self.margin;
        toolsPanelHeight = (minItemHeight * toolRowsToShow) + toolMargins;
        toolsContentHeight = (minItemHeight * toolRows) + (toolRows * self.margin);
        minHeight = minHeight + toolsPanelHeight + self.margin;
    end
    
    local materialsContentHeight = 0;
    local materialsPanelHeight = 0;

    if self.hasMaterials and #self.materials > 0 then
        minHeight = minHeight + self.materialsLabel:getHeight() + self.margin;
        local materialRowsToShow = math.min(2, materialRows);
        local materialMargins = materialRowsToShow * self.margin;
        materialsPanelHeight = (minItemHeight * materialRowsToShow) + materialMargins;
        materialsContentHeight = (minItemHeight * materialRows) + (materialRows * self.margin);
        minHeight = minHeight + materialsPanelHeight;
    end
    
    width = math.max(width, minWidth);
    height = math.max(height, minHeight);
    
    local x = self.margin;
    local y = self.margin;

    local toggleX = width - self.margin - self.autoToggle:getWidth();
    local toggleY = self.margin;
    self.autoToggle:setX(toggleX);
    self.autoToggle.originalX = self.autoToggle:getX();
    self.autoToggle:setY(toggleY);

    toggleX = toggleX - self.margin - self.autoLabel:getWidth();
    self.autoLabel:setX(toggleX);
    self.autoLabel.originalX = self.autoLabel:getX();
    self.autoLabel:setY(toggleY);
    
    local joypadData = JoypadState.players[self.player:getPlayerNum()+1]
    local oldIndexY = math.max(self.joypadIndexY, 1)
    local oldIndex = math.max(self.joypadIndex, 1)
    if joypadData ~= nil and joypadData.focus == self and self.joypadButtons ~= nil and #self.joypadButtons > 0 then
        self:clearJoypadFocus(joypadData)
    end
    
    self.joypadButtons = {}
    self.joypadButtonsY = {}
    
    if self.hasTools and #self.tools > 0 then
        self.toolsLabel:setVisible(true);
        self.toolsLabel:setX(x);
        self.toolsLabel.originalX = self.toolsLabel:getX();
        self.toolsLabel:setY(y);
        
        y = y + self.toolsLabel:getHeight() + self.margin;
        
        self.toolsPanel:setVisible(true);
        self.toolsPanel:setX(0);
        self.toolsPanel:setY(y);
        self.toolsPanel:setWidth(width);
        self.toolsPanel:setHeight(toolsPanelHeight);
        self.toolsPanel:setScrollHeight(toolsContentHeight);
        
        if toolsContentHeight > toolsPanelHeight then
            if not self.toolsPanel.vscroll then
                self.toolsPanel:addScrollBars();
            end
            local scrollBarWidth = self.toolsPanel.vscroll and self.toolsPanel.vscroll.width or 0
            self.toolsPanel.vscroll:setX(width - scrollBarWidth - self.margin)
            self.toolsPanel.vscroll:setY(0)
            self.toolsPanel.vscroll:setHeight(toolsPanelHeight)
        elseif self.toolsPanel.vscroll then
            self.toolsPanel:removeChild(self.toolsPanel.vscroll)
            self.toolsPanel.vscroll = nil
        end
        
        local column = 0;
        local row = 0;
        for k,v in ipairs(self.tools) do
            v:calculateLayout(minItemWidth, minItemHeight);
            
            local itemX = self.itemMargin + (column*(minItemWidth+self.itemSpacing));
            local itemY = row*(minItemHeight+self.margin);
            v:setX(itemX);
            v:setY(itemY);
            
            table.insert(self.joypadButtons, v)
            
            column = column + 1;
            if column >= toolCols then
                column = 0;
                row = row + 1;
                table.insert(self.joypadButtonsY, self.joypadButtons)
                self.joypadButtons = {}
            end
        end
        
        if #self.joypadButtons > 0 then
            table.insert(self.joypadButtonsY, self.joypadButtons)
            self.joypadButtons = {}
        end
        
        y = y + toolsPanelHeight + self.margin;
    else
        self.toolsLabel:setVisible(false);
        self.toolsPanel:setVisible(false);
    end
    
    if self.hasMaterials and #self.materials > 0 then
        self.materialsLabel:setVisible(true);
        self.materialsLabel:setX(x);
        self.materialsLabel.originalX = self.materialsLabel:getX();
        self.materialsLabel:setY(y);
        
        y = y + self.materialsLabel:getHeight() + self.margin;
        
        self.materialsPanel:setVisible(true);
        self.materialsPanel:setX(0);
        self.materialsPanel:setY(y);
        self.materialsPanel:setWidth(width);
        self.materialsPanel:setHeight(materialsPanelHeight);
        self.materialsPanel:setScrollHeight(materialsContentHeight);
        
        if materialsContentHeight > materialsPanelHeight then
            if not self.materialsPanel.vscroll then
                self.materialsPanel:addScrollBars();
            end
            local scrollBarWidth = self.materialsPanel.vscroll and self.materialsPanel.vscroll.width or 0
            self.materialsPanel.vscroll:setX(width - scrollBarWidth - self.margin)
            self.materialsPanel.vscroll:setY(0)
            self.materialsPanel.vscroll:setHeight(materialsPanelHeight)
        elseif self.materialsPanel.vscroll then
            self.materialsPanel:removeChild(self.materialsPanel.vscroll)
            self.materialsPanel.vscroll = nil
        end
        
        local column = 0;
        local row = 0;
        for k,v in ipairs(self.materials) do
            v:calculateLayout(minItemWidth, minItemHeight);
            
            local itemX = self.itemMargin + (column*(minItemWidth+self.itemSpacing));
            local itemY = row*(minItemHeight+self.margin);
            v:setX(itemX);
            v:setY(itemY);
            
            table.insert(self.joypadButtons, v)
            
            column = column + 1;
            if column >= materialCols then
                column = 0;
                row = row + 1;
                table.insert(self.joypadButtonsY, self.joypadButtons)
                self.joypadButtons = {}
            end
        end
        
        if #self.joypadButtons > 0 then
            table.insert(self.joypadButtonsY, self.joypadButtons)
        end
    else
        self.materialsLabel:setVisible(false);
        self.materialsPanel:setVisible(false);
    end
    
    self.joypadIndexY = math.min(oldIndexY or 1, #self.joypadButtonsY)
    if #self.joypadButtonsY > 0 and self.joypadButtonsY[self.joypadIndexY] then
        self.joypadIndex = math.min(oldIndex or 1, #self.joypadButtonsY[self.joypadIndexY])
        self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
        if joypadData ~= nil and joypadData.focus == self and self.joypadButtons and self.joypadButtons[self.joypadIndex] then
            self.joypadButtons[self.joypadIndex]:setJoypadFocused(true, joypadData)
        end
    else
        self.joypadButtons = {}
        self.joypadIndex = 1
        self.joypadIndexY = 1
    end
    
    self:setWidth(width);
    self:setHeight(height);
end

function ISWidgetIngredientsInputs:onAutoToggled(_newState)
    self.logic:setManualSelectInputs(_newState);
    if self.parent and self.parent.parent and self.parent.parent.parent and self.parent.parent.parent.onManualSelectChanged then
        self.parent.parent.parent:onManualSelectChanged(_newState);
    end
    self:xuiRecalculateLayout();
end

function ISWidgetIngredientsInputs:onResize()
    ISPanelJoypad.onResize(self)
end

function ISWidgetIngredientsInputs:prerender()
    ISPanelJoypad.prerender(self);
end

function ISWidgetIngredientsInputs:render()
    ISPanelJoypad.render(self);
end

function ISWidgetIngredientsInputs:update()
    ISPanelJoypad.update(self);
end

function ISWidgetIngredientsInputs:onRebuildItemNodes(_inputItems)
    if self.tools then
        for k,v in ipairs(self.tools) do
           v:onRebuildItemNodes(_inputItems); 
        end
    end
    if self.materials then
        for k,v in ipairs(self.materials) do
           v:onRebuildItemNodes(_inputItems); 
        end
    end
end

function ISWidgetIngredientsInputs:onRecipeChanged()
    if self.logic:shouldShowManualSelectInputs() then
        local firstInput = nil;
        if #self.tools > 0 then
            firstInput = self.tools[1];
        elseif #self.materials > 0 then
            firstInput = self.materials[1];
        end
        
        if firstInput then
            self.logic:setManualSelectInputScriptFilter(firstInput.inputScript);
        end
    end
end

function ISWidgetIngredientsInputs:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    if self.joypadButtonsY and #self.joypadButtonsY > 0 then
        self.joypadIndexY = 1
        self.joypadIndex = 1
        if self.joypadButtonsY[self.joypadIndexY] then
            self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
            if self.joypadButtons and #self.joypadButtons > 0 then
                self.joypadButtons[self.joypadIndex]:setJoypadFocused(true, joypadData)
            end
        else
            self.joypadButtons = {} 
        end
    end
end

function ISWidgetIngredientsInputs:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self:clearJoypadFocus(joypadData)
end

function ISWidgetIngredientsInputs:onJoypadDown(button, joypadData)
    if button == Joypad.AButton then
        if self.joypadButtons and self.joypadButtons[self.joypadIndex] then
            local input = self.joypadButtons[self.joypadIndex]
            if input and input.primary and input.primary.selectInputButton then
                input:onSelectInputsClicked(input.primary.selectInputButton)
            end
        end
        return
    end
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
end

function ISWidgetIngredientsInputs:new (x, y, width, height, player, logic)
	local o = ISPanelJoypad.new(self, x, y, width, height);
    o.player = player;
    o.logic = logic;

    o.interactiveMode = false;

    o.backgroundColor = {r=0, g=0, b=0, a=0};
    o.borderColor = {r=1, g=1, b=1, a=0.7};

    o.background = true;

    o.textureLink = getTexture("media/ui/Entity/icon_link_io.png");

    o.margin = UI_BORDER_SPACING;
    o.minimumWidth = 0;
    o.minimumHeight = 0;

    local fontScale = getTextManager():getFontHeight(UIFont.Small) / 19;

    o.itemSpacing = 10 * fontScale;
    o.itemMargin = 10 * fontScale;
    o.itemNameMaxLines = 3;

    o.doToolTip = true;

    o.autoFillContents = false;

    o.isAutoFill = false;
    o.isAutoFillX = false;
    o.isAutoFillY = false;

    return o
end