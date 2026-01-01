local function SetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    Respawn.Data.Stats = {};
    ModData.add(Respawn.GetModDataStatsKey(), Respawn.Data.Stats);

    for i, recoverable in ipairs(Respawn.Recoverables) do
        recoverable:Save(player);
    end

    if isClient() then
        Respawn.Sync.SaveRemote();
    end

    SetRespawnAvailable();
end

Events.OnPlayerDeath.Add(SavePlayer);