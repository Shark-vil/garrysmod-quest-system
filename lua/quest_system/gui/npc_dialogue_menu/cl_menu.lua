local OpenDialoguNpc, OpenDialogueMenu, LoadAnswerOptions
local npcDialogue = NULL

local background_texture = Material('quest_system/vgui/dialogue_panel_background')
local background_color = Color(10, 69, 20, 200)
local pick_color = Color(43, 181, 69, 150)
local nopick_color = Color(0, 0, 0, 0)
local rectline_color = Color(87, 255, 118)

local cam_anim = 0
hook.Add("CalcView", "QSystem.NpcDialogueCamera", function(ply, pos, angles, fov)
    if IsValid(npcDialogue) and IsValid(npcDialogue:GetNPC()) then
        local npc = npcDialogue:GetNPC()
        local n_origin = npc:EyePos() - (npc:GetAngles():Forward() * -35) - Vector(0, 0, 10)
        local n_angles = npc:EyeAngles() - Angle(0, 180, 0)

        local view = {
            origin = LerpVector(cam_anim, pos, n_origin),
            angles = LerpAngle(cam_anim, angles, n_angles),
            fov = fov,
            drawviewer = false
        }

        if cam_anim < 1 then
            cam_anim = cam_anim + 0.015
        else
            cam_anim = 1
        end

        return view
    end

    cam_anim = 0
end)

hook.Add('PreDrawPlayerHands', 'QSystem.NpcDialogueCamera', function()
    if IsValid(npcDialogue) then
        return true
    end
end)

hook.Add('PreDrawViewModel', 'QSystem.NpcDialogueCamera', function()
    if IsValid(npcDialogue) then
        return true
    end
end)

OpenDialoguNpc = function(ignore_npc_text)
    local step = npcDialogue:GetStep()
    
    if step.text ~= nil and not ignore_npc_text then
        step.delay = step.delay or 3

        local text = ''

        if isstring(step.text) then
            text = step.text
        end

        if istable(step.text) then
            text = table.Random(step.text)
        end

        text = utf8.force(text)

        local width =  ScrW() / 2
        local maxLineSize = math.floor(width * 0.14)
        local startPos = 1
        local endPos = maxLineSize
        local lines = {}
        local str_len = utf8.len(text)
        if str_len >= maxLineSize then
            for i = 1, str_len do
                if endPos == i then
                    local line = utf8.sub(text, startPos, endPos) -- Чистая магия
                    table.insert(lines, line .. '\n')
                    
                    startPos = i
                    endPos = endPos + maxLineSize
                    if endPos > str_len then
                        endPos = str_len
                    end
                end
            end
        end

        if #lines ~= 0 then
            text = table.concat(lines)
        end

        hook.Add("HUDPaint", "QSystem.DialogueNpcText", function() 
            if not IsValid(npcDialogue) then return end

            local width =  ScrW() / 2
            local height = 150
            local pos_x = (ScrW() - width) / 2
            local pos_y = ScrH() - 200

            if background_texture ~= nil then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(background_texture)
                surface.DrawTexturedRect(pos_x, pos_y , width, height)
            else
                draw.RoundedBox(2, pos_x, pos_y, width, height, background_color)
            end

            draw.DrawText(text, "TargetID", 
                pos_x + 30, pos_y + 30, Color(255, 255, 255, 255))
        end)

        timer.Simple(step.delay, function()
            if IsValid(npcDialogue) then
                hook.Remove("HUDPaint", "QSystem.DialogueNpcText")
                OpenDialogueMenu()
            end
        end)
    else
        OpenDialogueMenu()
    end
end

