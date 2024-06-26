--[[
Title: ItemAgentSign
Author(s): LiXizhi
Date: 2021/2/17
Desc: Agent sign block is a signature block for describing all scene blocks connected to it. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemAgentSign.lua");
local ItemAgentSign = commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentSign");
local item = ItemAgentSign:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemAgentSign = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentSign"));

block_types.RegisterItemClass("ItemAgentSign", ItemAgentSign);

function ItemAgentSign:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		local itemStack = ItemStack:new():Init(self.id, 1);
		local agentName = entity:GetAgentName()
		if(agentName) then
			agentName = ""
		end
		-- since agent name is unique, we will set empty name for cloned item 
		itemStack:SetDataField("agentPackageName", nil);
		itemStack:SetDataField("agentPackageVersion", entity:GetVersion());
		itemStack:SetDataField("agentDependencies", entity:GetAgentDependencies());
		itemStack:SetDataField("agentExternalFiles", entity:GetAgentExternalFiles());
		itemStack:SetDataField("updateMethod", entity:GetUpdateMethod());
		--itemStack:SetDataField("agentUrl", entity:GetAgentUrl());
		itemStack:SetDataField("isGlobal", entity:IsGlobal());
		itemStack:SetDataField("isPhantom", entity:IsPhantom());
		return itemStack;
	end
	return ItemAgentSign._super.PickItemFromPosition(self, x,y,z);
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemAgentSign:CompareItems(left, right)
	if(ItemAgentSign._super.CompareItems(self, left, right)) then
		if(left and right and left:GetDataField("agentPackageName") == right:GetDataField("agentPackageName")) then
			return true;
		end
	end
end


function ItemAgentSign:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local text = itemStack:GetDataField("tooltip");

	local res = ItemAgentSign._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
	if(res) then
		local entity = self:GetBlock():GetBlockEntity(x,y,z);
		if(entity and entity:GetBlockId() == self.id) then
			entity.cmd = text;
			entity:SetAgentName(itemStack:GetDataField("agentPackageName"))
			entity:SetVersion(itemStack:GetDataField("agentPackageVersion"))
			entity:SetAgentDependencies(itemStack:GetDataField("agentDependencies"))
			entity:SetAgentExternalFiles(itemStack:GetDataField("agentExternalFiles"))
			entity:SetUpdateMethod(itemStack:GetDataField("updateMethod"))
			entity:SetAgentUrl(itemStack:GetDataField("agentUrl"))
			entity:SetGlobal(itemStack:GetDataField("isGlobal"))
			entity:SetPhantom(itemStack:GetDataField("isPhantom"))
			entity:Refresh();
			entity:CheckDuplicates(0);
			commonlib.TimerManager.SetTimeout(function()  
				local filename = entity:GetExistingAgentFilename()
				if(filename) then
					entity:LoadFromAgentFile(filename);
				else
					entity:UpdateFromRemoteSource(nil);
				end
			end, 10)
		end
	end
	return res;
end
