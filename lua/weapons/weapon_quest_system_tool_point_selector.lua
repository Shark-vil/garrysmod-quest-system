AddCSLuaFile()

SWEP.PrintName = "Points creator"
SWEP.Author = "Shark_vil"
SWEP.Purpose = "Create points for selected event."
SWEP.Category = 'Quest System Tools'

SWEP.AdminOnly = true

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = true

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
SWEP.Points = {}

function SWEP:Initialize()
	if SERVER then return end

    hook.Add('PostDrawOpaqueRenderables', self, function()
		if #self.Points ~= 0 then
			render.SetColorMaterial()
            for _, pos in pairs(self.Points) do
                render.DrawSphere(pos, 10, 30, 30, Color(58, 23, 255, 100))
            end
        end
	end)
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

function SWEP:AddPointPosition(value)
	table.insert(self.Points, value)
end

function SWEP:RemoveLastPoint()
    local max = #self.Points
    if max - 1 >= 0 then
        table.remove(self.Points, max)
    end
end

function SWEP:ClearPoints()
    table.Empty(self.Points)
	surface.PlaySound('common/wpn_denyselect.wav')
end

function SWEP:GetPlayerOwner()
	local owner = nil
	if self.Owner:IsPlayer() then owner = self.Owner end
	return owner
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
			self:AddPointPosition(hit_vector + Vector(0, 0, 15))
			surface.PlaySound('common/wpn_select.wav')
		end
	end
end

function SWEP:Reload()
	if SERVER then self:CallOnClient('Reload') return end
	if self:IsReloadDelay() then return end

	self:ClearPoints()
end

function SWEP:SecondaryAttack()
	if SERVER then self:CallOnClient('SecondaryAttack') return end
	if not IsFirstTimePredicted() then return end

	self:RemoveLastPoint()
end

function SWEP:OnDrop()
	self:Remove()
end