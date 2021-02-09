local storage = {}

if SERVER then
    util.AddNetworkString('sv_qsystem_structure_save')
    util.AddNetworkString('sv_qsystem_structure_read')
end

if SERVER then
    net.Receive('sv_qsystem_structure_save', function(len, ply)
        if not ply:IsQuestEditAccess() then return end
        local id = net.ReadString()
        local name = net.ReadString()
        local data = net.ReadTable()
        storage:Save(id, name, data)
    end)
end


function storage:GetFilePath(id, name)
    local file_path = 'quest_system/structure/' .. id .. '/' ..  game.GetMap() .. '/' .. name .. '.json'
    return file_path
end

function storage:Save(id, name, data)
    if CLIENT then
        net.Start('sv_qsystem_structure_save')
        net.WriteString(id)
        net.WriteString(name)
        net.WriteTable(data)
        net.SendToServer()
        return
    end

    if id == nil or string.len(id) == 0 then return end
    if name == nil or string.len(name) == 0 then return end
    if data == nil or table.Count(data) == 0 then return end

    local file_path = 'quest_system/structure/' .. id

    if not file.Exists(file_path, 'DATA') then
        file.CreateDir(file_path)
    end

    file_path = file_path .. '/' .. game.GetMap()

    if not file.Exists(file_path, 'DATA') then
        file.CreateDir(file_path)
    end

    file_path = file_path .. '/' .. name .. '.json'
    file.Write(file_path, util.TableToJSON(data))
end

if SERVER then
    net.Receive('sv_qsystem_structure_read', function(len, ply)
        if not ply:IsQuestEditAccess() then return end
        
        local id = net.ReadString()
        local name = net.ReadString()
        local fileData = storage:Read(id, name)

        if fileData ~= nil then
            snet.Invoke('structure_read' .. name, ply, fileData)
        end
    end)
end

function storage:Read(id, name, callback)
    if CLIENT then
        if callback ~= nil and isfunction(callback) then
            snet.RegisterCallback('structure_read' .. name, callback, true, true)

            net.Start('sv_qsystem_structure_read')
            net.WriteString(id)
            net.WriteString(name)
            net.SendToServer()
        end
    else
        if id ~= nil and string.len(id) ~= 0 then
            if name ~= nil and string.len(name) ~= 0 then
                local file_path = self:GetFilePath(id, name)
                if file_path ~= nil and file.Exists(file_path, 'DATA') then
                    return util.JSONToTable(file.Read(file_path, 'DATA'))
                end
            end
        end
    end
    return nil
end

QuestSystem:SetStorage('structure', storage)