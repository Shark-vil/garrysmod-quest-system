local weapon_class = 'weapon_quest_system_tool_point_selector'

sgui.RouteRegister('qsystem/editor/quest/points', function(quest)
	net.Start('sv_qsystem_open_points_editor')
	net.SendToServer()

	local is_back = true
	local frame = vgui.Create('DFrame')
	frame:SetPos(20, 20)
	frame:SetSize(550, 350)
	frame:SetTitle('Select point')
	frame:MakePopup()
	frame:Center()

	frame.OnClose = function(self)
		if not is_back then return end
		net.Start('sv_qsystem_close_points_editor')
		net.SendToServer()

		sgui.route('qsystem/editor/quest', quest)
	end

	local QuestList = vgui.Create('DListView', frame)
	QuestList:Dock(FILL)
	QuestList:SetMultiSelect(false)
	QuestList:AddColumn('Id')
	QuestList:AddColumn('Vectors')
	local exists_names = {}

	for _, step in pairs(quest.steps) do
		if step.points ~= nil then
			for name, _ in pairs(step.points) do
				if not table.HasValue(exists_names, name) then
					local line = QuestList:AddLine(name)

					QuestSystem:GetStorage('points'):Read(quest.id, name, function(ply, data)
						line:SetColumnText(2, 'Vectors count - ' .. tostring(table.Count(data)))
					end)

					table.insert(exists_names, name)
				end
			end
		end
	end

	QuestList.OnRowSelected = function(lst, index, pnl)
		if not LocalPlayer():HasWeapon(weapon_class) then return end

		timer.Simple(0.1, function()
			sgui.route('qsystem/editor/quest/points/select', quest, pnl:GetColumnText(1))
			is_back = false
			frame:Close()
		end)
	end
end)

sgui.RouteRegister('qsystem/editor/quest/points/select', function(quest, points_name)
	local weapon = LocalPlayer():GetWeapon(weapon_class)

	QuestSystem:GetStorage('points'):Read(quest.id, points_name, function(ply, data)
		if IsValid(weapon) then
			weapon.Points = data
		end
	end)

	local points = nil

	local PanelManager = DFCL:New('qsystem_points_editor')
	PanelManager:AddMouseClickListener()
	PanelManager:AddContextMenuListener()
	PanelManager:AddFocusName('DTextEntry')

	local InfoPanel = vgui.Create('DFrame')
	InfoPanel:MakePopup()
	InfoPanel:SetSize(230, 180)
	InfoPanel:SetPos(100, ScrH() / 2 - 10)
	InfoPanel:SetTitle('Points editor')
	InfoPanel:SetSizable(false)
	InfoPanel:SetDraggable(true)
	InfoPanel:ShowCloseButton(false)
	InfoPanel:SetKeyboardInputEnabled(false)
	InfoPanel:SetMouseInputEnabled(false)
	InfoPanel:SetVisible(true)

	InfoPanel.Paint = function(self, width, height)
		draw.RoundedBox(0, 0, 0, width, height, Color(33, 29, 46, 255))

		if points ~= nil then
			surface.SetFont('Trebuchet18')
			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(15, 25)
			surface.DrawText('Points:')
			surface.SetTextPos(15, 40)
			surface.DrawText(#points)
		end

		if IsValid(weapon) then
			points = weapon.Points
		else
			self:Close()
		end
	end

	InfoPanel.OnClose = function()
		weapon:ClearPoints()
		sgui.route('qsystem/editor/quest/points', quest)
		PanelManager:Destruct()
	end

	PanelManager:AddPanel(InfoPanel, true)

	local InfoButtonYes = vgui.Create('DButton')
	InfoButtonYes:SetParent(InfoPanel)
	InfoButtonYes:SetText('Save')
	InfoButtonYes:SetPos(15, 100)
	InfoButtonYes:SetSize(200, 30)

	InfoButtonYes.DoClick = function()
		if points_name ~= nil and points ~= nil then
			QuestSystem:GetStorage('points'):Save(quest.id, points_name, points)
			surface.PlaySound('buttons/blip1.wav')
		else
			surface.PlaySound('Resource/warning.wav')
		end
	end

	PanelManager:AddPanel(InfoButtonYes)
	local InfoButtonNo = vgui.Create('DButton')
	InfoButtonNo:SetParent(InfoPanel)
	InfoButtonNo:SetText('Exit')
	InfoButtonNo:SetPos(15, 140)
	InfoButtonNo:SetSize(200, 30)

	InfoButtonNo.DoClick = function()
		InfoPanel:Close()
	end

	PanelManager:AddPanel(InfoButtonNo)
end)