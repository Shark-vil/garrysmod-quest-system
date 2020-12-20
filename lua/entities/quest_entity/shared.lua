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
ENT.spawned_npcs = {}

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
			-------------------------------------
			-- Calls a step function - onUse - when press E on any (almost) entity.
			-------------------------------------
			-- @params wiki - https://wiki.facepunch.com/gmod/GM:PlayerUse
			-------------------------------------
			hook.Add("PlayerUse", globalHookName, function(ply, ent)
				if not IsValid(self) then hook.Remove("PlayerUse", globalHookName) return end
				
				local step = self:GetQuestStepTable()
				if step ~= nil and step.onUse ~= nil then
					if table.HasValue(self.players, ply) then
						step.onUse(self, ent)
					end
				end
			end)
		end

		if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then
			-------------------------------------
			-- Disable collision with quest objects for players not belonging to the quest.
			-------------------------------------
			-- @params wiki - https://wiki.facepunch.com/gmod/GM:ShouldCollide
			-------------------------------------
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

			-------------------------------------
			-- Disables player damage to NPCs if players do not belong to the quest, and vice versa.
			-------------------------------------
			-- @params wiki - https://wiki.facepunch.com/gmod/GM:EntityTakeDamage
			-------------------------------------
			hook.Add('EntityTakeDamage', globalHookName, function(target, dmginfo)
				if not IsValid(self) then hook.Remove("EntityTakeDamage", globalHookName) return end

				local attaker = dmginfo:GetAttacker()
				if attaker:IsWeapon() then
					attaker = attaker.Owner
				end

				if target:IsNPC() then
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
				elseif target:IsPlayer() and attaker ~= nil and attaker:IsNPC() then
					for _, ent in pairs(ents.FindByClass('quest_entity')) do
						if ent ~= self then
							local npcs = ent.npcs
							if npcs ~= nil and table.Count(npcs) ~= 0 then
								for _, data in pairs(npcs) do
									if attaker == data.npc then
										return true
									end
								end
							end
						end
					end
				end
			end)
		end

		-------------------------------------
		-- Calls a function for a step if the quest NPC is killed.
		-------------------------------------
		-- @params wiki - https://wiki.facepunch.com/gmod/GM:OnNPCKilled
		-------------------------------------
		hook.Add('OnNPCKilled', globalHookName, function(npc, attacker, inflictor)
			if not IsValid(self) then hook.Remove("OnNPCKilled", globalHookName) return end
			for _, data in pairs(self.npcs) do
				if data.npc == npc then
					local step = self:GetQuestStepTable()
					if step ~= nil and step.onQuestNPCKilled ~= nil then
						step.onQuestNPCKilled(self, data, npc, attacker, inflictor)
					end
					break
				end
			end
		end)

		-------------------------------------
		-- Forces the visibility of all quest entities. Otherwise, clients may receive an empty value.
		-------------------------------------
		-- @params wiki - https://wiki.facepunch.com/gmod/GM:SetupPlayerVisibility
		-------------------------------------
		hook.Add('SetupPlayerVisibility', globalHookName, function(pPlayer, pViewEntity)
			if not IsValid(self) then hook.Remove("SetupPlayerVisibility", globalHookName) return end
			AddOriginToPVS(self:GetPos())

			local entities = {}
			for _, data in pairs(self.npcs) do
				table.insert(entities, data.npc)
			end

			for _, data in pairs(self.items) do
				table.insert(entities, data.item)
			end

			for _, spawn_id in pairs(self.structures) do
				local props = QuestSystem:GetStructure(spawn_id)
				for _, prop in pairs(props) do
					table.insert(entities, prop)
				end
			end
			
			for _, data in pairs(self.weapons) do
				table.insert(entities, data.weapon)
			end

			for _, ent in pairs(entities) do
				if IsValid(ent) then
					AddOriginToPVS(ent:GetPos())
				end
			end
		end)

		self:SetNWBool('StopThink', true)
		self:SetNWFloat('ThinkDelay', 0)
	else
		local globalHookName = self:GetNWString('global_hook_name')

		-------------------------------------
		-- Removes NPCs sounds if players do not belong to the quest.
		-- WARNING:
		-- The effectiveness of the hook is questionable. May be removed in the future.
		-------------------------------------
		-- @params wiki - https://wiki.facepunch.com/gmod/GM:EntityEmitSound
		-------------------------------------
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
			hook.Run('QSystem.EventStarted', self, quest)
		else
			hook.Run('QSystem.QuestStarted', self, quest)
		end
	end)
