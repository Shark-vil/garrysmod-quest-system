-- Helper table for specific functions.
QuestService = QuestService or {}
-- List of NPCs that should move to random positions
QuestService.npcs_random_walk = QuestService.npcs_random_walk or {}

if SERVER then
    -------------------------------------
    -- The timer for starting the walk of the NPC to a random position.
    -------------------------------------
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

    -------------------------------------
    -- Timer to temporarily stop the NPC walking and start waiting.
    -------------------------------------
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
                        npc.npc_wait_walk_delay = CurTime() + 1
                    else
                        if npc.npc_wait_walk_delay < CurTime() then
                            npc:SetEyeTarget(ply:EyePos())
                            npc:StopMoving()
                            npc:SetMovementActivity(ACT_IDLE)
                        end
                    end
                end
            end
        end
    end)
    
    -------------------------------------
    -- Adds NPC to the random move table list.
    -------------------------------------
    -- @param npc entity - the entity of the NPC
    -------------------------------------
    function QuestService:StartNPCRandomWalk(npc)
        if IsValid(npc) and npc:IsNPC() then
            if not table.HasValue(self.npcs_random_walk, npc) then
                table.insert(self.npcs_random_walk, npc)
            end
        end
    end

    -------------------------------------
    -- Removes NPC from random move table list.
    -------------------------------------
    -- @param npc entity - the entity of the NPC
    -------------------------------------
    function QuestService:StopNPCRandomWalk(npc)
        if IsValid(npc) and npc:IsNPC() then
            if table.HasValue(self.npcs_random_walk, npc) then
                table.RemoveByValue(self.npcs_random_walk, npc)
            end
        end
    end

    -------------------------------------
    -- Adds an NPC to the move waiting table list.
    -------------------------------------
    -- @param npc entity - the entity of the NPC
    -- @param state bool - pass true if you want to start waiting or false to stop
    -------------------------------------
    function QuestService:WaitingNPCWalk(npc, state)
        if IsValid(npc) and npc:IsNPC() then
            npc.npc_wait_walk = state
            npc.npc_wait_walk_move_target = state
        end
    end
end

function QuestService:PlayerIsViewVector(ply, pos)
    local DirectionAngle = math.pi / 90
    local EntityDifference = pos - ply:EyePos()
    local EntityDifferenceDot = ply:GetAimVector():Dot(EntityDifference) / EntityDifference:Length()
    local IsView = EntityDifferenceDot > DirectionAngle
    if IsView then
        return true
    end
    return false
end