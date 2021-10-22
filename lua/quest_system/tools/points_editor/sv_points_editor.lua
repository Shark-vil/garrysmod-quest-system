local weapon_class = 'weapon_quest_system_tool_point_selector'

util.AddNetworkString('sv_qsystem_open_points_editor')
util.AddNetworkString('cl_qsystem_open_points_editor')
util.AddNetworkString('sv_qsystem_close_points_editor')

net.Receive('sv_qsystem_open_points_editor', function(len, ply)
    if not ply:IsQuestEditAccess(true) then return end

    ply:Give(weapon_class)
    ply:SelectWeapon(weapon_class)
    net.Start('cl_qsystem_open_points_editor')
    net.Send(ply)
end)

net.Receive('sv_qsystem_close_points_editor', function(len, ply)
    if not ply:IsQuestEditAccess(true) then return end
    
    if ply:HasWeapon(weapon_class) then
        ply:StripWeapon(weapon_class)
    end
end)