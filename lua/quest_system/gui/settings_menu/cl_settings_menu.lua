local lang = slib.language({
	['default'] = {
		['category_title'] = 'General settings',
		['qsystem_cfg_hide_quests_of_other_players_title'] = 'Hide quests for other players',
		['qsystem_cfg_hide_quests_of_other_players_description'] = 'Description: Allows you to hide quests for other players. Disables collision with quest objects, disables their rendering, dealing damage, tries to block NPC sounds.',
		['qsystem_cfg_hide_quests_npcs_not_completely_title'] = 'Not completely hiding the NPC',
		['qsystem_cfg_hide_quests_npcs_not_completely_description'] = 'Description: Allows you not to completely hide quest NPCs for other players. Since the sounds of shots or particles from NPCs may not be completely hidden, it is better to make them semi-transparent so as not to create discomfort for the players.',
		['qsystem_cfg_enable_game_events_title'] = 'Enable game events',
		['qsystem_cfg_enable_game_events_description'] = 'Description: Enables the appearance of random game events for all players.',
		['qsystem_cfg_events_delay_title'] = 'Delay between game events',
		['qsystem_cfg_events_delay_description'] = 'Description: Sets the delay in seconds between game events.',
		['qsystem_cfg_events_chance_title'] = 'Chance of activating a game event',
		['qsystem_cfg_events_chance_description'] = 'Description: Sets the chance of activating a game event after the delay expires. Useful for enhancing randomization.',
		['qsystem_cfg_events_max_title'] = 'Maximum number of simultaneous game events',
		['qsystem_cfg_events_max_description'] = 'Description: sets the maximum allowed number of simultaneously running game events. Setting the value to "0" will disable the limiting.',
		['qsystem_cfg_max_quests_for_player_title'] = 'Maximum number of quests for a player',
		['qsystem_cfg_max_quests_for_player_description'] = 'Description: sets the maximum allowed number of simultaneously active quests for one player. Setting the value to "0" will disable the limiting.',
		['qsystem_cfg_delay_between_quests_title'] = 'Delay between taking quests',
		['qsystem_cfg_delay_between_quests_description'] = 'Description: Sets the delay in seconds between accepting new quests for the player. Canceling the taken quest does not remove the restriction! Setting the value to "0" will disable the limiting.',
	},
	['russian'] = {
		['category_title'] = 'Основные настройки',
		['qsystem_cfg_hide_quests_of_other_players_title'] = 'Скрывать квесты для других игроков',
		['qsystem_cfg_hide_quests_of_other_players_description'] = 'Описание: озволяет скрыть квесты для других игроков. Отключает столкновение с квестовыми объектами, отключает их рендер, нанесение урона, пытается блокировать звуки NPC.',
		['qsystem_cfg_hide_quests_npcs_not_completely_title'] = 'Не полное скрытие NPC',
		['qsystem_cfg_hide_quests_npcs_not_completely_description'] = 'Описание: озволяет не полностью скрыть квестовых NPC для других игроков. Поскольку звуки выстрелов или партиклы от NPC могут быть не скрыты полностью, лучше сделать их полупрозрачными чтобы не создавать дискомфорт игрокам.',
		['qsystem_cfg_enable_game_events_title'] = 'Включить игровые события',
		['qsystem_cfg_enable_game_events_description'] = 'Описание: включает появление случайных игровых событий для всех игроков.',
		['qsystem_cfg_events_delay_title'] = 'Задержка между игровыми событиями',
		['qsystem_cfg_events_delay_description'] = 'Описание: устанавливает задержку в секундах между игровыми событиями.',
		['qsystem_cfg_events_chance_title'] = 'Шанс активации игрового события',
		['qsystem_cfg_events_chance_description'] = 'Описание: устанавливает шанс активации игрового события по истечению задержки. Полезно для повышения рандомизации.',
		['qsystem_cfg_events_max_title'] = 'Максимальное кол-во одновременных игровых событий',
		['qsystem_cfg_events_max_description'] = 'Описание: устанавливает максимальное допустимое кол-во одновременно запущенных игровых событий. Установка значения в "0" отключит ограничение.',
		['qsystem_cfg_max_quests_for_player_title'] = 'Максимальное кол-во квестов для игрока',
		['qsystem_cfg_max_quests_for_player_description'] = 'Описание: устанавливает максимальное допустимое кол-во одновременно активных квестов для одного игрока. Установка значения в "0" отключит ограничение.',
		['qsystem_cfg_delay_between_quests_title'] = 'Задержка между взятием квестов',
		['qsystem_cfg_delay_between_quests_description'] = 'Описание: устанавливает задержку в секундах между взятием новых квестов для игрока. Отмена взятого квеста не снимает ограничение! Установка значения в "0" отключит ограничение.',
	},
})

local function init_tool_menu(panel)
	panel:AddControl('CheckBox', {
		['Label'] = lang['qsystem_cfg_hide_quests_of_other_players_title'],
		['Command'] = 'qsystem_cfg_hide_quests_of_other_players'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_hide_quests_of_other_players_description']
	})

	panel:AddControl('CheckBox', {
		['Label'] = lang['qsystem_cfg_hide_quests_npcs_not_completely_title'],
		['Command'] = 'qsystem_cfg_hide_quests_npcs_not_completely'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_hide_quests_npcs_not_completely_description']
	})

	panel:AddControl('CheckBox', {
		['Label'] = lang['qsystem_cfg_enable_game_events_title'],
		['Command'] = 'qsystem_cfg_enable_game_events'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_enable_game_events_description']
	})

	panel:AddControl('Slider', {
		['Label'] = lang['qsystem_cfg_events_delay_title'],
		['Command'] = 'qsystem_cfg_events_delay',
		['Type'] = 'Integer',
		['Min'] = '1',
		['Max'] = '600'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_events_delay_description']
	})

	panel:AddControl('Slider', {
		['Label'] = lang['qsystem_cfg_events_chance_title'],
		['Command'] = 'qsystem_cfg_events_chance',
		['Type'] = 'Integer',
		['Min'] = '1',
		['Max'] = '600'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_events_chance_description']
	})

	panel:AddControl('Slider', {
		['Label'] = lang['qsystem_cfg_events_max_title'],
		['Command'] = 'qsystem_cfg_max_quests_for_player',
		['Type'] = 'Integer',
		['Min'] = '0',
		['Max'] = '10'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_events_max_description']
	})

	panel:AddControl('Slider', {
		['Label'] = lang['qsystem_cfg_max_quests_for_player_title'],
		['Command'] = 'qsystem_cfg_max_quests_for_player',
		['Type'] = 'Integer',
		['Min'] = '0',
		['Max'] = '10'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_max_quests_for_player_description']
	})

	panel:AddControl('Slider', {
		['Label'] = lang['qsystem_cfg_delay_between_quests_title'],
		['Command'] = 'qsystem_cfg_delay_between_quests',
		['Type'] = 'Integer',
		['Min'] = '0',
		['Max'] = '600'
	}); panel:AddControl('Label', {
		['Text'] = lang['qsystem_cfg_delay_between_quests_description']
	})
end

hook.Add('PopulateToolMenu', 'QSystem.Tool.Menu.GeneralSettings', function()
	spawnmenu.AddToolMenuOption('Options', 'Quest System', 'QuestSystem_General_Settings',
		lang['category_title'], '', '', init_tool_menu)
end)