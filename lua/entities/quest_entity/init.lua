AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SetQuest(quest_id, ply)
	self:SetNWEntity('player', ply)
	self:SetNWString('quest_id', quest_id)
end

function ENT:SetStep(step)
	local delay = 0.5
	
	self:SetNWBool('StopThink', true)
	self:SetNWFloat('ThinkDelay', RealTime() + 1)

	local quest = self:GetQuest()
	local ply = self:GetPlayer()

	if quest ~= nil and quest.steps[step] ~= nil then
		self:SetNWString('step', step)

		timer.Simple(delay, function()
			if IsValid(self) then
				net.Start('cl_qsystem_entity_step_construct')
				net.WriteEntity(self)
				net.WriteString(self:GetQuestId())
				net.WriteString(step)
				net.Send(ply)
			end
		end)

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
				net.Send(ply)
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
				net.Send(ply)
			end
		end)
	end

	if quest.steps[step].construct ~= nil then
		quest.steps[step].construct(self)
	end
	
	self:OnNextStep(step)

	timer.Simple(delay, function()
		if IsValid(self) then
			net.Start('cl_qsystem_entity_step_done')
			net.WriteEntity(self)
			net.WriteString(step)
			net.Send(ply)
		end
	end)
end

function ENT:NextStep(step)
	local ply = self:GetPlayer()
	if IsValid(ply) then
		ply:SetQuestStep(self:GetQuestId(), step)
	end
end

--[[
	Darkrp mode only. Gives the player a reward and notifies him about it.
--]]
function ENT:Reward(customPayment)
	if engine.ActiveGamemode() ~= 'darkrp' then return end

	local ply = self:GetPlayer()
	if ply.addMoney ~= nil then
		local payment = customPayment or self:GetQuest().payment
		if payment ~= nil then
			ply:addMoney(payment)
			DarkRP.notify(ply, 4, 4, 'Ваша награда за выполнение квеста - ' .. DarkRP.formatMoney(payment))
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
	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/NovaProspekt/al_done01.wav')]])
end

function ENT:Failed()
	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
	ply:SendLua([[surface.PlaySound('vo/k_lab/ba_getoutofsight01.wav')]])
end