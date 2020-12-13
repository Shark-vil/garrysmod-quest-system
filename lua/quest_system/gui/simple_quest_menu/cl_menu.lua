local function OpenMenu()
    local Frame = vgui.Create('DFrame')
    Frame:SetTitle('Доска заданий')
    Frame:SetSize(500, 450)
    Frame:MakePopup()
    Frame:Center()
    Frame.Paint = function(self, w, h )
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0))
    end

    local ScrollPanel = vgui.Create("DScrollPanel", Frame)
    ScrollPanel:Dock(FILL)

    local quests = QuestSystem:GetAllQuest()

    for id, quest in pairs(quests) do
        if not quest.isEvent then
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

            if LocalPlayer():QuestIsActive(id) then
                local ButtonQuestDisable = vgui.Create('DButton', PanelItem)
                ButtonQuestDisable:SetText('Отозвать задание')
                ButtonQuestDisable:Dock(BOTTOM)
                ButtonQuestDisable.DoClick = function()
                    net.Start('sv_qsystem_stopquest')
                    net.WriteString(quest.id)
                    net.SendToServer()
                    Frame:Close()
                end
            else
                local ButtonQuestEnable = vgui.Create('DButton', PanelItem)
                ButtonQuestEnable:SetText('Взять задание')
                ButtonQuestEnable:Dock(BOTTOM)
                ButtonQuestEnable.DoClick = function()
                    net.Start('sv_qsystem_startquest')
                    net.WriteString(quest.id)
                    net.SendToServer()
                    Frame:Close()
                end
            end
        end
    end
end
concommand.Add('qsystem_open_simple_quest_menu', OpenMenu)