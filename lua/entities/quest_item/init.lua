AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()
	self:SetSolid(SOLID_VPHYSICS);
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
    
    local phy = self:GetPhysicsObject()
    if IsValid(phy) then
        phy:Wake()
    end
end

function ENT:Use(activator, caller, useType, value)
    local eQuest = self:GetQuestEntity()
    if useType == USE_ON and activator:IsPlayer() and activator == eQuest:GetPlayer() then
        local step = eQuest:GetQuestStep()
        local quest = eQuest:GetQuest()
        if quest.steps[step].onUseItem ~= nil then
            local func = quest.steps[step].onUseItem
            func(eQuest, self)
        end
    end
end