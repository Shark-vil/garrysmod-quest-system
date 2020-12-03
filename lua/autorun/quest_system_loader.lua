local root_directory = 'quest_system'

local function getFullPathToFile(local_file_path, not_root_directory)
    if not not_root_directory then
        return root_directory .. '/' .. local_file_path
    else
        return local_file_path
    end
end

local function using(local_file_path, network_type, not_root_directory)
    local file_path = getFullPathToFile(local_file_path, not_root_directory)    
    network_type = network_type or 'sh'
    network_type = string.lower(network_type)

    if network_type == 'cl' or network_type == 'sh' then
        if SERVER then AddCSLuaFile(file_path) end
        include(file_path)
    elseif network_type == 'sv' and SERVER then
        include(file_path)
    end
end

local function auto_using(local_directory_path, not_root_directory)
    local files, directories = file.Find(local_directory_path .. "/*", "LUA")
    
    for _, file_path in pairs(files) do
        local type = string.sub(file_path, 1, 2)
        using(local_directory_path .. '/' .. file_path, type, true)
    end

    for _, directory_path in pairs(directories) do
        auto_using(local_directory_path .. '/' .. directory_path, true)
    end
end

auto_using(root_directory)

getFullPathToFile, using, auto_using, root_directory = nil