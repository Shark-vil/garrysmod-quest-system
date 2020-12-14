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

hook.Add('DisableEvent', 'QSystem.RemoveEventFromTable', function(eQuest, quest)
    QuestSystem.activeEvents[quest.id] = nil
end)