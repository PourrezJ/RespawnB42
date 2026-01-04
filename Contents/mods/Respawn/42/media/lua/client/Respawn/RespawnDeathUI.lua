-- Hook ISPostDeathUI to add a "Respawn with Stats" button

require "ISUI/ISPanelJoypad"

Respawn.Log("RespawnDeathUI.lua loading...")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

-- Hook ISPostDeathUI to add button
local original_createChildren = ISPostDeathUI.createChildren

function ISPostDeathUI:createChildren()
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
    button:setVisible(false)
    self:addChild(button)
    self.buttonRespawnWithStats = button
    self.hasCheckedForSavedData = false
end

-- Show button if saved data exists
local original_prerender = ISPostDeathUI.prerender

function ISPostDeathUI:prerender()
    original_prerender(self)
    
    if self.buttonRespawnWithStats and not self.hasCheckedForSavedData and self.waitOver then
        self.hasCheckedForSavedData = true
        
        if not isClient() then
            local key = Respawn.GetModDataStatsKey()
            Respawn.Data.Stats = ModData.get(key)
        end
        
        local hasData = Respawn.Data.Stats and 
                        (Respawn.Data.Stats.Experience or 
                         Respawn.Data.Stats.Traits or 
                         Respawn.Data.Stats.Visual)
        
        if hasData then
            self.buttonRespawnWithStats:setVisible(true)
        end
    end
end

-- Button click handler
function ISPostDeathUI:onRespawnWithStats()
    if MainScreen.instance:isReallyVisible() then return end
    
    Respawn.PendingRestore = true
    setGameSpeed(1)
    self:setVisible(false)
    
    local joypadData = JoypadState.players[self.playerIndex+1]
    
    if not CoopMapSpawnSelect then
        require "OptionScreens/CoopMapSpawnSelect"
    end
    if not CoopCharacterCreation then
        require "OptionScreens/CoopCharacterCreation"
    end
    
    -- Hook to skip profession screen
    if not Respawn.OriginalCoopMapSpawnSelectClickNext then
        Respawn.OriginalCoopMapSpawnSelectClickNext = CoopMapSpawnSelect.clickNext
        
        function CoopMapSpawnSelect:clickNext()
            if Respawn.PendingRestore then
                self.selectedRegion = self.listbox.items[self.listbox.selected].item.region
                setSpawnRegion(self.selectedRegion.name)
                self:setVisible(false)
                
                if CoopCharacterCreation.instance then
                    CoopCharacterCreation.instance:accept()
                end
            else
                Respawn.OriginalCoopMapSpawnSelectClickNext(self)
            end
        end
    end
    
    -- Hook to restore appearance before player creation
    if not Respawn.OriginalCoopCharacterCreationAccept then
        Respawn.OriginalCoopCharacterCreationAccept = CoopCharacterCreation.accept
        
        function CoopCharacterCreation:accept()
            if Respawn.PendingRestore then
                if not Respawn.Data.Stats then
                    if isClient() then
                        Respawn.Sync.LoadRemote()
                    else
                        Respawn.Data.Stats = ModData.get(Respawn.GetModDataStatsKey()) or {}
                    end
                end
                
                -- Restore visual appearance and gender to descriptor
                if Respawn.Data.Stats.Visual and MainScreen.instance.desc then
                    local savedVisual = Respawn.Data.Stats.Visual
                    
                    if savedVisual.isFemale ~= nil then
                        MainScreen.instance.desc:setFemale(savedVisual.isFemale)
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
                end
            end
            
            return Respawn.OriginalCoopCharacterCreationAccept(self)
        end
    end
    
    if joypadData then
        CoopCharacterCreation.newPlayer(joypadData.id, joypadData)
    else
        CoopCharacterCreation:newPlayerMouse()
    end
end

-- Restore stats after player creation
local function OnCreatePlayer(playerIndex, player)
    if not Respawn.PendingRestore then return end
    
    Respawn.PendingRestore = false
    
    local tickHandler = nil
    tickHandler = function()
        if not player or player:isDead() then
            Events.OnTick.Remove(tickHandler)
            return
        end
        
        -- Restore character name
        if Respawn.Data.Stats.CharacterName then
            local descriptor = player:getDescriptor()
            if descriptor then
                descriptor:setForename(Respawn.Data.Stats.CharacterName.forename)
                descriptor:setSurname(Respawn.Data.Stats.CharacterName.surname)
            end
        end
        
        -- Restore visual appearance
        if Respawn.Data.Stats.Visual then
            local visual = player:getHumanVisual()
            if visual then
                local savedVisual = Respawn.Data.Stats.Visual
                
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
                
                player:resetModel()
                player:resetModelNextFrame()
            end
        end
        
        -- Restore XP
        if RecoverableExperience and Respawn.Data.Stats.Experience then
            RecoverableExperience:Load(player)
        end
        
        -- Restore traits and occupation
        if not isClient() then
            if Respawn.Data.Stats.Occupation then
                local descriptor = player:getDescriptor()
                if descriptor then
                    local profession = CharacterProfession.get(ResourceLocation.of(Respawn.Data.Stats.Occupation))
                    if profession then
                        descriptor:setCharacterProfession(profession)
                    end
                end
            end
            
            if RecoverableTraits and Respawn.Data.Stats.Traits then
                RecoverableTraits:Load(player)
            end
        else
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
        
        -- Give basic starting clothes
        local inventory = player:getInventory()
        if inventory then
            local tshirt = inventory:AddItem("Base.Tshirt_DefaultTEXTURE")
            local trousers = inventory:AddItem("Base.Trousers_DefaultTEXTURE")
            local shoes = inventory:AddItem("Base.Shoes_Black")
            local socks = inventory:AddItem("Base.Socks_Ankle")
            
            if tshirt then player:setWornItem(tshirt:getBodyLocation(), tshirt) end
            if trousers then player:setWornItem(trousers:getBodyLocation(), trousers) end
            if shoes then player:setWornItem(shoes:getBodyLocation(), shoes) end
            if socks then player:setWornItem(socks:getBodyLocation(), socks) end
        end
        
        Events.OnTick.Remove(tickHandler)
    end
    Events.OnTick.Add(tickHandler)
end

Events.OnCreatePlayer.Add(OnCreatePlayer)
