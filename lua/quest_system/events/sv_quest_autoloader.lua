hook.Add('PlayerSpawn', 'QSystem.QuestsAutoLoader', function(ply)
    if not ply.quest_auto_loader then
        local delay = QuestSystem:GetConfig('DelayBetweenQuests')
        if delay > 0 then
            local file_path = 'quest_system/players_data/' .. ply:PlayerId() .. '/delay.json'
            if file.Exists(file_path, 'DATA') then
                local current_delay = file.Read(file_path, "DATA")
                ply:SetNWFloat('quest_delay', tonumber(current_delay, 10))
            end
        end

        timer.Simple(3, function()
            if IsValid(ply) then
                ply:EnableAllQuest()
                ply.quest_auto_loader = true

                local entities = ents.FindByClass('quest_entity')
                for _, ent in pairs(entities) do
                    if IsValid(ent) and not table.HasValue(ent.players, ply) then
                        ent:SyncAll(ply)
                    end
                end
            end
        end)
    end
end)

hook.Add('PostCleanupMap', 'QSystem.QuestsAutoLoader', function()
    timer.Simple(1, function()
        for _, ply in pairs(player.GetHumans()) do
            if IsValid(ply) then
                ply:EnableAllQuest()
            end
        end
    end)
end)