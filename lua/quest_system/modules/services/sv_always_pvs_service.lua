local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local dialogues = QuestSystem.Storage.Dialogues

hook.Add('SetupPlayerVisibility', 'QSystem.Service.AlwaysPVS', function(pPlayer, pViewEntity)
	for i = #quests, 1, -1 do
		local eQuest = quests[i]
		if IsValid(eQuest) then AddOriginToPVS(eQuest:GetPos()) end
	end

	for i = #dialogues, 1, -1 do
		local eDialogue = dialogues[i]
		if IsValid(eDialogue) then
			local dialogue_npc = eDialogue:GetNPC()
			if IsValid(dialogue_npc) then
				AddOriginToPVS(dialogue_npc:GetPos())
			end
			AddOriginToPVS(eDialogue:GetPos())
		end
	end
end)