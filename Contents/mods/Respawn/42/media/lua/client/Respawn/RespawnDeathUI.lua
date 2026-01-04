-- Hook ISPostDeathUI to add a "Respawn with Stats" button
-- Uses the spawn point selection screen then directly creates the player

require "ISUI/ISPanelJoypad"

Respawn.Log("RespawnDeathUI.lua loading - installing hooks...")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

-- Hook immediately when file loads
local original_createChildren = ISPostDeathUI.createChildren

function ISPostDeathUI:createChildren()
    Respawn.Log("ISPostDeathUI:createChildren called")
    
    -- Call original to create the 3 default buttons
    original_createChildren(self)
    
    -- Calculate button dimensions
    local buttonWid = UI_BORDER_SPACING * 2 + math.max(
        getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PostDeath_Respawn")),
        getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PostDeath_Exit")),
        getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PostDeath_Quit")),
        getTextManager():MeasureStringX(UIFont.Small, "Respawn (Keep Stats)")
    )
    
    local buttonHgt = BUTTON_HGT
    local buttonGapY = UI_BORDER_SPACING
    
    -- Adjust height to fit 4 buttons instead of 3
    local totalHgt = (buttonHgt * 4) + (buttonGapY * 3)
    self:setWidth(buttonWid)
    self:setHeight(totalHgt)
    
    -- Reposition to center
    self:setX(self.screenX + (self.screenWidth - buttonWid) / 2)
    self:setY(self.screenY + (self.screenHeight - 40 - totalHgt))
    
    -- Shift existing buttons down
    local shift = buttonHgt + buttonGapY
    self.buttonRespawn:setY(self.buttonRespawn:getY() + shift)
    self.buttonExit:setY(self.buttonExit:getY() + shift)
    self.buttonQuit:setY(self.buttonQuit:getY() + shift)
    
    -- Add our new "Respawn with stats" button at the top (hidden by default)
    local button = ISButton:new(0, 0, buttonWid, buttonHgt,
        "Respawn (Keep Stats)", self, self.onRespawnWithStats)
    self:configButton(button)
    button:setVisible(false) -- Hidden until we verify saved data exists
    self:addChild(button)
    self.buttonRespawnWithStats = button
    self.hasCheckedForSavedData = false -- Flag to check only once
    
    Respawn.Log("Respawn button created (will check for saved data in prerender)")
end

-- Override prerender to show/hide our button based on saved data
local original_prerender = ISPostDeathUI.prerender

function ISPostDeathUI:prerender()
    original_prerender(self)
    
    -- Check for saved data once after OnPlayerDeath has fired
    if self.buttonRespawnWithStats and not self.hasCheckedForSavedData and self.waitOver then
        self.hasCheckedForSavedData = true
        
        -- Load saved stats from ModData
        if not isClient() then
            local key = Respawn.GetModDataStatsKey()
            Respawn.Data.Stats = ModData.get(key)
            Respawn.Log("Checked for saved data, key: " .. tostring(key) .. " = " .. tostring(Respawn.Data.Stats ~= nil))
        end
        
        -- Check if we have saved data
        local hasData = Respawn.Data.Stats and 
                        (Respawn.Data.Stats.Experience or 
                         Respawn.Data.Stats.Traits or 
                         Respawn.Data.Stats.Occupation or
                         Respawn.Data.Stats.Boosts or
                         Respawn.Data.Stats.Visual)
        
        if hasData then
            Respawn.Log("Saved data found - showing Respawn button")
            self.buttonRespawnWithStats:setVisible(true)
        else
            Respawn.Log("No saved data found - Respawn button stays hidden")
        end
    end
end

