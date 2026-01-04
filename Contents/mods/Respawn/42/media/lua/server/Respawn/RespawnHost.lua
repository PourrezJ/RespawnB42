if not isServer() then
    return;
end

local function LoadOptions()
    local options = Respawn.File.Load(Respawn.OptionsPath);
    
    if not options then
        options = {
            XPRestored = 21, -- Default: "Last Level"
            ExcludeFitness = true,
            ExcludeStrength = true,
        };
        
        Respawn.File.Save(Respawn.OptionsPath, options);
    end
    
    return options;
end

local function AddOptionsToModData()
    local options = LoadOptions();
    ModData.add(Respawn.GetModDataOptionsKey(), options);
end

Events.OnInitGlobalModData.Add(AddOptionsToModData);