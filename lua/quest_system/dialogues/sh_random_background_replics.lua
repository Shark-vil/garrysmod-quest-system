local conversation = {
    id = 'citizens_random_replics',
    name = 'Гражданин',
    isBackground = true,
    isRandomNpc = true,
    class = 'npc_citizen',
    model = {
        'models/props_junk/PopCan01a.mdl'
    },
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