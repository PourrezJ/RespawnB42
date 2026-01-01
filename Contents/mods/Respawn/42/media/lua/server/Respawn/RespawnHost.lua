if not isServer() then
    return;
end

local function LoadOptions()
    local options = Respawn.File.Load(Respawn.OptionsPath);

    if not options then
        options = Respawn.DefaultOptions;
        Respawn.File.Save(Respawn.OptionsPath, options);
    end

    return options;
end

local function AddOptionsToModData()
    writeLog(Respawn.GetLogName(), "adding options to mod data");

    local options = LoadOptions();

    ModData.add(Respawn.GetModDataOptionsKey(), options);
    writeLog(Respawn.GetLogName(), "tables: "..tostring(ModData.getTableNames()));
end

Events.OnInitGlobalModData.Add(AddOptionsToModData);