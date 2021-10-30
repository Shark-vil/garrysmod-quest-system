local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local snet_InvokeAll = snet.InvokeAll
local table_HasValueBySeq = table.HasValueBySeq

-------------------------------------
-- Calls a step function - onUse - when press E on any (almost) entity.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/GM:PlayerUse
-------------------------------------
hook.Add('PlayerUse', 'QSystem.System.PlayerUse', function(ply, ent)
	for i = 1, #quests do
		local eQuest = quests[i]

		local step = eQuest:GetQuestStepTable()
		if not step or not step.onUse or not isfunction(step.onUse) then continue end
		if not table_HasValueBySeq(eQuest.players, ply) then continue end

		snet_InvokeAll('QSystem.QuestAction.OnUse', eQuest, ply, ent)
		step.onUse(eQuest, ply, ent)
	end
end)