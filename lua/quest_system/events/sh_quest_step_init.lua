if SERVER then
    util.AddNetworkString('cl_network_qsystem_entity_step_construct')
    util.AddNetworkString('cl_network_qsystem_entity_step_triggers')
    util.AddNetworkString('cl_network_qsystem_entity_step_done')
else
    net.Receive('cl_network_qsystem_entity_step_construct', function()
        local ent = net.ReadEntity()
        local quest_id = net.ReadString()
        local step = net.ReadString()
        local quest = QuestSystem:GetQuest(quest_id)

        if quest ~= nil and quest.steps[step].construct ~= nil then
            quest.steps[step].construct(ent)
        end
    end)

    net.Receive('cl_network_qsystem_entity_step_triggers', function()
        local ent = net.ReadEntity()
        local triggers = net.ReadTable()
        local quest = QuestSystem:GetQuest(quest_id)

        if IsValid(ent) then
            ent.triggers = triggers
        end
    end)

    net.Receive('cl_network_qsystem_entity_step_done', function()
        local ent = net.ReadEntity()
        local step = net.ReadString()
        ent:OnNextStep(step)
    end)
end