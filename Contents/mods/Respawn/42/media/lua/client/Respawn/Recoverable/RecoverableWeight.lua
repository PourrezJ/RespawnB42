RecoverableWeight = {};

function RecoverableWeight:Save(player)
    Respawn.Data.Stats.Weight = player:getNutrition():getWeight();
end

function RecoverableWeight:Load(player)
    if Respawn.Data.Stats.Weight then
        player:getNutrition():setWeight(Respawn.Data.Stats.Weight);
    end
end