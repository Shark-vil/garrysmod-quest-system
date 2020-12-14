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

function ENT:Initialize()
    self:SetModel('models/props_junk/PopCan01a.mdl')
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNoDraw(true)
end

function ENT:Think()
    if self.isStarted then
        if SERVER then
            if not IsValid(self:GetNPC()) or not IsValid(self:GetPlayer()) then
                self:Remove()
            end
        end
    end
end

function ENT:OnRemove()
    self:GetPlayer():Freeze(false)
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
    local step_id = self:GetStepID()
    return self:GetDialogue().steps[step_id]
end

function ENT:GetPlayer()
    return self:GetNWEntity('player')
end

function ENT:GetNPC()
    return self:GetNWEntity('npc')
end

function ENT:StartDialogue(ignore_npc_text)
    ignore_npc_text = ignore_npc_text or false

    if SERVER then
        local ply = self:GetPlayer()
        ply:Freeze(true)

        net.Start('cl_qsystem_set_dialogue_id')
        net.WriteEntity(self)
        net.WriteBool(ignore_npc_text)
        net.Send(ply)
    end

    -- if not ignore_npc_text then
        local step = self:GetStep()
        if step.eventDelay ~= nil then
            local delay = step.delay or 0
            timer.Simple(delay, function()
                if not IsValid(self) then return end
                step.eventDelay(self)
            end)
        end

        if step.event ~= nil then
            step.event(self)
        end
    -- end

    self.isStarted = true
end

function ENT:VoiceSay(sound_path, soundLevel, pitchPercent, volume, channel, soundFlags, dsp)
    soundLevel = soundLevel or 75
    pitchPercent = pitchPercent or 100
    volume = volume or 1
    channel = channel or CHAN_AUTO
    soundFlags = soundFlags or 0
    dsp = dsp or 0

    self:GetNPC():EmitSound(sound_path, soundLevel, pitchPercent, volume, channel, soundFlags, dsp)
end