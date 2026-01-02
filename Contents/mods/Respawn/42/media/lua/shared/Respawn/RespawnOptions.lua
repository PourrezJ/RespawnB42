-- Ensure Respawn.Data exists before assigning to it
if not Respawn.Data then
    Respawn.Data = {};
end

-- Default options
Respawn.Data.Options = {
    XPRestored = 21, -- Default: "Last Level" (index 21)
    ExcludeFitness = true,
    ExcludeStrength = true,
}

-- Build 42 ModOptions using PZAPI
if PZAPI and PZAPI.ModOptions then
    -- Create mod options section
    local modOptions = PZAPI.ModOptions:create("respawn_options", "Respawn Mod")
    
    -- Add title
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
    
    -- Exclude Fitness tickbox
    modOptions:addTickBox(
        "ExcludeFitness",
        "Exclude Fitness",
        true,
        "If enabled, Fitness XP will be restored at 100% regardless of the XP Restored setting."
    )
    
    -- Exclude Strength tickbox
    modOptions:addTickBox(
        "ExcludeStrength",
        "Exclude Strength",
        true,
        "If enabled, Strength XP will be restored at 100% regardless of the XP Restored setting."
    )
    
    -- Apply function to update Respawn.Data.Options when settings change
    modOptions.apply = function(self)
        Respawn.Data.Options.XPRestored = self:getOption("XPRestored"):getValue()
        Respawn.Data.Options.ExcludeFitness = self:getOption("ExcludeFitness"):getValue()
        Respawn.Data.Options.ExcludeStrength = self:getOption("ExcludeStrength"):getValue()
        
        print("[Respawn] Options updated:")
        print("  XPRestored: " .. tostring(Respawn.Data.Options.XPRestored))
        print("  ExcludeFitness: " .. tostring(Respawn.Data.Options.ExcludeFitness))
        print("  ExcludeStrength: " .. tostring(Respawn.Data.Options.ExcludeStrength))
    end
    
    -- Initialize options on main menu
    Events.OnMainMenuEnter.Add(function()
        modOptions:apply()
    end)
end