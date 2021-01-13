local conversation = {
    id = 'citizens_random_replics',
    name = 'Гражданин',
    isBackground = true,
    isRandomNpc = true,
    class = 'npc_citizen',
    steps = {
        start = {
            text = {
                'Тебе чего надо?',
                'У меня сейчас нету времени на разговоры',
                'Отвянь',
                'А? Чего?',
                '...'
            },
            delay = 4,
            eventDelay = function(eDialogue)
                if CLIENT then return end 
                eDialogue:Stop()
            end,
        }
    }
}

list.Set('QuestSystemDialogue', conversation.id, conversation)