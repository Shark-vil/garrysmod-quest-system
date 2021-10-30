AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

-------------------------------------
-- Writes the quest identifier to the entity's network variable.
-------------------------------------
-- @param quest_id string - quest id
-- @param ply entity - player entity (Optional)
-------------------------------------
function ENT:SetQuest(quest_id, ply)
	QuestSystem:Debug('SetQuest - ' .. tostring(quest_id) .. ' to ' .. tostring(ply))

	if ply ~= nil then
		timer.Simple(0.5, function()
			if IsValid(self) then
				self:AddPlayer(ply)
			end
		end)
	end
	self:SetNWString('quest_id', quest_id)
end

-------------------------------------
-- Starts a quest step and performs all operations for execute constructors, triggers, points, etc.
-------------------------------------
-- @param step string - step id
-------------------------------------
function ENT:SetStep(step)
	QuestSystem:Debug('SetStep - ' .. step)

	self.StopThink = true
	self:SetNWBool('StopThink', self.StopThink)

	local quest = self:GetQuest()
	if not quest or not quest.steps then return end

	if quest.steps[step] then
		local old_step = self:GetQuestStep()
		if old_step and #old_step ~= 0 then
			if quest.steps[old_step].destruct and quest.steps[old_step].destruct(self) then
				return
			end

			self:SetNWString('old_step', old_step)
		end
		self:SetNWString('step', step)

		if step ~= 'start' then
			self:SetNWBool('is_first_start', false)
		end
	end

	hook.Run('QSystem.PreSetStep', self, quest, step)

	self:TimerCreate(function()
		self:TimerCreate(function()
			snet.InvokeAll('qsystem_on_construct', self, quest.id, step)

			self:TimerCreate(function()
				if quest.steps[step] and quest.steps[step].construct and quest.steps[step].construct(self) then
					return
				end

				self.StopThink = false
				self:SetNWBool('StopThink', self.StopThink)

				hook.Run('QSystem.PostSetStep', self, quest, step)

				snet.InvokeAll('qsystem_on_next_step', self, step)
				self:OnNextStep()
			end)
		end)

		if step == 'start' then
			if quest.is_event then
				hook.Run('QSystem.EventStarted', self, quest)
			else
				hook.Run('QSystem.QuestStarted', self, quest)
			end

			if quest.auto_next_step_delay ~= nil and quest.auto_next_step ~= nil then
				self:TimerCreate(function()
					if quest.auto_next_step_validaotr and not quest.auto_next_step_validaotr(self) then
						self:Failed()
					else
						self:NextStep(quest.auto_next_step)
					end
				end, quest.auto_next_step_delay)
			end

			if quest.quest_time ~= nil then
				local time = quest.quest_time

				if quest.auto_next_step_delay ~= nil then
					time = time + quest.auto_next_step_delay
				end

				timer.Simple(time, function()
					if IsValid(self) then
						if quest.failed_text then
							quest.failed_text.title = quest.failed_text.title or 'Quest failed'
							quest.failed_text.text = quest.failed_text.text or 'The execution time has expired.'
							self:NotifyOnlyRegistred(quest.failed_text.title, quest.failed_text.text)
						end
						self:Failed()
					end
				end)
			end
		end
	end)
end

-------------------------------------
-- Starts the next step of the quest.
-------------------------------------
-- @param step string - step id
-------------------------------------
function ENT:NextStep(step)
	local quest = self:GetQuest()
	if quest.is_event then
		self:SetStep(step)
	else
		local ply = self:GetPlayer()
		if IsValid(ply) then
			ply:SetQuestStep(self:GetQuestId(), step)
		end
	end
end

