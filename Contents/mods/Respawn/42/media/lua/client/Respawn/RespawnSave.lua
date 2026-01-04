local function SetRespawnAvailable()
    local available = Respawn.File.Load(Respawn.AvailablePath) or {};
    available[Respawn.GetUserID()] = true;

    Respawn.File.Save(Respawn.AvailablePath, available);
end

local function SavePlayer(player)
    Respawn.Data.Stats = {};
    ModData.add(Respawn.GetModDataStatsKey(), Respawn.Data.Stats);
    
    -- Save character name and visual appearance
    local descriptor = player:getDescriptor()
    if descriptor then
        Respawn.Data.Stats.CharacterName = {
            forename = descriptor:getForename(),
            surname = descriptor:getSurname()
        }
    end
    
    local visual = player:getHumanVisual()
    if visual then
        Respawn.Data.Stats.Visual = {
            bodyHairIndex = visual:getBodyHairIndex(),
            hairModel = visual:getHairModel(),
            beardModel = visual:getBeardModel(),
            skinTextureIndex = visual:getSkinTextureIndex(),
            isFemale = player:isFemale()
        }
        
        local hairColor = visual:getNaturalHairColor()
        if hairColor then
            Respawn.Data.Stats.Visual.hairColor = {
                r = hairColor:getRedFloat(), 
                g = hairColor:getGreenFloat(), 
                b = hairColor:getBlueFloat()
            }
        end
        
        local beardColor = visual:getNaturalBeardColor()
        if beardColor then
            Respawn.Data.Stats.Visual.beardColor = {
                r = beardColor:getRedFloat(), 
                g = beardColor:getGreenFloat(), 
                b = beardColor:getBlueFloat()
            }
        end
    end
    
    -- Save stats via recoverable modules
    for i, recoverable in ipairs(Respawn.Recoverables) do
        recoverable:Save(player);
    end

    if isClient() then
        Respawn.Sync.SaveRemote();
    end

    SetRespawnAvailable();
end

Events.OnPlayerDeath.Add(SavePlayer);