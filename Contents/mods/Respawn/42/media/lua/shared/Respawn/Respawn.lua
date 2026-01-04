Respawn = {};

Respawn.Id = "respawn"; -- Short ID for ModData keys and internal use
Respawn.FullId = "respawn:respawn"; -- Full ID with namespace (kept for compatibility)
Respawn.Name = "Respawn";
Respawn.PendingRestore = false; -- Flag to indicate restoration should happen after respawn

-- Note: Profession/trait system removed in favor of hooking ISPostDeathUI:onRespawn

Respawn.OptionsPath = "respawn-options.json";
Respawn.AvailablePath = "respawn-available.json";

Respawn.Data = {};
Respawn.Data.Stats = {};
-- Respawn.Data.Options is initialized in RespawnOptions.lua

function Respawn.GetModDataStatsKey()
    return Respawn.Id..'-'..Respawn.GetUserID();
end

function Respawn.GetModDataOptionsKey()
    return Respawn.Id..'-options';
end

function Respawn.GetUserID()
    return isClient() and "player-"..getWorld():getWorld().."-"..getClientUsername() or "player-"..getWorld():getWorld();
end

function Respawn.GetLogName()
    return isClient() and "respawn-client" or "respawn-server";
end