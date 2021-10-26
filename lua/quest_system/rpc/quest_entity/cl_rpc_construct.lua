snet.Callback('qsystem_on_construct', function(_, ent, quest_id, step)
	if not IsValid(ent) then return end

	local quest = QuestSystem:GetQuest(quest_id)
	if not quest then return end

	if step == 'start' then
		if quest.isEvent then
			quest.title = '[Событие] ' .. quest.title
		end

		if quest.timeToNextStep and quest.nextStep then
			quest.description = quest.description .. '\nДо начала: ' .. quest.timeToNextStep .. ' сек.'
		end

		if quest.timeQuest then
			quest.description = quest.description .. '\nВремя выполнения: ' .. quest.timeQuest .. ' сек.'
		end

		if quest.isEvent then
			hook.Run('QSystem.EventStarted', ent, quest)
		else
			hook.Run('QSystem.QuestStarted', ent, quest)
		end
	end

	if quest and quest.steps and quest.steps[step] and quest.steps[step].construct then
		quest.steps[step].construct(ent)
	end
end).Validator(SNET_ENTITY_VALIDATOR)