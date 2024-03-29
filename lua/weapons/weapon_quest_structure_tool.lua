AddCSLuaFile()
SWEP.PrintName = 'Structure creator'
SWEP.Author = 'Shark_vil'
SWEP.Purpose = 'Create trigger for selected event.'
SWEP.Category = 'Quest System Tools'
SWEP.AdminOnly = true
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.Spawnable = false
SWEP.ViewModel = Model('models/weapons/c_toolgun.mdl')
SWEP.WorldModel = Model('models/weapons/w_toolgun.mdl')
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = 'none'
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = 'none'
SWEP.DrawAmmo = false
SWEP.Distance = 500

SWEP.StructureZone = {
	vec1 = nil,
	vec2 = nil
}

function SWEP:Initialize()
	if SERVER then return end

	hook.Add('PostDrawOpaqueRenderables', self, function()
		local vec1 = self.StructureZone.vec1
		local vec2 = self.StructureZone.vec2
		render.SetColorMaterial()

		if vec1 ~= nil then
			render.DrawSphere(vec1, 10, 30, 30, Color(58, 23, 255, 100))
		end

		if vec2 ~= nil then
			render.DrawSphere(vec2, 10, 30, 30, Color(255, 23, 23, 100))
		end

		if vec1 ~= nil and vec2 ~= nil then
			local center = (vec1 + vec2) / 2
			render.SetMaterial(Material('color'))
			render.DrawWireframeBox(center, Angle(0, 0, 0), center - vec1, center - vec2, Color(255, 255, 255))
			render.DrawBox(center, Angle(0, 0, 0), center - vec1, center - vec2, Color(135, 135, 135, 30))
		end
	end)
end

function SWEP:GetPropsOnZone()
	local vec1 = self.StructureZone.vec1
	local vec2 = self.StructureZone.vec2

	if vec1 ~= nil and vec2 ~= nil then
		local entities = ents.FindInBox(vec1, vec2)
		local props = {}

		for _, ent in pairs(entities) do
			if not ent:IsPlayer() then
				table.insert(props, ent)
			end
		end

		return props
	end

	return {}
end

function SWEP:SetZonePosition(value)
	if self.StructureZone.vec1 == nil then
		self.StructureZone.vec1 = value
	else
		self.StructureZone.vec2 = value
	end
end

function SWEP:ClearZonePositions()
	self.StructureZone.vec1 = nil
	self.StructureZone.vec2 = nil
	surface.PlaySound('common/wpn_denyselect.wav')
end

function SWEP:PrimaryAttack()
	if not self:slibIsSingleCall() then return end
	self:slibPredictedClientRPC('RpcPrimaryAttack')
end

function SWEP:RpcPrimaryAttack()
	local owner = self:GetOwner()
	local tr = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * self.Distance,
		filter = function(ent)
			if IsValid(ent) and ent:IsPlayer() then return false end
			return true
		end
	})

	local hit_vector = tr.HitPos

	if tr.Entity == NULL then
		tr = util.TraceLine({
			start = owner:GetShootPos(),
			endpos = owner:GetShootPos() + owner:GetAimVector() * (self.Distance / 2),
			filter = function(ent)
				if IsValid(ent) and ent:IsPlayer() then return false end
				return true
			end
		})
	end

	if hit_vector ~= nil then
		self:SetZonePosition(hit_vector)
		surface.PlaySound('common/wpn_select.wav')
	end
end

function SWEP:SecondaryAttack()
	if not self:slibIsSingleCall() then return end
	self:slibPredictedClientRPC('RpcSecondaryAttack')
end

function SWEP:RpcSecondaryAttack()
	self:ClearZonePositions()
end

function SWEP:OnDrop()
	self:Remove()
end