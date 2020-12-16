AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SetDialogueID(id)
    self:SetNWString('id', id)
end

function ENT:SetStep(step_id)
    self:SetNWString('step_id', step_id)
end

function ENT:SetPlayer(ply)
    self:SetNWEntity('player', ply)
end

function ENT:SetNPC(npc)
    self:SetNWEntity('npc', npc)
end

function ENT:Next(step_id, ignore_npc_text)
    ignore_npc_text = ignore_npc_text or false
    self:SetStep(step_id)
    timer.Simple(0.5, function()
        self:StartDialogue(ignore_npc_text, true)
    end)
end

function ENT:LoadPlayerValues()
    local ply = self:GetPlayer()
    if IsValid(ply) then
        local file_path = 'quest_system/dialogue/'.. ply:PlayerId()
        file_path = file_path .. '/' .. self:GetDialogueID()
        file_path = file_path .. '/'

        local files_values = file.Find(file_path .. '*', 'DATA')
        for _, file_name in pairs(files_values) do
            local value_name = string.Split(file_name, '.')
            local value = self:GetNWString('var_' .. value_name[1])

            if value == nil or #value == 0 then
                value = file.Read(file_path .. file_name, "DATA")
                self:SetNWString('var_' .. value_name[1], value)
            end
        end
    end
end

function ENT:SavePlayerValue(value_name, value, not_autoload)
    local ply = self:GetPlayer()
    if IsValid(ply) then
        local file_path = 'quest_system/dialogue/'.. ply:PlayerId()
        
        if not file.Exists(file_path, 'DATA') then
            file.CreateDir(file_path)
        end

        file_path = file_path .. '/' .. self:GetDialogueID()

        if not file.Exists(file_path, 'DATA') then
            file.CreateDir(file_path)
        end

        file_path = file_path .. '/' .. value_name .. '.txt'

        value = tostring(value)

        file.Write(file_path, value)

        if not not_autoload then
            self:SetNWString('var_' .. value_name, value)
        end

        return true
    end

    return false
end

function ENT:RemovePlayerValue(value_name, player_id)

    if player_id == nil then
        local ply = self:GetPlayer()
        if IsValid(ply)  then
            player_id = ply:PlayerId()
        end
    end

    if player_id ~= nil then
        local file_path = 'quest_system/dialogue/'.. player_id
        file_path = file_path .. '/' .. self:GetDialogueID()
        file_path = file_path .. '/' .. value_name .. '.txt'

        if file.Exists(file_path, 'DATA') then
            file.Remove(file_path)
            return true
        end
    end

    return false
end

function ENT:Stop()
    self:Remove()
end