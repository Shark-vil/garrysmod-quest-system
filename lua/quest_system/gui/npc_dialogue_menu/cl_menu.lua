local OpenDialoguNpc, OpenDialogueMenu, LoadAnswerOptions
local npcDialogue = NULL

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
            cam_anim = cam_anim + 0.010
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

        local width =  ScrW() / 2
        local maxLineSize = math.floor(width / 7.5)
        local startPos = 1
        local endPos = maxLineSize
        local lines = {}
        for i = 1, string.len(text) do
            if endPos == i then
                local line = string.sub(text, startPos,endPos) .. '\n'
                table.insert(lines, line)
                startPos = i + 1
                endPos = endPos + maxLineSize
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

            draw.RoundedBox(2, pos_x, pos_y, width, height, Color(0, 0, 0, 220))
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
        MainPanel.Paint = function(self, width, height)
            draw.RoundedBox(2, 0, 0, width, height, Color(0, 0, 0, 220))

            if not IsValid(npcDialogue) then
                self:Close() 
            end
        end

        local AnswerOptions = vgui.Create("DScrollPanel", MainPanel)
        AnswerOptions:Dock(FILL)
        AnswerOptions:DockMargin(5, 5, 5, 5)

        for id, data in pairs(step.answers) do
            local AnswerOptionItem = AnswerOptions:Add("DPanel")
            AnswerOptionItem:SetHeight(80)
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
                    
                    dont_send = true
                    MainPanel:Close()

                    net.Start('sv_qsystem_dialogue_answer_select')
                    net.WriteInt(id, 10)
                    net.SendToServer()
                end
            end
            
            local hoverColor = Color(184, 211, 217, 200)
            local defaultColor = Color(255, 255, 255, 200)
            local currentColor = defaultColor
            AnswerOptionItem.Paint = function(self, width, height)
                if self.onCursor then
                    local vec_color = currentColor:ToVector()
                    local vec_new_color = hoverColor:ToVector()
                    local new_vec =  LerpVector(0.5, vec_color, vec_new_color)
                    currentColor = new_vec:ToColor()
                else
                    local vec_color = currentColor:ToVector()
                    local vec_new_color = defaultColor:ToVector()
                    local new_vec =  LerpVector(0.5, vec_color, vec_new_color)
                    currentColor = new_vec:ToColor()
                end

                draw.RoundedBox(8, 0, 0, width, height, currentColor)
            end

            local TextAnswer = vgui.Create("DLabel", AnswerOptionItem)
            TextAnswer:SetFont('QuestSystemDialogueText')
            TextAnswer:SetPos(5, 5)
            local text = ''

            if isstring(data.text) then
                text = data.text
            end
    
            if istable(data.text) then
                text = table.Random(data.text)
            end

            TextAnswer:SetText(text)
            TextAnswer:SetDark(true)
            TextAnswer:SizeToContents()
            TextAnswer:SetWrap(true)
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