net.RegisterCallback('qsystem_sync_points', function(_, ent, points)
    ent.points = points
    QuestSystem:Debug('SyncPoints (' .. table.Count(points) .. ') - ' .. table.ToString(points))
end)