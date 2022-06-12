if SERVER then
	util.AddNetworkString('qsystem_add_structure_from_client')
	util.AddNetworkString('qsystem_remove_structure_from_client')
	util.AddNetworkString('qsystem_remove_all_structure_from_client')
end

local string_EndsWith = string.EndsWith

-- List of registered storages (Not to be confused with a pattern)
QuestSystem.storage = QuestSystem.storage or {}
-- List of currently active events
QuestSystem.activeEvents = QuestSystem.activeEvents or {}
-- List of currently active game structures
QuestSystem.structures = QuestSystem.structures or {}
QuestSystem.debug_index = 0

function QuestSystem:CallTableSSC(table_object, field_name, ...)
	if not table_object or not istable(table_object) then return end
	if not field_name or not isstring(field_name) then return end
	if string_EndsWith(field_name, 'Server') or string_EndsWith(field_name, 'Client') then return end

	local basic_result, server_result, client_result

	if isfunction(table_object[field_name]) then
		basic_result = table_object[field_name](...)
	end

	if SERVER and isfunction(table_object[field_name .. 'Server']) then
		server_result = table_object[field_name .. 'Server'](...)
	end

	if CLIENT and isfunction(table_object[field_name .. 'Client']) then
		client_result = table_object[field_name .. 'Client'](...)
	end

	if basic_result or server_result or client_result then
		return {
			basic = basic_result,
			server = server_result,
			client = client_result,
		}
	end
end

-------------------------------------
-- Creates an entity for a global game event.
-------------------------------------
-- @param event_id string - game event id
-- @param step string - game event step (Default - start)
-------------------------------------
-- @return entity - will return the created entity or NULL on failure
-------------------------------------
function QuestSystem:EnableEvent(event_id, step)
	local players = player.GetAll()
	if #players == 0 then return end

	local playerTarget = table.RandomBySeq(players)
	local allQuests = ents.FindByClass('quest_entity')

	for _, ent in pairs(allQuests) do
		if ent:GetQuestId() == event_id then return end
	end

	local event = QuestSystem:GetQuest(event_id)
	step = step or 'start'

	if event ~= nil and event.steps[step] ~= nil then
		local eQuest = ents.Create('quest_entity')
		eQuest:SetPos(playerTarget:GetPos())
		eQuest:SetQuest(event_id)
		eQuest:Spawn()
		eQuest:Activate()
		eQuest:slibFixPVS()

		if event.auto_add_players then
			for _, ply in ipairs(players) do
				eQuest:AddPlayer(ply)
			end
		end

		timer.Simple(1, function()
			if not IsValid(eQuest) then return end
			eQuest:SetStep(step)
		end)

		QuestSystem.activeEvents[event_id] = eQuest

		return eQuest
	end

	return NULL
end

-------------------------------------
-- Removes the game event entity, if it exists.
-------------------------------------
-- @param event_id string - game event id
-------------------------------------
function QuestSystem:DisableEvent(event_id)
	local allQuests = ents.FindByClass('quest_entity')

	for _, ent in pairs(allQuests) do
		if IsValid(ent) and ent:GetQuestId() == event_id then
			ent:Remove()
			return
		end
	end
end

-------------------------------------
-- Get a list of all registered events.
-------------------------------------
-- @return table - list of registered game events
-------------------------------------
function QuestSystem:GetAllEvents()
	local all_events = {}

	for quest_id, quest in pairs(list.Get('QuestSystem')) do
		if quest.is_event then
			all_events[quest_id] = quest
		end
	end

	return all_events
end

-------------------------------------
-- Adds storage to the table list.
-------------------------------------
-- @param storage_id string - custom storage id
-- @param data_table table - storage table
-------------------------------------
function QuestSystem:SetStorage(storage_id, data_table)
	self.storage[storage_id] = data_table
end

-------------------------------------
-- Get the storage table.
-------------------------------------
-- @param storage_id string - storage id
-------------------------------------
-- @return table - will return the storage data table or nil
-------------------------------------
function QuestSystem:GetStorage(storage_id)
	return self.storage[storage_id]
end

-------------------------------------
-- Get quest data from the list by identifier.
-------------------------------------
-- @param quest_id string - quest id
-------------------------------------
-- @return table - will return the quest data table or nil
-------------------------------------
function QuestSystem:GetQuest(quest_id)
	local quest_data = list.Get('QuestSystem')[quest_id]
	if not quest_data then return end

	local quest = table.Copy(quest_data)
	if CLIENT and quest and quest.lang then
		for key, text in pairs(quest) do
			if isstring(text) then
				local player_lang = LocalPlayer():slibGetLanguage()
				if quest.lang[player_lang] and quest.lang[player_lang][text] then
					quest[key] = quest.lang[player_lang][text]
				elseif quest.lang['default'] and quest.lang['default'][text] then
					quest[key] = quest.lang['default'][text]
				end
			end
		end
	end

	return quest
end

