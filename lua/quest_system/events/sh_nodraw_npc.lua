if SERVER then
    util.AddNetworkString('cl_qsystem_nodraw_npc')
else
    net.Receive('cl_qsystem_nodraw_npc', function()
        if not QuestSystem:GetConfig('NoDrawNPC_WhenCompletingQuest') then return end

        local classes = net.ReadTable()
        local ply = net.ReadEntity()
    
        for _, class in pairs(classes) do
            local npcs = ents.FindByClass(class)
            for _, npc in pairs(npcs) do
                if IsValid(npc) and IsValid(npc:GetNWEntity('quester')) then
                    if npc:GetNWEntity('quester') == LocalPlayer() then
                        npc:SetNoDraw(true)
                        local wep = npc:GetActiveWeapon()
                        if IsValid(wep) then
                            wep:SetNoDraw(true)
                        end
                    end
                end
            end
        end
    end)
end