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
ENT.points = {}
ENT.npcs = {}
ENT.items = {}
ENT.weapons = {}
ENT.players = {}
ENT.values = {}
ENT.structures = {}

function ENT:Initialize()
    self:SetModel('models/props_junk/PopCan01a.mdl')
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNoDraw(true)

	if SERVER then
		local globalHookName = 'QuestEntity_' .. tostring(self:EntIndex()) .. tostring(CurTime())
		self:SetNWString('global_hook_name', globalHookName)

		if self:IsExistStepArg('onUse') then
			hook.Add("PlayerUse", globalHookName, function(ply, ent)
				if not IsValid(self) then hook.Remove("PlayerUse", globalHookName) return end
				
				local step = self:GetQuestStepTable()
				if step ~= nil and step.onUse ~= nil then
					if self:GetPlayer() == ply then
						step.onUse(self, ent)
					end
				end
			end)
		end

		if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then
			hook.Add('ShouldCollide', globalHookName, function(ent1, ent2)
				if not IsValid(self) then hook.Remove("ShouldCollide", globalHookName) return end

				local quest = self:GetQuest()
				if quest.isEvent then return end

				for id, spawn_id in pairs(self.structures) do
					local props = QuestSystem:GetStructure(spawn_id)
					if table.HasValue(props, ent1) and ent2 ~= self:GetPlayer() then
						return false
					end
				end
			end)

			hook.Add('EntityTakeDamage', globalHookName, function(target, dmginfo)
				if not IsValid(self) then hook.Remove("EntityTakeDamage", globalHookName) return end

				local quest = self:GetQuest()
				if quest.isEvent then return end

				for _, data in pairs(self.npcs) do
					local npc = data.npc
					local attaker = dmginfo:GetInflictor()
					if IsValid(npc) and IsValid(attaker) and attaker:IsPlayer() then
						if attaker == self:GetPlayer() then
							return true
						end
					end
				end
			end)
		end

		self:SetNWBool('StopThink', true)
		self:SetNWFloat('ThinkDelay', 0)
	end

	timer.Simple(1, function()
		if not IsValid(self) then return end

		local quest = self:GetQuest()
		if quest.isEvent then
			hook.Run('EnableEvent', self, quest)
		else
			hook.Run('EnableQuest', self, quest)
		end
	end)
end

function ENT:IsExistStepArg(arg)
	for step_name, step_data in pairs(self:GetQuest().steps) do
		if step_data[arg] ~= nil then return true end
	end
	return false
end

function ENT:GetQuest()
	self.quest = self.quest or QuestSystem:GetQuest(self:GetQuestId())
	return self.quest
end

function ENT:GetQuestStepTable()
	local quest = self:GetQuest()
	if quest == nil then return nil end

	local step = self:GetQuestStep()
	return quest.steps[step]
end

function ENT:GetQuestId()
	return self:GetNWString('quest_id')
end

function ENT:GetQuestStep()
	return self:GetNWString('step')
end

function ENT:GetQuestOldStep()
	return self:GetNWString('old_step')
end

function ENT:GetPlayer()
	return self.players[1]
end

function ENT:GetQuestFunction(id)
	local quest = self:GetQuest()
	if quest ~= nil and quest.functions ~= nil then
		return quest.functions[id]
	end
	return nil
end

function ENT:GetAllPlayers()
	return self.players
end

function ENT:AddPlayer(ply)
	if not table.HasValue(self.players, ply) then
		table.insert(self.players, ply)

		if SERVER then
			net.Start('cl_qsystem_add_player')
			net.WriteEntity(self)
			net.WriteEntity(ply)
			net.Broadcast()
		end
	end
end

function ENT:RemovePlayer(ply)
	if table.HasValue(self.players, ply) then
		table.RemoveByValue(self.players, ply)

		if SERVER then
			net.Start('cl_qsystem_remove_player')
			net.WriteEntity(self)
			net.WriteEntity(ply)
			net.Broadcast()
		end
	end
end

function ENT:Think()
	local step = self:GetQuestStepTable()

	if step ~= nil then
		if step.think ~= nil 
			and not self:GetNWBool('StopThink') 
			and self:GetNWFloat('ThinkDelay') < RealTime() 
		then
			step.think(self)
		end

		if #self.triggers ~= 0 and step.triggers ~= nil then
			for _, tdata in pairs(self.triggers) do
				local name = tdata.name
				local trigger = tdata.trigger

				if trigger.type == 'box' then
					local func = step.triggers[name]
					if func ~= nil then
						local entities = ents.FindInBox(trigger.vec1, trigger.vec2)
						func(self, entities)
					end
				elseif trigger.type == 'sphere' then
					local func = step.triggers[name]
					if func ~= nil then
						local entities = ents.FindInSphere(trigger.center, trigger.radius)
						func(self, entities)
					end
				end
			end
		end
	end
