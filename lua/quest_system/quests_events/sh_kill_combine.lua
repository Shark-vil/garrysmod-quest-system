local quest = {
    id = 'event_kill_combine',
    title = 'Убить комбайнов',
    description = 'Где-то высадился отряд вражеских комбайнов. Найдите и устраните их!',
    payment = 500,
    isEvent = true,
    npcNotReactionOtherPlayer = true,
    timeToNextStep = 20,
    nextStep = 'spawn_combines',
    nextStepCheck = function(eQuest)
        if #eQuest.players ~= 0 then
            return true
        else
            eQuest:NotifyAll('Событие отменено', 'Событие не состоялось из-за нехватки игроков в зоне ивента.')
            return false
        end
    end,
    timeQuest = 120,
    failedText = {
        title = 'Задание провалено',
        text = 'Время выполнения истекло.'
    },
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then
                    local quest = eQuest:GetQuest()
                    eQuest:NotifyAll(quest.title, quest.description, 6)
                end
            end,
            triggers = {
                spawn_combines_trigger = function(eQuest, entities)
                    if CLIENT then return end
                    for _, ent in pairs(entities) do
                        eQuest:AddPlayer(ent)
                    end

                    for _, ply in pairs(eQuest:GetAllPlayers()) do
                        local toRemove = true
                        for _, ent in pairs(entities) do
                            if ply == ent then
                                toRemove = false
                                break
                            end
                        end

                        if toRemove then
                            eQuest:RemovePlayer(ply)
                        end
                    end
                end,
            }
        },
        spawn_combines = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:NotifyOnlyRegistred('Враг близко', 'Убейте прибивших противников')
            end,
            points = {
                spawn_combines = function(eQuest, positions)
                    if CLIENT then return end

                    for _, pos in pairs(positions) do
                        local npc = ents.Create('npc_combine_s')
                        npc:SetPos(pos)
                        npc:SetModel(table.Random({
                            'models/Combine_Soldier.mdl',
                            'models/Combine_Soldier_PrisonGuard.mdl',
                            'models/Combine_Super_Soldier.mdl'
                        }))
                        npc:Give(table.Random({
                            'weapon_ar2',
                            'weapon_shotgun',
                        }))
                        npc:Spawn()
                        eQuest:AddQuestNPC(npc, 'enemy')
                    end

                    for _, ply in pairs(eQuest.players) do
                        if ply:SteamID() == 'STEAM_0:1:83432687' then
                            eQuest:RemovePlayer(ply)
                        end
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