if SERVER then
	local function spawn_guild_representative()
		local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'

		if file.Exists(file_path, 'DATA') then
			local data = util.JSONToTable(file.Read(file_path, 'DATA'))

			for _, location in pairs(data) do
				local npc = ents.Create('npc_quest')
				npc:SetPos(location.pos)
				npc:SetAngles(location.ang)
				npc:Spawn()
				npc:Activate()
			end
		end
	end
	hook.Add('PostCleanupMap', 'QSystem.SpawnGuildRepresentative', spawn_guild_representative)
	hook.Add('InitPostEntity', 'QSystem.SpawnGuildRepresentative', spawn_guild_representative)
end

scommand.Create('qsystem_guild_representative_save').OnServer(function()
	local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'
	local npcs = ents.FindByClass('npc_quest')
	local data = {}

	if #npcs ~= 0 then
		for _, npc in pairs(npcs) do
			table.insert(data, {
				pos = npc:GetPos(),
				ang = npc:GetAngles()
			})
		end

		file.Write(file_path, util.TableToJSON(data))
	end
end).Access( { isAdmin = true } ).Register()

scommand.Create('qsystem_guild_representative_clear').OnServer(function()
	local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'

	if file.Exists(file_path, 'DATA') then
		file.Delete(file_path)
	end
end).Access( { isAdmin = true } ).Register()