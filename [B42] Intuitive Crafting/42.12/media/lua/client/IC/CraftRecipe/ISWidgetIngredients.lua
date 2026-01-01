require "ISUI/ISPanel"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10

ISWidgetIngredients = ISPanel:derive("ISWidgetIngredients");

function ISWidgetIngredients:initialise()
	ISPanel.initialise(self);
end

function ISWidgetIngredients:createChildren()
    ISPanel.createChildren(self);

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

    self.outputsLabel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISLabel, 0, 0, fontHeight, getText("IGUI_CraftingWindow_Creates"), 1.0, 1.0, 1.0, 1, UIFont.Medium, true);
    self.outputsLabel:initialise();
    self.outputsLabel:instantiate();
    self:addChild(self.outputsLabel);

    self.tools = {};
    self.materials = {};
    self.outputs = {};

    self.hasTools = false;

    for i=0,recipe:getOutputs():size()-1 do
        local output = recipe:getOutputs():get(i);
        if not output:isAutomationOnly() then
            self:addOutput(output);
        end
    end
    
    for i=0,recipe:getInputs():size()-1 do
        local input = recipe:getInputs():get(i);
        if input:getCreateToItemScript() and (not input:isAutomationOnly()) then
            if input:isKeep() or input:isTool() then
                self:addTool(input);
                self.hasTools = true;
            else
                self:addMaterial(input);
            end
            self:addKeeps(input);
        end
    end
    
    for i=0,recipe:getInputs():size()-1 do
        local input = recipe:getInputs():get(i);
        if (not input:getCreateToItemScript()) and (not input:isAutomationOnly()) then
            if input:isKeep() or input:isTool() then
                self:addTool(input);
                self.hasTools = true;
            else
                self:addMaterial(input);
            end
            self:addKeeps(input);
        end
    end

    self.toolsLabel:setVisible(self.hasTools);
end

function ISWidgetIngredients:addTool(_inputScript)
    if _inputScript:isKeep() then
        return;
    end
    local tool = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
    tool.interactiveMode = self.interactiveMode;
    tool:initialise();
    tool:instantiate();
    self:addChild(tool);
    table.insert(self.tools, tool);

    if _inputScript:getCreateToItemScript() then
        local output = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
        output.interactiveMode = self.interactiveMode;
        output.displayAsOutput = true;
        output:initialise();
        output:instantiate();
        self:addChild(output);
        table.insert(self.outputs, output);

        local iconLink = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISImage, 0, 0, 19, 12, self.textureLink);
        iconLink.autoScale = true;
        iconLink:initialise();
        iconLink:instantiate();
        self:addChild(iconLink);
        output.iconLink = iconLink;
    end
end

function ISWidgetIngredients:addMaterial(_inputScript)
    if _inputScript:isKeep() then
        return;
    end
    local material = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
    material.interactiveMode = self.interactiveMode;
    material:initialise();
    material:instantiate();
    self:addChild(material);
    table.insert(self.materials, material);

    if _inputScript:getCreateToItemScript() then
        local output = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
        output.interactiveMode = self.interactiveMode;
        output.displayAsOutput = true;
        output:initialise();
        output:instantiate();
        self:addChild(output);
        table.insert(self.outputs, output);

        local iconLink = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISImage, 0, 0, 19, 12, self.textureLink);
        iconLink.autoScale = true;
        iconLink:initialise();
        iconLink:instantiate();
        self:addChild(iconLink);
        output.iconLink = iconLink;
    end
end

function ISWidgetIngredients:addKeeps(_inputScript)
    if not _inputScript:isKeep() then
        return;
    end
    
    local isToolKeep = _inputScript:isTool();
    
    local input = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
    input.interactiveMode = self.interactiveMode;
    input:initialise();
    input:instantiate();
    self:addChild(input);
    
    if isToolKeep then
        table.insert(self.tools, input);
        self.hasTools = true;
    else
        table.insert(self.materials, input);
    end
    
    if _inputScript:getCreateToItemScript() then
        local output = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
        output.interactiveMode = self.interactiveMode;
        output.displayAsOutput = true;
        output:initialise();
        output:instantiate();
        self:addChild(output);
        table.insert(self.outputs, output);

        local iconLink = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISImage, 0, 0, 19, 12, self.textureLink);
        iconLink.autoScale = true;
        iconLink:initialise();
        iconLink:instantiate();
        self:addChild(iconLink);
        output.iconLink = iconLink;
    else
        local output = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipInput, 0, 0, 10, 10, self.player, self.logic, _inputScript);
        output.interactiveMode = self.interactiveMode;
        output.displayAsOutput = true;
        output:initialise();
        output:instantiate();
        self:addChild(output);
        table.insert(self.outputs, output);
    end
end

function ISWidgetIngredients:addOutput(_outputScript)
    local output = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", ISWidgetTooltipOutput, 0, 0, 10, 10, self.player, self.logic, _outputScript);
    output.interactiveMode = self.interactiveMode;
    output:initialise();
    output:instantiate();
    self:addChild(output);
    table.insert(self.outputs, output);
end

