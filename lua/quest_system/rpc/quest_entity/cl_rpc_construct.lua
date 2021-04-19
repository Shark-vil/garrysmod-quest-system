snet.Callback('qsystem_on_construct', function(_, ent, step, quest_data)
    local quest = ent:GetQuest()

    if not quest then
        if not quest_data then return end
        list.Set('QuestSystem', quest_data.id, quest_data)
        
        quest = list.Get('QuestSystem')[quest_data.id]
        if not quest then return end
    end

    if step == 'start' then
        if quest.isEvent then
            quest.title = '[Событие] ' .. quest.title
        end

        if quest.timeToNextStep and quest.nextStep then
            quest.description = quest.description .. '\nДо начала: ' .. quest.timeToNextStep .. ' сек.'
        end

        if quest.timeQuest then
            quest.description = quest.description .. '\nВремя выполнения: ' .. quest.timeQuest .. ' сек.'
        end
    end
    
    if quest and quest.steps and quest.steps[step] and quest.steps[step].construct then
        quest.steps[step].construct(ent)
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()