local weapon_class = 'weapon_quest_system_tool_trigger_selector'

util.AddNetworkString('sv_qsystem_open_trigger_editor')
util.AddNetworkString('cl_qsystem_open_trigger_editor')
util.AddNetworkString('sv_qsystem_close_trigger_editor')
util.AddNetworkString('sv_qsystem_get_trigger_info')
util.AddNetworkString('cl_qsystem_get_trigger_info')

net.Receive('sv_qsystem_open_trigger_editor', function(len, ply)
    if not ply:IsQuestEditAccess(true) then return end

    ply:Give(weapon_class)
    ply:SelectWeapon(weapon_class)
    net.Start('cl_qsystem_open_trigger_editor')
    net.Send(ply)
end)

net.Receive('sv_qsystem_close_trigger_editor', function(len, ply)
    if not ply:IsQuestEditAccess(true) then return end
    
    if ply:HasWeapon(weapon_class) then
        ply:StripWeapon(weapon_class)
    end
end)

net.Receive('sv_qsystem_get_trigger_info', function(len, ply)
    if not ply:IsQuestEditAccess(true) then return end

    local quest_id = net.ReadString()
    local trigger_name = net.ReadString()
    local file_path = 'quest_system/triggers/' .. quest_id .. '/' 
        .. game.GetMap() .. '/' .. trigger_name .. '.json'

    if file.Exists(file_path, 'DATA') then
        local data = util.JSONToTable(file.Read(file_path, "DATA"))
        net.Start('cl_qsystem_get_trigger_info')
        net.WriteTable(data)
        net.Send(ply)
    end
end)