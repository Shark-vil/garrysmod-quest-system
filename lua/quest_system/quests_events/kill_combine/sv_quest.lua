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
         construct = function(eQuest)
            local quest = eQuest:GetQuest()
            eQuest:NotifyAll(quest.title, quest.description, 6)
         end,
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
                  local model = table.Random({
                     'models/Combine_Soldier.mdl',
                     'models/Combine_Soldier_PrisonGuard.mdl',
                     'models/Combine_Super_Soldier.mdl'
                  })

                  local weapon_class = table.Random({
                     'weapon_ar2',
                     'weapon_shotgun',
                  })
                  
                  eQuest:SpawnQuestNPC('npc_combine_s', {
                     type = 'enemy',
                     pos = pos,
                     model = model,
                     weapon_class = weapon_class
                  })
               end

               eQuest:MoveEnemyToRandomPlayer()
            end,
         },
         hooks = {
            OnNPCKilled = function(eQuest, npc, attacker, inflictor)
               local combines = eQuest:GetQuestNpc('enemy')
               for _, npc in pairs(combines) do
                  if IsValid(npc) and npc:Health() > 0 then
                     return
                  end
               end

               eQuest:NextStep('complete')
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