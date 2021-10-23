local conversation = {
	id = 'free_medic',
	name = 'Вольный медик',
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
			text = {
				'Ты что-то хотел?',
				'А?..',
				'Чего надо?',
				'Да-да?',
				'Я слушаю.',
				'Чего хотели?'
			},
			event = function(eDialogue)
				if CLIENT and eDialogue.isFirst then
					eDialogue:VoiceSay('vo/canals/matt_go_nag01.wav')
				end
			end,
			answers = {
				{
					text = {
						'Ничего, простите.',
						'Обознался.'
					},
					condition = function(eDialogue)
						local lock_health = eDialogue:GetPlayerValue('lock_health')
						return lock_health == nil
					end,
					event = function(eDialogue)
						if SERVER then eDialogue:Next('exit') end
					end
				},
				{
					text = 'Больше ничего не нужно, пока.',
					condition = function(eDialogue)
						local lock_health = eDialogue:GetPlayerValue('lock_health')
						return lock_health ~= nil
					end,
					event = function(eDialogue)
						if SERVER then eDialogue:Next('exit_2') end
					end
				},
				{
					text = 'Вылечи меня пожалуйста',
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
			text = 'Ага, а деньги то есть?... Чего, и всего? Этого мало. Зайди когда на руках будет хотяб сотня...',
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		rejection_health = {
			text = 'Я тебя уже подлатал, у меня и другие клиенты есть. Можешь зайти позднее.',
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		get_health = {
			text = 'Ладно. Сейчас мы тебя починим. Вот так... И тут... Готово!',
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
			text = 'Ты не выглядишь таким уж помятым. Обойдёшься.',
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Next('start', true) end
			end
		},
		exit = {
			text = {
				'Ебать ты...',
				'Зря время отнимаешь',
				'Ну тебя...',
				'Ладно.',
				'Ладно. Всего доброго',
				'Ну бывай'
			},
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
			text = {
				'Ладно.',
				'Ладно. Всего доброго',
				'Всего доброго',
				'Ну бывай'
			},
			delay = 3,
			eventDelay = function(eDialogue)
				if SERVER then eDialogue:Stop() end
			end
		}
	}
}
list.Set('QuestSystemDialogue', conversation.id, conversation)