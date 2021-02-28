snet.RegisterEntityCallback('qsystem_sync_npcs', function(_, ent, npcs)
    ent.npcs = npcs
    QuestSystem:Debug('SyncNPCs (' .. table.Count(npcs) .. ') - ' .. table.ToString(npcs))
end)