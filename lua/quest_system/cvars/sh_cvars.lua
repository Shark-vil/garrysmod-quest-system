local DefaultAccess = { isAdmin = true }
local lang = slib.language({
	['default'] = {
		['qsystem_cfg_hide_quests_of_other_players'] = 'Hides quests for other players.',
		['qsystem_cfg_hide_quests_npcs_not_completely'] = 'Does not completely hide quest NPCs, making them semi-transparent.',
		['qsystem_cfg_enable_game_events'] = 'Enable a random game events',
		['qsystem_cfg_events_delay'] = 'Задержка между игровыми событиями',
		['qsystem_cfg_events_chance'] = 'Chance of activating a game event',
		['qsystem_cfg_events_max'] = 'Maximum number of simultaneously running game events',
		['qsystem_cfg_max_quests_for_player'] = 'Maximum number of quests for one player',
		['qsystem_cfg_delay_between_quests'] = 'Delay between taking quests',
		['qsystem_cfg_debug_mode'] = 'Debug mode',
	},
	['russian'] = {
		['qsystem_cfg_hide_quests_of_other_players'] = 'Скрывает квесты для других игроков.',
		['qsystem_cfg_hide_quests_npcs_not_completely'] = 'Не скрывает полностью квестовых NPC, делая их полупрозрачными.',
		['qsystem_cfg_enable_game_events'] = 'Включает случайные игровые события',
		['qsystem_cfg_events_delay'] = 'Задержка между игровыми событиями',
		['qsystem_cfg_events_chance'] = 'Шанс активации игрового события',
		['qsystem_cfg_events_max'] = 'Максимальное кол-во одновременно запущенных игровых событий',
		['qsystem_cfg_max_quests_for_player'] = 'Максимальное кол-во квестов для одного игрока',
		['qsystem_cfg_delay_between_quests'] = 'Задержка между взятием квестов',
		['qsystem_cfg_debug_mode'] = 'Режим отладки',
	}
})

local qsystem_cfg_debug_mode = 0
local qsystem_cfg_hide_quests_of_other_players = 1
local qsystem_cfg_hide_quests_npcs_not_completely = 1
local qsystem_cfg_enable_game_events = 1
local qsystem_cfg_events_delay = 120
local qsystem_cfg_events_chance = 10
local qsystem_cfg_events_max = 3
local qsystem_cfg_max_quests_for_player = 4
local qsystem_cfg_delay_between_quests = 0

scvar.Register('qsystem_cfg_debug_mode', qsystem_cfg_debug_mode,
	FCVAR_ARCHIVE, lang['qsystem_cfg_debug_mode'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_hide_quests_of_other_players', qsystem_cfg_hide_quests_of_other_players,
	FCVAR_ARCHIVE, lang['qsystem_cfg_hide_quests_of_other_players'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_hide_quests_npcs_not_completely', qsystem_cfg_hide_quests_npcs_not_completely,
	FCVAR_ARCHIVE, lang['qsystem_cfg_hide_quests_npcs_not_completely'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_enable_game_events', qsystem_cfg_enable_game_events,
	FCVAR_ARCHIVE, lang['qsystem_cfg_enable_game_events'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_events_delay', qsystem_cfg_events_delay,
	FCVAR_ARCHIVE, lang['qsystem_cfg_events_delay'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_events_chance', qsystem_cfg_events_chance,
	FCVAR_ARCHIVE, lang['qsystem_cfg_events_chance'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_events_max', qsystem_cfg_events_max,
	FCVAR_ARCHIVE, lang['qsystem_cfg_events_max'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_max_quests_for_player', qsystem_cfg_max_quests_for_player,
	FCVAR_ARCHIVE, lang['qsystem_cfg_max_quests_for_player'])
	.Access(DefaultAccess)

scvar.Register('qsystem_cfg_delay_between_quests', qsystem_cfg_delay_between_quests,
	FCVAR_ARCHIVE, lang['qsystem_cfg_delay_between_quests'])
	.Access(DefaultAccess)