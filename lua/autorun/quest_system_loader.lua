local root_directory = 'quest_system'

local function using(local_file_path, network_type)
    local file_path = root_directory .. '/' .. local_file_path .. '.lua'
    network_type = network_type or 'sh'

    if network_type == 'cl' or network_type == 'sh' then
        if SERVER then AddCSLuaFile(file_path) end
        include(file_path)
    elseif network_type == 'sv' and SERVER then
        include(file_path)
    end
end

using('main')