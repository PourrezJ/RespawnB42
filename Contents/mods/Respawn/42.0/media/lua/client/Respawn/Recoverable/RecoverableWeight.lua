RecoverableWeight = {};

function RecoverableWeight:Save(player)
    Respawn.Data.Stats.Weight = player:getNutrition():getWeight();
end

function RecoverableWeight:Load(player)
    if not Respawn.Data.Stats.Weight then
        return;
    end
    
    player:getNutrition():setWeight(Respawn.Data.Stats.Weight);
end