local weapon_class = 'weapon_quest_system_tool_trigger_selector'

util.AddNetworkString('sv_network_qsystem_open_trigger_editor')
util.AddNetworkString('cl_network_qsystem_open_trigger_editor')
util.AddNetworkString('sv_network_qsystem_close_trigger_editor')

local function IsValidPlayer(ply)
    if IsValid(ply) and ply:Alive() then
        if ply:IsAdmin() or ply:IsSuperAdmin() then
            return true
        end
    end
    return false
end

net.Receive('sv_network_qsystem_open_trigger_editor', function(len, ply)
    if not IsValidPlayer(ply) then return end

    ply:Give(weapon_class)
    ply:SelectWeapon(weapon_class)
    net.Start('cl_network_qsystem_open_trigger_editor')
    net.Send(ply)
end)

net.Receive('sv_network_qsystem_close_trigger_editor', function(len, ply)
    if not IsValidPlayer(ply) then return end
    
    if ply:HasWeapon(weapon_class) then
        ply:StripWeapon(weapon_class)
    end
end)