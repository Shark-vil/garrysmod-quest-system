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

function QuestDialogue:GetAllDialogues()
    return list.Get('QuestSystemDialogue')
end

function QuestDialogue:GetAllRandom()
    local data = {}
    for key, value in pairs(list.Get('QuestSystemDialogue')) do
        if value.isRandomNpc then
            data[key] = value
        end
    end
    return data
end

function QuestDialogue:GetAllBackground()
    local data = {}
    for key, value in pairs(list.Get('QuestSystemDialogue')) do
        if value.isBackground then
            data[key] = value
        end
    end
    return data
end

function QuestDialogue:AutoParentToNPC(npc, ply)
    local dialogues = QuestDialogue:GetAllDialogues()

    for key, data in pairs(dialogues) do
        if self:IsValidParentNPCDialogue(npc, ply, data) then
            local is_done = true

            if data.randomNumber ~= nil and data.randomNumber > 0 then
                if math.random(1, data.randomNumber) ~= 1 then is_done = false end
            end

            if is_done then
                npc.npc_dialogue_id = data.id
                break
            end
        end
    end
end

function QuestDialogue:ParentToNPC(id, npc, ply, ignore_valid, ignore_random)
    local dialogue = QuestDialogue:GetDialogue(id)

    if dialogue ~= nil then
        if not self:IsValidParentNPCDialogue(npc, ply, dialogue) and not ignore_valid then
            return
        end

        if not ignore_random and data.randomNumber ~= nil and data.randomNumber > 0 then
            if math.random(1, data.randomNumber) ~= 1 then 
                return
            end
        end

        npc.npc_dialogue_id = id
    end
end