end

-------------------------------------
-- Gets the delay time. Used to delay sending network requests to clients.
-------------------------------------
-- @return number - delay number
-------------------------------------
function ENT:GetSyncDelay()
	return 0.5
end

-------------------------------------
-- Checks for the existence of a nested steps value.
-------------------------------------
-- @params arg - value key
-------------------------------------
-- @return bool - will return true if the key exists, otherwise false
-------------------------------------
function ENT:IsExistStepArg(arg)
	for step_name, step_data in pairs(self:GetQuest().steps) do
		if step_data[arg] ~= nil then return true end
	end
	return false
end

-------------------------------------
-- Get data for the current quest.
-------------------------------------
-- @return table - returns the quest configuration data table
-------------------------------------
function ENT:GetQuest()
	self.quest = self.quest or QuestSystem:GetQuest(self:GetQuestId())
	return self.quest
end

-------------------------------------
-- Get the data of the current step of the quest.
-------------------------------------
-- @return table - returns the data table of the current step
-------------------------------------
function ENT:GetQuestStepTable()
	local quest = self:GetQuest()
	if quest == nil then return nil end

	local step = self:GetQuestStep()
	return quest.steps[step]
end

-------------------------------------
-- Get the quest ID.
-------------------------------------
-- @return string - quest id
-------------------------------------
function ENT:GetQuestId()
	return self:GetNWString('quest_id')
end

-------------------------------------
-- Get the current quest step.
-------------------------------------
-- @return string - step id
-------------------------------------
function ENT:GetQuestStep()
	return self:GetNWString('step')
end

-------------------------------------
-- Get the old quest step.
-------------------------------------
-- @return string - step id or empty string
-------------------------------------
function ENT:GetQuestOldStep()
	return self:GetNWString('old_step')
end

-------------------------------------
-- Get the entity of the player. If there are several players, 
-- this function will return only the first one in the table.
-------------------------------------
-- @return entity - step id or empty string
-------------------------------------
function ENT:GetPlayer()
	return self.players[1]
end

-------------------------------------
-- Check if step is first.
-------------------------------------
-- @return bool - if the current step is start, true will be returned, otherwise false
-------------------------------------
function ENT:IsFirstStart()
	return self:GetNWBool('is_first_start', true)
end

-------------------------------------
-- Executable a global quest function.
-------------------------------------
-- @params id - function identifier
-- @params args - any arguments separated by commas
-------------------------------------
function ENT:ExecQuestFunction(id, ...)
	local quest = self:GetQuest()
	if quest ~= nil and quest.functions ~= nil then
		local func = quest.functions[id]
		func(...)
	end
end

-------------------------------------
-- Get a list of all registered players.
-------------------------------------
-- @return table - will return a list with player entities
-------------------------------------
function ENT:GetAllPlayers()
	return self.players
end

-------------------------------------
-- Calls an step think and triggers function if exists.
-------------------------------------
-- @params wiki - https://wiki.facepunch.com/gmod/ENTITY:Think
-------------------------------------
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

-------------------------------------
-- Removes all dependencies when the entity is deleted, and also calls the step function - destruct.
-------------------------------------
-- @params wiki - https://wiki.facepunch.com/gmod/ENTITY:OnRemove
-------------------------------------
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
	hook.Remove("SetupPlayerVisibility", globalHookName)

	local quest = self:GetQuest()
	if quest.isEvent then
		hook.Run('QSystem.EventStopped', self, quest)
	else
		hook.Run('QSystem.QuestStopped', self, quest)
	end
end