-------------------------------------
-- Get a list of all registered quests.
-------------------------------------
-- @return table - list of registered quests
-------------------------------------
function QuestSystem:GetAllQuests()
	local quests = {}
	for quest_id, _ in pairs(list.Get('QuestSystem')) do
		quests[quest_id] = QuestSystem:GetQuest(quest_id)
	end
	return quests
end

-------------------------------------
-- Prints a stylized message to the console.
-------------------------------------
-- @param message any - custom message
-------------------------------------
function QuestSystem:ConsoleAlert(message)
	MsgN('[QSystem][ALER] ' .. tostring(message))
end

-------------------------------------
-- Prints a stylized chat message for all administrators on the server, with an audio alert playing.
-- Also calls - QuestSystem:ConsoleAlert(message).
-------------------------------------
-- @param message any - custom message
-------------------------------------
function QuestSystem:AdminAlert(message)
	self:ConsoleAlert(message)
	local script = 'surface.PlaySound("common/warning.wav");chat.AddText(Color(255,10,10), "[QSystem][ALER] ' .. message .. '")'

	for _, ply in pairs(player.GetHumans()) do
		if ply:IsAdmin() or ply:IsSuperAdmin() then
			local lastMessageTime = ply.qSystemLastMessageTime or 0

			if lastMessageTime < SysTime() then
				ply:SendLua(script)
				ply.qSystemLastMessageTime = SysTime() + 0.1
			end
		end
	end
end

-------------------------------------
-- Receives data from config by key.
-------------------------------------
-- @param ply entity - player entity
-- @param restiction table - quest restrictions table
-------------------------------------
-- @return any - will return true if all checks are successful, otherwise false
-------------------------------------
function QuestSystem:CheckRestiction(ply, restiction)
	if restiction ~= nil then
		local team = restiction.team

		if team ~= nil then
			local pTeam = ply:Team()

			if isstring(team) then
				if team ~= pTeam then return false end
			elseif istable(team) then
				if not table.HasValue(team, pTeam) then return false end
			end
		end

		local steamid = restiction.steamid

		if steamid ~= nil then
			local pSteamID = ply:SteamID()
			local pSteamID64 = ply:SteamID64()

			if isstring(steamid) then
				if steamid ~= pSteamID and steamid ~= pSteamID64 then return false end
			elseif istable(steamid) then
				if not table.HasValue(steamid, pSteamID) and not table.HasValue(steamid, pSteamID64) then return false end
			end
		end

		local nick = restiction.nick

		if nick ~= nil then
			local pNick = ply:Nick():lower()

			if isstring(nick) then
				if nick:lower() ~= pNick then return false end
			elseif istable(nick) then
				local done = false

				for _, nickValue in pairs(nick) do
					if nickValue:lower() == pNick then
						done = true
						break
					end
				end

				if not done then return false end
			end
		end

		local usergroup = restiction.usergroup

		if usergroup ~= nil then
			local pUserGroup = ply:GetUserGroup():lower()

			if isstring(usergroup) then
				if usergroup:lower() ~= pUserGroup then return false end
			elseif istable(usergroup) then
				local done = false

				for _, usergroupValue in pairs(usergroup) do
					if string.find(usergroupValue:lower(), pUserGroup) ~= nil then
						done = true
						break
					end
				end

				if not done then return false end
			end
		end

		if restiction.adminOnly ~= nil and not ply:IsAdmin() and not ply:IsSuperAdmin() then return false end
	end

	return true
end

if SERVER then
	-------------------------------------
	-- Creates the game structure of the quest on the map.
	-------------------------------------
	-- @param quest_id string - quest id
	-- @param structure_name string - structure id
	-------------------------------------
	-- Note: The spawn ID is used when deleting a structure.
	-- @return string - will return the unique identifier of the created structure or nil
	-------------------------------------
	function QuestSystem:SpawnStructure(quest_id, structure_name)
		local data = QuestSystem:GetStorage('structure'):Read(quest_id, structure_name)

		if data ~= nil then
			local spawn_id = quest_id .. '_' .. string.Replace(SysTime(), '.', '')
			QuestSystem.structures[spawn_id] = {}

			for id, prop in pairs(data.Props) do
				local ent = ents.Create(prop.class)
				ent:SetModel(prop.model)
				ent:SetPos(prop.pos)
				ent:SetAngles(prop.ang)
				ent:SetColor(prop.color)
				ent:SetMaterial(prop.material)
				ent:Spawn()
				ent:Activate()
				ent:SetCustomCollisionCheck(true)
				local phys = ent:GetPhysicsObject()

				if IsValid(phys) then
					phys:EnableMotion(false)
				end

				table.insert(QuestSystem.structures[spawn_id], ent)
			end

			if QuestSystem.structures[spawn_id] ~= nil then
				local ids = {}

				for _, ent in pairs(QuestSystem.structures[spawn_id]) do
					if IsValid(ent) then
						table.insert(ids, ent:EntIndex())
					end
				end

				net.Start('qsystem_add_structure_from_client')
				net.WriteString(spawn_id)
				net.WriteTable(ids)
				net.Broadcast()
			end

			return spawn_id
		end

		return nil
	end

	-------------------------------------
	-- Removes quest structures from the map if they exist.
	-------------------------------------
	-- @param spawn_id string - unique identifier of the structure spawn
	-------------------------------------
	function QuestSystem:RemoveStructure(spawn_id)
		if QuestSystem.structures[spawn_id] ~= nil then
			for _, ent in pairs(QuestSystem.structures[spawn_id]) do
				if IsValid(ent) then
					ent:FadeRemove()
				end
			end

			QuestSystem.structures[spawn_id] = nil
			net.Start('qsystem_remove_structure_from_client')
			net.WriteString(spawn_id)
			net.Broadcast()
		end
	end

	-------------------------------------
	-- Removes all existing structures on the map.
	-------------------------------------
	function QuestSystem:RemoveAllStructure()
		for spawn_id, data in pairs(QuestSystem.structures) do
			for _, ent in pairs(data) do
				if IsValid(ent) then
					ent:FadeRemove()
				end
			end
		end

		net.Start('qsystem_remove_all_structure_from_client')
		net.Broadcast()
	end