-- Handler for our new respawn button
function ISPostDeathUI:onRespawnWithStats()
    if MainScreen.instance:isReallyVisible() then return end
    
    Respawn.Log("Player clicked Respawn (Keep Stats) - opening spawn selection screen...")
    
    -- Set flag to restore stats after spawn point is chosen
    Respawn.PendingRestore = true
    
    setGameSpeed(1)
    self:setVisible(false)
    
    -- Use CoopMapSpawnSelect like vanilla respawn does
    local joypadData = JoypadState.players[self.playerIndex+1]
    
    -- Load CoopMapSpawnSelect if not already loaded
    if not CoopMapSpawnSelect then
        require "OptionScreens/CoopMapSpawnSelect"
    end
    if not CoopCharacterCreation then
        require "OptionScreens/CoopCharacterCreation"
    end
    
    -- Hook CoopMapSpawnSelect.clickNext to skip profession/trait screens
    if not Respawn.OriginalCoopMapSpawnSelectClickNext then
        Respawn.OriginalCoopMapSpawnSelectClickNext = CoopMapSpawnSelect.clickNext
        
        function CoopMapSpawnSelect:clickNext()
            -- Check if we're in "restore stats" mode
            if Respawn.PendingRestore then
                Respawn.Log("Spawn point selected - skipping profession screen and calling accept()...")
                
                -- Save selected spawn region (like vanilla clickNext)
                self.selectedRegion = self.listbox.items[self.listbox.selected].item.region
                setSpawnRegion(self.selectedRegion.name)
                self:setVisible(false)
                
                -- Instead of showing charCreationProfession, call accept() directly
                if CoopCharacterCreation.instance then
                    CoopCharacterCreation.instance:accept()
                end
            else
                -- Normal flow - call original
                Respawn.OriginalCoopMapSpawnSelectClickNext(self)
            end
        end
    end
    
    -- Hook CoopCharacterCreation.accept to restore stats before player creation
    if not Respawn.OriginalCoopCharacterCreationAccept then
        Respawn.OriginalCoopCharacterCreationAccept = CoopCharacterCreation.accept
        
        function CoopCharacterCreation:accept()
            -- Check if we're in "restore stats" mode
            if Respawn.PendingRestore then
                Respawn.Log("Preparing to restore stats after player creation...")
                
                -- Load saved stats from ModData
                if not Respawn.Data.Stats then
                    if isClient() then
                        Respawn.Sync.LoadRemote()
                    else
                        Respawn.Data.Stats = ModData.get(Respawn.GetModDataStatsKey()) or {}
                    end
                end
                
                -- Restore visual appearance to the descriptor
                if Respawn.Data.Stats.Visual and MainScreen.instance.desc then
                    local savedVisual = Respawn.Data.Stats.Visual
                    
                    -- Restore gender first
                    if savedVisual.isFemale ~= nil then
                        MainScreen.instance.desc:setFemale(savedVisual.isFemale)
                        Respawn.Log("Gender restored: " .. (savedVisual.isFemale and "Female" or "Male"))
                    end
                    
                    local visual = MainScreen.instance.desc:getHumanVisual()
                    
                    if savedVisual.hairModel then
                        visual:setHairModel(savedVisual.hairModel)
                    end
                    if savedVisual.beardModel then
                        visual:setBeardModel(savedVisual.beardModel)
                    end
                    if savedVisual.bodyHairIndex then
                        visual:setBodyHairIndex(savedVisual.bodyHairIndex)
                    end
                    if savedVisual.skinTextureIndex then
                        visual:setSkinTextureIndex(savedVisual.skinTextureIndex)
                    end
                    
                    -- Restore hair color
                    if savedVisual.hairColor then
                        local color = ImmutableColor.new(
                            savedVisual.hairColor.r,
                            savedVisual.hairColor.g,
                            savedVisual.hairColor.b,
                            1
                        )
                        visual:setNaturalHairColor(color)
                        visual:setHairColor(color)
                    end
                    
                    -- Restore beard color
                    if savedVisual.beardColor then
                        local color = ImmutableColor.new(
                            savedVisual.beardColor.r,
                            savedVisual.beardColor.g,
                            savedVisual.beardColor.b,
                            1
                        )
                        visual:setNaturalBeardColor(color)
                        visual:setBeardColor(color)
                    end
                    
                    Respawn.Log("Visual appearance restored to descriptor")
                end
            end
            
            -- Call original accept() - it handles everything else
            return Respawn.OriginalCoopCharacterCreationAccept(self)
        end
    end
    
    -- Show spawn point selection screen
    if joypadData then
        CoopCharacterCreation.newPlayer(joypadData.id, joypadData)
    else
        CoopCharacterCreation:newPlayerMouse()
    end
end

Respawn.Log("ISPostDeathUI hooks installed successfully")