function ISWidgetIngredients:calculateLayout(_preferredWidth, _preferredHeight)

    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);

    local minWidth = self.margin*2;
    local minHeight = self.margin;

    local labelsWidth = 0;
    if self.hasTools then
        labelsWidth = math.max(labelsWidth, self.toolsLabel:getWidth());
    end
    labelsWidth = math.max(labelsWidth, self.materialsLabel:getWidth());
    labelsWidth = math.max(labelsWidth, self.outputsLabel:getWidth());
    
    minWidth = math.max(minWidth, minWidth + labelsWidth);

    if self.hasTools then
        minHeight = minHeight + self.toolsLabel:getHeight() + self.margin;
    end
    minHeight = minHeight + self.materialsLabel:getHeight() + self.margin;
    minHeight = minHeight + self.outputsLabel:getHeight() + self.margin;

    local minToolWidth = 0;
    local minToolHeight = 0;
    for k,v in ipairs(self.tools) do
        v:calculateLayout(0,0);
        minToolWidth = math.max(minToolWidth, v:getWidth());
        minToolHeight = math.max(minToolHeight, v:getHeight());
    end

    local minMaterialWidth = 0;
    local minMaterialHeight = 0;
    for k,v in ipairs(self.materials) do
        v:calculateLayout(0,0);
        minMaterialWidth = math.max(minMaterialWidth, v:getWidth());
        minMaterialHeight = math.max(minMaterialHeight, v:getHeight());
    end

    local minOutputWidth = 0;
    local minOutputHeight = 0;
    for k,v in ipairs(self.outputs) do
        v:calculateLayout(0,0);
        minOutputWidth = math.max(minOutputWidth, v:getWidth());
        minOutputHeight = math.max(minOutputHeight, v:getHeight());
    end

    local minIOWidth = math.max(minToolWidth, math.max(minMaterialWidth, minOutputWidth));
    local minIOHeight = math.max(minToolHeight, math.max(minMaterialHeight, minOutputHeight));

    local toolsMargins = #self.tools > 0 and #self.tools * self.margin or 0;
    local materialsMargins = #self.materials > 0 and #self.materials * self.margin or 0;
    local outputsMargins = #self.outputs > 0 and #self.outputs * self.margin or 0;
    
    minHeight = minHeight + (#self.tools * minIOHeight) + toolsMargins;
    minHeight = minHeight + (#self.materials * minIOHeight) + materialsMargins;
    minHeight = minHeight + (#self.outputs * minIOHeight) + outputsMargins;

    minWidth = math.max(minWidth, (self.margin*2) + minIOWidth);

    width = math.max(width, minWidth);
    height = math.max(height, minHeight);

    local IOWidth = width - (self.margin*2);

    local x = self.margin;
    local y = self.margin;

    if self.hasTools then
        self.toolsLabel:setX(x);
        self.toolsLabel.originalX = self.toolsLabel:getX();
        self.toolsLabel:setY(y);

        y = self.toolsLabel:getY() + self.toolsLabel:getHeight() + self.margin;

        for k,v in ipairs(self.tools) do
            v:calculateLayout(IOWidth, minIOHeight);
            v:setX(x);
            v:setY(y);
            y = v:getY() + v:getHeight() + self.margin;
        end
    end

    self.materialsLabel:setX(x);
    self.materialsLabel.originalX = self.materialsLabel:getX();
    self.materialsLabel:setY(y);

    y = self.materialsLabel:getY() + self.materialsLabel:getHeight() + self.margin;

    for k,v in ipairs(self.materials) do
        v:calculateLayout(IOWidth, minIOHeight);
        v:setX(x);
        v:setY(y);
        y = v:getY() + v:getHeight() + self.margin;
    end

    self.outputsLabel:setX(x);
    self.outputsLabel.originalX = self.outputsLabel:getX();
    self.outputsLabel:setY(y);

    y = self.outputsLabel:getY() + self.outputsLabel:getHeight() + self.margin;

    for k,v in ipairs(self.outputs) do
        v:calculateLayout(IOWidth, minIOHeight);
        v:setX(x);
        v:setY(y);

        if v.iconLink then
            v.iconLink:setX(x-12);
            v.iconLink:setY(y+15);
        end

        y = v:getY() + v:getHeight() + self.margin;
    end

    self:setWidth(width);
    self:setHeight(height);
end

function ISWidgetIngredients:onResize()
    ISUIElement.onResize(self)
end

function ISWidgetIngredients:prerender()
    ISPanel.prerender(self);
    for k,v in ipairs(self.outputs) do
        if v.iconLink then
            local r,g,b = v.borderColor.r, v.borderColor.g, v.borderColor.b;
            v.iconLink:setColor(r,g,b);
        end
    end
end

function ISWidgetIngredients:render()
    ISPanel.render(self);
end

function ISWidgetIngredients:update()
    ISPanel.update(self);
end

function ISWidgetIngredients:new (x, y, width, height, player, logic)
	local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.player = player;
    o.logic = logic;

    o.interactiveMode = false;

    o.background = false;

    o.textureLink = getTexture("media/ui/Entity/icon_link_io.png");

    o.margin = UI_BORDER_SPACING;
    o.minimumWidth = 0;
    o.minimumHeight = 0;

    o.doToolTip = true;

    o.autoFillContents = false;

    o.isAutoFill = false;
    o.isAutoFillX = false;
    o.isAutoFillY = false;

    return o
end