function CharacterCreationProfession:resetBuild()
    local index = self:getUnemployedProfessionIndex();

    if index > #self.listboxProf.items then
        Respawn.Log("ERROR: Unemployed profession not found!");
        return;
    end

    self.listboxProf.selected = index;
    self:onSelectProf(self.listboxProf.items[self.listboxProf.selected].item);

    while #self.listboxTraitSelected.items > 0 do
        self.listboxTraitSelected.selected = 1;
        self:onOptionMouseDown(self.removeTraitBtn);
    end
end

function CharacterCreationProfession:resetTraits()
    local index = self:getUnemployedProfessionIndex();
    
    if index > #self.listboxProf.items then
        Respawn.Log("ERROR: Unemployed profession not found!");
        return;
    end

    self:onSelectProf(self.listboxProf.items[index].item);

	while #self.listboxTraitSelected.items > 0 do
		self.listboxTraitSelected.selected = 1;
		self:onOptionMouseDown(self.removeTraitBtn);
	end

	self:onSelectProf(self.listboxProf.items[self.listboxProf.selected].item);
end

function CharacterCreationProfession:getUnemployedProfessionIndex()
    local index = 1;

    while index <= #self.listboxProf.items and self.listboxProf.items[index].item:getType() ~= "unemployed" do
        index = index + 1;
    end

    return index;
end