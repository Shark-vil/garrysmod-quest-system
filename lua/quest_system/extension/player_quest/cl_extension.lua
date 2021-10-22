local meta = FindMetaTable('Player')

net.Receive('cl_qsystem_player_notify', function()
    LocalPlayer():QuestNotify(net.ReadString(), net.ReadString(), net.ReadFloat(), net.ReadString(), net.ReadColor())
end)