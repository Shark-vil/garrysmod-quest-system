local storage = {}

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
                local vars = net.ReadType()
                data.execute(ply, vars, name)
            end
        else
            local vars = net.ReadType()
            data.execute(ply, vars, name)
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
    if SERVER then
        net.Start('cl_qsystem_callback')
        net.WriteString(name)
        net.WriteType(data)
        net.Send(ply)
    else
        net.Start('sv_qsystem_callback')
        net.WriteString(name)
        net.WriteType(data)
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