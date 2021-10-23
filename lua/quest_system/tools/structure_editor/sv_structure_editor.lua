local weapon_class = 'weapon_quest_structure_tool'

util.AddNetworkString('sv_qsystem_open_structure_editor')
util.AddNetworkString('cl_qsystem_open_structure_editor')
util.AddNetworkString('sv_qsystem_close_structure_editor')
util.AddNetworkString('sv_qsystem_structure_spawn')
util.AddNetworkString('sv_qsystem_structure_remove')

net.Receive('sv_qsystem_open_structure_editor', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end
	ply:Give(weapon_class)
	ply:SelectWeapon(weapon_class)
	net.Start('cl_qsystem_open_structure_editor')
	net.Send(ply)
end)

net.Receive('sv_qsystem_close_structure_editor', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end

	if ply:HasWeapon(weapon_class) then
		ply:StripWeapon(weapon_class)
	end
end)

net.Receive('sv_qsystem_structure_spawn', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end
	local quest_id = net.ReadString()
	local structure_name = net.ReadString()
	local spawn_id = QuestSystem:SpawnStructure(quest_id, structure_name)
	snet.Invoke('spawn_structure_editor', ply, spawn_id)
end)

net.Receive('sv_qsystem_structure_remove', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end
	local spawn_id = net.ReadString()
	QuestSystem:RemoveStructure(spawn_id)
end)