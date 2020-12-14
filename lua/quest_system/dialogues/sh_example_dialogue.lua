local conversation = {
    id = 'example_dialogue',
    name = 'Неизвестный гражданин',
    isRandomNpc = false,
    randomNumber = 5,
    npc_class = 'npc_barney',
    steps = {
        start = {
            text = {
                'Ты что-то хотел?',
                'А?..',
                'Чего надо?',
                'Да-да?',
                'Ммм...'
            },
            delay = 3,
            event = function(eDialogue)
                if CLIENT then
                    eDialogue:VoiceSay('vo/canals/matt_go_nag01.wav')
                end
            end,
            answers = {
                {
                    text = {
                        'Ничего, простите.',
                        'Обознался.'
                    },
                    event = function(eDialogue)
                        if SERVER then eDialogue:Next('exit') end
                    end
                },
                {
                    text = 'Продай мне немного аптечек',
                    event = function(eDialogue)
                        if SERVER then
                            local ply = eDialogue:GetPlayer()
                            if ply:Health() < 100 then
                                local npc = eDialogue:GetNPC()
                                npc.lock_health = npc.lock_health or {}

                                if table.HasValue(npc.lock_health, ply) then
                                    eDialogue:Next('rejection_health')
                                else
                                    eDialogue:Next('get_health')
                                end
                            else
                                eDialogue:Next('failed_health')
                            end
                        end
                    end
                },
            },
        },
        rejection_health = {
            text = 'Я тебя уже подлатал, больше аптечек не дам.',
            delay = 3,
            eventDelay = function(eDialogue)
                if SERVER then
                    eDialogue:Next('start', true)
                end
            end
        },
        get_health = {
            text = 'Ладно. Вот, держи немного.',
            delay = 3,
            eventDelay = function(eDialogue)
                if SERVER then
                    local ply = eDialogue:GetPlayer()
                    local health = ply:Health()

                    if health + 10 < 100 then
                        ply:SetHealth(health + 10)
                    else
                        ply:SetHealth(100)
                    end

                    local npc = eDialogue:GetNPC()
                    npc.lock_health = npc.lock_health or {}
                    table.insert(npc.lock_health, ply)

                    eDialogue:Next('start', true)
                end

                local dialogue = eDialogue:GetDialogue()
                table.insert(dialogue.steps.start.answers, {
                    text = 'Больше ничего не нужно, прощай.',
                    event = function(eDialogue)
                        if SERVER then print('stop') eDialogue:Stop() end
                    end
                })
            end
        },
        failed_health = {
            text = 'Ты не выглядишь таким уж помятым. Обойдёшься.',
            delay = 4,
            eventDelay = function(eDialogue)
                if SERVER then
                    eDialogue:Next('start', true)
                end
            end
        },
        exit = {
            text = {
                'Ебать ты...',
                'Зря время отнимаешь',
                'Ну тебя...',
                'Ладно.',
                'Ладно. Всего доброго',
                'Ну бывай'
            },
            delay = 3,
            eventDelay = function(eDialogue)
                if CLIENT then
                    eDialogue:VoiceSay('vo/canals/gunboat_dam.wav')
                else
                    eDialogue:Stop()
                end
            end
        }
    }
}

list.Set('QuestSystemDialogue', conversation.id, conversation)