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
        Respawn.DebugLog("ScheduleRestore - Already scheduled, skipping");
        return;
    end

    Respawn.Log("Starting restoration scheduler");
    RestoreTickFn = function()
        if not LoadingPlayer then
            Respawn.DebugLog("Restore tick - LoadingPlayer=false, removing tick handler");
            Events.OnTick.Remove(RestoreTickFn);
            RestoreTickFn = nil;
            return;
        end

        local player = getPlayer();
        if not player then
            Respawn.DebugLog("Restore tick - waiting for player");
            return;
        end

        if not Respawn.Data or not Respawn.Data.Stats then
            Respawn.DebugLog("Restore tick - waiting for stats data");
            return;
        end

        Respawn.Log("Prerequisites met, restoring character");
        ApplyTraitsAndProfession(player);
        LoadPlayerXPAndRecipes();
        Respawn.Log("Character restoration complete");
        
        LoadingPlayer = false;
        Events.OnTick.Remove(RestoreTickFn);
        RestoreTickFn = nil;
    end

    Events.OnTick.Add(RestoreTickFn);
end

LoadPlayerXPAndRecipes = function()
    Respawn.DebugLog("LoadPlayerXPAndRecipes called");
    
    if not Respawn.Data or not Respawn.Data.Stats then
        Respawn.Log("ERROR: No stats data available");
        return;
    end

    Respawn.DebugLog("Processing " .. #Respawn.Recoverables .. " recoverables");
    
    -- Load XP, boosts and recipes (traits/profession already applied)
    for i, recoverable in ipairs(Respawn.Recoverables) do
        if recoverable ~= RecoverableTraits and recoverable ~= RecoverableOccupation then
            Respawn.DebugLog("Loading recoverable: " .. tostring(recoverable));
            recoverable:Load(getPlayer());
        end
    end
    
    Respawn.DebugLog("XP and recipes restoration complete");
end

ApplyTraitsAndProfession = function(player)
    if not Respawn.Data or not Respawn.Data.Stats then
        Respawn.Log("ERROR: No stats data to restore");
        return;
    end
    
    Respawn.DebugLog("ApplyTraitsAndProfession - Starting restoration");
    
    local descriptor = player:getDescriptor();
    if not descriptor then
        Respawn.Log("ERROR: Could not get descriptor");
        return;
    end
    
    -- Apply profession
    local occupationId = Respawn.Data.Stats.OccupationId;
    if occupationId then
        local profType = FindProfessionById(occupationId);
        if profType then
            descriptor:setCharacterProfession(profType);
            Respawn.Log("Profession restored: " .. tostring(profType));
        else
            Respawn.Log("ERROR: Could not find profession: " .. tostring(occupationId));
        end
    end
    
    -- Apply traits
    if Respawn.Data.Stats.Traits and #Respawn.Data.Stats.Traits > 0 then
        Respawn.DebugLog("Restoring " .. #Respawn.Data.Stats.Traits .. " traits");
        
        if isClient() then
            -- Multiplayer: server applies traits
            sendClientCommand('respawn', 'applyTraits', { traits = Respawn.Data.Stats.Traits });
        else
            -- Solo: apply locally
            local playerTraits = player:getCharacterTraits();
            
            for i, traitId in ipairs(Respawn.Data.Stats.Traits) do
                local success, err = pcall(function()
                    local trait = CharacterTrait.get(ResourceLocation.of(traitId));
                    if trait then
                        playerTraits:add(trait);
                        Respawn.DebugLog("Added trait: " .. traitId);
                    end
                end);
                if not success then
                    Respawn.Log("ERROR adding trait " .. traitId .. ": " .. tostring(err));
                end
            end
            
            Respawn.Log("Traits restored");
        end
    end
end

local function OnCreatePlayer(id, player)
    -- Get the trait from the registered profession
    if not Respawn.Trait then
        Respawn.Trait = CharacterTrait.get(ResourceLocation.of(Respawn.FullId));
        if not Respawn.Trait then
            Respawn.Log("ERROR: Could not retrieve trait " .. Respawn.FullId);
            return;
        end
    end
    
    local descriptor = player:getDescriptor();
    local profession = descriptor:getCharacterProfession();
    
    Respawn.DebugLog("OnCreatePlayer - Profession: " .. tostring(profession));
    
    -- Check if player selected Respawn profession
    if profession and tostring(profession) == Respawn.FullId then
        Respawn.Log("Player selected Respawn profession - loading saved stats");
        LoadingPlayer = true;
        
        if not isClient() then
            -- Solo mode: load from local ModData
            Respawn.Data.Stats = ModData.get(Respawn.GetModDataStatsKey()) or {};
            ScheduleRestore();
        else
            -- Multiplayer: request from server
            Respawn.Sync.LoadRemote();
        end
    end
end

local function OnReceiveModData(key, modData)
    Respawn.DebugLog("OnReceiveModData - key: " .. tostring(key));
    
    if not LoadingPlayer or key ~= Respawn.GetModDataStatsKey() or not modData then
        return;
    end

    Respawn.Log("Received stats data from server");
    Respawn.Data.Stats = modData;
    ScheduleRestore();
end

Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.OnReceiveGlobalModData.Add(OnReceiveModData);