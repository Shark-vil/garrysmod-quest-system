if SERVER then
    util.AddNetworkString('cl_qsystem_nodraw_npc')
    util.AddNetworkString('cl_qsystem_nodraw_items')
    util.AddNetworkString('cl_qsystem_nodraw_structures')
else
    net.Receive('cl_qsystem_nodraw_npc', function()
        if not QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then return end

        local ent = net.ReadEntity()
        local npcs = ent.npcs
        
        if not IsValid(ent) then return end
        local noDraw = table.HasValue(ent.players, LocalPlayer())

        for _, data in pairs(npcs) do
            local npc = data.npc
            if IsValid(npc) then
                if QuestSystem:GetConfig('HideQuestsNPCNotCompletely') then
                    if not noDraw then
                        npc:SetRenderMode(RENDERMODE_TRANSCOLOR)
                        npc:SetColor(ColorAlpha(npc:GetColor(), 50))
                    end
                else
                    npc:SetNoDraw(not noDraw)
                end
                local wep = npc:GetActiveWeapon()
                if IsValid(wep) then
                    if QuestSystem:GetConfig('HideQuestsNPCNotCompletely') then
                        if not noDraw then
                            wep:SetRenderMode(RENDERMODE_TRANSCOLOR)
                            wep:SetColor(ColorAlpha(wep:GetColor(), 50))
                        end
                    else
                        wep:SetNoDraw(not noDraw)
                    end
                end
            end
        end
    end)

    net.Receive('cl_qsystem_nodraw_items', function()
        if not QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then return end

        local ent = net.ReadEntity()
        local items = ent.items
    
        if not IsValid(ent) then return end
        local noDraw = table.HasValue(ent.players, LocalPlayer())

        for _, data in pairs(items) do
            local item = data.item
            if IsValid(item) then
                item:SetNoDraw(not noDraw)
            end
        end
    end)

    net.Receive('cl_qsystem_nodraw_structures', function()
        if not QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then return end

        local ent = net.ReadEntity()
        local structures = net.ReadTable()
    
        if not IsValid(ent) then return end
        local noDraw = table.HasValue(ent.players, LocalPlayer())

        for id, spawn_id in pairs(structures) do
            local props = QuestSystem:GetStructure(spawn_id)
            if props ~= nil and table.Count(props) ~= 0 then
                for _, ent in pairs(props) do
                    if IsValid(ent) then
                        ent:SetNoDraw(not noDraw)
                    end
                end
            end
        end
    end)
end