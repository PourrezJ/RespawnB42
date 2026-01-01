local LoadingPlayer = false;

-- Build 42: Register the trait dynamically
local function InitRespawnTrait()
    if not Respawn.Trait then
        print("[Respawn] Registering trait: " .. Respawn.FullId);
        Respawn.Trait = CharacterTrait.register(Respawn.FullId);
        print("[Respawn] Trait registered: " .. tostring(Respawn.Trait));
    end
end
Events.OnGameBoot.Add(InitRespawnTrait);

local function LoadPlayer()
    if not Respawn.Trait then
        print("[Respawn] ERROR: Respawn.Trait is nil in LoadPlayer");
        return;
    end
    
    if not getPlayer():hasTrait(Respawn.Trait) then
        print("[Respawn] Player does not have respawn trait");
        return;
    end
    
    print("[Respawn] Loading player stats...");

    LoadingPlayer = false;

    for i, recoverable in ipairs(Respawn.Recoverables) do
        recoverable:Load(getPlayer());
    end
end

local function OnCreatePlayer(id, player)
    if not Respawn.Trait then
        print("[Respawn] ERROR: Respawn.Trait is nil in OnCreatePlayer");
        return;
    end
    
    -- Wrap everything in pcall to catch any API errors
    local success, err = pcall(function()
        local descriptor = player:getDescriptor();
        local profession = descriptor:getCharacterProfession();
        
        print("[Respawn] OnCreatePlayer - Player profession: " .. tostring(profession));
        
        -- Check if player selected Respawn profession
        -- In Build 42, we need to manually add the trait since getGrantedTraits() doesn't auto-apply
        if profession then
            local profId = tostring(profession);  -- Convert to string for comparison
            print("[Respawn] Profession ID string: " .. profId);
            
            if profId == Respawn.FullId then
                print("[Respawn] Player has Respawn profession! Adding trait manually...");
                player:getCharacterTraits():add(Respawn.Trait);
                print("[Respawn] Trait added, player now has trait: " .. tostring(player:hasTrait(Respawn.Trait)));
            end
        end
        
        print("[Respawn] Checking if player has respawn trait...");
        if not player:hasTrait(Respawn.Trait) then
            print("[Respawn] Player does not have respawn trait");
            return;
        end
        
        print("[Respawn] Player has respawn trait! Starting load process...");

        LoadingPlayer = true;

        if isClient() then
            Respawn.Sync.LoadRemote();
        else
            Respawn.Data.Stats = ModData.get(Respawn.GetModDataStatsKey()) or {};
            LoadPlayer();
        end
    end);
    
    if not success then
        print("[Respawn] ERROR in OnCreatePlayer: " .. tostring(err));
    end
end

local function OnReceiveModData(key, modData)
    if not LoadingPlayer or key ~= Respawn.GetModDataStatsKey() or not modData then
        return;
    end

    LoadPlayer();
end

Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.OnReceiveGlobalModData.Add(OnReceiveModData);