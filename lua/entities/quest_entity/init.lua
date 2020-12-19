AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

-------------------------------------
-- Writes the quest identifier to the entity's network variable.
-------------------------------------
-- @param quest_id string - quest id
-- @param ply entity - player entity (Optional)
-------------------------------------
function ENT:SetQuest(quest_id, ply)
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
-- @return any - will return the value returned by the quest step constructor or nil
-------------------------------------
function ENT:SetStep(step)
	self:SetNWBool('StopThink', true)
	self:SetNWFloat('ThinkDelay', RealTime() + 1)

	local quest = self:GetQuest()

	if quest ~= nil and quest.steps[step] ~= nil then
		local old_step = self:GetQuestStep()
		if old_step ~= nil and #old_step ~= 0 then
			self:SetNWString('old_step', old_step)
		end
		self:SetNWString('step', step)

		if step ~= 'start' then
			self:SetNWBool('is_first_start', false)
		end

		self.triggers = {}
		if quest.steps[step].triggers ~= nil then
			for trigger_name, _ in pairs(quest.steps[step].triggers) do
				local file_path = 'quest_system/triggers/' .. quest.id .. '/' .. game.GetMap() .. '/' .. trigger_name .. '.json'
				if file.Exists(file_path, 'DATA') then
					local trigger = util.JSONToTable(file.Read(file_path, "DATA"))
					table.insert(self.triggers, {
						name = trigger_name,
						trigger = trigger
					})
				end
			end
		end

		self:SyncTriggers()

		self.points = {}
		if quest.steps[step].points ~= nil then
			for point_name, _ in pairs(quest.steps[step].points) do
				local file_path = 'quest_system/points/' .. quest.id .. '/' .. game.GetMap() .. '/' .. point_name .. '.json'
				if file.Exists(file_path, 'DATA') then
					local points = util.JSONToTable(file.Read(file_path, "DATA"))
					table.insert(self.points, {
						name = point_name,
						points = points
					})
				end
			end
		end

		if quest.steps[step].structures ~= nil then
			for structure_id, method in pairs(quest.steps[step].structures) do
				local spawn_id = QuestSystem:SpawnStructure(quest.id, structure_id)
				if spawn_id ~= nil then
					if isfunction(method) then
						self.structures[structure_id] = spawn_id
						method(eQuest, QuestSystem:GetStructure(spawn_id), spawn_id)
					elseif isbool(method) and method == true then
						self.structures[structure_id] = spawn_id
					end
				end
			end
		end
	end

	if step == 'start' then
		if quest.isEvent then
			quest.title = '[Событие] ' .. quest.title
		end

		if quest.timeToNextStep ~= nil and quest.nextStep ~= nil then
			quest.description = quest.description .. '\nДо начала: ' .. quest.timeToNextStep .. ' сек.'
		end

		if quest.timeQuest ~= nil then
			quest.description = quest.description .. '\nВремя выполнения: ' .. quest.timeQuest .. ' сек.'
		end
	end

	self:OnNextStep()

	local start_result = nil
	if quest.steps[step].construct ~= nil then
		start_result = quest.steps[step].construct(self)
	end

	self:TimerCreate(function()
		net.Start('cl_qsystem_on_construct')
		net.WriteEntity(self)
		net.WriteString(self:GetQuestId())
		net.WriteString(step)
		if step == 'start' then
			net.WriteString(utf8.force(quest.title))
			net.WriteString(utf8.force(quest.description))
		end
		net.Broadcast()
	end)

	self:TimerCreate(function()
		net.Start('cl_qsystem_on_next_step')
		net.WriteEntity(self)
		net.WriteString(step)
		net.Broadcast()
	end)

	if step == 'start' then
		if quest.timeToNextStep ~= nil and quest.nextStep ~= nil then
			timer.Simple(quest.timeToNextStep, function()
				if IsValid(self) then
					if quest.nextStepCheck ~= nil then
						if quest.nextStepCheck(self) then
							self:NextStep(quest.nextStep)
						else
							self:Failed()
						end
					end
				end
			end)
		end

		if quest.timeQuest ~= nil then
			local time = quest.timeQuest

			if quest.timeToNextStep ~= nil then
				time = time + quest.timeToNextStep
			end

			timer.Simple(time, function()
				if IsValid(self) then
					local failedText = quest.failedText or {
						title = 'Quest failed',
						text = 'The execution time has expired.'
					}

					self:NotifyOnlyRegistred(failedText.title, failedText.text)
					self:Failed()
				end
			end)
		end
	end

	return start_result
end

