local storage = {}
local send_size = 10000

netCallback = netCallback or {}

local function network_callback(len, ply)
    if CLIENT then
        ply = LocalPlayer()
    end

    local name = net.ReadString()
    local networkData = util.JSONToTable(util.Decompress(net.ReadData(send_size)))

    if storage[name] ~= nil then
        local data = storage[name]
        if data.adminOnly then
            if ply:IsAdmin() or ply:IsSuperAdmin() then
                data.execute(ply, networkData, category, name)
            end
        else
            data.execute(ply, networkData, category, name)
        end

        netCallback.remove(name)
    end
end

if SERVER then
    util.AddNetworkString('sv_qsystem_callback')
    util.AddNetworkString('cl_qsystem_callback')

    net.Receive('sv_qsystem_callback', network_callback)
else
    net.Receive('cl_qsystem_callback', network_callback)
end

netCallback.invoke = function(name, ply, data)
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

netCallback.register = function(name, func, adminOnly)
    adminOnly = adminOnly or true
    storage[name] = {
        adminOnly = adminOnly,
        execute = func
    }
end

netCallback.remove = function(name)
    storage[name] = nil
end