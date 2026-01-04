RecoverableExperience = {};

function RecoverableExperience:Save(player)
    Respawn.DebugLog("RecoverableExperience:Save called");
    Respawn.Data.Stats.Experience = {};

    local perks = PerkFactory.PerkList;
    for i = 0, perks:size() - 1 do
        self:SavePerkXP(player, perks:get(i));
    end
    
    Respawn.DebugLog("Experience data saved");
end

function RecoverableExperience:SavePerkXP(player, perk)
    local xp = player:getXp();
    local perkName = perk:getName();
    local options = Respawn.Data.Options or {};
    
    -- Get the XPRestored option (1-21, where 21 = "Last Level")
    local xpRestoredOption = options.XPRestored or 21;
    
    -- Debug: Log the active option on first call
    if perkName == "Strength" then
        Respawn.Log("SavePerkXP - Active XPRestored option: " .. tostring(xpRestoredOption));
    end
    
    -- Check if this perk should be excluded (100% XP restore)
    local isExcluded = (options.ExcludeStrength and perkName == "Strength") or 
                       (options.ExcludeFitness and perkName == "Fitness");
    
    if isExcluded then
        Respawn.Data.Stats.Experience[perkName] = xp:getXP(perk);
        return;
    end
        
    if xpRestoredOption == 21 then
        -- Option 21 is "Last Level" - save XP needed to reach current level
        xp:setXPToLevel(perk, player:getPerkLevel(perk));
        Respawn.Data.Stats.Experience[perkName] = xp:getXP(perk);
    else
        -- Options 1-20 correspond to 5%-100% (option 1 = 5%, option 20 = 100%)
        -- Formula: (option * 5) / 100 = option / 20
        local percentage = xpRestoredOption / 20;
        Respawn.Data.Stats.Experience[perkName] = xp:getXP(perk) * percentage;
    end
end

function RecoverableExperience:Load(player)
    if not Respawn.Data.Stats.Experience then
        return;
    end
    
    if isClient() then
        -- Multiplayer: server applies XP
        sendClientCommand('respawn', 'applyXP', { experience = Respawn.Data.Stats.Experience });
    else
        -- Solo: apply locally
        self:ResetXP(player);
        local xp = player:getXp();
        
        for perkName, experience in pairs(Respawn.Data.Stats.Experience) do
            local perk = PerkFactory.getPerkFromName(perkName);
            if perk then
                xp:AddXP(perk, experience, false, false, false);
            end
        end
        
        Respawn.Log("Experience restored");
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