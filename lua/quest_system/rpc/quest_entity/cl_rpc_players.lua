snet.Callback('qsystem_sync_players', function(_, ent, players)
    ent.players = players
    QuestSystem:Debug('SyncPlayers (' .. table.Count(players) .. ') - ' .. table.ToString(players))
end).Validator(SNET_ENTITY_VALIDATOR).Register()