local quest = {
	id = 'event_kill_combine',
	title = 'Убить комбайнов',
	description = 'Где-то высадился отряд вражеских комбайнов. Найдите и устраните их!',
	payment = 500,
	isEvent = true,
	npcNotReactionOtherPlayer = true,
	timeToNextStep = 20,
	nextStep = 'spawn_combines',
	nextStepCheck = function(eQuest)
		local count = #eQuest.players

		if count == 0 then
			eQuest:NotifyAll('Событие отменено', 'Событие не состоялось из-за нехватки игроков в зоне ивента.')
		end

		return count ~= 0
	end,
	timeQuest = 120,
	failedText = {
		title = 'Задание провалено',
		text = 'Время выполнения истекло.'
	},
	steps = {
		start = {
			triggers = {
				spawn_combines_trigger = {
					onEnter = function(eQuest, ent)
						eQuest:AddPlayer(ent)
					end,
					onExit = function(eQuest, ent)
						if not eQuest:HasQuester(ent) then return end
						eQuest:RemovePlayer(ent)
					end
				},
			},
		},
		spawn_combines = {
			construct = function(eQuest)
				eQuest:NotifyOnlyRegistred('Враг близко', 'Убейте прибивших противников')
			end,
			structures = {
				barricades = true
			},
			points = {
				spawn_combines = function(eQuest, positions)
					for _, pos in pairs(positions) do
						eQuest:SpawnQuestNPC('npc_combine_s', {
							type = 'enemy',
							pos = pos,
							model = array.Random({'models/Combine_Soldier.mdl', 'models/Combine_Soldier_PrisonGuard.mdl', 'models/Combine_Super_Soldier.mdl'}),
							weapon_class = array.Random({'weapon_ar2', 'weapon_shotgun',})
						})
					end

					eQuest:MoveEnemyToRandomPlayer()
				end,
			},
			hooks = {
				OnNPCKilled = function(eQuest, npc, attacker, inflictor)
					if not eQuest:IsAliveQuestNPC('enemy') then
						eQuest:NextStep('complete')
					end
				end
			}
		},
		complete = {
			construct = function(eQuest)
				eQuest:NotifyOnlyRegistred('Завершено', 'Все противники были уничтожены')
				eQuest:Reward()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)