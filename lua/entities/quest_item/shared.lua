ENT.Type = "anim"  
ENT.Base = "base_gmodentity"     
ENT.PrintName = "Quest Item"  
ENT.Author = ""  
ENT.Contact = ""  
ENT.Purpose	= ""  
ENT.Instructions = ""  

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.eQuest = nil

function ENT:SetQuest(eQuest)
    self.eQuest = eQuest
end

function ENT:SetId(itemId)
    self:SetNWString('item_id', itemId)
end

function ENT:GetQuestEntity()
    return self.eQuest
end

function ENT:GetItemId()
    return self:GetNWString('item_id')
end