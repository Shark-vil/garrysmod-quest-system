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
		local globalHookName = 'QuestEntity_' 
			.. tostring(self:EntIndex()) 
			.. tostring(string.Replace(CurTime(), '.', ''))

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

				if ent2:IsPlayer() then
					local quest = self:GetQuest()

					for id, spawn_id in pairs(self.structures) do
						local props = QuestSystem:GetStructure(spawn_id)
						if table.HasValue(props, ent1) and not table.HasValue(self.players, ent2) then
							return false
						end
					end

					for _, data in pairs(self.items) do
						local item = data.item
						if IsValid(item) and item:GetCustomCollisionCheck() then
							if ent1 == item and not table.HasValue(self.players, ent2) then
								return false
							end
						end
					end

					for _, data in pairs(self.npcs) do
						local npc = data.npc
						if IsValid(npc) and npc:GetCustomCollisionCheck() then
							if ent1 == npc and not table.HasValue(self.players, ent2) then
								return false
							end
						end
					end
				end
			end)

			hook.Add('EntityTakeDamage', globalHookName, function(target, dmginfo)
				if not IsValid(self) then hook.Remove("EntityTakeDamage", globalHookName) return end

				local quest = self:GetQuest()
				local attaker = dmginfo:GetAttacker()

				if attaker:IsWeapon() then
					attaker = attaker.Owner
				end

				if attaker ~= nil and attaker:IsPlayer() then
					for _, data in pairs(self.npcs) do
						local npc = data.npc
						if IsValid(npc) and IsValid(attaker) then
							if not table.HasValue(self.players, attaker) then
								return true
							end
						end
					end
				end
			end)

			hook.Add('OnNPCKilled', globalHookName, function(npc, attacker, inflictor)
				if not IsValid(self) then hook.Remove("OnNPCKilled", globalHookName) return end

				if self:IsQuestNPC(npc) then
					local g_ragdoll_fadespeed = GetConVar("g_ragdoll_fadespeed"):GetInt()
					local g_ragdoll_important_maxcount = GetConVar("g_ragdoll_important_maxcount"):GetInt()
					local g_ragdoll_lvfadespeed = GetConVar("g_ragdoll_lvfadespeed"):GetInt()
					local g_ragdoll_maxcount = GetConVar("g_ragdoll_maxcount"):GetInt()
					
					RunConsoleCommand("g_ragdoll_fadespeed", "1")
					RunConsoleCommand("g_ragdoll_important_maxcount", "0")
					RunConsoleCommand("g_ragdoll_lvfadespeed", "1")
					RunConsoleCommand("g_ragdoll_maxcount", "0")

					local timerName = 'OnNPCKilled_' .. globalHookName
					if timer.Exists(timerName) then
						timer.Remove(timerName)
					end

					timer.Create(timerName, 0.5, 1, function()
						RunConsoleCommand("g_ragdoll_fadespeed", g_ragdoll_fadespeed)
						RunConsoleCommand("g_ragdoll_important_maxcount", g_ragdoll_important_maxcount)
						RunConsoleCommand("g_ragdoll_lvfadespeed", g_ragdoll_lvfadespeed)
						RunConsoleCommand("g_ragdoll_maxcount", g_ragdoll_maxcount)
					end)
				end
			end)
		end

		self:SetNWBool('StopThink', true)
		self:SetNWFloat('ThinkDelay', 0)
	else
		local globalHookName = self:GetNWString('global_hook_name')
		hook.Add("EntityEmitSound", globalHookName, function(t)
			if not IsValid(self) then hook.Remove("EntityEmitSound", globalHookName) return end
			local ent = t.Entity
	
			if self:IsQuestNPC(ent) and table.HasValue(self:GetAllPlayers(), LocalPlayer()) then
				return false
			end
		end)
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

function ENT:GetSyncDelay()
	return 0.5
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

function ENT:IsFirstStart()
	return self:GetNWBool('is_first_start', true)
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

function ENT:OnRemove()
	local step = self:GetQuestStepTable()

	if step ~= nil then
		if step.destruct ~= nil then
			step.destruct(self)
		end
	end

	if SERVER then
		self:RemoveNPC()
		self:RemoveItems()
		self:RemoveAllQuestWeapon()
		self:RemoveAllStructure()
	end

	local globalHookName = self:GetNWString('global_hook_name')
	hook.Remove("PlayerUse", globalHookName)
	hook.Remove("ShouldCollide", globalHookName)
	hook.Remove("EntityTakeDamage", globalHookName)
	hook.Remove("OnNPCKilled", globalHookName)
	hook.Remove("EntityEmitSound", globalHookName)

	local quest = self:GetQuest()
	if quest.isEvent then
		hook.Run('DisableEvent', self, quest)
	else
		hook.Run('DisableQuest', self, quest)
	end
end

function ENT:OnNextStep()
	local delay = 1
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

		if SERVER then
			timer.Simple(delay, function()
				if not IsValid(self) then return end
				self:SyncPoints()
			end)
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
		self:SetNPCsBehavior()

		if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then				
			timer.Simple(1, function()
				if IsValid(self) then
					self:SyncNoDraw()
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
	if IsValid(npc) then 
		for _, data in pairs(self.npcs) do
			if data.npc == npc then
				if type ~= nil and data.type ~= type then return false end
				if tag ~= nil and data.tag ~= tag then return false end
				return true
			end
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

function ENT:GetStepValue(key)
	return self.values[key]
end

function ENT:IsQuestWeapon(otherWeapon)
	for _, data in pairs(self.weapons) do
		if IsValid(otherWeapon) and data.weapon_class == otherWeapon:GetClass() then
			return true
		end
	end
	return false
end