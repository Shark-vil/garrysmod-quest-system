net.RegisterCallback('qsystem_on_next_step', function(_, ent, step)
    ent:OnNextStep(step)
    QuestSystem:Debug('Next Step - ' .. step)
end)