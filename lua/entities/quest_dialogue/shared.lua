ENT.Type = "anim"  
ENT.Base = "base_gmodentity"     
ENT.PrintName = "Dialogue Entity"  
ENT.Author = ""  
ENT.Contact = ""  
ENT.Purpose	= ""  
ENT.Instructions = ""  

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.conversation = nil
ENT.isStarted = false
ENT.isFirst = true
ENT.isFirstAnswer = false

function ENT:Initialize()
    self:SetModel('models/props_junk/PopCan01a.mdl')
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNoDraw(true)

    if CLIENT then
        local lines = nil
        hook.Add('PostDrawOpaqueRenderables', self, function()
            local npc = self:GetNPC()
    
            if IsValid(npc) then
                local dialogue = self:GetDialogue()
                
                if dialogue ~= nil then
                    if not dialogue.isBackground then
                        hook.Remove('PostDrawOpaqueRenderables', self)
                        return
                    end
                    
                    if npc:GetPos():Distance(LocalPlayer():GetPos()) < 800 then    
                        if lines == nil then
                            lines = {}
                            local step = self:GetStep()
                            local text = ''
                            if step.text ~= nil then
                                if isstring(step.text) then
                                    text = step.text
                                elseif istable(step.text) then
                                    text = table.Random(step.text)
                                end
                            end
    
                            text = utf8.force(text)
                            local maxLineSize = 50
                            local startPos = 1
                            local endPos = maxLineSize
                            local str_len = utf8.len(text)
                            if str_len >= maxLineSize then
                                for i = 1, str_len do
                                    if endPos == i then
                                        local line = utf8.sub(text, startPos, endPos)
                                        table.insert(lines, string.Trim(line))
    
                                        startPos = i
                                        endPos = endPos + maxLineSize
                                        if endPos > str_len then
                                            endPos = str_len
                                        end
                                    end
                                end
                            end
    
                            if #lines == 0 then
                                table.insert(lines, text)
                            end
                        end
            
                        local angle = LocalPlayer():EyeAngles()
                        angle:RotateAroundAxis(angle:Forward(), 90)
                        angle:RotateAroundAxis(angle:Right(), 90)
                        
                        local lengthLines = #lines
                        if lengthLines ~= 0 then
                            local vec = npc:OBBMaxs()
                            cam.Start3D2D(npc:GetPos() + npc:GetForward() + npc:GetUp() * vec.z, angle, 0.25)
                                local ypos = -15
                                for i = 1, lengthLines do
                                    local text = lines[i]
                                    draw.SimpleTextOutlined(text, 
                                        "QuestSystemDialogueBackgroundText", 0, ypos, Color(255, 255, 255), 
                                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
                                    
                                    ypos = ypos + 15
                                end
                            cam.End3D2D()
                        end
                    end
                end
            end
        end)
    end
end

function ENT:OnTakeDamage(damage)
    self:Remove()
end

function ENT:Think()
    if self.isStarted then
        if SERVER then
            if not IsValid(self:GetNPC()) or not IsValid(self:GetPlayer()) or self:NpcIsFear() then
                self:Remove()
                return
            end
        end
    end
end

function ENT:OnRemove()
    if SERVER then
        QuestService:WaitingNPCWalk(self:GetNPC(), false)

        if not self:AlreadySaid() then
            self:SavePlayerValue('already_said', true, true)
        end
    
        if not self:GetDialogue().isBackground then
            self:GetPlayer():Freeze(false)
        end
    end
end

function ENT:GetDialogue()
    self.dialogue = self.dialogue or QuestDialogue:GetDialogue(self:GetDialogueID())
    return self.dialogue
end

function ENT:GetDialogueID()
    return self:GetNWString('id')
end

function ENT:GetStepID()
    return self:GetNWString('step_id')
end

function ENT:GetStep()
    local dialogue = self:GetDialogue()
    if dialogue.isBackground then
        return dialogue.start
    else
        local step_id = self:GetStepID()
        return dialogue.steps[step_id]
    end
end

function ENT:GetPlayer()
    return self:GetNWEntity('player')
end

function ENT:GetNPC()
    return self:GetNWEntity('npc')
end

function ENT:AlreadySaid()
    local value = self:GetPlayerValue('already_said')
    if value == nil then value = false end
    return tobool(value)
end

function ENT:GetPlayerValue(value_name)
    local value = self:GetNWString('var_' .. value_name)

    if value ~= nil and #value ~= 0 then
        return value
    else
        local ply = self:GetPlayer()
        if IsValid(ply) then
            local file_path = 'quest_system/dialogue/'.. ply:PlayerId()
            file_path = file_path .. '/' .. self:GetDialogueID()
            file_path = file_path .. '/' .. value_name .. '.txt'

            if file.Exists(file_path, 'DATA') then
                local value = file.Read(file_path, "DATA")
                self:SetNWString('var_' .. value_name, value)
                return value
            end
        end
    end
    
    return nil
end

function ENT:StartDialogue(ignore_npc_text, is_next)
    ignore_npc_text = ignore_npc_text or false
    is_next = is_next or false

    if SERVER then
        if self:NpcIsFear() then
            self:Remove()
            return
        end

        local ply = self:GetPlayer()
        
        if not is_next then
            if not self:GetDialogue().isBackground then
                ply:Freeze(true)
                QuestService:WaitingNPCWalk(self:GetNPC(), true)
            end

            self:LoadPlayerValues()
        end

        net.Start('cl_qsystem_set_dialogue_id')
        net.WriteEntity(self)
        net.WriteBool(ignore_npc_text)
        net.WriteBool(is_next)
        net.Send(ply)
    end

    -- if not ignore_npc_text then
        local step = self:GetStep()
        local delay = step.delay or 0
        if step.eventDelay ~= nil then
            timer.Simple(delay, function()
                if not IsValid(self) then return end
                step.eventDelay(self)
            end)
        end

        if SERVER and self:GetDialogue().isBackground then
            timer.Simple(delay + 1, function()
                if not IsValid(self) then return end
                self:Remove()
            end)
        end

        if step.event ~= nil then
            step.event(self)
        end
    -- end

    self.isStarted = true
    self.isFirst = false
end

function ENT:VoiceSay(sound_path, soundLevel, pitchPercent, volume, channel, soundFlags, dsp)
    if not IsValid(self) or not IsValid(self:GetNPC()) then return end
    
    soundLevel = soundLevel or 75
    pitchPercent = pitchPercent or 100
    volume = volume or 1
    channel = channel or CHAN_AUTO
    soundFlags = soundFlags or 0
    dsp = dsp or 0

    self:GetNPC():EmitSound(sound_path, soundLevel, pitchPercent, volume, channel, soundFlags, dsp)
end