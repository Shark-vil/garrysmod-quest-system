local quest = {
    id = 'search_box',
    title = 'Найти коробку',
    description = 'Наш наниматель потерял свою коробку с ценными вещами. Найдите её и отнесите заказчику.',
    payment = 500,
    npcNotReactionOtherPlayer = false,
    timeQuest = 240,
    functions = {
        spawn_npc_on_trigger = function(eQuest, entities)
            if table.HasValue(entities, eQuest:GetPlayer()) then
                if CLIENT then return end
                eQuest:Notify('Незваные гости', 'О нет, кажется на нашего заказчика напали! Спасите его, чтобы не провалить задание.')
                eQuest:NextStep('safe_employer')
            end
        end,
        failed_if_employer_death = function(eQuest)
            local npc = eQuest:GetQuestNpc('friend', 'employer')
            if not IsValid(npc) then
                eQuest:NextStep('failed')
            end
        end,
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
                    local item = ents.Create('quest_item')
                    item:SetModel('models/props_junk/cardboard_box004a.mdl')
                    item:SetPos(table.Random(positions))
                    item:SetAngles(AngleRand())
                    item:Spawn()
                    eQuest:AddQuestItem(item , 'box')
                end,
            },
            onUseItem = function(eQuest, item)
                if eQuest:GetQuestItem('box') == item then
                    item:Remove()
                    eQuest:NextStep('spawn_npc_on_trigger')
                end
            end,
        },
        spawn_npc_on_trigger = {
            construct = function(eQuest)
                if SERVER then return end
                eQuest:Notify('Завершено', 'Отлично, вы нашли коробку. Теперь отнесите её заказчику.')
            end,
            triggers = {
                spawn_npc_trigger = function(eQuest, entities)
                    local func = eQuest:GetQuestFunction('spawn_npc_on_trigger')
                    func(eQuest, entities)
                end,
                spawn_npc_trigger_2 = function(eQuest, entities)
                    local func = eQuest:GetQuestFunction('spawn_npc_on_trigger')
                    func(eQuest, entities)
                end,
            }
        },
        safe_employer = {
            points = {
                enemy = function(eQuest, positions)
                    if CLIENT then return end
                    for _, pos in pairs(positions) do
                        local npc = ents.Create('npc_combine_s')
                        npc:SetPos(pos)
                        npc:Give('weapon_ar2')
                        npc:Spawn()
                        eQuest:AddQuestNPC(npc, 'enemy')
                    end
                end,
                employer = function(eQuest, positions)
                    if CLIENT then return end
                    local employer = ents.Create('npc_citizen')
                    employer:SetPos(table.Random(positions))
                    employer:SetHealth(1000)
                    employer:Give('weapon_smg1')
                    employer:Spawn()
                    eQuest:AddQuestNPC(employer, 'friend', 'employer')

                    local npcs = eQuest:GetQuestNpc('enemy')
                    for _, npc in pairs(npcs) do
                        npc:AddEntityRelationship(employer, D_HT, 70)
                        npc:SetSaveValue("m_vecLastPosition", employer:GetPos())
	                    npc:SetSchedule(SCHED_FORCED_GO)
                    end
                end,
            },
            think = function(eQuest)
                if CLIENT then return end
                eQuest:GetQuest().functions.failed_if_employer_death(eQuest)

                local npcs = eQuest:GetQuestNpc('enemy')
                local allowDeath = true
                for _, npc in pairs(npcs) do
                    if IsValid(npc) then
                        allowDeath = false
                    end
                end
                if allowDeath then eQuest:NextStep('give_box')  end
            end
        },
        give_box = {
            construct = function(eQuest)
                if SERVER then return end
                eQuest:Notify('Завершено', 'Вы спасли клиента. Теперь можете отдать заказ.')
            end,
            onUse = function(eQuest, ent)
                local npc = eQuest:GetQuestNpc('friend', 'employer')
                if IsValid(ent) and ent == npc then
                    eQuest:RemoveNPC(true)
                    eQuest:NextStep('complete')
                end
            end,
            think = function(eQuest)
                if CLIENT then return end
                eQuest:GetQuest().functions.failed_if_employer_death(eQuest)
            end
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Вы успешно доставили заказ получателю.')
                eQuest:Reward()
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