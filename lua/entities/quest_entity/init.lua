AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SetQuest(quest_id, ply)
	self:SetNWEntity('player', ply)
	self:SetNWString('quest_id', quest_id)
end

function ENT:SetStep(step, delay)
	delay = delay or 0
	self.npcs = {}

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
	end

	timer.Simple(delay, function()
		if IsValid(self) then
			net.Start('cl_qsystem_entity_step_done')
			net.WriteEntity(self)
			net.WriteString(step)
			net.Send(ply)
		end
	end)

	timer.Simple(delay + 0.5, function()
		if quest.steps[step].construct ~= nil then
			quest.steps[step].construct(self)
		end

		self:OnNextStep()
	end)
end

function ENT:NextStep(step)
	local ply = self:GetPlayer()
	if IsValid(ply) then
		ply:SetQuestStep(self:GetQuestId(), step)
	end
end

--[[
	DarkRp Only
]]
function ENT:Reward()
	if engine.ActiveGamemode() ~= 'darkrp' then return end

	local ply = self:GetPlayer()
	if ply.addMoney ~= nil then
		local payment = self:GetQuest().payment
		if payment ~= nil then
			ply:addMoney(payment)
			DarkRP.notify(ply, 4, 4, 'Ваша награда за выполнение квеста - ' .. DarkRP.formatMoney(payment))
		end
	end
end

function ENT:Complete()
	local ply = self:GetPlayer()
	local quest_id = self:GetQuestId()
	ply:DisableQuest(quest_id)
	ply:RemoveQuest(quest_id)
end