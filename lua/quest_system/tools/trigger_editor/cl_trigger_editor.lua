local weapon_class = 'weapon_quest_system_tool_trigger_selector'

concommand.Add("qsystem_open_trigger_editor", function(ply)
    net.Start('sv_network_qsystem_open_trigger_editor')
    net.SendToServer()
end)

net.Receive('cl_network_qsystem_open_trigger_editor', function(len, ply)
    local trigger = nil
    local trigger_name = nil
    local delay = 0

    local PanelManager = DFCL:New( "qsystem_trigger_editor" )
    PanelManager:AddMouseClickListener()
    PanelManager:AddContextMenuListener()
    PanelManager:AddFocusName( "DTextEntry" )

    local InfoPanel = vgui.Create( "DFrame" )
    InfoPanel:MakePopup()
    InfoPanel:SetSize( 230, 270 )
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

        if delay < CurTime() then
            local weapon = LocalPlayer():GetWeapon(weapon_class)
            if IsValid(weapon) then
                trigger = weapon.CurrentTrigger
            else
                self:Close()
            end

            delay = CurTime() + 1
        end
    end
    InfoPanel.OnClose = function()
        PanelManager:Destruct()
    end
    PanelManager:AddPanel( InfoPanel, true )

    local InfoTextPrintLabel = vgui.Create( "DLabel" )
    InfoTextPrintLabel:SetParent( InfoPanel )
    InfoTextPrintLabel:SetFont( "Default" )
    InfoTextPrintLabel:SetText( "Trigger name:" )
    InfoTextPrintLabel:SetPos( 15, 90 )
    InfoTextPrintLabel:SizeToContents()
    PanelManager:AddPanel( InfoTextPrintLabel )

    local InfoTextPrint = vgui.Create( "DTextEntry" )
    InfoTextPrint:SetParent( InfoPanel )
    InfoTextPrint:SetPos( 15, 110 )
    InfoTextPrint:SetSize( 200, 25 )
    InfoTextPrint.OnEnter = function( self )
        trigger_name = self:GetValue()
        PanelManager:PanelStateReset()
    end
    InfoTextPrint.OnMousePressed = function( self, keyCode )
        PanelManager:SetFocusPanel( self )
    end
    PanelManager:AddPanel( InfoTextPrint )

    local InfoButtonYes = vgui.Create( "DButton" )
    InfoButtonYes:SetParent( InfoPanel )
    InfoButtonYes:SetText( "Save" )
    InfoButtonYes:SetPos( 15, 170 )
    InfoButtonYes:SetSize( 200, 30 )
    InfoButtonYes.DoClick = function ()
        if trigger_name ~= nil and trigger ~= nil then
            local trigger_save = {
                name = trigger_name,
                trigger = trigger
            }
            PrintTable(trigger_save)
            surface.PlaySound('buttons/blip1.wav')
        else
            surface.PlaySound('Resource/warning.wav')
        end
    end
    PanelManager:AddPanel( InfoButtonYes )

    local InfoButtonNo = vgui.Create( "DButton" )
    InfoButtonNo:SetParent( InfoPanel )
    InfoButtonNo:SetText( "Exit" )
    InfoButtonNo:SetPos( 15, 210 )
    InfoButtonNo:SetSize( 200, 30 )
    InfoButtonNo.DoClick = function()
        net.Start('sv_network_qsystem_close_trigger_editor')
        net.SendToServer()
        InfoPanel:Close()
    end
    PanelManager:AddPanel( InfoButtonNo )
end)