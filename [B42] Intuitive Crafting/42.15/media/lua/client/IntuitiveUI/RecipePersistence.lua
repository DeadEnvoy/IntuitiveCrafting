require "IntuitiveUI/RecipeFilters"
require "Entity/ISUI/CraftRecipe/ISRecipeScrollingListBox"
require "Entity/ISUI/CraftRecipe/ISWidgetRecipesPanel"

local original_ISRecipeScrollingListBox_addGroup = ISRecipeScrollingListBox.addGroup
function ISRecipeScrollingListBox:addGroup(_groupNode, _nodes, _recipeToSelect, _enabledShowAllFilter)
    local index = original_ISRecipeScrollingListBox_addGroup(self, _groupNode, _nodes, _recipeToSelect, _enabledShowAllFilter)
    if index ~= -1 and _groupNode then
        if self:isCraftable(_recipeToSelect) then
            _groupNode:setExpandedState(CraftRecipeListNodeExpandedState.PARTIAL)
        else
            _groupNode:setExpandedState(CraftRecipeListNodeExpandedState.OPEN)
        end
    end
    return index
end

local original_ISHandCraftPanel_new = ISHandCraftPanel.new
function ISHandCraftPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = original_ISHandCraftPanel_new(self, x, y, width, height, player, craftBench, isoObject, recipeQuery)

    o.seeAllRecipe = ISHandCraftPanel.lastSeeAll or nil;

    o.pendingCategory = ISHandCraftPanel.lastCategory or nil;
    o.pendingRecipeName = ISHandCraftPanel.lastRecipeName or nil;

    return o
end

local original_ISHandCraftPanel_setSeeAllRecipe = ISHandCraftPanel.setSeeAllRecipe
function ISHandCraftPanel:setSeeAllRecipe(enabled)
    ISHandCraftPanel.lastSeeAll = enabled;
    original_ISHandCraftPanel_setSeeAllRecipe(self, enabled)
end

local original_ISHandCraftPanel_onCategoryChanged = ISHandCraftPanel.onCategoryChanged
function ISHandCraftPanel:onCategoryChanged(category)
    ISHandCraftPanel.lastCategory = category;
    self.logic:setRecipe(nil)
    original_ISHandCraftPanel_onCategoryChanged(self, category)
end

local original_ISHandCraftPanel_onRecipeChanged = ISHandCraftPanel.onRecipeChanged
function ISHandCraftPanel:onRecipeChanged(recipe)
    if recipe and recipe.getName then
        ISHandCraftPanel.lastRecipeName = recipe:getName()
    end
    original_ISHandCraftPanel_onRecipeChanged(self, recipe)
end

local original_ISHandCraftPanel_onUpdateRecipeList = ISHandCraftPanel.onUpdateRecipeList
function ISHandCraftPanel:onUpdateRecipeList(recipeList)
    if self.pendingCategory then
        local found = false
        if self.pendingCategory == "*" or self.pendingCategory == "" then
            found = true
        else
            local categories = self.logic:getCategoryList()
            if categories then
                for i=0, categories:size()-1 do
                    if categories:get(i) == self.pendingCategory then
                        found = true
                        break
                    end
                end
            end
        end

        if found then
            local category = self.pendingCategory
            self.pendingCategory = nil
            if self.recipeCategories then
                self.recipeCategories.selectedCategory = category
            end
            self:onCategoryChanged(category)
        elseif self.logic:getCategoryList() and self.logic:getCategoryList():size() > 0 then
            self.pendingCategory = nil
        end
    end

    if self.pendingRecipeName and not self.pendingCategory then
        local collection = recipeList or self.logic:getRecipeList()
        if collection then
            local allRecipes = collection:getAllRecipes()
            for i=0, allRecipes:size()-1 do
                local recipe = allRecipes:get(i)
                if recipe and recipe.getName and recipe:getName() == self.pendingRecipeName then
                    self.logic:setRecipe(recipe)
                    self.pendingRecipeName = nil
                    break
                end
            end
        end
    end

    original_ISHandCraftPanel_onUpdateRecipeList(self, recipeList)
end

local original_ISBuildPanel_new = ISBuildPanel.new
function ISBuildPanel:new(x, y, width, height, player, craftBench, isoObject, recipeQuery)
    local o = original_ISBuildPanel_new(self, x, y, width, height, player, craftBench, isoObject, recipeQuery)

    o.filterAllVersions = ISBuildPanel.lastFilterAll or nil;

    o.pendingCategory = ISBuildPanel.lastCategory or nil;
    o.pendingRecipeName = ISBuildPanel.lastRecipeName or nil;
    
    return o
