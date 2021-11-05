-- Global table for working with dialogs
QuestDialogue = {}

-------------------------------------
-- Checks for the correctness of the entity class and model, as well as the condition for issuing a dialog.
-------------------------------------
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-- @param data table - dialogue data
-------------------------------------
-- @return bool - true if the entity matches validation, else false
-------------------------------------
function QuestDialogue:IsValidParentNPCDialogue(npc, ply, data)
	local is_valid_parent = true

	if data.class then
		is_valid_parent = false
		local npc_class = npc:GetClass():lower()

		if isstring(data.class) and data.class:lower() == npc_class then
			is_valid_parent = true
		elseif istable(data.class) then
			for _, v in ipairs(data.class) do
				if v:lower() == npc_class then
					is_valid_parent = true
					break
				end
			end
		end
	end

	if is_valid_parent and data.model then
		is_valid_parent = false
		local npc_model = npc:GetModel():lower()

		if isstring(data.model) then
			if data.model:lower() == npc_model then
				is_valid_parent = true
			end
		elseif istable(data.model) then
			for _, v in pairs(data.model) do
				if v:lower() == npc_model then
					is_valid_parent = true
					break
				end
			end
		end
	end

	if is_valid_parent and data.condition then
		local result = data.condition(ply, npc)
		if isbool(result) and result == false then is_valid_parent = false end
	end

	if isnumber(data.parent_chance) and not slib.chance(data.parent_chance) then
		is_valid_parent = false
	end

	-- if not data.auto_parent then is_valid_parent = false end

	return is_valid_parent
end

-------------------------------------
-- Get dialog data from the global list using an identifier.
-------------------------------------
-- @param id string - dialogue id
-------------------------------------
-- @return table - dialog data table or nil if dialog doesn't exist
-------------------------------------
function QuestDialogue:GetDialogue(id)
	return list.Get('QuestSystemDialogue')[id]
end

-------------------------------------
-- Get a list of all registered dialogs.
-------------------------------------
-- @return table - list of all dialogs with IDs as keys
-------------------------------------
function QuestDialogue:GetAllDialogues()
	return list.Get('QuestSystemDialogue')
end

-------------------------------------
-- Automatic assignment of a dialogue ID for NPCs. Will not assign anything if checks fail.
-------------------------------------
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-- @param ignore_valid bool - pass true, if you want to ignore the validation check
-- @param ignore_auto_parent_locker bool - if true, then removes the constraint "auto_parent"
-------------------------------------
function QuestDialogue:AutoParentToNPC(npc, ply, ignore_valid, ignore_auto_parent_locker)
	local dialogues = QuestDialogue:GetAllDialogues()

	for key, data in pairs(dialogues) do
		if not ignore_auto_parent_locker and not data.auto_parent then continue end

		if self:IsValidParentNPCDialogue(npc, ply, data) then
			npc.npc_dialogue_id = data.id
			break
		end
	end
end

-------------------------------------
-- Assigning a specific dialogue ID for the NPC. Will not assign anything if checks fail.
-------------------------------------
-- @param id string - dialogue id
-- @param npc entity - any entity, not necessarily an NPC
-- @param ply entity - player entity
-- @param ignore_valid bool - pass true, if you want to ignore the validation check
-------------------------------------
function QuestDialogue:ParentToNPC(id, npc, ply, ignore_valid)
	local dialogue = QuestDialogue:GetDialogue(id)

	if not dialogue then return end
	if not self:IsValidParentNPCDialogue(npc, ply, dialogue) and not ignore_valid then return end

	npc.npc_dialogue_id = id
end

-------------------------------------
-- Starts a dialogue with the NPC.
-------------------------------------
-- @param id string - dialogue id
-- @param ply entity - player entity
-- @param npc entity - any entity, not necessarily an NPC
-------------------------------------
function QuestDialogue:SetPlayerDialogue(id, ply, npc)
	if QuestDialogue:GetDialogue(id) ~= nil then
		local dialogue_ent = ents.Create('quest_dialogue')
		dialogue_ent:Spawn()
		dialogue_ent:Activate()
		dialogue_ent:SetDialogueID(id)
		dialogue_ent:SetStep('start')
		dialogue_ent:SetPlayer(ply)
		dialogue_ent:SetNPC(npc)

		timer.Simple(1.5, function()
			dialogue_ent:StartDialogue()
		end)

		return dialogue_ent
	end

	return NULL
end

-------------------------------------
-- Start a single NPC replic without any functionality.
-------------------------------------
-- @param ply entity - player entity
-- @param npc entity - any entity, not necessarily an NPC
-- @param name string - interlocutor name
-- @param text string - dialogue text
-- @param delay number - window activity time
-------------------------------------
function QuestDialogue:SingleReplic(ply, npc, name, text, delay, overhead)
	if not isbool(overhead) then overhead = true end

	local dialogue_ent = ents.Create('quest_dialogue')
	dialogue_ent:Spawn()
	dialogue_ent:Activate()
	dialogue_ent:SingleReplic(name, text, delay, overhead)
	dialogue_ent:SetStep('start')
	dialogue_ent:SetPlayer(ply)
	dialogue_ent:SetNPC(npc)

	timer.Simple(1.5, function()
		dialogue_ent:StartDialogue()
	end)

	return dialogue_ent
end