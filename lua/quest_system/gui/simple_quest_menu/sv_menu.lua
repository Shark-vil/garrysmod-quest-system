util.AddNetworkString('sv_qsystem_startquest')
util.AddNetworkString('sv_qsystem_stopquest')

net.Receive('sv_qsystem_startquest', function(len, ply)
    if ply:QSystemIsSpam() then
        QuestSystem:AdminAlert('Spam was detected in the network from the player - ' .. ply:Nick())
        return
    end

    local id = net.ReadString()
    ply:SaveQuest(id)
    ply:EnableQuest(id)
end)

net.Receive('sv_qsystem_stopquest', function(len, ply)
    if ply:QSystemIsSpam() then
        QuestSystem:AdminAlert('Spam was detected in the network from the player - ' .. ply:Nick())
        return
    end

    local id = net.ReadString()
    ply:DisableQuest(id)
    ply:RemoveQuest(id)
end)