-------------------------------------
-- DarkRp supported
-------------------------------------
-- Gives registered players a reward, if it is in the quest configuration.
-------------------------------------
-- @param customPayment number|nil - set the amount of cash reward
-- (By default, the number is taken from the quest configuration - quest.payment)
-- @param addToPayment number|nil - add the specified amount of money to the total.
-- Can be used as a bonus.
-------------------------------------
function ENT:Reward(customPayment, addToPayment)
	local players = self:GetAllPlayers()
	local payment = customPayment or self:GetQuest().payment
	addToPayment = addToPayment or 0

	if payment ~= nil then
		payment = payment + addToPayment
		for _, ply in pairs(players) do
			local new_payment = hook.Run('QSystem.PreReward', self, ply, payment)
			if new_payment ~= nil and isnumber(new_payment) then
				payment = new_payment
			end

			if ply.addMoney ~= nil and engine.ActiveGamemode() == 'darkrp' then
				ply:addMoney(payment)
				DarkRP.notify(ply, 4, 4, 'Ваша награда за выполнение квеста - ' .. DarkRP.formatMoney(payment))
			end

			hook.Run('QSystem.PostReward', self, ply, payment)
		end
	end
end

-------------------------------------
-- DarkRp supported
-------------------------------------
-- Provides compensation to the player if the quest was interrupted or not completed correctly.
-------------------------------------
-- @param customPayment number|nil - set the amount of cash reward
-- (By default, the number from the quest configuration is taken (quest.payment) and divided by two)
-- @param addToPayment number|nil - add the specified amount of money to the total.
-- Can be used as a bonus.
-------------------------------------
function ENT:Reparation(customPayment, addToPayment)
	local payment = customPayment or self:GetQuest().payment
	if payment ~= nil then
		self:Reward(payment / 2, addToPayment)
	end
end

-------------------------------------
-- Gives the player a weapon for the duration of the quest.
-- If the player has a similar weapon, then it will still be added to the database,
-- but will not be removed after the quest is completed.
-------------------------------------
-- @param weapon_class string - weapon class
-------------------------------------
function ENT:GiveQuestWeapon(weapon_class)
	local ply = self:GetPlayer()
	local data = {
		weapon_class = weapon_class,
		weapon = NULL
	}
	local wep

	if not ply:HasWeapon(weapon_class) then
		wep = ply:Give(weapon_class)
		data.weapon = wep
	else
		wep = ply:GetWeapon(weapon_class)
	end

	table.insert(self.weapons, data)

	self:SyncWeapons()

	return wep
end

-------------------------------------
-- Removes the player's quest weapon if issued by the system.
-------------------------------------
-- @param weapon_class string - weapon class
-------------------------------------
function ENT:RemoveQuestWeapon(weapon_class)
	local ply = self:GetPlayer()
	local plyWep = ply:GetWeapon(weapon_class)
	for key, data in pairs(self.weapons) do
		if data.weapon_class == weapon_class then
			if IsValid(data.weapon) and IsValid(plyWep) and plyWep == data.weapon then
				ply:StripWeapon(weapon_class)
			end
			table.remove(self.weapons, key)
		end
	end

	self:SyncWeapons()
end

-------------------------------------
-- Removes all of the player's registered quest weapons if issued by the system.
-------------------------------------
function ENT:RemoveAllQuestWeapon()
	local ply = self:GetPlayer()
	for key, data in pairs(self.weapons) do
		if IsValid(data.weapon) then
			local plyWep = ply:GetWeapon(data.weapon_class)
			if IsValid(plyWep) then
				ply:StripWeapon(data.weapon_class)
			end
		end
	end
	self.weapons = {}
end

-------------------------------------
-- Called to complete a quest and play a sound on success.
-------------------------------------
function ENT:Complete()
	self:TimerCreate(function()
		if self:GetQuest().is_event then
			if SERVER then self:Remove() end
			return
		end

		local ply = self:GetPlayer()
		local quest_id = self:GetQuestId()
		ply:DisableQuest(quest_id)
		ply:RemoveQuest(quest_id)
		ply:SendLua([[surface.PlaySound('vo/NovaProspekt/al_done01.wav')]])
	end)
end

-------------------------------------
-- Called to complete quest and play sound on failure
-------------------------------------
function ENT:Failed()
	self:TimerCreate(function()
		if self:GetQuest().is_event then
			if SERVER then self:Remove() end
			return
		end

		local ply = self:GetPlayer()
		local quest_id = self:GetQuestId()
		ply:DisableQuest(quest_id)
		ply:RemoveQuest(quest_id)
		ply:SendLua([[surface.PlaySound('vo/k_lab/ba_getoutofsight01.wav')]])
	end)
