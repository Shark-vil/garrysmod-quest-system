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

function QuestSystem:GetQuest(quest_id)
    return list.Get('QuestSystem')[quest_id]
end

function QuestSystem:GetAllQuest()
    return list.Get('QuestSystem')
end