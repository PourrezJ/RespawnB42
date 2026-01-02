-- Server-side trait application
-- The server is authoritative for traits in multiplayer

local function OnClientCommand(module, command, player, args)
    if module ~= 'respawn' then
        return;
    end
    
    print("[Respawn Server] Received command: " .. tostring(command) .. " from player " .. tostring(player:getUsername()));
    
    if command == 'applyTraits' then
        if not args or not args.traits then
            print("[Respawn Server] ERROR: No traits provided");
            return;
        end
        
        print("[Respawn Server] Applying " .. #args.traits .. " traits to player");
        print("[Respawn Server] Traits: " .. table.concat(args.traits, ", "));
        
        local playerTraits = player:getCharacterTraits();
        local addedCount = 0;
        
        for i, traitId in ipairs(args.traits) do
            local success, err = pcall(function()
                local trait = CharacterTrait.get(ResourceLocation.of(traitId));
                if trait then
                    playerTraits:add(trait);
                    print("[Respawn Server] Added trait: " .. tostring(trait));
                    addedCount = addedCount + 1;
                else
                    print("[Respawn Server] ERROR: Could not find trait: " .. traitId);
                end
            end);
            if not success then
                print("[Respawn Server] ERROR adding trait " .. traitId .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Successfully added " .. addedCount .. " traits");
        
        -- Notify client that traits were applied
        sendServerCommand(player, 'respawn', 'traitsApplied', { count = addedCount });
        
    elseif command == 'applyXP' then
        if not args or not args.experience then
            print("[Respawn Server] ERROR: No XP data provided");
            return;
        end
        
        print("[Respawn Server] Applying XP to player");
        local xp = player:getXp();
        local count = 0;
        
        for perkName, experience in pairs(args.experience) do
            local success, err = pcall(function()
                local perk = PerkFactory.getPerkFromName(perkName);
                if perk then
                    xp:AddXP(perk, experience, false, false, false);
                    if count < 5 then
                        print("[Respawn Server] Restored XP for " .. perkName .. ": " .. experience);
                    end
                    count = count + 1;
                else
                    print("[Respawn Server] ERROR: Could not find perk: " .. perkName);
                end
            end);
            if not success then
                print("[Respawn Server] ERROR applying XP for " .. perkName .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Successfully applied XP for " .. count .. " perks");
        sendServerCommand(player, 'respawn', 'xpApplied', { count = count });
        
    elseif command == 'applyBoosts' then
        if not args or not args.boosts then
            print("[Respawn Server] ERROR: No boost data provided");
            return;
        end
        
        print("[Respawn Server] Applying XP boosts to player");
        local xp = player:getXp();
        local count = 0;
        
        for perkName, boost in pairs(args.boosts) do
            local success, err = pcall(function()
                local perk = PerkFactory.getPerkFromName(perkName);
                if perk then
                    xp:AddXP(perk, 0, true, false, false);
                    xp:setPerkBoost(perk, boost);
                    print("[Respawn Server] Restored boost for " .. perkName .. ": " .. boost);
                    count = count + 1;
                else
                    print("[Respawn Server] ERROR: Could not find perk: " .. perkName);
                end
            end);
            if not success then
                print("[Respawn Server] ERROR applying boost for " .. perkName .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Successfully applied " .. count .. " boosts");
        sendServerCommand(player, 'respawn', 'boostsApplied', { count = count });
    end
end

Events.OnClientCommand.Add(OnClientCommand);
