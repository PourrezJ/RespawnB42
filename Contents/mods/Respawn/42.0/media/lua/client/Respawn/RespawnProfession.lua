local Original_Create = CharacterCreationProfession.create;
local Original_SetVisible = CharacterCreationProfession.setVisible;
local Profession;

local function CreateRespawnProfession()
    -- Build 42: Create profession dynamically without script files
    -- Since we can't use script files (profession would always be visible),
    -- we create a minimal profession object that we'll manually add to the list
    
    -- First get or create the CharacterProfession enum value
    local prof = CharacterProfession.register(Respawn.FullId);
    if not prof then
        print("[Respawn] ERROR: Could not register CharacterProfession enum");
        return nil;
    end
    
    -- Now create a profession definition
    local profDef = CharacterProfessionDefinition.addCharacterProfessionDefinition(
        prof,
        "Respawn",
        0,
        "Respawn character",
        "profession_unemployed"
    );
    
    if not profDef then
        print("[Respawn] ERROR: Could not create profession definition");
        return nil;
    end
    
    -- Add the respawn trait to this profession
    -- IMPORTANT: Use the CharacterTrait object, not the string ID
    if Respawn.Trait then
        print("[Respawn] Adding trait to profession: " .. tostring(Respawn.Trait));
        profDef:getGrantedTraits():add(Respawn.Trait);
        print("[Respawn] Granted traits count: " .. profDef:getGrantedTraits():size());
    else
        print("[Respawn] WARNING: Respawn.Trait is nil, trait not added to profession!");
    end
    
    print("[Respawn] Successfully created profession: " .. tostring(Respawn.FullId));
    return profDef;
end

local function GetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath);

    return available and available[Respawn.GetUserID()];
end

function CharacterCreationProfession:create()
    Original_Create(self);
    -- Don't create the profession here - only create it when player is dead and can respawn
end

function CharacterCreationProfession:setVisible(visible, joypadData)
    Original_SetVisible(self, visible, joypadData);

    if not visible then
        return;
    end

    self:removeRespawnProfession();

    if GetRespawnAvailable() then
        writeLog(Respawn.GetLogName(), "respawn available!");
        
        -- Create the profession only when respawn is available (player is dead)
        if not Profession then
            Profession = CreateRespawnProfession();
        end
        
        self:addRespawnProfession();
    end
end

function CharacterCreationProfession:addRespawnProfession()
    if not Profession then
        print("[Respawn] ERROR: Respawn profession is nil! Cannot add to profession list.");
        return;
    end
    
    self.listboxProf:insertItem(0, Respawn.Id, Profession);
    self:onSelectProf(Profession);
end

function CharacterCreationProfession:removeRespawnProfession()
    self.listboxProf:removeItem(Respawn.Id);

    self.listboxProf.selected = 1;
    self:onSelectProf(self.listboxProf.items[1].item);
end