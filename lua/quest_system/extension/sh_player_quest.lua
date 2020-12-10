local meta = FindMetaTable('Player')

function meta:SaveQuest(quest_id, step)
    if CLIENT then return end

    local file_path = 'quest_system/players/' .. self:SteamID64()
    if not file.Exists(file_path, 'DATA') then
        file.CreateDir(file_path)
    end

    file_path = file_path .. '/' .. quest_id .. '.json'

    local quest = QuestSystem:GetQuest(quest_id)
    step = step or 'start'
    if quest ~= nil and quest.steps[step] ~= nil then
        local data = {
            id = quest_id,
            step = step
        }
        file.Write(file_path, util.TableToJSON(data))
        return true
    end
    return false
end

function meta:ReadQuest(quest_id)
    if CLIENT then return end

    local file_path = 'quest_system/players/' .. self:SteamID64() .. '/' .. quest_id .. '.json'
    if file.Exists(file_path, 'DATA') then
        return util.JSONToTable(file.Read(file_path, "DATA"))
    end
    return nil
end

function meta:ReadAllQuest()
    if CLIENT then return end

    local file_path = 'quest_system/players/' .. self:SteamID64() .. '/*'
    local quest_files = file.Find(file_path, 'DATA')
    if #quest_files ~= 0 then
        local quests = {}
        for _, filename in pairs(quest_files) do
            local nameAndExt = string.Split(filename, '.')
            local quest = self:ReadQuest(nameAndExt[1])
            if quest ~= nil then
                table.insert(quests, quest)
            end
        end
        return quests
    end
    return {}
end

function meta:RemoveQuest(quest_id)
    if CLIENT then return end

    local file_path = 'quest_system/players/' .. self:SteamID64() .. '/' .. quest_id .. '.json'
    if file.Exists(file_path, 'DATA') then
        file.Delete(file_path)
        return true
    end
    return false
end

function meta:EnableQuest(quest_id)
    if CLIENT then return end

    local quest_data = self:ReadQuest(quest_id)
    if quest_data ~= nil then
        local ent = ents.Create('quest_entity')
        ent:SetQuest(quest_id, self)
        ent:Spawn()
        ent:SetStep(quest_data.step, 1)
    end
end

function meta:EnableAllQuest()
    if CLIENT then return end

    local quests = self:ReadAllQuest()
    for _, quest_data in pairs(quests) do
        if quest_data ~= nil then
            local ent = ents.Create('quest_entity')
            ent:SetQuest(quest_data.id, self)
            ent:Spawn()
            ent:SetStep(quest_data.step, 1)
        end
    end
end

function meta:FindQuestEntity(quest_id)
    local eQuests = ents.FindByClass('quest_entity')
    if #eQuests ~= 0 then
        for _, quest_entity in pairs(eQuests) do
            local quest = quest_entity:GetQuest()
            local ply = quest_entity:GetPlayer()
            
            if ply == self and quest ~= nil and quest.id == quest_id then
                return quest_entity
            end
        end
    end
    return NULL
end

function meta:FindQuestEntities()
    local eQuests = ents.FindByClass('quest_entity')
    if #eQuests ~= 0 then
        local quest_entities = {}
        for _, quest_entity in pairs(eQuests) do
            local quest = quest_entity:GetQuest()
            local ply = quest_entity:GetPlayer()
            
            if ply == self and quest ~= nil then
                table.insert(quest_entities, quest_entity)
            end
        end
        return quest_entities
    end
    return {}
end

function meta:DisableQuest(quest_id)
    if CLIENT then return end

    local quest_entity = self:FindQuestEntity(quest_id)
    if IsValid(quest_entity) then
        quest_entity:Remove()
    end
end

function meta:DisableAllQuest()
    if CLIENT then return end

    local quest_entities = self:FindQuestEntities()

    for _, quest_entity in pairs(quest_entities) do
        if IsValid(quest_entity) then
            quest_entity:Remove()
        end
    end
end

function meta:SetQuestStep(quest_id, step)
    if CLIENT then return end

    local quest_data = self:ReadQuest(quest_id)
    if quest_data ~= nil then
        local isSaved = self:SaveQuest(quest_id, step)
        if isSaved then
            local ent = self:FindQuestEntity(quest_id)
            if IsValid(ent) then
                ent:SetStep(step)
            end
        end
    end

    return false
end