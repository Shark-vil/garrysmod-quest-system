util.AddNetworkString('cl_qsystem_player_notify')
util.AddNetworkString('cl_qsystem_player_notify_quest_start')

local meta = FindMetaTable('Player')

function meta:SaveQuest(quest_id, step)
	local file_path = 'quest_system/players/' .. self:PlayerId()
	if not file.Exists(file_path, 'DATA') then file.CreateDir(file_path) end

	file_path = file_path .. '/' .. quest_id .. '.json'

	local quest = QuestSystem:GetQuest(quest_id)
	step = step or 'start'

	if quest and quest.steps[step] then
		local data_save = {
			id = quest_id,
			step = step
		}

		file.Write(file_path, util.TableToJSON(data_save))

		return true
	end

	return false
end

function meta:ReadQuest(quest_id)
	local file_path = 'quest_system/players/' .. self:PlayerId() .. '/' .. quest_id .. '.json'
	if file.Exists(file_path, 'DATA') then
		return util.JSONToTable(file.Read(file_path, 'DATA'))
	end

	return nil
end

function meta:ReadAllQuest()
	local file_path = 'quest_system/players/' .. self:PlayerId() .. '/*'
	local quest_files = file.Find(file_path, 'DATA')

	if #quest_files ~= 0 then
		local quests = {}

		for _, filename in pairs(quest_files) do
			local nameAndExt = string.Split(filename, '.')
			local quest = self:ReadQuest(nameAndExt[1])

			if quest ~= nil then
				table.insert(quests, quest)
			end
		end

		return quests
	end

	return {}
end

function meta:GetNumberQuestsActive()
	local file_path = 'quest_system/players/' .. self:PlayerId() .. '/*'
	local quest_files = file.Find(file_path, 'DATA')

	return table.Count(quest_files)
end

function meta:RemoveQuest(quest_id)
	local file_path = 'quest_system/players/' .. self:PlayerId() .. '/' .. quest_id .. '.json'

	if file.Exists(file_path, 'DATA') then
		file.Delete(file_path)
		return true
	end

	return false
end

function meta:QuestIsValid(quest_id)
	local quest = QuestSystem:GetQuest(quest_id)
	if quest.hide or quest.is_event then return false end
	if not QuestSystem:CheckRestiction(self, quest.restriction) then return false end

	if quest.condition ~= nil and not quest.condition(self) then
		return false
	end

	return true
end

function meta:EnableQuest(quest_id)
	local quests_limit = GetConVar('qsystem_cfg_max_quests_for_player'):GetInt()
	local active_quests_count = self:GetNumberQuestsActive()

	if quests_limit > 0 and active_quests_count > quests_limit then
		self:QuestNotify('Отклонено', 'Вы не можете взять больше заданий, пока не выполните текущие.')
		return
	end

	if self:QuestIsActive(quest_id) then return end

	if not QuestSystem:QuestIsValid(self, quest_id) then
		self:RemoveQuest(quest_id)
		return
	end

	local quest = QuestSystem:GetQuest(quest_id)

	if quest ~= nil then
		local quest_data = self:ReadQuest(quest_id)
		local step = 'start'

		if quest_data == nil then
			self:SaveQuest(quest_id)
		else
			step = quest_data.step
		end

		local ent = ents.Create('quest_entity')
		ent:SetQuest(quest_id, self)
		ent:SetPos(self:GetPos())
		ent:Spawn()
		ent:slibFixPVS()
		ent:Activate()

		timer.Simple(1, function()
			if not IsValid(ent) then return end
			-- ent:ForcedTracking()
			ent:SetStep(step)
		end)
	end
end

function meta:EnableAllQuest()
	local quests = self:ReadAllQuest()

	for _, quest_data in ipairs(quests) do
		if quest_data ~= nil then
			if QuestSystem:QuestIsValid(self, quest_data.id) then
				local ent = ents.Create('quest_entity')
				ent:SetQuest(quest_data.id, self)
				ent:SetPos(self:GetPos())
				ent:Spawn()
				ent:slibFixPVS()
				ent:Activate()

				timer.Simple(1, function()
					if not IsValid(ent) then return end
					ent:SetStep(quest_data.step)
				end)
			else
				self:RemoveQuest(quest_data.id)
			end
		end
	end
end

function meta:DisableQuest(quest_id)
	local quest_entity = self:FindQuestEntity(quest_id)

	if IsValid(quest_entity) then
		quest_entity:Remove()
	end
end

function meta:DisableAllQuest()
	local quest_entities = self:FindQuestEntities()

	for _, quest_entity in ipairs(quest_entities) do
		if IsValid(quest_entity) then
			quest_entity:Remove()
		end
	end
end

function meta:SetQuestStep(quest_id, step)
	local quest_data = self:ReadQuest(quest_id)
	if not quest_data then return end

	local is_saved = self:SaveQuest(quest_id, step)
	if not is_saved then return end

	local ent = self:FindQuestEntity(quest_id)
	if not IsValid(ent) then return end

	ent:SetStep(step)
end