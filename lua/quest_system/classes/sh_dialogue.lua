QuestDialogue = {}

function QuestDialogue:IsValidParentNPCDialogue(npc, ply, data)
    local nice = true

    if data.npc_class ~= nil then
        if isstring(data.npc_class) then
            if data.npc_class ~= npc:GetClass() then nice = false end
        end

        if istable(data.npc_class) then
            if not table.HasValue(data.npc_class, npc:GetClass()) then nice = false end
        end
    end

    if data.condition ~= nil then
        if not data.condition(ply, npc) then nice = false end
    end

    return nice
end

function QuestDialogue:GetDialogue(id)
    return list.Get('QuestSystemDialogue')[id]
end

function QuestDialogue:GetAllDialogues(randomOnly)
    randomOnly = randomOnly or false
    if randomOnly then
        local data = {}
        for key, value in pairs(list.Get('QuestSystemDialogue')) do
            if value.isRandomNpc then
                data[key] = value
            end
        end
        return data
    else
        return list.Get('QuestSystemDialogue')
    end
end

function QuestDialogue:ParentToNPC(npc, ply)
    do
        local dialogues = QuestDialogue:GetAllDialogues()
        for key, data in pairs(dialogues) do
            if self:IsValidParentNPCDialogue(npc, ply, data) and not data.isRandomNpc then
                npc.npc_dialogue_id = data.id
                break
            end
        end
    end

    do
        local dialogues = QuestDialogue:GetAllDialogues(true)
        if table.Count(dialogues) ~= 0 then
            local dialogue = table.Random(dialogues)
            
            if self:IsValidParentNPCDialogue(npc, ply, dialogue) then
                if dialogue.randomNumber ~= nil and dialogue.randomNumber > 0 then
                    if math.random(1, dialogue.randomNumber) ~= 1 then return end
                end

                npc.npc_dialogue_id = dialogue.id
            end
        end
    end
end
