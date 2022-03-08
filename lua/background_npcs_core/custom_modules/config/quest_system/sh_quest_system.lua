bgNPC.cfg.npcs_template['quest_system_enemy'] = {
   enabled = false,
   hidden = true,
   class = 'npc_citizen',
   name = 'Quest System Enemy Actor',
   team = { 'enemy' },
   at_random = { ['defense'] = 50, ['walk'] = 50 },
   at_damage = { ['defense'] = 100 },
   at_protect = { ['defense'] = 100 },
}

bgNPC.cfg.npcs_template['quest_system_friend'] = {
   enabled = false,
   hidden = true,
   class = 'npc_citizen',
   name = 'Quest System Friend Actor',
   team = { 'player' },
   at_random = { ['idle'] = 50, ['walk'] = 50 },
   at_damage = { ['defense'] = 100 },
   at_protect = { ['defense'] = 100 },
}