local lang = slib.language({
	['default'] = {
		['name'] = 'Free medic',
		['start'] = {
			'What did you want?',
			'Mm?...',
			'Yes?',
			'I\'m listening to.',
			'What did they want?',
		},
		['start_answers_1'] = {
			'Nothing, sorry.',
			'I identified myself.'
		},
		['start_answers_2'] = 'Nothing else is needed, yet.',
		['start_answers_3'] = 'Cure me, please.',
		['few_money'] = 'Hah, and that is money?... What, and that\'s all? This is not enough. Come in when you have at least a hundred...',
		['rejection_health'] = 'I have already patched you up, I have other clients as well. You can come back later.',
		['get_health'] = 'OK. We will fix you now. That\'s it... And then... Done!',
		['failed_health'] = 'You don\'t look so rumpled. You can do it.',
		['exit'] = {
			'Fuck you...',
			'You are wasting my time.',
			'Damn you...',
			'Okay.',
			'Okay. All the best.',
			'Goodbye.',
			'Bye.',
		},
		['exit_2'] = {
			'Okay.',
			'Okay. All the best.',
			'Всего доброго',
			'Goodbye.',
			'Bye.',
		},
	},
	['russian'] = {
		['name'] = 'Вольный медик',
		['start'] = {
			'Ты что-то хотел?',
			'А?..',
			'Чего надо?',
			'Да-да?',
			'Я слушаю.',
			'Чего хотели?',
		},
		['start_answers_1'] = {
			'Ничего, простите.',
			'Обознался.'
		},
		['start_answers_2'] = 'Больше ничего не нужно, пока.',
		['start_answers_3'] = 'Вылечи меня, пожалуйста.',
		['few_money'] = 'Ага, а деньги то есть?... Чего, и всего? Этого мало. Зайди когда на руках будет хотяб сотня...',
		['rejection_health'] = 'Я тебя уже подлатал, у меня и другие клиенты есть. Можешь зайти позднее.',
		['get_health'] = 'Ладно. Сейчас мы тебя починим. Вот так... И тут... Готово!',
		['failed_health'] = 'Ты не выглядишь таким уж помятым. Обойдёшься.',
		['exit'] = {
			'Ебать ты...',
			'Ты тратишь моё время.',
			'Ну тебя...',
			'Ладно.',
			'Ладно. Всего доброго',
			'Ну бывай',
			'Пока',
			'Прощай',
		},
		['exit_2'] = {
			'Ладно.',
			'Ладно. Всего доброго',
			'Всего доброго',
			'Ну бывай',
			'Пока',
			'Прощай',
		},
	}
})

local conversation = {
	id = 'free_medic',
	name = lang['name'],
	autoParent = true,
	isRandomNpc = true,
	randomNumber = 2,
	class = 'npc_citizen',
	condition = function(ply, npc)
		if not bgNPC then
			local actor = bgNPC:GetActor(npc)
			if actor then return actor:HasTeam('medic') end
		end

		return string.find(npc:GetModel():lower(), '/male_') ~= nil
	end,
	steps = {
		start = {
			text = lang['start'],
			event = function(eDialogue)
				if CLIENT and eDialogue.isFirst then
					eDialogue:VoiceSay('vo/canals/matt_go_nag01.wav')
				end
			end,
			answers = {
				{
					text = lang['start_answers_1'],
					condition = function(eDialogue)
						local lock_health = eDialogue:GetPlayerValue('lock_health')
						return lock_health == nil
					end,
					event = function(eDialogue)
						if SERVER then eDialogue:Next('exit') end
					end
				},
				{
					text = lang['start_answers_2'],
					condition = function(eDialogue)
						local lock_health = eDialogue:GetPlayerValue('lock_health')
						return lock_health ~= nil
					end,
					event = function(eDialogue)
						if SERVER then eDialogue:Next('exit_2') end
					end
				},
				{
					text = lang['start_answers_3'],
					event = function(eDialogue)
						if SERVER then
							local ply = eDialogue:GetPlayer()

							if ply:Health() < 90 then
								local lock_health = eDialogue:GetPlayerValue('lock_health')
								if lock_health ~= nil and tonumber(lock_health) > os.time() then
									eDialogue:Next('rejection_health')
								else
									if engine.ActiveGamemode() == 'darkrp' and ply:getDarkRPVar('money') < 100 then
										eDialogue:Next('few_money')
										return
									end

									eDialogue:Next('get_health')
								end
							else
								eDialogue:Next('failed_health')
							end
						end
					end
				},
			},
		},
		few_money = {
			text = lang['few_money'],
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		rejection_health = {
			text = lang['rejection_health'],
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		get_health = {
			text = lang['get_health'],
			delay = 4,
			eventDelay = function(eDialogue)
				if SERVER then
					local ply = eDialogue:GetPlayer()
					local health = ply:Health()
					local new_health = health + math.random(10, 50)

					if new_health < 100 then
						ply:SetHealth(new_health)
					else
						ply:SetHealth(100)
					end

					if engine.ActiveGamemode() == 'darkrp' then
						ply:addMoney(-100)
					end

					eDialogue:SavePlayerValue('lock_health', os.time() + 60)
					eDialogue:Next('start', true)
				end
			end
		},
		failed_health = {
			text = lang['failed_health'],
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		exit = {
			text = lang['exit'],
			delay = 3,
			eventDelay = function(eDialogue)
				if CLIENT then
					eDialogue:VoiceSay('vo/canals/gunboat_dam.wav')
				else
					eDialogue:Stop()
				end
			end
		},
		exit_2 = {
			text = lang['exit_2'],
			delay = 3,
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Stop() end
			end
		}
	}
}
list.Set('QuestSystemDialogue', conversation.id, conversation)