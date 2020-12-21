net.RegisterCallback('qsystem_on_construct', function(_, ent, step)
    local quest = ent:GetQuest()

    if step == 'start' then
        if quest.isEvent then
            quest.title = '[Событие] ' .. quest.title
        end

        if quest.timeToNextStep ~= nil and quest.nextStep ~= nil then
            quest.description = quest.description .. '\nДо начала: ' .. quest.timeToNextStep .. ' сек.'
        end

        if quest.timeQuest ~= nil then
            quest.description = quest.description .. '\nВремя выполнения: ' .. quest.timeQuest .. ' сек.'
        end
    end
    
    if quest ~= nil and quest.steps[step].construct ~= nil then
        quest.steps[step].construct(ent)
    end
end)