-- Apply remaining restoration after the new character is created
local function OnCreatePlayer(playerIndex, player)
    if not Respawn.PendingRestore then
        return
    end
    
    Respawn.Log("New character created - applying stat restoration...")
    Respawn.PendingRestore = false
    
    -- Wait a tick for player to be fully initialized
    local tickHandler = nil
    tickHandler = function()
        if not player or player:isDead() then
            Events.OnTick.Remove(tickHandler)
            return
        end
        
        Respawn.Log("Restoring XP, traits, recipes, and boosts...")
        
        -- Restore character name
        if Respawn.Data.Stats.CharacterName then
            local descriptor = player:getDescriptor()
            if descriptor then
                descriptor:setForename(Respawn.Data.Stats.CharacterName.forename)
                descriptor:setSurname(Respawn.Data.Stats.CharacterName.surname)
                Respawn.Log("Character name restored: " .. tostring(Respawn.Data.Stats.CharacterName.forename) .. " " .. tostring(Respawn.Data.Stats.CharacterName.surname))
            end
        end
        
        -- Restore visual appearance directly to the player
        if Respawn.Data.Stats.Visual then
            local visual = player:getHumanVisual()
            if visual then
                local savedVisual = Respawn.Data.Stats.Visual
                
                Respawn.Log("Restoring visual data - Hair: " .. tostring(savedVisual.hairModel) .. 
                            ", Beard: " .. tostring(savedVisual.beardModel) ..
                            ", BodyHair: " .. tostring(savedVisual.bodyHairIndex) ..
                            ", SkinTexture: " .. tostring(savedVisual.skinTextureIndex))
                
                if savedVisual.hairModel then
                    visual:setHairModel(savedVisual.hairModel)
                    Respawn.Log("Set hair model: " .. tostring(savedVisual.hairModel))
                end
                if savedVisual.beardModel then
                    visual:setBeardModel(savedVisual.beardModel)
                    Respawn.Log("Set beard model: " .. tostring(savedVisual.beardModel))
                end
                if savedVisual.bodyHairIndex then
                    visual:setBodyHairIndex(savedVisual.bodyHairIndex)
                    Respawn.Log("Set body hair index: " .. tostring(savedVisual.bodyHairIndex))
                end
                if savedVisual.skinTextureIndex then
                    visual:setSkinTextureIndex(savedVisual.skinTextureIndex)
                    Respawn.Log("Set skin texture: " .. tostring(savedVisual.skinTextureIndex))
                end
                
                -- Restore hair color
                if savedVisual.hairColor then
                    local color = ImmutableColor.new(
                        savedVisual.hairColor.r,
                        savedVisual.hairColor.g,
                        savedVisual.hairColor.b,
                        1
                    )
                    visual:setNaturalHairColor(color)
                    visual:setHairColor(color)
                end
                
                -- Restore beard color
                if savedVisual.beardColor then
                    local color = ImmutableColor.new(
                        savedVisual.beardColor.r,
                        savedVisual.beardColor.g,
                        savedVisual.beardColor.b,
                        1
                    )
                    visual:setNaturalBeardColor(color)
                    visual:setBeardColor(color)
                end
                
                -- Force the player model to refresh with new visual data
                player:resetModel()
                player:resetModelNextFrame()
                
                Respawn.Log("Visual appearance restored to player and model reset")
            end
        end
        
        -- Restore XP
        if RecoverableExperience and Respawn.Data.Stats.Experience then
            RecoverableExperience:Load(player)
        end
        
        -- Restore traits and occupation
        if not isClient() then
            -- Solo mode: apply directly
            if Respawn.Data.Stats.Occupation then
                local descriptor = player:getDescriptor()
                if descriptor then
                    descriptor:setCharacterProfession(Respawn.Data.Stats.Occupation)
                    Respawn.Log("Restored occupation: " .. tostring(Respawn.Data.Stats.Occupation))
                end
            end
            
            if RecoverableTraits and Respawn.Data.Stats.Traits then
                RecoverableTraits:Load(player)
            end
        else
            -- Multiplayer: send to server
            if Respawn.Data.Stats.Traits then
                sendClientCommand('respawn', 'applyTraits', { traits = Respawn.Data.Stats.Traits })
            end
        end
        
        -- Restore recipes
        if RecoverableRecipes and Respawn.Data.Stats.Recipes then
            RecoverableRecipes:Load(player)
        end
        
        -- Restore boosts
        if RecoverableBoosts and Respawn.Data.Stats.Boosts then
            RecoverableBoosts:Load(player)
        end
        
        -- Give basic starting clothes (non-cheaty)
        local inventory = player:getInventory()
        if inventory then
            -- Use the default clothing definitions from vanilla
            -- These are XML clothing files, not item types
            local tshirt = inventory:AddItem("Base.Tshirt_DefaultTEXTURE")
            local trousers = inventory:AddItem("Base.Trousers_DefaultTEXTURE")
            local shoes = inventory:AddItem("Base.Shoes_Black")
            local socks = inventory:AddItem("Base.Socks_Ankle")
            
            -- Equip the basic clothes
            if tshirt then 
                player:setWornItem(tshirt:getBodyLocation(), tshirt)
                Respawn.Log("Equipped tshirt: " .. tshirt:getType())
            else
                Respawn.Log("Failed to add tshirt")
            end
            
            if trousers then 
                player:setWornItem(trousers:getBodyLocation(), trousers)
                Respawn.Log("Equipped trousers: " .. trousers:getType())
            else
                Respawn.Log("Failed to add trousers")
            end
            
            if shoes then 
                player:setWornItem(shoes:getBodyLocation(), shoes)
                Respawn.Log("Equipped shoes: " .. shoes:getType())
            else
                Respawn.Log("Failed to add shoes")
            end
            
            if socks then 
                player:setWornItem(socks:getBodyLocation(), socks)
                Respawn.Log("Equipped socks: " .. socks:getType())
            else
                Respawn.Log("Failed to add socks")
            end
            
            Respawn.Log("Basic starting clothes equipped")
        end
        
        Respawn.Log("All stats restored successfully!")
        
        -- Remove this tick handler
        Events.OnTick.Remove(tickHandler)
    end
    Events.OnTick.Add(tickHandler)
end

Events.OnCreatePlayer.Add(OnCreatePlayer)
