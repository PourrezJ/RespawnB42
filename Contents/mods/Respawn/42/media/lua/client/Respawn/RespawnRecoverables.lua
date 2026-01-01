Respawn.Recoverables = {};

local function AddRecoverable(recoverable)
    table.insert(Respawn.Recoverables, recoverable);
end

AddRecoverable(RecoverableBoosts);
AddRecoverable(RecoverableExperience);
AddRecoverable(RecoverableTraits);
AddRecoverable(RecoverableRecipes);
AddRecoverable(RecoverableOccupation);
AddRecoverable(RecoverableWeight);