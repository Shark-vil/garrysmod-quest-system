AddCSLuaFile()

SWEP.PrintName = 'Points creator'
SWEP.Author = 'Shark_vil'
SWEP.Purpose = 'Create points for selected event.'
SWEP.Category = 'Quest System Tools'

SWEP.AdminOnly = true

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = false

SWEP.ViewModel = Model( 'models/weapons/c_toolgun.mdl' )
SWEP.WorldModel = Model( 'models/weapons/w_toolgun.mdl' )
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
SWEP.Distance = 1000
SWEP.Points = {}

function SWEP:Initialize()
	if SERVER then return end

	local ply = LocalPlayer()
	local add_upper_vetor = Vector(0, 0, 20)
	local render_DrawSphere = render.DrawSphere
	local render_SetColorMaterial = render.SetColorMaterial
	local cam_Start3D2D = cam.Start3D2D
	local cam_End3D2D = cam.End3D2D
	local point_color = Color(23, 255, 243, 200)
	local text_color = Color(255, 255, 255)
	local text_outline_color = Color(0, 0, 0)
	local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER

	hook.Add('PostDrawOpaqueRenderables', self, function()
		local points_count = #self.Points
		if points_count == 0 then return end

		local QuestService = QuestService
		local angle = ply:EyeAngles()
		angle:RotateAroundAxis(angle:Forward(), 90)
		angle:RotateAroundAxis(angle:Right(), 90)

		render_SetColorMaterial()

		for i = 1, points_count do
			local pos = self.Points[i]

			if QuestService:PlayerIsViewVector(ply, pos) and ply:GetPos():DistToSqr(pos) <= 1000000 then
				render_DrawSphere(pos, 10, 30, 30, point_color)

				cam_Start3D2D(pos + add_upper_vetor, angle, 0.9)
					draw.SimpleTextOutlined(i, 'TargetID', 0, 0, text_color,
						TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, text_outline_color)
				cam_End3D2D()
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

function SWEP:CallOnClient(function_name)
	if CLIENT or not IsFirstTimePredicted() then return end
	self:slibClientRPC(function_name)
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

function SWEP:PrimaryAttack()
	if SERVER then self:CallOnClient('PrimaryAttack') return end

	local owner = self:GetOwner()
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

function SWEP:Reload()
	if SERVER then self:CallOnClient('Reload') return end
	if self:IsReloadDelay() then return end

	self:ClearPoints()
end

function SWEP:SecondaryAttack()
	if SERVER then self:CallOnClient('SecondaryAttack') return end
	self:RemoveLastPoint()
end

function SWEP:OnDrop()
	self:Remove()
end