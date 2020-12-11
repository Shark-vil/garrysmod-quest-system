AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()
    self:SetModel('models/Eli.mdl')
	self:SetSolid(SOLID_BBOX);
	self:PhysicsInit(SOLID_BBOX);
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal();
	self:SetMoveType(MOVETYPE_NONE);
	self:SetNPCState(NPC_STATE_SCRIPT);
	self:CapabilitiesAdd(CAP_ANIMATEDFACE);
	self:CapabilitiesAdd(CAP_TURN_HEAD);
	self:SetUseType(SIMPLE_USE);
	self:SetMaxYawSpeed(90);
	self:DropToFloor();
end

function ENT:Use(activator, caller, useType, value)
    if useType == USE_ON and activator:IsPlayer() then
        activator:ConCommand('qsystem_open_simple_quest_menu')
    end
end