require "Entity/ISUI/CraftRecipe/ISRecipeScrollingListBox"

local UI_BORDER_SPACING = 10
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_HEADING = getTextManager():getFontHeight(UIFont.Small)
local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 19
local ICON_SCALE = math.max(1, (FONT_SCALE - math.floor(FONT_SCALE)) < 0.5 and math.floor(FONT_SCALE) or math.ceil(FONT_SCALE))
local LIST_ICON_SIZE, LIST_SUBICON_SIZE, LIST_FAVICON_SIZE = 32 * ICON_SCALE, 16 * ICON_SCALE, 10 * ICON_SCALE
local LIST_SUBICON_SPACING, SUBCATEGORY_INDENT = 2 * ICON_SCALE, LIST_ICON_SIZE

local xpAwardFieldCache = {}
local function getXPAwardVal(object, fieldName)
    if not object then return nil end
    if xpAwardFieldCache[fieldName] then
        return getClassFieldVal(object, xpAwardFieldCache[fieldName])
    end
    for i=0, getNumClassFields(object)-1 do
        local f = getClassField(object, i)
        local s = tostring(f)
        local name = string.match(s, "%.([^%.]+)$")
        if name == fieldName then
            xpAwardFieldCache[fieldName] = f
            return getClassFieldVal(object, f)
        end
    end
    return nil
end

local function getPerkXpMultiplier(player, perk)
    if not player or not perk then return 1.0 end
    
    local multiplier = 1.0
    
    if player:hasTrait(CharacterTrait.FAST_LEARNER) then
        multiplier = multiplier * 1.3
    end
    
    if player:hasTrait(CharacterTrait.SLOW_LEARNER) then
        multiplier = multiplier * 0.7
    end
    
    if player:hasTrait(CharacterTrait.PACIFIST) then
        local perkType = perk:getType()
        if perkType == Perks.SmallBlade or perkType == Perks.LongBlade or
           perkType == Perks.SmallBlunt or perkType == Perks.Spear or
           perkType == Perks.Blunt or perkType == Perks.Axe or
           perkType == Perks.Aiming then
            multiplier = multiplier * 0.75
        end
    end
    
    if player:hasTrait(CharacterTrait.CRAFTY) then
        local parent = perk:getParent()
        if parent == Perks.Crafting then
            multiplier = multiplier * 1.3
        end
    end
    
    return multiplier
end

