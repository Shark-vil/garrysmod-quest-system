AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SetQuest(quest_id, ply)
	if ply ~= nil then
		timer.Simple(0.5, function()
			if IsValid(self) then
				self:AddPlayer(ply)
			end
		end)
	end
	self:SetNWString('quest_id', quest_id)
end

function ENT:SetStep(step)
	local delay = 1
	
	self:SetNWBool('StopThink', true)
	self:SetNWFloat('ThinkDelay', RealTime() + 1)

	local quest = self:GetQuest()
	local ply = self:GetPlayer()

	if quest ~= nil and quest.steps[step] ~= nil then
		self:SetNWString('step', step)

		self.triggers = {}
		if quest.steps[step].triggers ~= nil then
			for trigger_name, _ in pairs(quest.steps[step].triggers) do
				local file_path = 'quest_system/triggers/' .. quest.id .. '/' .. game.GetMap() .. '/' .. trigger_name .. '.json'
				if file.Exists(file_path, 'DATA') then
					local trigger = util.JSONToTable(file.Read(file_path, "DATA"))
					table.insert(self.triggers, {
						name = trigger_name,
						trigger = trigger
					})
				end
			end
		end

		local triggers = self.triggers
		timer.Simple(delay, function()
			if IsValid(self) then
				net.Start('cl_qsystem_entity_step_triggers')
				net.WriteEntity(self)
				net.WriteTable(triggers)
				if quest.isEvent then
					net.Broadcast()
				else
					net.Send(ply)
				end
			end
		end)

		self.points = {}
		if quest.steps[step].points ~= nil then
			for point_name, _ in pairs(quest.steps[step].points) do
				local file_path = 'quest_system/points/' .. quest.id .. '/' .. game.GetMap() .. '/' .. point_name .. '.json'
				if file.Exists(file_path, 'DATA') then
					local points = util.JSONToTable(file.Read(file_path, "DATA"))
					table.insert(self.points, {
						name = point_name,
						points = points
					})
				end
			end
		end

		local points = self.points
		timer.Simple(delay, function()
			if IsValid(self) then
				net.Start('cl_qsystem_entity_step_points')
				net.WriteEntity(self)
				net.WriteTable(points)
				if quest.isEvent then
					net.Broadcast()
				else
					net.Send(ply)
				end
			end
		end)
	end

	if step == 'start' then
		if quest.isEvent then
			quest.title = '[Событие] ' .. quest.title
		end

		if quest.timeToNextStep ~= nil and quest.nextStep ~= nil then
			quest.description = quest.description .. '\nДо начала: ' .. quest.timeToNextStep .. ' сек.'
		end

		if quest.timeQuest ~= nil then
			quest.description = quest.description .. '\nВремя выполнения: ' .. quest.timeQuest .. ' сек.'
		end
	end

	self:OnNextStep(step)

	local start_result = nil
	if quest.steps[step].construct ~= nil then
		start_result = quest.steps[step].construct(self)
	end

	timer.Simple(delay, function()
		if IsValid(self) then
			net.Start('cl_qsystem_entity_step_construct')
			net.WriteEntity(self)
			net.WriteString(self:GetQuestId())
			net.WriteString(step)
			if step == 'start' then
				net.WriteString(utf8.force(quest.title))
				net.WriteString(utf8.force(quest.description))
			end
			if quest.isEvent then
				net.Broadcast()
			else
				net.Send(ply)
			end
		end
	end)

	timer.Simple(delay, function()
		if IsValid(self) then
			net.Start('cl_qsystem_entity_step_done')
			net.WriteEntity(self)
			net.WriteString(step)
			if quest.isEvent then
				net.Broadcast()
			else
				net.Send(ply)
			end
		end
	end)

	if step == 'start' then
		if quest.timeToNextStep ~= nil and quest.nextStep ~= nil then
			timer.Simple(quest.timeToNextStep, function()
				if IsValid(self) then
					if quest.nextStepCheck ~= nil then
						if quest.nextStepCheck(self) then
							self:NextStep(quest.nextStep)
						else
							self:Failed()
						end
					end
				end
			end)
		end

		if quest.timeQuest ~= nil then
			local time = quest.timeQuest

			if quest.timeToNextStep ~= nil then
				time = time + quest.timeToNextStep
			end

			timer.Simple(time, function()
				if IsValid(self) then
					local failedText = quest.failedText or {
						title = 'Quest failed',
						text = 'The execution time has expired.'
					}

					self:NotifyOnlyRegistred(failedText.title, failedText.text)
					self:Failed()
				end
			end)
		end
	end

	return start_result
