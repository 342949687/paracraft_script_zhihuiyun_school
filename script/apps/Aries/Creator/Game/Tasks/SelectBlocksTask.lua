--[[
Title: Select blocks task
Author(s): LiXizhi
Date: 2013/2/8
Desc: Ctrl+left click to select all blocks in the AABB. right click anywhere or esc key to deselect and exit the selection mode. 
when a group of blocks are selected, the following commands can be applied. 
   * hit the del key to delete all selected blocks. 
   * esc key to cancel selection.  
   * shift+left click a place to translate the current selection to a new position. (multiple clicks will create multiple copies)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, blocks=nil})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformWnd.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local TransformWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.TransformWnd");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local ShareBlocksPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ShareBlocksPage.lua");

local SelectBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks"));

SelectBlocks:Property({"PivotPoint", {0,0,0}, "GetPivotPoint", "SetPivotPoint"})
SelectBlocks:Property({"PivotPointReal", {0,0,0}})
SelectBlocks:Property({"position", {0,0,0}, "GetPosition", "SetPosition"})
SelectBlocks:Property({"yaw", 0, "GetYaw", "SetYaw", auto=true})
SelectBlocks:Property({"pitch", 0, "GetPitch", "SetPitch", auto=true})
SelectBlocks:Property({"roll", 0, "GetRoll", "SetRoll", auto=true})
SelectBlocks:Property({"PivotPointColor", "#00ffff",})

SelectBlocks:Signal("valueChanged");
SelectBlocks:Signal("selectionCanceled");
SelectBlocks:Signal("sceneRightClicked");

local groupindex_hint = 6; 

-- this is always a top level task. 
SelectBlocks.is_top_level = true;
-- picking filter
SelectBlocks.filter = 4294967295;
-- whether to use the player's y position as the pivot point. 
-- use "/UsePlayerPivotY" command
-- SelectBlocks.UsePlayerPivotY = true;

local cur_instance;
local cur_selection;
-- user can press Ctrl+D to select/deselect last selection. 
local last_instance;

-----------------------------------
-- select blocks class
-----------------------------------
function SelectBlocks:ctor()
	self.aabb = self.aabb or ShapeAABB:new();
	-- all blocks that is being selected. 
	self.blocks = self.blocks or {};
	self.liveEntities = nil;
	self.cursor = vector3d:new();
	self.PivotPoint = vector3d:new(0,0,0);
	self.PivotPointReal = vector3d:new(0,0,0);
	self.position = vector3d:new(0,0,0);

	GameLogic.GetFilters():add_filter("file_exported", SelectBlocks.filter_file_exported);
end

