local quest = {
    id = 'player_killer',
    title = 'Охотник за головами',
    description = 'Убейте случайного игрока, которого предложит заказчик.',
    payment = 500,
    --[[
    -- An example of creating restrictions for quests (also works with dialogues) 
    restriction = {
        team = {
            TEAM_GANG,
            TEAM_MOB
        },
        steamid = {
            'STEAM_0:1:83432687'
        },
        nick = {
            '[FG] Shark_vil'
        },
        usergroup = {
            'superadmin'
        },
        adminOnly = true,
    },
    ]]
    condition = function(ply)
        if table.Count(player.GetAll()) > 1 then
            return true
        else
            ply:QuestNotify('Отказ', 'На сервере слишком мало игроков для начала этого задания.')
            return false
        end
    end,
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then 
                    local target = table.Random(player.GetAllOmit(eQuest:GetPlayer()))
                    eQuest:SetNWEntity('playerTarget', target)
                    
                    local quest = eQuest:GetQuest()
                    local text = 'Убейте игрока ' .. target:Nick() .. ' пока это не сделал кто-то другой.'
                    eQuest:Notify(quest.title, text)

                    eQuest:NextStep('kill_player')
                end
            end,
        },
        kill_player = {
            hooks = {
                PlayerDeath = function(eQuest, victim, inflictor, attacker)
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
                PlayerDisconnected = function(eQuest, ply)
                    local target = eQuest:GetNWEntity('playerTarget')
                    if target == ply then
                        eQuest:Notify('Провалено', 'К сожалению, игрок покинул этот мир до того, как вы настигли его.')
                        eQuest:Failed()
                    end
                end,
            }
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