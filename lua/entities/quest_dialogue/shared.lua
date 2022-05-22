ENT.Type = 'anim'
ENT.Base = 'base_gmodentity'
ENT.PrintName = 'Dialogue Entity'
ENT.Author = ''
ENT.Contact = ''
ENT.Purpose = ''
ENT.Instructions = ''
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
		local text_color_upper_head = Color(255, 255, 255)

		-------------------------------------
		-- Renders the background dialog text above the NPC's head.
		-------------------------------------
		-- Wiki - https://wiki.facepunch.com/gmod/GM:PostDrawOpaqueRenderables
		-------------------------------------
		hook.Add('PostDrawOpaqueRenderables', self, function()
			local npc = self:GetNPC()
			if not IsValid(npc) then return end

			local dialogue = self:GetDialogue()
			if not dialogue then return end

			if not dialogue.overhead then
				hook.Remove('PostDrawOpaqueRenderables', self)
				return
			end

			if npc:GetPos():Distance(LocalPlayer():GetPos()) < 800 then
				if not lines then
					local step = self:GetStep()
					if not step then return end

					lines = {}
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

				local lines_count = #lines
				if lines_count == 0 then return end

				local angle = LocalPlayer():EyeAngles()
				angle:RotateAroundAxis(angle:Forward(), 90)
				angle:RotateAroundAxis(angle:Right(), 90)

				local vec = npc:OBBMaxs()

				cam.Start3D2D(npc:GetPos() + npc:GetForward() + npc:GetUp() * vec.z, angle, 0.25)
					local ypos = -15

					for i = 1, lines_count do
						local text = lines[i]
						draw.SimpleTextOutlined(text, 'QuestSystemDialogueBackgroundText', 0, ypos, text_color_upper_head, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
						ypos = ypos + 15
					end
				cam.End3D2D()
			end
		end)
	end

	timer.Simple(1, function()
		if not IsValid(self) then return end
		hook.Run('QSystem.StartDialogue', self)
	end)

	table.insert(QuestSystem.Storage.Dialogues, self)
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

		if not dialogue.overhead and not dialogue.dont_lock_control then
			self:GetPlayer():Freeze(false)
		end
	end

	hook.Run('QSystem.StopDialogue', self)

	table.RemoveValueBySeq(QuestSystem.Storage.Dialogues, self)
end

-------------------------------------
-- Gets the dialog data table.
-------------------------------------
-- @return table - dialogue data table
-------------------------------------
function ENT:GetDialogue()
	if isstring(self:slibGetVar('single_replic')) then
		return {
			name = self:slibGetVar('single_replic_name'),
			dont_lock_control = true,
			dont_focus_on_target = true,
			overhead = self:slibGetVar('single_replic_overhead'),
			steps = {
				start = {
					text = self:slibGetVar('single_replic'),
					delay = self:slibGetVar('single_replic_delay'),
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
	return self:slibGetVar('id')
end

-------------------------------------
-- Get the id of the current dialog step.
-------------------------------------
-- @return string - step id
-------------------------------------
function ENT:GetStepID()
	return self:slibGetVar('step_id')
end

-------------------------------------
-- Get the data for the current step.
-------------------------------------
-- @return table - step data table
-------------------------------------
function ENT:GetStep()
	local step = self:GetDialogue().steps[self:GetStepID()]
	if not step then return end

	if step.answers and isfunction(step.answers) then
		local func = step.answers
		step.answers = func(self)
	end

	if step.text and isfunction(step.text) then
		local func = step.text
		local result = func(self)
		if isstring(result) then
			step.text = result
		elseif istable(result) then
			local table_value = table.RandomBySeq(result)
			if table_value then step.text = result end
		end
	end

	return step
end

-------------------------------------
-- Get the entity of the player.
-------------------------------------
-- @return entity - player entity
-------------------------------------
function ENT:GetPlayer()
	return self:slibGetVar('player')
end

-------------------------------------
-- Get the player interlocutor entity.
-------------------------------------
-- @return entity - specific entity
-------------------------------------
function ENT:GetNPC()
	return self:slibGetVar('npc')
end

-------------------------------------
-- Checks if the player is using this dialogue for the first time or not.
-------------------------------------
-- @return bool - will return true if the player has already used this dialog, otherwise false
-------------------------------------
function ENT:AlreadySaid()
	return tobool(self:GetPlayerValue('already_said'))
end

-------------------------------------
-- Loads custom network variables, if they exist.
-------------------------------------
function ENT:LoadPlayerValues()
	local ply = self:GetPlayer()
	if not IsValid(ply) then return end

	local dialogue_id = self:GetDialogueID()
	if not dialogue_id then return end

	local file_path = 'quest_system/dialogue/' .. ply:PlayerId()
	file_path = file_path .. '/' .. dialogue_id .. '.json'

	if file.Exists(file_path, 'DATA') then
		local dialogue_values = util.JSONToTable(file.Read(file_path, 'DATA'))
		for key, value in pairs(dialogue_values) do
			if self:slibGetVar('var_' .. key) then continue end
			self:slibSetVar('var_' .. key, value)
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
	if not IsValid(ply) or not isstring(value_name) then return false end

	local dialogue_id = self:GetDialogueID()
	if not dialogue_id then return false end

	local file_path = 'quest_system/dialogue/' .. ply:PlayerId()

	if not file.Exists(file_path, 'DATA') then
		file.CreateDir(file_path)
	end

	file_path = file_path .. '/' .. dialogue_id .. '.json'

	local dialogue_values

	if not file.Exists(file_path, 'DATA') then
		dialogue_values = {}
	else
		dialogue_values = util.JSONToTable(file.Read(file_path, 'DATA'))
	end

	dialogue_values[value_name] = value
	file.Write(file_path, util.TableToJSON(dialogue_values))

	if not not_autoload then
		self:slibSetVar('var_' .. value_name, value)
	end

	return true
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
	if not player_id then
		local ply = self:GetPlayer()
		if not IsValid(ply) then return false end
		player_id = ply:PlayerId()
	end

	if not player_id then return false end

	local dialogue_id = self:GetDialogueID()
	if not dialogue_id then return false end

	local file_path = 'quest_system/dialogue/' .. player_id
	file_path = file_path .. '/' .. dialogue_id .. '.json'

	if file.Exists(file_path, 'DATA') then
		local dialogue_values = util.JSONToTable(file.Read(file_path, 'DATA'))
		dialogue_values[value_name] = nil
		file.Write(file_path, util.TableToJSON(dialogue_values))
		self:slibSetVar('var_' .. value_name, nil)
	end

	return true
end

-------------------------------------
-- Reads a custom variable from a file and writes to the entity network variable.
-------------------------------------
-- @param value_name string - custom variable key in dialog
-------------------------------------
-- @return string - will return a string with the data of a variable or nil
-------------------------------------
function ENT:GetPlayerValue(value_name, get_type)
	local value = self:slibGetVar('var_' .. value_name)

	if value == nil then
		local ply = self:GetPlayer()

		if IsValid(ply) then
			local dialogue_id = self:GetDialogueID()
			if not dialogue_id then return nil end

			local file_path = 'quest_system/dialogue/' .. ply:PlayerId()
			file_path = file_path .. '/' .. dialogue_id .. '.json'

			if file.Exists(file_path, 'DATA') then
				local dialogue_values = util.JSONToTable(file.Read(file_path, 'DATA'))
				if dialogue_values[value_name] then
					value = dialogue_values[value_name]
					self:slibSetVar('var_' .. value_name, value)
				end
			end
		end
	end

	if get_type == 'string' or get_type == 'str' then
		return tostring(value)
	end

	if get_type == 'number' or get_type == 'num' then
		return tonumber(value)
	end

	if get_type == 'boolean' or get_type == 'bool' then
		return tobool(value)
	end

	return value
end

function ENT:InittDialogueStep()
	local step = self:GetStep()

	if step.delay then
		timer.Simple(step.delay + 0.5, function()
			if not IsValid(self) then return end
			QuestSystem:CallTableSSC(step, 'eventDelay', self)
		end)
	end

	-- QuestSystem:CallTableSSC(step, 'event', self)

	self.isStarted = true
	self.isFirst = false
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

	if SERVER then
		local single_replic_exists = self:slibGetVar('single_replic') ~= ''

		if single_replic_exists and self:NpcIsFear() and not self:GetDialogue().overhead then
			self:Remove()
			return
		end
	end

	if not is_next and not single_replic_exists then
		if SERVER then
			local dialogue = self:GetDialogue()
			if not dialogue.overhead and not dialogue.dont_lock_control then
				ply:Freeze(true)
				QuestService:WaitingNPCWalk(self:GetNPC(), true)
			end
		end

		self:LoadPlayerValues()
	end

	if SERVER then
		snet.Request('cl_qsystem_set_dialogue_id', self, ignore_npc_text, is_next).Complete(function()
			self:InittDialogueStep()
		end).Invoke(ply)
	end

	if CLIENT then
		self:InittDialogueStep()
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