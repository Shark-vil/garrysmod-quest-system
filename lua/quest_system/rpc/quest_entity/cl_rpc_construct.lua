snet.Callback('qsystem_on_construct', function(_, ent, quest_id, step)
	if not IsValid(ent) then return end

	local quest = QuestSystem:GetQuest(quest_id)
	if not quest then return end

	if step == 'start' then
		if quest.is_event then
			quest.title = '[Событие] ' .. quest.title
		end

		if quest.auto_next_step_delay and quest.auto_next_step then
			quest.description = quest.description .. '\nДо начала: ' .. quest.auto_next_step_delay .. ' сек.'
		end

		if quest.quest_time then
			quest.description = quest.description .. '\nВремя выполнения: ' .. quest.quest_time .. ' сек.'
		end

		if quest.is_event then
			hook.Run('QSystem.EventStarted', ent, quest)
		else
			hook.Run('QSystem.QuestStarted', ent, quest)
		end
	end

	if quest and quest.steps and quest.steps[step] and quest.steps[step].onStart then
		quest.steps[step].onStart(ent)
	end
end).Validator(SNET_ENTITY_VALIDATOR)