OpenDialogueMenu = function()    
    local step = npcDialogue:GetStep()
    if step.answers ~= nil and #step.answers ~= 0 then
        local dont_send = false
        local mpx, mpy = ScrW() / 2, 250
        local MainPanel = vgui.Create('DFrame')
        MainPanel:ShowCloseButton(false)
        MainPanel:SetDraggable(false)
        MainPanel:SetSize(mpx, mpy)
        MainPanel:SetPos((ScrW() - mpx) / 2, ScrH() - 10 - mpy)
        
        local name = tostring(npcDialogue:GetNPC())
        if isstring(npcDialogue:GetDialogue().name) then
            name = npcDialogue:GetDialogue().name
        elseif istable(npcDialogue:GetDialogue().name) then
            name = table.Random(npcDialogue:GetDialogue().name)
        end
        
        MainPanel:SetTitle(name)
        MainPanel:MakePopup()
        MainPanel.OnClose = function(self)
            if not dont_send then
                net.Start('sv_qsystem_close_npc_dialogue_menu')
                net.SendToServer()
            end
        end
        MainPanel.OnKeyCodePressed = function(self, keyCode)
            if keyCode == KEY_TAB then
                self:Close()
            end
        end
        MainPanel.Paint = function(self, width, height)

            if background_texture ~= nil then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(background_texture)
                surface.DrawTexturedRect(0, 0 , width, height)
            else
                draw.RoundedBox(2, 0, 0, width, height, background_color)
            end

            surface.SetDrawColor(rectline_color)
            surface.DrawRect(0, 0, width, 2)
            surface.DrawRect(0, height-2, width, 2)

            local horizontal_line_size = 30
            surface.DrawRect(0, 0, 2, horizontal_line_size)
            surface.DrawRect(width - 2, 0, 2, horizontal_line_size)
            surface.DrawRect(0, height - horizontal_line_size, 2, horizontal_line_size)
            surface.DrawRect(width - 2, height - horizontal_line_size, 2, horizontal_line_size)

            if not IsValid(npcDialogue) then
                self:Close() 
            end
        end

        local AnswerOptions = vgui.Create("DScrollPanel", MainPanel)
        AnswerOptions:Dock(FILL)
        AnswerOptions:DockMargin(5, 5, 5, 5)

        for id, data in pairs(step.answers) do
            local skip = false
            local condition = step.answers[id].condition
            if condition ~= nil then
                if not condition(npcDialogue) then skip = true end
            end

            if not skip then
                local AnswerOptionItem = AnswerOptions:Add("DPanel")
                -- AnswerOptionItem:SetHeight(80)
                AnswerOptionItem:Dock(TOP)
                AnswerOptionItem:DockMargin(0, 0, 5, 5)
                AnswerOptionItem.OnCursorEntered = function(self)
                    self.onCursor = true
                end
                AnswerOptionItem.OnCursorExited = function(self)
                    self.onCursor = false
                end
                AnswerOptionItem.DragMouseRelease = function(self, mouseCode)
                    if step.answers[id] ~= nil then
                        local func = step.answers[id].event
                        func(LocalPlayer(), npcDialogue, currentDialogue)

                        npcDialogue.isFirstAnswer = true
                        
                        dont_send = true
                        MainPanel:Close()

                        net.Start('sv_qsystem_dialogue_answer_select')
                        net.WriteInt(id, 10)
                        net.SendToServer()
                    end
                end
                
                local currentColor = nopick_color
                AnswerOptionItem.Paint = function(self, width, height)
                    local alpha = 0

                    if self.onCursor then
                        local vec_color = currentColor:ToVector()
                        local vec_new_color = pick_color:ToVector()
                        local new_vec =  LerpVector(0.5, vec_color, vec_new_color)
                        currentColor = new_vec:ToColor()
                        alpha = pick_color.a

                        surface.SetDrawColor(rectline_color)
                        surface.DrawOutlinedRect(0, 0, width, height, 2)
                    else
                        local vec_color = currentColor:ToVector()
                        local vec_new_color = nopick_color:ToVector()
                        local new_vec =  LerpVector(0.5, vec_color, vec_new_color)
                        currentColor = new_vec:ToColor()
                        alpha = nopick_color.a
                    end

                    currentColor = ColorAlpha(currentColor, alpha)
                    draw.RoundedBox(8, 0, 0, width, height, currentColor)
                end

                local text = ''

                if isstring(data.text) then
                    text = data.text
                end
        
                if istable(data.text) then
                    text = table.Random(data.text)
                end

                local str_len = string.len(text)
                local max_str_one_line = 85
                local height = 40
                if str_len >= max_str_one_line then
                    local next_skip = max_str_one_line
                    for i = 1, str_len do
                        if next_skip == i then
                            height = height + 15
                            
                            next_skip = next_skip + max_str_one_line
                            if max_str_one_line > str_len then
                                max_str_one_line = str_len
                            end
                        end
                    end
                end
                AnswerOptionItem:SetHeight(height)

                local TextAnswer = vgui.Create("DLabel", AnswerOptionItem)
                TextAnswer:SetFont('QuestSystemDialogueText')
                TextAnswer:SetWidth(mpx - 25)
                TextAnswer:SetPos(5, 5)
                TextAnswer:SetText(text)
                TextAnswer:SetWrap(true)
                TextAnswer:SetAutoStretchVertical(true)
            end
        end
    end
end

net.Receive('cl_qsystem_set_dialogue_id', function()
    local ent = net.ReadEntity()
    local ignore_npc_text = net.ReadBool()
    npcDialogue = ent
    npcDialogue:StartDialogue(ignore_npc_text)
    OpenDialoguNpc(ignore_npc_text)
end)