local function SetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    Respawn.Log("Saving character stats (OnPlayerDeath)");
    
    Respawn.Data.Stats = {};
    ModData.add(Respawn.GetModDataStatsKey(), Respawn.Data.Stats);
    
    -- Save visual appearance and name
    local descriptor = player:getDescriptor()
    if descriptor then
        -- Save character name
        Respawn.Data.Stats.CharacterName = {
            forename = descriptor:getForename(),
            surname = descriptor:getSurname()
        }
        Respawn.Log("Saved character name: " .. tostring(descriptor:getForename()) .. " " .. tostring(descriptor:getSurname()))
    end
    
    -- Save visual appearance directly from player
    local visual = player:getHumanVisual()
    if visual then
        Respawn.Data.Stats.Visual = {
            bodyHairIndex = visual:getBodyHairIndex(),
            hairModel = visual:getHairModel(),
            beardModel = visual:getBeardModel(),
            skinTextureIndex = visual:getSkinTextureIndex(),
            isFemale = player:isFemale()
        }
        
        Respawn.Log("Saved visual data - Hair: " .. tostring(Respawn.Data.Stats.Visual.hairModel) .. 
                    ", Beard: " .. tostring(Respawn.Data.Stats.Visual.beardModel) ..
                    ", BodyHair: " .. tostring(Respawn.Data.Stats.Visual.bodyHairIndex) ..
                    ", SkinTexture: " .. tostring(Respawn.Data.Stats.Visual.skinTextureIndex))
        
        -- Save hair color if exists
        local hairColor = visual:getNaturalHairColor()
        if hairColor then
            Respawn.Data.Stats.Visual.hairColor = {
                r = hairColor:getRedFloat(), 
                g = hairColor:getGreenFloat(), 
                b = hairColor:getBlueFloat()
            }
        end
        
        -- Save beard color if exists
        local beardColor = visual:getNaturalBeardColor()
        if beardColor then
            Respawn.Data.Stats.Visual.beardColor = {
                r = beardColor:getRedFloat(), 
                g = beardColor:getGreenFloat(), 
                b = beardColor:getBlueFloat()
            }
        end
        
        Respawn.Log("Saved visual appearance")
    else
        Respawn.Log("ERROR: Could not get player HumanVisual")
    end
    
    for i, recoverable in ipairs(Respawn.Recoverables) do
        Respawn.DebugLog("Saving recoverable: " .. tostring(recoverable));
        recoverable:Save(player);
    end

    Respawn.DebugLog("Save complete");
    
    if isClient() then
        Respawn.Sync.SaveRemote();
    end

    SetRespawnAvailable();
    Respawn.Log("Character stats saved successfully");
end

Events.OnPlayerDeath.Add(SavePlayer);