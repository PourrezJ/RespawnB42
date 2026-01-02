RecoverableBoosts = {};

function RecoverableBoosts:Save(player)
    print("[Respawn] RecoverableBoosts:Save called");
    Respawn.Data.Stats.Boosts = {};

    local perks = PerkFactory.PerkList;
    local xp = player:getXp();
    print("[Respawn] Checking XP boosts for " .. perks:size() .. " perks");
    local count = 0;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        local boost = xp:getPerkBoost(perk);

        if boost > 0 then
            Respawn.Data.Stats.Boosts[perk:getName()] = boost;
            print("[Respawn] Saved boost for " .. perk:getName() .. ": " .. boost);
            count = count + 1;
        end
    end
    
    print("[Respawn] RecoverableBoosts:Save - Saved " .. count .. " boosts");
end

function RecoverableBoosts:Load(player)
    if not Respawn.Data.Stats.Boosts then
        print("[Respawn] RecoverableBoosts:Load - No saved boosts data");
        return;
    end
    
    print("[Respawn] RecoverableBoosts:Load - Restoring XP boosts");
    
    if isClient() then
        -- In multiplayer, ask server to apply boosts
        print("[Respawn] Multiplayer mode - sending boost application request to server");
        sendClientCommand('respawn', 'applyBoosts', { boosts = Respawn.Data.Stats.Boosts });
    else
        -- In solo, apply boosts locally
        print("[Respawn] Solo mode - applying boosts locally");
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
end