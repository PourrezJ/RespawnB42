if not isServer() then
    return;
end

-- Build 42: Profession registration moved to shared/Respawn/RespawnProfessionInit.lua
-- This ensures the profession is available on both server and client
--[[
local function InitRespawnProfessionOnServer()
    print("[Respawn Server] Registering profession...");
    
    -- Register the trait first
    local trait = CharacterTrait.register(Respawn.FullId);
    if not trait then
        print("[Respawn Server] ERROR: Could not register trait");
        return;
    end
    print("[Respawn Server] Trait registered: " .. tostring(trait));
    
    -- Register the profession enum
    local prof = CharacterProfession.register(Respawn.FullId);
    if not prof then
        print("[Respawn Server] ERROR: Could not register profession enum");
        return;
    end
    print("[Respawn Server] Profession enum registered: " .. tostring(prof));
    
    -- Create profession definition
    local profDef = CharacterProfessionDefinition.addCharacterProfessionDefinition(
        prof,
        "Respawn",
        0,
        "Respawn character",
        "profession_unemployed"
    );
    
    if profDef and trait then
        profDef:getGrantedTraits():add(trait);
        print("[Respawn Server] Profession registered successfully with granted trait");
    else
        print("[Respawn Server] ERROR: Could not create profession definition");
    end
end

-- Use OnGameBoot instead of OnServerStarted for both dedicated servers and host mode
Events.OnGameBoot.Add(InitRespawnProfessionOnServer);
--]]

local function LoadOptions()
    -- Try to load from file first
    local options = Respawn.File.Load(Respawn.OptionsPath);
    
    if not options then
        -- Create default options if file doesn't exist
        options = {
            XPRestored = 21, -- Default: "Last Level"
            ExcludeFitness = true,
            ExcludeStrength = true,
        };
        
        -- Save default options to file for future editing
        Respawn.File.Save(Respawn.OptionsPath, options);
        print("[Respawn Server] Created default options file: " .. Respawn.OptionsPath);
    else
        print("[Respawn Server] Loaded options from file: " .. Respawn.OptionsPath);
    end
    
    print("[Respawn Server] Server options:");
    print("  XPRestored: " .. tostring(options.XPRestored));
    print("  ExcludeFitness: " .. tostring(options.ExcludeFitness));
    print("  ExcludeStrength: " .. tostring(options.ExcludeStrength));

    return options;
end

local function AddOptionsToModData()
    writeLog(Respawn.GetLogName(), "adding options to mod data");

    local options = LoadOptions();

    -- Store in ModData so clients can receive them
    ModData.add(Respawn.GetModDataOptionsKey(), options);
    writeLog(Respawn.GetLogName(), "options added to ModData");
end

Events.OnInitGlobalModData.Add(AddOptionsToModData);