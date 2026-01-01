RecoverableTraits = {};

function RecoverableTraits:Save(player)
    Respawn.Data.Stats.Traits = {};
    
    print("[Respawn] RecoverableTraits:Save - Getting traits...");
    local characterTraits = player:getCharacterTraits();
    print("[Respawn] CharacterTraits object: " .. tostring(characterTraits));
    
    -- Get the list of known traits using getKnownTraits()
    local traitsList = characterTraits:getKnownTraits();
    print("[Respawn] KnownTraits list: " .. tostring(traitsList));
    
    if not traitsList then
        print("[Respawn] ERROR: getKnownTraits() returned nil");
        return;
    end
    
    local size = traitsList:size();
    print("[Respawn] Traits count: " .. tostring(size));
    
    for i = 0, size - 1 do
        local trait = traitsList:get(i);
        print("[Respawn] Trait #" .. i .. ": " .. tostring(trait));
        if trait then
            local traitStr = trait:toString();
            print("[Respawn] Trait toString: " .. tostring(traitStr));
            if traitStr then
                table.insert(Respawn.Data.Stats.Traits, traitStr);
            end
        end
    end
    
    print("[Respawn] Saved " .. #Respawn.Data.Stats.Traits .. " traits");
end

function RecoverableTraits:Load(player)
    if not Respawn.Data.Stats.Traits then
        print("[Respawn] RecoverableTraits:Load - No saved traits data");
        return;
    end
    
    print("[Respawn] RecoverableTraits:Load - Restoring " .. #Respawn.Data.Stats.Traits .. " traits");
    
    local playerTraits = player:getCharacterTraits();
    
    -- Build 42: Remove existing traits manually (no clear() method)
    local knownTraits = playerTraits:getKnownTraits();
    if knownTraits then
        local traitsToRemove = {};
        for i = 0, knownTraits:size() - 1 do
            table.insert(traitsToRemove, knownTraits:get(i));
        end
        for _, trait in ipairs(traitsToRemove) do
            playerTraits:remove(trait);
        end
    end

    for i, traitId in ipairs(Respawn.Data.Stats.Traits) do
        print("[Respawn] Restoring trait #" .. i .. ": " .. tostring(traitId));
        -- Build 42: Get the CharacterTrait object from the ID and add it
        local trait = CharacterTrait.get(ResourceLocation.of(traitId));
        if trait then
            playerTraits:add(trait);
            print("[Respawn] Successfully added trait: " .. tostring(trait));
        else
            print("[Respawn] ERROR: Failed to get trait for ID: " .. tostring(traitId));
        end
    end
    
    print("[Respawn] RecoverableTraits:Load - Restoration complete");
end