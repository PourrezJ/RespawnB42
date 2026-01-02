Respawn = Respawn or {};
Respawn.Data = Respawn.Data or {};

local LoadingPlayer = false;
local RestoreTickFn = nil;
local LoadPlayerXPAndRecipes;
local ApplyTraitsAndProfession;

local function FindProfessionById(professionId)
    if not professionId then
        return nil;
    end

    local wanted = tostring(professionId);
    local allProfs = CharacterProfessionDefinition.getProfessions();
    for i = 0, allProfs:size() - 1 do
        local profDef = allProfs:get(i);
        local profType = profDef and profDef:getType();
        if profType and tostring(profType) == wanted then
            return profType;
        end
    end

    return nil;
end

local function ScheduleRestore()
    if RestoreTickFn then
        print("[Respawn] ScheduleRestore - Already scheduled, skipping");
        return;
    end

    print("[Respawn] ScheduleRestore - Starting tick scheduler");
    RestoreTickFn = function()
        if not LoadingPlayer then
            print("[Respawn] Restore tick - LoadingPlayer=false, removing tick handler");
            Events.OnTick.Remove(RestoreTickFn);
            RestoreTickFn = nil;
            return;
        end

        local player = getPlayer();
        if not player then
            print("[Respawn] Restore tick - waiting for player (getPlayer() is nil)");
            return;
        end

        if not Respawn.Data or not Respawn.Data.Stats then
            print("[Respawn] Restore tick - waiting for stats data (Respawn.Data.Stats is nil)");
            return;
        end

        print("[Respawn] Restore tick - all prerequisites met, applying profession, traits and XP");
        ApplyTraitsAndProfession(player);
        LoadPlayerXPAndRecipes();
        print("[Respawn] Restore tick - restoration complete, cleaning up");        LoadingPlayer = false;
        Events.OnTick.Remove(RestoreTickFn);
        RestoreTickFn = nil;
    end

    Events.OnTick.Add(RestoreTickFn);
end

