util.AddNetworkString('sv_network_qsystem_trigger_save')

net.Receive('sv_network_qsystem_trigger_save', function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end

    local tdata = net.ReadTable()
    local file_path = 'quest_system/triggers/' .. tdata.id

    if not file.Exists(file_path, 'DATA') then
        file.CreateDir(file_path)
    end

    file_path = file_path .. '/' .. game.GetMap()

    if not file.Exists(file_path, 'DATA') then
        file.CreateDir(file_path)
    end

    file_path = file_path .. '/' .. tdata.name .. '.json'
    file.Write(file_path, util.TableToJSON(tdata.trigger))
end)