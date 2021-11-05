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
-- Loads custom network variables, if they exist.
-------------------------------------
function ENT:LoadPlayerValues()
	local ply = self:GetPlayer()

	if IsValid(ply) then
		local file_path = 'quest_system/dialogue/' .. ply:PlayerId()
		file_path = file_path .. '/' .. self:GetDialogueID()
		file_path = file_path .. '/'
		local files_values = file.Find(file_path .. '*', 'DATA')

		for _, file_name in pairs(files_values) do
			local value_name = string.Split(file_name, '.')
			local value = self:slibGetVar('var_' .. value_name[1])

			if not value then
				value = file.Read(file_path .. file_name, 'DATA')
				self:slibSetVar('var_' .. value_name[1], value)
			end
		end
	end
end

-------------------------------------
-- Saves the user variable to the database, and connects in real time if necessary.
-------------------------------------
-- @param value_name string - variable key
-- @param value string - variable value (string only)
-- @param not_autoload bool - if true, the variable will not be uploaded to the network immediately after saving
-------------------------------------
-- @return bool - returns true if the variable was saved, false otherwise
-------------------------------------
function ENT:SavePlayerValue(value_name, value, not_autoload)
	local ply = self:GetPlayer()

	if IsValid(ply) then
		local file_path = 'quest_system/dialogue/' .. ply:PlayerId()

		if not file.Exists(file_path, 'DATA') then
			file.CreateDir(file_path)
		end

		file_path = file_path .. '/' .. self:GetDialogueID()

		if not file.Exists(file_path, 'DATA') then
			file.CreateDir(file_path)
		end

		file_path = file_path .. '/' .. value_name .. '.txt'
		value = tostring(value)
		file.Write(file_path, value)

		if not not_autoload then
			self:slibSetVar('var_' .. value_name, value)
		end

		return true
	end

	return false
end

-------------------------------------
-- Deletes the network variable data file.
-------------------------------------
-- @param value_name string - variable key
-- @param player_id string - player id (default nil, since the player can be obtained automatically)
-------------------------------------
-- @return bool - returns true if the variable was removed, false otherwise
-------------------------------------
function ENT:RemovePlayerValue(value_name, player_id)
	if player_id == nil then
		local ply = self:GetPlayer()

		if IsValid(ply) then
			player_id = ply:PlayerId()
		end
	end

	if player_id ~= nil then
		local file_path = 'quest_system/dialogue/' .. player_id
		file_path = file_path .. '/' .. self:GetDialogueID()
		file_path = file_path .. '/' .. value_name .. '.txt'

		if file.Exists(file_path, 'DATA') then
			file.Remove(file_path)
			return true
		end
	end

	return false
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
		if npc:IsCurrentSchedule(SCHED_RUN_FROM_ENEMY) or npc:IsCurrentSchedule(SCHED_WAKE_ANGRY) or schedule == 159 then return true end
	end

	return false
end