RecoverableRecipes = {};

function RecoverableRecipes:Save(player)
    print("[Respawn] RecoverableRecipes:Save called");
    Respawn.Data.Stats.Recipes = {};

    local recipes = player:getKnownRecipes();
    print("[Respawn] Total known recipes: " .. recipes:size());
    for i = 0, recipes:size() - 1 do
        table.insert(Respawn.Data.Stats.Recipes, recipes:get(i));
    end
    
    print("[Respawn] Saved " .. #Respawn.Data.Stats.Recipes .. " recipes");
end

function RecoverableRecipes:Load(player)
    print("[Respawn] RecoverableRecipes:Load called");
    if not Respawn.Data.Stats.Recipes then
        print("[Respawn] No recipes data to restore");
        return;
    end
    
    print("[Respawn] Restoring " .. #Respawn.Data.Stats.Recipes .. " recipes");
    local recipes = player:getKnownRecipes();

    for i, recipe in ipairs(Respawn.Data.Stats.Recipes) do
        recipes:add(recipe);
    end
    
    print("[Respawn] RecoverableRecipes:Load complete");
end