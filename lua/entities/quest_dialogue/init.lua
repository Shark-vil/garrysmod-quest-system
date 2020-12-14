AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SetDialogueID(id)
    self:SetNWString('id', id)
end

function ENT:SetStep(step_id)
    self:SetNWString('step_id', step_id)
end

function ENT:SetPlayer(ply)
    self:SetNWEntity('player', ply)
end

function ENT:SetNPC(npc)
    self:SetNWEntity('npc', npc)
end

function ENT:Next(step_id, ignore_npc_text)
    ignore_npc_text = ignore_npc_text or false
    self:SetStep(step_id)
    timer.Simple(0.5, function()
        self:StartDialogue(ignore_npc_text)
    end)
end

function ENT:Stop()
    self:Remove()
end