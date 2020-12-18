local meta = FindMetaTable('Entity')

function meta:FadeRemove(delay, minus)
    if not IsValid(self) then return end

    delay = CurTime() + (delay or 0)
    minus = minus or 1

    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local weapon = NULL
    local IsNPC = self:IsNPC()
    if IsNPC then
        self:SetSchedule(SCHED_IDLE_STAND)
        self:CapabilitiesClear()
        weapon = self:GetActiveWeapon()
        if IsValid(weapon) then
            weapon:SetRenderMode(RENDERMODE_TRANSCOLOR)
        end
    end
    self.Use = function() end

    hook.Add('EntityTakeDamage', self, function(this, ent)
        if IsValid(self) and self == ent then
            return true
        end
    end)

    hook.Add("PhysgunPickup", self, function(this, ply, ent)
        if IsValid(self) and self == ent then
            return false
        end
    end)
    
    hook.Add('Think', self, function()
        if IsValid(self) then
            if IsNPC then
                local target = self:GetTarget()
                if IsValid(target) then
                    self:AddEntityRelationship(target, D_NU, 99)
                end
                local enemy = self:GetEnemy()
                if IsValid(enemy) then
                    self:AddEntityRelationship(enemy, D_NU, 99)
                end
                self:ClearGoal()
                self:ClearSchedule()
            end

            if delay < CurTime() then
                local color = self:GetColor()
                if color.a - minus >= 0 then
                    local newColor = ColorAlpha(color, color.a - minus)
                    self:SetColor(newColor)
                    if IsNPC then
                        local weapon = self:GetActiveWeapon()
                        if IsValid(weapon) then
                            weapon:SetColor(newColor)
                        end
                    end
                else
                    self:Remove()
                end
            end
        end
    end)
end