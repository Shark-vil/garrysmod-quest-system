AddCSLuaFile()

SWEP.PrintName = "Points creator"
SWEP.Author = "Shark_vil"
SWEP.Purpose = "Create points for selected event."
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
SWEP.Points = {}

function SWEP:Initialize()
	if SERVER then return end

    hook.Add('PostDrawOpaqueRenderables', self, function()
		if #self.Points ~= 0 then
			local ply = LocalPlayer()
			render.SetColorMaterial()

			local old_pos, old_color
			for index, pos in pairs(self.Points) do
				local color

				if index % 2 == 0 then
					color = Color(58, 23, 255, 100)
				else
					color = Color(255, 23, 23, 100)
				end
				
				if QuestService:PlayerIsViewVector(ply, pos) and ply:GetPos():Distance(pos) < 1500 then

					if old_pos ~= nil then
						render.DrawLine(old_pos, pos, old_color)
					end

					render.DrawSphere(pos, 10, 30, 30, color)

					local angle = LocalPlayer():EyeAngles()
					angle:RotateAroundAxis(angle:Forward(), 90)
					angle:RotateAroundAxis(angle:Right(), 90)

					cam.Start3D2D(pos + Vector(0, 0, 20), angle, 0.9)
						draw.SimpleTextOutlined(tostring(index), 
							"TargetID", 0, 0, Color(255, 255, 255), 
							TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(0, 0, 0))
					cam.End3D2D()
				end

				old_color = color
				old_pos = pos
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
	
	if CLIENT then
		surface.PlaySound('common/wpn_denyselect.wav')
	end
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
	if SERVER and game.SinglePlayer() then self:CallOnClient('PrimaryAttack') end
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
			if CLIENT then
				surface.PlaySound('common/wpn_select.wav')
			end
		end
	end
end

function SWEP:Reload()
	if SERVER and game.SinglePlayer() then self:CallOnClient('Reload') end
	if self:IsReloadDelay() then return end

	self:ClearPoints()
end

function SWEP:SecondaryAttack()
	if SERVER and game.SinglePlayer() then self:CallOnClient('SecondaryAttack') end
	if not IsFirstTimePredicted() then return end

	self:RemoveLastPoint()
end

function SWEP:OnDrop()
	self:Remove()
end