hook.Add('PostCleanupMap', 'QSystem.NpcAutoLoader', function()    
    local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'
    if file.Exists(file_path, 'DATA') then
        local data = util.JSONToTable(file.Read(file_path, 'DATA'))
        for _, location in pairs(data) do
            local npc = ents.Create('npc_quest')
            npc:SetPos(location.pos)
            npc:SetAngles(location.ang)
            npc:Spawn()
        end
    end
end)

hook.Add('InitPostEntity', 'QSystem.NpcAutoLoader', function()
    local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'
    if file.Exists(file_path, 'DATA') then
        local data = util.JSONToTable(file.Read(file_path, 'DATA'))
        for _, location in pairs(data) do
            local npc = ents.Create('npc_quest')
            npc:SetPos(location.pos)
            npc:SetAngles(location.ang)
            npc:Spawn()
        end
    end
end)

concommand.Add('qsystem_save_guild_representative', function(ply)
    if IsValid(ply) then
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
    end

    local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'
    local npcs = ents.FindByClass('npc_quest')
    local data = {}

    if #npcs ~= 0 then
        for _, npc in pairs(npcs) do
            table.insert(data, {
                pos = npc:GetPos(),
                ang = npc:GetAngles()
            })
        end

        file.Write(file_path, util.TableToJSON(data))
    end
end)

concommand.Add('qsystem_save_guild_representative_clear', function(ply)
    if IsValid(ply) then
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
    end

    local file_path = 'quest_system/save_npc/' .. game.GetMap() .. '.json'
    if file.Exists(file_path, 'DATA') then
        file.Delete(file_path)
    end
end)