LoadPlayerXPAndRecipes = function()
    print("[Respawn] LoadPlayerXPAndRecipes called");
    
    if not Respawn.Data or not Respawn.Data.Stats then
        print("[Respawn] ERROR: No stats data available");
        return;
    end

    print("[Respawn] Stats data available, processing recoverables (count: " .. #Respawn.Recoverables .. ")");
    
    -- Load only XP boosts and recipes (traits/profession already applied)
    for i, recoverable in ipairs(Respawn.Recoverables) do
        -- Skip RecoverableTraits and RecoverableOccupation (already handled separately)
        if recoverable ~= RecoverableTraits and recoverable ~= RecoverableOccupation then
            print("[Respawn] Loading recoverable [" .. i .. "]: " .. tostring(recoverable));
            recoverable:Load(getPlayer());
        else
            print("[Respawn] Skipping recoverable [" .. i .. "]: " .. tostring(recoverable) .. " (already handled)");
        end
    end
    
    print("[Respawn] XP and recipes restoration complete");
end

ApplyTraitsAndProfession = function(player)
    if not Respawn.Data or not Respawn.Data.Stats then
        print("[Respawn] ERROR: No stats data to restore");
        return;
    end
    
    print("[Respawn] ApplyTraitsAndProfession - Starting restoration");
    print("[Respawn] Player: " .. tostring(player));
    print("[Respawn] Stats.OccupationId: " .. tostring(Respawn.Data.Stats.OccupationId));
    print("[Respawn] Stats.Occupation: " .. tostring(Respawn.Data.Stats.Occupation));
    print("[Respawn] Stats.Traits count: " .. (Respawn.Data.Stats.Traits and #Respawn.Data.Stats.Traits or 0));
    
    local descriptor = player:getDescriptor();
    if not descriptor then
        print("[Respawn] ERROR: Could not get descriptor");
        return;
    end
    
    -- Apply profession (this will replace Respawn profession)
    local occupationId = Respawn.Data.Stats.OccupationId or Respawn.Data.Stats.Occupation;
    if occupationId then
        print("[Respawn] Looking up profession for id: " .. tostring(occupationId));
        local profType = FindProfessionById(occupationId);
        if profType then
            print("[Respawn] Found profession type: " .. tostring(profType));
            print("[Respawn] Current profession before restore: " .. tostring(descriptor:getCharacterProfession()));
            descriptor:setCharacterProfession(profType);
            print("[Respawn] Profession restored successfully. New profession: " .. tostring(descriptor:getCharacterProfession()));
        else
            print("[Respawn] ERROR: Could not map occupation id to profession: " .. tostring(occupationId));
        end
    else
        print("[Respawn] WARNING: No occupationId to restore");
    end
    
    -- Apply saved traits - use player traits directly, not descriptor
    if Respawn.Data.Stats.Traits and #Respawn.Data.Stats.Traits > 0 then
        print("[Respawn] Restoring " .. #Respawn.Data.Stats.Traits .. " traits to player");
        print("[Respawn] Saved traits list: " .. table.concat(Respawn.Data.Stats.Traits, ", "));
        
        if isClient() then
            -- In multiplayer, ask server to apply traits (server is authoritative)
            print("[Respawn] Multiplayer mode - sending trait application request to server");
            sendClientCommand('respawn', 'applyTraits', { traits = Respawn.Data.Stats.Traits });
        else
            -- In solo, apply traits locally
            print("[Respawn] Solo mode - applying traits locally");
            local playerTraits = player:getCharacterTraits();
            print("[Respawn] Player traits object: " .. tostring(playerTraits));
            
            for i, traitId in ipairs(Respawn.Data.Stats.Traits) do
                local success, err = pcall(function()
                    local trait = CharacterTrait.get(ResourceLocation.of(traitId));
                    if trait then
                        playerTraits:add(trait);
                        print("[Respawn] Added trait to player: " .. tostring(trait));
                    else
                        print("[Respawn] ERROR: Failed to get trait: " .. tostring(traitId));
                    end
                end);
                if not success then
                    print("[Respawn] ERROR: Exception adding trait " .. traitId .. ": " .. tostring(err));
                end
            end
        end
    else
        print("[Respawn] No traits to restore");
    end
    
    print("[Respawn] Traits and profession restoration complete");
end

local function OnCreatePlayer(id, player)
    -- Get the trait from the registered profession (created in shared)
    if not Respawn.Trait then
        Respawn.Trait = CharacterTrait.get(ResourceLocation.of(Respawn.FullId));
        if Respawn.Trait then
            print("[Respawn] Trait retrieved: " .. tostring(Respawn.Trait));
        else
            print("[Respawn] ERROR: Could not retrieve trait " .. Respawn.FullId);
            return;
        end
    end
    
    local descriptor = player:getDescriptor();
    local profession = descriptor:getCharacterProfession();
    
    print("[Respawn] OnCreatePlayer - Player profession: " .. tostring(profession));
    print("[Respawn] OnCreatePlayer - id=" .. tostring(id) .. ", player=" .. tostring(player));
    
    -- Check if player selected Respawn profession
    if profession then
        local profId = tostring(profession);
        print("[Respawn] Profession ID string: " .. profId);
        print("[Respawn] Respawn.FullId: " .. tostring(Respawn.FullId));
        print("[Respawn] IDs match: " .. tostring(profId == Respawn.FullId));
        
        if profId == Respawn.FullId then
            print("[Respawn] Player has Respawn profession! Will restore stats shortly...");
            print("[Respawn] isClient(): " .. tostring(isClient()));
            LoadingPlayer = true;
            
            -- Load saved data
            if not isClient() then
                print("[Respawn] Server/Solo mode - loading data now");
                local statsKey = Respawn.GetModDataStatsKey();
                print("[Respawn] ModData key: " .. tostring(statsKey));
                Respawn.Data.Stats = ModData.get(statsKey) or {};
                print("[Respawn] Loaded stats from ModData: " .. tostring(Respawn.Data.Stats));
                ScheduleRestore();
            else
                print("[Respawn] Client mode - requesting data from server");
                Respawn.Sync.LoadRemote();
                -- Data will be received in OnReceiveModData, then timer will apply changes
            end
        end
    end
end

local function OnReceiveModData(key, modData)
    print("[Respawn] OnReceiveModData - key: " .. tostring(key) .. ", LoadingPlayer: " .. tostring(LoadingPlayer));
    print("[Respawn] Expected key: " .. tostring(Respawn.GetModDataStatsKey()));
    print("[Respawn] modData is nil: " .. tostring(modData == nil));
    
    if not LoadingPlayer or key ~= Respawn.GetModDataStatsKey() or not modData then
        print("[Respawn] OnReceiveModData - Conditions not met, skipping");
        return;
    end

    print("[Respawn] Received stats data from server");
    print("[Respawn] ModData.OccupationId: " .. tostring(modData.OccupationId));
    print("[Respawn] ModData.Occupation: " .. tostring(modData.Occupation));
    print("[Respawn] ModData.Traits: " .. tostring(modData.Traits and table.concat(modData.Traits, ", ") or "nil"));
    Respawn.Data.Stats = modData;

    ScheduleRestore();
end

Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.OnReceiveGlobalModData.Add(OnReceiveModData);