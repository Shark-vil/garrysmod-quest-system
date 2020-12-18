if SERVER then
    util.AddNetworkString('qsystem_add_structure_from_client')
    util.AddNetworkString('qsystem_remove_structure_from_client')
    util.AddNetworkString('qsystem_remove_all_structure_from_client')
end

QuestSystem = QuestSystem or {}
QuestSystem.storage = QuestSystem.storage or {}
QuestSystem.activeEvents = QuestSystem.activeEvents or {}
QuestSystem.structures = QuestSystem.structures or {}

function QuestSystem:EnableEvent(event_id, step)
    local allQuests = ents.FindByClass('quest_entity')

    for _, ent in pairs(allQuests) do
        if ent:GetQuestId() == event_id then
            return
        end
    end

    local event = QuestSystem:GetQuest(event_id)
    step = step or 'start'
    if event ~= nil and event.steps[step] ~= nil then
        local ply = table.Random(player.GetAll())
        local ent = ents.Create('quest_entity')
        ent:SetQuest(event_id)
        ent:SetPos(ply:GetPos())
        ent:Spawn()
        timer.Simple(1, function()
            if not IsValid(ent) then return end
            ent:SetStep(step)
        end)

        QuestSystem.activeEvents[event_id] = ent

        return ent
    end
    return NULL
end

function QuestSystem:DisableEvent(event_id)
    local allQuests = ents.FindByClass('quest_entity')

    for _, ent in pairs(allQuests) do
        if IsValid(ent) and ent:GetQuestId() == event_id then
            ent:Remove()
            return
        end
    end
end

function QuestSystem:GetAllEvents()
    local all_events = {}
    for quest_id, quest in pairs(list.Get('QuestSystem')) do
        if quest.isEvent then
            all_events[quest_id] = quest
        end
    end
    return all_events
end

function QuestSystem:SetStorage(storage_id, data_table)
    self.storage[storage_id] = data_table
end

function QuestSystem:GetStorage(storage_id)
    return self.storage[storage_id]
end

function QuestSystem:GetQuest(quest_id)
    return list.Get('QuestSystem')[quest_id]
end

function QuestSystem:GetAllQuest()
    return list.Get('QuestSystem')
end

function QuestSystem:ConsoleAlert(message)
    MsgN('[QSystem][ALER] ' .. tostring(message))
end

function QuestSystem:AdminAlert(message)
    self:ConsoleAlert(message)

    local script = 'surface.PlaySound("common/warning.wav");chat.AddText(Color(255,10,10), "[QSystem][ALER] ' .. message .. '")'
    for _, ply in pairs(player.GetHumans()) do
        if ply:IsAdmin() or ply:IsSuperAdmin() then
            local lastMessageTime = ply.qSystemLastMessageTime or 0
            if lastMessageTime < SysTime() then
                ply:SendLua(script)
                ply.qSystemLastMessageTime = SysTime() + 0.1
            end
        end
    end
end

function QuestSystem:GetConfig(key)
    return QuestSystem.cfg[key]
end

function QuestSystem:CheckRestiction(ply, restiction)
    if restiction ~= nil then
        local team = restiction.team
        if team ~= nil then
            local pTeam = ply:Team()
            if isstring(team) then
                if team ~=pTeam then return false end
            elseif istable(team) then
                if not table.HasValue(team, pTeam) then return false end
            end
        end

        local steamid = restiction.steamid
        if steamid ~= nil then
            local pSteamID = ply:SteamID()
            local pSteamID64 = ply:SteamID64()
            if isstring(steamid) then
                if steamid ~= pSteamID and steamid ~= pSteamID64 then return false end
            elseif istable(steamid) then
                if not table.HasValue(steamid, pSteamID) and
                    not table.HasValue(steamid, pSteamID64) then return false end
            end
        end

        local nick = restiction.nick
        if nick ~= nil then
            local pNick = ply:Nick():lower()
            if isstring(nick) then
                if nick:lower() ~= pNick then return false end
            elseif istable(nick) then
                local done = false
                for _, nickValue in pairs(nick) do
                    if nickValue:lower() == pNick  then
                        done = true
                        break
                    end
                end
                if not done then return false end
            end
        end

        local usergroup = restiction.usergroup
        if usergroup ~= nil then
            local pUserGroup = ply:GetUserGroup():lower()
            if isstring(usergroup) then
                if usergroup:lower() ~= pUserGroup then return false end
            elseif istable(usergroup) then
                local done = false
                for _, usergroupValue in pairs(usergroup) do
                    if string.find(usergroupValue:lower(), pUserGroup) ~= nil then
                        done = true
                        break
                    end
                end
                if not done then return false end
            end
        end

        if restiction.adminOnly ~= nil then
            if not ply:IsAdmin() and not ply:IsSuperAdmin() then return false end
        end
    end

    return true
end

if SERVER then
    function QuestSystem:SpawnStructure(quest_id, structure_name)
        local data = QuestSystem:GetStorage('structure'):Read(quest_id, structure_name)
        if data ~= nil then
            local spawn_id = quest_id .. '_' .. string.Replace(SysTime(), '.', '')
            QuestSystem.structures[spawn_id] = {}
            for id, prop in pairs(data.Props) do
                local ent = ents.Create(prop.class)
                ent:SetModel(prop.model)
                ent:SetPos(prop.pos)
                ent:SetAngles(prop.ang)
                ent:Spawn()
                ent:SetCustomCollisionCheck(true)
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                end
                table.insert(QuestSystem.structures[spawn_id], ent)
            end
            timer.Simple(1, function()
                if QuestSystem.structures[spawn_id] ~= nil then
                    local ids = {}
                    for _, ent in pairs(QuestSystem.structures[spawn_id]) do
                        if IsValid(ent) then
                            table.insert(ids, ent:EntIndex())
                        end
                    end
                    net.Start('qsystem_add_structure_from_client')
                    net.WriteString(spawn_id)
                    net.WriteTable(ids)
                    net.Broadcast()
                end
            end)
            return spawn_id
        end
        return nil
    end

    function QuestSystem:RemoveStructure(spawn_id)
        if QuestSystem.structures[spawn_id] ~= nil then
            for _, ent in pairs(QuestSystem.structures[spawn_id]) do
                if IsValid(ent) then
                    ent:FadeRemove()
                end
            end
            
            QuestSystem.structures[spawn_id] = nil

            net.Start('qsystem_remove_structure_from_client')
            net.WriteString(spawn_id)
            net.Broadcast()
        end
    end

    function QuestSystem:RemoveAllStructure()
        for spawn_id, data in pairs(QuestSystem.structures) do
            for _, ent in pairs(data) do
                if IsValid(ent) then
                    ent:FadeRemove()
                end
            end
        end

        net.Start('qsystem_remove_all_structure_from_client')
        net.Broadcast()
    end
else
    net.Receive('qsystem_add_structure_from_client', function()
        local spawn_id = net.ReadString()
        local ids = net.ReadTable()

        QuestSystem.structures[spawn_id] = {}

        for _, id in pairs(ids) do
            local ent = Entity(id)
            if IsValid(ent) then
                table.insert(QuestSystem.structures[spawn_id], ent)
            end
        end
    end)

    net.Receive('qsystem_remove_structure_from_client', function()
        local spawn_id = net.ReadString()
        QuestSystem.structures[spawn_id] = nil
    end)

    net.Receive('qsystem_remove_all_structure_from_client', function()
        QuestSystem.structures = {}
    end)
end

function QuestSystem:GetStructure(spawn_id)
    return QuestSystem.structures[spawn_id]
end

function QuestSystem:GetAllStructure()
    return QuestSystem.structures
end