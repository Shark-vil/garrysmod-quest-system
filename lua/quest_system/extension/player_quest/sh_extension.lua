local meta = FindMetaTable('Player')

function meta:PlayerId()
    return self:SteamID64() or 'localhost'
end

function meta:QuestIsActive(quest_id)
    local eQuests = ents.FindByClass('quest_entity')
    if #eQuests ~= 0 then
        for _, eQuest in pairs(eQuests) do
            local ply = eQuest:GetPlayer()
            if ply == self and eQuest:GetQuestId() == quest_id then
                return true
            end
        end
    end
    return false
end

function meta:FindQuestEntity(quest_id)
    local eQuests = ents.FindByClass('quest_entity')
    if #eQuests ~= 0 then
        for _, quest_entity in pairs(eQuests) do
            local quest = quest_entity:GetQuest()
            local ply = quest_entity:GetPlayer()
            
            if ply == self and quest ~= nil and quest.id == quest_id then
                return quest_entity
            end
        end
    end
    return NULL
end

function meta:FindQuestEntities()
    local eQuests = ents.FindByClass('quest_entity')
    if #eQuests ~= 0 then
        local quest_entities = {}
        for _, quest_entity in pairs(eQuests) do
            local quest = quest_entity:GetQuest()
            local ply = quest_entity:GetPlayer()
            
            if ply == self and quest ~= nil then
                table.insert(quest_entities, quest_entity)
            end
        end
        return quest_entities
    end
    return {}
end

function meta:IsQuestEditAccess(isAlive)
    if isAlive and not self:Alive() then return false end

    if self:IsAdmin() or self:IsSuperAdmin() then
        return true
    else
        return false
    end
end

function meta:QSystemIsSpam()
    if self:IsQuestEditAccess() then return false end

    local lastRequest = self.qSystemLastRequest or 0
    if lastRequest < SysTime() then
        self.qSystemLastRequest = SysTime() + 0.1
        return false
    end
    return true
end

function meta:QuestNotify(title, desc, image, bgcolor)
    bgcolor = bgcolor or Color(64, 64, 64)
    image = image or "entities/npc_kleiner.png"

    if SERVER then
        net.Start('cl_qsystem_player_notify')
        net.WriteString(title)
        net.WriteString(desc)
        net.WriteString(image)
        net.WriteColor(bgcolor)
        net.Send(self)
    else
        local NotifyPanel = vgui.Create("DNotify")
        NotifyPanel:SetPos(15, 15)
        NotifyPanel:SetSize(400, 150)
    
        local bg = vgui.Create("DPanel", NotifyPanel)
        bg:Dock(FILL)
        bg:SetBackgroundColor(bgcolor)
    
        local img = vgui.Create("DImage", bg)
        img:SetPos(10, 10)
        img:SetSize(130, 130)
        img:SetImage(image)
    
        local dtitle = vgui.Create("DLabel", bg)
        dtitle:SetPos(150, 10)
        dtitle:SetWidth(250)
        dtitle:SetText(title)
        dtitle:SetTextColor(Color(255, 200, 0))
        dtitle:SetFont("GModNotify")
        dtitle:SetWrap(true)
    
        local ddesc = vgui.Create("DLabel", bg)
        ddesc:SetPos(150, 40)
        ddesc:SetWidth(250)
        ddesc:SetHeight(100)
        ddesc:SetText(desc)
        ddesc:SetTextColor(Color(255, 200, 0))
        ddesc:SetFont("QSystemNotifyFont")
        ddesc:SetWrap(true)
    
        NotifyPanel:AddItem(bg)
    end
end