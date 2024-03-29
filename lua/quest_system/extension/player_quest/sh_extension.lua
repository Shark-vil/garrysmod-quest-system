local meta = FindMetaTable('Player')

function meta:PlayerId()
	return self:SteamID64() or 'localhost'
end

function meta:QuestIsActive(quest_id)
	local eQuests = ents.FindByClass('quest_entity')

	if #eQuests ~= 0 then
		for _, eQuest in pairs(eQuests) do
			local ply = eQuest:GetPlayer()
			if ply == self and eQuest:GetQuestId() == quest_id then return true end
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
			if ply == self and quest ~= nil and quest.id == quest_id then return quest_entity end
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

local notifyHistory = {}

hook.Add('Think', 'QuestNotifyAnimationPosition', function()
	for i = #notifyHistory, 1, -1 do
		local data = notifyHistory[i]

		if data == nil or data.deltime < RealTime() then
			table.remove(notifyHistory, i)
		end
	end

	if #notifyHistory ~= 0 then
		local new_y = 15

		for i = 1, #notifyHistory do
			local data = notifyHistory[i]

			if data ~= nil then
				data.panel:SetPos(15, new_y)
				new_y = new_y + 160
			end
		end
	end
end)

function meta:QuestStartNotify(quest_id, lifetime, image, bgcolor)
	bgcolor = bgcolor or Color(64, 64, 64)
	image = image or 'entities/npc_kleiner.png'
	lifetime = lifetime or 5
	lifetime = lifetime + #notifyHistory

	if SERVER then
		net.Start('cl_qsystem_player_notify_quest_start')
		net.WriteString(quest_id)
		net.WriteFloat(lifetime)
		net.WriteString(image)
		net.WriteColor(bgcolor)
		net.Send(self)
	else
		local quest = QuestSystem:GetQuest(quest_id)
		if not quest then return end

		local title = quest.title or ''
		local description = quest.description or ''

		self:QuestNotify(title, description, lifetime, image, bgcolor)
	end
end

function meta:QuestNotify(title, desc, lifetime, image, bgcolor)
	title = title or ''
	desc = desc or ''
	bgcolor = bgcolor or Color(64, 64, 64)
	image = image or 'entities/npc_kleiner.png'
	lifetime = lifetime or 5
	lifetime = lifetime + #notifyHistory

	if SERVER then
		net.Start('cl_qsystem_player_notify')
		net.WriteString(title)
		net.WriteString(desc)
		net.WriteFloat(lifetime)
		net.WriteString(image)
		net.WriteColor(bgcolor)
		net.Send(self)
	else
		local NotifyPanel = vgui.Create('DNotify')
		NotifyPanel:SetPos(15, 15)
		NotifyPanel:SetSize(400, 150)
		NotifyPanel:SetLife(lifetime)
		NotifyPanel:LerpPositions(1, true)

		table.insert(notifyHistory, {
			panel = NotifyPanel,
			deltime = RealTime() + lifetime
		})

		local bg = vgui.Create('DPanel', NotifyPanel)
		bg:Dock(FILL)
		bg:SetBackgroundColor(bgcolor)

		local img = vgui.Create('DImage', bg)
		img:SetPos(10, 10)
		img:SetSize(130, 130)
		img:SetImage(image)

		local dtitle = vgui.Create('DLabel', bg)
		dtitle:SetPos(150, 10)
		dtitle:SetWidth(250)
		dtitle:SetText(title)
		dtitle:SetTextColor(Color(255, 200, 0))
		dtitle:SetFont('GModNotify')
		dtitle:SetWrap(true)

		local ddesc = vgui.Create('DLabel', bg)
		ddesc:SetPos(150, 40)
		ddesc:SetWidth(250)
		ddesc:SetHeight(100)
		ddesc:SetText(desc)
		ddesc:SetTextColor(Color(255, 200, 0))
		ddesc:SetFont('QSystemNotifyFont')
		ddesc:SetWrap(true)
		NotifyPanel:AddItem(bg)
	end
end

scommand.Create('qsystem_players_reset_all_quests_delay').OnServer(function(ply)
	for _, human in pairs(player.GetAll()) do
		local file_path = 'quest_system/players_data/' .. human:PlayerId() .. '/delay.json'

		if file.Exists(file_path, 'DATA') then
			human:SetNWFloat('quest_delay', 0)
			file.Delete(file_path)
		end
	end
end).Access( { isAdmin = true } ).Register()