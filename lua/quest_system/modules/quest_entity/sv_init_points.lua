hook.Add('QSystem.PreSetStep', 'QSystem.QuestEntity.InitPoints', function(eQuest, quest, step)
	for i = #eQuest.points, 1, -1 do
		if not eQuest.points[i].global then
			table.remove(eQuest.points, i)
		end
	end

	if not quest.steps[step] or not quest.steps[step].points then return end

	local quest_points = quest.steps[step].points

	for point_name, _ in pairs(quest_points) do
		for _, past_point_data in ipairs(eQuest.points) do
			if point_name == past_point_data.name and past_point_data.global then
				goto skip
			end
		end

		local file_path = 'quest_system/points/' ..
			quest.id .. '/' .. game.GetMap() .. '/' .. point_name .. '.json'

		if file.Exists(file_path, 'DATA') then
			table.insert(eQuest.points, {
				name = point_name,
				points = util.JSONToTable(file.Read(file_path, 'DATA')),
				global = string.EndsWith(string.lower(point_name), 'global'),
				step = step
			})
		end

		::skip::
	end

	eQuest:SyncPoints()
end)