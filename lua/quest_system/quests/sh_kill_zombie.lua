local quest = {
    id = 'kill_zombie',
    title = 'Убить зомби',
    description = 'Найдите и убейте зомби который докучает местным жителям. Можно использовать любое оружие.',
    payment = 500,
    timeQuest = 300,
    steps = {
        start = {
            construct = function(eQuest)
                if SERVER then return end
                
                local quest = eQuest:GetQuest()
                eQuest:Notify(quest.title, quest.description)
            end,
            triggers = {
                spawn_zombie_trigger_1 = function(eQuest, entities)
                    if CLIENT then return end
                    if table.HasValue(entities, eQuest:GetPlayer()) then
                        eQuest:NextStep('spawn')
                    end
                end,
                spawn_zombie_trigger_2 = function(eQuest, entities)
                    if CLIENT then return end
                    if table.HasValue(entities, eQuest:GetPlayer()) then
                        eQuest:NextStep('spawn')
                    end
                end
            }
        },
        spawn = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Враг близко', 'Неожиданно. Их оказалось больше, чем в заказе. Но это не важно, убейте всех.')
            end,
            points = {
                spawn_zombie = function(eQuest, positions)
                    if CLIENT then return end

                    for _, pos in pairs(positions) do
                        local npc = ents.Create(table.Random({'npc_zombie', 'npc_headcrab', 'npc_fastzombie'}))
                        npc:SetPos(pos)
                        npc:Spawn()
                        eQuest:AddQuestNPC(npc, 'enemy')
                    end
                end,
            },
            think = function(eQuest)
                if CLIENT then return end

                local zombies = eQuest:GetQuestNpc('enemy')
                if #zombies ~= 0 then
                    for _, npc in pairs(zombies) do
                        if IsValid(npc) then
                            return
                        end
                    end
                    eQuest:NextStep('complete')
                end
            end
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then return end
                eQuest:Notify('Завершено', 'Спасибо за вашу помощь! Больше это отродье не будет никому мешать.')
                eQuest:Reward()
                eQuest:Complete()
            end,
        }
    }
}

list.Set('QuestSystem', quest.id, quest)