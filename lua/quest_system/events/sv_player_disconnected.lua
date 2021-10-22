hook.Add('PlayerDisconnected', 'QSystem.RemoveActivePlayerQuests', function(ply)
    local entities = ents.FindByClass('quest_entity')
    for _, eQuest in pairs(entities) do
        if eQuest:GetPlayer() == ply then
            eQuest:Remove()
        end
    end
end)