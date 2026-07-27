require "ISUI/ISToolTipInv"
require "Entity/ISUI/CraftRecipe/ISWidgetHandCraftControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/CraftRecipe/ISWidgetOutput"

local original_ISWidgetOutput_createScriptValues = ISWidgetOutput.createScriptValues
function ISWidgetOutput:createScriptValues(_script)
    local table = original_ISWidgetOutput_createScriptValues(self, _script)

    if _script:getResourceType() == ResourceType.Fluid then
        if table.amountStr and table.amountStr:sub(-1) == "L" then
            table.amountStr = table.amountStr:sub(1, -2) .. getText("IGUI_CraftingUI_Liters")
        end
        if table.label and table.label.setName then
            table.label:setName(table.amountStr)
        end
    end

    if _script:getResourceType() == ResourceType.Item then
        if table.icon.tooltipUI then
            table.icon.tooltipUI:removeFromUIManager()
        end

        table.icon.tooltipUI = ISToolTipInv:new(nil)
        table.icon.tooltipUI:setOwner(table.icon)
        table.icon.tooltipUI:setVisible(false)
        table.icon.tooltipUI:setAlwaysOnTop(true)
        table.icon.tooltipUI:setCharacter(self.player)

        function table.icon.tooltipUI:setDesiredPosition(x, y)
        end
    end

    return table
end

local original_ISWidgetOutput_updateScriptValues = ISWidgetOutput.updateScriptValues
function ISWidgetOutput:updateScriptValues(_table)
    original_ISWidgetOutput_updateScriptValues(self, _table)

    if _table.script:getResourceType() == ResourceType.Fluid then
        if _table.amountStr and _table.amountStr:sub(-1) == "L" then
            _table.amountStr = _table.amountStr:sub(1, -2) .. getText("IGUI_CraftingUI_Liters")
        end
        if _table.label and _table.label.setName then
            _table.label:setName(_table.amountStr)
        end
    end

    if _table.script:getResourceType() == ResourceType.Item then
        local index = 0
        if _table.cycleIcons then
            local playerIndex = self.player:getPlayerNum()
            index = UIManager.getSyncedIconIndex(playerIndex, _table.outputObjects:size())
        end

        local item = _table.outputObjects:get(index)
        if item then
            if not _table.dummyItem or _table.dummyItem:getFullType() ~= item:getFullName() then
                _table.dummyItem = instanceItem(item:getFullName())
            end

            if _table.icon.tooltipUI then
                _table.icon.tooltipUI:setItem(_table.dummyItem)
            end
        end
    end
end

local original_ISWidgetInput_createScriptValues = ISWidgetInput.createScriptValues
function ISWidgetInput:createScriptValues(_script, isSecondary, ...)
    local table = original_ISWidgetInput_createScriptValues(self, _script, isSecondary, ...)

    if _script:getResourceType() == ResourceType.Fluid then
        if table.amountStr and table.amountStr:sub(-1) == "L" then
            table.amountStr = table.amountStr:sub(1, -2) .. getText("IGUI_CraftingUI_Liters")
        end
        if table.label and table.label.setName then
            table.label:setName(table.amountStr)
        end
    end

    return table
end

local original_ISWidgetInput_updateScriptValues = ISWidgetInput.updateScriptValues
function ISWidgetInput:updateScriptValues(_table, ...)
    original_ISWidgetInput_updateScriptValues(self, _table, ...)

    if _table.script:getResourceType() == ResourceType.Fluid then
        if _table.amountStr and _table.amountStr:sub(-1) == "L" then
            _table.amountStr = _table.amountStr:sub(1, -2) .. getText("IGUI_CraftingUI_Liters")
        end
        if _table.label and _table.label.setName then
            _table.label:setName(_table.amountStr)
        end
    end
end

local original_ISWidgetHandCraftControl_calculateLayout = ISWidgetHandCraftControl.calculateLayout
function ISWidgetHandCraftControl:calculateLayout(_preferredWidth, _preferredHeight)
    original_ISWidgetHandCraftControl_calculateLayout(self, _preferredWidth, _preferredHeight)
    if self.durationLabel then
        self.durationLabel.originalX = self.durationLabel:getX()
    end
end

local original_ISWidgetHandCraftControl_createChildren = ISWidgetHandCraftControl.createChildren
function ISWidgetHandCraftControl:createChildren()
    original_ISWidgetHandCraftControl_createChildren(self)

    if self.quantityLabel and self.quantityLabel.setName then
        self.quantityLabel:setName(getText("IGUI_CraftingUI_Quantity"))
    end
    if self.buttonMax and self.buttonMax.setTitle then
        self.buttonMax:setTitle(getText("IGUI_CraftingUI_Max"))
    end
    if self.buttonForceCraft and self.buttonForceCraft.setTitle then
        self.buttonForceCraft:setTitle(getText("IGUI_CraftingUI_ForceAction"))
    end
    if self.durationLabel and self.durationLabel.setName then
        local text = string.format("%s %02d%s %02d%s",
            getText("IGUI_CraftingUI_TimeRequired"),
            0, getText("IGUI_CraftingUI_Minutes"),
            0, getText("IGUI_CraftingUI_Seconds"))
        self.durationLabel:setName(text)
    end
end

function ISWidgetHandCraftControl:prerender()
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.boxHeight, self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b)
        self:drawRectBorderStatic(0, 0, self.width, self.boxHeight, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
    end

    if self.durationLabel then
        if self.logic and self.logic:getRecipe() then
            local seconds = self.logic:getRecipe():getTime(self.player)
            local mm = (seconds < 60) and 0 or round(seconds / 60, 0)
            local ss = math.fmod(seconds, 60)
            local text = string.format("%s %02d%s %02d%s",
                getText("IGUI_CraftingUI_TimeRequired"),
                mm, getText("IGUI_CraftingUI_Minutes"),
                ss, getText("IGUI_CraftingUI_Seconds"))
            self.durationLabel:setName(text)
        else
            self.durationLabel:setName(getText("IGUI_CraftingUI_TimeRequired") .. " ??")
        end
    end

    if self.logic and self.logic:isCraftActionInProgress() and self.logic:getCraftActionTable() then
        local action = self.logic:getCraftActionTable()
        local plrQueue = ISTimedActionQueue.getTimedActionQueue(self.player)
        if plrQueue and plrQueue.queue and plrQueue.queue[1] and plrQueue.queue[1] == action then
            if self.progressBar then
                self.progressBar:setProgress(action:getJobDelta())
                self.progressBar:setText(tostring(round(action:getJobDelta() * 100, 0)) .. "%")
            end
            if self.buttonCraft then
                self.buttonCraft.enable = false
            end
        end
    else
        if self.buttonCraft then
            self.buttonCraft.enable = self.logic:cachedCanPerformCurrentRecipe()
        end
        if self.progressBar then
            self.progressBar:setProgress(0)
            self.progressBar:setText("")
        end
    end
end