end

-------------------------------------
-- Attempts to force registered NPCs to move to a random registered player.
-------------------------------------
function ENT:MoveEnemyToRandomPlayer()
	local players = self:GetAllPlayers()
	if #players ~= 0 then
		local ply = table.Random(players)
		if IsValid(ply) then
			self:MoveQuestNpcToPosition(ply:GetPos(), 'enemy', nil, 'run')
		end
	end
end

-------------------------------------
-- Makes quest NPCs move towards a given vector.
-------------------------------------
-- @param pos vector - destination vector
-- @param type string|nil - npc type
-- @param tag string - npc tag
-- @param moveType string - type of movement - walk or run
-------------------------------------
function ENT:MoveQuestNpcToPosition(pos, type, tag, moveType)
	moveType = moveType or 'walk'

	local function MoveToPosition(npc)
		local is_background_npcs_movable = false

		if bgNPC then
			local actor = bgNPC:GetActor(npc)
			if actor then
				if moveType == 'walk' then
					actor:WalkToPos(pos, 'walk')
				else
					actor:WalkToPos(pos, 'run')
				end
				if #actor.walkPath ~= 0 then s_background_npcs_movable = true end
			end
		end

		if not is_background_npcs_movable then
			npc:SetSaveValue('m_vecLastPosition', pos)
			if moveType == 'walk' then
				npc:SetSchedule(SCHED_FORCED_GO)
			else
				npc:SetSchedule(SCHED_FORCED_GO_RUN)
			end
		end

		if not npc:slibExistsTimer('QSystem.WalkNpcToPosition') and type == 'enemy' then
			npc:slibCreateTimer('QSystem.WalkNpcToPosition', 1, 0, function()
				if not IsValid(self) then
					npc:slibRemoveTimer('QSystem.WalkNpcToPosition')
					return
				end

				if not IsValid(npc:GetTarget()) then
					local near_target
					local last_distance = 1000000

					for _, ply in ipairs(self.players) do
						local distance = ply:GetPos():DistToSqr(npc:GetPos())
						if distance <= last_distance then
							near_target = ply
							last_distance = distance
						end
					end

					if IsValid(near_target) then
						local actor

						if bgNPC then
							actor = bgNPC:GetActor(npc)
							if actor then actor:SetState('defense', nil, true) end
						end

						if not actor then
							npc:ClearSchedule()
							npc:SetTarget(near_target)
						end
					end
				end
			end)
		end
	end

	for _, data in pairs(self.npcs) do
		if IsValid(data.npc) then
			if type ~= nil and tag ~= nil then
				if type == data.type and tag == data.tag then
					MoveToPosition(data.npc)
					break
				end
			elseif type ~= nil then
				if type == data.type then
					MoveToPosition(data.npc)
				end
			else
				MoveToPosition(data.npc)
			end
		end
	end
end

-------------------------------------
-- Removes the quest structure if it exists.
-------------------------------------
-- @param id string - structure spawn id
-------------------------------------
function ENT:RemoveStructure(id)
	local spawn_id = self.structures[id]
	if spawn_id ~= nil then
		QuestSystem:RemoveStructure(spawn_id)
	end
end

-------------------------------------
-- Removes all quest structures if they exist.
-------------------------------------
function ENT:RemoveAllStructure()
	for id, spawn_id in pairs(self.structures) do
		QuestSystem:RemoveStructure(spawn_id)
	end
end

-------------------------------------
-- Registers an entity as a quest item. It is recommended to use the essence - quest_item as quest items.
-------------------------------------
-- @param item entity - any entity
-- @param item_id string - custom item id (Must be unique!)
-------------------------------------
function ENT:AddQuestItem(item, item_id)

	if IsValid(item) and item:GetClass() == 'quest_item' then
		item:SetQuest(self)
		item:SetId(item_id)
	end

	table.insert(self.items, {
		id = item_id,
		item = item
	})

	if GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then
		item:SetCustomCollisionCheck(true)
	end

	if not self:GetNWBool('StopThink') then
		self:SyncItems()
	end
