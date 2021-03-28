local quest = {
    id = 'event_kill_combine',
    title = 'Убить комбайнов',
    description = 'Где-то высадился отряд вражеских комбайнов. Найдите и устраните их!',
    payment = 500,
    isEvent = true,
    notAddAllPlayers = true,
    npcNotReactionOtherPlayer = true,
    timeQuest = 120,
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then
                    local quest = eQuest:GetQuest()
                    eQuest:NotifyAll(quest.title, quest.description, 6)

                    eQuest:TimerCreate(function()
                        eQuest:NextStep('spawn_combines')
                    end, 20)
                end
            end,
            triggers = {
                spawn_combines_trigger = {
                    onEnter = function(eQuest, ent)
                        if CLIENT then return end
                        eQuest:AddPlayer(ent)
                    end,
                    onExit = function(eQuest, ent)
                        if CLIENT then return end
                        if not eQuest:HasQuester(ent) then return end
                        eQuest:RemovePlayer(ent)
                    end
                },
            },
        },
        spawn_combines = {
            construct = function(eQuest)
                if CLIENT then return end
                if #eQuest.players ~= 0 then
                    eQuest:NotifyOnlyRegistred('Враг близко', 'Убейте прибивших противников')
                else
                    eQuest:NotifyAll('Событие отменено', 'Событие не состоялось из-за нехватки игроков в зоне ивента.')
                    eQuest:Failed()
                    return true
                end
            end,
            structures = {
                barricades = true
            },
            points = {
                spawn_combines = function(eQuest, positions)
                    if CLIENT then return end

                    for _, pos in pairs(positions) do
                        local model = table.Random({
                            'models/Combine_Soldier.mdl',
                            'models/Combine_Soldier_PrisonGuard.mdl',
                            'models/Combine_Super_Soldier.mdl'
                        })

                        local weapon_class = table.Random({
                            'weapon_ar2',
                            'weapon_shotgun',
                        })
                        
                        eQuest:SpawnQuestNPC('npc_combine_s', {
                            type = 'enemy',
                            pos = pos,
                            model = model,
                            weapon_class = weapon_class
                        })
                    end

                    eQuest:MoveEnemyToRandomPlayer()
                end,
            },
            hooks = {
                OnNPCKilled = function(eQuest, npc, attacker, inflictor)
                    if CLIENT then return end

                    local combines = eQuest:GetQuestNpc('enemy')
                    for _, npc in pairs(combines) do
                        if IsValid(npc) and npc:Health() > 0 then
                            return
                        end
                    end

                    eQuest:NextStep('complete')
                end
            }
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:NotifyOnlyRegistred('Завершено', 'Все противники были уничтожены')
                eQuest:Reward()
                eQuest:Complete()
            end,
        }
    }
}

list.Set('QuestSystem', quest.id, quest)