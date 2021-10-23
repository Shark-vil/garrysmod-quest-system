snet.Callback('qsystem_sync_npcs', function(_, ent, npcs)
	ent.npcs = npcs
	QuestSystem:Debug('SyncNPCs (' .. table.Count(npcs) .. ') - ' .. table.ToString(npcs))
end).Validator(SNET_ENTITY_VALIDATOR).Register()