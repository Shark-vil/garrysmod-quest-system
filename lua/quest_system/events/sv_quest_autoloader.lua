hook.Add('SlibPlayerFirstSpawn', 'QSystem.QuestsAutoLoader', function(ply)
	local delay = GetConVar('qsystem_cfg_delay_between_quests'):GetInt()

	if delay > 0 then
		local file_path = 'quest_system/players_data/' .. ply:PlayerId() .. '/delay.json'

		if file.Exists(file_path, 'DATA') then
			local current_delay = file.Read(file_path, 'DATA')
			ply:SetNWFloat('quest_delay', tonumber(current_delay, 10))
		end
	end

	ply:EnableAllQuest()

	for _, ent in ipairs(ents.FindByClass('quest_entity')) do
		if IsValid(ent) and not table.HasValue(ent.players, ply) then
			ent:SyncAll(ply)
		end
	end
end)

hook.Add('PostCleanupMap', 'QSystem.QuestsAutoLoader', function()
	timer.Create('PostCleanupMap.QSystem.QuestsAutoLoader', 1, 1, function()
		for _, ply in ipairs(player.GetHumans()) do
			if IsValid(ply) then
				ply:EnableAllQuest()
			end
		end
	end)
end)