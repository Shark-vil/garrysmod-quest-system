local meta = FindMetaTable('Entity')

function meta:FadeRemove(delay, minus)
    if not IsValid(self) then return end

    delay = CurTime() + (delay or 0)
    minus = minus or 1

    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self.Use = function() end
    
    hook.Add('Think', self, function()
        if IsValid(self) then
            if delay < CurTime() then
                local color = self:GetColor()
                if color.a - minus >= 0 then
                    self:SetColor(ColorAlpha(color, color.a - minus))
                else
                    self:Remove()
                end
            end
        end
    end)
end