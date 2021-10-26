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
QuestSystem.VERSION = '1.0-beta'

local root_directory = 'quest_system'
local script = slib.CreateIncluder(root_directory, '[Quest System] Script load - {file}')

script:using('classes/sh_quest_system.lua')
script:using('classes/sh_dialogue.lua')
script:using('classes/sh_quest_npc_service.lua')
script:using('resources/cl_fonts.lua')
script:using('cfg/sh_main_config.lua')
script:using('sh_main.lua')
script:using('extension/player_getting_list/sv_player_lib.lua')
script:using('extension/player_quest/sv_extension.lua')
script:using('extension/player_quest/sh_extension.lua')
script:using('extension/player_quest/cl_extension.lua')
script:using('extension/sv_entity_remove.lua')
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
script:using('rpc/quest_entity/cl_rpc_functions.lua')
script:using('gui/simple_quest_menu/sv_menu.lua')
script:using('gui/simple_quest_menu/cl_menu.lua')
script:using('gui/simple_quest_menu/cl_active_quests.lua')
script:using('gui/npc_dialogue_menu/sv_menu.lua')
script:using('gui/npc_dialogue_menu/cl_menu.lua')

if not QuestSystem.cfg.DisableDefaultQuests then
	script:using('quests/sh_kill_zombie.lua')
	script:using('quests/sh_search_box.lua')
	script:using('quests/sh_kill_drug_dealer.lua')
	script:using('quests/sh_player_killer.lua')
	script:using('quests/sh_mobs_attack.lua')
	script:using('quests_events/sh_kill_combine.lua')
	script:using('dialogues/sh_free_medic_dialogue.lua')
	script:using('dialogues/sh_random_background_replics.lua')
	script:using('dialogues/sh_talking_bank_background.lua')
	script:using('dialogues/sh_killer_dialogue.lua')
end

slib.usingDirectory(root_directory .. '/addons', '[Quest System | Addons] Script load - {file}')