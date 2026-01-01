RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    local descriptor = player:getDescriptor();
    if descriptor then
        Respawn.Data.Stats.Occupation = descriptor:getCharacterProfession();
        print("[Respawn] Saved occupation: " .. tostring(Respawn.Data.Stats.Occupation));
    else
        print("[Respawn] ERROR: player:getDescriptor() returned nil");
    end
end

function RecoverableOccupation:Load(player)
    if not Respawn.Data.Stats.Occupation then
        print("[Respawn] No saved occupation data");
        return;
    end
    
    local descriptor = player:getDescriptor();
    if descriptor then
        -- Build 42: Use setCharacterProfession instead of setProfession
        descriptor:setCharacterProfession(Respawn.Data.Stats.Occupation);
        print("[Respawn] Restored occupation: " .. tostring(Respawn.Data.Stats.Occupation));
    else
        print("[Respawn] ERROR: player:getDescriptor() returned nil during Load");
    end
end