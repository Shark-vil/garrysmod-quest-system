snet.RegisterEntityCallback('qsystem_rpc_function_onUse', function(_, eQuest, ent)
    local step = eQuest:GetQuestStepTable()
    if step.onUse ~= nil then
        step.onUse(eQuest, ent)
    end
end)

snet.RegisterEntityCallback('qsystem_rpc_function_onQuestNPCKilled', function(_, eQuest, data, npc, attacker, inflictor)
    local step = eQuest:GetQuestStepTable()
    if step.onQuestNPCKilled ~= nil then
        step.onQuestNPCKilled(eQuest, data, npc, attacker, inflictor)
    end
end)

snet.RegisterEntityCallback('qsystem_rpc_function_onPoints', function(_, eQuest)
    local quest = eQuest:GetQuest()
    for _, data in pairs(eQuest.points) do
        local func = quest.steps[data.step].points[data.name]
        if func ~= nil then
            func(eQuest, data.points)
        end
    end
end)

snet.RegisterEntityCallback('qsystem_rpc_function_onUseItem', function(_, item, activator, caller, useType, value)
    local eQuest = item:GetQuestEntity()
    local step = eQuest:GetQuestStep()
    local quest = eQuest:GetQuest()
    if quest.steps[step].onUseItem ~= nil then
        local func = quest.steps[step].onUseItem
        func(eQuest, item, activator, caller, useType, value)
    end
end)