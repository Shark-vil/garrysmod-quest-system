AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

-------------------------------------
-- An entity deletes itself if one of the conditions is violated.
-------------------------------------
-- Wiki - https://wiki.facepunch.com/gmod/ENTITY:Think
-------------------------------------
function ENT:Think()
	if not self.isStarted then return end
	if not IsValid(self:GetNPC()) or not IsValid(self:GetPlayer()) or self:NpcIsFear() then
		self:Remove()
	end
end

-------------------------------------
-- Adds a dialog ID to a network variable.
-------------------------------------
-- @param id string - dialogue id
-------------------------------------
function ENT:SetDialogueID(id)
	self:slibSetVar('id', id)
	hook.Run('QSystem.ParentDialogueId', self, id)
end

-------------------------------------
-- Adds a dialog step to a network variable.
-------------------------------------
-- @param step_id string - dialogue step id
-------------------------------------
function ENT:SetStep(step_id)
	self:slibSetVar('step_id', step_id)
	hook.Run('QSystem.ParentDialogueStepId', self, step_id)
end

-------------------------------------
-- Adds the dialogue player to the network variable.
-------------------------------------
-- @param ply entity - player entity
-------------------------------------
function ENT:SetPlayer(ply)
	self:slibSetVar('player', ply)
	hook.Run('QSystem.ParentDialoguePlayer', self, ply)
end

-------------------------------------
-- Adds the entity with which the player has a conversation to the network variable.
-- If the entity does not exist, you can add the player himself as an interlocutor.
-------------------------------------
-- @param npc entity - entity of the interlocutor
-------------------------------------
function ENT:SetNPC(npc)
	self:slibSetVar('npc', npc)
	hook.Run('QSystem.ParentDialogueNPC', self, npc)
end

-------------------------------------
-- UNFINISHED
-------------------------------------
-- Creates a dialog box with text, and closes after a specified period of time.
-- This function has not yet been implemented very correctly, and is not recommended for use.
-- Use character dialog configs.
-------------------------------------
-- @param name string - interlocutor name
-- @param text string - dialogue text
-- @param delay number - window activity time
-------------------------------------
function ENT:SingleReplic(name, text, delay, overhead)
	self:slibSetVar('single_replic', text)
	self:slibSetVar('single_replic_name', name)
	self:slibSetVar('single_replic_delay', delay)
	self:slibSetVar('single_replic_overhead', overhead)
end

-------------------------------------
-- Switches the dialog to another step.
-------------------------------------
-- @param step_id string - step id
-- @param ignore_npc_text bool - if true, the NPC replic will be skipped
-------------------------------------
function ENT:Next(step_id, ignore_npc_text)
	ignore_npc_text = ignore_npc_text or false
	self:SetStep(step_id)

	timer.Simple(0.5, function()
		self:StartDialogue(ignore_npc_text, true)
	end)
end

-------------------------------------
-- Stops the dialog by deleting the dialog entity.
-------------------------------------
function ENT:Stop()
	self:Remove()
end

-------------------------------------
-- Checks the state of fear of the NPC. Used to stop the dialogue if NPCs are attacked.
-------------------------------------
-- @return bool - will return true if the NPC is in a state of fear, otherwise false
-------------------------------------
function ENT:NpcIsFear()
	local npc = self:GetNPC()

	if IsValid(npc) and npc:IsNPC() then
		local schedule = npc:GetCurrentSchedule()
		if npc:IsCurrentSchedule(SCHED_RUN_FROM_ENEMY)
			or npc:IsCurrentSchedule(SCHED_WAKE_ANGRY)
			or schedule == 159
		then
			return true
		end
	end

	return false
end