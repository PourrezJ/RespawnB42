local Original_Create = CharacterCreationProfession.create;
local Original_SetVisible = CharacterCreationProfession.setVisible;

-- The profession is created by the server in RespawnHost.lua
-- We just need to reference it here without creating a new one

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
        self:addRespawnProfession();
    end
end

function CharacterCreationProfession:addRespawnProfession()
    -- Find the profession created by the server
    local allProfs = CharacterProfessionDefinition.getProfessions();
    local respawnProf = nil;
    
    Respawn.DebugLog("Searching for profession in " .. tostring(allProfs:size()) .. " professions");
    
    for i = 0, allProfs:size() - 1 do
        local profDef = allProfs:get(i);
        local uiName = profDef:getUIName();
        local profType = profDef:getType();
        print("[Respawn] Profession #" .. tostring(i) .. " UIName: " .. tostring(uiName) .. ", Type: " .. tostring(profType));
        
        -- Match by profession type using toString() to check for "respawn:respawn"
        if profType and tostring(profType):lower():find("respawn") then
            respawnProf = profDef;
            print("[Respawn] Found profession definition: " .. tostring(profDef));
            break;
        end
    end
    
    if not respawnProf then
        print("[Respawn] ERROR: Could not find Respawn profession definition");
        return;
    end
    
    print("[Respawn] Adding profession to list");
    self.listboxProf:insertItem(0, Respawn.Id, respawnProf);
    self:onSelectProf(respawnProf);
end

function CharacterCreationProfession:removeRespawnProfession()
    self.listboxProf:removeItem(Respawn.Id);

    self.listboxProf.selected = 1;
    self:onSelectProf(self.listboxProf.items[1].item);
end