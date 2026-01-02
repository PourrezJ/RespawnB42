RecoverableExperience = {};

function RecoverableExperience:Save(player)
    print("[Respawn] RecoverableExperience:Save called");
    Respawn.Data.Stats.Experience = {};

    local perks = PerkFactory.PerkList;
    print("[Respawn] Total perks to save: " .. perks:size());
    for i = 0, perks:size() - 1 do
        self:SavePerkXP(player, perks:get(i));
    end
    
    print("[Respawn] Experience data saved. Sample: " .. tostring(Respawn.Data.Stats.Experience.Tailoring or "no tailoring"));
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
    print("[Respawn] RecoverableExperience:Load called");
    if not Respawn.Data.Stats.Experience then
        print("[Respawn] No experience data to restore");
        return;
    end
    
    if isClient() then
        -- In multiplayer, ask server to apply XP
        print("[Respawn] Multiplayer mode - sending XP application request to server");
        sendClientCommand('respawn', 'applyXP', { experience = Respawn.Data.Stats.Experience });
    else
        -- In solo, apply XP locally
        print("[Respawn] Solo mode - resetting and applying XP locally");
        self:ResetXP(player);

        local xp = player:getXp();
        local count = 0;
        for perkName, experience in pairs(Respawn.Data.Stats.Experience) do
            local perk = PerkFactory.getPerkFromName(perkName);
            if perk then
                xp:AddXP(perk, experience, false, false, false);
                if count < 5 then  -- Log first 5
                    print("[Respawn] Restored XP for " .. perkName .. ": " .. experience);
                end
                count = count + 1;
            end
        end
        
        print("[Respawn] RecoverableExperience:Load - Restored XP for " .. count .. " perks");
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