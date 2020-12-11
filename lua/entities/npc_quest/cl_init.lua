include('shared.lua') 

function ENT:Draw()
   self:DrawModel()

   if self:GetPos():Distance(LocalPlayer():GetPos()) < 800 then // only draw when dist < 800 gmod units
		local playerAngle = LocalPlayer():GetAngles()
		local textAngle = Angle(0, playerAngle.y - 180, 0)

		textAngle:RotateAroundAxis(textAngle:Forward(), 90)
		textAngle:RotateAroundAxis(textAngle:Right(), -90)

		cam.Start3D2D(self:GetPos() + self:GetForward() + self:GetUp() * 78, textAngle, 0.25)
         draw.SimpleTextOutlined('Guild representative', "DermaLarge", 0, -15, Color(255, 255, 0), 
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0));
		cam.End3D2D()
	end
end