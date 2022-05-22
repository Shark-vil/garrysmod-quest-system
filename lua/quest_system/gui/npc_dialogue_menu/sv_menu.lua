util.AddNetworkString('sv_qsystem_close_npc_dialogue_menu')
util.AddNetworkString('sv_qsystem_dialogue_answer_select')
util.AddNetworkString('sv_qsystem_dialogue_answer_onclick')

hook.Add('PlayerSpawnedNPC', 'QSystem.SetNpcDialogue', function(ply, ent)
	QuestDialogue:AutoParentToNPC(ent, ply)
end)

hook.Add('PlayerSpawnedProp', 'QSystem.PlayerSpawnedProp', function(ply, model, ent)
	QuestDialogue:AutoParentToNPC(ent, ply)
end)

hook.Add('PlayerUse', 'QSystem.OpenNpcDialogueMenu', function(ply, npc)
	if not IsValid(npc) then return end

	ply.npc_dialogue_delay = ply.npc_dialogue_delay or 0
	if ply.npc_dialogue_delay > RealTime() then return end

	for _, eDialogue in ipairs(QuestSystem.Storage.Dialogues) do
		if IsValid(eDialogue) and eDialogue:GetNPC() == npc then
			local dialogue = eDialogue:GetDialogue()
			if dialogue and (dialogue.singleton or dialogue.overhead) then return end
			if eDialogue:GetPlayer() == ply then return end
		end
	end

	local dialogue_id = npc.npc_dialogue_id
	if not dialogue_id or not isstring(dialogue_id) then return end

	local dialogue = QuestDialogue:GetDialogue(dialogue_id)
	if not QuestSystem:CheckRestiction(ply, dialogue.restriction) then return end

	local eDialogueEntity = ents.Create('quest_dialogue')
	eDialogueEntity:SetPos(ply:GetPos())
	eDialogueEntity:Spawn()
	eDialogueEntity:Activate()
	eDialogueEntity:SetDialogueID(dialogue_id)
	eDialogueEntity:SetPlayer(ply)
	eDialogueEntity:SetNPC(npc)

	snet.Invoke('cl_qsystem_instance_dialogue', ply, eDialogueEntity)

	ply.npc_dialogue_delay = RealTime() + 1
end)

snet.Callback('sv_qsystem_instance_dialogue', function(ply, eDialogueEntity)
	if not IsValid(eDialogueEntity) or eDialogueEntity:GetPlayer() ~= ply then return end
	eDialogueEntity:SetStep('start')
end)

snet.Callback('sv_qsystem_start_dialogue', function(ply, eDialogueEntity)
	if not IsValid(eDialogueEntity) or eDialogueEntity:GetPlayer() ~= ply then return end
	eDialogueEntity:StartDialogue()
end)

net.Receive('sv_qsystem_close_npc_dialogue_menu', function(len, ply)
	for _, ent in ipairs(QuestSystem.Storage.Dialogues) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			ent:Remove()
		end
	end
end)

net.Receive('sv_qsystem_dialogue_answer_select', function(len, ply)
	for _, ent in ipairs(QuestSystem.Storage.Dialogues) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			local id = net.ReadInt(10)
			local step = ent:GetStep()

			local step_data = step.answers[id]
			local condition = QuestSystem:CallTableSSC(step_data, 'condition', ent)
			if condition and (not condition.server or not condition.basic) then
				return
			end

			QuestSystem:CallTableSSC(step_data, 'event', ent)
			ent.isFirstAnswer = true

			break
		end
	end
end)

net.Receive('sv_qsystem_dialogue_answer_onclick', function(len, ply)
	for _, ent in ipairs(QuestSystem.Storage.Dialogues) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			local step = ent:GetStep()
			if step.delay then
				QuestSystem:CallTableSSC(step, 'eventDelay', ent)
			end

			QuestSystem:CallTableSSC(step, 'event', ent)
			break
		end
	end
end)