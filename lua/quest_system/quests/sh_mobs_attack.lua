local quest = {
	id = 'mobs_attack',
	title = 'Волны мобов',
	description = 'Вам нужно продержаться три волны, отбиваясь от толпы зомби. Ваше передвижение ограничено зоной квеста.',
	condition = function(ply)
		for _, eQuest in ipairs(ents.FindByClass('quest_entity')) do
			if eQuest:GetQuest().id == 'mobs_attack' then
				ply:QuestNotify('Отказ', 'Этот квест нельзя взять нескольким игрокам одновременно.')
				return false
			end
		end

		return true
	end,
	global_hooks = {
		PlayerDeath = function(eQuest, ply)
			eQuest:QuestFunction('f_left_zone', eQuest, ply)
		end
	},
	functions = {
		f_left_zone = function(eQuest, ent)
			if CLIENT then return end

			if ent == eQuest:GetPlayer() then
				eQuest:NextStep('failed')
			end
		end,
		f_spawn_zombie = function(eQuest, pos)
			if CLIENT then return end
			local mob_list = {}
			local rnd = math.random(0, 11)

			if rnd >= 0 and rnd <= 5 then
				table.insert(mob_list, 'npc_fastzombie')
			elseif rnd > 5 and rnd <= 9 then
				table.insert(mob_list, 'npc_fastzombie')
			elseif rnd > 9 then
				table.insert(mob_list, 'npc_poisonzombie')
			end

			if math.random(0, 10) == 0 then
				table.insert(mob_list, 'npc_antlionguard')
			end

			if math.random(0, 5) == 0 then
				table.insert(mob_list, 'npc_antlion')
			end

			local npc = eQuest:SpawnQuestNPC(table.Random(mob_list), {
				pos = pos,
				type = 'enemy',
				notViewSpawn = true,
				notSpawnDistance = 600
			})

			npc.lastAttackTime = CurTime() + 15
			eQuest:MoveQuestNpcToPosition(eQuest:GetPlayer():GetPos(), 'enemy', nil, 'run')
		end,
		f_spawn_zombie_points = function(eQuest, positions, max_spawn, max_mobs)
			if CLIENT then return end
			eQuest:SetVariable('mob_spawn_positions', positions)

			if max_spawn > max_mobs then
				max_spawn = max_spawn
			end

			eQuest:SetVariable('mob_killed', 0)
			eQuest:SetVariable('max_spawn', max_spawn)
			eQuest:SetVariable('max_mobs', max_mobs)

			for i = 1, max_spawn do
				eQuest:QuestFunction('f_spawn_zombie', eQuest, table.Random(positions))
			end
		end,
		f_next_step = function(eQuest, data, next_step_id)
			if CLIENT then return end
			if data.type ~= 'enemy' then return end
			local positions = eQuest:GetVariable('mob_spawn_positions')
			local mob_killed = eQuest:GetVariable('mob_killed')
			local max_mobs = eQuest:GetVariable('max_mobs')
			local max_spawn = eQuest:GetVariable('max_spawn')

			if mob_killed + 1 == max_mobs then
				eQuest:NextStep(next_step_id)
			else
				if max_mobs - mob_killed > max_spawn then
					eQuest:QuestFunction('f_spawn_zombie', eQuest, table.Random(positions))
				end
			end

			eQuest:SetVariable('mob_killed', mob_killed + 1)
		end,
		f_move_player_to_old_position = function(eQuest)
			if CLIENT then return end
			local ply = eQuest:GetPlayer()

			if ply:Alive() then
				local pos = eQuest:GetVariable('player_old_pos')
				local health = eQuest:GetVariable('player_old_health')
				local armor = eQuest:GetVariable('player_old_armor')
				ply:SetPos(pos)
				ply:SetHealth(health)
				ply:SetArmor(armor)
			end
		end,
		f_respawn_npc_if_bad_attack = function(eQuest)
			if CLIENT then return end

			for _, data in pairs(eQuest.npcs) do
				if IsValid(data.npc) and data.npc.lastAttackTime < CurTime() then
					local new_pos = eQuest:GetVariable('mob_spawn_positions')

					if new_pos ~= nil then
						new_pos = table.Random(new_pos)
						local ply = eQuest:GetPlayer()
						if QuestService:PlayerIsViewVector(ply, new_pos) or QuestService:PlayerIsViewVector(ply, data.npc:GetPos()) or ply:GetPos():Distance(data.npc:GetPos()) < 800 then return end
					end

					data.npc:SetPos(new_pos)
					data.npc.lastAttackTime = CurTime() + 15
					eQuest:MoveQuestNpcToPosition(eQuest:GetPlayer():GetPos(), 'enemy', nil, 'run')
				end
			end
		end,
		f_take_damage_reset_last_attack = function(eQuest, target, dmginfo)
			if eQuest:IsQuestPlayer(target) then
				local attacker = dmginfo:GetAttacker()

				if attacker:IsNPC() then
					attacker.lastAttackTime = CurTime() + 15
				end
			end
		end
	},
	steps = {
		start = {
			structures = {
				barricades = true
			},
			construct = function(eQuest)
				if CLIENT then
					eQuest:GetPlayer():ConCommand('r_cleardecals')
					return
				end

				eQuest:TimerCreate(function()
					eQuest:NextStep('spawn_mobs_wave_1')
				end, 20)

				local weapons = {'weapon_357', 'weapon_pistol', 'weapon_crossbow', 'weapon_crowbar', 'weapon_frag', 'weapon_ar2', 'weapon_rpg', 'weapon_slam', 'weapon_shotgun', 'weapon_smg1',}

				for _, class in pairs(weapons) do
					eQuest:GiveQuestWeapon(class)
				end
			end,
			points = {
				player_spawner = function(eQuest, positions)
					if CLIENT then return end
					local ply = eQuest:GetPlayer()
					eQuest:SetVariable('player_old_pos', ply:GetPos())
					eQuest:SetVariable('player_old_health', ply:Health())
					eQuest:SetVariable('player_old_armor', ply:Armor())
					ply:SetPos(table.Random(positions))
					ply:SetHealth(100)
					ply:SetArmor(100)
				end,
				ammo_spawner_global = function(eQuest, positions)
					if CLIENT then return end

					local s_ammo = {'item_ammo_357', 'item_ammo_357_large', 'item_ammo_ar2', 'item_ammo_ar2_large', 'item_ammo_ar2_altfire', 'item_ammo_crossbow', 'item_ammo_pistol', 'item_ammo_pistol_large', 'item_rpg_round', 'item_box_buckshot', 'item_ammo_smg1', 'item_ammo_smg1_large', 'item_ammo_smg1_grenade', 'npc_grenade_frag'}

					for i = 1, #positions do
						if math.random(0, 100) > 40 then
							eQuest:SpawnQuestItem(table.Random(s_ammo), {
								id = 'ammo_' .. i,
								pos = positions[i],
							})
						end
					end
				end
			},
			triggers = {
				quest_zone_global = {
					onExit = function(eQuest, ent)
						eQuest:QuestFunction('f_left_zone', eQuest, ent)
					end
				},
			}
		},
		spawn_mobs_wave_1 = {
			construct = function(eQuest)
				if CLIENT then return end

				for _, data in pairs(eQuest.items) do
					if IsValid(data.item) then
						data.item:Remove()
					end
				end

				eQuest:Notify('Начало первой волны!', 'Не помри там.')
			end,
			points = {
				mob_spawners_1 = function(eQuest, positions)
					eQuest:QuestFunction('f_spawn_zombie_points', eQuest, positions, 10, 10)
				end,
			},
			onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
				eQuest:QuestFunction('f_next_step', eQuest, data, 'delay_spawn_mobs_wave_2')
			end,
			think = function(eQuest)
				eQuest:QuestFunction('f_respawn_npc_if_bad_attack', eQuest)
			end,
			hooks = {
				EntityTakeDamage = function(eQuest, target, dmginfo)
					eQuest:QuestFunction('f_take_damage_reset_last_attack', eQuest, target, dmginfo)
				end,
			}
		},
		delay_spawn_mobs_wave_2 = {
			construct = function(eQuest)
				if SERVER then
					eQuest:TimerCreate(function()
						eQuest:NextStep('spawn_mobs_wave_2')
					end, 20)
				else
					eQuest:GetPlayer():ConCommand('r_cleardecals')
					eQuest:Notify('Передышка', 'Новая волна через 20 секунд...')
				end
			end,
			points = {
				ammo_spawner_global = true,
				helpers_spawner = function(eQuest, positions)
					if CLIENT then return end

					local s_helpers = {'item_healthkit', 'item_healthvial', 'item_battery',}

					for i = 1, #positions do
						if math.random(0, 100) > 70 then
							eQuest:SpawnQuestItem(table.Random(s_helpers), {
								id = 'helper_' .. i,
								pos = positions[i],
							})
						end
					end
				end,
			}
		},
		spawn_mobs_wave_2 = {
			construct = function(eQuest)
				if CLIENT then return end

				for _, data in pairs(eQuest.items) do
					if IsValid(data.item) then
						data.item:Remove()
					end
				end

				eQuest:Notify('Начало второй волны!', 'Держись, их стало больше...')
			end,
			points = {
				mob_spawners_1 = function(eQuest, positions)
					eQuest:QuestFunction('f_spawn_zombie_points', eQuest, positions, 15, 40)
				end,
			},
			onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
				eQuest:QuestFunction('f_next_step', eQuest, data, 'delay_spawn_mobs_wave_3')
			end,
			think = function(eQuest)
				eQuest:QuestFunction('f_respawn_npc_if_bad_attack', eQuest)
			end,
			hooks = {
				EntityTakeDamage = function(eQuest, target, dmginfo)
					eQuest:QuestFunction('f_take_damage_reset_last_attack', eQuest, target, dmginfo)
				end,
			}
		},
		delay_spawn_mobs_wave_3 = {
			construct = function(eQuest)
				if SERVER then
					eQuest:TimerCreate(function()
						eQuest:NextStep('spawn_mobs_wave_3')
					end, 20)
				else
					eQuest:GetPlayer():ConCommand('r_cleardecals')
					eQuest:Notify('Передышка', 'Новая волна через 20 секунд...')
				end
			end,
			points = {
				ammo_spawner_global = true
			}
		},
		spawn_mobs_wave_3 = {
			construct = function(eQuest)
				if CLIENT then return end

				for _, data in pairs(eQuest.items) do
					if IsValid(data.item) then
						data.item:Remove()
					end
				end

				eQuest:Notify('Начало третьей волны!', 'Ещё немного!')
			end,
			points = {
				mob_spawners_1 = function(eQuest, positions)
					eQuest:QuestFunction('f_spawn_zombie_points', eQuest, positions, 20, 50)
				end,
			},
			onQuestNPCKilled = function(eQuest, data, npc, attacker, inflictor)
				eQuest:QuestFunction('f_next_step', eQuest, data, 'complete')
			end,
			think = function(eQuest)
				eQuest:QuestFunction('f_respawn_npc_if_bad_attack', eQuest)
			end,
			hooks = {
				EntityTakeDamage = function(eQuest, target, dmginfo)
					eQuest:QuestFunction('f_take_damage_reset_last_attack', eQuest, target, dmginfo)
				end,
			}
		},
		complete = {
			construct = function(eQuest)
				if CLIENT then
					eQuest:GetPlayer():ConCommand('r_cleardecals')
					return
				end

				eQuest:QuestFunction('f_move_player_to_old_position', eQuest)
				eQuest:Notify('Завершено', 'Вы продержались все волны, так держать!')
				eQuest:Reward()
				eQuest:Complete()
			end,
		},
		failed = {
			construct = function(eQuest)
				if CLIENT then
					eQuest:GetPlayer():ConCommand('r_cleardecals')
					return
				end

				eQuest:QuestFunction('f_move_player_to_old_position', eQuest)
				eQuest:Notify('Провалено', 'Вы вышли за пределы игровой зоны.')
				eQuest:Failed()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)