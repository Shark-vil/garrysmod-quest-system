util.AddNetworkString('sv_qsystem_close_npc_dialogue_menu')
util.AddNetworkString('sv_qsystem_dialogue_answer_select')
util.AddNetworkString('cl_qsystem_set_dialogue_id')

hook.Add('PlayerSpawnedNPC', 'QSystem.SetNpcDialogue', function(ply, ent)
    if IsValid(ent) and ent:IsNPC() then
        do
            local dialogues = QuestDialogue:GetAllDialogues()
            for key, data in pairs(dialogues) do
                if data.npc_class ~= nil then
                    if isstring(data.npc_class) then
                        if data.npc_class ~= ent:GetClass() then break end
                    end

                    if istable(data.npc_class) then
                        if table.HasValue(data.npc_class, ent:GetClass()) then break end
                    end
                    
                    ent.npc_dialogue_id = data.id
                    break
                end
            end
        end

        do
            local dialogues = QuestDialogue:GetAllDialogues(true)
            if #dialogues ~= 0 then
                local dialogue = table.Random(dialogues)

                if dialogue.randomNumber ~= nil then
                    if math.random(1, dialogue.randomNumber) ~= 1 then return end
                end

                ent.npc_dialogue_id = dialogue.id
            end
        end
    end
end)

hook.Add('PlayerUse', 'QSystem.OpenNpcDialogueMenu', function(ply, ent)
    if IsValid(ent) and ent:IsNPC() then
        for _, ent in pairs(ents.FindByClass('quest_dialogue')) do
            if IsValid(ent) and ent:GetPlayer() == ply then return end
        end
        
        local id = ent.npc_dialogue_id
        if id ~= nil then
            local dialogue_ent = ents.Create('quest_dialogue')
            dialogue_ent:SetPos(ply:GetPos())
            dialogue_ent:Spawn()
            dialogue_ent:SetDialogueID(id)
            dialogue_ent:SetStep('start')
            dialogue_ent:SetPlayer(ply)
            dialogue_ent:SetNPC(ent)

            timer.Simple(0.6, function()
                dialogue_ent:StartDialogue()
            end)
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
    for _, ent in pairs( ents.FindByClass('quest_dialogue')) do
        if IsValid(ent) and ent:GetPlayer() == ply then
            local id = net.ReadInt(10)
            local step = ent:GetStep()

            if step.answers[id] ~= nil then
                local func = step.answers[id].event
                func(ent)
            end
            break
        end
    end
end)