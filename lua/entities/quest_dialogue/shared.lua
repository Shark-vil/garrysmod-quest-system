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
        -------------------------------------
        -- Renders the background dialog text above the NPC's head.
        -------------------------------------
        -- Wiki - https://wiki.facepunch.com/gmod/GM:PostDrawOpaqueRenderables
        -------------------------------------
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
    else
        -------------------------------------
        -- Provides visibility of the entity of the dialogue to clients.
        -- Otherwise, clients may not receive data.
		-------------------------------------
		-- Wiki - https://wiki.facepunch.com/gmod/GM:SetupPlayerVisibility
		-------------------------------------
        hook.Add('SetupPlayerVisibility', self, function(this, pPlayer, pViewEntity)
            AddOriginToPVS(self:GetPos())
            local npc = self:GetNPC()
            if IsValid(npc) then
                AddOriginToPVS(npc:GetPos())
            end
		end)
    end

    timer.Simple(1, function()
        if not IsValid(self) then return end
        hook.Run('QSystem.StartDialogue', self)
    end)
end

-------------------------------------
-- An entity deletes itself if one of the conditions is violated.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/ENTITY:Think
-------------------------------------
function ENT:Think()
    if self.isStarted then
        if SERVER then
            if not IsValid(self:GetNPC()) or not IsValid(self:GetPlayer()) 
                or (self:NpcIsFear() and not self:GetDialogue().isBackground) 
            then
                self:Remove()
                return
            end
        end
    end
end

-------------------------------------
-- Saves data about the first dialogue and unfreezes the player if it is frozen.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/ENTITY:OnRemove
-------------------------------------
function ENT:OnRemove()
    if SERVER then
        QuestService:WaitingNPCWalk(self:GetNPC(), false)

        if not self:AlreadySaid() then
            self:SavePlayerValue('already_said', true, true)
        end
    
        local dialogue = self:GetDialogue()
        if not dialogue.isBackground and not dialogue.notFreeze then
            self:GetPlayer():Freeze(false)
        end
    end

    hook.Run('QSystem.StopDialogue', self)
end

-------------------------------------
-- Gets the dialog data table.
-------------------------------------
-- @return table - dialogue data table
-------------------------------------
function ENT:GetDialogue()
    if self:GetNWString('single_replic') ~= '' then
        return {
            name = self:GetNWString('single_replic_name'),
            notFreeze = true,
            notLook = true,
            isBackground = self:GetNWBool('single_replic_is_background'),
            steps = {
                start = {
                    text = self:GetNWString('single_replic'),
                    delay = self:GetNWFloat('single_replic_delay'),
                    eventDelay = function(eDialogue)
                        if CLIENT then return end 
                        eDialogue:Stop()
                    end,
                },
            }
        }
    else
        self.dialogue = self.dialogue or QuestDialogue:GetDialogue(self:GetDialogueID())
        return self.dialogue
    end
end

-------------------------------------
-- Get the ID of the conversation.
-------------------------------------
-- @return string - dialogue id
-------------------------------------
function ENT:GetDialogueID()
    return self:GetNWString('id')
end

-------------------------------------
-- Get the id of the current dialog step.
-------------------------------------
-- @return string - step id
-------------------------------------
function ENT:GetStepID()
    return self:GetNWString('step_id')
end

-------------------------------------
-- Get the data for the current step.
-------------------------------------
-- @return table - step data table
-------------------------------------
function ENT:GetStep()
    local step = self:GetDialogue().steps[self:GetStepID()]

    if step.answers and isfunction(step.answers) then
        local func = step.answers
        step.answers = func(self)
    end

    if step.text and isfunction(step.text) then
        local func = step.text
        step.text = func(self)
    end

    return step
end

-------------------------------------
-- Get the entity of the player.
-------------------------------------
-- @return entity - player entity
-------------------------------------
function ENT:GetPlayer()
    return self:GetNWEntity('player')
end

-------------------------------------
-- Get the player interlocutor entity.
-------------------------------------
-- @return entity - specific entity
-------------------------------------
function ENT:GetNPC()
    return self:GetNWEntity('npc')
end

-------------------------------------
-- Checks if the player is using this dialogue for the first time or not.
-------------------------------------
-- @return bool - will return true if the player has already used this dialog, otherwise false
-------------------------------------
function ENT:AlreadySaid()
    local value = self:GetPlayerValue('already_said')
    if value == nil then value = false end
    return tobool(value)
end

-------------------------------------
-- Reads a custom variable from a file and writes to the entity network variable.
-------------------------------------
-- @param value_name string - custom variable key in dialog
-------------------------------------
-- @return string - will return a string with the data of a variable or nil
-------------------------------------
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

-------------------------------------
-- Starts a dialogue between the player and the interlocutor.
-------------------------------------
-- @param ignore_npc_text bool - pass true if you want to skip the NPC replic
-- @param is_next bool - convey the truth if the dialogue continues (By default assigned automatically)
-------------------------------------
function ENT:StartDialogue(ignore_npc_text, is_next)
    ignore_npc_text = ignore_npc_text or false
    is_next = is_next or false

    local ply = self:GetPlayer()

    local function initStep()
        local step = self:GetStep()
        local delay = step.delay or 0
        if step.eventDelay ~= nil then
            timer.Simple(delay + 0.5, function()
                if not IsValid(self) then return end
                step.eventDelay(self)
            end)
        end

        if step.event ~= nil then
            step.event(self)
        end

        self.isStarted = true
        self.isFirst = false
    end

    local max_validator_pass = 5
    local current_pass = 0

    local function validator()
        if not IsValid(self) then return end

        current_pass = current_pass + 1

        snet.IsValidForClient(ply, function(_, success)
            if not success then 
                if current_pass == max_validator_pass then
                    self:Remove()
                    return
                end

                timer.Simple(0.1, validator)
                return
            end

            if self:GetNWString('single_replic') ~= '' and (self:NpcIsFear() 
                and not self:GetDialogue().isBackground) 
            then
                self:Remove()
                return
            end
            
            if not is_next and self:GetNWString('single_replic') == '' then
                local dialogue = self:GetDialogue()
                if not dialogue.isBackground and not dialogue.notFreeze then
                    ply:Freeze(true)
                    QuestService:WaitingNPCWalk(self:GetNPC(), true)
                end

                self:LoadPlayerValues()
            end
            
            snet.Invoke('cl_qsystem_set_dialogue_id', ply, self, ignore_npc_text, is_next)
            initStep()
        end, 'dialogue', nil, nil, self)
    end

    if SERVER then
        validator()
    else
        initStep()
    end
end

-------------------------------------
-- Plays the sound coming from the player's interlocutor.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/Entity:EmitSound
-------------------------------------
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