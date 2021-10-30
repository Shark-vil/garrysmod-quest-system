ENT.Type = 'anim'
ENT.Base = 'base_gmodentity'
ENT.PrintName = 'Quest Entity'
ENT.Author = ''
ENT.Contact = ''
ENT.Purpose	= ''
ENT.Instructions = ''

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.hooks = {}
ENT.triggers = {}
ENT.points = {}
ENT.npcs = {}
ENT.items = {}
ENT.weapons = {}
ENT.players = {}
ENT.values = {}
ENT.structures = {}

ENT.trigger_entities = {}

ENT.StopThink = false

local ipairs = ipairs
local pairs = pairs
local IsValid = IsValid
local table_HasValueBySeq = table.HasValueBySeq
local table_insert = table.insert
local hook_Remove = hook.Remove
local table_remove = table.remove
local slib_FindInBox = slib.FindInBox
local slib_FindInSphere = slib.FindInSphere

function ENT:Initialize()
	self:SetModel('models/props_junk/PopCan01a.mdl')
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetNoDraw(true)

	if SERVER then
		self:slibSetVar('quest_entity_uuid', slib.UUID())
		self:SetNWBool('StopThink', true)
		self:SetNWFloat('ThinkDelay', 0)
	end

	table_insert(QuestSystem.Storage.Quests, self)
end

function ENT:GetUUID()
	return self:slibGetVar('quest_entity_uuid', nil)
end

-------------------------------------
-- Gets the delay time. Used to delay sending network requests to clients.
-------------------------------------
-- @return number - delay number
-------------------------------------
function ENT:GetSyncDelay()
	return 0.3
end

-------------------------------------
-- Checks for the existence of a nested steps value.
-------------------------------------
-- @param arg string - value key
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

function ENT:HasQuester(ply)
	return table_HasValueBySeq(self.players, ply)
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
-- @param id string - function identifier
-- @param args varargs - any arguments separated by commas
-------------------------------------
function ENT:QuestFunction(id, ...)
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
-- Checks the existence of one or more NPCs. If there are several NPCs in the check,
-- then the truth will be returned, even if there is only one left alive!
-------------------------------------
-- @param npcType string - npc type
-- @param npcTag string|nil - npc tag
-------------------------------------
-- @return bool - will return true if one or more npc exists, otherwise false
-------------------------------------
function ENT:QuestNPCIsAlive(npcType, npcTag)
	local allowAlive = false
	for i = 1, #self.npcs do
		local data = self.npcs[i]
		local npc = data.npc
		if npcType and npcTag then
			if data.type == npcType and data.tag == npcTag and IsValid(npc) and npc:Health() > 0 then
				allowAlive = true
				break
			end
		elseif npcType then
			if data.type == npcType and IsValid(npc) and npc:Health() > 0 then
				allowAlive = true
				break
			end
		else
			ErrorNoHalt('This function must take at least 1 argument!')
		end
	end
	return allowAlive
end

-------------------------------------
-- Calls an step think and triggers function if exists.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/ENTITY:Think
-------------------------------------
function ENT:Think()
	local step = self:GetQuestStepTable()

	if step and not self:SetNWBool('StopThink', true) and not self.StopThink then
		if step.think then step.think(self) end

		local triggers = self.triggers
		local triggers_count = #triggers

		if triggers_count ~= 0 then
			local quest = self:GetQuest()

			for i = 1, triggers_count do
				local tdata = triggers[i]
				local entities = {}
				local name = tdata.name
				local trigger = tdata.trigger
				local trigger_functions = quest.steps[tdata.step].triggers[name]
				local trigger_think = trigger_functions.think
				local trigger_onEnter = trigger_functions.onEnter
				local trigger_onExit = trigger_functions.onExit
				local center

				self.trigger_entities[name] = self.trigger_entities[name] or {}

				if trigger.type == 'box' then
					entities = slib_FindInBox(trigger.vec1, trigger.vec2)
					center = (trigger.vec1 + trigger.vec2) / 2
				elseif trigger.type == 'sphere' then
					entities = slib_FindInSphere(trigger.center, trigger.radius)
					center = trigger.center
				end

				for k = #self.trigger_entities[name], 1, -1 do
					local ent = self.trigger_entities[name][k]
					if not table_HasValueBySeq(entities, ent) then
						if trigger_onExit then
							trigger_onExit(self, ent, center, trigger)
						end
						table_remove(self.trigger_entities[name], k)
					end
				end

				for _, ent in ipairs(entities) do
					if not table_HasValueBySeq(self.trigger_entities[name], ent) then
						table_insert(self.trigger_entities[name], ent)
						if trigger_onEnter then
							trigger_onEnter(self, ent, center, trigger)
						end
					end
				end

				if trigger_think then
					trigger_think(self, entities, center, trigger)
				end
			end
		end
	end
end

