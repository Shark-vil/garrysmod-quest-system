snet.Callback('qsystem_on_next_step', function(_, ent, step)
	if not IsValid(ent) then return end

	ent:OnNextStep(step)
	QuestSystem:Debug('Next Step - ' .. step)
end).Validator(SNET_ENTITY_VALIDATOR).Register()