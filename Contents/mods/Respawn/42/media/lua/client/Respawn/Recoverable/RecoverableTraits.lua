RecoverableTraits = {};

function RecoverableTraits:Save(player)
    Respawn.Data.Stats.Traits = {};
    
    Respawn.DebugLog("RecoverableTraits:Save - Getting traits...");
    local characterTraits = player:getCharacterTraits();
    local traitsList = characterTraits:getKnownTraits();
    
    if not traitsList then
        Respawn.Log("ERROR: getKnownTraits() returned nil");
        return;
    end
    
    -- Get profession-granted traits to filter them out
    local descriptor = player:getDescriptor();
    local profession = descriptor and descriptor:getCharacterProfession();
    local professionDef = nil;
    local grantedTraits = {};
    
    if profession then
        local allProfs = CharacterProfessionDefinition.getProfessions();
        for i = 0, allProfs:size() - 1 do
            local profDef = allProfs:get(i);
            if profDef and profDef:getType() and tostring(profDef:getType()) == tostring(profession) then
                professionDef = profDef;
                break;
            end
        end
        
        if professionDef then
            local grantedList = professionDef:getGrantedTraits();
            if grantedList then
                for i = 0, grantedList:size() - 1 do
                    local grantedTrait = grantedList:get(i);
                    grantedTraits[tostring(grantedTrait)] = true;
                end
            end
        end
    end
    
    local size = traitsList:size();
    for i = 0, size - 1 do
        local trait = traitsList:get(i);
        local traitStr = tostring(trait);
        
        -- Skip profession-granted traits
        if not grantedTraits[traitStr] then
            table.insert(Respawn.Data.Stats.Traits, traitStr);
        end
    end
    
    Respawn.DebugLog("Saved " .. #Respawn.Data.Stats.Traits .. " traits (excluding profession traits)");
end

-- Note: Traits are applied in solo mode via this Load method
-- In multiplayer, traits are applied via server commands
function RecoverableTraits:Load(player)
    if not Respawn.Data.Stats.Traits or #Respawn.Data.Stats.Traits == 0 then
        return
    end
    
    local playerTraits = player:getCharacterTraits()
    
    for _, traitId in ipairs(Respawn.Data.Stats.Traits) do
        local success, err = pcall(function()
            local trait = CharacterTrait.get(ResourceLocation.of(traitId))
            if trait then
                playerTraits:add(trait)
            end
        end)
        if not success then
            Respawn.Log("ERROR adding trait " .. traitId .. ": " .. tostring(err))
        end
    end
    
    Respawn.Log("Restored " .. #Respawn.Data.Stats.Traits .. " traits")
end