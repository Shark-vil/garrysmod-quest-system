if SERVER then
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
else
    surface.CreateFont( "SimpleQuestMenuTitle", {
        font = "Arial",
        extended = false,
        size = 18,
        weight = 1000,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )

    local function OpenMenu()
        local Frame = vgui.Create('DFrame')
        Frame:SetTitle('Simple quest menu')
        Frame:SetSize(500, 450)
        Frame:MakePopup()
        Frame:Center()

        local ScrollPanel = vgui.Create("DScrollPanel", Frame)
        ScrollPanel:Dock(FILL)

        local quests = QuestSystem:GetAllQuest()

        for id, quest in pairs(quests) do
            local PanelItem = ScrollPanel:Add("DPanel")
            PanelItem:SetHeight(120)
            PanelItem:Dock(TOP)
            PanelItem:DockMargin(0, 0, 0, 5)

            local LabelTitle = vgui.Create("DLabel", PanelItem)
            LabelTitle:SetPos(1, 1)
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
                ButtonQuestDisable:SetText('Отменить квест')
                ButtonQuestDisable:Dock(BOTTOM)
                ButtonQuestDisable.DoClick = function()
                    net.Start('sv_qsystem_stopquest')
                    net.WriteString(quest.id)
                    net.SendToServer()
                    Frame:Close()
                end
            else
                local ButtonQuestEnable = vgui.Create('DButton', PanelItem)
                ButtonQuestEnable:SetText('Начать квест')
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
    concommand.Add('qsystem_open_simple_quest_menu', OpenMenu)
end