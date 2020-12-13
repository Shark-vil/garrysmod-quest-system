local quest = {
    id = 'player_killer',
    title = 'Охотник за головами',
    description = 'Убейте случайного игрока, которого предложит заказчик.',
    payment = 500,
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then 
                    local getPlayers = player.GetAllOmit(eQuest:GetPlayer())
                    if table.Count(getPlayers) > 1 then
                        local target = table.Random(getPlayers)
                        eQuest:SetNWEntity('playerTarget', target)
                        
                        local quest = eQuest:GetQuest()
                        local text = 'Убейте игрока ' .. target:Nick() .. ' пока это не сделал кто-то другой.'
                        eQuest:Notify(quest.title, text)

                        eQuest:NextStep('kill_player')
                    else
                        eQuest:NextStep('few_players')
                        return false
                    end
                end
            end,
        },
        kill_player = {
            playerDeath = function(eQuest, victim, inflictor, attacker)
                local target = eQuest:GetNWEntity('playerTarget')
                if target == victim then
                    if eQuest:GetPlayer() == attacker then
                        eQuest:NextStep('complete')
                    else
                        eQuest:Notify('Провалено', 'К сожалению, игрок умер до того, как его прикончили вы.')
                        eQuest:Failed()
                    end
                end
            end,
            playerDisconnected = function(eQuest, ply)
                local target = eQuest:GetNWEntity('playerTarget')
                if target == ply then
                    eQuest:Notify('Провалено', 'К сожалению, игрок покинул этот мир до того, как вы настигли его.')
                    eQuest:Failed()
                end
            end,
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Хорошая работа. Будем надеется, что он не восстанет из мертвых, чтобы отомстить...')
                eQuest:Reward()
                eQuest:Complete()
            end,
        },
        few_players = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Отказ', 'На сервере слишком мало игроков для начала этого задания.')
                eQuest:Failed()
            end,
        },
    }
}

list.Set('QuestSystem', quest.id, quest)