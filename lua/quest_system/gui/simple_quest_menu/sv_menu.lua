util.AddNetworkString('sv_qsystem_startquest')
util.AddNetworkString('sv_qsystem_stopquest')
util.AddNetworkString('cl_qsystem_set_quest_tracking')

local language_data = {
	['default'] = {
		['reject_title'] = 'Rejected',
		['reject_description'] = 'You can take a new quest only after {time} sec.',
	},
	['russian'] = {
		['reject_title'] = 'Отклонено',
		['reject_description'] = 'Вы сможете взять новое задание только через {time} сек.',
	}
}

net.Receive('sv_qsystem_startquest', function(len, ply)
	if ply:QSystemIsSpam() then
		QuestSystem:AdminAlert('Spam was detected in the network from the player - ' .. ply:Nick())
		return
	end

	local id = net.ReadString()
	if not QuestSystem:QuestIsValid(ply, id) then return end
	local delay = QuestSystem:GetConfig('DelayBetweenQuests')

	if delay > 0 then
		local current_delay = ply:GetNWFloat('quest_delay')

		if current_delay > os.time() then
			local delay_math = current_delay - os.time()
			local lang = ply:slibLanguage(language_data)
			ply:QuestNotify(lang['reject_title'],
				string.Replace(lang['reject_description'], '{time}', delay_math))
			return
		else
			local file_path = 'quest_system/players_data/' .. ply:PlayerId()

			if not file.Exists(file_path, 'DATA') then
				file.CreateDir(file_path)
			end

			file_path = file_path .. '/delay.json'
			current_delay = os.time() + delay

			ply:SetNWFloat('quest_delay', current_delay)
			file.Write(file_path, current_delay)
		end
	end

	ply:SaveQuest(id)
	ply:EnableQuest(id)
end)

net.Receive('sv_qsystem_stopquest', function(len, ply)
	if ply:QSystemIsSpam() then
		QuestSystem:AdminAlert('Spam was detected in the network from the player - ' .. ply:Nick())
		return
	end

	local id = net.ReadString()
	ply:DisableQuest(id)
	ply:RemoveQuest(id)
end)