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
    EnableDebug = false, -- Show debug messages in console
}

-- Debug logging function
function Respawn.DebugLog(message)
    if Respawn.Data.Options and Respawn.Data.Options.EnableDebug then
        print("[Respawn] " .. message)
    end
end

-- Always log important messages
function Respawn.Log(message)
    print("[Respawn] " .. message)
end

Respawn.Log("Default options initialized")