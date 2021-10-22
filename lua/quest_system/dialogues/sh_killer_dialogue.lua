local conversation = {
	id = 'killer',
	name = 'Киллер',
	autoParent = true,
	class = 'npc_citizen',
	condition = function(ply, npc)
		if not bgNPC then return false end
		local actor = bgNPC:GetActor(npc)
		if not actor then return false end

		return actor:GetType() == 'gangster'
	end,
	steps = {
		start = {
			text = {'Я полагаю, у тебя есть ко мне дело?', 'Что нужно?',},
			answers = {
				{
					text = {'Я хочу заказать убийство...',},
					event = function(eDialogue)
						if CLIENT then return end
						eDialogue:Next('select_target')
					end
				},
			},
		},
		select_target = {
			text = 'Ого вот так прямо? И кто же этот счастливичик?',
			answers = function()
				local result = {}

				table.insert(result, {
					text = 'Прости, я передумал.',
					event = function(eDialogue)
						if CLIENT then return end
						eDialogue:Next('cancel')
					end
				})

				for _, ply in ipairs(player.GetAll()) do
					table.insert(result, {
						text = 'Это ' .. ply:Nick(),
						event = function(eDialogue)
							if CLIENT then return end
							eDialogue:slibSetVar('murder_target', ply)
							eDialogue:Next('finish_select')
						end
					})
				end

				return result
			end
		},
		finish_select = {
			text = function(eDialogue)
				local ply = eDialogue:slibGetVar('murder_target')
				return 'Значит это ' .. ply:Nick() .. ', хорошо, заказ принят'
			end,
			delay = 3.5,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				local ply = eDialogue:slibGetVar('murder_target')
				local npc = eDialogue:GetNPC()
				local actor = bgNPC:GetActor(npc)
				eDialogue:Stop()

				timer.Simple(1, function()
					ply.bgn_always_visible = true
					actor:AddEnemy(ply)
					actor:SetState('killer')
				end)
			end
		},
		cancel = {
			text = 'Может оно и к лучшему. Бывай.',
			delay = 3.5,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				eDialogue:Stop()
			end
		}
	}
}

list.Set('QuestSystemDialogue', conversation.id, conversation)