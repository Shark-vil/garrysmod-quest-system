QuestService = QuestService or {}
QuestService.npcs_random_walk = QuestService.npcs_random_walk or {}

if SERVER then
    timer.Create('QSystem.QuestService.NpcRandomWalk', 1, 0, function()
        local npcs = QuestService.npcs_random_walk
        for _, npc in pairs(npcs) do
            local cooldown = npc.npc_cooldown_random_walk or 0
            local npc_wait_walk = npc.npc_wait_walk or false

            if not npc_wait_walk and cooldown < CurTime() and IsValid(npc) then
                local pos = npc:GetPos()
                local min = pos - Vector(math.random(0, 1000), math.random(0, 1000), math.random(0, 1000))
                local max = pos + Vector(math.random(0, 1000), math.random(0, 1000), math.random(0, 1000))
                
                npc:SetSaveValue("m_vecLastPosition", VectorRand(min, max))
                npc:SetSchedule(SCHED_FORCED_GO)
                npc.npc_cooldown_random_walk = CurTime() + math.random(5, 10)
            end
        end
    end)

    timer.Create('QSystem.QuestService.NpcWaitWalk', 0.5, 0, function()
        for _, eDialogue in pairs(ents.FindByClass('quest_dialogue')) do
            local npc = eDialogue:GetNPC()
            if IsValid(npc) and npc:IsNPC() then
                local npc_wait_walk = npc.npc_wait_walk
                
                if npc_wait_walk ~= nil and npc_wait_walk then
                    local ply = eDialogue:GetPlayer()
                    if npc.npc_wait_walk_move_target then
                        npc:SetSaveValue("m_vecLastPosition", ply:GetPos())
                        npc:SetSchedule(SCHED_FORCED_GO)
                        npc.npc_wait_walk_move_target = false
                    else
                        npc:SetEyeTarget(ply:EyePos())
                        npc:StopMoving()
                        npc:SetMovementActivity(ACT_IDLE)
                    end
                end
            end
        end
    end)
    
    function QuestService:StartNPCRandomWalk(npc)
        if IsValid(npc) and npc:IsNPC() then
            if not table.HasValue(self.npcs_random_walk, npc) then
                table.insert(self.npcs_random_walk, npc)
            end
        end
    end

    function QuestService:StopNPCRandomWalk(npc)
        if IsValid(npc) and npc:IsNPC() then
            if table.HasValue(self.npcs_random_walk, npc) then
                table.RemoveByValue(self.npcs_random_walk, npc)
            end
        end
    end

    function QuestService:WaitingNPCWalk(npc, state)
        if IsValid(npc) and npc:IsNPC() then
            npc.npc_wait_walk = state
            npc.npc_wait_walk_move_target = state
        end
    end
end