local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local snet_InvokeAll = snet.InvokeAll
local IsValid = IsValid
local isfunction = isfunction

hook.Add('OnNPCKilled', 'QSystem.QuestAction.OnQuestNPCKilled', function(npc, attacker, inflictor)
	for i = 1, #quests do
		local eQuest = quests[i]
		local step = eQuest:GetQuestStepTable()

		if not step then continue end

		local func = step.onQuestNPCKilled
		if not func or not isfunction(func) then continue end

		local npcs = eQuest.npcs
		local npcs_count = #npcs

		if npcs_count == 0 then continue end

		for k = 1, npcs_count do
			local data = npcs[k]
			local quest_npc = data.npc
			if IsValid(quest_npc) and quest_npc == npc then
				snet_InvokeAll('QSystem.QuestAction.OnQuestNPCKilled', eQuest, data, attacker, inflictor)
				func(eQuest, data, npc, attacker, inflictor)
				return
			end
		end
	end
end)