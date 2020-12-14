local storage = {}
local send_size = 10000

net = net or {}

local function network_callback(len, ply)
    if CLIENT then
        ply = LocalPlayer()
    end

    local name = net.ReadString()

    if storage[name] ~= nil then
        local data = storage[name]

        if data.adminOnly then
            if ply:IsAdmin() or ply:IsSuperAdmin() then
                local net_data = net.ReadData(send_size)
                if net_data ~= nil and #net_data ~= 0 then
                    local networkData = util.JSONToTable(util.Decompress(net_data))
                    data.execute(ply, networkData, category, name)
                end
            end
        else
            local net_data = net.ReadData(send_size)
            if net_data ~= nil and #net_data ~= 0 then
                local networkData = util.JSONToTable(util.Decompress(net_data))
                data.execute(ply, networkData, category, name)
            end
        end

        net.RemoveCallback(name)
    end
end

if SERVER then
    util.AddNetworkString('sv_qsystem_callback')
    util.AddNetworkString('cl_qsystem_callback')

    net.Receive('sv_qsystem_callback', network_callback)
else
    net.Receive('cl_qsystem_callback', network_callback)
end

net.Invoke = function(name, ply, data)
    data = data or {}
    if not istable(data) then
        data = {}
    end

    local compressedTable = util.Compress(util.TableToJSON(data))
    local start = 0
    local endbyte = math.min(start + send_size, string.len(compressedTable))
    local size = endbyte - start
    
    if SERVER then
        net.Start('cl_qsystem_callback')
        net.WriteString(name)
        net.WriteData(compressedTable:sub(start + 1, endbyte + 1), size)
        net.Send(ply)
    else
        net.Start('sv_qsystem_callback')
        net.WriteString(name)
        net.WriteData(compressedTable:sub(start + 1, endbyte + 1), size)
        net.SendToServer()
    end
end

net.RegisterCallback = function(name, func, adminOnly)
    adminOnly = adminOnly or true
    storage[name] = {
        adminOnly = adminOnly,
        execute = func
    }
end

net.RemoveCallback = function(name)
    storage[name] = nil
end