-------------------------------------
-- Removes all dependencies when the entity is deleted, and also calls the step function - destruct.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/ENTITY:OnRemove
-------------------------------------
function ENT:OnRemove()
	local step = self:GetQuestStepTable()
	if step and step.destruct then step.destruct(self) end

	if SERVER then
		self:RemoveNPC()
		self:RemoveItems()
		self:RemoveAllQuestWeapon()
		self:RemoveAllStructure()
	end

	local quest = self:GetQuest()

	for i = #self.hooks, 1, -1 do
		local data = self.hooks[i]
		hook_Remove(data.hook_type, data.hook_name)
		table_remove(self.hooks, i)
	end

	if quest.is_event then
		hook.Run('QSystem.EventStopped', self, quest)
	else
		hook.Run('QSystem.QuestStopped', self, quest)
	end

	table.RemoveValueBySeq(QuestSystem.Storage.Quests, self)
end

-------------------------------------
-- Registers and synchronizes the remaining dependencies. This function is called after - SetStep.
-------------------------------------
function ENT:OnNextStep()
	QuestSystem:Debug('> OnNextStep execute')

	local quest = self:GetQuest()
	if not quest.steps then return end

	local step = self:GetQuestStep()

	if #self.points ~= 0 and quest.steps[step] and quest.steps[step].points then
		for i = 1, #self.points do
			local data = self.points[i]
			if quest.steps[step].points[data.name] then
				local func = quest.steps[data.step].points[data.name]
				if func and isfunction(func) then func(self, data.points) end
			end
		end

		if SERVER then
			snet.InvokeAll('QSystem.QuestAction.InitPoints', self)
		end
	end

	if #self.triggers ~= 0 then
		for i = 1, #self.triggers do
			local tdata = self.triggers[i]
			local name = tdata.name
			local trigger = tdata.trigger
			local trigger_functions = quest.steps[tdata.step].triggers[name]
			local trigger_construct = trigger_functions.construct

			if trigger_construct and isfunction(trigger_construct) then
				local center

				if trigger.type == 'box' then
					center = (trigger.vec1 + trigger.vec2) / 2
				elseif trigger.type == 'sphere' then
					center = trigger.center
				end

				trigger_construct(self, center, trigger)
			end
		end
	end

	for i = #self.hooks, 1, -1 do
		local data = self.hooks[i]
		if not data.is_gloabl then
			hook_Remove(data.hook_type, data.hook_name)
			table_remove(self.hooks, i)
		end
	end

	if SERVER then
		self:SyncNPCs()
		self:SyncItems()
		self:SetNPCsBehavior()

		if GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then
			self:SyncNoDraw()
		end
	end

	-- if SERVER then
	-- 	self:SetNWBool('StopThink', false)
	-- end

	if step == 'start' then
		if SERVER and not quest.disableNotify then
			if quest.is_event then
				self:NotifyAllQuestStart(quest.notify_lifetime, quest.notify_image, quest.notify_bgcolor)
			else
				self:NotifyQuestStart(quest.notify_lifetime, quest.notify_image, quest.notify_bgcolor)
			end
		end

		if quest.global_hooks then
			for hook_type, func in pairs(quest.global_hooks) do
				local hook_name = slib.UUID()

				hook.Add(hook_type, hook_name, function(...)
					if not IsValid(self) then
						hook_Remove(hook_type, hook_name)
						return
					end

					func(self, ...)
				end)

				table_insert(self.hooks, { hook_type = hook_type, hook_name = hook_name, is_gloabl = true })
			end
		end
	end

	if quest.steps[step] and quest.steps[step].hooks then
		for hook_type, func in pairs(quest.steps[step].hooks) do
			local hook_name = slib.UUID()

			hook.Add(hook_type, hook_name, function(...)
				if not IsValid(self) then
					hook_Remove(hook_type, hook_name)
					return
				end

				func(self, ...)
			end)

			table_insert(self.hooks, { hook_type = hook_type, hook_name = hook_name, is_gloabl = false })
		end
	end

	if quest.is_event then
		hook.Run('QSystem.NextEventStep', self, step, quest)
	else
		hook.Run('QSystem.NextQuestStep', self, step, quest)
	end
end

-------------------------------------
-- Sends a notification to the first player in the list of registered players.
-------------------------------------
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- ЗАПОЛНИТЬ ОПИСАНИЕ ПАРАМЕТРОВ
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-------------------------------------
function ENT:Notify(title, desc, lifetime, image, bgcolor)
	if SERVER then
		local ply = self:GetPlayer()
		if not IsValid(ply) then return end
		ply:QuestNotify(title, desc, lifetime, image, bgcolor)
	else
		LocalPlayer():QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

function ENT:NotifyQuestStart(lifetime, image, bgcolor)
	if SERVER then
		local ply = self:GetPlayer()
		if not IsValid(ply) then return end
		ply:QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
	else
		LocalPlayer():QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
	end
end

-------------------------------------
-- Sends notification to all registered players.
-------------------------------------
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- ЗАПОЛНИТЬ ОПИСАНИЕ ПАРАМЕТРОВ
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-------------------------------------
function ENT:NotifyOnlyRegistred(title, desc, lifetime, image, bgcolor)
	if SERVER then
		for _, ply in pairs(self.players) do
			if IsValid(ply) then
				ply:QuestNotify(title, desc, lifetime, image, bgcolor)
			end
		end
	else
		LocalPlayer():QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

