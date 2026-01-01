RecoverableExperience = {};

function RecoverableExperience:Save(player)
    Respawn.Data.Stats.Experience = {};

    local perks = PerkFactory.PerkList;
    for i = 0, perks:size() - 1 do
        self:SavePerkXP(player, perks:get(i));
    end
end

function RecoverableExperience:SavePerkXP(player, perk)
    local xp = player:getXp();

    if Respawn.Data.Options.ExcludeStrength and perk:getName() == "Strength" or Respawn.Data.Options.ExcludeFitness and perk:getName() == "Fitness" then
        Respawn.Data.Stats.Experience[perk:getName()] = xp:getXP(perk);
        return;
    end
        
    if Respawn.Data.Options.XPRestored == 21 then --Option 21 is "Last Level"
        xp:setXPToLevel(perk, player:getPerkLevel(perk));
        
        Respawn.Data.Stats.Experience[perk:getName()] = xp:getXP(perk);
    else
        Respawn.Data.Stats.Experience[perk:getName()] = xp:getXP(perk) * Respawn.Data.Options.XPRestored / 20;
    end
end

function RecoverableExperience:Load(player)
    if not Respawn.Data.Stats.Experience then
        return;
    end
    
    self:ResetXP(player);

    local xp = player:getXp();
    for perkName, experience in pairs(Respawn.Data.Stats.Experience) do
        local perk = PerkFactory.getPerkFromName(perkName);

        xp:AddXP(perk, experience, false, false, false);
    end
end

function RecoverableExperience:ResetXP(player)
    local perks = PerkFactory.PerkList;
    local xp = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);

        xp:setXPToLevel(perk, 0);
        
        while player:getPerkLevel(perk) > 0 do
            player:LoseLevel(perk);
        end
    end
end