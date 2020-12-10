hook.Add('PlayerSpawn', 'QSystem.QuestsAutoLoader', function(ply)
    if not ply.quest_auto_loader then
        timer.Simple(3, function()
            if IsValid(ply) then
                ply:EnableAllQuest()
                ply.quest_auto_loader = true
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