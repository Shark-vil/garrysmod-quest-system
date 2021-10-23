snet.Callback('qsystem_sync_weapons', function(_, ent, weapons)
	ent.weapons = weapons
	QuestSystem:Debug('SyncWeapons (' .. table.Count(weapons) .. ') - ' .. table.ToString(weapons))
end).Validator(SNET_ENTITY_VALIDATOR).Register()