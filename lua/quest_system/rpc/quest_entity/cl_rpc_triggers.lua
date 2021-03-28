snet.RegisterCallback('qsystem_sync_triggers', function(_, ent, triggers)
    ent.triggers = triggers
    QuestSystem:Debug('SyncTriggers (' .. table.Count(triggers) .. ') - ' .. table.ToString(triggers))
end)