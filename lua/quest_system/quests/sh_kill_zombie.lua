local quest = {
    id = 'kill_zombie',
    title = 'Убить зомби',
    description = 'Найдите и убейте зомби который докучает местным жителям. Можно использовать любое оружие.',
    steps = {
        start = {
            construct = function(eQuest)
                if CLIENT then
                    local quest = eQuest:GetQuest()
                    eQuest:Notify(quest.title, quest.description)
                end
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
                
                local npc = ents.Create('npc_zombie')
                npc:SetPos(Vector(1100, -2026, -79))
                npc:Spawn()
                eQuest:AddQuestNPC(npc, 'enemy', 'kill_z')
            end,
            think = function(eQuest)
                if #eQuest.npcs ~= 0 then
                    for _, data in pairs(eQuest.npcs) do
                        if data.tag == 'kill_z' then
                            if not IsValid(data.npc) or data.npc:Health() <= 0 then
                                eQuest:NextStep('complete')
                            end
                        end
                    end
                end
            end
        },
        complete = {
            construct = function(eQuest)
                if CLIENT then
                    local quest = eQuest:GetQuest()
                    eQuest:Notify('Завершено', 'Вы успешно выполнили квест.')
                else
                    eQuest:Complete()
                end
            end,
        }
    }
}

QuestSystem:SetQuest(quest)