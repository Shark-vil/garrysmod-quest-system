local lang = slib.language({
	['default'] = {
		['title'] = 'List of active quests',
		['quest_time'] = 'Quest time: {time} sec.',
		['stop_tracking'] = 'Stop tracking',
		['tracking'] = 'Track quest',
		['empty'] = 'No active quests',
	},
	['russian'] = {
		['title'] = 'Список активных заданий',
		['quest_time'] = 'Время на выполнение: {time} сек.',
		['tracking'] = 'Отслеживать задание',
		['stop_tracking'] = 'Прекратить отслеживание',
		['empty'] = 'Нету активных заданий',
	}
})

local QuestTracking

local function OpenMenu()
	local Frame = vgui.Create('DFrame')
	Frame:SetTitle(lang['title'])
	Frame:SetSize(500, 450)
	Frame:MakePopup()
	Frame:Center()

	Frame.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 245))
	end

	local ScrollPanel = vgui.Create('DScrollPanel', Frame)
	ScrollPanel:Dock(FILL)

	QuestTracking = QuestSystem:GetQuestTracking()

	local quests = ents.FindByClass('quest_entity')
	local LastButtonQuestTracking
	local isZero = true

	for _, ent in pairs(quests) do
		local quest = ent:GetQuest()

		if quest.is_event or ent:GetPlayer() == LocalPlayer() then
			local description = quest.description

			if quest.quest_time ~= nil then
				description = quest.description .. '\n'
					.. string.Replace(lang['quest_time'], '{time}', quest.quest_time)
			end

			isZero = false

			local PanelItem = ScrollPanel:Add('DPanel')
			PanelItem:SetHeight(120)
			PanelItem:Dock(TOP)
			PanelItem:DockMargin(0, 0, 0, 5)

			PanelItem.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(220, 225, 220, 200))
			end

			local LabelTitle = vgui.Create('DLabel', PanelItem)
			LabelTitle:SetPos(5, 5)
			LabelTitle:SetFont('SimpleQuestMenuTitle')
			LabelTitle:SetText(quest.title)
			LabelTitle:SizeToContents()
			LabelTitle:SetDark(1)

			local PanelDescription = vgui.Create('DPanel', PanelItem)
			PanelDescription:Dock(FILL)
			PanelDescription:DockMargin(0, 30, 0, 0)

			PanelDescription.Paint = function(self, w, h)
				surface.SetDrawColor(100, 100, 100, 50)
				surface.DrawRect(0, 0, w, h)
			end

			PanelDescription.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(220, 225, 220, 255))
			end

			local LabelDescription = vgui.Create('DLabel', PanelDescription)
			LabelDescription:SetHeight(50)
			LabelDescription:SetWidth(450)
			LabelDescription:Dock(TOP)
			LabelDescription:DockMargin(5, 0, 0, 0)
			LabelDescription:SetFont('DermaDefault')
			LabelDescription:SetText(description)
			LabelDescription:SetDark(1)
			LabelDescription:SetWrap(true)

			local ButtonQuestTracking = vgui.Create('DButton', PanelItem)
			if IsValid(QuestTracking) and QuestTracking == ent then
				ButtonQuestTracking:SetText(lang['stop_tracking'])
				LastButtonQuestTracking = ButtonQuestTracking
			else
				ButtonQuestTracking:SetText(lang['tracking'])
			end
			ButtonQuestTracking:Dock(BOTTOM)
			ButtonQuestTracking.DoClick = function(self)
				if IsValid(QuestTracking) and QuestTracking == ent then
					QuestTracking = QuestSystem:SetQuestTracking()
					self:SetText(lang['tracking'])
				else
					QuestTracking = QuestSystem:SetQuestTracking(ent)
					self:SetText(lang['stop_tracking'])

					if IsValid(LastButtonQuestTracking) and LastButtonQuestTracking ~= self then
						LastButtonQuestTracking:SetText(lang['tracking'])
						LastButtonQuestTracking = self
					end
				end
			end
		end
	end

	if isZero then
		local LabelDescription = vgui.Create('DLabel', Frame)
		LabelDescription:SetFont('DermaLarge')
		LabelDescription:SetText(lang['empty'])
		LabelDescription:SizeToContents()
		LabelDescription:Center()
	end
end

concommand.Add('qsystem_active_quests_menu', OpenMenu)

net.Receive('cl_qsystem_set_quest_tracking', function()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	QuestTracking = QuestSystem:SetQuestTracking(ent)
end)

local arrow_color = Color(0, 0, 0)
local arrow_texture = surface.GetTextureID('vgui/quest_system/quest_arrow')

local function DrawNavigationArrow()
	local eQuest = QuestSystem:GetQuestTracking()
	if not IsValid(eQuest) then return end

	if eQuest:HasQuester(LocalPlayer()) and eQuest:slibGetVar('arrow_target_enabled') then
		local target = eQuest:slibGetVar('arrow_target_' .. LocalPlayer():PlayerId(), Vector(0, 0, 0))
		local vec = target

		if not isvector(vec) then
			if not isentity(target) or not IsValid(target) then return end
			vec = target:GetPos()
		end

		local local_pos = LocalPlayer():GetPos()
		local eye_angle = LocalPlayer():EyeAngles()

		if LocalPlayer():InVehicle() then
			local veh = LocalPlayer():GetVehicle()
			eye_angle = eye_angle + veh:EyeAngles()
		end

		local angTo = (vec - local_pos):Angle()
		local diffYaw = angTo.y - eye_angle.y
		local absYaw = math.abs(math.sin(math.rad(diffYaw)))
		surface.SetDrawColor(arrow_color)
		surface.SetTexture(arrow_texture)
		surface.DrawTexturedRectRotated(ScrW() / 2, 75, 128, 32 + 64 * absYaw, diffYaw)

		return
	end
end

hook.Add('HUDPaint', 'QSystem.DrawNavigationArrow', DrawNavigationArrow)