local conversation = {
    id = 'citizens_random_replics',
    name = 'Гражданин',
    isBackground = true,
    isRandomNpc = true,
    class = 'npc_citizen',
    condition = function(ply, ent)
        if ent:GetModel():lower() == ('models/props_junk/PopCan01a.mdl'):lower() then
            if math.random(0, 10) ~= 1 then
                return false
            end
        end
    end,
    start = {
        text = {
            'Тебе чего надо?',
            'У меня сейчас нету времени на разговоры',
            'Отвянь',
            'А? Чего?',
            '...'
        },
        delay = 4
    }
}

list.Set('QuestSystemDialogue', conversation.id, conversation)