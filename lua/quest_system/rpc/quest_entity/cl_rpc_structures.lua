snet.RegisterEntityCallback('qsystem_sync_structures', function(_, ent, structures)
    ent.structures = structures
    QuestSystem:Debug('SyncStructures (' .. table.Count(structures) .. ') - ' .. table.ToString(structures))
end)