end

function ENT:RemoveNPC(isDisappear, type, tag)
	local function NpcRemove(npc, isDisappear)
		if CLIENT then return end

		if isDisappear then
			npc:SetRenderMode(RENDERMODE_TRANSCOLOR)
			hook.Add('Think', npc, function()
				if IsValid(npc) then
					npc.delayDisappear = npc.delayDisappear or CurTime() + 5
					
					if npc.delayDisappear < CurTime() then
						local color = npc:GetColor()
						local minus = 1
						if color.a - minus >= 0 then
							npc:SetColor(ColorAlpha(color, color.a - minus))
						else
							npc:Remove()
						end
					end
				end
			end)
		else
			npc:Remove()
		end
	end

	if #self.npcs ~= nil then
		if type ~= nil then
			local key_removes = {}

			for key, data in pairs(self.npcs) do
				if IsValid(data.npc) then
					if tag ~= nil then
						if type == data.type and tag == data.tag then
							NpcRemove(data.npc, isDisappear)
							table.insert(key_removes, key)
						end
					elseif type == data.type then
						NpcRemove(data.npc, isDisappear)
						table.insert(key_removes, key)
					end
				end
			end

			for _, key in pairs(key_removes) do
				table.remove(self.npcs, key)
			end
		else
			for _, data in pairs(self.npcs) do
				if IsValid(data.npc) then 
					NpcRemove(data.npc, isDisappear)
				end
			end
			table.Empty(self.npcs)
		end
	end
end

function ENT:RemoveItems(item_id)
	if #self.items ~= nil then
		if item_id ~= nil then
			for key, data in pairs(self.items) do
				if IsValid(data.item) and data.name == item_id then
					if SERVER then data.item:Remove() end
					table.remove(self.items, key)
					break;
				end
			end
		else
			for _, data in pairs(self.items) do
				if IsValid(data.item) then
					if SERVER then data.item:Remove() end
				end
			end
			table.Empty(self.items)
		end
	end
end

function ENT:OnRemove()
	local step = self:GetQuestStepTable()

	if step ~= nil then
		if step.destruct ~= nil then
			step.destruct(self)
		end
	end

	self:RemoveNPC()
	self:RemoveItems()
	if SERVER then
		self:RemoveAllQuestWeapon()
		self:RemoveAllStructure()
	end

	local globalHookName = self:GetNWString('global_hook_name')
	hook.Remove("PlayerUse", globalHookName)
	hook.Remove("ShouldCollide", globalHookName)
	hook.Remove("EntityTakeDamage", globalHookName)

	local quest = self:GetQuest()
	if quest.isEvent then
		hook.Run('DisableEvent', self, quest)
	else
		hook.Run('DisableQuest', self, quest)
	end
end

function ENT:OnNextStep(step)
	local quest = self:GetQuest()
	local step = self:GetQuestStep()
	local old_step = self:GetQuestOldStep()

	if #self.points ~= 0 then			
		if quest.steps[step].points ~= nil then
			for _, data in pairs(self.points) do
				local func = quest.steps[step].points[data.name]
				if func ~= nil then
					func(self, data.points)
				end
			end
		end
	end

	if old_step ~= nil and #old_step ~= 0 then
		if quest.steps[old_step].hooks ~= nil then
			for hook_type, _ in pairs(quest.steps[old_step].hooks) do
				hook.Remove(hook_type, self)
			end
		end
	end

	
	if SERVER then
		if table.Count(self.npcs) ~= 0 then
			local notReaction = quest.npcNotReactionOtherPlayer or false

			for _, ply in pairs(player.GetHumans()) do
				for _, data in pairs(self.npcs) do
					if IsValid(data.npc) then
						if table.HasValue(self.players, ply) then
							if data.type == 'enemy' then
								data.npc:AddEntityRelationship(ply, D_HT, 70)
							elseif data.type == 'friend' then
								data.npc:AddEntityRelationship(ply, D_LI, 70)
							end
						else
							if notReaction then
								data.npc:AddEntityRelationship(ply, D_NU, 99)
							end
						end
					end
				end
			end
		end

		if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') and not quest.isEvent then				
			timer.Simple(1, function()
				if IsValid(self) then
					if table.Count(self.npcs) ~= 0 then
						net.Start('cl_qsystem_nodraw_npc')
						net.WriteEntity(self)
						net.Broadcast()
					end

					if table.Count(self.items) ~= 0 then
						net.Start('cl_qsystem_nodraw_items')
						net.WriteEntity(self)
						net.Broadcast()
					end

					if table.Count(self.structures) ~= 0 then
						net.Start('cl_qsystem_nodraw_structures')
						net.WriteEntity(self)
						net.WriteTable(self.structures)
						net.Broadcast()
					end
				end
			end)
		end
	end

	if SERVER then
		self:SetNWBool('StopThink', false)
		self:SetNWFloat('ThinkDelay', RealTime() + 1)
	end

	if quest.steps[step].hooks ~= nil then
		for hook_type, func in pairs(quest.steps[step].hooks) do
			hook.Add(hook_type, self, func)
		end
	end

	if quest.isEvent then
		hook.Run('NewEventStep', self, step, quest)
	else
		hook.Run('NewQuestStep', self, step, quest)
	end
