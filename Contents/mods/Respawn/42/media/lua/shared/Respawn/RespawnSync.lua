Respawn.Sync = {};

function Respawn.Sync.SaveRemote()
    if not isClient() then
        return;
    end

    ModData.transmit(Respawn.GetModDataStatsKey());
end

function Respawn.Sync.LoadRemote()
    if not isClient() then
        return;
    end

    ModData.request(Respawn.GetModDataStatsKey());
    ModData.request(Respawn.GetModDataOptionsKey());
end

local function OnClientInitGlobalModData()
    if not isClient() then
        return;
    end

    Respawn.Sync.LoadRemote();
end

local function OnServerReceiveModData(key, modData)
    if isClient() or not key:find(Respawn.Id) or key == Respawn.GetModDataOptionsKey() or not modData then
        return;
    end

    ModData.add(key, modData);
end

local function OnClientReceiveStatsModData(key, modData)
    if not isClient() or key ~= Respawn.GetModDataStatsKey() or not modData then
        return;
    end

    Respawn.Data.Stats = modData;
    ModData.add(key, Respawn.Data.Stats);
end

local function OnClientReceiveOptionsModData(key, modData)
    if not isClient() or key ~= Respawn.GetModDataOptionsKey() or not modData then
        return;
    end

    Respawn.Data.Options = modData;
end

Events.OnInitGlobalModData.Add(OnClientInitGlobalModData);
Events.OnReceiveGlobalModData.Add(OnServerReceiveModData);
Events.OnReceiveGlobalModData.Add(OnClientReceiveStatsModData);
Events.OnReceiveGlobalModData.Add(OnClientReceiveOptionsModData);