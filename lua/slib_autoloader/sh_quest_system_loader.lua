file.CreateDir('quest_system')
file.CreateDir('quest_system/players')
file.CreateDir('quest_system/triggers')
file.CreateDir('quest_system/points')
file.CreateDir('quest_system/events')
file.CreateDir('quest_system/players_data')
file.CreateDir('quest_system/save_npc')
file.CreateDir('quest_system/compile')
file.CreateDir('quest_system/dialogue')
file.CreateDir('quest_system/structure')

resource.AddFile('materials/quest_system/vgui/dialogue_panel_background.png')
resource.AddFile('resource/fonts/qsystem_dialogue.ttf')

local Category = 'Quest'
local NPC = {
	Name = 'Quest NPC',
	Class = 'npc_quest',
	Category = Category,
}
list.Set('NPC', NPC.Class, NPC)

-- Main table for working with quests and events
QuestSystem = QuestSystem or {}
QuestSystem.VERSION = '1.1.3'
QuestSystem.Storage = QuestSystem.Storage or {}
QuestSystem.Storage.Quests = QuestSystem.Storage.Quests or {}
QuestSystem.Storage.Dialogues = QuestSystem.Storage.Dialogues or {}

local root_directory = 'quest_system'
local script = slib.CreateIncluder(root_directory, '[Quest System] Script load - {file}')

script:using('cvars/sh_cvars.lua')

script:using('resources/cl_fonts.lua')

script:using('classes/sh_quest_system.lua')
script:using('classes/sh_dialogue.lua')
script:using('classes/sh_quest_npc_service.lua')

script:using('sh_main.lua')

script:using('extension/player_getting_list/sv_player_lib.lua')
script:using('extension/player_quest/sv_extension.lua')
script:using('extension/player_quest/sh_extension.lua')
script:using('extension/player_quest/cl_extension.lua')
script:using('extension/sv_entity_remove.lua')

script:using('tools/sh_main.lua')
script:using('tools/cl_main.lua')
script:using('tools/trigger_editor/sv_trigger_editor.lua')
script:using('tools/trigger_editor/cl_trigger_editor.lua')
script:using('tools/points_editor/sv_points_editor.lua')
script:using('tools/points_editor/cl_points_editor.lua')
script:using('tools/structure_editor/sv_structure_editor.lua')
script:using('tools/structure_editor/cl_strucutre_editor.lua')

script:using('events/sv_quest_autoloader.lua')
script:using('events/sv_player_disconnected.lua')
script:using('events/sh_npc_autoloader.lua')

script:using('storage/trigger/sh_storage.lua')
script:using('storage/points/sh_storage.lua')
script:using('storage/structure/sh_storage.lua')
script:using('storage/sh_compile_quests.lua')

script:using('rpc/quest_entity/cl_rpc_construct.lua')
script:using('rpc/quest_entity/cl_rpc_triggers.lua')
script:using('rpc/quest_entity/cl_rpc_points.lua')
script:using('rpc/quest_entity/cl_rpc_next_step.lua')
script:using('rpc/quest_entity/cl_rpc_npcs.lua')
script:using('rpc/quest_entity/cl_rpc_items.lua')
script:using('rpc/quest_entity/cl_rpc_players.lua')
script:using('rpc/quest_entity/cl_rpc_values.lua')
script:using('rpc/quest_entity/cl_rpc_weapons.lua')
script:using('rpc/quest_entity/cl_rpc_structures.lua')
script:using('rpc/quest_entity/cl_rpc_nodraw.lua')

script:using('modules/actions/on_quest_npc_killed/cl_on_quest_npc_killed_action.lua')
script:using('modules/actions/on_quest_npc_killed/sv_on_quest_npc_killed_action.lua')
script:using('modules/actions/on_use/cl_on_use_action.lua')
script:using('modules/actions/on_use/sv_on_use_action.lua')
script:using('modules/actions/on_use_item/cl_on_use_item_action.lua')
script:using('modules/actions/points/cl_points_init_action.lua')
script:using('modules/services/cl_remove_quest_sounds_service.lua')
script:using('modules/services/sv_npc_damage_service.lua')
script:using('modules/services/sv_should_collider_service.lua')
script:using('modules/services/sv_always_pvs_service.lua')
script:using('modules/quest_entity/sv_init_points.lua')
script:using('modules/quest_entity/sv_init_structures.lua')
script:using('modules/quest_entity/sv_init_triggers.lua')

script:using('gui/simple_quest_menu/sv_menu.lua')
script:using('gui/simple_quest_menu/cl_menu.lua')
script:using('gui/simple_quest_menu/cl_active_quests.lua')
script:using('gui/npc_dialogue_menu/sv_menu.lua')
script:using('gui/npc_dialogue_menu/cl_menu.lua')
script:using('gui/settings_menu/cl_settings_menu.lua')

slib.usingDirectory(root_directory .. '/addons', '[Quest System | Addons] Script load - {file}')