end

function ENT:Notify(title, desc, lifetime, image, bgcolor)
	self:GetPlayer():QuestNotify(title, desc, lifetime, image, bgcolor)
end

function ENT:NotifyOnlyRegistred(title, desc, lifetime, image, bgcolor)
	for _, ply in pairs(self.players) do
		ply:QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

function ENT:NotifyAll(title, desc, lifetime, image, bgcolor)
	for _, ply in pairs(player.GetHumans()) do
		ply:QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

function ENT:IsQuestNPC(npc, type, tag)
	for _, data in pairs(self.npcs) do
		if data.npc == npc then
			if type ~= nil and data.type ~= type then return false end
			if tag ~= nil and data.tag ~= tag then return false end
			return true
		end
	end
	return false
end

function ENT:GetQuestNpc(type, tag)
	if type ~= nil then
		if tag ~= nil then
			for _, data in pairs(self.npcs) do
				if data.type == type and data.tag == tag then
					return data.npc
				end
			end
		else
			local npcs = {}
			for _, data in pairs(self.npcs) do
				if data.type == type then
					table.insert(npcs, data.npc)
				end
			end
			return npcs
		end
	end
	return NULL
end

function ENT:IsQuestItem(item)
	for _, data in pairs(self.items) do
		if data.item == item then return true end
	end
	return false
end

function ENT:GetQuestItem(item_id)
	for _, data in pairs(self.items) do
		if data.id == item_id then
			return data.item
		end
	end
	return NULL
end

function ENT:AddQuestItem(item , item_id)

	if IsValid(item) and item:GetClass() == 'quest_item' then
		item:SetQuest(self)
		item:SetId(item_id)
	end

	table.insert(self.items, {
		id = item_id,
		item = item
	})

	local quest = self:GetQuest()
	if SERVER then
		if QuestSystem:GetConfig('DisableCollisionWithItems') then
			item:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
		end

		timer.Simple(1, function()
			if not IsValid(self) then return end

			net.Start('cl_qsystem_add_item')
			net.WriteEntity(self)
			net.WriteEntity(item)
			net.WriteString(item_id)
			net.Broadcast()
		end)
	end
end

function ENT:AddQuestNPC(npc, type, tag)
	tag = tag or 'none'
	
	table.insert(self.npcs, {
		type = type,
		tag = tag,
		npc = npc
	})

	local quest = self:GetQuest()
	if SERVER then
		if QuestSystem:GetConfig('DisableCollisionWithNPCs') then
			npc:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
		end

		timer.Simple(1, function()
			if not IsValid(self) then return end

			net.Start('cl_qsystem_add_npc')
			net.WriteEntity(self)
			net.WriteEntity(npc)
			net.WriteString(type)
			net.WriteString(tag)
			net.Broadcast()
		end)
	end
end

function ENT:DoorLocker(ent, lockState)
	lockState = lockState or 'lock'
	lockState = lockState:lower()
	local doors
	if istable(ent) then
		doors = ent
	else
		doors = { ent }
	end

	for _, door in pairs(doors) do
		if lockState == 'lock' and door.qsystemDoorIsLock ~= true 
			or lockState == 'unlock' and door.qsystemDoorIsLock ~= false
		then
			local doorsValidClass = {
				"func_door",
				"func_door_rotating",
				"prop_door_rotating",
				"func_movelinear",
				"prop_dynamic",
			}
		
			if table.HasValue(doorsValidClass, door:GetClass()) then
				door:Fire(lockState)
				print(lockState)
		
				if lockState == 'lock' then
					door.qsystemDoorIsLock = true
				else
					door.qsystemDoorIsLock = false
				end
			end
		end
	end
end

function ENT:SetStepValue(key, value)
	self.values[key] = value
	
	if SERVER then
		net.Start('qsystem_quest_entity_set_value')
		net.WriteEntity(self)
		net.WriteString(key)
		net.WriteType(value)
		net.Broadcast()
	end
end

function ENT:GetStepValue(key)
	return self.values[key]
end

function ENT:ResetStepValues()
	self.values = {}
	net.Start('qsystem_quest_entity_reset_values')
	net.WriteEntity(self)
	net.Broadcast()
end