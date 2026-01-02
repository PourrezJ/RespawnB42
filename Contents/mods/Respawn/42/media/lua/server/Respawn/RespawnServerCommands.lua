-- Server-side command handler for multiplayer synchronization
-- The server is authoritative for traits, XP, and boosts in multiplayer

local function OnClientCommand(module, command, player, args)
    if module ~= 'respawn' then
        return;
    end
    
    print("[Respawn Server] Command: " .. tostring(command) .. " from " .. tostring(player:getUsername()));
    
    if command == 'applyTraits' then
        if not args or not args.traits then
            print("[Respawn Server] ERROR: No traits provided");
            return;
        end
        
        local playerTraits = player:getCharacterTraits();
        local addedCount = 0;
        
        for i, traitId in ipairs(args.traits) do
            local success, err = pcall(function()
                local trait = CharacterTrait.get(ResourceLocation.of(traitId));
                if trait then
                    playerTraits:add(trait);
                    addedCount = addedCount + 1;
                end
            end);
            if not success then
                print("[Respawn Server] ERROR adding trait " .. traitId .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Applied " .. addedCount .. " traits");
        sendServerCommand(player, 'respawn', 'traitsApplied', { count = addedCount });
        
    elseif command == 'applyXP' then
        if not args or not args.experience then
            print("[Respawn Server] ERROR: No XP data provided");
            return;
        end
        
        local xp = player:getXp();
        local count = 0;
        
        for perkName, experience in pairs(args.experience) do
            local success, err = pcall(function()
                local perk = PerkFactory.getPerkFromName(perkName);
                if perk then
                    xp:AddXP(perk, experience, false, false, false);
                    count = count + 1;
                end
            end);
            if not success then
                print("[Respawn Server] ERROR applying XP for " .. perkName .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Applied XP for " .. count .. " perks");
        sendServerCommand(player, 'respawn', 'xpApplied', { count = count });
        
    elseif command == 'applyBoosts' then
        if not args or not args.boosts then
            print("[Respawn Server] ERROR: No boost data provided");
            return;
        end
        
        local xp = player:getXp();
        local count = 0;
        
        for perkName, boost in pairs(args.boosts) do
            local success, err = pcall(function()
                local perk = PerkFactory.getPerkFromName(perkName);
                if perk then
                    xp:AddXP(perk, 0, true, false, false);
                    xp:setPerkBoost(perk, boost);
                    count = count + 1;
                end
            end);
            if not success then
                print("[Respawn Server] ERROR applying boost for " .. perkName .. ": " .. tostring(err));
            end
        end
        
        print("[Respawn Server] Applied " .. count .. " boosts");
        sendServerCommand(player, 'respawn', 'boostsApplied', { count = count });
    end
end

Events.OnClientCommand.Add(OnClientCommand);
