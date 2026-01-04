-- Build 42 ModOptions using PZAPI (client-side only)
-- This file creates the options UI in OPTIONS > MODS > Respawn Mod

if not PZAPI or not PZAPI.ModOptions then
    print("[Respawn] ERROR: PZAPI.ModOptions not available!")
    return
end

local modOptions = PZAPI.ModOptions:create("respawn_options", "Respawn Mod")

-- In multiplayer, only show a message explaining that server controls options
if isClient() then
    modOptions:addTitle("In multiplayer mode, the server")
    modOptions:addTitle("controls all Respawn mod options.")
    modOptions:addSeparator()
    modOptions:addDescription("The server administrator can edit options in:")
    modOptions:addDescription("Zomboid/Lua/respawn-options.json")
    
    return -- Don't create the actual option controls
end

modOptions:addTitle("Experience Restoration")

-- XP Restored combobox
local XP_RESTORE_OPTIONS = {
    "5%", "10%", "15%", "20%", "25%",
    "30%", "35%", "40%", "45%", "50%",
    "55%", "60%", "65%", "70%", "75%",
    "80%", "85%", "90%", "95%", "100%",
    "Last Level"
}

local xpRestoredCombo = modOptions:addComboBox("XPRestored", "XP Restored")
for i, option in ipairs(XP_RESTORE_OPTIONS) do
    xpRestoredCombo:addItem(option, i == 21) -- Default: "Last Level" (index 21)
end

modOptions:addSeparator()

-- Always restore Fitness at 100%
modOptions:addTickBox(
    "ExcludeFitness",
    "Always Restore Fitness at 100%",
    true,
    "When enabled, Fitness XP is always fully restored (100%) regardless of the XP Restored percentage."
)

-- Always restore Strength at 100%
modOptions:addTickBox(
    "ExcludeStrength",
    "Always Restore Strength at 100%",
    true,
    "When enabled, Strength XP is always fully restored (100%) regardless of the XP Restored percentage."
)

modOptions:addSeparator()
modOptions:addTitle("Debug")

-- Enable Debug tickbox
modOptions:addTickBox(
    "EnableDebug",
    "Enable Debug Logging",
    false,
    "Show detailed debug messages in console.txt for troubleshooting."
)

-- Apply function - called by PZAPI when options change
modOptions.apply = function(self)
    -- In multiplayer, options come from server, don't override
    if isClient() then
        return
    end
    
    -- Solo mode: use local settings
    Respawn.Data.Options.XPRestored = self:getOption("XPRestored"):getValue()
    Respawn.Data.Options.ExcludeFitness = self:getOption("ExcludeFitness"):getValue()
    Respawn.Data.Options.ExcludeStrength = self:getOption("ExcludeStrength"):getValue()
    Respawn.Data.Options.EnableDebug = self:getOption("EnableDebug"):getValue()
    
    Respawn.Log("Solo options updated:")
    Respawn.Log("  XPRestored: " .. tostring(Respawn.Data.Options.XPRestored))
    Respawn.Log("  ExcludeFitness: " .. tostring(Respawn.Data.Options.ExcludeFitness))
    Respawn.Log("  ExcludeStrength: " .. tostring(Respawn.Data.Options.ExcludeStrength))
    Respawn.Log("  EnableDebug: " .. tostring(Respawn.Data.Options.EnableDebug))
end

-- PZAPI automatically calls apply() when options change and when the mod options screen is opened
-- We just need to call it once at startup to load saved options
modOptions:apply()