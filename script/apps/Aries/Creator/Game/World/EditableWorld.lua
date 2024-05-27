--[[
Title: freeze world
Author(s): WangYanXiang
Date: 2023/07/04
Desc: If freezeworld mode is on, blocks created before the /freezeworld command is frozen and can not be deleted or edited. 
In freeworld mode, only new blocks can be added or deleted. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/EditableWorld.lua")
local EditableWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld")
GameLogic.EditableWorld:Reset()
GameLogic.EditableWorld:FreezeWorld(bEnable)   -- 冷冻世界, /freezeworld  true|false
GameLogic.EditableWorld:Save()
GameLogic.EditableWorld:Load()
GameLogic.EditableWorld:IsEditableBlock(bx, by, bz)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua")
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager")

local EditableWorld = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld"))
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

EditableWorld.isFreezeWorld = false
local addBlocks = {}
function EditableWorld:ctor()
	GameLogic:Connect("WorldLoaded", self, self.OnEnterWorld, "UniqueConnection")
	GameLogic:Connect("WorldUnloaded", self, self.OnLeaveWorld, "UniqueConnection")
	GameLogic:Connect("WorldSaved", self, self.OnWorldSaved, "UniqueConnection")
end

function EditableWorld:OnEnterWorld()
	self.filename = Files.WorldPathToFullPath("editableBlocks.txt")
	self:Load()
end

function EditableWorld:OnLeaveWorld()
	self:UnregisterHooks()
	self.isFreezeWorld = false;
end

function EditableWorld:RegisterHooks()
	if self.hasRegistered then
		return
	end
	self.hasRegistered = true
	GameLogic.events:AddEventListener("CreateBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:AddEventListener("CreateDiffIdBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:AddEventListener("DestroyBlockTask", self.OnDestroyBlockTask, self, "EditableWorld")
	GameLogic.GetFilters():add_filter("BatchModifyBlocks", EditableWorld.OnBlockRegionChange)
end

function EditableWorld:UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:RemoveEventListener("CreateDiffIdBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:RemoveEventListener("DestroyBlockTask", self.OnDestroyBlockTask, self, "EditableWorld")
	GameLogic.GetFilters():remove_filter("BatchModifyBlocks",EditableWorld.OnBlockRegionChange);
	self.hasRegistered = false
end

function EditableWorld.OnBlockRegionChange(blocks, is_delete)
	local self = GameLogic.CreateGetEditableWorld();
	if type(blocks) == "table" then
		for i = 1, #blocks do
			local b = blocks[i];
			local x,y,z = b[1],b[2],b[3]
						
			if is_delete then
				--self:RemoveEditablePos(x,y,z)
			else
				self:AddEditablePos(x, y, z)
			end
		end
	end
	return blocks, is_delete
end

function EditableWorld:OnWorldSaved()
	self:Save()
end

function EditableWorld:GetBlockCanDestroy(x,y,z)
	if self.isFreezeWorld then
		return self:IsEditableBlock(x,y,z)
	end
	return true
end

function EditableWorld:IsEditableBlock(x,y,z)
	if self.isFreezeWorld then
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		return self.blocksMap[mapIndex] == true
	end
	return true;
end

function EditableWorld:OnCreateBlockTask(event)
	if self.isFreezeWorld and event.x ~= nil and event.y~= nil  and  event.z ~= nil then
		self:AddEditablePos(event.x, event.y, event.z)
	end
end


function EditableWorld:AddEditablePos(x, y, z)
	if not self:IsEditableBlock(x,y,z) then
		self.blocksMap = self.blocksMap or {}
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = true
	end
end

function EditableWorld:RemoveEditablePos(x,y,z)
	if self:IsEditableBlock(x,y,z) then
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = nil
	end
end

function EditableWorld:OnDestroyBlockTask(event)
	if self.isFreezeWorld then
		if event.x ~= nil and event.y~= nil  and  event.z ~= nil then
			--self:RemoveEditablePos(event.x, event.y, event.z)
		end
	end
end

function EditableWorld:IsWorldFrozen()
	return self.isFreezeWorld
end

function EditableWorld:Reset()
	addBlocks = {}
	self.firstBlockData = {}
	self.blocksMap = {}
	if(not GameLogic.IsReadOnly()) then
		self:WriteToFile();
	end
end

function EditableWorld:FreezeWorld(bEnable)
	LOG.std(nil, "info", "EditableWorld", "Set FreezeWorld %s",tostring(bEnable))
	self:Reset()
	self.isFreezeWorld = bEnable
	WorldCommon.SetWorldTag("isFreezeWorld",self.isFreezeWorld)
	WorldCommon.SaveWorldTag()
	if self.isFreezeWorld then
		self:RegisterHooks()
	else
		self:UnregisterHooks()
	end
end

function EditableWorld:Save()
	local isFreezeWorld = WorldCommon.GetWorldTag("isFreezeWorld")
	if isFreezeWorld then
		addBlocks = {}
		local x,y,z,_x,_y,_z
		local index = 0
		for k, v in commonlib.keysorted_pairs(self.blocksMap) do    
			index = index + 1
			x,y,z = GameLogic.BlockEngine:FromSparseIndex(k)
			if index == 1 then
				-- 第一个坐标为绝对坐标保存
				_x,_y,_z = x,y,z
				table.insert(addBlocks,x)
				table.insert(addBlocks,y)
				table.insert(addBlocks,z)
			else
				-- 往后的坐标存的是相对于第一个坐标的相对值
				table.insert(addBlocks,x - _x)
				table.insert(addBlocks,y - _y)
				table.insert(addBlocks,z - _z)
			end
		end
		self:WriteToFile();
	end
end

function EditableWorld:WriteToFile(filename)
	local file = ParaIO.open(filename or self.filename, "w");
	if(file:IsValid()) then
		LOG.std(nil, "info", "EditableWorld", "Save blocks in freeze mode")
		file:WriteString(commonlib.serialize_compact(addBlocks));
		file:close();
		return true;
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed saving blocks in freeze mode");
	end	
end

function EditableWorld:HandleDataToMap()
	self.blocksMap = {}
	local totalCount = math.ceil(#addBlocks / 3)
	local mapIndex,x,y,z
	for i = 1, totalCount do
		if i == 1 then
			-- 前三个数值为第一个坐标点,保持不变
			x,y,z = addBlocks[(i - 1) * 3 + 1],addBlocks[(i - 1) * 3 + 2],addBlocks[(i - 1) * 3 + 3]
		else
			-- 往后每三个数值为下一个坐标点,是相对与第一个坐标的相对值，需要加上第一个坐标的值
			x = addBlocks[(i - 1) * 3 + 1] + addBlocks[1]
			y = addBlocks[(i - 1) * 3 + 2] + addBlocks[2]
			z = addBlocks[(i - 1) * 3 + 3] + addBlocks[3]
		end
		mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = true
	end
end

function EditableWorld:Load()
	self.isFreezeWorld = WorldCommon.GetWorldTag("isFreezeWorld")
	if self.isFreezeWorld then
		LOG.std(nil, "info", "EditableWorld", "Load FreezeWorld blocks %s",tostring(self.isFreezeWorld))
		if not ParaIO.DoesFileExist(self.filename, true) then
			addBlocks = {}
			self:WriteToFile();
			self.blocksMap = {}
		else
			addBlocks = commonlib.LoadTableFromFile(self.filename)
			self:HandleDataToMap()
		end
		self:RegisterHooks()
	end
end
