local language_data = {
	['default'] = {
		['title'] = 'Head hunter',
		['description'] = 'Kill a random player suggested by the customer.',
		['condition_title'] = 'Refusal',
		['condition_description'] = 'There are too few players on the server to start this quest.',
		['start'] = 'Kill player %player% before someone else does.',
		['failed_title'] = 'Failed',
		['failed_playerDeath'] = 'Unfortunately, the player died before you finished him off.',
		['failed_playerDisconnected'] = 'Unfortunately, the player left this world before you overtook him.',
		['complete_title'] = 'Completed',
		['complete_description'] = 'Good job. Let\'s hope he doesn\'t rise from the dead to get revenge...',
	},
	['russian'] = {
		['title'] = 'Охотник за головами',
		['description'] = 'Убейте случайного игрока, которого предложит заказчик.',
		['condition_title'] = 'Отказ',
		['condition_description'] = 'На сервере слишком мало игроков для начала этого задания.',
		['start'] = 'Убейте игрока %player% пока это не сделал кто-то другой.',
		['failed_title'] = 'Провалено',
		['failed_playerDeath'] = 'К сожалению, игрок умер до того, как его прикончили вы.',
		['failed_playerDisconnected'] = 'К сожалению, игрок покинул этот мир до того, как вы настигли его.',
		['complete_title'] = 'Завершено',
		['complete_description'] = 'Хорошая работа. Будем надеяться, что он не восстанет из мертвых, чтобы отомстить...',
	}
}

local lang = slib.language(language_data)

local quest = {
	id = 'player_killer',
	title = lang['title'],
	description = lang['description'],
	disableNotify = true,
	payment = 500,
	--[[
	-- An example of creating restrictions for quests (also works with dialogues) 
	restriction = {
		team = {
			TEAM_GANG,
			TEAM_MOB
		},
		steamid = {
			'STEAM_0:1:83432687'
		},
		nick = {
			'[FG] Shark_vil'
		},
		usergroup = {
			'superadmin'
		},
		adminOnly = true,
	},
	]]
	condition = function(ply)
		if player.GetCount() > 1 then
			return true
		else
			-- The check is done on the server, so the language will always return a value - by default
			-- Therefore, you need to get data from the player's language
			local player_language = ply:slibLanguage(language_data)
			ply:QuestNotify(player_language['condition_title'], player_language['condition_description'])
			return false
		end
	end,
	steps = {
		start = {
			construct = function(eQuest)
				if SERVER then
					local target = table.Random(player.GetAllOmit(eQuest:GetPlayer()))
					eQuest:SetNWEntity('playerTarget', target)

					local player_language = eQuest:GetPlayer():slibLanguage(language_data)
					local text = player_language['start']
					text = string.Replace(text, '%player%', target:Nick())

					eQuest:Notify(player_language['title'], text)
					eQuest:NextStep('kill_player')
				end
			end,
		},
		kill_player = {
			hooks = {
				PlayerDeath = function(eQuest, victim, inflictor, attacker)
					local target = eQuest:GetNWEntity('playerTarget')
					if target == victim then
						local quester = eQuest:GetPlayer()
						local player_language = quester:slibLanguage(language_data)

						if quester == attacker then
							eQuest:NextStep('complete')
						else
							eQuest:Notify(player_language['failed_title'], player_language['failed_playerDeath'])
							eQuest:Failed()
						end
					end
				end,
				PlayerDisconnected = function(eQuest, ply)
					local target = eQuest:GetNWEntity('playerTarget')
					if target == ply then
						local quester = eQuest:GetPlayer()
						local player_language = quester:slibLanguage(language_data)

						eQuest:Notify(player_language['failed_title'], player_language['failed_playerDisconnected'])
						eQuest:Failed()
					end
				end,
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