QuestSystem = QuestSystem or {}
QuestSystem.storage = QuestSystem.storage or {}
QuestSystem.activeEvents = QuestSystem.activeEvents or {}

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