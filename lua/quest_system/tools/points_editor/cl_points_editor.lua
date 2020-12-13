local weapon_class = 'weapon_quest_system_tool_point_selector'

concommand.Add("qsystem_open_points_editor", function(ply)
    net.Start('sv_qsystem_open_points_editor')
    net.SendToServer()
end)

local OpenPointsPanelEditor, OpenQuestSelectPanel, OpenPointsSelectPanel

net.Receive('cl_qsystem_open_points_editor', function(len, ply)
    OpenQuestSelectPanel()
end)

local allQuests
OpenQuestSelectPanel = function()
    local notsend = false
    local frame = vgui.Create("DFrame")
    frame:SetPos(20, 20)
    frame:SetSize(550, 350)
    frame:SetTitle("Select quest")
    frame:MakePopup()
    frame:Center()
    frame.OnClose = function()
        if notsend then return end
        net.Start('sv_qsystem_close_points_editor')
        net.SendToServer()
    end

    allQuests = QuestSystem:GetAllQuest()

    local QuestList = vgui.Create("DListView", frame)
    QuestList:Dock(FILL)
    QuestList:SetMultiSelect(false)
    QuestList:AddColumn("Id")
    QuestList:AddColumn("Title")

    for _, quest in pairs(allQuests) do
        QuestList:AddLine(quest.id, quest.title)
    end

    QuestList.OnRowSelected = function(lst, index, pnl)
        OpenPointsSelectPanel(allQuests[pnl:GetColumnText(1)])
        notsend = true
        frame:Close()
    end
end

OpenPointsSelectPanel = function(quest)
    local notsend = false
    local frame = vgui.Create("DFrame")
    frame:SetPos(20, 20)
    frame:SetSize(550, 350)
    frame:SetTitle("Select point")
    frame:MakePopup()
    frame:Center()
    frame.OnClose = function(self)
        if notsend then return end
        OpenQuestSelectPanel()
    end

    local QuestList = vgui.Create("DListView", frame)
    QuestList:Dock(FILL)
    QuestList:SetMultiSelect(false)
    QuestList:AddColumn("Id")

    for _, step in pairs(quest.steps) do
        if step.points ~= nil then
            for name, _ in pairs(step.points) do
                QuestList:AddLine(name)
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

OpenPointsPanelEditor = function(quest, points_name)
    local weapon = LocalPlayer():GetWeapon(weapon_class)

    QuestSystem:GetStorage('points'):Read(quest.id, points_name, function(ply, data)
        if IsValid(weapon) then
            weapon.Points = data
        end
    end)

    local points = nil
    local delay = 0

    local PanelManager = DFCL:New( "qsystem_points_editor" )
    PanelManager:AddMouseClickListener()
    PanelManager:AddContextMenuListener()
    PanelManager:AddFocusName( "DTextEntry" )

    local InfoPanel = vgui.Create( "DFrame" )
    InfoPanel:MakePopup()
    InfoPanel:SetSize( 230, 180 )
    InfoPanel:SetPos( 100, ScrH()/2 - 10 )
    InfoPanel:SetTitle( "Points editor" )
    InfoPanel:SetSizable( false )
    InfoPanel:SetDraggable( true )
    InfoPanel:ShowCloseButton( false )
    InfoPanel:SetKeyboardInputEnabled( false )
    InfoPanel:SetMouseInputEnabled( false )
    InfoPanel:SetVisible( true )
    InfoPanel.Paint = function( self, width, height )
        draw.RoundedBox( 0, 0, 0, width, height, Color(33,29,46,255) )
        if points ~= nil then
            surface.SetFont( "Trebuchet18" )
            surface.SetTextColor( 255, 255, 255, 255 )
            surface.SetTextPos( 15, 25 )
            surface.DrawText( "Points:" )
            surface.SetTextPos( 15, 40 )
            surface.DrawText( #points )
        end

        if IsValid(weapon) then
            points = weapon.Points
        else
            self:Close()
        end
    end
    InfoPanel.OnClose = function()
        weapon:ClearPoints()
        OpenPointsSelectPanel(quest)
        PanelManager:Destruct()
    end
    PanelManager:AddPanel( InfoPanel, true )

    local InfoButtonYes = vgui.Create( "DButton" )
    InfoButtonYes:SetParent( InfoPanel )
    InfoButtonYes:SetText( "Save" )
    InfoButtonYes:SetPos( 15, 100 )
    InfoButtonYes:SetSize( 200, 30 )
    InfoButtonYes.DoClick = function ()
        if points_name ~= nil and points ~= nil then
            QuestSystem:GetStorage('points'):Save(quest.id, points_name, points)
            surface.PlaySound('buttons/blip1.wav')
        else
            surface.PlaySound('Resource/warning.wav')
        end
    end
    PanelManager:AddPanel( InfoButtonYes )

    local InfoButtonNo = vgui.Create( "DButton" )
    InfoButtonNo:SetParent( InfoPanel )
    InfoButtonNo:SetText( "Exit" )
    InfoButtonNo:SetPos( 15, 140 )
    InfoButtonNo:SetSize( 200, 30 )
    InfoButtonNo.DoClick = function()
        InfoPanel:Close()
    end
    PanelManager:AddPanel( InfoButtonNo )
end