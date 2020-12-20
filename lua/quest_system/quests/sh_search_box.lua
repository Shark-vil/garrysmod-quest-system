local quest = {
    id = 'search_box',
    title = 'Найти коробку',
    description = 'Наш наниматель потерял свою коробку с ценными вещами. Найдите её и отнесите заказчику.',
    payment = 500,
    npcNotReactionOtherPlayer = false,
    timeQuest = 240,
    functions = {
        f_spawn_enemy_npcs = function(eQuest, entities)
            if table.HasValue(entities, eQuest:GetPlayer()) then
                if CLIENT then return end
                eQuest:Notify('Незваные гости', 'О нет, кажется на нашего заказчика напали! Спасите его, чтобы не провалить задание.')
                eQuest:NextStep('safe_customer')
            end
        end,
        f_loss_conditions = function(eQuest)
            if not eQuest:QuestNPCIsValid('friend', 'customer') then
                eQuest:NextStep('failed')
            elseif not eQuest:QuestNPCIsValid('enemy') then
                eQuest:Notify('Завершено', 'Вы спасли клиента. Теперь можете отдать заказ.')
                eQuest:NextStep('give_box')
            end
        end,
        f_spawn_customer = function(eQuest, pos, isAttack)
            if eQuest:QuestNPCIsValid('friend', 'customer') then return end

            local weapon_class = nil
            if isAttack then
                weapon_class = table.Random({
                    'weapon_pistol',
                     'weapon_smg1', 
                     'weapon_smg1', 
                     'weapon_shotgun', 
                     'weapon_357'
                })
            end

            eQuest:SpawnQuestNPC('npc_citizen', {
                pos = pos,
                weapon_class = weapon_class,
                type = 'friend',
                tag = 'customer',
                afterSpawnExecute = function(eQuest, data)
                    if not isAttack then return end
                    local npc = data.npc
                    eQuest:MoveQuestNpcToPosition(npc:GetPos(), 'enemy')
                end
            })
        end
    },
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then return end

                local quest = eQuest:GetQuest()
                eQuest:Notify(quest.title, quest.description)
            end,
            points = {
                spawn_points_1 = function(eQuest, positions)
                    if CLIENT then return end
                    eQuest:SpawnQuestItem('quest_item', {
                        id = 'box',
                        model = 'models/props_junk/cardboard_box004a.mdl',
                        pos = table.Random(positions),
                        ang = AngleRand()
                    }):SetFreeze(true)
                end,
            },
            onUseItem = function(eQuest, item)
                if eQuest:GetQuestItem('box') == item then
                    item:FadeRemove()
                    if math.random(0, 1) == 1 then
                        eQuest:SetVariable('is_customer_attack', true)
                        eQuest:NextStep('attack_on_the_customer')
                    else
                        eQuest:Notify('Доставка', 'Дело за малым. Найдите клиента и отдайте ему коробку.')
                        eQuest:NextStep('give_box')
                    end
                end
            end,
        },
        attack_on_the_customer = {
            construct = function(eQuest)
                if SERVER then return end
                eQuest:Notify('Завершено', 'Отлично, вы нашли коробку. Теперь отнесите её заказчику.')
            end,
            triggers = {
                spawn_npc_trigger = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_spawn_enemy_npcs', eQuest, entities)
                end,
                spawn_npc_trigger_2 = function(eQuest, entities)
                    eQuest:ExecQuestFunction('f_spawn_enemy_npcs', eQuest, entities)
                end,
            }
        },
        safe_customer = {
            structures = {
                barricades = true
            },
            points = {
                enemy = function(eQuest, positions)
                    if CLIENT then return end
                    for _, pos in pairs(positions) do
                        eQuest:SpawnQuestNPC('npc_combine_s', {
                            pos = pos,
                            weapon_class = 'weapon_ar2',
                            type = 'enemy'
                        })
                    end
                end,
                customer = function(eQuest, positions)
                    if CLIENT then return end                    
                    eQuest:ExecQuestFunction('f_spawn_customer', eQuest, table.Random(positions), true)
                end,
            },
            onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
                eQuest:ExecQuestFunction('f_loss_conditions', eQuest)
            end,
        },
        give_box = {
            points = {
                customer = function(eQuest, positions)
                    if CLIENT then return end                    
                    eQuest:ExecQuestFunction('f_spawn_customer', eQuest, table.Random(positions))
                end,
            },
            onUse = function(eQuest, ent)
                local npc = eQuest:GetQuestNpc('friend', 'customer')
                if IsValid(ent) and ent == npc then
                    eQuest:NextStep('complete')
                end
            end,
            onQuestNPCKilled = function(eQuest)
                eQuest:ExecQuestFunction('f_loss_conditions', eQuest)
            end,
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Вы успешно доставили заказ получателю.')
                if eQuest:GetVariable('is_customer_attack') then
                    eQuest:Reward(nil, 500)
                else
                    eQuest:Reward()
                end
                eQuest:Complete()
            end,
        },
        failed = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Провалено', 'Заказчик мёртв, вы не получите награду за выполнение.')
                eQuest:Failed()
            end,
        }
    }
}

list.Set('QuestSystem', quest.id, quest)