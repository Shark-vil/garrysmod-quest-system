local conversation = {
    id = 'talking_bank',
    name = 'Банка',
    isBackground = true,
    model = 'models/props_junk/PopCan01a.mdl',
    condition = function(ply, ent)
        if ent:GetModel():lower() == ('models/props_junk/PopCan01a.mdl'):lower() then
            if math.random(0, 10) ~= 1 then
                return false
            end
        end
    end,
    start = {
        text = {
            'ТЕБЕ ЧЕГО НАДО?!!!',
            'Поставь меня обратно!',
            'Не трогай меня!',
            'ААААААААААААААААААААААААААА!!!',
            'НЕТ, НЕ НАДО, ОТПУСТИ!'
        },
        delay = 4,
        event = function(eDialogue)
            if CLIENT then
                eDialogue:VoiceSay('vo/coast/bugbait/sandy_help.wav')
            end
        end
    }
}

list.Set('QuestSystemDialogue', conversation.id, conversation)