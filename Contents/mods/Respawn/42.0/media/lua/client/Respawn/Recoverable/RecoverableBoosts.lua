RecoverableBoosts = {};

function RecoverableBoosts:Save(player)
    Respawn.Data.Stats.Boosts = {};

    local perks = PerkFactory.PerkList;
    local xp = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        local boost = xp:getPerkBoost(perk);

        if boost > 0 then
            Respawn.Data.Stats.Boosts[perk:getName()] = boost;
        end
    end
end

function RecoverableBoosts:Load(player)
    if not Respawn.Data.Stats.Boosts then
        print("[Respawn] RecoverableBoosts:Load - No saved boosts data");
        return;
    end
    
    print("[Respawn] RecoverableBoosts:Load - Restoring " .. tostring(#Respawn.Data.Stats.Boosts) .. " XP boosts");
    
    -- Build 42: Apply boosts directly via XP system instead of via profession
    local xp = player:getXp();
    
    for perkName, boost in pairs(Respawn.Data.Stats.Boosts) do
        local perk = PerkFactory.getPerkFromName(perkName);
        if perk then
            print("[Respawn] Restoring boost for " .. perkName .. ": " .. tostring(boost));
            xp:AddXP(perk, 0, true, false, false); -- Initialize if needed
            xp:setPerkBoost(perk, boost); -- Apply the boost directly
        else
            print("[Respawn] ERROR: Could not find perk: " .. perkName);
        end
    end
    
    print("[Respawn] RecoverableBoosts:Load - Restoration complete");
end