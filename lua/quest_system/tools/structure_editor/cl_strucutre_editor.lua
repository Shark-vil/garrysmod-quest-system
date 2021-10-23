local weapon_class = 'weapon_quest_structure_tool'

concommand.Add('qsystem_open_structure_editor', function(ply)
	net.Start('sv_qsystem_open_structure_editor')
	net.SendToServer()
end)

local OpenPointsPanelEditor, OpenQuestSelectPanel, OpenPointsSelectPanel

net.Receive('cl_qsystem_open_structure_editor', function(len, ply)
	OpenQuestSelectPanel()
end)

local allQuests

OpenQuestSelectPanel = function()
	local notsend = false
	local frame = vgui.Create('DFrame')
	frame:SetPos(20, 20)
	frame:SetSize(550, 350)
	frame:SetTitle('Select quest')
	frame:MakePopup()
	frame:Center()

	frame.OnClose = function()
		if notsend then return end
		net.Start('sv_qsystem_close_structure_editor')
		net.SendToServer()
	end

	allQuests = QuestSystem:GetAllQuest()
	local QuestList = vgui.Create('DListView', frame)
	QuestList:Dock(FILL)
	QuestList:SetMultiSelect(false)
	QuestList:AddColumn('Id')
	QuestList:AddColumn('Title')

	for _, quest in pairs(allQuests) do
		for _, step in pairs(quest.steps) do
			if step.structures ~= nil then
				QuestList:AddLine(quest.id, quest.title)
				break
			end
		end
	end

	QuestList.OnRowSelected = function(lst, index, pnl)
		OpenPointsSelectPanel(allQuests[pnl:GetColumnText(1)])
		notsend = true
		frame:Close()
	end
end

OpenPointsSelectPanel = function(quest)
	local notsend = false
	local frame = vgui.Create('DFrame')
	frame:SetPos(20, 20)
	frame:SetSize(550, 350)
	frame:SetTitle('Select structure')
	frame:MakePopup()
	frame:Center()

	frame.OnClose = function(self)
		if notsend then return end
		OpenQuestSelectPanel()
	end

	local QuestList = vgui.Create('DListView', frame)
	QuestList:Dock(FILL)
	QuestList:SetMultiSelect(false)
	QuestList:AddColumn('Id')
	QuestList:AddColumn('Zone')
	QuestList:AddColumn('Props count')
	local exists_names = {}

	for _, step in pairs(quest.steps) do
		if step.structures ~= nil then
			for name, _ in pairs(step.structures) do
				if not table.HasValue(exists_names, name) then
					local line = QuestList:AddLine(name)

					QuestSystem:GetStorage('structure'):Read(quest.id, name, function(ply, data)
						local zone = data.Zone

						if zone ~= nil then
							local vec1 = zone.vec1
							local vec2 = zone.vec2

							if vec1 ~= nil and vec2 ~= nil then
								line:SetColumnText(2, 'X - ' .. tostring(vec1) .. '; Y - ' .. tostring(vec2))
							end
						end

						line:SetColumnText(3, tostring(table.Count(data.Props)))
					end)

					table.insert(exists_names, name)
				end
			end
		end
	end

	QuestList.OnRowSelected = function(lst, index, pnl)
		timer.Simple(0.1, function()
			OpenPointsPanelEditor(quest, pnl:GetColumnText(1))
			notsend = true
			frame:Close()
		end)
	end
end

