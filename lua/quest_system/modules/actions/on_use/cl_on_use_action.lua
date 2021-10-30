snet.Callback('QSystem.QuestAction.OnUse', function(_, eQuest, ply, ent)
	local step = eQuest:GetQuestStepTable()
	if not step.onUse or not isfunction(step.onUse) then return end
	step.onUse(eQuest, ply, ent)
end).Validator(SNET_ENTITY_VALIDATOR)