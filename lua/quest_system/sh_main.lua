MsgN('Loading the quest system.')

QuestSystem = QuestSystem or {}
QuestSystem.storage = QuestSystem.storage or {}
QuestSystem.activeEvents = QuestSystem.activeEvents or {}

if SERVER then
    local function ActivateRandomEvent()
        local events = QuestSystem:GetAllEvents()
        local event = table.Random(events)

        if QuestSystem.activeEvents[event.id] == nil then
            QuestSystem:EnableEvent(event.id)
        end
    end
    concommand.Add('qsystem_activate_random_event', function(ply)
        if IsValid(ply) then
            if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
        end
        ActivateRandomEvent()
    end)

    local current_time = 0
    hook.Add('Think', 'QSystemActivateRandomEvents', function()
        if #player.GetAll() == 0 then return end

        local delay_time = QuestSystem:GetConfig('EventsTimeDelay')

        if delay_time > 0 then
            if current_time > CurTime() then
                return
            else
                current_time = CurTime() + delay_time
            end
        end

        if not QuestSystem:GetConfig('EnableEvents') then return end
        
        local randNum = QuestSystem:GetConfig('EventsRandomActivate')
        local maxEvents = QuestSystem:GetConfig('MaxActiveEvents')

        if randNum > 0 then
            if math.random(1, randNum) ~= 1 then return end
        end

        if table.Count(QuestSystem.activeEvents) > maxEvents then return end

        ActivateRandomEvent()
    end)
end

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

        return true
    end
    return false
end

hook.Add('DisableEvent', 'QSystem.RemoveEventFromTable', function(eQuest, quest)
    QuestSystem.activeEvents[quest.id] = nil
end)

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