MsgN('Loading the quest system.')

if CLIENT then
    surface.CreateFont( "QSystemNotifyFont", {
        font = "Arial",
        extended = false,
        size = 16,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )
    
end

QuestSystem = QuestSystem or {}
QuestSystem.storage = {}

function QuestSystem:SetQuest(quest)
    QuestSystem.storage[quest.id] = quest
end

function QuestSystem:GetQuest(quest_id)
    return QuestSystem.storage[quest_id]
end

function QuestSystem:GetAllQuest()
    return QuestSystem.storage
end