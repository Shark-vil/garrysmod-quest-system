snet.Callback('QSystem.QuestAction.OnUseItem', function(_, item, activator, caller, useType, value)
	local eQuest = item:GetQuestEntity()
	if not eQuest or not IsValid(eQuest) then return end

	local quest = eQuest:GetQuest()
	local step = eQuest:GetQuestStep()
	if not quest or not step then return end
	if not quest.steps or not quest.steps[step] then return end

	local func = quest.steps[step].onUseItem
	if not func or not isfunction(func) then return end

	func(eQuest, item, activator, caller, useType, value)
end).Validator(SNET_ENTITY_VALIDATOR)