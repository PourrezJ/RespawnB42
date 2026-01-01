Respawn.DefaultOptions = {
    XPRestored = 21,
    ExcludeFitness = true,
    ExcludeStrength = true,
}

Respawn.Data.Options = Respawn.DefaultOptions;

if ModOptions and ModOptions.getInstance then
    local options = ModOptions:getInstance(Respawn.DefaultOptions, Respawn.Id, Respawn.Name);

    options.names = {
        XPRestored = "XP Restored",
        ExcludeFitness = "Exclude Fitness",
        ExcludeStrength = "Exclude Strength",
    }

    local xpRestoredDropdown = options:getData("XPRestored");
    xpRestoredDropdown[1] = "5%";
    xpRestoredDropdown[2] = "10%";
    xpRestoredDropdown[3] = "15%";
    xpRestoredDropdown[4] = "20%";
    xpRestoredDropdown[5] = "25%";
    xpRestoredDropdown[6] = "30%";
    xpRestoredDropdown[7] = "35%";
    xpRestoredDropdown[8] = "40%";
    xpRestoredDropdown[9] = "45%";
    xpRestoredDropdown[10] = "50%";
    xpRestoredDropdown[11] = "55%";
    xpRestoredDropdown[12] = "60%";
    xpRestoredDropdown[13] = "65%";
    xpRestoredDropdown[14] = "70%";
    xpRestoredDropdown[15] = "75%";
    xpRestoredDropdown[16] = "80%";
    xpRestoredDropdown[17] = "85%";
    xpRestoredDropdown[18] = "90%";
    xpRestoredDropdown[19] = "95%";
    xpRestoredDropdown[20] = "100%";
    xpRestoredDropdown[21] = "Last Level";

    local excludeFitness = options:getData("ExcludeFitness");
    excludeFitness.tooltip = "If enabled 100% of experience will be saved.";
    
    local excludeStrength = options:getData("ExcludeStrength");
    excludeStrength.tooltip = "If enabled 100% of experience will be saved.";
end