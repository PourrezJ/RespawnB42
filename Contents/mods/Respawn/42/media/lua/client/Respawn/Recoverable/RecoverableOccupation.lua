RecoverableOccupation = {};

function RecoverableOccupation:Save(player)
    local descriptor = player:getDescriptor();
    if descriptor then
        local prof = descriptor:getCharacterProfession();
        if prof then
            Respawn.Data.Stats.Occupation = tostring(prof);
        end
    end
end

function RecoverableOccupation:Load(player)
    -- Occupation is now restored directly in RespawnDeathUI.lua
    -- This function kept for compatibility with the recoverable system
end