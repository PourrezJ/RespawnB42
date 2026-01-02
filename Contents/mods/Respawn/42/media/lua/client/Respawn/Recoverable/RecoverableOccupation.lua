RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    Respawn.DebugLog("RecoverableOccupation:Save called");
    local descriptor = player:getDescriptor();
    if descriptor then
        local prof = descriptor:getCharacterProfession();
        local profId = prof and tostring(prof) or nil;

        -- Never persist the temporary respawn placeholder
        if profId == Respawn.FullId then
            Respawn.DebugLog("Skipping save (still respawn profession)");
            return;
        end

        Respawn.Data.Stats.OccupationId = profId;
        Respawn.DebugLog("Saved occupation: " .. tostring(profId));
    end
end

function RecoverableOccupation:Load(player)
    Respawn.DebugLog("RecoverableOccupation:Load called");
    local occupationId = Respawn.Data.Stats.OccupationId;
    if not occupationId then
        Respawn.DebugLog("No saved occupation data");
        return;
    end

    occupationId = tostring(occupationId);
    Respawn.DebugLog("Looking up profession: " .. occupationId);

    local descriptor = player:getDescriptor();
    if descriptor then
        local allProfs = CharacterProfessionDefinition.getProfessions();
        for i = 0, allProfs:size() - 1 do
            local profDef = allProfs:get(i);
            local profType = profDef and profDef:getType();
            if profType and tostring(profType) == occupationId then
                descriptor:setCharacterProfession(profType);
                Respawn.DebugLog("Restored occupation: " .. occupationId);
                return;
            end
        end

        Respawn.Log("ERROR: Could not find profession: " .. tostring(occupationId));
    end
end