OpenPointsPanelEditor = function(quest, structure_name)
	local weapon = LocalPlayer():GetWeapon(weapon_class)

	QuestSystem:GetStorage('structure'):Read(quest.id, structure_name, function(ply, data)
		if IsValid(weapon) and data ~= nil then
			weapon.StructureZone = data.Zone
		end
	end)

	local spawn_id = nil
	local zone = nil

	local PanelManager = DFCL:New('qsystem_structure_editor')
	PanelManager:AddMouseClickListener()
	PanelManager:AddContextMenuListener()
	PanelManager:AddFocusName('DTextEntry')

	local InfoPanel = vgui.Create('DFrame')
	InfoPanel:MakePopup()
	InfoPanel:SetSize(230, 260)
	InfoPanel:SetPos(100, ScrH() / 2 - 10)
	InfoPanel:SetTitle('Structure editor')
	InfoPanel:SetSizable(false)
	InfoPanel:SetDraggable(true)
	InfoPanel:ShowCloseButton(false)
	InfoPanel:SetKeyboardInputEnabled(false)
	InfoPanel:SetMouseInputEnabled(false)
	InfoPanel:SetVisible(true)

	InfoPanel.Paint = function(self, width, height)
		draw.RoundedBox(0, 0, 0, width, height, Color(33, 29, 46, 255))

		if zone ~= nil then
			surface.SetFont('Trebuchet18')
			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(15, 25)
			surface.DrawText('Zone:')
			surface.SetTextPos(15, 40)
			surface.SetTextColor(94, 220, 255, 255)
			surface.SetFont('Default')

			if zone.vec1 ~= nil then
				surface.SetTextPos(15, 55)
				surface.DrawText(tostring(zone.vec1))
			end

			if zone.vec2 ~= nil then
				surface.SetTextPos(15, 65)
				surface.DrawText(tostring(zone.vec2))
			end
		end

		if IsValid(weapon) then
			zone = weapon.StructureZone
		else
			self:Close()
		end
	end

	InfoPanel.OnClose = function()
		if spawn_id ~= nil then
			net.Start('sv_qsystem_structure_remove')
			net.WriteString(spawn_id)
			net.SendToServer()
		end

		weapon:ClearZonePositions()
		OpenPointsSelectPanel(quest)
		PanelManager:Destruct()
	end

	PanelManager:AddPanel(InfoPanel, true)

	local CreatePropsButton = vgui.Create('DButton')
	CreatePropsButton:SetParent(InfoPanel)
	CreatePropsButton:SetText('Create props')
	CreatePropsButton:SetPos(15, 100)
	CreatePropsButton:SetSize(200, 30)

	CreatePropsButton.DoClick = function()
		if spawn_id ~= nil then
			surface.PlaySound('Resource/warning.wav')
		else
			snet.RegisterCallback('spawn_structure_editor', function(ply, id)
				spawn_id = id
			end)

			net.Start('sv_qsystem_structure_spawn')
			net.WriteString(quest.id)
			net.WriteString(structure_name)
			net.SendToServer()
		end
	end

	PanelManager:AddPanel(CreatePropsButton)
	local RemovePropsButton = vgui.Create('DButton')
	RemovePropsButton:SetParent(InfoPanel)
	RemovePropsButton:SetText('Remove props')
	RemovePropsButton:SetPos(15, 140)
	RemovePropsButton:SetSize(200, 30)

	RemovePropsButton.DoClick = function()
		if spawn_id ~= nil then
			net.Start('sv_qsystem_structure_remove')
			net.WriteString(spawn_id)
			net.SendToServer()
			spawn_id = nil
		end
	end

	PanelManager:AddPanel(RemovePropsButton)

	local InfoButtonYes = vgui.Create('DButton')
	InfoButtonYes:SetParent(InfoPanel)
	InfoButtonYes:SetText('Save')
	InfoButtonYes:SetPos(15, 180)
	InfoButtonYes:SetSize(200, 30)

	InfoButtonYes.DoClick = function()
		local props = weapon:GetPropsOnZone()

		local new_data = {
			Zone = zone,
			Props = {}
		}

		for _, ent in pairs(props) do
			if tobool(string.find(ent:GetClass(), 'prop_*')) then
				local prop_data = {
					class = ent:GetClass(),
					model = ent:GetModel(),
					pos = ent:GetPos(),
					ang = ent:GetAngles()
				}

				table.insert(new_data.Props, prop_data)
			end
		end

		if structure_name ~= nil and new_data.Zone ~= nil and table.Count(new_data.Props) ~= 0 then
			QuestSystem:GetStorage('structure'):Save(quest.id, structure_name, new_data)
			surface.PlaySound('buttons/blip1.wav')
		else
			surface.PlaySound('Resource/warning.wav')
		end
	end

	PanelManager:AddPanel(InfoButtonYes)

	local InfoButtonNo = vgui.Create('DButton')
	InfoButtonNo:SetParent(InfoPanel)
	InfoButtonNo:SetText('Exit')
	InfoButtonNo:SetPos(15, 220)
	InfoButtonNo:SetSize(200, 30)

	InfoButtonNo.DoClick = function()
		InfoPanel:Close()
	end

	PanelManager:AddPanel(InfoButtonNo)
end