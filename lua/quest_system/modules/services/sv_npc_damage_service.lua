local QuestSystem = QuestSystem
local quests = QuestSystem.Storage.Quests
local table_HasValueBySeq = table.HasValueBySeq
local IsValid = IsValid

-------------------------------------
-- Disables player damage to NPCs if players do not belong to the quest, and vice versa.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/GM:EntityTakeDamage
-------------------------------------
hook.Add('EntityTakeDamage', 'QSystem.Service.EntityTakeDamage', function(target, dmginfo)
	if not GetConVar('qsystem_cfg_hide_quests_of_other_players'):GetBool() then return end

	local attacker = dmginfo:GetAttacker()
	if attacker:IsWeapon() then attacker = attacker.Owner end

	if not IsValid(attacker) then return end

	for i = 1, #quests do
		local quest = quests[i]
		local npcs = quest.npcs
		local npcs_count = #npcs

		if npcs_count == 0 then return end

		if target:IsNPC() and attacker:IsPlayer() then
			for k = 1, npcs_count do
				local data = npcs[k]
				local npc = data.npc
				if IsValid(npc) and npc == target and not table_HasValueBySeq(quest.players, attacker) then
					return true
				end
			end
		end

		if target:IsPlayer() and (attacker:IsNPC() or attacker:IsNextBot()) then
			for k = 1, npcs_count do
				local data = npcs[k]
				local npc = data.npc
				if IsValid(npc) and npc == attacker and not table_HasValueBySeq(quest.players, target) then
					return true
				end
			end
		end
	end
end)