local quest = {
	id = 'kill_zombie',
	title = 'Убить зомби',
	description = 'Найдите и убейте зомби который докучает местным жителям. Можно использовать любое оружие.',
	payment = 500,
	timeQuest = 600,
	steps = {
		start = {
			triggers = {
				spawn_zombie_trigger_1 = {
					onEnter = function(eQuest, ent)
						if CLIENT then return end
						if ent ~= eQuest:GetPlayer() then return end
						eQuest:NextStep('spawn')
					end
				},
				spawn_zombie_trigger_2 = {
					onEnter = function(eQuest, ent)
						if CLIENT then return end
						if ent ~= eQuest:GetPlayer() then return end
						eQuest:NextStep('spawn')
					end
				},
			}
		},
		spawn = {
			construct = function(eQuest)
				if CLIENT then return end
				eQuest:Notify('Враг близко', 'Неожиданно. Их оказалось больше, чем в заказе. Но это не важно, убейте всех.')
			end,
			points = {
				spawn_zombie = function(eQuest, positions)
					if CLIENT then return end
					local index = 0

					for _, pos in pairs(positions) do
						index = index + 1
						if index > 5 and math.random(0, 1) == 1 then continue end

						eQuest:SpawnQuestNPC(table.Random({'npc_zombie', 'npc_headcrab', 'npc_fastzombie'}), {
							pos = pos,
							type = 'enemy'
						})
					end
				end,
			},
			onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
				if CLIENT then return end

				if not eQuest:QuestNPCIsValid('enemy') then
					eQuest:NextStep('complete')
				end
			end
		},
		complete = {
			construct = function(eQuest)
				if CLIENT then return end
				eQuest:Notify('Завершено', 'Спасибо за вашу помощь! Больше это отродье не будет никому мешать.')
				eQuest:Reward()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)