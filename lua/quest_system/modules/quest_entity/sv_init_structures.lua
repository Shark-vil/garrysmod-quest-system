hook.Add('QSystem.PreSetStep', 'QSystem.QuestEntity.InitStructures', function(eQuest, quest, step)
	if not quest.steps[step] or not quest.steps[step].structures then return end

	local quest_structures = quest.steps[step].structures

	for structure_id, method in pairs(quest_structures) do
		local spawn_id = QuestSystem:SpawnStructure(quest.id, structure_id)
		if not spawn_id then continue end

		eQuest.structures[structure_id] = spawn_id

		if isfunction(method) then
			method(eQuest, QuestSystem:GetStructure(spawn_id), spawn_id)
		end
	end

	eQuest:SyncStructures()
end)