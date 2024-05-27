--[[
Title: Entity Animation Generator
Author(s): LiXizhi
Date: 2018/9/27
Desc: This is the character class generated by EntityAnimModel
It will try to follow the main player but will not leave the source AutoAnim block very far. 
When clicked, it will pop up a save as dialog
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAnimCharacter.lua");
local EntityAnimCharacter = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAnimCharacter")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityAnimCharacter"));

-- class name
Entity.class_name = "EntityAnimCharacter";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = false;


function Entity:ctor()
	self:SetCanRandomMove(false);
	self:SetDummy(false);
end

-- set which anim model entity created this character
function Entity:SetAnimModelEntity(entity)
	self.animModelEntity = entity;
end

function Entity:GetAnimModelEntity()
	return self.animModelEntity;
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	GameLogic.RunCommand(string.format("/avatar %s", self:GetMainAssetPath()));
	GameLogic.RunCommand("/take 0");
	self:GetAnimModelEntity():DeleteOutputCharacter();
	return true;
end

-- this will cause framemove to skip for this amount of time
function Entity:Wait(seconds)
	self.nextTickTime = commonlib.TimerManager.GetCurrentTime() + seconds*1000;
end

function Entity:ShallWait()
	return commonlib.TimerManager.GetCurrentTime() < (self.nextTickTime or 0);
end

-- called every frame
function Entity:FrameMove(deltaTime)
	Entity._super.FrameMove(self, deltaTime);

	if(not self:IsRemote()) then
		-- check respawn
		if(not self:ShallWait()) then
			local x,y,z = self:GetAnimModelEntity():GetBlockPos()
			local distSqToSrcBlock = self:DistanceSqTo(x,y,z);
			if(distSqToSrcBlock > 26*26) then
				self:SetBlockPos(x,y+1,z);
			elseif(distSqToSrcBlock > 16*16) then
				self:SetBlockTarget(x,y,z);
				self:Wait(5);
			else
				local px, py, pz = EntityManager.GetPlayer():GetBlockPos()
				local distSqToPlayer = self:DistanceSqTo(px, py, pz);
				if(distSqToPlayer > 10*10) then
					local x, y, z = self:GetRandomMovePos();
					if(x) then
						self:MoveTo(x,y,z);
					end
					self:Wait(1);
				elseif(distSqToPlayer > 4*4) then
					self:SetBlockTarget(px,py,pz);
					self:Wait(2);
				else
					local x, y, z = self:GetRandomMovePos();
					if(x) then
						self:MoveTo(x,y,z);
					end
					self:Wait(1);
				end
			end
		end
	end
end