end

-------------------------------------
-- Registers the entity as a quest NPC.
-------------------------------------
-- @param npc entity - npc entity
-- @param type string - type can be - friend or enemy
-- @param tag string|nil - tag is a unique identifier for an NPC.
-- Can be used to check the state of a specific entity. (Must be unique!)
-------------------------------------
function ENT:AddQuestNPC(npc, type, tag)
	tag = tag or 'none'

	table.insert(self.npcs, {
		type = type,
		tag = tag,
		npc = npc,
	})

	local active_weapon = npc:GetActiveWeapon()
	local active_weapon_class
	if IsValid(active_weapon) then active_weapon_class = active_weapon:GetClass() end

	if bgNPC then
		local actor

		if type == 'enemy' then
			actor = BGN_ACTOR:Instance(npc, 'quest_system_enemy')
		elseif type == 'friend' then
			actor = BGN_ACTOR:Instance(npc, 'quest_system_friend')
		end

		if actor then
			actor.disable_fold_weapon = true
			if active_weapon_class then
				actor.weapon = active_weapon_class
				actor:PrepareWeapon()
			else
				actor.weapon = ''
			end
		end
	end

	if GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then
		npc:SetCustomCollisionCheck(true)
	end

	if not self:GetNWBool('StopThink') then
		self:SyncNPCs()
	end
end

