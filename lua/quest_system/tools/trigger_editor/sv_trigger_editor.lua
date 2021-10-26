local weapon_class = 'weapon_quest_system_tool_trigger_selector'

util.AddNetworkString('sv_qsystem_open_trigger_editor')
util.AddNetworkString('sv_qsystem_close_trigger_editor')

net.Receive('sv_qsystem_open_trigger_editor', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end
	if not ply:HasWeapon(weapon_class) then ply:Give(weapon_class) end
	ply:SelectWeapon(weapon_class)
end)

net.Receive('sv_qsystem_close_trigger_editor', function(len, ply)
	if not ply:IsQuestEditAccess(true) then return end
	if ply:HasWeapon(weapon_class) then ply:StripWeapon(weapon_class) end
end)