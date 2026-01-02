RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    print("[Respawn] RecoverableOccupation:Save called");
    local descriptor = player:getDescriptor();
    print("[Respawn] Descriptor: " .. tostring(descriptor));
    if descriptor then
        local prof = descriptor:getCharacterProfession();
        print("[Respawn] Current profession object: " .. tostring(prof));
        local profId = prof and tostring(prof) or nil;
        print("[Respawn] Profession ID string: " .. tostring(profId));
        print("[Respawn] Respawn.FullId: " .. tostring(Respawn.FullId));

        -- Never persist the temporary respawn placeholder as the "real" occupation
        if profId == Respawn.FullId then
            print("[Respawn] Saved occupation skipped (still respawn profession)");
            return;
        end

        Respawn.Data.Stats.OccupationId = profId;
        Respawn.Data.Stats.Occupation = nil;
        print("[Respawn] Saved occupation id: " .. tostring(Respawn.Data.Stats.OccupationId));
    else
        print("[Respawn] ERROR: player:getDescriptor() returned nil");
    end
end

function RecoverableOccupation:Load(player)
    print("[Respawn] RecoverableOccupation:Load called");
    local occupationId = Respawn.Data.Stats.OccupationId or Respawn.Data.Stats.Occupation;
    print("[Respawn] OccupationId from Stats: " .. tostring(occupationId));
    if not occupationId then
        print("[Respawn] No saved occupation data");
        return;
    end

    occupationId = tostring(occupationId);
    print("[Respawn] Looking up profession: " .. occupationId);

    local descriptor = player:getDescriptor();
    print("[Respawn] Descriptor: " .. tostring(descriptor));
    if descriptor then
        local allProfs = CharacterProfessionDefinition.getProfessions();
        print("[Respawn] Total professions available: " .. allProfs:size());
        for i = 0, allProfs:size() - 1 do
            local profDef = allProfs:get(i);
            local profType = profDef and profDef:getType();
            local profTypeStr = profType and tostring(profType) or "nil";
            if i < 5 then  -- Log first 5 professions
                print("[Respawn] Profession [" .. i .. "]: " .. profTypeStr);
            end
            if profType and tostring(profType) == occupationId then
                print("[Respawn] MATCH FOUND! Setting profession to: " .. profTypeStr);
                descriptor:setCharacterProfession(profType);
                print("[Respawn] Restored occupation id: " .. occupationId);
                return;
            end
        end

        print("[Respawn] ERROR: Could not map occupation id to profession: " .. tostring(occupationId));
        print("[Respawn] Searched through " .. allProfs:size() .. " professions without finding a match");
    else
        print("[Respawn] ERROR: player:getDescriptor() returned nil during Load");
    end
end