-------------------------------------
-- Spawns a quest npc and registers it in the list.
-------------------------------------
-- @param npc_class string - npc class
-- @param data table - data to create
-- Example:
-- local npc = ENTITY:SpawnQuestNPC('npc_citizen',
-- {
-- 	pos = Vector(0, 0, 0),
-- 	type = 'friend',
-- 	tag = 'Garry', -- Optional
-- 	model = 'models/Humans/Group01/Male_Cheaple.mdl', -- Optional
-- 	ang = Angle(0, 0, 0), -- Optional
-- 	weapon_class = 'weapon_pistol', -- Optional
-- 	afterSpawnExecute = function(eQuest, data) -- Optional
--		local npc = data.npc
-- 		timer.Simple(3, function()
-- 			if not IsValid(npc) then return end
-- 			-- BOOOOOOM!!!!!!
-- 			util.BlastDamage(npc, npc, npc:GetPos(), 350, 250)
-- 			local effectdata = EffectData()
-- 			effectdata:SetOrigin(npc:GetPos())
-- 			util.Effect('Explosion', effectdata)
-- 		end)
-- 	end
-- }
-------------------------------------
-- @return entity - will return the entity of the object
-------------------------------------
function ENT:SpawnQuestNPC(npc_class, data)
	local npc = ents.Create(npc_class)
	npc:SetPos(data.pos)
	if data.ang then
		npc:SetAngles(data.ang)
	end
	if data.model then
		npc:SetModel(data.model)
	end
	if data.weapon_class then
		npc:Give(data.weapon_class)
	end

	if data.health then
		if isnumber(data.health) then
			npc:SetHealth(data.health)
		elseif isstring(data.health) then
			local health = npc:Health()

			do
				local split = string.Split(data.health, '/')
				local value = tonumber(split[2])
				if value then npc:SetHealth(health / value) print(health / value) end
			end

			do
				local split = string.Split(data.health, '*')
				local value = tonumber(split[2])
				if value then npc:SetHealth(health * value) end
			end

			do
				local split = string.Split(data.health, '+')
				local value = tonumber(split[2])
				if value then npc:SetHealth(health + value) end
			end

			do
				local split = string.Split(data.health, '-')
				local value = tonumber(split[2])
				if value then npc:SetHealth(health - value) end
			end
		end
	end

	--[[
		Adds an NPC spawn check. If the player does not see the NPC spawn vector
		or if the distance is greater than the minimum.
	--]]
	if (data.notViewSpawn or data.notSpawnDistance ~= nil) and #self.players ~= 0 then
		local timerName = 'QSystem.SpawnNotView.ID' .. tostring(npc:EntIndex())
		timer.Create(timerName, 0.5, 0, function()
			if not IsValid(self) then
				timer.Remove(timerName)
				return
			end

			if data.notViewSpawn then
				for _, ply in pairs(self.players) do
					if QuestService:PlayerIsViewVector(ply, data.pos) then
						return
					end
				end
			end

			if data.notSpawnDistance ~= nil then
				for _, ply in pairs(self.players) do
					local minDistance = data.notSpawnDistance
					if ply:GetPos():Distance(data.pos) < minDistance then
						return
					end
				end
			end

			npc:Spawn()
			npc:Activate()
			timer.Remove(timerName)
		end)
	else
		npc:Spawn()
		npc:Activate()
	end
	self:AddQuestNPC(npc, data.type, data.tag)
	return npc
end

-------------------------------------
-- Spawns a quest item and registers it in the list.
-------------------------------------
-- @param item_class string - any entity class
-- @param data table - data to create
-- Example:
-- local item = ENTITY:SpawnQuestItem('quest_item', {
-- 	id = 'box',
-- 	model = 'models/props_junk/cardboard_box004a.mdl',
-- 	pos = Vector(0, 0, 0),
-- 	ang = AngleRand()
-- })
-- item:SetFreeze(true)
-------------------------------------
-- @return entity - will return the entity of the object
-------------------------------------
function ENT:SpawnQuestItem(item_class, data)
	local item = ents.Create(item_class)
	item:SetPos(data.pos)
	if data.ang ~= nil then
		item:SetAngles(data.ang)
	end
	if data.model ~= nil then
		item:SetModel(data.model)
	end
	item:Spawn()
	item:Activate()
	self:AddQuestItem(item, data.id)
	return item
end

-------------------------------------
-- Establishes the rules of conduct for registered NPCs for other players or NPCs.
-- If the config parameter - qsystem_cfg_hide_quests_of_other_players - is not false,
-- then the NPCs will ignore players that do not belong to the quest.
-------------------------------------
-- @param ent entity|nil - player or npc entity
-------------------------------------
function ENT:SetNPCsBehavior(ent)
	if table.Count(self.npcs) == 0 then return end

	local npc_ignore_other_players = self:GetQuest().npc_ignore_other_players or false

	if GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then
		npc_ignore_other_players = true
	end

	local function restictionByPlayer(ply)
		for _, data in pairs(self.npcs) do
			if IsValid(data.npc) then
				if table.HasValue(self.players, ply) then
					if data.type == 'enemy' then
						if bgNPC then
							local actor = bgNPC:GetActor(data.npc)
							if actor then actor:AddEnemy(ply, 'defense', true) end
						end
						data.npc:AddEntityRelationship(ply, D_HT, 70)
					elseif data.type == 'friend' then
						data.npc:AddEntityRelationship(ply, D_LI, 70)
					end
				else
					if npc_ignore_other_players then
						data.npc:AddEntityRelationship(ply, D_NU, 99)
					end
				end
			end
		end
	end

	if ent ~= nil then
		if IsValid(ent) and ent:IsPlayer() then
			restictionByPlayer(ent)
			return
		end
	else
		for _, ply in pairs(player.GetAll()) do
			restictionByPlayer(ply)
		end
	end

	local function restictionByOtherNPC(otherNPC)
		if IsValid(otherNPC) and otherNPC:IsNPC() then
			for _, data in pairs(self.npcs) do
				if otherNPC == data.npc then
					for _, npcData in pairs(self.npcs) do
						if IsValid(npcData.npc) and IsValid(otherNPC) and npcData.npc ~= otherNPC then
							if npcData.type == 'enemy' and data.type == 'friend' then
								local actor_1, actor_2

								if bgNPC then
									actor_1 = bgNPC:GetActor(data.npc)
									if actor_1 then actor_1:AddEnemy(npcData.npc, 'defense', true) end

									actor_2 = bgNPC:GetActor(npcData.npc)
									if actor_2 then actor_2:AddEnemy(data.npc, 'defense', true) end
								end

								if not actor_1 then data.npc:AddEntityRelationship(npcData.npc, D_HT, 70) end
								if not actor_2 then npcData.npc:AddEntityRelationship(data.npc, D_HT, 70) end
							elseif (npcData.type == 'friend' and data.type == 'friend') or
								(npcData.type == 'enemy' and data.type == 'enemy')
							then
								npcData.npc:AddEntityRelationship(data.npc, D_LI, 70)
								data.npc:AddEntityRelationship(npcData.npc, D_LI, 70)
							end
						end
					end
					return
				end
			end


			for _, data in pairs(self.npcs) do
				if IsValid(data.npc) then
					data.npc:AddEntityRelationship(otherNPC, D_NU, 99)
					otherNPC:AddEntityRelationship(data.npc, D_NU, 99)
				end
			end
		end
	end

	if ent ~= nil then
		restictionByOtherNPC(ent)
	else
		for _, _ent in pairs(ents.GetAll()) do
			restictionByOtherNPC(_ent)
		end
	end
end

-------------------------------------
-- Registers a player for this quest and syncs some data.
-------------------------------------
-- @param ply entity - player entity
-------------------------------------
function ENT:AddPlayer(ply)
	if IsValid(ply) and ply:IsPlayer() and not table.HasValue(self.players, ply) then
		QuestSystem:Debug('AddPlayer - ' .. tostring(ply))

		table.insert(self.players, ply)

		self:SyncPlayers()
		self:SyncNoDraw()
		self:SetNPCsBehavior()
	end
end

-------------------------------------
-- Removes the player for the given quest and syncs some data.
-------------------------------------
-- @param ply entity - player entity
-------------------------------------
function ENT:RemovePlayer(ply)
	if IsValid(ply) and ply:IsPlayer() and table.HasValue(self.players, ply) then
		QuestSystem:Debug('RemovePlayer - ' .. tostring(ply))

		table.RemoveByValue(self.players, ply)

		self:SyncPlayers()
		self:SyncNoDraw()
		self:SetNPCsBehavior()
	end
end

-------------------------------------
-- Synchronizes the prohibition of drawing quest objects for other players.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncNoDraw(ply, delay)
	self:TimerCreate(function()
		if ply then
			snet.Invoke('qsystem_sync_nodraw', ply, self)
		else
			snet.InvokeAll('qsystem_sync_nodraw', self)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest items with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncItems(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncItems (' .. table.Count(self.items) .. ') - ' .. table.ToString(self.items))
		if ply then
			snet.Invoke('qsystem_sync_items', ply, self, self.items)
		else
			snet.InvokeAll('qsystem_sync_items', self, self.items)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest NPCs with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncNPCs(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncNPCs (' .. table.Count(self.npcs) .. ') - ' .. table.ToString(self.npcs))

		if ply then
			snet.Invoke('qsystem_sync_npcs', ply, self, self.npcs)
		else
			snet.InvokeAll('qsystem_sync_npcs', self, self.npcs)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data about registered players with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncPlayers(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncPlayers (' .. table.Count(self.players) .. ') - ' .. table.ToString(self.players))

		if ply then
			snet.Invoke('qsystem_sync_players', ply, self, self.players)
		else
			snet.InvokeAll('qsystem_sync_players', self, self.players)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest triggers with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncTriggers(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncTriggers (' .. table.Count(self.triggers) .. ') - ' .. table.ToString(self.triggers))

		if ply then
			snet.Invoke('qsystem_sync_triggers', ply, self, self.triggers)
		else
			snet.InvokeAll('qsystem_sync_triggers', self, self.triggers)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest points with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncPoints(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncPoints (' .. table.Count(self.points) .. ') - ' .. table.ToString(self.points))

		if ply then
			snet.Invoke('qsystem_sync_points', ply, self, self.points)
		else
			snet.InvokeAll('qsystem_sync_points', self, self.points)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest variables with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncValues(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncValues (' .. table.Count(self.values) .. ') - ' .. table.ToString(self.values))

		if ply then
			snet.Invoke('qsystem_sync_values', ply, self, self.values)
		else
			snet.InvokeAll('qsystem_sync_values', self, self.values)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest weapons with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncWeapons(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncWeapons (' .. table.Count(self.weapons) .. ') - ' .. table.ToString(self.weapons))

		if ply then
			snet.Invoke('qsystem_sync_weapons', ply, self, self.weapons)
		else
			snet.InvokeAll('qsystem_sync_weapons', self, self.weapons)
		end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest structures with clients.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-- @param delay number|nil - delay before sending data to clients
-------------------------------------
function ENT:SyncStructures(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncStructures (' .. table.Count(self.structures) .. ') - ' .. table.ToString(self.structures))

		if ply then
			snet.Invoke('qsystem_sync_structures', ply, self, self.structures)
		else
			snet.InvokeAll('qsystem_sync_structures', self, self.structures)
		end
	end, delay)
end

-------------------------------------
-- Calls all sync methods in order.
-------------------------------------
-- @param ply entity|nil - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncAll(ply)
	QuestSystem:Debug('Start SyncAll <<<<<<')
	self:SyncPlayers(ply)
	self:SyncTriggers(ply)
	self:SyncPoints(ply)
	self:SyncNPCs(ply)
	self:SyncItems(ply)
	self:SyncValues(ply)
	self:SyncStructures(ply)
	self:SyncNoDraw(ply)
	QuestSystem:Debug('>>>>>> Finish SyncAll')
end

-------------------------------------
-- Sets the quest variable.
-------------------------------------
-- @param key string - variable key
-- @param value any - variable value
-------------------------------------
function ENT:SetVariable(key, value)
	self.values[key] = value
	self:SyncValues()
end

-------------------------------------
-- Removes all existing quest variables.
-------------------------------------
function ENT:ResetVariables()
	self.values = {}
	self:SyncValues()
end

-------------------------------------
-- Lock or unlock the door entity.
-------------------------------------
-- @param ent entity|table - entity or list of entities
-- @param lockState string|nil - door state - lock or unlock. (The default is always  - lock)
-------------------------------------
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
				'func_door',
				'func_door_rotating',
				'prop_door_rotating',
				'func_movelinear',
				'prop_dynamic',
			}

			if table.HasValue(doorsValidClass, door:GetClass()) then
				door:Fire(lockState)
				if lockState == 'lock' then
					door.qsystemDoorIsLock = true
				else
					door.qsystemDoorIsLock = false
				end
			end
		end
	end
end

-------------------------------------
-- Removes registered npc. If no arguments are passed, then all NPCs will be removed.
-------------------------------------
-- @param type string|nil - if not nil, then all NPCs of this type will be deleted
-- @param tag string|nil - if not nil, then all NPCs for this tag will be deleted 
-- (The type must not be nil)
-------------------------------------
function ENT:RemoveNPC(type, tag)
	if #self.npcs ~= nil then
		if type ~= nil then
			local key_removes = {}

			for key, data in pairs(self.npcs) do
				if IsValid(data.npc) then
					if tag ~= nil then
						if type == data.type and tag == data.tag then
							data.npc:FadeRemove()
							table.insert(key_removes, key)
						end
					elseif type == data.type then
						data.npc:FadeRemove()
						table.insert(key_removes, key)
					end
				end
			end

			for _, key in pairs(key_removes) do
				table.remove(self.npcs, key)
			end
		else
			for _, data in pairs(self.npcs) do
				data.npc:FadeRemove()
			end
			table.Empty(self.npcs)
		end

		self:SyncNPCs()
	end
end

-------------------------------------
-- Removes registered items. If no arguments are passed, then all items will be removed.
-------------------------------------
-- @param item_id string|nil - if not nil, then only the item with this identifier will be deleted
-------------------------------------
function ENT:RemoveItems(item_id)
	if #self.items ~= nil then
		if item_id ~= nil then
			for key, data in pairs(self.items) do
				if IsValid(data.item) and data.name == item_id then
					data.item:FadeRemove()
					table.remove(self.items, key)
					break;
				end
			end
		else
			for _, data in pairs(self.items) do
				if IsValid(data.item) then
					data.item:FadeRemove()
				end
			end
			table.Empty(self.items)
		end
	end
end

function ENT:ForcedTracking()
	net.Start('cl_qsystem_set_quest_tracking')
	net.WriteEntity(self)
	net.Send(self.players)
end