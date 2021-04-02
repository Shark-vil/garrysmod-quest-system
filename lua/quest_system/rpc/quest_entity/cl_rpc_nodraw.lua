snet.Callback('qsystem_sync_nodraw', function(_, ent)
    if not QuestSystem:GetConfig('HideQuestsOfOtherPlayers') then return end
    if not IsValid(ent) then return end

    -- NPC
    do
        local npcs = ent.npcs
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
    end

    -- Items
    do
        local items = ent.items
        local noDraw = table.HasValue(ent.players, LocalPlayer())

        for _, data in pairs(items) do
            local item = data.item
            if IsValid(item) then
                item:SetNoDraw(not noDraw)
            end
        end
    end

    -- Structures
    do
        local structures = ent.structures
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
    end
end).Validator(SNET_ENTITY_VALIDATOR).Register()