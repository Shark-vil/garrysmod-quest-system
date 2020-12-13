if SERVER then
    util.AddNetworkString('cl_qsystem_entity_step_construct')
    util.AddNetworkString('cl_qsystem_entity_step_triggers')
    util.AddNetworkString('cl_qsystem_entity_step_points')
    util.AddNetworkString('cl_qsystem_entity_step_done')
    util.AddNetworkString('cl_qsystem_add_npc')
    util.AddNetworkString('cl_qsystem_add_item')
else
    net.Receive('cl_qsystem_entity_step_construct', function()
        local ent = net.ReadEntity()
        local quest_id = net.ReadString()
        local step = net.ReadString()
        local quest = QuestSystem:GetQuest(quest_id)

        if quest ~= nil and quest.steps[step].construct ~= nil then
            quest.steps[step].construct(ent)
        end
    end)

    net.Receive('cl_qsystem_entity_step_triggers', function()
        local ent = net.ReadEntity()
        local triggers = net.ReadTable()
        local quest = QuestSystem:GetQuest(quest_id)

        if IsValid(ent) then
            ent.triggers = triggers
        end
    end)

    net.Receive('cl_qsystem_entity_step_points', function()
        local ent = net.ReadEntity()
        local points = net.ReadTable()
        local quest = QuestSystem:GetQuest(quest_id)

        if IsValid(ent) then
            ent.points = points
        end
    end)

    net.Receive('cl_qsystem_entity_step_done', function()
        local ent = net.ReadEntity()
        local step = net.ReadString()
        ent:OnNextStep(step)
    end)

    net.Receive('cl_qsystem_add_npc', function()
        local ent = net.ReadEntity()
        local npc = net.ReadEntity()
        local type = net.ReadString()
        local tag = net.ReadString()

        ent:AddQuestNPC(npc, type, tag)
    end)

    net.Receive('cl_qsystem_add_item', function()
        local ent = net.ReadEntity()
        local item = net.ReadEntity()
        local id = net.ReadString()
        
        ent:AddQuestItem(item, id)
    end)
end