-- Simplified load system - restoration is now triggered from RespawnDeathUI.lua
-- This file just handles receiving ModData from server in multiplayer

local function OnReceiveModData(modDataKey, modData)
    if not string.find(modDataKey, Respawn.Id) then
        return;
    end

    Respawn.Log("Received ModData: " .. tostring(modDataKey));
    
    if modDataKey == Respawn.GetModDataStatsKey() then
        Respawn.Data.Stats = modData;
        Respawn.Log("Stats data loaded from ModData");
    elseif modDataKey == Respawn.GetModDataOptionsKey() then
        Respawn.Data.Options = modData;
        Respawn.Log("Options data loaded from ModData");
    end
end

Events.OnReceiveGlobalModData.Add(OnReceiveModData);
