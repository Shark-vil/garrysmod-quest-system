local quest = {
    id = 'kill_drug_dealer',
    title = 'Убить наркоторговца',
    description = 'Поступил заказ на убийство наркоторговца. Используйте для этого выданный вам лом, если его у вас нет.',
    payment = 500,
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then 
                    eQuest:GiveQuestWeapon('weapon_crowbar')
                else            
                    local quest = eQuest:GetQuest()
                    eQuest:Notify(quest.title, quest.description)
                end
            end,
            triggers = {
                spawn_dealer_trigger = {
                    onEnter = function(eQuest, ent)
                        if CLIENT then return end
                        if ent ~= eQuest:GetPlayer() then return end
                        eQuest:NextStep('spawn')
                    end,
                }
            }
        },
        spawn = {
            structures = {
                barricades = true
            },
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Враг близко', 'Наркоторговец где-то по близости. Найдите и убейте его.')
            end,
            points = {
                spawn_dealer = function(eQuest, positions)
                    if CLIENT then return end

                    local npc = eQuest:SpawnQuestNPC('npc_citizen', {
                        pos = table.Random(positions),
                        weapon_class = 'weapon_pistol',
                        type = 'enemy'
                    })

                    QuestDialogue:SingleReplic(eQuest:GetPlayer(), npc, 'Наркодиллер', 
                        'Чёрт, облава! Эй, кто бы там ни был, я буду защищаться!', 6)
                end,
            },
            onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
                if CLIENT then return end
                if not eQuest:QuestNPCIsValid('enemy') then
                    if eQuest:GetPlayer() == attacker then
                        if not eQuest:IsQuestWeapon(attacker:GetActiveWeapon()) then
                            eQuest:Notify('Провалено', 'Вы использовали не то оружие.')
                            eQuest:Failed()
                        else
                            eQuest:NextStep('complete')
                        end
                    else
                        eQuest:NextStep('compensation')
                    end
                end
            end
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Наркоторговец был устранён. Наш заказчик будет доволен.')
                eQuest:Reward()
                eQuest:Complete()
            end,
        },
        compensation = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Наркоторговец был устранён, но не вами. Вы получите компенсацию за задание.')
                eQuest:Reparation()
                eQuest:Complete()
            end,
        }
    }
}

list.Set('QuestSystem', quest.id, quest)