-- filter callback
function SelectBlocks.filter_file_exported(id, filename)
	local self = cur_instance;
	if(not self) then
		return id;
	end
	if((id == "bmax" or id == "template" or id == "x") and filename) then
		filename = Files.GetRelativePath(filename)
		filename = commonlib.Encoding.DefaultToUtf8(filename)
		GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", filename));
	elseif(id == "STL" and filename) then
		local output_file_name = filename;
		if(not commonlib.Files.IsAbsolutePath(filename)) then
			output_file_name = ParaIO.GetWritablePath()..filename;
		end
		filename = Files.GetRelativePath(filename)
		filename = commonlib.Encoding.DefaultToUtf8(filename);
		GameLogic.AddBBS(nil, L"文件已自动导入你手中的CAD方块", 6000);
		_guihelper.MessageBox(format(L"文件成功保存在%s,现在打开吗?", filename), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				ParaGlobal.ShellExecute("open", output_file_name, "", "", 1);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		local displayName = filename:match("([^/]+)%.%w+$");
		GameLogic.RunCommand("take", format("NPLCADCodeBlock {displayname=\"%s\" nplCode=\"importStl('union','%s','#ff0000')\"}", displayName, filename))
	end
	SelectBlocks.CancelSelection();
	return id,filename;
end

-- static function
function SelectBlocks.GetCurrentSelection()
	return cur_selection;
end

-- static function
function SelectBlocks.GetCurrentInstance()
	return cur_instance;
end

-- static function
function SelectBlocks.GetLastInstance()
	return last_instance;
end

-- static function
function SelectBlocks.ToggleLastInstance()
	if(SelectBlocks.GetLastInstance() == SelectBlocks.GetCurrentInstance()) then
		SelectBlocks.CancelSelection();
	elseif(SelectBlocks.GetLastInstance()) then
		SelectBlocks.GetLastInstance():Run(true);
	end
end

function SelectBlocks.RegisterHooks()
	local self = cur_instance;
	self:LoadSceneContext();
end

function SelectBlocks.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self:UnloadSceneContext();
	end
	ParaTerrain.DeselectAllBlock(groupindex_hint);
	GameLogic.AddBBS("SelectBlocks", nil);
end

-- static method
function SelectBlocks:OnMirrorAxisChange(axis)
	local self = cur_instance;
	self:UpdateManipulators();
end

-- virtual function: 
function SelectBlocks:UpdateManipulators()
	self:DeleteManipulators();

	NPL.load("(gl)script/ide/System/Scene/Manipulators/BlockPivotManipContainer.lua");
	local BlockPivotManipContainer = commonlib.gettable("System.Scene.Manipulators.BlockPivotManipContainer");

	local manipCont = BlockPivotManipContainer:new()
	manipCont.radius = 0.5;

	manipCont.xColor = self.PivotPointColor;
	manipCont.yColor = self.PivotPointColor;
	manipCont.zColor = self.PivotPointColor;
	-- manipCont.showArrowHead = false;
	manipCont:init();
	manipCont:SetPivotPointPlugName("PivotPoint");
	self:AddManipulator(manipCont);
	manipCont:connectToDependNode(self);

	if(self:IsMirrorMode()) then
		local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
		local axis = MirrorWnd.GetMirrorAxis();
		if(not axis or axis == "x") then
			manipCont.translateManip:SetShowXPlane(true)
			manipCont.translateManip.xColor = "#ff0000";
		elseif(axis == "y") then
			manipCont.translateManip:SetShowYPlane(true)
			manipCont.translateManip.yColor = "#0000ff";
		elseif(axis == "z") then
			manipCont.translateManip:SetShowZPlane(true)
			manipCont.translateManip.zColor = "#00ff00";
		end
	else
		local manipCont = BlockPivotManipContainer:new():init();
		manipCont:SetPivotPointPlugName("position");
		self:AddManipulator(manipCont);
		-- Use first block as position.
		local b = self.blocks[1];
		if(b) then
			self:SetManipulatorPosition({b[1], b[2], b[3]});
		elseif(self.blockX) then
			self:SetManipulatorPosition({self.blockX, self.blockY, self.blockZ});
		end
		manipCont:connectToDependNode(self);
	
		-- For rotation of blocks
		NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManipContainer.lua");
		local RotateManipContainer = commonlib.gettable("System.Scene.Manipulators.RotateManipContainer");
		local manipCont = RotateManipContainer:new():init();
		manipCont:SetPositionPlugName("PivotPointReal");
		manipCont:SetRealTimeUpdate(false);
		manipCont:SetYawInverted(true);
		-- manipCont:SetRollInverted(true);
		-- manipCont:SetPitchInverted(true);
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(self);
	end
end

-- change manipulator position, but does not translate the blocks
function SelectBlocks:SetManipulatorPosition(vec)
	if(vec and not self.position:equals(vec)) then
		self.position:set(vec);
		self:valueChanged();
	end
end

-- translate blocks to a new position.  This function is mostly called from the translate manipulator.
-- use SetManipulatorPosition() if one only wants to change the manipulator display location. 
function SelectBlocks:SetPosition(vec)
	if(vec and not self.position:equals(vec)) then
		local dx, dy, dz = vec[1] - self.position[1], vec[2] - self.position[2], vec[3] - self.position[3];
		self.position:set(vec);
		self:valueChanged();

		if(not TransformWnd:IsVisible()) then
			SelectBlocks.ShowTransformWnd();
		end
		TransformWnd:Translate(dx, dy, dz);
		GameLogic.AddBBS("SelectBlocks", L"回车键确认操作");
	end
end

function SelectBlocks:GetPosition()
	return self.position;
end

function SelectBlocks:SetYaw(value)
	if(self.yaw ~= value) then
		self:valueChanged();
		if(not TransformWnd:IsVisible()) then
			SelectBlocks.ShowTransformWnd();
		end
		TransformWnd:Rotate("y", value, self:GetPivotPoint());
		GameLogic.AddBBS("SelectBlocks", L"回车键确认操作");
	end
end

function SelectBlocks:SetRoll(value)
	if(self.roll ~= value) then
		self:valueChanged();
		if(not TransformWnd:IsVisible()) then
			SelectBlocks.ShowTransformWnd();
		end
		TransformWnd:Rotate("z", value, self:GetPivotPoint());
		GameLogic.AddBBS("SelectBlocks", L"回车键确认操作");
	end
end

function SelectBlocks:SetPitch(value)
	if(self.pitch ~= value) then
		self:valueChanged();
		if(not TransformWnd:IsVisible()) then
			SelectBlocks.ShowTransformWnd();
		end
		TransformWnd:Rotate("x", value, self:GetPivotPoint());
		GameLogic.AddBBS("SelectBlocks", L"回车键确认操作");
	end
end


-- set pivot point vector3d in block coordinate system
-- @param vec: if nil, we will use self.aabb's bottom center if player is in air, otherwise it will use the player's block position
function SelectBlocks:SetPivotPoint(vec)
	if(not vec) then
		local x, y, z = EntityManager.GetPlayer():GetBlockPos();
		local xx, yy, zz = EntityManager.GetPlayer():GetPosition();
		xx, yy, zz = BlockEngine:block(xx, yy-0.2, zz)
		local block = BlockEngine:GetBlock(xx, yy, zz)
		if(block and block.obstruction) then
			vec = {x, y, z};
		else
			-- player is in air, use the bottom center of the selection box
			local bx, by, bz = self.aabb:GetBottomCenter()
			vec = {math.floor(bx), math.floor(by), math.floor(bz)};
		end
	end
	if(not self.PivotPoint:equals(vec)) then
		self.PivotPoint:set(vec);
		self.PivotPointReal:set(BlockEngine:real(vec[1], vec[2], vec[3]));
		SelectBlocks.GetEventSystem():DispatchEvent({type = "OnSelectionChanged" , data = "pivot"});
		self:valueChanged();
	end
end

-- get pivot point vector3d in block coordinate system
function SelectBlocks:GetPivotPoint()
	return self.PivotPoint;
end

function SelectBlocks:CheckCanSelectNow()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks, unless it is also SelectBlock tasks
		local task = TaskManager.GetTopLevelTask();
		if(task and task:isa(SelectBlocks)) then
			if(self.blockX) then
				task.aabb:SetPointAABB(vector3d:new({self.blockX,self.blockY,self.blockZ}))
				task:RefreshDisplay();
				SelectBlocks.UpdateBlockNumber(#(task.blocks));
			end
		end
		return;
	end
	return true;
end

function SelectBlocks:PrepareData()
	if(self.blockX) then
		self.aabb:SetPointAABB(vector3d:new({self.blockX,self.blockY,self.blockZ}))
		self:RefreshDisplay()
	else
		self.aabb:SetInvalid();
		if(#(self.blocks) > 0) then
			self.need_refresh = false;
			ParaTerrain.DeselectAllBlock();

			local b = self.blocks[1];
			local min_x, min_y, min_z = b[1], b[2], b[3];
			local max_x, max_y, max_z = min_x, min_y, min_z;
			
			for _, b in ipairs(self.blocks) do
				local x, y, z = b[1], b[2], b[3]
				b[4] = b[4] or ParaTerrain.GetBlockTemplateByIdx(x,y,z);
				b[5] = b[5] or ParaTerrain.GetBlockUserDataByIdx(x,y,z);
				
				if(x < min_x) then
					min_x = x;
				end
				if(y < min_y) then
					min_y = y;
				end
				if(z < min_z) then
					min_z = z;
				end

				if(x > max_x) then
					max_x = x;
				end
				if(y > max_y) then
					max_y = y;
				end
				if(z > max_z) then
					max_z = z;
				end
				ParaTerrain.SelectBlock(x, y, z, true);
			end
			self.aabb:SetMinMax(vector3d:new({min_x, min_y, min_z}), vector3d:new({max_x, max_y, max_z}));
		end
	end
end

-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function SelectBlocks:Run(bIsDataPrepared)
	if(not self:CheckCanSelectNow()) then
		return;
	end
	cur_instance = self;
	last_instance = self;

	if(not bIsDataPrepared) then
		self:PrepareData();
	else
		self:RefreshDisplay();
	end

	cur_selection = self.blocks;
	SelectBlocks.finished = false;
	SelectBlocks.RegisterHooks();
	if not ShareBlocksPage.IsOpen() then
		SelectBlocks.ShowPage();
	end
	
	self:SetPivotPoint();

	if(#(self.blocks) > 0) then
		SelectBlocks.UpdateBlockNumber(#(self.blocks));
	end
end

function SelectBlocks:ReplaceSelection(blocks)
	if(not blocks) then
		return;
	end
	ParaTerrain.DeselectAllBlock();
	self.blocks = blocks;
	cur_selection = blocks;
end


-- @param bCommitChange: true to commit all changes made 
function SelectBlocks.CancelSelection()
	SelectBlocks.finished = true;
	ParaTerrain.DeselectAllBlock();
	SelectBlocks.UnregisterHooks();
	SelectBlocks.ClosePage();
	SelectBlocks.selected_count = 0
	
	-- canceled the selection. 	
	cur_selection = nil;

	if(cur_instance) then
		local self = cur_instance;
		self:selectionCanceled();

		cur_instance = nil;
	end

	if ShareBlocksPage.IsOpen() then
		ShareBlocksPage.CancelSelection()
	end
end

function SelectBlocks:Redo()
end

function SelectBlocks:Undo()
end

-- refresh the 3d view 
function SelectBlocks:RefreshDisplay(bImmediateUpdate)
	self.need_refresh = true;
	self.blocks = {};
	cur_selection = self.blocks;
	ParaTerrain.DeselectAllBlock();
	self.cursor = self.aabb:GetMin();
	self.min = self.aabb:GetMin();
	self.max = self.aabb:GetMax();
	if(bImmediateUpdate) then
		self:RefreshImediately();
	end
end

function SelectBlocks:RefreshImediately()
	while(self.need_refresh) do
		self:FrameMove();
	end
end

-- automatically select blocks near a given position. 
-- it first find the closest block within the radius, and then select all connected blocks to it. 
-- @param radius: default to 7;
-- @return the number of blocks selected.
function SelectBlocks.AutoSelectNearbyBlocks(cx, cy, cz, radius)
	radius = radius or 7;
	NPL.load("(gl)script/ide/System/Util/Iterators.lua");
	local Iterators = commonlib.gettable("System.Util.Iterators");
	
	for dx, dz in Iterators.Spiral3d(radius) do 
		local x, y, z = cx + dx, cy, cz + dz;
		local blockId = BlockEngine:GetBlockId(x, y, z);
		if(blockId and blockId ~= 0) then
			local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
			local self = cur_instance;
			local count = 0;
			if(cur_instance) then
				self:SelectSingleBlock(x,y,z, blockId, block_data);
				count = SelectBlocks.SelectAll(true, 2000)
			else
				local task = SelectBlocks:new({blockX = x, blockY = y, blockZ = z, blocks = {}})
				task:Run()
				task:SelectSingleBlock(x,y,z, blockId, block_data);
				count = SelectBlocks.SelectAll(true, 2000)
			end
			return count or 0;
		end
	end
	return 0;
end

-- static function:
-- select all blocks connected with current selection but not below current selection. 
-- @param max_new_count: max number of blocks to be added. default to 20000
function SelectBlocks.SelectAll(bImmediateUpdate, max_new_count)
	max_new_count = max_new_count or 20000;
	local self = cur_instance;
	if(not self) then
		return
	end 
	local blockIndices = {}; -- mapping from block index to true for processed bones
	local block = self.blocks[1];
	local cx, cy, cz;
	if(block) then
		cx, cy, cz = block[1], block[2], block[3];
	elseif(self.blockX) then
		cx, cy, cz = self.blockX, self.blockY, self.blockZ;
		self.blocks[1] = {cx, cy, cz};
	else
		return
	end
	local baseBlockCount = #(self.blocks);
	
	local min_y = 9999;
	for i, block in ipairs(self.blocks) do
		local x, y, z = block[1], block[2], block[3];
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
		blockIndices[boneIndex] = true;
		if(y < min_y) then
			min_y = y;
		end
	end
	local function IsBlockProcessed(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz);
		return blockIndices[boneIndex];
	end
	local newlyAddedCount = 0;
	local function AddBlock(x, y, z)
		local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
		if(not blockIndices[boneIndex]) then
			blockIndices[boneIndex] = true;
			local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
			if(block_id > 0) then
				local block = block_types.get(block_id);
				self.aabb:Extend(x,y,z)
				if(block) then
					local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
					self:SelectSingleBlock(x,y,z, block_id, block_data);
					newlyAddedCount = newlyAddedCount + 1;
					return true;
				end
			end
		end
	end
	local breadthFirstQueue = commonlib.Queue:new();
	local function AddConnectedBlockRecursive(cx,cy,cz)
		if(newlyAddedCount < max_new_count) then
			for side=0,5 do
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x, y, z = cx+dx, cy+dy, cz+dz;
				if(y >= min_y and AddBlock(x, y, z)) then
					breadthFirstQueue:pushright({x,y,z});
				end
			end
		end
	end
	
	for i = 1, baseBlockCount do
		local block = self.blocks[i];
		local x, y, z = block[1], block[2], block[3];
		AddConnectedBlockRecursive(x,y,z);
	end

	while (not breadthFirstQueue:empty()) do
		local block = breadthFirstQueue:popleft();
		AddConnectedBlockRecursive(block[1], block[2], block[3]);
	end

	self:OnSelectionRefreshed();
	SelectBlocks.UpdateBlockNumber(#(self.blocks));
	return #(self.blocks);
end

-- return a table containing all blocks that has been selected. 
-- if may return nil if no blocks are selected or not all blocks have finished iterating and marked. 
function SelectBlocks:GetAllBlocks()
	if(not self.need_refresh) then
		return self.blocks;
	end
end

-- get block id
-- @param typeIndex: the type id. 1 is first type, 2 is second type. 
function SelectBlocks.GetBlockId(typeIndex)
	if(cur_instance) then
		local self = cur_instance;
		local nCurType = 0;
		local nLastTypeId;
		for i, b in ipairs(self.blocks) do
			if(nLastTypeId ~= b[4]) then
				nLastTypeId = b[4];
				nCurType = nCurType + 1;
				if(nCurType == typeIndex) then
					return nLastTypeId;
				end
			end
		end
		if(#(self.blocks) >= typeIndex) then
			return nLastTypeId
		end
	end
end

-- add a single block to selection. 
function SelectBlocks:SelectSingleBlock(x,y,z, block_id, block_data)
	self.blocks[#(self.blocks)+1] = {x,y,z, block_id, block_data};
	ParaTerrain.SelectBlock(x,y,z,true);
end

-- highlight all blocks that are selected. Each frame we will only select a limited number of blocks for framerate. 
function SelectBlocks:FrameMove()
	local min, max, cursor = self.min, self.max, self.cursor;
	if(not self.need_refresh or not min or not cursor) then
		return;
	end

	-- already selected all;
	--if(self.max and self.cursor and cursor:equals(max) ) then
		--return;
	--end

	local x,y,z = cursor[1], cursor[2], cursor[3];

	local count = 0;
	local max_block_per_frame = 20000;

	local function TryAddBlock(x,y,z)
		cursor[1], cursor[2], cursor[3] = x,y,z
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		if(block_id > 0) then
			local block = block_types.get(block_id);
			if(block) then
				-- TODO: check for tasks
				count = count + 1;

				if(count < max_block_per_frame) then
					local block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
					self:SelectSingleBlock(x,y,z, block_id, block_data);
					return true;
				else
					return false;
				end
			end
		end

	end

	
	for x = cursor[1], max[1] do
		if(TryAddBlock(x,y,z) == false) then
			return;
		end
	end

	for z = cursor[3]+1, max[3] do
		for x = min[1], max[1] do
			if(TryAddBlock(x,y,z) == false) then
				return;
			end
		end
	end

	for y = cursor[2]+1, max[2] do
		for z = min[3], max[3] do
			for x = min[1], max[1] do
				if(TryAddBlock(x,y,z) == false) then
					return;
				end
			end
		end
	end
	
	if(cursor:equals(max)) then
		self:OnSelectionRefreshed();
		local liveEntityCount = self:UpdateLiveEntitySelection()
		SelectBlocks.UpdateBlockNumber(#(self.blocks), liveEntityCount);
	end
end

-- return count
function SelectBlocks:UpdateLiveEntitySelection()
	local liveEntityCount = 0;
	self.liveEntities = nil;
	if(self.aabb and (self.aabb:GetVolume() < 100000)) then
		local liveEntities = SelectBlocks.GetLiveEntities(self.aabb)
		if(liveEntities) then
			self.liveEntities = liveEntities;
			liveEntityCount = #liveEntities;
			for _, entity in ipairs(liveEntities) do
				local x, y, z = entity:GetBlockPos()
				ParaTerrain.SelectBlock(x,y,z,true);
			end
		end
	end
	return liveEntityCount;
end

function SelectBlocks.GetLiveEntities(aabb)
	if(aabb) then
		local min_x, min_y, min_z = aabb:GetMinValues()
		local max_x, max_y, max_z = aabb:GetMaxValues()
		local entities = EntityManager.GetEntitiesByMinMax(min_x, min_y, min_z, max_x, max_y, max_z, EntityManager.EntityLiveModel)
		return entities;
	end
end

function SelectBlocks:OnSelectionRefreshed()
	self.need_refresh = nil;
	SelectBlocks.GetEventSystem():DispatchEvent({type = "OnSelectionChanged" , data = "pivot"});
end

function SelectBlocks:OnExit()
	SelectBlocks.GetEventSystem():ClearAllEvents();
	SelectBlocks.CancelSelection();
end

-- filter only blocks of the given type in selection. 
function SelectBlocks.FilterOnlyBlock(x, y, z)
	local self = cur_instance;
	if(not self) then
		return
	end 
	local block_id = BlockEngine:GetBlockId(x,y,z);
	local blocks = {};
	ParaTerrain.DeselectAllBlock();
	
	for i, b in pairs(self.blocks) do
		if(b[4] == block_id) then
			blocks[#blocks+1] = b;
			ParaTerrain.SelectBlock(b[1],b[2],b[3],true);
		end
	end
	self.blocks = blocks;
	cur_selection = blocks;
	SelectBlocks.UpdateBlockNumber(#(blocks));
	self:OnSelectionRefreshed();
end

function SelectBlocks:mouseWheelEvent(event)
	-- disable other mouse wheel event 
	if(self:GetSceneContext()) then
		self:GetSceneContext():handleCameraWheelEvent(event);
	end
end

function SelectBlocks:handleRightClickScene(event)
	if(self:sceneRightClicked(event)) then
		return
	end
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		local self = cur_instance;
		local ctrl_pressed = event.ctrl_pressed;
		if ctrl_pressed then
			local result = {};
			result = SelectionManager:MousePick(GameLogic.GetPickingDist(), result, self.filter);
			
			if(result.blockX) then
				local block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
				if(block_id and block_id > 0) then
					local block = block_types.get(block_id);
					if(block) then
						if(block.invisible and not block.solid) then
							-- we will skip picking for invisible non solid block. instead we will only pick solid or customModel object.
							result = SelectionManager:MousePick(GameLogic.GetPickingDist(), result, mathlib.bit.band(0x84, self.filter));
						end
					end
				end
			end
			SelectBlocks.ExtendAABB(result.blockX,result.blockY,result.blockZ)
			self:SetPivotPoint();
			self:SetManipulatorPosition({result.blockX,result.blockY,result.blockZ});
		end
		return 
	end
end

function SelectBlocks:handleLeftClickScene(event)
	local self = cur_instance;
	local ctrl_pressed = event.ctrl_pressed;
	local alt_pressed = event.alt_pressed;
	local shift_pressed = event.shift_pressed;

	if(ctrl_pressed) then
		-- pick any scene object
		local result = {};
		result = SelectionManager:MousePick(GameLogic.GetPickingDist(), result, self.filter);
		
		if(result.blockX) then
			local block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
			if(block_id and block_id > 0) then
				local block = block_types.get(block_id);
				if(block) then
					if(block.invisible and not block.solid) then
						-- we will skip picking for invisible non solid block. instead we will only pick solid or customModel object.
						result = SelectionManager:MousePick(GameLogic.GetPickingDist(), result, mathlib.bit.band(0x84, self.filter));
					end
				end
			end
		end

		if(result.blockX) then
			if(shift_pressed) then
				-- ctrl+shift+ left click to toggle a single block's selection state
				SelectBlocks.ToggleBlockSelection(result.blockX,result.blockY,result.blockZ)
			elseif(alt_pressed) then
				-- ctrl+alt+ left click to filter the given block in the current selection. 
				SelectBlocks.FilterOnlyBlock(result.blockX,result.blockY,result.blockZ)
			else
				SelectBlocks.ExtendAABB(result.blockX,result.blockY,result.blockZ)
				self:SetPivotPoint();
				self:SetManipulatorPosition({result.blockX,result.blockY,result.blockZ});
			end
		end
	elseif(alt_pressed) then
		local result = {};
		result = SelectionManager:MousePick(GameLogic.GetPickingDist(), result, self.filter);

		if(result.blockX) then
			self:SetPivotPoint({result.blockX,result.blockY,result.blockZ});
		end

	elseif(shift_pressed) then
		local result = Game.SelectionManager:MousePickBlock();

		if(result.blockX) then
			local x,y,z
			if(result.side) then
				x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
			else
				x,y,z = result.blockX,result.blockY,result.blockZ;
			end

			local pivot_x, pivot_y, pivot_z = self:GetSelectionPivot();
			local dx, dy, dz = x - pivot_x,y - pivot_y,z - pivot_z;
			if (dx~=0 or dy ~=0 or dz~=0) then
				SelectBlocks.TransformSelection({dx=dx,dy=dy,dz=dz});
				self.aabb:Offset(dx,dy,dz);
			end
		end	
	else
		-- clicking without ctrl key will cancel the selection mode. 
		SelectBlocks.CancelSelection();
	end
	event:accept();
end

function SelectBlocks:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- cancel selection. 
		SelectBlocks.CancelSelection();
		event:accept();
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		SelectBlocks.DeleteSelection();
		event:accept();
	elseif(dik_key == "DIK_EQUALS")then
		if(event.ctrl_pressed) then
			SelectBlocks.TransformSelection({scalingX = 2, scalingY = 2, scalingZ = 2})
		else
			SelectBlocks.AutoExtrude(true);
		end
		event:accept();
	elseif(dik_key == "DIK_MINUS")then
		if(event.ctrl_pressed) then
			SelectBlocks.TransformSelection({scalingX = 0.5, scalingY = 0.5, scalingZ = 0.5})
		else
			SelectBlocks.AutoExtrude(false);
		end
		event:accept();
	elseif(dik_key == "DIK_LBRACKET")then
		SelectBlocks.TransformSelection({rot_angle=1.57, rot_axis = "y"})
		event:accept();
	elseif(dik_key == "DIK_RBRACKET")then
		SelectBlocks.TransformSelection({rot_angle=-1.57, rot_axis = "y"})
		event:accept();
	elseif(dik_key == "DIK_A" and event.ctrl_pressed)then
		SelectBlocks.SelectAll(true)
		event:accept();
	elseif(dik_key == "DIK_C" or dik_key == "DIK_V" or dik_key == "DIK_X" )then
		if(event.ctrl_pressed) then
			if(dik_key == "DIK_C")then
				local isExportReferences = event.shift_pressed;
				self:CopyBlocks(nil, isExportReferences);
			elseif(dik_key == "DIK_X")then
				self:CopyBlocks(true);
			else
				self:PasteBlocks();
			end
			event:accept();
			if(GameLogic.Macros:IsRecording()) then
				local angleX, angleY = GameLogic.Macros.GetSceneClickParams();
				GameLogic.Macros:AddMacro("NextKeyPressWithMouseMove", angleX, angleY);
			end
		end
	elseif(dik_key == "DIK_Z")then
		if(event.ctrl_pressed) then
			self:PopAABB();
		elseif(dik_key == "DIK_Z") then
			UndoManager.Undo();
		end
		event:accept();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
		event:accept();
	elseif(dik_key == "DIK_RETURN" or dik_key == "DIK_NUMPADENTER")then
		if(TransformWnd:IsVisible()) then
			TransformWnd.TransformSelection();
			event:accept();
		end
	else
		self:GetSceneContext():keyPressEvent(event);
	end	
end

------------------------
-- page function 
------------------------
local page;
function SelectBlocks.ShowPage(bShow)
	SelectBlocks.selected_count = 0;
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	local x, y, width, height = 0, 160, 120, 330;
	params = {
		url = "script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.html", 
		name = "SelectBlocksTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		allowDrag = true,
		click_through = true,
		directPosition = true,
			align = "_lt",
			x = x,
			y = y,
			width = width,
			height = height,
	}
	params =  GameLogic.GetFilters():apply_filters('GetUIPageHtmlParam',params,"SelectBlocksTask");
	System.App.Commands.Call("File.MCMLWindowFrame",params);
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
	GameLogic:UserAction("select blocks");
end

function SelectBlocks.ShowEditPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectBlocksEditor.mobile.html", 
			name = "SelectBlocksTask.ShowEditPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = -2,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_ct",
				x = -340/2,
				y = -290/2,
				width = 340,
				height = 290,
		});
end

function SelectBlocks.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function SelectBlocks.GetBlockCountText()
	local count = SelectBlocks.selected_count or 0;
	local liveEntityCount = SelectBlocks.liveEntityCount or 0;
	if(liveEntityCount == 0) then
		return format(L"选中了%d块",count or 1);
	elseif(not count or count == 0) then
		return format(L"选中了%d物体", liveEntityCount);
	else
		return format(L"%d块, %d物体", count, liveEntityCount);
	end
end

-- update the block number in the left panel page. 
function SelectBlocks.UpdateBlockNumber(count, liveEntityCount)
	liveEntityCount = liveEntityCount or 0
	if(page) then
		if(SelectBlocks.selected_count ~= count or SelectBlocks.liveEntityCount ~= liveEntityCount) then
			SelectBlocks.selected_count = count;
			SelectBlocks.liveEntityCount = liveEntityCount;
			if( not (count > 1 and SelectBlocks.selected_count>1) ) then
				page:Refresh(0.01);
			else
				page:SetUIValue("title", SelectBlocks.GetBlockCountText())
			end

			GameLogic.GetFilters():apply_filters('UpdateBlockNumber');
		end
	end

	if ShareBlocksPage.IsOpen() then
		ShareBlocksPage.UpdateBlockNumber(count)
	end
end


function SelectBlocks.OnInit()
	page = document:GetPageCtrl();
	if(System.options.mc) then
		page.OnClose = function () 
			TransformWnd.ClosePage();
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
			local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
			MirrorWnd.ClosePage();
		end	
	end
end

function SelectBlocks.GetEventSystem()
	SelectBlocks.events = SelectBlocks.events or commonlib.EventSystem:new();
	return SelectBlocks.events;
end

function SelectBlocks.DoClick(name)
	local self = SelectBlocks;
	if(name == "delete")then
		self.DeleteSelection()
	elseif(name == "btn_selectall")then
		self.SelectAll(true);
	elseif(name == "save_template" or name == "btn_template")then
		GameLogic.RunCommand("export");
		-- self.SaveToTemplate();
	elseif(name == "extrude_negY")then
		self.AutoExtrude(false);
	elseif(name == "extrude_posY")then
		-- can we scale like vectors so that we can resize a hollow room without making the wall thicke?
		self.AutoExtrude(true);
	elseif(name == "btnTransform" or name == "btn_transform")then
		SelectBlocks.ShowTransformWnd();
	elseif(name == "left_rot" or name == "btn_rotate_left")then
		SelectBlocks.TransformSelection({rot_angle=1.57, rot_axis = "y"})
	elseif(name == "right_rot" or name == "btn_rotate_right")then
		SelectBlocks.TransformSelection({rot_angle=-1.57, rot_axis = "y"})
	elseif(name == "dx_positive" or name == "btn_moveto_front")then
		SelectBlocks.TransformSelection({dx=1})
	elseif(name == "dx_negative" or name == "btn_moveto_back")then
		SelectBlocks.TransformSelection({dx=-1})
	elseif(name == "dy_positive" or name == "btn_moveto_up")then
		SelectBlocks.TransformSelection({dy=1})
	elseif(name == "dy_negative" or name == "btn_moveto_down")then
		SelectBlocks.TransformSelection({dy=-1})
	elseif(name == "dz_positive" or name == "btn_moveto_left")then
		SelectBlocks.TransformSelection({dz=1})
	elseif(name == "dz_negative" or name == "btn_moveto_right")then
		SelectBlocks.TransformSelection({dz=-1})
	elseif(name == "btn_mirror")then
		SelectBlocks.MirrorSelection()
	elseif(name == "btn_share")then
		local ShareBlocksPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ShareBlocksPage.lua");
		ShareBlocksPage.ShareBlcok()
		SelectBlocks.ClosePage();
	end
end

-- get the pivot point at the bottom center of the aabb
function SelectBlocks:GetSelectionPivot()
	local mCenter = self.aabb:GetCenter();
	local mMin = self.aabb:GetMin();
	mCenter[2] = mMin[2];
	return math.floor(mCenter[1]), math.floor(mCenter[2]), math.floor(mCenter[3]);
end

-- get the current selected blocks and pivot
-- @return blocks, pi
function SelectBlocks:GetSelectedBlocks()
	return cur_selection;
end

-- Get a copy of blocks including block's server data
-- @param pivot: the pivot point vector, if nil, it will default to self:GetPivotPoint()
-- this can be {0,0,0} which will retain absolute position. 
-- @return blocks: array of {x,y,z,id, data, entity_data}
function SelectBlocks:GetCopyOfBlocks(pivot)
	pivot = pivot or self:GetPivotPoint()
	local pivot_x,pivot_y,pivot_z = unpack(pivot);
	
	self:UpdateSelectionEntityData();

	local blocks = {};
	for i = 1, #(cur_selection) do
		-- x,y,z,block_id, data, serverdata
		local b = cur_selection[i];
		blocks[i] = {b[1]-pivot_x, b[2]-pivot_y, b[3]- pivot_z, b[4], if_else(b[5] == 0, nil, b[5]), b[6]};
	end
	return blocks;
end

-- @return array of entities XML nodes
function SelectBlocks.GetLiveEntitiesInAABB(aabb, pivot)
	if(aabb) then
		local min_x, min_y, min_z = aabb:GetMinValues()
		local max_x, max_y, max_z = aabb:GetMaxValues()
		local entities = EntityManager.GetEntitiesByMinMax(min_x, min_y, min_z, max_x, max_y, max_z, EntityManager.EntityLiveModel)
		local entityNodes = {}
		if(entities and #entities > 0) then
			local pivot_x, pivot_y, pivot_z = unpack(pivot);
			local pivot_rx, pivot_ry, pivot_rz = pivot_x * BlockEngine.blocksize, pivot_y * BlockEngine.blocksize, pivot_z * BlockEngine.blocksize; 
			for _, entity in ipairs(entities) do
				local node = entity:SaveToXMLNode()
				if(node.attr.x) then
					node.attr.x, node.attr.y, node.attr.z = node.attr.x - pivot_rx, node.attr.y - pivot_ry, node.attr.z - pivot_rz;
				end
				if(node.attr.bx) then
					node.attr.bx, node.attr.by, node.attr.bz = nil, nil, nil;
				end
				entityNodes[#entityNodes+1] = node;
			end

			return entityNodes;
		end
	end
end

function SelectBlocks.SaveToTemplate()
	if(cur_selection and cur_instance) then
		local self = cur_instance;

		-- all relative to pivot point. 
		local pivot_x, pivot_y, pivot_z = self:GetSelectionPivot();
		if(self.UsePlayerPivotY) then
			local x,y,z = ParaScene.GetPlayer():GetPosition();
			local _, by, _ = BlockEngine:block(0,y+0.1,0);
			pivot_y = by;
		end
		local pivot = {pivot_x, pivot_y, pivot_z};

		local blocks = self:GetCopyOfBlocks(pivot);
		local liveEntities = SelectBlocks.GetLiveEntitiesInAABB(self.aabb, pivot)
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
		BlockTemplatePage.ShowPage(true, blocks, pivot, liveEntities);
	end
end

function SelectBlocks:PushAABB()
	self.history_aabbs = self.history_aabbs or commonlib.List:new();
	
	if(self.aabb) then
		local aabb = self.history_aabbs:last();
		if(not aabb or not self.aabb:equals(aabb.aabb)) then
			self.history_aabbs:push_back({aabb=self.aabb:clone()});
		end
	end
end

function SelectBlocks:PopAABB()
	if(self.history_aabbs) then
		local aabb = self.history_aabbs:last();
		if(aabb) then
			self.history_aabbs:remove(aabb);
			self.aabb = aabb.aabb;
			self:RefreshDisplay();
		end
	end
end

function SelectBlocks:IsBlockSelected(x,y,z)
	for i, block in pairs(self.blocks) do
		if(block[1] == x and block[2] == y and block[3] == z) then
			return true;
		end
	end
end

-- toggle block selection. 
function SelectBlocks.ToggleBlockSelection(x,y,z)
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	for i, block in pairs(self.blocks) do
		if(block[1] == x and block[2] == y and block[3] == z) then
			commonlib.removeArrayItem(self.blocks, i);
			ParaTerrain.SelectBlock(x,y,z,false);
			SelectBlocks.UpdateBlockNumber(#(self.blocks));
			return;
		end
	end
	self:SelectSingleBlock(x,y,z, BlockEngine:GetBlockId(x,y,z), BlockEngine:GetBlockData(x,y,z));
	SelectBlocks.UpdateBlockNumber(#(self.blocks));
end

-- extend AABB
function SelectBlocks.ExtendAABB(bx,by,bz, bImmediateUpdate )
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(bx) then
		if(by<0) then
			by = 0;
		end
		if(by>=256) then
			by = 255;
		end
		self:PushAABB();
		if(self.aabb:Extend(vector3d:new({bx,by,bz}))) then
			self:RefreshDisplay(bImmediateUpdate);
		end
	end
end

-- automatically extruding according to a direction. The chosen direction is always the direction which the lagest aabb extent. 
-- @param isPositiveDirection:true for positive direction. 
function SelectBlocks.AutoExtrude(isPositiveDirection)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		local mExtents = cur_instance.aabb.mExtents;
		if(mExtents) then
			local dx,dy,dz = 0,0,0;
			local params = {blocks = cur_selection};
			-- extending according to whichever direction has most blocks. 
			if(mExtents[2] <= mExtents[1] and mExtents[2] <= mExtents[3]) then
				dy = if_else(isPositiveDirection, 1, -1);
			elseif(mExtents[1] <= mExtents[2] and mExtents[1] <= mExtents[3]) then
				dx = if_else(isPositiveDirection, 1, -1);
			elseif(mExtents[3] <= mExtents[2] and mExtents[3] <= mExtents[1]) then
				dz = if_else(isPositiveDirection, 1, -1);
			end

			SelectBlocks.ExtrudeSelection(dx,dy,dz);
		end
	end
end

function SelectBlocks.ExtrudeSelection(dx, dy, dz)
	if(cur_instance and cur_instance.aabb and cur_instance.aabb:IsValid() and #cur_selection > 0) then
		local self = cur_instance;
		dx,dy,dz = (dx or 0), (dy or 0), (dz or 0);
		self.px, self.py, self.pz = (self.px or 0), (self.py or 0), (self.pz or 0);
		if( (dx~=0) or (dy~=0) or (dz~=0)) then
			self:UpdateSelectionEntityData();
			local params = {blocks = cur_selection};

			-- tricky: only allow extruding one direction.
			if(self.px*dx <= 0) then
				self.px = 0
			end
			if(self.py*dy <= 0) then
				self.py = 0;
			end
			if(self.pz*dz <= 0) then
				self.pz = 0;
			end

			self.px = self.px + dx;
			params.dx = self.px;

			self.py = self.py + dy;
			params.dy = self.py;

			self.pz = self.pz + dz;
			params.dz = self.pz;

			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExtrudeBlocksTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ExtrudeBlocks:new(params)
			task:Run();
		end
	end
end

-- delete without saving to history
function SelectBlocks.DeleteLiveEntitiesInAABB(aabb)
	if(aabb) then
		local min_x, min_y, min_z = aabb:GetMinValues()
		local max_x, max_y, max_z = aabb:GetMaxValues()
		local entities = EntityManager.GetEntitiesByMinMax(min_x, min_y, min_z, max_x, max_y, max_z, EntityManager.EntityLiveModel)
		if(entities and #entities > 0) then
			local fail_count = 0;
			for _, entity in ipairs(entities) do
				if(not entity:IsLocked()) then
					entity:Destroy();
				else
					fail_count = fail_count + 1
				end
			end
			if(fail_count > 0) then
				GameLogic.AddBBS(nil, L"有部分实体被锁定，无法删除", 3000, "255 0 0");
			end
		end
	end
end

-- delete entity without saving to history
function SelectBlocks.DeleteEntitiesInAABB(aabb)
	if(aabb) then
		local fail_count = 0;
		local min_x, min_y, min_z = aabb:GetMinValues()
		local max_x, max_y, max_z = aabb:GetMaxValues()
		for x = min_x, max_x do
			for y = min_y, max_y do
				for z = min_z, max_z do
					local entities = EntityManager.GetEntitiesInBlock(x, y, z);
					if(entities) then
						for entity,_ in pairs(entities) do
							if entity and (entity:isa(EntityManager.EntityLiveModel) or entity:isa(EntityManager.EntityRailcar)) then
								if(not entity:IsLocked()) then
									entity:Destroy();
								else
									fail_count = fail_count + 1
								end
							end
						end
					end
				end
			end
		end
		if(fail_count > 0) then
			GameLogic.AddBBS(nil, L"有部分实体被锁定，无法删除", 3000, "255 0 0");
		end
	end
end

-- global function to delete a group of blocks. 
-- @param bFastDelete: if true, we will delete blocks without generating new undergound blocks. 
function SelectBlocks.DeleteSelection(bFastDelete)
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	GameLogic.GetFilters():apply_filters("user_event_stat", "block", "DeleteSelection", 1, nil);
	
	if(bFastDelete) then
		SelectBlocks.FillSelection(0);
		-- SelectBlocks.DeleteLiveEntitiesInAABB(self.aabb)
		SelectBlocks.DeleteEntitiesInAABB(self.aabb)
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({
			explode_time=200, 
			destroy_blocks = cur_selection,
			liveEntities = SelectBlocks.GetLiveEntitiesInAABB(self.aabb, {0,0,0}),
		})
		SelectBlocks.CancelSelection();
		task:Run();
	end
end

-- update entity data for each selected block
function SelectBlocks:UpdateSelectionEntityData()
	if(#cur_selection > 0) then
		for i = 1, #(cur_selection) do
			-- x,y,z,block_id, data, serverdata
			local b = cur_selection[i];
			b[6] = BlockEngine:GetBlockEntityData(b[1], b[2], b[3]);
		end
	end
end

local pivotInClipboard = {};
function SelectBlocks:GetPivotInClipboard()
	return pivotInClipboard;
end

function SelectBlocks:CopyBlocks(bRemoveOld, isExportReferences)
	if(self.aabb:IsValid()) then
		local mExtents = self.aabb.mExtents;
		local center = self.aabb:GetCenter();

		self:UpdateSelectionEntityData();

		self.copy_task = { blocks = commonlib.copy(cur_selection), aabb = self.aabb:clone(), 
			liveEntities = SelectBlocks.GetLiveEntitiesInAABB(self.aabb, {0,0,0}),
			};

		if(not bRemoveOld) then
			self.copy_task.operation = "add";
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
		local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");
		if(Clipboard and ((#cur_selection > 0) or (self.copy_task.liveEntities))) then
			local pivot = self:GetPivotPoint()
			if(pivot) then
				local pivot_x,pivot_y,pivot_z = EntityManager.GetPlayer():GetBlockPos();
				pivotInClipboard[1], pivotInClipboard[2], pivotInClipboard[3] = pivot_x,pivot_y,pivot_z
				local blocks = {};
				for i = 1, #(cur_selection) do
					-- x,y,z,block_id, data, serverdata
					local b = cur_selection[i];
					blocks[i] = {b[1]-pivot_x, b[2]-pivot_y, b[3]- pivot_z, b[4], if_else(b[5] == 0, nil, b[5]), b[6]};
				end
				local liveEntities = SelectBlocks.GetLiveEntitiesInAABB(self.aabb, {pivot_x,pivot_y,pivot_z})
				SelectBlocks.CopyToClipboard(blocks, liveEntities, isExportReferences)
			end
		end

		BroadcastHelper.PushLabel({id="BuildMinimap", label = L"保存成功! Ctrl+V在鼠标所在位置粘贴！", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

-- static public function: 
-- copy current mouse cursor block to clipboard
function SelectBlocks.CopyToClipboard(blocks, liveEntities, isExportReferencedFiles)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
	local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");

	local result = Game.SelectionManager:MousePickBlock();
	local bFound;
	if(result.entity and not liveEntities) then
		if(result.entity:isa(EntityManager.EntityLiveModel)) then
			bFound = true;
			local xmlNode = result.entity:SaveToXMLNode()
			if(isExportReferencedFiles) then
				xmlNode.attr.x, xmlNode.attr.y, xmlNode.attr.z = BlockEngine:real_bottom(0, 0, 0);
				xmlNode.attr.bx, xmlNode.attr.by, xmlNode.attr.bz = nil, nil, nil;
				liveEntities = {xmlNode};
				blocks = blocks or {};
			else
				if(Clipboard.Save("EntityLiveModel", xmlNode)) then
					GameLogic.AddBBS(nil, format(L"1个模型已存到裁剪版"), 4000, "0 255 0");
				end
			end
		end
	end
	if((liveEntities or blocks) or (not bFound and result.blockX and result.side)) then
		if(not blocks) then
			local bx, by, bz = result.blockX, result.blockY, result.blockZ;
			local b = {0, 0, 0}
			b[4], b[5], b[6] = BlockEngine:GetBlockFull(bx, by, bz);
			if(b[4]) then
				blocks = {b};
			end
		end
		
		if(blocks or liveEntities) then
			bFound = true;
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
			local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
			local task = BlockTemplate:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, 
				blocks = blocks or {}, liveEntities = liveEntities,
				relative_motion=true, UseAbsolutePos = false, TeleportPlayer = false, exportReferencedFiles = isExportReferencedFiles == true, relative_to_player = (#blocks>1)})
				
			local filedata = task:SaveTemplateToString();
			if(filedata) then
				if(Clipboard.Save("block_template", filedata)) then
					local text = format(L"%d个方块已存到裁剪版", blocks and #blocks or 0)
					if(liveEntities and #liveEntities>0) then
						text = format(L"%d个实体, %s", #liveEntities, text);
					end
					if(isExportReferencedFiles) then
						text = text..L"(包含引用文件)";
					end
					GameLogic.AddBBS(nil, text, 4000, "0 255 0");
				end
			end
		end
	end
end

-- static public function: clipboard
function SelectBlocks.PasteFromClipboard(bx, by, bz)
	if not GameLogic.options.CanPasteBlock then
		GameLogic.AddBBS(nil,L"粘贴失败，该世界禁止从外部粘贴方块！")
		return
	end
	local bHasSpecifiedPasteLocation;
	local x, y, z;
	if(bx) then
		bHasSpecifiedPasteLocation = true;
	else
		local result = Game.SelectionManager:MousePickBlock();
		if(result and result.blockX and result.side) then
			bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
		end
		if(result and result.physicalX) then
			x, y, z = result.physicalX, result.physicalY, result.physicalZ
		end
	end
	if(bx) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
		local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");

		local obj_type, obj = Clipboard.Load()
		if(obj_type == "block_template") then
			if(type(obj) == "string") then
				local xmlRoot = ParaXML.LuaXML_ParseString(obj);
				if(xmlRoot and xmlRoot[1]) then
					local attr = xmlRoot[1].attr;
					if(attr and attr.relative_to_player=="true" and not bHasSpecifiedPasteLocation) then
						bx,by,bz = EntityManager.GetPlayer():GetBlockPos();
					end

					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
					local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
					local task = BlockTemplate:new({blockX = bx,blockY = by, blockZ = bz, 
						UseAbsolutePos = false, TeleportPlayer = false, exportReferencedFiles = false})
					if(task:LoadTemplateFromXmlNode(xmlRoot)) then
						
					end
				end
			end
		elseif(obj_type == "EntityLiveModel") then
			if(type(obj) == "table" and obj.attr) then
				local xmlNode = obj;
				local attr = xmlNode.attr;
				attr.x, attr.y, attr.z = nil, nil, nil;
				attr.name = nil;
				local entityClass;
				if(attr.class) then
					entityClass = EntityManager.GetEntityClass(attr.class)
				end
				entityClass = entityClass or EntityManager.EntityLiveModel
				if(x) then
					bx, by, bz = nil, nil, nil;
				end
				local entity = entityClass:Create({bx=bx,by=by,bz=bz, x=x, y=y, z=z}, xmlNode);
				entity:Attach();

				if(GameLogic.GameMode:IsEditor()) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
					local dragTask = MyCompany.Aries.Game.Tasks.DragEntity:new({})
					dragTask:CreateEntity(entity)
				end
			end
		end
	end
end

-- paste at current mouse position
-- @param bx, by, bz: center of the blocks. if nil, the current mouse pick block is used. 
function SelectBlocks:PasteBlocks(bx, by, bz)
	if(not self.copy_task) then
		self:CopyBlocks();
	end

	if(self.copy_task) then
		local copy_task = {blocks = self.copy_task.blocks, liveEntities = self.copy_task.liveEntities, aabb =  self.copy_task.aabb:clone(), operation = self.copy_task.operation};
		
		if(not bx) then
			local result = Game.SelectionManager:MousePickBlock();
			if(result.blockX and result.side) then
				bx, by, bz = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side)
				copy_task.x, copy_task.y, copy_task.z = bx, by, bz;
			end
		end

		if(copy_task.x) then
			-- whether to confirm with ui
			local g_bUI_Confirm = true;
			if(g_bUI_Confirm) then
				self:SetManipulatorPosition({bx, by, bz});
				
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
				local dx,dy,dz = MyCompany.Aries.Game.Tasks.TransformBlocks:GetDeltaPosition(copy_task.x,copy_task.y,copy_task.z, copy_task.aabb);
				
				TransformWnd.ShowPage(copy_task.blocks, {x=dx, y=dy, z=dz, method=copy_task.operation}, function(trans, res, method)
					if(trans and res == "ok") then
						copy_task.dx = trans.x;
						copy_task.dy = trans.y;
						copy_task.dz = trans.z;
						copy_task.x,copy_task.y,copy_task.z = nil, nil, nil;
						copy_task = MyCompany.Aries.Game.Tasks.TransformBlocks:new(copy_task);
						if(method == "no_clone") then
							copy_task.operation = "move"
						end
						copy_task:Run();
					end
				end)
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
				copy_task = MyCompany.Aries.Game.Tasks.TransformBlocks:new(copy_task);
				copy_task:Run();
			end
			if(self.copy_task.operation == "move") then
				self.copy_task.operation = "add";
			end
		end
	end
end

local function OnMirrorSelectionChanged()
	local self = cur_instance;
	if(self and cur_selection) then
		local pivot_x,pivot_y,pivot_z = unpack(self:GetPivotPoint());
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
		local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");

		MirrorWnd.UpdateHintLocation(cur_selection, pivot_x, pivot_y, pivot_z);
	end
end

function SelectBlocks:SetMirrorMode(bEnable)
	if(self.isMirrorMode ~= bEnable) then
		self.isMirrorMode = bEnable;
		if(self:GetSceneContext() and self:GetSceneContext():HasManipulators()) then
			self:UpdateManipulators();
		end
	end
end

function SelectBlocks:IsMirrorMode()
	return self.isMirrorMode;
end

function SelectBlocks.MirrorSelection()
	local self = cur_instance;
	if(self) then
		local pivot_x,pivot_y,pivot_z = unpack(self:GetPivotPoint());
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
		local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
		
		SelectBlocks.GetEventSystem():AddEventListener("OnSelectionChanged", OnMirrorSelectionChanged, nil, "MirrorWnd");

		self:SetMirrorMode(true);

		MirrorWnd.ShowPage(cur_selection, pivot_x,pivot_y,pivot_z, function(settings, result)
			SelectBlocks.GetEventSystem():RemoveEventListener("OnSelectionChanged", OnMirrorSelectionChanged);
			self:SetMirrorMode(false);
			if(result) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MirrorBlocksTask.lua");
				local task = MyCompany.Aries.Game.Tasks.MirrorBlocks:new({method=settings.method, from_blocks=MirrorWnd.blocks, pivot_x=MirrorWnd.pivot_x,pivot_y=MirrorWnd.pivot_y,pivot_z=MirrorWnd.pivot_z, mirror_axis=settings.xyz, })
				task:Run();
			end
		end);
		self:UpdateManipulators()
		MirrorWnd:Connect("axisChanged", SelectBlocks, SelectBlocks.OnMirrorAxisChange, "UniqueConnection");
	end
end

local function OnTransformSelectionChanged()
	local self = cur_instance;
	if(self and cur_selection) then
		TransformWnd.UpdateHintLocation(cur_selection);
	end
end

function SelectBlocks:HasSelection()
	if(self and self.aabb and self.aabb:IsValid() and (#cur_selection > 0 or (self.liveEntities and #(self.liveEntities) > 0)) ) then
		return true;
	end
end

function SelectBlocks.ShowTransformWnd()
	local self = cur_instance;
	if(self and self:HasSelection()) then
		SelectBlocks.GetEventSystem():AddEventListener("OnSelectionChanged", OnTransformSelectionChanged, nil, "TransformWnd");
		TransformWnd.ShowPage(cur_selection, {x=0, y=0, z=0,}, function(trans, res)
			SelectBlocks.GetEventSystem():RemoveEventListener("OnSelectionChanged", OnTransformSelectionChanged);
			if(trans and res == "ok") then
				SelectBlocks.TransformSelection({dx=trans.x, dy=trans.y, dz=trans.z, pivot = self:GetPivotPoint(), rot_axis = trans.rot_axis, rot_angle=trans.rot_angle, 
					scalingX = trans.scalingX, scalingY = trans.scalingY, scalingZ = trans.scalingZ, method = trans.method});
			end
		end)
	end
end

-- @param trans: {dx,dy,dz, pivot, rot_axis, rot_angle, scalingX, scalingY, scalingZ, method}
-- method can be nil or "clone" or "extrude"
function SelectBlocks.TransformSelection(trans)
	local self = cur_instance;
	if(self and self:HasSelection()) then
		local mExtents = cur_instance.aabb.mExtents;

		local shift_pressed = Keyboard:IsShiftKeyPressed()
		if(trans.method == "extrude" or shift_pressed) then
			-- if shift is pressed, we will extrude	
			SelectBlocks.ExtrudeSelection(trans.dx, trans.dy, trans.dz);
		else
			self:UpdateSelectionEntityData();
			local liveEntities = SelectBlocks.GetLiveEntitiesInAABB(self.aabb, {0,0,0})

			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({dx = trans.dx, dy=trans.dy, dz=trans.dz, pivot = self:GetPivotPoint(), rot_axis = trans.rot_axis, rot_angle=trans.rot_angle, scalingX=trans.scalingX, scalingY=trans.scalingY, scalingZ=trans.scalingZ, 
				blocks=cur_selection, liveEntities = liveEntities,
				aabb=cur_instance.aabb, operation = trans.method})
			task:Run();

			self:ReplaceSelection(commonlib.clone(task.final_blocks));
		end
	end
end

function SelectBlocks.ConvertBlocksToRealTerrain()
	local self = cur_instance;
	if(self and self:HasSelection()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateTerrainHoleTask.lua");

		local mExtents = self.aabb.mExtents;
		local center = self.aabb:GetCenter();

		local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({operation="BlocksToRealTerrain", 
			blockX = center[1], blockY = center[2], blockZ = center[3], 
		});
		task:Run();
	end
end

function SelectBlocks.EnterNeuronEditMode()
	if(cur_instance) then
		local self = cur_instance;
		local bx, by, bz = self.blockX, self.blockY, self.blockZ;
		SelectBlocks.CancelSelection();
		TaskManager.RemoveTask(self);

		NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/EditNeuronBlockPage.lua");
		local EditNeuronBlockPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditNeuronBlockPage");
		local task = MyCompany.Aries.Game.Tasks.EditNeuronBlockPage:new({blockX = bx,blockY = by, blockZ = bz})
		task:Run();
	end
end

-- global function to fill selection with given blocks. 
-- TODO: making this function with undo manager
-- @param fill_block_id: if nil, it will be the current block.  if 0, it is fast delete. 
-- @param fill_block_data: can be nil.
function SelectBlocks.FillSelection(fill_block_id, fill_block_data)
	local self = cur_instance;
	if(self and self:HasSelection()) then
		local min = self.aabb:GetMin();
		local max = self.aabb:GetMax();

		fill_block_id = fill_block_id or GameLogic.GetBlockInRightHand()
		
		for x = min[1], max[1] do
			for y = min[2], max[2] do
				for z = min[3], max[3] do
					BlockEngine:SetBlock(x,y,z,fill_block_id, fill_block_data);
				end
			end
		end
	end
end

-- global function to delete a group of blocks. 
-- TODO: making this function with undo manager
function SelectBlocks.ReplaceBlocks(from_block_id, to_block_id)
	if(from_block_id and to_block_id and from_block_id~=to_block_id) then
		local self = cur_instance;
		if(self and self:HasSelection()) then
			local min = self.aabb:GetMin();
			local max = self.aabb:GetMax();

			local block_in_hand = GameLogic.GetBlockInRightHand()
			
			for x = min[1], max[1] do
				for y = min[2], max[2] do
					for z = min[3], max[3] do
						local id, data = BlockEngine:GetBlockIdAndData(x, y, z);
						if(id == from_block_id) then
							BlockEngine:SetBlock(x,y,z, to_block_id, data, 3);
						end
					end
				end
			end
		end
	end
end


-- make blocks in the selected aabb area solid (without hollow blocks)
-- @param fillBlockId: if nil, it will be 62 grass block. 
-- @return number of blocks filled.
function SelectBlocks.MakeSolid(fillBlockId, fillBlockData)
	local self = cur_instance;
	if(self and self:HasSelection()) then
		local min = self.aabb:GetMin();
		local max = self.aabb:GetMax();
		local minX, minY, minZ = min[1], min[2], min[3];
		local maxX, maxY, maxZ = max[1], max[2], max[3];

		-- mark block states: 0 for light, 1 for solid, 2 for hollow, -1 for unknown
		local blocks = {};
		local lightBlocks = {};
		for x = minX, maxX do
			for y = minY, maxY do
				for z = minZ, maxZ do
					local sparseIndex = BlockEngine:GetSparseIndex(x, y, z);
					local id = BlockEngine:GetBlockId(x, y, z);
					if(x == minX or x == maxX or y == minY or y == maxY or z == minZ or z == maxZ) then
						if(id > 0) then
							blocks[sparseIndex] = 1;
						else	
							lightBlocks[#lightBlocks+1] = sparseIndex;
							blocks[sparseIndex] = 0;
						end
					else
						blocks[sparseIndex] = (id > 0) and 1 or -1;
					end
				end
			end
		end
		-- for each light block, also light the nearby blocks, use a breath first search
		while(#lightBlocks > 0) do
			local sparseIndex = lightBlocks[#lightBlocks];
			lightBlocks[#lightBlocks] = nil;
			local x, y, z = BlockEngine:FromSparseIndex(sparseIndex);
			for i = 0, 5 do
				local dx, dy, dz = Direction.GetOffsetBySide(i)
				local newSparseIndex = BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz);
				if(blocks[newSparseIndex] == -1) then
					blocks[newSparseIndex] = 0;
					lightBlocks[#lightBlocks+1] = newSparseIndex;
				end
			end
		end
		-- everything else marked -1 is hollow blocks, and we shall fill it with a default block
		fillBlockId = fillBlockId or 62;
		local count = 0
		for x = minX, maxX do
			for y = minY, maxY do
				for z = minZ, maxZ do
					local sparseIndex = BlockEngine:GetSparseIndex(x, y, z);
					if(blocks[sparseIndex] == -1) then
						BlockEngine:SetBlock(x, y, z, fillBlockId, fillBlockData);
						count = count + 1;
					end
				end
			end
		end
		return count;
	end
end
