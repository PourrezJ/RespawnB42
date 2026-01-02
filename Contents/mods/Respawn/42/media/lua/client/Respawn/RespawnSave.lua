local function SetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    Respawn.Log("Saving character stats (OnPlayerDeath)");
    
    Respawn.Data.Stats = {};
    ModData.add(Respawn.GetModDataStatsKey(), Respawn.Data.Stats);
    
    for i, recoverable in ipairs(Respawn.Recoverables) do
        Respawn.DebugLog("Saving recoverable: " .. tostring(recoverable));
        recoverable:Save(player);
    end

    Respawn.DebugLog("Save complete");
    
    if isClient() then
        Respawn.Sync.SaveRemote();
    end

    SetRespawnAvailable();
    Respawn.Log("Character stats saved successfully");
end

Events.OnPlayerDeath.Add(SavePlayer);