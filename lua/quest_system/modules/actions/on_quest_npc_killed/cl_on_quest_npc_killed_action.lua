snet.Callback('QSystem.QuestAction.OnQuestNPCKilled', function(_, eQuest, data, attacker, inflictor)
	local step = eQuest:GetQuestStepTable()
	if not step then return end

	local func = step.onQuestNPCKilled
	if not func or not isfunction(func) then return end

	func(eQuest, data, attacker, inflictor)
end).Validator(SNET_ENTITY_VALIDATOR)