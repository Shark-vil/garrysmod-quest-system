snet.Callback('qsystem_rpc_function_onUse', function(_, eQuest, ent)
    local step = eQuest:GetQuestStepTable()
    if step.onUse ~= nil then
        step.onUse(eQuest, ent)
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.Callback('qsystem_rpc_function_onQuestNPCKilled', function(_, eQuest, data, npc, attacker, inflictor)
    local step = eQuest:GetQuestStepTable()
    if step.onQuestNPCKilled ~= nil then
        step.onQuestNPCKilled(eQuest, data, npc, attacker, inflictor)
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.Callback('qsystem_rpc_function_onPoints', function(_, eQuest)
    local quest = eQuest:GetQuest()
    if not eQuest.points then return end

    for _, data in pairs(eQuest.points) do
        local steps = quest.steps
        if not steps  then return end

        local step = quest.steps[data.step]
        if step and step.points and step.points[data.name] then
            local func = step.points[data.name]
            if func then func(eQuest, data.points) end
        end
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.Callback('qsystem_rpc_function_onUseItem', function(_, item, activator, caller, useType, value)
    local eQuest = item:GetQuestEntity()
    local step = eQuest:GetQuestStep()
    local quest = eQuest:GetQuest()
    if quest.steps and quest.steps[step] and quest.steps[step].onUseItem then
        local func = quest.steps[step].onUseItem
        func(eQuest, item, activator, caller, useType, value)
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()