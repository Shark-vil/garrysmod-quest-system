include('shared.lua') 

function ENT:Draw()
   self:DrawModel()
end

net.Receive('qsystem_quest_entity_set_value', function()
   local ent = net.ReadEntity()
   local type = net.ReadUInt(8)
   local key = net.ReadString()
   local data = net.ReadTable(type)
   
   ent.values[key] = data
end)

net.Receive('qsystem_quest_entity_reset_values', function()
   local ent = net.ReadEntity()   
   ent.values = {}
end)