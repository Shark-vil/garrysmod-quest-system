ENT.Type = 'anim'
ENT.Base = 'base_gmodentity'
ENT.PrintName = 'Quest Item'
ENT.Author = ''
ENT.Contact = ''
ENT.Purpose = ''
ENT.Instructions = ''
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.eQuest = nil

function ENT:SetQuest(eQuest)
	self:SetNWEntity('quest_entity', eQuest)
end

function ENT:SetId(itemId)
	self:slibSetVar('item_id', itemId)
end

function ENT:GetQuestEntity()
	return self:GetNWEntity('quest_entity')
end

function ENT:GetItemId()
	return self:slibGetVar('item_id')
end