end

local original_ISBuildPanel_createChildren = ISBuildPanel.createChildren
function ISBuildPanel:createChildren()
    original_ISBuildPanel_createChildren(self)
    if self.filterAllVersions and self.recipesPanel and self.recipesPanel.recipeListPanel then
        self.recipesPanel.recipeListPanel.enabledShowAllFilter = true;
        self:refreshList();
    end
end

function ISBuildPanel:refreshList()
    local list = self.logic:getAllBuildableRecipes();
    self.logic:setRecipes(list);
    
    self:ReselectRecipeOrFirst(self.logic:getRecipe());
end

local original_ISBuildPanel_onCategoryChanged = ISBuildPanel.onCategoryChanged
function ISBuildPanel:onCategoryChanged(category)
    ISBuildPanel.lastCategory = category;
    self.logic:setRecipe(nil)
    
    if self.pendingRecipeName then
        self._categoryString = category;
        self:filterRecipeList();
        return;
    end

    original_ISBuildPanel_onCategoryChanged(self, category)
end

local original_ISBuildPanel_onRecipeChanged = ISBuildPanel.onRecipeChanged
function ISBuildPanel:onRecipeChanged(recipe)
    if recipe and recipe.getName and not self.pendingRecipeName then
        ISBuildPanel.lastRecipeName = recipe:getName()
    end
    original_ISBuildPanel_onRecipeChanged(self, recipe)
end

local original_ISBuildPanel_onUpdateRecipeList = ISBuildPanel.onUpdateRecipeList
function ISBuildPanel:onUpdateRecipeList(recipeList)
    if self.pendingCategory then
        local found = false
        if self.pendingCategory == "*" or self.pendingCategory == "" then
            found = true
        else
            local categories = self.logic:getCategoryList()
            if categories then
                for i=0, categories:size()-1 do
                    if categories:get(i) == self.pendingCategory then
                        found = true
                        break
                    end
                end
            end
        end

        if found then
            local category = self.pendingCategory
            self.pendingCategory = nil
            if self.recipeCategories then
                self.recipeCategories.selectedCategory = category
            end
            self:onCategoryChanged(category)
        elseif self.logic:getCategoryList() and self.logic:getCategoryList():size() > 0 then
            self.pendingCategory = nil
        end
    end

    original_ISBuildPanel_onUpdateRecipeList(self, recipeList)
end

local original_ISBuildPanel_ReselectRecipeOrFirst = ISBuildPanel.ReselectRecipeOrFirst
function ISBuildPanel:ReselectRecipeOrFirst(_recipe)
    if self.pendingRecipeName then
        local collection = self.logic:getRecipeList()
        if collection then
            local allRecipes = collection:getAllRecipes()
            for i=0, allRecipes:size()-1 do
                local recipe = allRecipes:get(i)
                if recipe and recipe.getName and recipe:getName() == self.pendingRecipeName then
                    _recipe = recipe
                    self.pendingRecipeName = nil
                    break
                end
            end
        end
    end
    original_ISBuildPanel_ReselectRecipeOrFirst(self, _recipe)
end

local original_ISWidgetRecipesPanel_OnFilterAll = ISWidgetRecipesPanel.OnFilterAll
function ISWidgetRecipesPanel:OnFilterAll(filter)
    if self.callbackTarget and self.callbackTarget.Type == "ISBuildPanel" then
        ISBuildPanel.lastFilterAll = filter;
        self.callbackTarget.filterAllVersions = filter;
    end
    original_ISWidgetRecipesPanel_OnFilterAll(self, filter)
end

local original_ISWidgetRecipeFilterPanel_createChildren = ISWidgetRecipeFilterPanel.createChildren
function ISWidgetRecipeFilterPanel:createChildren()
    original_ISWidgetRecipeFilterPanel_createChildren(self)

    if self.showAllRecipeTickBox and self.callbackTarget and self.callbackTarget.Type == "ISHandCraftPanel" then
        if self.callbackTarget.seeAllRecipe then
            self.showAllRecipeTickBox:setSelected(1, true);
        end
    end

    if self.tickBoxShowAllVersion and self.callbackTarget and self.callbackTarget.Type == "ISBuildPanel" then
        if self.callbackTarget.filterAllVersions then
            self.tickBoxShowAllVersion:setSelected(1, true);
        end
    end
end