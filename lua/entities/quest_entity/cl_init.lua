include('shared.lua') 
function ENT:Draw()
   self:DrawModel()
end

function ENT:Notify(title, desc, image, bgcolor)
   local NotifyPanel = vgui.Create("DNotify")
   NotifyPanel:SetPos(15, 15)
   NotifyPanel:SetSize(400, 150)

   bgcolor = bgcolor or Color(64, 64, 64)

   local bg = vgui.Create("DPanel", NotifyPanel)
   bg:Dock(FILL)
   bg:SetBackgroundColor(bgcolor)

   image = image or "entities/npc_kleiner.png"

   local img = vgui.Create("DImage", bg)
   img:SetPos(10, 10)
   img:SetSize(130, 130)
   img:SetImage(image)

   local dtitle = vgui.Create("DLabel", bg)
   dtitle:SetPos(150, 10)
   dtitle:SetWidth(250)
   dtitle:SetText(title)
   dtitle:SetTextColor(Color(255, 200, 0))
   dtitle:SetFont("GModNotify")
   dtitle:SetWrap(true)

   local ddesc = vgui.Create("DLabel", bg)
   ddesc:SetPos(150, 40)
   ddesc:SetWidth(250)
   ddesc:SetHeight(100)
   ddesc:SetText(desc)
   ddesc:SetTextColor(Color(255, 200, 0))
   ddesc:SetFont("QSystemNotifyFont")
   ddesc:SetWrap(true)

   NotifyPanel:AddItem(bg)
end