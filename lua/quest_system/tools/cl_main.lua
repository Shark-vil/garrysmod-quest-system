concommand.Add('qsystem_editor', function()
	sgui.route('qsystem/editor')
end)

sgui.RouteRegister('qsystem/editor', function()
	local all_quests = QuestSystem:GetAllQuests()

	local MainFrame = vgui.Create('DFrame')
	MainFrame:SetPos(20, 20)
	MainFrame:SetSize(550, 350)
	MainFrame:SetTitle('Select quest')
	MainFrame:MakePopup()
	MainFrame:Center()

	local QuestList = vgui.Create('DListView', MainFrame)
	QuestList:Dock(FILL)
	QuestList:SetMultiSelect(false)
	QuestList:AddColumn('Id')
	QuestList:AddColumn('Title')

	for _, quest in pairs(all_quests) do
		QuestList:AddLine(quest.id, quest.title)
	end

	QuestList.OnRowSelected = function(lst, index, pnl)
		sgui.route('qsystem/editor/quest', all_quests[pnl:GetColumnText(1)])
		MainFrame:Close()
	end
end)

sgui.RouteRegister('qsystem/editor/quest', function(quest)
	local is_back = true
	local MainFrame = vgui.Create('DFrame')
	MainFrame:SetPos(20, 20)
	MainFrame:SetSize(550, 350)
	MainFrame:SetTitle('Edit quest zones')
	MainFrame:MakePopup()
	MainFrame:Center()
	MainFrame.OnClose = function()
		if not is_back then return end
		sgui.route('qsystem/editor')
	end

	local ZonesList = vgui.Create('DListView', MainFrame)
	ZonesList:Dock(FILL)
	ZonesList:SetMultiSelect(false)
	ZonesList:AddColumn('Zones')

	for _, step in pairs(quest.steps) do
		if step.points then
			ZonesList:AddLine('points')
			break
		end
	end

	for _, step in pairs(quest.steps) do
		if step.triggers then
			ZonesList:AddLine('triggers')
			break
		end
	end

	for _, step in pairs(quest.steps) do
		if step.structures then
			ZonesList:AddLine('structures')
			break
		end
	end

	ZonesList.OnRowSelected = function(lst, index, pnl)
		local zone_type = pnl:GetColumnText(1)

		if zone_type == 'points' then
			sgui.route('qsystem/editor/quest/points', quest)
		end

		if zone_type == 'triggers' then
			sgui.route('qsystem/editor/quest/triggers', quest)
		end

		if zone_type == 'structures' then
			sgui.route('qsystem/editor/quest/structures', quest)
		end

		is_back = false

		MainFrame:Close()
	end
end)