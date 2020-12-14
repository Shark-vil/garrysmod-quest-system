local root_directory = 'quest_system'

file.CreateDir('quest_system')
file.CreateDir('quest_system/players')
file.CreateDir('quest_system/triggers')
file.CreateDir('quest_system/points')
file.CreateDir('quest_system/events')
file.CreateDir('quest_system/players_data')
file.CreateDir('quest_system/save_npc')
file.CreateDir('quest_system/compile')
file.CreateDir('quest_system/dialogue')

local Category = "Quest"
local NPC = {
	Name = "Quest NPC", 
	Class = "npc_quest",
	Category = Category,
}
list.Set( "NPC", NPC.Class, NPC )

local function getFullPathToFile(local_file_path, not_root_directory)
    if not not_root_directory then
        return root_directory .. '/' .. local_file_path
    else
        return local_file_path
    end
end

local function p_include(file_path)
    include(file_path)
    MsgN('[QuestSystem] script load - ' .. file_path)
end

local function using(local_file_path, network_type, not_root_directory)
    local file_path = getFullPathToFile(local_file_path, not_root_directory)
    network_type = network_type or string.sub(string.GetFileFromFilename(local_file_path), 1, 2)
    network_type = string.lower(network_type)

    if network_type == 'cl' or network_type == 'sh' then
        if SERVER then AddCSLuaFile(file_path) end
        if CLIENT and network_type == 'cl' then
            p_include(file_path)
        elseif network_type == 'sh' then
            p_include(file_path)
        end
    elseif network_type == 'sv' and SERVER then
        p_include(file_path)
    end
end

MsgN('[QuestSystem] Loading scripts...')

using('classes/sh_quest_system.lua')
using('classes/sh_dialogue.lua')

using('resources/cl_fonts.lua')

using('cfg/sh_main_config.lua')

using('sh_main.lua')

using('net/sh_callback.lua')

using('extension/player_getting_list/sv_player_lib.lua')
using('extension/player_quest/sv_extension.lua')
using('extension/player_quest/sh_extension.lua')
using('extension/player_quest/cl_extension.lua')

using('tools/trigger_editor/sv_trigger_editor.lua')
using('tools/trigger_editor/cl_trigger_editor.lua')
using('tools/points_editor/sv_points_editor.lua')
using('tools/points_editor/cl_points_editor.lua')
using('tools/structure_editor/sv_structure_editor.lua')
using('tools/structure_editor/cl_strucutre_editor.lua')

using('events/sh_quest_step_init.lua')
using('events/sh_nodraw_npc.lua')
using('events/sv_quest_autoloader.lua')
using('events/sv_player_disconnected.lua')
using('events/sv_npc_autoloader.lua')

using('storage/trigger/sh_storage.lua')
using('storage/points/sh_storage.lua')
using('storage/sv_compile_quests.lua')

using('gui/simple_quest_menu/sv_menu.lua')
using('gui/simple_quest_menu/cl_menu.lua')
using('gui/npc_dialogue_menu/sv_menu.lua')
using('gui/npc_dialogue_menu/cl_menu.lua')

using('quests/sh_kill_zombie.lua')
using('quests/sh_search_box.lua')
using('quests/sh_kill_drug_dealer.lua')
using('quests/sh_player_killer.lua')

using('quests_events/sh_kill_combine.lua')

using('dialogues/sh_free_medic_dialogue.lua')

MsgN('[QuestSystem] Loading scripts completed!')