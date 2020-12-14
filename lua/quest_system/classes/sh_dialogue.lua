QuestDialogue = {}

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