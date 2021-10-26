local language_data = slib.language({
	['default'] = {
		['title'] = 'Kill drug dealer',
		['description'] = 'A detachment of enemy combines has landed somewhere. Find and eliminate them!',
		['cancel_title'] = 'Event canceled',
		['cancel_description'] = 'The event did not take place due to a lack of players in the event area.',
		['spawn_combines_title'] = 'The enemy is close',
		['spawn_combines_description'] = 'Kill the arriving enemies',
		['complete_title'] = 'Completed',
		['complete_description'] = 'All enemies were killed',
	},
	['russian'] = {
		['title'] = 'Убить комбайнов',
		['description'] = 'Где-то высадился отряд вражеских комбайнов. Найдите и устраните их!',
		['cancel_title'] = 'Событие отменено',
		['cancel_description'] = 'Событие не состоялось из-за нехватки игроков в зоне ивента.',
		['spawn_combines_title'] = 'Враг близко',
		['spawn_combines_description'] = 'Убейте прибывших противников',
		['complete_title'] = 'Завершено',
		['complete_description'] = 'Все противники были уничтожены',
	}
})

local lang = slib.language(language_data)

local quest = {
	id = 'event_kill_combine',
	title = lang['title'],
	description = lang['description'],
	payment = 500,
	isEvent = true,
	npcNotReactionOtherPlayer = true,
	timeToNextStep = 20,
	nextStep = 'spawn_combines',
	nextStepCheck = function(eQuest)
		local count = #eQuest.players

		if count == 0 then
			for _, ply in ipairs(player.GetHumans()) do
				local player_language = ply:slibLanguage(language_data)
				ply:QuestNotify(player_language['cancel_title'], player_language['cancel_description'])
			end
		end

		return count ~= 0
	end,
	timeQuest = 120,
	failedText = {
		title = 'Quest failed :(',
		text = 'The execution time has expired.'
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
				if SERVER then return end
				eQuest:NotifyOnlyRegistred(lang['spawn_combines_title'], lang['spawn_combines_description'])
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
				if CLIENT then
					eQuest:Notify(lang['complete_title'], lang['complete_description'])
					return
				end

				eQuest:Reward()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)