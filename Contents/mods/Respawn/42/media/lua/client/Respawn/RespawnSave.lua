local function SetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    print("[Respawn] SavePlayer called - OnPlayerDeath triggered");
    print("[Respawn] Player: " .. tostring(player));
    
    Respawn.Data.Stats = {};
    ModData.add(Respawn.GetModDataStatsKey(), Respawn.Data.Stats);
    
    print("[Respawn] Processing " .. #Respawn.Recoverables .. " recoverables for save");
    for i, recoverable in ipairs(Respawn.Recoverables) do
        print("[Respawn] Saving recoverable [" .. i .. "]: " .. tostring(recoverable));
        recoverable:Save(player);
    end

    print("[Respawn] Save complete. Stats data: " .. tostring(Respawn.Data.Stats));
    
    if isClient() then
        print("[Respawn] Client mode - syncing to server");
        Respawn.Sync.SaveRemote();
    else
        print("[Respawn] Server/Solo mode - no sync needed");
    end

    SetRespawnAvailable();
    print("[Respawn] Respawn availability set for user");
end

Events.OnPlayerDeath.Add(SavePlayer);