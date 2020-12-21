net.RegisterCallback('qsystem_sync_items', function(_, ent, items)
    ent.items = items
    QuestSystem:Debug('SyncItems (' .. table.Count(items) .. ') - ' .. table.ToString(items))
end)