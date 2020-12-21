net.RegisterCallback('qsystem_sync_values', function(_, ent, values)
    ent.values = values
    QuestSystem:Debug('SyncValues (' .. table.Count(values) .. ') - ' .. table.ToString(values))
end)