-------------------------------------
-- Registers and synchronizes the remaining dependencies. This function is called after - SetStep.
-------------------------------------
function ENT:OnNextStep()
	QuestSystem:Debug('> OnNextStep execute')
	
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
		--[[
			Smooth creation of NPC in order to compensate for lags.
		--]]
		do
			local count = table.Count(self.spawned_npcs)
			if count ~= 0 then
				local delay = 0.1
				local next_delay = delay
				for i = 1, count do
					local data = self.spawned_npcs[i]
					self:AddQuestNPC(data.npc, data.type, data.tag)
					self:TimerCreate(function()
						data.npc:Spawn()
						if data.afterSpawnExecute ~= nil then
							data.afterSpawnExecute(self, data)
						end
					end, next_delay)
					next_delay = next_delay + delay
				end
				table.Empty(self.spawned_npcs)
			end
		end

		self:SyncNPCs()
		self:SyncItems()
		self:SetNPCsBehavior()

		if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then				
			self:SyncNoDraw()
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
		hook.Run('QSystem.NextEventStep', self, step, quest)
	else
		hook.Run('QSystem.NextQuestStep', self, step, quest)
	end
end

-------------------------------------
-- Sends a notification to the first player in the list of registered players.
-------------------------------------
-- @params player extension - lua/quest_system/extension/player_quest/sh_extension.lua
-------------------------------------
function ENT:Notify(title, desc, lifetime, image, bgcolor)
	self:GetPlayer():QuestNotify(title, desc, lifetime, image, bgcolor)
end

-------------------------------------
-- Sends notification to all registered players.
-------------------------------------
-- @params player extension - lua/quest_system/extension/player_quest/sh_extension.lua
-------------------------------------
function ENT:NotifyOnlyRegistred(title, desc, lifetime, image, bgcolor)
	for _, ply in pairs(self.players) do
		ply:QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

-------------------------------------
-- Sends a notification to all players on the server.
-------------------------------------
-- @params player extension - lua/quest_system/extension/player_quest/sh_extension.lua
-------------------------------------
function ENT:NotifyAll(title, desc, lifetime, image, bgcolor)
	for _, ply in pairs(player.GetHumans()) do
		ply:QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

-------------------------------------
-- Check if the NPC belongs to the quest or not.
-------------------------------------
-- @params npc - entity to check
-- (Optional) @params type - npc type (if required)
-- (Optional) @params tag - npc tag (if required)
-------------------------------------
-- @return bool - will return true if NPCs were found according to the conditions, otherwise false
-------------------------------------
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

-------------------------------------
-- Get one or more registered NPCs.
-------------------------------------
-- @params type - npc type
-- (Optional) @params tag extension - npc tag. 
-------------------------------------
-- @return entity - will return the found entity, otherwise NULL
-------------------------------------
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

-------------------------------------
-- Check if the Entity belongs to the quest or not.
-------------------------------------
-- @params item - entity to check
-------------------------------------
-- @return bool - will return true if entity were found, otherwise false
-------------------------------------
function ENT:IsQuestItem(item)
	for _, data in pairs(self.items) do
		if data.item == item then return true end
	end
	return false
end

-------------------------------------
-- Get registered item.
-------------------------------------
-- @params item_id - unique item identifier
-------------------------------------
-- @return entity - will return the found entity, otherwise NULL
-------------------------------------
function ENT:GetQuestItem(item_id)
	for _, data in pairs(self.items) do
		if data.id == item_id then
			return data.item
		end
	end
	return NULL
end

-------------------------------------
-- Get quest variable.
-------------------------------------
-- @params key - variable key
-------------------------------------
-- @return string - will return the value of a variable or nil
-------------------------------------
function ENT:GetVariable(key)
	return self.values[key]
end

-------------------------------------
-- Check if the weapon is a quest one.
-------------------------------------
-- @params otherWeapon - weapon entity
-------------------------------------
-- @return bool - will return true if the weapon is a quest weapon, otherwise false
-------------------------------------
function ENT:IsQuestWeapon(otherWeapon)
	for _, data in pairs(self.weapons) do
		if IsValid(otherWeapon) and data.weapon_class == otherWeapon:GetClass() then
			return true
		end
	end
	return false
end

-------------------------------------
-- timer.Simple wrapper. Creates a timer and automatically 
-- checks the existence of the quest before executing the function.
-------------------------------------
-- @params func - executable function
-- (Optional) @params delay - timer delay 
-- (By default it takes a number from the function - self:GetSyncDelay())
-------------------------------------
function ENT:TimerCreate(func, delay)
	delay = delay or self:GetSyncDelay()
	timer.Simple(delay, function()
		if not IsValid(self) then return end
		func()
	end)
end