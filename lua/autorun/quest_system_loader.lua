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
    network_type = network_type or string.sub(string.GetPathFromFilename(local_file_path), 1, 2)
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

-- Classes
using('classes/sh_c_quest.lua')
-- Main
using('sh_main.lua')
-- Stor
using('storage/sv_quest_progress.lua')
-- EX
using('extension/sh_player_quest.lua')
-- Tools
using('tools/trigger_editor/cl_trigger_editor.lua')
using('tools/trigger_editor/sv_trigger_editor.lua')
-- Events
using('events/sv_trigger_event.lua')
-- Quests
using('quests/q_kill_zombie.lua', 'sh')

if SERVER then
    concommand.Add('set_quest', function(ply)
        ply:SetQuest('q_kill_zombie')
    end)
end