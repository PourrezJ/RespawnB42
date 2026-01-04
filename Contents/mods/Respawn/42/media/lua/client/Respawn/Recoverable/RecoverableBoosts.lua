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
        return;
    end
    
    if isClient() then
        -- Multiplayer: server applies boosts
        sendClientCommand('respawn', 'applyBoosts', { boosts = Respawn.Data.Stats.Boosts });
    else
        -- Solo: apply locally
        local xp = player:getXp();
        
        for perkName, boost in pairs(Respawn.Data.Stats.Boosts) do
            local perk = PerkFactory.getPerkFromName(perkName);
            if perk then
                xp:AddXP(perk, 0, true, false, false);
                xp:setPerkBoost(perk, boost);
            end
        end
        
        Respawn.Log("Boosts restored");
    end
end