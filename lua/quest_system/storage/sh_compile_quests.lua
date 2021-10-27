local function compile(quest_id)
	local current_map_name = game.GetMap()
	local point_dir_path = 'quest_system/points/' .. quest_id .. '/'
	local _, points_maps = file.Find(point_dir_path .. '*', 'DATA')
	local all_points = {}
	local all_triggers = {}
	local all_structure = {}

	for _, map_name in pairs(points_maps) do
		if current_map_name == map_name then
			local points_map_path = point_dir_path .. map_name .. '/'
			local point_files = file.Find(points_map_path .. '*', 'DATA')

			for _, file_name in pairs(point_files) do
				local full_file_path = points_map_path .. file_name
				local points_name = string.Split(file_name, '.')[1]
				all_points[points_name] = all_points[points_name] or {}
				all_points[points_name][map_name] = util.JSONToTable(file.Read(full_file_path, "DATA"))
			end

			break
		end
	end

	local triggers_dir_path = 'quest_system/triggers/' .. quest_id .. '/'
	local _, triggers_maps = file.Find(triggers_dir_path .. '*', 'DATA')

	for _, map_name in pairs(triggers_maps) do
		if current_map_name == map_name then
			local triggers_map_path = triggers_dir_path .. map_name .. '/'
			local triggers_files = file.Find(triggers_map_path .. '*', 'DATA')

			for _, file_name in pairs(triggers_files) do
				local full_file_path = triggers_map_path .. file_name
				local trigger_name = string.Split(file_name, '.')[1]
				all_triggers[trigger_name] = all_triggers[trigger_name] or {}
				all_triggers[trigger_name][map_name] = util.JSONToTable(file.Read(full_file_path, "DATA"))
			end

			break
		end
	end

	local structure_dir_path = 'quest_system/structure/' .. quest_id .. '/'
	local _, structure_maps = file.Find(structure_dir_path .. '*', 'DATA')

	for _, map_name in pairs(structure_maps) do
		if current_map_name == map_name then
			local structure_map_path = structure_dir_path .. map_name .. '/'
			local structure_files = file.Find(structure_map_path .. '*', 'DATA')

			for _, file_name in pairs(structure_files) do
				local full_file_path = structure_map_path .. file_name
				local structure_name = string.Split(file_name, '.')[1]
				all_structure[structure_name] = all_structure[structure_name] or {}
				all_structure[structure_name][map_name] = util.JSONToTable(file.Read(full_file_path, "DATA"))
			end

			break
		end
	end

	local create_files = "file.CreateDir('quest_system/');"
	create_files = create_files .. "file.CreateDir('quest_system/points/');"
	create_files = create_files .. "file.CreateDir('quest_system/points/" .. quest_id .. "/');"

	for points_name, map_data in pairs(all_points) do
		for map_name, data in pairs(map_data) do
			if current_map_name == map_name then
				create_files = create_files .. "file.CreateDir('quest_system/points/" .. quest_id .. "/" .. map_name .. "/');"
				local json = util.TableToJSON(data)
				create_files = create_files .. "file.Write('quest_system/points/" .. quest_id .. "/" .. map_name .. "/" .. points_name .. ".json', '" .. json .. "');"

				break
			end
		end
	end

	create_files = create_files .. "file.CreateDir('quest_system/triggers/');"
	create_files = create_files .. "file.CreateDir('quest_system/triggers/" .. quest_id .. "/');"

	for trigger_name, map_data in pairs(all_triggers) do
		create_files = create_files .. "file.CreateDir('quest_system/triggers/" .. quest_id .. "/');"

		for map_name, data in pairs(map_data) do
			if current_map_name == map_name then
				create_files = create_files .. "file.CreateDir('quest_system/triggers/" .. quest_id .. "/" .. map_name .. "/');"
				local json = util.TableToJSON(data)
				create_files = create_files .. "file.Write('quest_system/triggers/" .. quest_id .. "/" .. map_name .. "/" .. trigger_name .. ".json', '" .. json .. "');"

				break
			end
		end
	end

	create_files = create_files .. "file.CreateDir('quest_system/structure/');"
	create_files = create_files .. "file.CreateDir('quest_system/structure/" .. quest_id .. "/');"

	for structure_name, map_data in pairs(all_structure) do
		create_files = create_files .. "file.CreateDir('quest_system/structure/" .. quest_id .. "/');"

		for map_name, data in pairs(map_data) do
			if current_map_name == map_name then
				create_files = create_files .. "file.CreateDir('quest_system/structure/" .. quest_id .. "/" .. map_name .. "/');"
				local json = util.TableToJSON(data)
				create_files = create_files .. "file.Write('quest_system/structure/" .. quest_id .. "/" .. map_name .. "/" .. structure_name .. ".json', '" .. json .. "');"

				break
			end
		end
	end

	return 'quest_system/compile/' .. quest_id .. '_' .. game.GetMap() .. '.txt', create_files
end

scommand.Create('qsystem_compile_quests').OnServer(function(ply, cmd, args)
	local quest_id = args[1]
	if not quest_id or not QuestSystem:GetQuest(quest_id) then return end
	local file_path, file_content = compile(quest_id)
	file.Write(file_path, file_content)
end).AutoComplete(function(cmd, args)
	local autoComplete = {}

	for quest_id, quest in pairs(QuestSystem:GetAllQuests()) do
		local point_dir_path = 'quest_system/points/' .. quest_id .. '/'
		local triggers_dir_path = 'quest_system/triggers/' .. quest_id .. '/'
		local structure_dir_path = 'quest_system/structure/' .. quest_id .. '/'

		if file.Exists(point_dir_path, 'DATA') or file.Exists(triggers_dir_path, 'DATA') or file.Exists(structure_dir_path, 'DATA') then
			table.insert(autoComplete, cmd .. ' ' .. quest_id)
		end
	end

	return autoComplete
end).Access( { isAdmin = true } ).Register()

scommand.Create('qsystem_compile_all_quests').OnServer(function(ply, cmd, args)
	local file_path =  'quest_system/compile/allow_' .. game.GetMap() .. '.txt'
	local file_content = ''

	for _, quest in pairs(QuestSystem:GetAllQuests()) do
		if quest.id then
			local _, _file_content = compile(quest.id)
			file_content = file_content .. ' ' .. _file_content
		end
	end

	if file_content ~= '' then
		file.Write(file_path, file_content)
	end
end).Access( { isAdmin = true } ).Register()