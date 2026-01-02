-- Ensure Respawn.Data exists before assigning to it
if not Respawn.Data then
    Respawn.Data = {};
end

-- Default options (used in solo, overridden by server in multiplayer)
-- The UI for these options is created in client/Respawn/RespawnModOptions.lua
Respawn.Data.Options = {
    XPRestored = 21, -- Default: "Last Level" (index 21)
    ExcludeFitness = true,
    ExcludeStrength = true,
}

print("[Respawn] Default options initialized")