MsgN('Loading the quest system.')

QuestSystem = QuestSystem or {}
QuestSystem.storage = QuestSystem.storage or {}

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