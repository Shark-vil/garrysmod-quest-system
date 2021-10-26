net.Receive('cl_qsystem_player_notify', function()
	LocalPlayer():QuestNotify(
		net.ReadString(), net.ReadString(), net.ReadFloat(), net.ReadString(), net.ReadColor()
	)
end)

net.Receive('cl_qsystem_player_notify_quest_start', function()
	LocalPlayer():QuestStartNotify(
		net.ReadString(), net.ReadFloat(), net.ReadString(), net.ReadColor()
	)
end)