else
	-------------------------------------
	-- Called on the client after being called - QuestSystem:SpawnStructure.
	-- Adds the spawn identifier of the structure on the client and any entities that are created.
	-------------------------------------
	net.Receive('qsystem_add_structure_from_client', function()
		local spawn_id = net.ReadString()
		local ids = net.ReadTable()
		QuestSystem.structures[spawn_id] = {}

		timer.Simple(0.3, function()
			for _, id in pairs(ids) do
				local ent = Entity(id)

				if IsValid(ent) then
					table.insert(QuestSystem.structures[spawn_id], ent)
				end
			end
		end)
	end)

	-------------------------------------
	-- Called on the client after being called - QuestSystem:RemoveStructure.
	-- Removes the spawn identifier of the structure on the client.
	-------------------------------------
	net.Receive('qsystem_remove_structure_from_client', function()
		local spawn_id = net.ReadString()
		QuestSystem.structures[spawn_id] = nil
	end)

	-------------------------------------
	-- Called on the client after being called - QuestSystem:RemoveAllStructure.
	-- Clears the spawn ID table of structures on the client.
	-------------------------------------
	net.Receive('qsystem_remove_all_structure_from_client', function()
		QuestSystem.structures = {}
	end)
end

-------------------------------------
-- Gets a list of created entities by structure spawn id.
-------------------------------------
-- @param spawn_id string - unique identifier of the structure spawn
-------------------------------------
-- @return table - will return a list of entities or nil
-------------------------------------
function QuestSystem:GetStructure(spawn_id)
	return QuestSystem.structures[spawn_id]
end

-------------------------------------
-- Gets a list with all registered structures.
-------------------------------------
-- @return table - will return a list of entities
-------------------------------------
function QuestSystem:GetAllStructure()
	return QuestSystem.structures
end

-------------------------------------
-- Checks the availability of the quest for the player.
-------------------------------------
-- @param ply entity - player entity
-- @param quest_id string - quest id
-------------------------------------
-- @return bool - will return true if all checks succeed, otherwise false
-------------------------------------
function QuestSystem:QuestIsValid(ply, quest_id)
	local quest = QuestSystem:GetQuest(quest_id)
	if quest.is_event then return false end
	if not QuestSystem:CheckRestiction(ply, quest.restriction) then return false end
	if quest.condition ~= nil and not quest.condition(ply) then return false end
	local anyCondition = hook.Run('QSystem.QuestCondition', ply, quest_id)
	if anyCondition ~= nil and isbool(anyCondition) and anyCondition == false then return false end

	return true
end

-------------------------------------
-- Prints a stylized message to the console if developer mode is active.
-------------------------------------
-- @param msg any - custom message
-------------------------------------
function QuestSystem:Debug(msg)
	if not GetConVar('qsystem_cfg_debug_mode'):GetBool() then return end
	MsgN('[QSystem Debug][' .. tostring(self.debug_index) .. '] ' .. tostring(msg))
	self.debug_index = self.debug_index + 1
end

function QuestSystem:IsExistsQuest(quest_id)
	for _, eQuest in ipairs(ents.FindByClass('quest_entity')) do
		if eQuest:GetQuest().id == quest_id then
			return true
		end
	end

	return false
end

if CLIENT then
	local TrackingQuest

	function QuestSystem:SetQuestTracking(eQuest)
		if not IsValid(eQuest) or eQuest:GetClass() ~= 'quest_entity' then
			TrackingQuest = nil
			return
		end
		TrackingQuest = eQuest
		return TrackingQuest
	end

	function QuestSystem:GetQuestTracking()
		return TrackingQuest
	end
end