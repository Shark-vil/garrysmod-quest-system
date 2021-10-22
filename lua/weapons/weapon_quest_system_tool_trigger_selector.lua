AddCSLuaFile()

SWEP.PrintName = "Trigger creator"
SWEP.Author = "Shark_vil"
SWEP.Purpose = "Create trigger for selected event."
SWEP.Category = 'Quest System Tools'

SWEP.AdminOnly = true

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = false

SWEP.ViewModel = Model( "models/weapons/c_toolgun.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_toolgun.mdl" )
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false

SWEP.Distance = 1000

SWEP.TriggerType = {
	[1] = {
		type = 'box',
		vec1 = nil,
		vec2 = nil,
	},
	[2] = {
		type = 'sphere',
		center = nil,
		radius = nil,
	},
}

SWEP.CurrentTriggerIndex = 1
SWEP.CurrentTrigger = SWEP.TriggerType[SWEP.CurrentTriggerIndex]

function SWEP:Initialize()
	if SERVER then return end

	hook.Add('PostDrawOpaqueRenderables', self, function()
		local current_trigger = self.CurrentTrigger

		if current_trigger.type == 'box' then
			local vec1 = current_trigger.vec1
			local vec2 = current_trigger.vec2

			render.SetColorMaterial()

			if vec1 ~= nil then
				render.DrawSphere( vec1, 10, 30, 30, Color( 58, 23, 255, 100 ) )	
			end

			if vec2 ~= nil then
				render.DrawSphere( vec2, 10, 30, 30, Color( 255, 23, 23, 100 ) )	
			end

			if vec1 ~= nil and vec2 ~= nil then
				local center = (vec1 + vec2) / 2
				render.SetMaterial(Material("color"))
				render.DrawWireframeBox(center, 
					Angle(0, 0, 0), 
					center - vec1, 
					center - vec2, 
					Color(255, 255, 255)
				)

				render.DrawBox(center, 
					Angle(0, 0, 0), 
					center - vec1, 
					center - vec2, 
					Color(135, 135, 135, 100)
				)
			end
		elseif current_trigger.type == 'sphere' then
			local center = current_trigger.center
			local radius = current_trigger.radius

			render.SetColorMaterial()

			if center ~= nil then
				render.DrawSphere( center, 10, 30, 30, Color( 58, 23, 255, 100 ) )	
			end

			if center ~= nil and radius ~= nil then
				render.SetMaterial(Material("color"))
				render.DrawWireframeSphere(center, radius, 30, 30, Color(255, 255, 255, 100))
				render.DrawSphere(center, radius, 30, 30, Color(135, 135, 135, 100))
			end
		end
	end)
end

function SWEP:SetTriggerPosition(value)
	local current_trigger = self.CurrentTrigger
	
	if current_trigger.type == 'box' then
		if current_trigger.vec1 == nil then
			current_trigger.vec1 = value
		else
			current_trigger.vec2 = value
		end
	elseif current_trigger.type == 'sphere' then
		if current_trigger.center == nil then
			current_trigger.center = value
		else
			current_trigger.radius = value:Distance(current_trigger.center)
		end
	end

	self.CurrentTrigger = current_trigger
end


function SWEP:ClearTriggerPosition()
	local current_trigger = self.CurrentTrigger
	
	if current_trigger.type == 'box' then
		current_trigger.vec1 = nil
		current_trigger.vec2 = nil
	elseif current_trigger.type == 'sphere' then
		current_trigger.center = nil
		current_trigger.radius = nil
	end

	self.CurrentTrigger = current_trigger

	surface.PlaySound('common/wpn_denyselect.wav')
end

function SWEP:GetPlayerOwner()
	local owner = nil
	if self.Owner:IsPlayer() then owner = self.Owner end
	return owner
end

function SWEP:IsReloadDelay()
	self.ReloadDelay = self.ReloadDelay or 0
	if self.ReloadDelay > CurTime() then 
		self.ReloadDelay = CurTime() + 0.3
		return true
	end
	self.ReloadDelay = CurTime() + 0.5
	return false
end

function SWEP:CallOnClient(hookType)
	if game.SinglePlayer() then self:CallOnClient(hookType) end
end

function SWEP:PrimaryAttack()
	if SERVER then self:CallOnClient('PrimaryAttack') return end
	if not IsFirstTimePredicted() then return end

	local owner = self:GetPlayerOwner()
	if owner ~= nil then
		local tr = util.TraceLine( {
			start = owner:GetShootPos(),
			endpos = owner:GetShootPos() + owner:GetAimVector() * self.Distance,
			filter = function(ent)
				if IsValid(ent) and ent:IsPlayer() then 
					return false
				end
				return true
			end
		} )

		local hit_vector = tr.HitPos

		if hit_vector ~= nil then
			self:SetTriggerPosition(hit_vector)
			surface.PlaySound('common/wpn_select.wav')
		end
	end
end

function SWEP:Reload()
	if SERVER then self:CallOnClient('Reload') return end
	if self:IsReloadDelay() then return end

	self:ClearTriggerPosition()

	local triggers = self.TriggerType
	local index = self.CurrentTriggerIndex

	if index + 1 > table.Count(triggers) then
		index = 1
	else
		index = index + 1
	end
	
	self.CurrentTriggerIndex = index
	self.CurrentTrigger = triggers[self.CurrentTriggerIndex]
end

function SWEP:SecondaryAttack()
	if SERVER then self:CallOnClient('SecondaryAttack') return end
	if not IsFirstTimePredicted() then return end

	self:ClearTriggerPosition()
end

function SWEP:OnDrop()
	self:Remove()
end