end

function ENT:NextStep(step)
	local quest = self:GetQuest()
	if quest.isEvent then
		self:SetStep(step)
	else
		local ply = self:GetPlayer()
		if IsValid(ply) then
			ply:SetQuestStep(self:GetQuestId(), step)
		end
	end
end

--[[
	Darkrp mode only. Gives the player a reward and notifies him about it.
--]]
function ENT:Reward(customPayment)
	if engine.ActiveGamemode() ~= 'darkrp' then return end

	local players = self:GetAllPlayers()
	for _, ply in pairs(players) do
		if ply.addMoney ~= nil then
			local payment = customPayment or self:GetQuest().payment
			if payment ~= nil then
				ply:addMoney(payment)
				DarkRP.notify(ply, 4, 4, 'Ваша награда за выполнение квеста - ' 
					.. DarkRP.formatMoney(payment))
			end
		end
	end
end

function ENT:Reparation(customPayment)
	if self:GetQuest().payment ~= nil then
		self:Reward(self:GetQuest().payment / 2)
	end
end

function ENT:IsQuestWeapon(getWep)
	for key, data in pairs(self.weapons) do
		if IsValid(getWep) and data.weapon_class == getWep:GetClass() then
			return true
		end
	end
	return false
end

function ENT:GiveQuestWeapon(weapon_class)
	local ply = self:GetPlayer()
	local data = {
		weapon_class = weapon_class,
		weapon = NULL
	}
	local wep

	if not ply:HasWeapon(weapon_class) then
		wep = ply:Give(weapon_class)
		data.weapon = wep
	else
		wep = ply:GetWeapon(weapon_class)
	end

	table.insert(self.weapons, data)

	return wep
end

function ENT:RemoveQuestWeapon(weapon_class)
	local ply = self:GetPlayer()
	local plyWep = ply:GetWeapon(weapon_class)
	for key, data in pairs(self.weapons) do
		if data.weapon_class == weapon_class then
			if IsValid(data.weapon) and IsValid(plyWep) and plyWep == data.weapon then
				ply:StripWeapon(weapon_class)
			end
			table.remove(self.weapons, key)
		end
	end
end

function ENT:RemoveAllQuestWeapon()
	local ply = self:GetPlayer()
	for key, data in pairs(self.weapons) do
		if IsValid(data.weapon) then
			local plyWep = ply:GetWeapon(data.weapon_class)
			if IsValid(plyWep) then
				ply:StripWeapon(data.weapon_class)
			end
		end
	end
	self.weapons = {}
end

function ENT:Complete()
	if self:GetQuest().isEvent then
		if SERVER then self:Remove() end
		return
	end

	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/NovaProspekt/al_done01.wav')]])
end

function ENT:Failed()
	if self:GetQuest().isEvent then
		if SERVER then self:Remove() end
		return
	end

	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/k_lab/ba_getoutofsight01.wav')]])
end

function ENT:MoveEnemyToRandomPlayer()
	local players = self:GetAllPlayers()

	if #players ~= 0 then
		local ply = table.Random(players)

		if IsValid(ply) then
			local player_pos = ply:GetPos()

			for _, data in pairs(self.npcs) do
				if IsValid(data.npc) then
					data.npc:SetSaveValue("m_vecLastPosition", player_pos)
					data.npc:SetSchedule(SCHED_FORCED_GO)
				end
			end
		end
	end
end