function ENT:NotifyOnlyRegistredQuestStart(lifetime, image, bgcolor)
	if SERVER then
		for _, ply in pairs(self.players) do
			if IsValid(ply) then
				ply:QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
			end
		end
	else
		LocalPlayer():QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
	end
end

-------------------------------------
-- Sends a notification to all players on the server.
-------------------------------------
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- ЗАПОЛНИТЬ ОПИСАНИЕ ПАРАМЕТРОВ
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-------------------------------------
function ENT:NotifyAll(title, desc, lifetime, image, bgcolor)
	if SERVER then
		for _, ply in pairs(player.GetHumans()) do
			if IsValid(ply) then
				ply:QuestNotify(title, desc, lifetime, image, bgcolor)
			end
		end
	else
		LocalPlayer():QuestNotify(title, desc, lifetime, image, bgcolor)
	end
end

function ENT:NotifyAllQuestStart(lifetime, image, bgcolor)
	if SERVER then
		for _, ply in pairs(player.GetHumans()) do
			if IsValid(ply) then
				ply:QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
			end
		end
	else
		LocalPlayer():QuestStartNotify(self:GetQuest().id, lifetime, image, bgcolor)
	end
end

-------------------------------------
-- Check if the NPC belongs to the quest or not.
-------------------------------------
-- @param npc entity - npc entity
-- @param type string|nil - npc type
-- @param tag string|nil - npc tag
-------------------------------------
-- @return bool - will return true if NPCs were found according to the conditions, otherwise false
-------------------------------------
function ENT:IsQuestNPC(npc, npcType, npcTag)
	if not IsValid(npc) then return false end
	for i = 1, #self.npcs do
		local data = self.npcs[i]
		if data.npc == npc then
			if npcTag and data.tag ~= npcTag then return false end
			if npcType and data.type ~= npcType then return false end
			return true
		end
	end
	return false
end

function ENT:IsAliveQuestNPC(npcType, npcTag)
	for i = 1, #self.npcs do
		local data = self.npcs[i]
		local npc = data.npc
		if npcTag then
			if data.tag == npcTag and IsValid(npc) and npc:Health() > 0 then return true end
		elseif npcType then
			if data.type == npcType and IsValid(npc) and npc:Health() > 0 then return true end
		else
			if IsValid(npc) and npc:Health() > 0 then return true end
		end
	end
	return false
end

-------------------------------------
-- Checks if the player is part of the quest.
-------------------------------------
-- @param ply entity - player entity
-------------------------------------
-- @return bool - will return true if the player belongs to the quest, otherwise false
-------------------------------------
function ENT:IsQuestPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	for i = 1, #self.players do
		if self.players[i] == ply then return true end
	end
	return false
end

-------------------------------------
-- Get one or more registered NPCs.
-------------------------------------
-- @param type string - npc type
-- @param tag string|nil - npc tag
-------------------------------------
-- @return entity - will return the found entity, otherwise NULL
-------------------------------------
function ENT:GetQuestNpc(npcType, npcTag)
	if not npcType then return NULL end
	if npcTag then
		for _, data in pairs(self.npcs) do
			if data.type == npcType and data.tag == npcTag then
				return data.npc
			end
		end
	else
		local npcs = {}
		for _, data in pairs(self.npcs) do
			if data.type == npcType then
				table_insert(npcs, data.npc)
			end
		end
		return npcs
	end
end

-------------------------------------
-- Check if the Entity belongs to the quest or not.
-------------------------------------
-- @param item entity - entity to check
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
-- @param item_id string - unique item identifier
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
-- @param key string - variable key
-------------------------------------
-- @return string - will return the value of a variable or nil
-------------------------------------
function ENT:GetVariable(key)
	return self.values[key]
end

function ENT:SetArrowVector(target, autoEnable)
	if not isvector(target) and (not isentity(target) or not IsValid(target)) then return end
	if autoEnable == nil then autoEnable = true end
	if autoEnable then self:EnableArrowVector() end
	self:slibSetVar('arrow_target', target)
end

function ENT:EnableArrowVector()
	self:slibSetVar('arrow_target_enabled', true)
end

function ENT:DisableArrowVector()
	self:slibSetVar('arrow_target_enabled', false)
end

-------------------------------------
-- Check if the weapon is a quest one.
-------------------------------------
-- @param otherWeapon entity - weapon entity
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
-- @param func function - executable function
-- @param delay number|nil - timer delay 
-- (By default it takes a number from the function - self:GetSyncDelay())
-------------------------------------
function ENT:TimerCreate(func, delay)
	delay = delay or self:GetSyncDelay()
	timer.Simple(delay, function()
		if not IsValid(self) then return end
		func()
	end)
end

function ENT:GetAllQuests()
	local quest = self:GetQuest()
	local quests = {}
	local quests_in_storage = QuestSystem.Storage.Quests

	for i = #quests_in_storage, 1, -1 do
		local eQuest = quests_in_storage[i]
		if eQuest:GetQuest().id == quest.id then
			table_insert(quests, eQuest)
		end
	end

	return quests
end