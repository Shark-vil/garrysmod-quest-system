include('shared.lua')

local guild_representative_name

function ENT:Draw()
	self:DrawModel()

	if not guild_representative_name then
		guild_representative_name = slib.language({
			['default'] = 'Guild representative',
			['russian'] = 'Представитель гильдии',
		})
	end

	-- Draws text above the head of the NPC
	if self:GetPos():Distance(LocalPlayer():GetPos()) < 800 then
		local angle = LocalPlayer():EyeAngles()
		angle:RotateAroundAxis(angle:Forward(), 90)
		angle:RotateAroundAxis(angle:Right(), 90)
		cam.Start3D2D(self:GetPos() + self:GetForward() + self:GetUp() * 78, angle, 0.25)
		draw.SimpleTextOutlined(guild_representative_name, 'DermaLarge', 0, -15, Color(255, 255, 0),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
		cam.End3D2D()
	end
end