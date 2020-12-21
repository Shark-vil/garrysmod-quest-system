net.RegisterCallback('qsystem_sync_weapons', function(_, ent, weapons)
    ent.weapons = weapons
    QuestSystem:Debug('SyncWeapons (' .. table.Count(weapons) .. ') - ' .. table.ToString(weapons))
end)