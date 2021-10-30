local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local table_HasValueBySeq = table.HasValueBySeq
local IsValid = IsValid
local LocalPlayer = LocalPlayer

-------------------------------------
-- Removes NPCs sounds if players do not belong to the quest.
-- WARNING:
-- The effectiveness of the hook is questionable. May be removed in the future.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/GM:EntityEmitSound
-------------------------------------
hook.Add('EntityEmitSound', 'QSystem.Service.EntityEmitSound', function(t)
	local ent = t.Entity
	local localplayer = LocalPlayer()
	local npc = NULL

	if ent:IsWeapon() then
		local owner = ent:GetOwner()
		if not owner:IsNPC() and not ent:IsNextBot() then return end
		npc = owner
	elseif ent:IsNPC() or ent:IsNextBot() then
		npc = ent
	else
		return
	end

	for i = 1, #quests do
		local eQuest = quests[i]
		local quest_players = eQuest:GetAllPlayers()

		if table_HasValueBySeq(quest_players, localplayer) then continue end

		local npcs = eQuest.npcs
		local npcs_count = #npcs

		if npcs_count == 0 then continue end

		for k = 1, npcs_count do
			local data = npcs[k]
			local quest_npc = data.npc

			if IsValid(quest_npc) and quest_npc == npc then return false end
		end
	end
end)