if SERVER then
    util.AddNetworkString('cl_qsystem_on_construct')
    util.AddNetworkString('cl_qsystem_sync_triggers')
    util.AddNetworkString('cl_qsystem_sync_points')
    util.AddNetworkString('cl_qsystem_on_next_step')
    util.AddNetworkString('cl_qsystem_sync_npcs')
    util.AddNetworkString('cl_qsystem_sync_items')
    util.AddNetworkString('cl_qsystem_sync_players')
    util.AddNetworkString('cl_qsystem_sync_values')
    util.AddNetworkString('cl_qsystem_sync_weapons')
else
    net.Receive('cl_qsystem_on_construct', function()
        local ent = net.ReadEntity()

        if not IsValid(ent) or not table.HasValue(ent.players, LocalPlayer()) then return end

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

    net.Receive('cl_qsystem_sync_triggers', function()
        local ent = net.ReadEntity()
        local triggers = net.ReadTable()
        ent.triggers = triggers

        QuestSystem:Debug('SyncTriggers (' .. table.Count(triggers) .. ') - ' .. table.ToString(triggers))
    end)

    net.Receive('cl_qsystem_sync_points', function()
        local ent = net.ReadEntity()
        local points = net.ReadTable()
        ent.points = points

        QuestSystem:Debug('SyncPoints (' .. table.Count(points) .. ') - ' .. table.ToString(points))
    end)

    net.Receive('cl_qsystem_on_next_step', function()
        local ent = net.ReadEntity()
        local step = net.ReadString()
        ent:OnNextStep(step)

        QuestSystem:Debug('Next Step - ' .. step)
    end)

    net.Receive('cl_qsystem_sync_npcs', function()
        local ent = net.ReadEntity()
        local npcs = net.ReadTable()
        ent.npcs = npcs

        QuestSystem:Debug('SyncNPCs (' .. table.Count(npcs) .. ') - ' .. table.ToString(npcs))
    end)

    net.Receive('cl_qsystem_sync_items', function()
        local ent = net.ReadEntity()
        local items = net.ReadTable()
        ent.items = items

        QuestSystem:Debug('SyncItems (' .. table.Count(items) .. ') - ' .. table.ToString(items))
    end)

    net.Receive('cl_qsystem_sync_players', function()
        local ent = net.ReadEntity()
        local players = net.ReadTable()
        ent.players = players

        QuestSystem:Debug('SyncPlayers (' .. table.Count(players) .. ') - ' .. table.ToString(players))
    end)

    net.Receive('cl_qsystem_sync_values', function()
        local ent = net.ReadEntity()
        local values = net.ReadTable()
        ent.values = values

        QuestSystem:Debug('SyncValues (' .. table.Count(values) .. ') - ' .. table.ToString(values))
    end)

    net.Receive('cl_qsystem_sync_weapons', function()
        local ent = net.ReadEntity()
        local weapons = net.ReadTable()
        ent.weapons = weapons

        QuestSystem:Debug('SyncWeapons (' .. table.Count(weapons) .. ') - ' .. table.ToString(weapons))
    end)
end