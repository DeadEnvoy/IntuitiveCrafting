require "ISUI/ISToolTipInv"
require "Entity/ISUI/CraftRecipe/ISWidgetOutput"

local original_createScriptValues = ISWidgetOutput.createScriptValues
function ISWidgetOutput:createScriptValues(_script)
    local table = original_createScriptValues(self, _script)

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

local original_updateScriptValues = ISWidgetOutput.updateScriptValues
function ISWidgetOutput:updateScriptValues(_table)
    original_updateScriptValues(self, _table)

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