-------------------------------------
-- Starts the next step of the quest.
-------------------------------------
-- @param step string - step id
-------------------------------------
function ENT:NextStep(step)
	local quest = self:GetQuest()
	if quest.isEvent then
		self:SetStep(step)
	else
		local ply = self:GetPlayer()
		if IsValid(ply) then
			ply:SetQuestStep(self:GetQuestId(), step)
		end
	end
end

-------------------------------------
-- DarkRp Only
-------------------------------------
-- Gives registered players a reward, if it is in the quest configuration.
-------------------------------------
-- (Optional) @param customPayment number - set the amount of cash reward
-- (By default, the number is taken from the quest configuration - quest.payment)
-------------------------------------
function ENT:Reward(customPayment)
	if engine.ActiveGamemode() ~= 'darkrp' then return end

	local players = self:GetAllPlayers()
	for _, ply in pairs(players) do
		if ply.addMoney ~= nil then
			local payment = customPayment or self:GetQuest().payment
			if payment ~= nil then
				ply:addMoney(payment)
				DarkRP.notify(ply, 4, 4, 'Ваша награда за выполнение квеста - ' 
					.. DarkRP.formatMoney(payment))
			end
		end
	end
end

-------------------------------------
-- DarkRp Only
-------------------------------------
-- Provides compensation to the player if the quest was interrupted or not completed correctly.
-------------------------------------
-- (Optional) @param customPayment number - set the amount of cash reward
-- (By default, the number from the quest configuration is taken (quest.payment) and divided by two)
-------------------------------------
function ENT:Reparation(customPayment)
	local payment = customPayment or self:GetQuest().payment
	if payment ~= nil then
		self:Reward(payment / 2)
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
	if self:GetQuest().isEvent then
		if SERVER then self:Remove() end
		return
	end

	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/NovaProspekt/al_done01.wav')]])
end

-------------------------------------
-- Called to complete quest and play sound on failure
-------------------------------------
function ENT:Failed()
	if self:GetQuest().isEvent then
		if SERVER then self:Remove() end
		return
	end

	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/k_lab/ba_getoutofsight01.wav')]])
end

-------------------------------------
-- Attempts to force registered NPCs to move to a random registered player.
-------------------------------------
function ENT:MoveEnemyToRandomPlayer()
	local players = self:GetAllPlayers()

	if #players ~= 0 then
		local ply = table.Random(players)

		if IsValid(ply) then
			local player_pos = ply:GetPos()

			for _, data in pairs(self.npcs) do
				if IsValid(data.npc) then
					data.npc:SetSaveValue("m_vecLastPosition", player_pos)
					data.npc:SetSchedule(SCHED_FORCED_GO)
				end
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

	if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then
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
-- (Optional) @param tag string - tag is a unique identifier for an NPC.
-- Can be used to check the state of a specific entity. (Must be unique!)
-------------------------------------
function ENT:AddQuestNPC(npc, type, tag)
	tag = tag or 'none'
	
	table.insert(self.npcs, {
		type = type,
		tag = tag,
		npc = npc
	})

	if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then
		npc:SetCustomCollisionCheck(true)
	end

	if not self:GetNWBool('StopThink') then
		self:SyncNPCs()
	end
end

