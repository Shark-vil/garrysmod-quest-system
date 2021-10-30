local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local table_HasValueBySeq = table.HasValueBySeq
local pairs = pairs
local IsValid = IsValid

-------------------------------------
-- Disable collision with quest objects for players not belonging to the quest.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/GM:ShouldCollide
-------------------------------------
hook.Add('ShouldCollide', 'QSystem.Service.ShouldCollide', function(ent, ply)
	if not GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then return end
	if not ply:IsPlayer() then return end

	for i = 1, #quests do
		local quest = quests[i]

		if table_HasValueBySeq(quest.players, ply) then continue end

		local structures = quest.structures
		for id, spawn_id in pairs(structures) do
			local props = QuestSystem:GetStructure(spawn_id)
			if table_HasValueBySeq(props, ent) then return false end
		end

		local items = quest.items
		for k = 1, #items do
			local data = items[k]
			local item = data.item
			if IsValid(item) and item:GetCustomCollisionCheck() and ent == item then return false end
		end

		local npcs = quest.npcs
		for k = 1, #npcs do
			local data = npcs[k]
			local npc = data.npc
			if IsValid(npc) and npc:GetCustomCollisionCheck() and ent == npc then return false end
		end
	end
end)