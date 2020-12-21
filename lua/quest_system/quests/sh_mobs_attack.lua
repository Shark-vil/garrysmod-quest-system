local quest = {
    id = 'mobs_attack',
    title = 'Волны мобов',
    description = 'Вам нужно продержаться три волны, отбиваясь от толпы зомби. Ваше передвижение ограничено зоной квеста.',
    timeToNextStep = 20,
    nextStep = 'spawn_mobs_wave_1',
    functions = {
        f_left_zone = function(eQuest, entities)
            if CLIENT then return end
            if not table.HasValue(entities, eQuest:GetPlayer()) then
                eQuest:NextStep('failed')
            end
        end,
        f_spawn_zombie = function(eQuest, pos)
            if CLIENT then return end
            local mob_list = {
                'npc_zombie',
                'npc_fastzombie',
                'npc_poisonzombie',
            }

            if math.random(0, 10) == 0 then
                table.insert(mob_list, 'npc_antlionguard')
            end

            if math.random(0, 5) == 0 then
                table.insert(mob_list, 'npc_antlion')
            end

            eQuest:SpawnQuestNPC(table.Random(mob_list), {
                pos = pos,
                type = 'enemy',
                notViewSpawn = true,
                notSpawnDistance = 600
            })

            eQuest:MoveQuestNpcToPosition(eQuest:GetPlayer():GetPos(),
                'enemy', nil, 'run')
        end,
        f_spawn_zombie_points = function(eQuest, positions, max_spawn, max_mobs)
            if CLIENT then return end
            eQuest:SetVariable('mob_spawn_positions', positions)

            local length

            if #positions > 10 then
                length = 10
            else
                length = #positions
            end

            if max_mobs > max_spawn then
                max_mobs = max_spawn
            end

            eQuest:SetVariable('mob_killed', 0)
            eQuest:SetVariable('max_spawn', max_spawn)
            eQuest:SetVariable('max_mobs', max_mobs)

            for i = 1, length do
                eQuest:ExecQuestFunction('f_spawn_zombie', eQuest, table.Random(positions))
            end
        end,
        f_next_step = function(eQuest, data, next_step_id)
            if CLIENT then return end
            if data.type ~= 'enemy' then return end

            local positions = eQuest:GetVariable('mob_spawn_positions')
            local mob_killed = eQuest:GetVariable('mob_killed')
            local max_mobs = eQuest:GetVariable('max_mobs')
            local max_spawn = eQuest:GetVariable('max_spawn')

            if mob_killed + 1 == max_mobs then
                eQuest:NextStep(next_step_id)
            else
                if max_mobs - mob_killed > max_spawn then
                    eQuest:ExecQuestFunction('f_spawn_zombie', eQuest, table.Random(positions))
                end
            end

            eQuest:SetVariable('mob_killed', mob_killed + 1)
        end,
        f_move_player_to_old_position = function(eQuest)
            if CLIENT then return end
            local ply = eQuest:GetPlayer()
            local pos = eQuest:GetVariable('player_old_pos')
            if pos ~= nil then
                ply:SetPos(pos)
            end
        end
    },
    steps = {
        start = {
            structures = {
                barricades = true
            },
            construct = function(eQuest)
                if SERVER then return end
                
                local quest = eQuest:GetQuest()
                eQuest:Notify(quest.title, quest.description)
            end,
            points = {
                player_spawner = function(eQuest, positions)
                    if CLIENT then return end

                    local ply = eQuest:GetPlayer()
                    eQuest:SetVariable('player_old_pos', ply:GetPos())
                    ply:SetPos(table.Random(positions))
                end
            },
            triggers = {
                quest_zone = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_left_zone', eQuest, entities)
                end,
            }
        },
        spawn_mobs_wave_1 = {
            construct = function(eQuest)
                if SERVER then return end
                eQuest:Notify('Начало первой волны!', 'Не помри там.')
            end,
            points = {
                mob_spawners_1 = function(eQuest, positions)
                    eQuest:ExecQuestFunction('f_spawn_zombie_points', eQuest, positions, 10, 10)
                end,
            },
            triggers = {
                quest_zone = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_left_zone', eQuest, entities)
                end,
            },
            onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
                eQuest:ExecQuestFunction('f_next_step', eQuest, data, 'delay_spawn_mobs_wave_2')
            end,
        },
        delay_spawn_mobs_wave_2 = {
            construct = function(eQuest)
                if SERVER then
                    eQuest:TimerCreate(function()
                        eQuest:NextStep('spawn_mobs_wave_2')
                    end, 20)
                else
                    eQuest:Notify('Передышка', 'Новая волна через 20 секунд...')
                end
            end,
            triggers = {
                quest_zone = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_left_zone', eQuest, entities)
                end,
            },
        },
        spawn_mobs_wave_2 = {
            construct = function(eQuest)
                if SERVER then return end
                eQuest:Notify('Начало первой волны!', 'Не помри там.')
            end,
            points = {
                mob_spawners_1 = function(eQuest, positions)
                    eQuest:ExecQuestFunction('f_spawn_zombie_points', eQuest, positions, 10, 20)
                end,
            },
            triggers = {
                quest_zone = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_left_zone', eQuest, entities)
                end,
            },
            onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
                eQuest:ExecQuestFunction('f_next_step', eQuest, data, 'complete')
            end,
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:ExecQuestFunction('f_move_player_to_old_position', eQuest)
                eQuest:Notify('Завершено', 'Вы продержались все волны, так держать!')
                eQuest:Reward()
                eQuest:Complete()
            end,
        },
        failed = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:ExecQuestFunction('f_move_player_to_old_position', eQuest)
                eQuest:Notify('Провалено', 'Вы вышли за пределы игровой зоны.')
                eQuest:Failed()
            end,
        }
    }
}

list.Set('QuestSystem', quest.id, quest)