-------------------------------------
-- Establishes the rules of conduct for registered NPCs for other players or NPCs.
-- If the config parameter - HideQuestsOfOtherPlayers - is not false,
-- then the NPCs will ignore players that do not belong to the quest.
-------------------------------------
-- (Optional) @param ent entity - player or npc entity
-------------------------------------
function ENT:SetNPCsBehavior(ent)
	if table.Count(self.npcs) == 0 then return end

	local npcNotReactionOtherPlayer = self:GetQuest().npcNotReactionOtherPlayer or false

	if QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then
		npcNotReactionOtherPlayer = true
	end

	local function restictionByPlayer(ply)
		for _, data in pairs(self.npcs) do
			if IsValid(data.npc) then
				if table.HasValue(self.players, ply) then
					if data.type == 'enemy' then
						data.npc:AddEntityRelationship(ply, D_HT, 70)
					elseif data.type == 'friend' then
						data.npc:AddEntityRelationship(ply, D_LI, 70)
					end
				else
					if npcNotReactionOtherPlayer then
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
			local isExist = false

			for _, data in pairs(self.npcs) do
				if IsValid(data.npc) and otherNPC == data.npc then
					isExist = true
					break
				end
			end

			if not isExist then
				for _, data in pairs(self.npcs) do
					if IsValid(data.npc) then
						data.npc:AddEntityRelationship(otherNPC, D_NU, 99)
						otherNPC:AddEntityRelationship(data.npc, D_NU, 99)
					end
				end
			end
		end
	end

	if ent ~= nil then
		restictionByOtherNPC(ent)
	else
		for _, ent in pairs(ents.GetAll()) do
			restictionByOtherNPC(ent)
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
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncNoDraw(ply)
	self:TimerCreate(function()
		if table.Count(self.npcs) ~= 0 then
			QuestSystem:Debug('SyncNoDraw NPCs (' .. table.Count(self.npcs) .. ') - ' .. table.ToString(self.npcs))

			net.Start('cl_qsystem_nodraw_npc')
			net.WriteEntity(self)
			if ply then net.Send(ply) else net.Broadcast() end
		end
	end)

	self:TimerCreate(function()
		if table.Count(self.items) ~= 0 then
			QuestSystem:Debug('SyncNoDraw Items (' .. table.Count(self.items) .. ') - ' .. table.ToString(self.items))

			net.Start('cl_qsystem_nodraw_items')
			net.WriteEntity(self)
			if ply then net.Send(ply) else net.Broadcast() end
		end
	end)

	self:TimerCreate(function()
		if table.Count(self.structures) ~= 0 then
			QuestSystem:Debug('SyncNoDraw Structures (' .. table.Count(self.structures) .. ') - ' .. table.ToString(self.structures))

			net.Start('cl_qsystem_nodraw_structures')
			net.WriteEntity(self)
			net.WriteTable(self.structures)
			if ply then net.Send(ply) else net.Broadcast() end
		end
	end)
end

-------------------------------------
-- Synchronizes data on quest items with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncItems(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncItems (' .. table.Count(self.items) .. ') - ' .. table.ToString(self.items))

		net.Start('cl_qsystem_sync_items')
		net.WriteEntity(self)
		net.WriteTable(self.items)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest NPCs with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncNPCs(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncNPCs (' .. table.Count(self.npcs) .. ') - ' .. table.ToString(self.npcs))

		net.Start('cl_qsystem_sync_npcs')
		net.WriteEntity(self)
		net.WriteTable(self.npcs)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data about registered players with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncPlayers(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncPlayers (' .. table.Count(self.players) .. ') - ' .. table.ToString(self.players))

		net.Start('cl_qsystem_sync_players')
		net.WriteEntity(self)
		net.WriteTable(self.players)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest triggers with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncTriggers(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncTriggers (' .. table.Count(self.triggers) .. ') - ' .. table.ToString(self.triggers))

		net.Start('cl_qsystem_sync_triggers')
		net.WriteEntity(self)
		net.WriteTable(self.triggers)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest points with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncPoints(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncPoints (' .. table.Count(self.points) .. ') - ' .. table.ToString(self.points))

		net.Start('cl_qsystem_sync_points')
		net.WriteEntity(self)
		net.WriteTable(self.points)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data about quest variables with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncValues(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncValues (' .. table.Count(self.values) .. ') - ' .. table.ToString(self.values))

		net.Start('cl_qsystem_sync_values')
		net.WriteEntity(self)
		net.WriteTable(self.values)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Synchronizes data on quest weapons with clients.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncWeapons(ply, delay)
	self:TimerCreate(function()
		QuestSystem:Debug('SyncWeapons (' .. table.Count(self.weapons) .. ') - ' .. table.ToString(self.weapons))

		net.Start('cl_qsystem_sync_weapons')
		net.WriteEntity(self)
		net.WriteTable(self.weapons)
		if ply then net.Send(ply) else net.Broadcast() end
	end, delay)
end

-------------------------------------
-- Calls all sync methods in order.
-------------------------------------
-- (Optional) @param ply entity - player entity (Sent to all players by default)
-------------------------------------
function ENT:SyncAll(ply)
	QuestSystem:Debug('Start SyncAll <<<<<<')
	self:SyncPlayers(ply)
	self:SyncTriggers(ply)
	self:SyncPoints(ply)
	self:SyncNPCs(ply)
	self:SyncItems(ply)
	self:SyncValues(ply)
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
-- (Optional) @param lockState string - door state - lock or unlock. (The default is always  - lock)
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
				"func_door",
				"func_door_rotating",
				"prop_door_rotating",
				"func_movelinear",
				"prop_dynamic",
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
-- (Optional) @param type string - if not nil, then all NPCs of this type will be deleted
-- (Optional) @param tag string - if not nil, then all NPCs for this tag will be deleted 
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
-- (Optional) @param item_id string - if not nil, then only the item with this identifier will be deleted
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
