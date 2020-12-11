local root_directory = 'quest_system'

local function getFullPathToFile(local_file_path, not_root_directory)
    if not not_root_directory then
        return root_directory .. '/' .. local_file_path
    else
        return local_file_path
    end
end

local function p_include(file_path)
    include(file_path)
    MsgN('QSystem file load - ' .. file_path)
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

using('sh_main.lua')
using('extension/sh_player_quest.lua')
using('tools/trigger_editor/cl_trigger_editor.lua')
using('tools/trigger_editor/sv_trigger_editor.lua')
using('events/sh_quest_step_init.lua')
using('events/sv_quest_autoloader.lua')
using('events/sv_player_disconnected.lua')
using('storage/sv_trigger_storage.lua')
using('quests/sh_kill_zombie.lua')

local Category = "Quest"
local NPC = { 	
	Name = "Quest NPC", 
	Class = "npc_quest",
	Category = Category,
}
list.Set( "NPC", NPC.Class, NPC )

if SERVER then
    file.CreateDir('quest_system')
    file.CreateDir('quest_system/players')
    file.CreateDir('quest_system/triggers')

    concommand.Add('start_quest', function(ply)
        ply:SaveQuest('kill_zombie')
        ply:EnableQuest('kill_zombie')
    end)

    concommand.Add('stop_quest', function(ply)
        ply:DisableQuest('kill_zombie')
        ply:RemoveQuest('kill_zombie')
    end)
end