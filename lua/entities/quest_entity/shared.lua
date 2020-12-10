ENT.Type = "anim"  
ENT.Base = "base_gmodentity"     
ENT.PrintName = "Quest Entity"  
ENT.Author = ""  
ENT.Contact = ""  
ENT.Purpose	= ""  
ENT.Instructions = ""  

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.triggers = {}
ENT.npcs = {}

function ENT:Initialize()
    self:SetModel('models/props_junk/PopCan01a.mdl')
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNoDraw(true)

	hook.Run('EnableQuest', self)
end

function ENT:GetQuest()
    self.quest = self.quest or QuestSystem:GetQuest(self:GetQuestId())
	return self.quest
end

function ENT:GetQuestId()
	return self:GetNWString('quest_id')
end

function ENT:GetQuestStep()
	return self:GetNWString('step')
end

function ENT:GetPlayer()
	return self:GetNWEntity('player')
end

function ENT:Think()
	local quest = self:GetQuest()
	local step = self:GetQuestStep()

	if quest ~= nil and quest.steps[step] ~= nil then
		if quest.steps[step].think ~= nil then
			quest.steps[step].think(self)
		end

		if #self.triggers ~= 0 then
			for _, tdata in pairs(self.triggers) do
				local name = tdata.name
				local trigger = tdata.trigger

				if trigger.type == 'box' then
					local entities = ents.FindInBox(trigger.vec1, trigger.vec2)
					local func = quest.steps[step].triggers[name]
					func(self, entities)
				elseif trigger.type == 'sphere' then
					local entities = ents.FindInSphere(trigger.center, trigger.radius)
					local func = quest.steps[step].triggers[name]
					func(self, entities)
				end
			end
		end
	end
end

function ENT:OnRemove()
	local quest = self:GetQuest()
	local step = self:GetQuestStep()

	if quest ~= nil and quest.steps[step] ~= nil then
		if quest.steps[step].destruct ~= nil then
			quest.steps[step].destruct(self)
		end
	end

	for _, data in pairs(self.npcs) do
		if IsValid(data.npc) then 
			data.npc:Remove()
		end
	end

	hook.Run('DisableQuest', self)
end

function ENT:OnNextStep(step)
	if #self.npcs == 0 then return end

	if SERVER then
		local quester = self:GetPlayer()
		for _, ply in pairs(player.GetHumans()) do
			for _, data in pairs(self.npcs) do
				if quester == ply then
					if data.type == 'enemy' then
						data.npc:AddEntityRelationship(quester, D_HT, 99)
					elseif data.type == 'friend' then
						data.npc:AddEntityRelationship(quester, D_LI, 80)
					end
				else
					data.npc:AddEntityRelationship(ply, D_NU, 99)
				end
			end
		end
	end
end

function ENT:AddQuestNPC(npc, type, tag)
	table.insert(self.npcs, {
		type = type,
		tag = tag,
		npc = npc
	})
end