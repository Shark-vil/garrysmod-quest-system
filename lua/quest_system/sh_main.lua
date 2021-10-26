if SERVER then
	local function ActivateRandomEvent(id)
		local event = QuestSystem:GetQuest(id)
		if not event then event = table.Random(QuestSystem:GetAllEvents()) end
		if not event then return end

		local active_event = QuestSystem.activeEvents[event.id]
		if not active_event or not IsValid(active_event) then
			QuestSystem:EnableEvent(event.id)
		end
	end

	scommand.Create('qsystem_activate_event').OnServer(function(ply, cmd, args)
		ActivateRandomEvent(args[1])
	end).AutoComplete(function(cmd, stringargs)
		local tbl = {}
		for id, _ in pairs(QuestSystem:GetAllEvents()) do tbl[ #tbl + 1] = cmd .. ' ' .. id end
		return tbl
	end).Access( { isAdmin = true } ).Register()

	local current_time = 0
	hook.Add('Think', 'QSystemActivateRandomEvents', function()
		if #player.GetAll() == 0 then return end

		local delay_time = QuestSystem:GetConfig('EventsTimeDelay')

		if delay_time > 0 then
			if current_time > CurTime() then
				return
			else
				current_time = CurTime() + delay_time
			end
		end

		if not QuestSystem:GetConfig('EnableEvents') then return end

		local randNum = QuestSystem:GetConfig('EventsRandomActivate')
		local maxEvents = QuestSystem:GetConfig('MaxActiveEvents')

		if randNum > 0 and math.random(1, randNum) ~= 1 then return end

		if table.Count(QuestSystem.activeEvents) > maxEvents then return end

		ActivateRandomEvent()
	end)

	hook.Add('OnEntityCreated', 'QSystem.ReloadingNPCsRestiction', function(npc)
		if npc:IsNPC() then
			for _, ent in ipairs(ents.FindByClass('quest_entity')) do
				if IsValid(ent) then
					ent:SetNPCsBehavior(npc)
				end
			end
		end
	end)
end

hook.Add('DisableEvent', 'QSystem.RemoveEventFromTable', function(eQuest, quest)
	QuestSystem.activeEvents[quest.id] = nil
end)