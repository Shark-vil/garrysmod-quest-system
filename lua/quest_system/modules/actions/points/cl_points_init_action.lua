snet.Callback('QSystem.QuestAction.InitPoints', function(_, eQuest)
	if not eQuest.points then return end
	local quest = eQuest:GetQuest()

	local steps = quest.steps
	if not steps then return end

	for i = 1, #eQuest.points do
		local data = eQuest.points[i]
		local step = quest.steps[data.step]

		if not step or not step.points or not step.points[data.name] then continue end

		local func = step.points[data.name]
		if not func or not isfunction(func) then continue end

		func(eQuest, data.points)
	end
end).Validator(SNET_ENTITY_VALIDATOR)