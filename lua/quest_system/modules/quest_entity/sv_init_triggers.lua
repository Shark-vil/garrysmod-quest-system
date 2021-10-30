hook.Add('QSystem.PreSetStep', 'QSystem.QuestEntity.InitTriggers', function(eQuest, quest, step)
	for i = #eQuest.triggers, 1, -1 do
		if not eQuest.triggers[i].global then
			table.remove(eQuest.triggers, i)
		end
	end

	if not quest.steps[step] or not quest.steps[step].triggers then return end

	local quest_triggers = quest.steps[step].triggers

	for trigger_name, trigger_data in pairs(quest_triggers) do
		for _, past_trigger_data in ipairs(eQuest.triggers) do
			if trigger_data.name == past_trigger_data.name and past_trigger_data.global then
				goto skip
			end
		end

		local file_path = 'quest_system/triggers/' ..
			quest.id .. '/' .. game.GetMap() .. '/' .. trigger_name .. '.json'

		if file.Exists(file_path, 'DATA') then
			table.insert(eQuest.triggers, {
				name = trigger_name,
				trigger = util.JSONToTable(file.Read(file_path, 'DATA')),
				global = string.EndsWith(string.lower(trigger_name), 'global'),
				step = step
			})
		end

		::skip::
	end

	eQuest:SyncTriggers()
end)