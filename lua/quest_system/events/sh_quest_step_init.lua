if SERVER then
    util.AddNetworkString('cl_qsystem_entity_step_construct')
    util.AddNetworkString('cl_qsystem_entity_step_triggers')
    util.AddNetworkString('cl_qsystem_entity_step_points')
    util.AddNetworkString('cl_qsystem_entity_step_done')
    util.AddNetworkString('cl_qsystem_add_npc')
    util.AddNetworkString('cl_qsystem_add_item')
    util.AddNetworkString('cl_qsystem_add_player')
    util.AddNetworkString('cl_qsystem_remove_player')
else
    net.Receive('cl_qsystem_entity_step_construct', function()
        local ent = net.ReadEntity()
        local quest_id = net.ReadString()
        local step = net.ReadString()
        local title, description

        if step == 'start' then
            title = net.ReadString()
            description = net.ReadString()
        end

        local quest = QuestSystem:GetQuest(quest_id)
        ent.quest = ent.quest or QuestSystem:GetQuest(quest_id)

        local quest = ent:GetQuest()
        if title ~= nil then
            quest.title = title
        end
        if description ~= nil then
            quest.description = description
        end

        if quest ~= nil and quest.steps[step].construct ~= nil then
            quest.steps[step].construct(ent)
        end
    end)

    net.Receive('cl_qsystem_entity_step_triggers', function()
        local ent = net.ReadEntity()
        local triggers = net.ReadTable()
        local quest = ent:GetQuest()

        if IsValid(ent) then
            ent.triggers = triggers
        end
    end)

    net.Receive('cl_qsystem_entity_step_points', function()
        local ent = net.ReadEntity()
        local points = net.ReadTable()
        local quest = ent:GetQuest()

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

    net.Receive('cl_qsystem_add_player', function()
        local ent = net.ReadEntity()
        local ply = net.ReadEntity()

        ent:AddPlayer(ply)
    end)

    net.Receive('cl_qsystem_remove_player', function()
        local ent = net.ReadEntity()
        local ply = net.ReadEntity()

        ent:RemovePlayer(ply)
    end)
end