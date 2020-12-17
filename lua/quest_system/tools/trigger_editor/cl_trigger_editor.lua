local weapon_class = 'weapon_quest_system_tool_trigger_selector'

concommand.Add("qsystem_open_trigger_editor", function(ply)
    net.Start('sv_qsystem_open_trigger_editor')
    net.SendToServer()
end)

local OpenTriggerPanelEditor, OpenQuestSelectPanel, OpenTriggerSelectPanel

net.Receive('cl_qsystem_open_trigger_editor', function(len, ply)
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
        net.Start('sv_qsystem_close_trigger_editor')
        net.SendToServer()
    end

    allQuests = QuestSystem:GetAllQuest()

    local QuestList = vgui.Create("DListView", frame)
    QuestList:Dock(FILL)
    QuestList:SetMultiSelect(false)
    QuestList:AddColumn("Id")
    QuestList:AddColumn("Title")

    for _, quest in pairs(allQuests) do
        for _, step in pairs(quest.steps) do
            if step.triggers ~= nil then
                QuestList:AddLine(quest.id, quest.title)
                break
            end
        end
    end

    QuestList.OnRowSelected = function(lst, index, pnl)
        OpenTriggerSelectPanel(allQuests[pnl:GetColumnText(1)])
        notsend = true
        frame:Close()
    end
end

OpenTriggerSelectPanel = function(quest)
    local notsend = false
    local frame = vgui.Create("DFrame")
    frame:SetPos(20, 20)
    frame:SetSize(550, 350)
    frame:SetTitle("Select trigger")
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
        if step.triggers ~= nil then
            for name, _ in pairs(step.triggers) do
                QuestList:AddLine(name)
            end
        end
    end

    QuestList.OnRowSelected = function(lst, index, pnl)
        timer.Simple(0.1, function()
            OpenTriggerPanelEditor(quest, pnl:GetColumnText(1)) 
            notsend = true
            frame:Close()
        end)
    end
end

OpenTriggerPanelEditor = function(quest, trigger_name)
    local weapon = LocalPlayer():GetWeapon(weapon_class)

    QuestSystem:GetStorage('trigger'):Read(quest.id, trigger_name, function(ply, data)
        if IsValid(weapon) then
            weapon.CurrentTrigger = data
        end
    end)

    local trigger = nil
    local delay = 0

    local PanelManager = DFCL:New( "qsystem_trigger_editor" )
    PanelManager:AddMouseClickListener()
    PanelManager:AddContextMenuListener()
    PanelManager:AddFocusName( "DTextEntry" )

    local InfoPanel = vgui.Create( "DFrame" )
    InfoPanel:MakePopup()
    InfoPanel:SetSize( 230, 180 )
    InfoPanel:SetPos( 100, ScrH()/2 - 10 )
    InfoPanel:SetTitle( "Trigger editor" )
    InfoPanel:SetSizable( false )
    InfoPanel:SetDraggable( true )
    InfoPanel:ShowCloseButton( false )
    InfoPanel:SetKeyboardInputEnabled( false )
    InfoPanel:SetMouseInputEnabled( false )
    InfoPanel:SetVisible( true )
    InfoPanel.Paint = function( self, width, height )
        draw.RoundedBox( 0, 0, 0, width, height, Color(33,29,46,255) )
        if trigger ~= nil then
            surface.SetFont( "Trebuchet18" )
            surface.SetTextColor( 255, 255, 255, 255 )
            surface.SetTextPos( 15, 25 )
            surface.DrawText( "Trigger:" )
            surface.SetTextPos( 15, 40 )
            surface.DrawText( trigger.type )
            surface.SetTextColor( 94, 220, 255, 255 )
            surface.SetFont( "Default" )
            if trigger.type == 'box' then
                if trigger.vec1 ~= nil then
                    surface.SetTextPos( 15, 55 )
                    surface.DrawText( tostring(trigger.vec1) )
                end
                if trigger.vec2 ~= nil then
                    surface.SetTextPos( 15, 65 )
                    surface.DrawText( tostring(trigger.vec2) )
                end
            end

            if trigger.type == 'sphere' then
                if trigger.center ~= nil then
                    surface.SetTextPos( 15, 55 )
                    surface.DrawText( tostring(trigger.center) )
                end
                if trigger.radius ~= nil then
                    surface.SetTextPos( 15, 65 )
                    surface.DrawText( trigger.radius )
                end
            end
        end

        if IsValid(weapon) then
            trigger = weapon.CurrentTrigger
        else
            self:Close()
        end
    end
    InfoPanel.OnClose = function()
        weapon:ClearTriggerPosition()
        OpenTriggerSelectPanel(quest)
        PanelManager:Destruct()
    end
    PanelManager:AddPanel( InfoPanel, true )

    local InfoButtonYes = vgui.Create( "DButton" )
    InfoButtonYes:SetParent( InfoPanel )
    InfoButtonYes:SetText( "Save" )
    InfoButtonYes:SetPos( 15, 100 )
    InfoButtonYes:SetSize( 200, 30 )
    InfoButtonYes.DoClick = function ()
        if trigger_name ~= nil and trigger ~= nil then
            QuestSystem:GetStorage('trigger'):Save(quest.id, trigger_name, trigger)
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