function ISRecipeScrollingListBox:doDrawNode(y, item, _alt)
    local craftRecipe = item and item.item
    local isInGroup = item and item.node and item.node:getParent() ~= nil
    local xOffset = isInGroup and SUBCATEGORY_INDENT or 0
    
    if craftRecipe then
        local favString = BaseCraftingLogic.getFavouriteModDataString(craftRecipe)
        local isFavourite = self.player:getModData()[favString] or false

        local yActual = self:getYScroll() + y
        if item.cachedHeight and (yActual > self.height or (yActual + item.cachedHeight) < 0) then
            return y + item.cachedHeight
        end

        if not item.height then item.height = self.itemheight end
        local safeDrawWidth = self:getWidth() - (self.vscroll and self.vscroll:getWidth() or 0) - xOffset

        local cheat = self.player:isBuildCheat()

        local color = self:isCraftable(craftRecipe) and {r=1.0, g=1.0, b=1.0, a=1.0} or {r=0.5, g=0.5, b=0.5, a=1.0}

        if self.selected == item.index then
            self:drawSelection(0, y, self:getWidth(), item.height-1)
        elseif (self.mouseoverselected == item.index) and self:isMouseOver() and not self:isMouseOverScrollBar() then
            self:drawMouseOverHighlight(0, y, self:getWidth(), item.height-1)
        end

        self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)

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

        if cheat then
            colBad = colGood
        end

        local detailsLeft = UI_BORDER_SPACING + LIST_ICON_SIZE + UI_BORDER_SPACING + xOffset
        local detailsY = 4

        local fileSize = ".png"
        if LIST_SUBICON_SIZE == 16 then
            fileSize = "_16.png"
        end

        local iconRight = safeDrawWidth - UI_BORDER_SPACING - (LIST_SUBICON_SIZE/2) - LIST_SUBICON_SPACING
        if craftRecipe:isCanWalk() then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking" .. fileSize)
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
        end
        if not craftRecipe:canBeDoneInDark() and not self.ignoreLightIcon then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light" .. fileSize)
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
        end
        if craftRecipe:needToBeLearn() then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book" .. fileSize)
            local alpha = 1
            if not self.player:isRecipeKnown(craftRecipe, true) then
                alpha = 0.5
            end
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, alpha, color.r, color.g, color.b)
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
        end
        if not craftRecipe:isInHandCraftCraft() and not self.ignoreSurface then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface" .. fileSize)
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b)
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING
        end

        local maxTitleWidth = (iconRight - detailsLeft) - (UI_BORDER_SPACING + LIST_SUBICON_SIZE + LIST_SUBICON_SPACING)
        local titleStr = getTextManager():WrapText(UIFont.Small, craftRecipe:getTranslationName(), maxTitleWidth, 2, "...")
        if isDebugEnabled() then
            local tags = ""
            for i=0,craftRecipe:getTags():size() -1 do
                tags = tags .. craftRecipe:getTags():get(i)
                if i < craftRecipe:getTags():size()-1 then
                    tags = tags .. ", "
                end
            end
            titleStr = titleStr .. " (tags: " .. tags .. ")"
        end
        
        local headerTextHeight = getTextManager():MeasureStringY(UIFont.Small, titleStr)
        
        if not craftRecipe:getTooltip() and craftRecipe:getXPAwardCount() == 0 and craftRecipe:getRequiredSkillCount() == 0 then
            detailsY = (self.itemheight - headerTextHeight) / 2
        else
            local headerAdj = (LIST_SUBICON_SIZE - FONT_HGT_HEADING) / 2
            detailsY = detailsY + headerAdj
        end

        self:drawText(titleStr, detailsLeft, y +detailsY, color.r, color.g, color.b, color.a, UIFont.Small)

        detailsY = detailsY + headerTextHeight
        
        if craftRecipe:getTooltip() then
            local text = getText(craftRecipe:getTooltip())
            if self.wrapTooltipText then
                local tooltipAvailableWidth = (safeDrawWidth - detailsLeft) - (UI_BORDER_SPACING*2 + LIST_SUBICON_SPACING)
                text = text:gsub("\n", " ")
                text = getTextManager():WrapText(UIFont.Small, text, tooltipAvailableWidth)
            end
            self:drawText(text, detailsLeft, y +detailsY, 0.5, 0.5, 0.5, color.a, UIFont.Small)
            local split = luautils.split(text, "\n")
            for i,v in ipairs(split) do
                detailsY = detailsY + FONT_HGT_SMALL
            end
        end

        if craftRecipe:getXPAwardCount() > 0 then
            local currentXpDrawX = detailsLeft
            local maxYInLine = 0
            local firstXpInLine = true
            local separatorColor = {r=0.7, g=0.7, b=0.7, a=1.0}
            local separatorWidth = getTextManager():MeasureStringX(UIFont.Small, ", ")
            
            for awardIndex = 0, craftRecipe:getXPAwardCount() - 1 do
                local XPAward = craftRecipe:getXPAward(awardIndex)
                
                local skillPerk = getXPAwardVal(XPAward, "perk")
                local xpAmount = getXPAwardVal(XPAward, "amount")
                
                if skillPerk and xpAmount then
                    local baseRealExp = xpAmount / 4
                    
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
                    local isBookBoosted = false
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
                    
                    local traitAndBoostMultiplier = getPerkXpMultiplier(self.player, skillPerk)

                    local finalRealExp = baseRealExp * finalEffectiveSandboxMultiplier * bookSkillMultiplier * traitAndBoostMultiplier
                    if finalRealExp < 0 then finalRealExp = 0 end
                    
                    local singleXpString = getText("IGUI_perks_" .. skillPerk:toString()) .. " (+" .. string.format("%.1f",finalRealExp) .. ")"
                    local xpTextColor; if isBookBoosted then
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
                        detailsY = detailsY + maxYInLine
                        maxYInLine = textHeight
                        firstXpInLine = true
                    end
                    
                    if not firstXpInLine then
                        self:drawText(", ", currentXpDrawX, y + detailsY, separatorColor.r, separatorColor.g, separatorColor.b, separatorColor.a, UIFont.Small)
                        currentXpDrawX = currentXpDrawX + separatorWidth
                    end
                    
                    self:drawText(singleXpString, currentXpDrawX, y + detailsY, xpTextColor.r, xpTextColor.g, xpTextColor.b, xpTextColor.a, UIFont.Small)
                    currentXpDrawX = currentXpDrawX + textWidth
                    firstXpInLine = false
                end
            end
            if maxYInLine > 0 then
                detailsY = detailsY + maxYInLine
            end
        end

        if craftRecipe:getRequiredSkillCount()>0 then
            for i=0,craftRecipe:getRequiredSkillCount()-1 do
                local requiredSkill = craftRecipe:getRequiredSkill(i)
                local hasSkill = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
                local lineColor = hasSkill and colGood or colBad

                local text = getText("IGUI_CraftingWindow_Requires2").." ".. tostring(requiredSkill:getPerk():getName()).." "..getText("IGUI_CraftingWindow_Level").." " .. tostring(requiredSkill:getLevel())
                self:drawText(text, detailsLeft, y +detailsY, lineColor.r, lineColor.g, lineColor.b, lineColor.a, UIFont.Small)
                detailsY = detailsY + FONT_HGT_SMALL
            end
        end

        local usedHeight = math.max(self.itemheight, detailsY + UI_BORDER_SPACING)
        if isFavourite then
            usedHeight = math.max(usedHeight, LIST_ICON_SIZE + (LIST_FAVICON_SIZE/2))
        end

        item.height = usedHeight
        item.cachedHeight = usedHeight

        local iconY = y + (usedHeight/2)-(LIST_ICON_SIZE/2)
        local texture = craftRecipe:getIconTexture()
        self:drawTextureScaledAspect(texture, UI_BORDER_SPACING + xOffset, iconY, LIST_ICON_SIZE, LIST_ICON_SIZE, color.a, color.r, color.g, color.b)

        local starIconY = iconY + (LIST_ICON_SIZE) - (LIST_FAVICON_SIZE)
        if isFavourite then
            self:drawTextureScaledAspect(self.starSetTexture, UI_BORDER_SPACING + xOffset, starIconY, LIST_FAVICON_SIZE, LIST_FAVICON_SIZE, color.a, getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB())
        end

        return y + usedHeight
    end
    return y
end