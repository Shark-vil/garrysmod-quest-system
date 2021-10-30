if SERVER then
	local function ActivateRandomEvent(id)
		local event = QuestSystem:GetQuest(id)
		if not event then event = table.Random(QuestSystem:GetAllEvents()) end
		if not event then return end

		local active_event = QuestSystem.activeEvents[event.id]
		if not active_event or not IsValid(active_event) then
			QuestSystem:EnableEvent(event.id)
		end
	end

	scommand.Create('qsystem_activate_event').OnServer(function(ply, cmd, args)
		ActivateRandomEvent(args[1])
	end).AutoComplete(function(cmd, stringargs)
		local tbl = {}
		for id, _ in pairs(QuestSystem:GetAllEvents()) do tbl[ #tbl + 1] = cmd .. ' "' .. id .. '"' end
		return tbl
	end).Access( { isAdmin = true } ).Register()

	local current_time = 0
	hook.Add('Think', 'QSystemActivateRandomEvents', function()
		if #player.GetAll() == 0 then return end

		local delay_time = GetConVar('qsystem_cfg_events_delay'):GetInt()

		if delay_time > 0 then
			if current_time > CurTime() then
				return
			else
				current_time = CurTime() + delay_time
			end
		end

		if not GetConVar('qsystem_cfg_enable_game_events'):GetBool() then return end

		local randNum = GetConVar('qsystem_cfg_events_chance'):GetInt()
		if randNum > 0 and randNum < math.random(1, 100) then return end

		local maxEvents = GetConVar('qsystem_cfg_events_max'):GetInt()
		if table.Count(QuestSystem.activeEvents) > maxEvents then return end

		ActivateRandomEvent()
	end)

	hook.Add('OnEntityCreated', 'QSystem.ReloadingNPCsRestiction', function(npc)
		if npc:IsNPC() then
			for _, ent in ipairs(ents.FindByClass('quest_entity')) do
				if IsValid(ent) then
					ent:SetNPCsBehavior(npc)
				end
			end
		end
	end)
end

hook.Add('DisableEvent', 'QSystem.RemoveEventFromTable', function(eQuest, quest)
	QuestSystem.activeEvents[quest.id] = nil
end)

hook.Add('PostCleanupMap', 'QSystem.PostCleanupMap.ResetGlobalTables', function()
	table.Empty(QuestSystem.Storage.Quests)
	table.Empty(QuestSystem.Storage.Dialogues)
end)

scommand.Create('qsystem_give_quest_from_player').OnServer(function(ply, cmd, args)
	if not QuestSystem:GetQuest(args[2]) then return end

	for _, quester in ipairs(player.GetAll()) do
		if quester:Nick() == args[1] then
			quester:EnableQuest(args[2])
			break
		end
	end
end).AutoComplete(function(cmd, stringargs)
	local autoComplete = {}
	stringargs = string.Trim(stringargs)

	if #string.Trim(stringargs) == 0 then
		for _, quester in ipairs(player.GetAll()) do
			table.insert(autoComplete, cmd .. ' "' .. quester:Nick() .. '"')
		end
	else
		for quest_id, _ in pairs(QuestSystem:GetAllQuests()) do
			table.insert(autoComplete, cmd .. ' ' .. stringargs .. ' "' .. quest_id .. '"')
		end
	end

	return autoComplete
end).Access( { isAdmin = true } ).Register()