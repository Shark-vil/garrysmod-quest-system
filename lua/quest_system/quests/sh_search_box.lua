local language_data = {
	['default'] = {
		['title'] = 'Find the box',
		['description'] = 'Our employer has lost his box of valuables. Find it and take it to the customer.',
		['spawn_enemy_title'] = 'Uninvited guests',
		['spawn_enemy_description'] = 'Oh no, it seems our customer has been attacked! Save him in order not to fail the mission.',
		['complete_title'] = 'Completed',
		['loss_description'] = 'You saved the client. Now you can place your order.',
		['give_box_title'] = 'Delivery',
		['give_box_description'] = 'The case is small. Find a client and give him the box.',
		['attack_on_the_customer_title'] = 'Completed',
		['attack_on_the_customer_description'] = 'Great, you found the box. Now take it to the customer.',
		['complete_description'] = 'You have successfully delivered your order to the recipient.',
		['failed_title'] = 'Провалено',
		['failed_description'] = 'The customer is dead, you will not receive a reward for completing it.',
	},
	['russian'] = {
		['title'] = 'Найти коробку',
		['description'] = 'Наш наниматель потерял свою коробку с ценными вещами. Найдите её и отнесите заказчику.',
		['spawn_enemy_title'] = 'Незваные гости',
		['spawn_enemy_description'] = 'О нет, кажется на нашего заказчика напали! Спасите его, чтобы не провалить задание.',
		['complete_title'] = 'Завершено',
		['loss_description'] = 'Вы спасли клиента. Теперь можете отдать заказ.',
		['give_box_title'] = 'Доставка',
		['give_box_description'] = 'Дело за малым. Найдите клиента и отдайте ему коробку.',
		['attack_on_the_customer_title'] = 'Завершено',
		['attack_on_the_customer_description'] = 'Отлично, вы нашли коробку. Теперь отнесите её заказчику.',
		['complete_description'] = 'Вы успешно доставили заказ получателю.',
		['failed_title'] = 'Провалено',
		['failed_description'] = 'Заказчик мёртв, вы не получите награду за выполнение.',
	}
}

local lang = slib.language(language_data)

local quest = {
	id = 'search_box',
	title = lang['title'],
	description = lang['description'],
	payment = 500,
	npcNotReactionOtherPlayer = false,
	functions = {
		f_spawn_enemy_npcs = function(eQuest, ent)
			if ent ~= eQuest:GetPlayer() then return end
			if CLIENT then
				eQuest:Notify(lang['spawn_enemy_title'], lang['spawn_enemy_description'])
				return
			end

			eQuest:NextStep('safe_customer')
		end,
		f_loss_conditions = function(eQuest)
			if not eQuest:QuestNPCIsValid('friend', 'customer') then
				if SERVER then
					eQuest:NextStep('failed')
				end
			elseif not eQuest:QuestNPCIsValid('enemy') then
				if SERVER then
					eQuest:NextStep('give_box')
				else
					eQuest:Notify(lang['complete_title'], lang['loss_description'])
				end
			end
		end,
		f_spawn_customer = function(eQuest, pos, isAttack)
			if CLIENT then return end
			if eQuest:QuestNPCIsValid('friend', 'customer') then return end
			local weapon_class = nil

			if isAttack then
				weapon_class = table.Random({'weapon_pistol', 'weapon_smg1', 'weapon_smg1', 'weapon_shotgun', 'weapon_357'})
			end

			eQuest:SpawnQuestNPC('npc_citizen', {
				pos = pos,
				weapon_class = weapon_class,
				type = 'friend',
				tag = 'customer',
				afterSpawnExecute = function(_, data)
					if not isAttack then return end
					local npc = data.npc
					eQuest:MoveQuestNpcToPosition(npc:GetPos(), 'enemy')
				end
			})
		end
	},
	steps = {
		start = {
			points = {
				spawn_quest_item_points = function(eQuest, positions)
					if CLIENT then return end

					local item = eQuest:SpawnQuestItem('quest_item', {
						id = 'box',
						model = 'models/props_junk/cardboard_box004a.mdl',
						pos = table.Random(positions),
						ang = AngleRand()
					})
					item:SetFreeze(true)
					eQuest:SetArrowVector(item)
				end,
				customer = function(eQuest, positions)
					eQuest:QuestFunction('f_spawn_customer', eQuest, table.Random(positions), true)
				end,
			},
			onUseItem = function(eQuest, item)
				if CLIENT then return end

				if eQuest:GetQuestItem('box') == item then
					item:FadeRemove()

					local customer = eQuest:GetQuestNpc('friend', 'customer')
					eQuest:SetArrowVector(customer)

					if math.random(0, 1) == 1 then
						eQuest:SetVariable('is_customer_attack', true)
						eQuest:NextStep('attack_on_the_customer')
					else
						eQuest:NextStep('give_box')
					end
				end
			end,
		},
		attack_on_the_customer = {
			construct = function(eQuest)
				if SERVER then return end
				eQuest:Notify(lang['attack_on_the_customer_title'], lang['attack_on_the_customer_description'])
			end,
			triggers = {
				spawn_npc_trigger_after_exit_tirgger = {
					onEnter = function(eQuest, ent)
						eQuest:QuestFunction('f_spawn_enemy_npcs', eQuest, ent)
					end
				},
			},
		},
		safe_customer = {
			structures = {
				barricades = true
			},
			points = {
				enemy = function(eQuest, positions)
					if CLIENT then return end

					for _, pos in pairs(positions) do
						eQuest:SpawnQuestNPC('npc_combine_s', {
							pos = pos,
							weapon_class = 'weapon_ar2',
							type = 'enemy'
						})
					end
				end,
			},
			onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
				eQuest:QuestFunction('f_loss_conditions', eQuest)
			end,
		},
		give_box = {
			construct = function(eQuest)
				if SERVER then return end
				eQuest:Notify(lang['give_box_title'], lang['give_box_description'])
			end,
			onUse = function(eQuest, ent)
				if CLIENT then return end
				local npc = eQuest:GetQuestNpc('friend', 'customer')

				if IsValid(ent) and ent == npc then
					eQuest:NextStep('complete')
				end
			end,
			onQuestNPCKilled = function(eQuest)
				eQuest:QuestFunction('f_loss_conditions', eQuest)
			end,
		},
		complete = {
			construct = function(eQuest)
				if CLIENT then
					eQuest:Notify(lang['complete_title'], lang['complete_description'])
					return
				end

				if eQuest:GetVariable('is_customer_attack') then
					eQuest:Reward(nil, 500)
				else
					eQuest:Reward()
				end

				eQuest:Complete()
				eQuest:DisableArrowVector()
			end,
		},
		failed = {
			construct = function(eQuest)
				if CLIENT then
					eQuest:Notify(lang['failed_title'], lang['failed_description'])
					return
				end

				eQuest:Failed()
				eQuest:DisableArrowVector()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)