RecoverableRecipes = {};

function RecoverableRecipes:Save(player)
    Respawn.DebugLog("RecoverableRecipes:Save called");
    Respawn.Data.Stats.Recipes = {};

    local recipes = player:getKnownRecipes();
    for i = 0, recipes:size() - 1 do
        table.insert(Respawn.Data.Stats.Recipes, recipes:get(i));
    end
    
    Respawn.DebugLog("Saved " .. #Respawn.Data.Stats.Recipes .. " recipes");
end

function RecoverableRecipes:Load(player)
    Respawn.DebugLog("RecoverableRecipes:Load called");
    if not Respawn.Data.Stats.Recipes then
        Respawn.DebugLog("No recipes data to restore");
        return;
    end
    
    local recipes = player:getKnownRecipes();
    for i, recipe in ipairs(Respawn.Data.Stats.Recipes) do
        recipes:add(recipe);
    end
    
    Respawn.Log("Recipes restored");
end