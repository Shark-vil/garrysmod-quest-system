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
	if IsValid(npc) then
		for _, ent in ipairs(ents.FindByClass('quest_dialogue')) do
			if IsValid(ent) and ent:GetPlayer() == ply then
				local dialogue = ent:GetDialogue()

				if dialogue.isBackground then
					if ent:GetNPC() == npc then return end
				else
					return
				end
			end
		end

		local id = npc.npc_dialogue_id

		if id ~= nil then
			local dialogue = QuestDialogue:GetDialogue(id)
			if not QuestSystem:CheckRestiction(ply, dialogue.restriction) then return end
			local dialogue_ent = ents.Create('quest_dialogue')
			dialogue_ent:SetPos(ply:GetPos())
			dialogue_ent:Spawn()
			dialogue_ent:Activate()
			dialogue_ent:SetDialogueID(id)
			dialogue_ent:SetStep('start')
			dialogue_ent:SetPlayer(ply)
			dialogue_ent:SetNPC(npc)
			dialogue_ent:StartDialogue()
			ply.npc_dialogue_delay = RealTime() + 1
		end
	end
end)

net.Receive('sv_qsystem_close_npc_dialogue_menu', function(len, ply)
	for _, ent in pairs(ents.FindByClass('quest_dialogue')) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			ent:Remove()
		end
	end
end)

net.Receive('sv_qsystem_dialogue_answer_select', function(len, ply)
	for _, ent in pairs(ents.FindByClass('quest_dialogue')) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			local id = net.ReadInt(10)
			local step = ent:GetStep()

			if step.answers[id] ~= nil then
				local condition = step.answers[id].condition
				if condition ~= nil and not condition(ent) then return end

				local func = step.answers[id].event
				func(ent)
				ent.isFirstAnswer = true
			end

			break
		end
	end
end)

net.Receive('sv_qsystem_dialogue_answer_onclick', function(len, ply)
	for _, ent in pairs(ents.FindByClass('quest_dialogue')) do
		if IsValid(ent) and ent:GetPlayer() == ply then
			local step = ent:GetStep()
			if step.eventDelay ~= nil and not step.delay then
				step.eventDelay(ent)
			end
			break
		end
	end
end)