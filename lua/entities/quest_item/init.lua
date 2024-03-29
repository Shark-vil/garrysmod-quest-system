AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

ENT.ThinkDelay = 0
ENT.Phys = NULL

function ENT:Initialize()
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		self.Phys = phys
	end

	hook.Add('PhysgunPickup', self, function(this, ply, ent)
		if IsValid(self) and self == ent and self:GetNWBool('isFreezeItem') then return false end
	end)

	self.ThinkDelay = CurTime() + 1
end

function ENT:Use(activator, caller, useType, value)
	local eQuest = self:GetQuestEntity()

	if IsValid(eQuest) and useType == USE_ON and activator:IsPlayer() and eQuest:IsQuestPlayer(activator) then
		local step = eQuest:GetQuestStep()
		if not step then return end

		local quest = eQuest:GetQuest()
		if not quest or not quest.steps[step] then return end

		local func = quest.steps[step].onUseItem
		if not func or not isfunction(func) then return end

		snet.InvokeAll('QSystem.QuestAction.OnUseItem', self, activator, caller, useType, value)
		func(eQuest, self, activator, caller, useType, value)
	end
end

function ENT:SetFreeze(isFreeze)
	self:SetNWBool('isFreezeItem', isFreeze)
end

function ENT:Think()
	if self.ThinkDelay > CurTime() then return end

	if self:GetNWBool('isFreezeItem') then
		local phys = self.Phys

		if IsValid(phys) and phys:IsMotionEnabled() then
			phys:EnableMotion(false)
		end
	end
end