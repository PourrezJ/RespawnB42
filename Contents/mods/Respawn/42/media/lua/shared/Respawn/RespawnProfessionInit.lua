-- Build 42: Register profession and trait in shared context
-- This ensures they are available on both server and client

local function InitRespawnProfession()
    Respawn.Log("Registering profession and trait...");
    
    -- Register the trait first
    local trait = CharacterTrait.register(Respawn.FullId);
    if not trait then
        Respawn.Log("ERROR: Could not register trait");
        return;
    end
    
    -- Register the profession enum
    local prof = CharacterProfession.register(Respawn.FullId);
    if not prof then
        Respawn.Log("ERROR: Could not register profession enum");
        return;
    end
    
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
        Respawn.Log("Profession registered successfully");
    else
        Respawn.Log("ERROR: Could not create profession definition");
    end
end

-- Use OnGameBoot to ensure it runs early on both client and server
Events.OnGameBoot.Add(InitRespawnProfession);
