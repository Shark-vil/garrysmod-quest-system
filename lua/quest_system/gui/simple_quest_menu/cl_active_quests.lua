local QuestTracking = NULL

local function OpenMenu()
    local Frame = vgui.Create('DFrame')
    Frame:SetTitle('Список активных заданий')
    Frame:SetSize(500, 450)
    Frame:MakePopup()
    Frame:Center()
    Frame.Paint = function(self, w, h )
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 245))
    end

    local ScrollPanel = vgui.Create("DScrollPanel", Frame)
    ScrollPanel:Dock(FILL)

    local quests = ents.FindByClass('quest_entity')

    local isZero = true
    for _, ent in pairs(quests) do
        local quest = ent:GetQuest()

        if quest.isEvent or ent:GetPlayer() == LocalPlayer() then       
            if quest.timeQuest ~= nil then
                quest.description = quest.description .. 
                    '\nВремя на выполнение: ' .. quest.timeQuest .. ' сек.'
            end

            isZero = false

            local PanelItem = ScrollPanel:Add("DPanel")
            PanelItem:SetHeight(120)
            PanelItem:Dock(TOP)
            PanelItem:DockMargin(0, 0, 0, 5)
            PanelItem.Paint = function(self, w, h )
                draw.RoundedBox(4, 0, 0, w, h, Color(220, 225, 220, 200))
            end

            local LabelTitle = vgui.Create("DLabel", PanelItem)
            LabelTitle:SetPos(5, 5)
            LabelTitle:SetFont('SimpleQuestMenuTitle')
            LabelTitle:SetText(quest.title)
            LabelTitle:SizeToContents()
            LabelTitle:SetDark(1)

            local PanelDescription = vgui.Create("DPanel", PanelItem)
            PanelDescription:Dock(FILL)
            PanelDescription:DockMargin(0, 30, 0, 0)
            PanelDescription.Paint = function(self, w, h)
                surface.SetDrawColor(100, 100, 100, 50)
                surface.DrawRect(0, 0, w, h)
            end
            PanelDescription.Paint = function(self, w, h )
                draw.RoundedBox(0, 0, 0, w, h, Color(220, 225, 220, 255))
            end

            local LabelDescription = vgui.Create("DLabel", PanelDescription)
            LabelDescription:SetHeight(50)
            LabelDescription:SetWidth(450)
            LabelDescription:Dock(TOP)
            LabelDescription:DockMargin(5, 0, 0, 0)
            LabelDescription:SetFont('DermaDefault')
            LabelDescription:SetText(quest.description)
            LabelDescription:SetDark(1)
            LabelDescription:SetWrap(true)

            local ButtonQuestTracking = vgui.Create('DButton', PanelItem)
            ButtonQuestTracking:SetText('Отслеживать задание')
            ButtonQuestTracking:Dock(BOTTOM)
            ButtonQuestTracking.DoClick = function()
                QuestTracking = ent
            end
        end
    end

    if isZero then
        local LabelDescription = vgui.Create("DLabel", Frame)
        LabelDescription:SetFont('DermaLarge')
        LabelDescription:SetText('Нету активных заданий')
        LabelDescription:SizeToContents()
        LabelDescription:Center()
    end
end
concommand.Add('qsystem_active_quests_menu', OpenMenu)

net.Receive('cl_qsystem_set_quest_tracking', function()
    local ent = net.ReadEntity()
    if IsValid(ent) then
        QuestTracking = ent
    end
end)

local arrow_color = Color(255, 255, 255, 255)
local arrow_texture = surface.GetTextureID("vgui/quest_system/mm_arrow")
local function DrawNavigationArrow()
    if not IsValid(QuestTracking) then return end
    local eQuest = QuestTracking

    if eQuest:HasQuester(LocalPlayer()) then
        if eQuest:slibGetVar('arrow_target_enabled') then
            local vec = eQuest:slibGetVar('arrow_target', Vector(0, 0, 0))
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
end
hook.Add("HUDPaint", "QSystem.DrawNavigationArrow", DrawNavigationArrow)