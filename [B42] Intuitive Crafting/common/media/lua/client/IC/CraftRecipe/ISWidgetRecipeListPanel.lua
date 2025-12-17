require "ISUI/ISPanel"
local Reflection = require("Starlit/utils/Reflection")
local UI_BORDER_SPACING = 10
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_HEADING = getTextManager():getFontHeight(UIFont.Small)
local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 19
local ICON_SCALE = math.max(1, (FONT_SCALE - math.floor(FONT_SCALE)) < 0.5 and math.floor(FONT_SCALE) or math.ceil(FONT_SCALE))
local LIST_ICON_SIZE = math.max(1, 48 * FONT_SCALE)
local LIST_SUBICON_SIZE = 16 * ICON_SCALE
local LIST_FAVICON_SIZE = 10 * ICON_SCALE
local LIST_SUBICON_SPACING = 2 * ICON_SCALE

ISWidgetRecipeListPanel = ISPanel:derive("ISWidgetRecipeListPanel");

function ISWidgetRecipeListPanel:initialise()
    ISPanel.initialise(self);
end

function ISWidgetRecipeListPanel:createChildren()
    ISPanel.createChildren(self)

    self.recipeListPanel = ISScrollingListBox:new(0, 0, 10, 10)
    self.recipeListPanel:initialise()
    self.recipeListPanel:instantiate()

    self.recipeListPanel.starUnsetTexture = getTexture("media/ui/inventoryPanes/FavouriteNo.png")
    self.recipeListPanel.starSetTexture = getTexture("media/ui/inventoryPanes/FavouriteYes.png")

    self.recipeListPanel.itemheight = math.max(2 + FONT_HGT_HEADING + FONT_HGT_SMALL + UI_BORDER_SPACING, LIST_ICON_SIZE + UI_BORDER_SPACING)
    
    self.recipeListPanel.doDrawItem = function(_self, _y, _item, _alt)
        local craftRecipe = _item and _item.item
        if craftRecipe then
            local favString = BaseCraftingLogic.getFavouriteModDataString(craftRecipe)
            local isFavourite = self.player:getModData()[favString] or false
            
            local yActual = _self:getYScroll() + _y
            if _item.cachedHeight and (yActual > _self.height or (yActual + _item.cachedHeight) < 0) then
                return _y + _item.cachedHeight
            end
            
            if not _item.height then _item.height = _self.itemheight end
            local safeDrawWidth = _self:getWidth() - (_self.vscroll and _self.vscroll:getWidth() or 0)
            
            local cheat = self.player:isBuildCheat()
            if self.logic and self.logic.craftCheat then
                cheat = true
            end
            
            local color = {r=1.0, g=1.0, b=1.0, a=1.0}
            if instanceof(self.logic, "BaseCraftingLogic") then
                local cachedRecipeInfo = self.logic:getCachedRecipeInfo(craftRecipe)
                if cachedRecipeInfo and (not cachedRecipeInfo:isValid()) then
                    color = {r=0.5, g=0.5, b=0.5, a=1.0};
                elseif cachedRecipeInfo and (not cachedRecipeInfo:isCanPerform()) then
                    color = {r=0.5, g=0.5, b=0.5, a=1.0};
                end
            end
            
            if _self.selected == _item.index then
                _self:drawSelection(0, _y, _self:getWidth(), _item.height-1);
            elseif (_self.mouseoverselected == _item.index) and _self:isMouseOver() and not _self:isMouseOverScrollBar() then
                _self:drawMouseOverHighlight(0, _y, _self:getWidth(), _item.height-1);
            end
            
            _self:drawRectBorder(0, _y, _self:getWidth(), _item.height, 0.5, _self.borderColor.r, _self.borderColor.g, _self.borderColor.b)
            
            local colGood = {
                r=getCore():getGoodHighlitedColor():getR(),
                g=getCore():getGoodHighlitedColor():getG(),
                b=getCore():getGoodHighlitedColor():getB(),
                a=getCore():getGoodHighlitedColor():getA(),
            }
            local colBad = {
                r=getCore():getBadHighlitedColor():getR(),
                g=getCore():getBadHighlitedColor():getG(),
                b=getCore():getBadHighlitedColor():getB(),
                a=getCore():getBadHighlitedColor():getA(),
            }
            
            local detailsLeft = UI_BORDER_SPACING + LIST_ICON_SIZE + UI_BORDER_SPACING
            local currentDrawingY = 4 
            
            local fileSize = ".png"
            if LIST_SUBICON_SIZE == 16 then
                fileSize = "_16.png"
            end
            
            local iconRight = safeDrawWidth - UI_BORDER_SPACING - (LIST_SUBICON_SIZE/2) - LIST_SUBICON_SPACING
            if craftRecipe:isCanWalk() then
                local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking" .. fileSize)
                _self:drawTextureScaledAspect(iconTexture, iconRight, _y+currentDrawingY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
                iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
            end
            if not craftRecipe:canBeDoneInDark() and not self.ignoreLightIcon then
                local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light" .. fileSize)
                _self:drawTextureScaledAspect(iconTexture, iconRight, _y+currentDrawingY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
                iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
            end
            if craftRecipe:needToBeLearn() then
                local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book" .. fileSize)
                local alpha = 1
                if not self.player:isRecipeKnown(craftRecipe, true) then
                    alpha = 0.5
                end
                _self:drawTextureScaledAspect(iconTexture, iconRight, _y+currentDrawingY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, alpha, color.r, color.g, color.b)
                iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
            end
            if not craftRecipe:isInHandCraftCraft() and not self.ignoreSurface then
                local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface" .. fileSize)
                _self:drawTextureScaledAspect(iconTexture, iconRight, _y+currentDrawingY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
                iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
            end
            
            local headerAdj = (LIST_SUBICON_SIZE - FONT_HGT_HEADING) / 2
            currentDrawingY = currentDrawingY + headerAdj
            
            local currentTextYAbsolute = _y + currentDrawingY
            
            local maxTitleWidth = (iconRight - detailsLeft) - (UI_BORDER_SPACING + LIST_SUBICON_SIZE + LIST_SUBICON_SPACING)
            local titleStr = getTextManager():WrapText(UIFont.Small, craftRecipe:getTranslationName(), maxTitleWidth, 2, "...")
            
            if isDebugEnabled() then
                local tags = "";
                for i=0,craftRecipe:getTags():size() -1 do
                    tags = tags .. craftRecipe:getTags():get(i);
                    if i < craftRecipe:getTags():size()-1 then
                        tags = tags .. ", ";
                    end
                end
                titleStr = titleStr .. "\n(tags: " .. tags .. ")";
            end

            _self:drawText(titleStr, detailsLeft, currentTextYAbsolute, color.r, color.g, color.b, color.a, UIFont.Small)
            
            local recipeNameActualHeight = getTextManager():MeasureStringY(UIFont.Small, titleStr)
            currentDrawingY = currentDrawingY + recipeNameActualHeight 
            currentTextYAbsolute = currentTextYAbsolute + recipeNameActualHeight
            
            local additionalTextY = currentDrawingY
            
            if craftRecipe:getTooltip() then
                local text = getText(craftRecipe:getTooltip())
                if self.wrapTooltipText then
                    local tooltipAvailableWidth = (safeDrawWidth - detailsLeft) - (UI_BORDER_SPACING*2 + LIST_SUBICON_SPACING)
                    text = text:gsub("\n", " ")
                    text = getTextManager():WrapText(UIFont.Small, text, tooltipAvailableWidth)
                end
                _self:drawText(text, detailsLeft, _y + additionalTextY, 0.5, 0.5, 0.5, color.a, UIFont.Small)
                local split = luautils.split(text, "\n")
                for _,_ in ipairs(split) do
                    additionalTextY = additionalTextY + FONT_HGT_SMALL
                end
            end
            
            if craftRecipe:getRequiredSkillCount() > 0 then
                for i=0,craftRecipe:getRequiredSkillCount() -1 do
                    local requiredSkill = craftRecipe:getRequiredSkill(i)
                    local hasSkill = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
                    local lineColor = (hasSkill or cheat) and colGood or colBad
                    
                    local text = getText("IGUI_CraftingWindow_Requires2").." ".. tostring(requiredSkill:getPerk():getName()) .. " " .. getText("IGUI_CraftingWindow_Level") .. " " .. tostring(requiredSkill:getLevel())
                    _self:drawText(text, detailsLeft, _y + additionalTextY, lineColor.r, lineColor.g, lineColor.b, lineColor.a, UIFont.Small)
                    additionalTextY = additionalTextY + FONT_HGT_SMALL
                end
            end
            
            if craftRecipe:getXPAwardCount() > 0 then
                local currentXpDrawX = detailsLeft
                local maxYInLine = 0
                local firstXpInLine = true
                local separatorString = ", "
                local separatorColor = {r=0.7, g=0.7, b=0.7, a=1.0}
                local separatorWidth = getTextManager():MeasureStringX(UIFont.Small, separatorString)
                
                for awardIndex = 0, 100 do
                    local XPAward = craftRecipe:getXPAward(awardIndex)
                    if not XPAward then break end
                    
                    local skillPerk = Reflection.getField(XPAward, "perk")
                    local xpAmount = Reflection.getField(XPAward, "amount")
                    
                    if skillPerk and xpAmount then
                        local baseRealExp = xpAmount / 4 
                        local finalRealExp = baseRealExp
                        local isBookBoosted = false
                        
                        local finalEffectiveSandboxMultiplier = 1.0
                        local sandboxOptions = getSandboxOptions()
                        if sandboxOptions then
                            local individualSkillMultiplierValue = 1.0
                            local globalMultiplierValue = 1.0
                            local globalMultiplierToggleIsOn = false
                            if skillPerk then
                                local perkNameStr = skillPerk:toString()
                                if not perkNameStr then perkNameStr = "InvalidPerkName" end
                                local individualSkillOption = sandboxOptions:getOptionByName("MultiplierConfig." .. perkNameStr)
                                if individualSkillOption then
                                    local val = individualSkillOption:getValue()
                                    if val ~= nil then individualSkillMultiplierValue = val end
                                end
                            end
                            local globalMultiplierOption = sandboxOptions:getOptionByName("MultiplierConfig.Global")
                            if globalMultiplierOption then
                                local val = globalMultiplierOption:getValue()
                                if val ~= nil then globalMultiplierValue = val end
                            end
                            local globalMultiplierToggleOption = sandboxOptions:getOptionByName("MultiplierConfig.GlobalToggle")
                            if globalMultiplierToggleOption then
                                local val = globalMultiplierToggleOption:getValue()
                                if val ~= nil then globalMultiplierToggleIsOn = val end
                            end
                            if globalMultiplierToggleIsOn then
                                finalEffectiveSandboxMultiplier = globalMultiplierValue * individualSkillMultiplierValue
                            else
                                finalEffectiveSandboxMultiplier = individualSkillMultiplierValue
                            end
                        end
                        
                        local bookSkillMultiplier = 1.0
                        if self.player and self.player:getXp() then
                            if skillPerk then
                                local rawBookMultiplier = self.player:getXp():getMultiplier(skillPerk)
                                if rawBookMultiplier ~= nil and rawBookMultiplier > 0 then
                                    bookSkillMultiplier = rawBookMultiplier
                                    if bookSkillMultiplier > 1.0 then
                                        isBookBoosted = true
                                    end
                                end
                            end
                        end
                        finalRealExp = baseRealExp * finalEffectiveSandboxMultiplier * bookSkillMultiplier
                        if finalRealExp < 0 then finalRealExp = 0 end
                        
                        local singleXpString = getText(skillPerk:getName()) .. " (+" .. string.format("%.1f",finalRealExp) .. ")"
                        local xpTextColor
                        if isBookBoosted then
                            xpTextColor = {r=1.0, g=0.65, b=0.0, a=1.0} 
                        else
                            xpTextColor = {r=0.3, g=0.5, b=1.0, a=1.0}
                        end
                        
                        local textWidth = getTextManager():MeasureStringX(UIFont.Small, singleXpString)
                        local textHeight = getTextManager():MeasureStringY(UIFont.Small, singleXpString)
                        maxYInLine = math.max(maxYInLine, textHeight)
                        
                        local requiredWidthForNextItem = textWidth
                        if not firstXpInLine then
                            requiredWidthForNextItem = requiredWidthForNextItem + separatorWidth
                        end
                        
                        if currentXpDrawX + requiredWidthForNextItem > safeDrawWidth - UI_BORDER_SPACING and currentXpDrawX ~= detailsLeft then
                            currentXpDrawX = detailsLeft
                            additionalTextY = additionalTextY + maxYInLine
                            maxYInLine = textHeight
                            firstXpInLine = true
                        end
                        
                        if not firstXpInLine then
                            _self:drawText(separatorString, currentXpDrawX, _y + additionalTextY, separatorColor.r, separatorColor.g, separatorColor.b, separatorColor.a, UIFont.Small)
                            currentXpDrawX = currentXpDrawX + separatorWidth
                        end
                        
                        _self:drawText(singleXpString, currentXpDrawX, _y + additionalTextY, xpTextColor.r, xpTextColor.g, xpTextColor.b, xpTextColor.a, UIFont.Small)
                        currentXpDrawX = currentXpDrawX + textWidth
                        firstXpInLine = false
                    end
                end
                if maxYInLine > 0 then
                    additionalTextY = additionalTextY + maxYInLine
                end
            end
            
            currentDrawingY = additionalTextY
            
            local usedHeight = math.max(_self.itemheight, currentDrawingY + UI_BORDER_SPACING)
            if isFavourite then
                usedHeight = math.max(usedHeight, LIST_ICON_SIZE + (LIST_FAVICON_SIZE/2));
            end
            
            _item.height = usedHeight
            _item.cachedHeight = usedHeight
            
            local iconY = _y + (usedHeight/2)-(LIST_ICON_SIZE/2)
            local texture = craftRecipe:getIconTexture()
            _self:drawTextureScaledAspect(texture, UI_BORDER_SPACING, iconY, LIST_ICON_SIZE, LIST_ICON_SIZE, color.a, color.r, color.g, color.b)
            
            local starIconY = iconY + (LIST_ICON_SIZE) - (LIST_FAVICON_SIZE);
            if isFavourite then
                _self:drawTextureScaledAspect(_self.starSetTexture, UI_BORDER_SPACING, starIconY, LIST_FAVICON_SIZE, LIST_FAVICON_SIZE, color.a, getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB());
            end
            
            return _y + usedHeight
        end
        return _y
    end

    self.recipeListPanel.onItemMouseHover = function(_self, _item)
        self.callbackTarget:onRecipeItemMouseHover(_item)
    end

    self.recipeListPanel.onScrolled = function(_self)
        self.callbackTarget:onRecipeListPanelScrolled()
    end

    self.recipeListPanel.selected = 0
    self.recipeListPanel.drawBorder = true
    self.recipeListPanel:setOnMouseDownFunction(self, function(_self, _recipe) _self.logic:setRecipe(_recipe) end)
    self.recipeListPanel.drawDebugLines = self.drawDebugLines

    self:addChild(self.recipeListPanel)
end

function ISWidgetRecipeListPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);

    if self.expandToFitTooltip and self.recipeListPanel and self.recipeListPanel.items then
        for k, v in ipairs(self.recipeListPanel.items) do
            local craftRecipe = v and v.item;
            if craftRecipe then
                local text = craftRecipe:getTooltip() and getText(craftRecipe:getTooltip());
                local tooltipWidth = UI_BORDER_SPACING + LIST_ICON_SIZE + UI_BORDER_SPACING + getTextManager():MeasureStringX(UIFont.Small, text) + UI_BORDER_SPACING + (self.recipeListPanel.vscroll and self.recipeListPanel.vscroll:getWidth() or 0);
                if v.itemindex == 1 or tooltipWidth > self.largestTooltipWidth then
                    self.largestTooltipWidth = tooltipWidth;
                end
            end
        end
        
        width = math.max(width, self.largestTooltipWidth);
    end
    
    self:setWidth(width);
    self:setHeight(height);
end

function ISWidgetRecipeListPanel:onResize()
    ISUIElement.onResize(self)

    if self.recipeListPanel and self.recipeListPanel.selected then
        self.recipeListPanel:ensureVisible(self.recipeListPanel.selected);
    end
end

function ISWidgetRecipeListPanel:prerender()
    ISPanel.prerender(self);

    if self.recipeListPanel and self.recipeListPanel.vscroll then
        self.recipeListPanel.vscroll:setHeight(self.recipeListPanel:getHeight());
        self.recipeListPanel.vscroll:setX(self.recipeListPanel:getWidth()-self.recipeListPanel.vscroll:getWidth());
    end
end

function ISWidgetRecipeListPanel:render()
    if self.pendingSelectedData and self.recipeListPanel and self.recipeListPanel.items then
        for i = 1, #self.recipeListPanel.items do
            if self.recipeListPanel.items[i].item == self.pendingSelectedData then
                self.recipeListPanel.selected = i;
                self.recipeListPanel:ensureVisible(i);
                break;
            end
        end
        self.pendingSelectedData = nil;
    end
    
    ISPanel.render(self);
    self:renderJoypadFocus()

    if #self.recipeListPanel.items == 0 then
        self:clearStencilRect();
        local tooltipStr = getText("IGUI_CraftingWindow_NoRecipes");
        local stringWidth = getTextManager():MeasureStringX(UIFont.Small, tooltipStr);
        local stringHeight = getTextManager():MeasureStringY(UIFont.Small, tooltipStr);
        local x = (self.recipeListPanel:getWidth() - stringWidth) / 2;
        local y = (self.recipeListPanel:getHeight() - stringHeight) / 2;
        local padding = 20;
        local boxX, boxY = math.max(0, self.recipeListPanel:getX() + x - padding), math.max(0, self.recipeListPanel:getY() + y - padding);
        local boxWidth, boxHeight = math.min(padding + stringWidth + padding, self.recipeListPanel:getWidth() - x), math.min(padding + stringHeight + padding, self.recipeListPanel:getHeight() - y);
    
        self:drawRect(boxX, boxY, boxWidth, boxHeight, 1, 0, 0, 0);
        self:drawRectBorder(boxX, boxY, boxWidth, boxHeight, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        
        local x = self.recipeListPanel:getX() + ((self.recipeListPanel:getWidth() - getTextManager():MeasureStringX(UIFont.Small, tooltipStr)) / 2);
        local y = self.recipeListPanel:getY() + ((self.recipeListPanel:getHeight() - getTextManager():MeasureStringY(UIFont.Small, tooltipStr)) / 2);
        self:drawText(tooltipStr, x, y, 1.0, 1.0, 1.0, 1.0, UIFont.Small);
    end
end

function ISWidgetRecipeListPanel:update()
    ISPanel.update(self);
end

function ISWidgetRecipeListPanel:setSelectedData(_recipe)
    self.pendingSelectedData = _recipe;
end

function ISWidgetRecipeListPanel:setDataList(_recipeList)
    local currentRecipe = self.logic:getRecipe();
    local currentRecipeFound = false;
    
    self.recipeListPanel:clear();
    for i = 0, _recipeList:size()-1 do
        local failed = false;
        if _recipeList:get(i):getOnAddToMenu() then
            local func = _recipeList:get(i):getOnAddToMenu();
            local params = {player = self.player, recipe = _recipeList:get(i), shouldShowAll = self.enabledShowAllFilter}

            failed = not callLuaBool(func, params);
        end
        if not failed then
            local listItem = self.recipeListPanel:addItem(_recipeList:get(i):getTranslationName(), _recipeList:get(i));
            
            if listItem.item == currentRecipe then
                self.recipeListPanel.selected = listItem.itemindex;
                currentRecipeFound = true;
            end
        end
    end

    if not currentRecipeFound then
        self.recipeListPanel.selected = -1;
    end
end

function ISWidgetRecipeListPanel:setInternalDimensions(_x, _y, _width, _height)
    if self.recipeListPanel then
        self.recipeListPanel:setHeight(_height);
        self.recipeListPanel:setWidth(_width);
        self.recipeListPanel:setX(_x);
        self.recipeListPanel:setY(_y);
    end
end

function ISWidgetRecipeListPanel:new(x, y, width, height, player, logic, callbackTarget)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.player = player;
    o.logic = logic;
    o.callbackTarget = callbackTarget;
    o.enabledShowAllFilter = false;

    o.wrapTooltipText = false;

    o.expandToFitTooltip = false;
    o.largestTooltipWidth = 0;

    return o
end