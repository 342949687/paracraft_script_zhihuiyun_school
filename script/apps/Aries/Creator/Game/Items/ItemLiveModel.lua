--[[
Title: item live model
Author(s): LiXizhi
Date: 2021/12/2
Desc: Live model entity is an iteractive model that can be moved around the scene and stacked upon one another. 
An example of Drop and drop EntityLiveModel are implemented here, see the virtual functions for details: mouseReleaseEvent, mouseMoveEvent, mousePressEvent
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local item_ = ItemLiveModel:new({block_id, text, icon, tooltip, max_count, scaling, filename, gold_count, hp, respawn_time});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_slot.lua");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Cameras = commonlib.gettable("System.Scene.Cameras");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ItemLiveModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel"));
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

ItemLiveModel:Property({"fingerRadius", 16});
-- if entity's radius is bigger than 0.3, we will not use finger picking
ItemLiveModel:Property({"maxFingerPickingRadius", 0.3});
-- between the eye lookat and the target position
ItemLiveModel:Property({"maxDragViewDistance", 90});
ItemLiveModel:Property({"isEntityAlwaysFacingCamera", true});
-- hover interval 0.2
ItemLiveModel:Property({"hoverInterval", 200});
-- pixels
ItemLiveModel:Property({"maxHoverMoveDistance", 10});
ItemLiveModel:Property({"autoTurningGridSnap", math.pi/4});

block_types.RegisterItemClass("ItemLiveModel", ItemLiveModel);

-- health point
ItemLiveModel.hp = 100;
-- respawn in 300 000 ms. 
ItemLiveModel.respawn_time = 300*1000;

function ItemLiveModel:ctor()
	self:SetOwnerDrawIcon(true);
	self.hp = tonumber(self.hp);
	self.respawn_time = tonumber(self.respawn_time);
	self.create_sound = BlockSound:new():Init({"cloth1", "cloth2", "cloth3",});
end

function ItemLiveModel:HasFacing()
	return true;
end


-- virtual function: use the item. 
function ItemLiveModel:OnUse()
end

-- virtual function: when selected in right hand
function ItemLiveModel:OnSelect(itemStack)
	ItemLiveModel._super.OnSelect(self, itemStack);
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		GameLogic.SetStatus(L"按住可以拖动模型, 点击编辑模型");
		return 
	end
	GameLogic.SetStatus(L"按住鼠标左键可以拖动模型, 右键点击编辑模型");
	
end

-- virtual function: when deselected in right hand
function ItemLiveModel:OnDeSelect()
	ItemLiveModel._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end

function ItemLiveModel:CanSpawn()
	return false;
end

-- called every frame
function ItemLiveModel:FrameMove(deltaTime)
end

function ItemLiveModel:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

function ItemLiveModel:SetModelFileName(itemStack, filename)
	if(itemStack) then
		itemStack:SetDataField("tooltip", filename);
		local xmlNode = itemStack:GetDataField("xmlNode");
		local skin,default_assets = CustomCharItems:GetSkinByAsset(filename)
		if skin then
			if not xmlNode or not xmlNode.attr then
				xmlNode = {name="entity",attr={yawOffset=0,anim=0,facing=3.14,stackHeight=0.2}}
				itemStack:SetDataField("xmlNode",xmlNode);
			end
			xmlNode.attr.skin = skin
			xmlNode.attr.filename = default_assets or CustomCharItems.defaultModelFile
		else
			itemStack:SetDataField("xmlNode", nil)
		end
		local task = self:GetTask();
		if(task) then
			task:SetItemInHand(itemStack);
			task:RefreshPage();
		end
	end
end

-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function ItemLiveModel:ConvertEntityToItem(entity, itemStack)
	if(entity and (entity:isa(EntityManager.EntityBlockModel) or entity:isa(EntityManager.EntityLiveModel)))then
		itemStack = itemStack or ItemStack:new():Init(block_types.names.LiveModel, 1);
		itemStack:SetDataField("tooltip", entity:GetModelFile())
		local node = entity:SaveToXMLNode()
		node.attr.x, node.attr.y, node.attr.z = nil, nil, nil
		node.attr.bx, node.attr.by, node.attr.bz = nil, nil, nil
		node.attr.name = nil;
		node.attr.linkTo = nil;
		node.attr.class = nil;
		node.attr.item_id = nil;
		if(entity:HasRealPhysics()) then
			node.attr.useRealPhysics = true;
		end
		itemStack:SetDataField("xmlNode", node)
		return itemStack
	end
end

-- whether we can create item at given block position.
function ItemLiveModel:CanCreateItemAt(x,y,z)
	if(ItemLiveModel._super.CanCreateItemAt(self, x,y,z)) then
		if(not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not EntityManager.HasNonPlayerEntityInBlock(x,y+1,z)) then
			return true;
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemLiveModel:DrawIcon(painter, width, height, itemStack)
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		itemStack.renderedTexturePath = ModelTextureAtlas:CreateGetModel(filename)
		
		if(itemStack.renderedTexturePath) then
			painter:SetPen("#ffffff");
			painter:DrawRectTexture(0, 0, width, height, itemStack.renderedTexturePath);
		else
			ItemLiveModel._super.DrawIcon(self, painter, width, height, itemStack);
		end
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:SetFont("System;12")
		painter:DrawText(1,0, filename);
		if(itemStack) then
			if(itemStack.count>1) then
				-- draw count at the corner: no clipping, right aligned, single line
				painter:SetPen("#000000");	
				painter:DrawText(0, height-15+1, width, 15, tostring(itemStack.count), 0x122);
				painter:SetPen("#ffffff");	
				painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
			end
		end
	else
		ItemLiveModel._super.DrawIcon(self, painter, width, height, itemStack);
	end
end


function ItemLiveModel:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity.GetModelFile and not entity:IsLocked()) then
			local filename = entity:GetModelFile();
			if(filename) then
				local itemStack = ItemStack:new():Init(self.id, 1);
				-- transfer filename from entity to item stack. 
				itemStack:SetTooltip(filename);
				if(entity.onclickEvent) then
					itemStack:SetDataField("onclickEvent", entity.onclickEvent);
				end
				return itemStack;
			end
		end
	end
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemLiveModel:CompareItems(left, right)
	if(ItemLiveModel._super.CompareItems(self, left, right)) then
		if(left and right and left:GetTooltip() == right:GetTooltip()) then
			return true;
		end
	end
end

function ItemLiveModel:OpenChangeFileDialog(itemStack)
	if(itemStack) then
		local local_filename = itemStack:GetDataField("tooltip");
		local_filename = commonlib.Encoding.Utf8ToDefault(local_filename)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
		local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
		OpenAssetFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
			if(result and result~="" and result~=local_filename) then
				result = commonlib.Encoding.DefaultToUtf8(result)
				self:SetModelFileName(itemStack, result);
			end
		end, local_filename, L"选择模型文件", "model", nil, function(filename)
			self:UnpackIntoWorld(itemStack, filename);
		end)
	end
end



-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemLiveModel:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		if((self:GetModelFileName(itemStack) or "") == "") then
			self:SelectModelFile(itemStack);
		end
	end
end

function ItemLiveModel:SelectModelFile(itemStack)
	local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
	if(selected_blocks and itemStack) then
		-- Save template:
		local last_filename = itemStack:GetDataField("tooltip");
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(L"将当前选择的方块保存为bmax文件. 请输入文件名:<br/> 例如: test", function(result)
			if(result and result~="") then
				result = commonlib.Encoding.DefaultToUtf8(result)
				local filename = result;
				local bSucceed, filename = GameLogic.RunCommand("/savemodel "..filename);
				if(filename) then
					self:SetModelFileName(itemStack, filename);
				end
			end
		end, last_filename, L"选择模型文件", "model");
	else
		self:OpenChangeFileDialog(itemStack);
	end
end

-- virtual function: 
function ItemLiveModel:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
	local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
	EditModelTask:SetItemInHand(itemStack)
	return EditModelTask:new();
end

---------------------------------
-- Drag and drop EntityLiveModel implementations
-- following methods can also be used in a scene context to achive similar functions
-- just copy and paste following methods and modify as needed in a custom scene context. 
---------------------------------

-- only entity that has physics or stackable or has mount points can receive entity drop on to it. 
-- @param entity: the target EntityLiveModel instance. 
-- @param draggingEntity: the dragging entity that will be dropped to the target entity. 
function ItemLiveModel:CanEntityReceiveModelDrop(entity, draggingEntity)
	if(entity:HasRealPhysics() or entity:IsStackable() or (entity:GetMountPointsCount() > 0)) then
		return true;
	elseif(self:CanEntityReceiveCustomCharItem(entity, draggingEntity)) then
		return true
	end
end

-- is a character entity and dragging entity is a custom char item. 
function ItemLiveModel:CanEntityReceiveCustomCharItem(entity, draggingEntity)
	if(entity:HasCustomGeosets() and draggingEntity) then
		local category = draggingEntity:GetCategory()
		if(category == "customCharItem" or draggingEntity:GetCanDrag()) then
			return true
		end
	end
end

-- @return the global result. 
function ItemLiveModel:MousePickBlock(event)
	local result = self:MousePickBlockWithFilters(event)
	if(result and result.bx) then
		local block = BlockEngine:GetBlock(result.bx, result.by, result.bz)
		if(block and not (block.obstruction or block.solid)) then
			if(not block.hasAction and block.name ~= "CornerGrass") then
				result = self:MousePickBlockWithFilters(event, 0x5)
			end
		end
	end
	return result;
end

function ItemLiveModel:MousePickBlockWithFilters(event, blockFilters)
	local result
	local lastBlockFilter = SelectionManager:GetBlockFilters()
	SelectionManager:SetBlockFilters(blockFilters)
	if(event and event:GetType() == "mousePressEvent") then
		-- we shall use finger picking for live entity smaller than 0.3
		if(GameLogic.options:HasTouchDevice() or event.touchSession) then
			local results = SelectionManager:MousePickWithFingerSize(true, true, true, nil, self.fingerRadius, nil, event.x, event.y)
			local lastMinExtent = 9999999;
			local lastEntity;
			for _, r in ipairs(results) do
				local entity = r.entity;
				if(entity and entity:isa(EntityManager.EntityLiveModel) and lastEntity~=entity) then
					local aabb = entity:GetInnerObjectAABB()
					local minExtent = aabb:GetMinExtent()
					-- if entity's radius is bigger than 0.3, we will not use finger picking
					if(minExtent < self.maxFingerPickingRadius) then
						if( (not lastEntity) or 
							(not lastEntity:GetCanDrag() and entity:GetCanDrag()) or 
							(minExtent < lastMinExtent and (lastEntity:GetCanDrag()==entity:GetCanDrag()))
						) then
							lastMinExtent = minExtent;
							lastEntity = entity
							result = r;
						end
					end
				end
			end
			if(result) then
				SelectionManager:GetPickingResult():CopyFrom(result);
			end
		end
	end
	result = result or SelectionManager:MousePickBlock(nil, nil, nil, nil, event and event.x, event and event.y);
	SelectionManager:SetBlockFilters(lastBlockFilter)
	return result;
end


-- @param event: nil or a mouse event invoking this method. 
--@return pickingResult, hoverEntity
function ItemLiveModel:CheckMousePick(event)
	local result
	-- we will try picking mounted objects first. 
	local function PickEntity_(parentEntity)
		result = self:MousePickBlock(event);

		if(result.entity and result.entity:isa(EntityManager.EntityLiveModel)) then
			local entity = result.entity;
			if(not parentEntity or parentEntity:HasLinkChild(entity)) then
				if(entity:GetLinkChildCount() > 0 and not entity:HasRealPhysics()) then
					
					self.skipEntities = self.skipEntities or {}
					self.skipEntities[entity] = true;

					local newEntity = PickEntity_(entity)
					if(not newEntity) then
						self.skipEntities[entity] = nil;
						result = self:MousePickBlock(event);
						-- double check, result.entity should always be EntityLiveModel. 
						if(result.entity and result.entity:isa(EntityManager.EntityLiveModel)) then
							entity = result.entity;
						end
					else
						return newEntity;
					end
				end
				return entity;
			end
		end
	end
	local draggingEntity = self:GetDraggingEntity(event);
	SelectionManager:SetEntityFilterFunction(function(entity)
		if(entity) then
			if(self.skipEntities and self.skipEntities[entity]) then
				return false;
			end
			if(entity:isa(EntityManager.EntityLiveModel) ) then
				if( (draggingEntity and not self:CanEntityReceiveModelDrop(entity, draggingEntity)) ) then
					-- we will filter out the given entity
					return false;
				end
			end
		end
		return true;
	end)
	self.skipEntities =  nil;
	local entity = PickEntity_()
	self.skipEntities =  nil;
	
	local newHoverEntity
	if(entity) then
		if(not draggingEntity or self:CanEntityReceiveModelDrop(entity, draggingEntity)) then
			newHoverEntity = entity;
		end
	end
	
	if(newHoverEntity)  then
		if (GameLogic.GameMode:IsEditor()) then
			local obj = newHoverEntity:GetInnerObject();
			if(obj) then	
				if(newHoverEntity:CanHighlight()) then
					ParaSelection.AddObject(obj, 1);
				else
					ParaSelection.ClearGroup(1);
				end
			end
		end
	else
		ParaSelection.ClearGroup(1);
	end
	self:SetHoverEntity(entity, event)
	return result, entity;
end

function ItemLiveModel:GetHoverEntity(event)
	if(event and event.touchSession) then
		return event.touchSession.hover_entity;
	else
		return self.hover_entity;
	end
end

function ItemLiveModel:SetHoverEntity(hover_entity, event)
	if(event and event.touchSession) then
		event.touchSession.hover_entity = hover_entity;
	end
	self.hover_entity = hover_entity;
end

function ItemLiveModel:SetMousePressEntity(mousePressEntity, event)
	if(event and event.touchSession) then
		event.touchSession.mousePressEntity = mousePressEntity;
	end
	self.mousePressEntity = mousePressEntity;
end

function ItemLiveModel:GetMousePressEntity(event)
	if(event and event.touchSession) then
		return event.touchSession.mousePressEntity;
	else
		return self.mousePressEntity;
	end
end

function ItemLiveModel:SetDraggingEntity(draggingEntity, event)
	if(event and event.touchSession) then
		event.touchSession.draggingEntity = draggingEntity;
	end
	self.draggingEntity = draggingEntity;
end

function ItemLiveModel:GetDraggingEntity(event)
	if(event and event.touchSession) then
		self.draggingEntity = event.touchSession.draggingEntity;
		return event.touchSession.draggingEntity;
	else
		return self.draggingEntity;
	end
end

function ItemLiveModel:mousePressEvent(event)
	if(event and event.touchSession and not event.touchSession:IsEnabled()) then
		self:RestoreDraggingEntity(event)
		return
	end

	Game.SelectionManager:SetEntityFilterFunction(nil)
	local result, entity = self:CheckMousePick(event)

	self:SetMousePressEntity(nil, event)
	
	if((event.alt_pressed and not event.shift_pressed and not event.ctrl_pressed) and event:button() == "left" and GameLogic.GameMode:IsEditor()) then
		-- alt + click to pick both EntityBlockModel and EntityLiveModel
		if(not entity and result.blockX) then
			local entityBlock = EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
			if(entityBlock and entityBlock:isa(EntityManager.EntityBlockModel)) then
				entity = entityBlock;
			end
		end
		if(entity) then
			local itemStack = EntityManager.GetPlayer().inventory:GetItemInRightHand()
			if(itemStack and itemStack.id == block_types.names.LiveModel) then
				self:ConvertEntityToItem(entity, itemStack)
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
				local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
				local task = EditModelTask.GetInstance()
				if(task) then
					task:UpdateValueToPage();
				end
			elseif(not result.entity:IsLocked()) then
				GameLogic.GetPlayerController():PickItemByEntity(entity);
			end
		elseif(result.block_id) then
			GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ, result.side);
		end
		event:accept();
	elseif(self:CanDragDropEntity(entity, true) and (event:button() == "left")) then
		-- only left button to drag and drop 
		self:SetMousePressEntity(entity, event);
		-- mouse left dragging only enabled when we are not dragging or clicking live model. simply accept this event to do this trick.
		event:accept();
	end

	local draggingEntity = self:GetDraggingEntity(event);
	if(draggingEntity) then
		self:DropDraggingEntity(draggingEntity, event)
	end
end

-- we will free fall into mountpoints if the horizontal distance is smaller than 0.5
-- we will also free fall into physical mesh without mount points. 
-- we will also free fall into bottom center of normal solid blocks
-- the highest point in above three conditions is used as the final drop location. 
-- @param dropLocation: {dropX, dropY, dropZ}, from which location to fall
-- @param maxFallDistance: default to 10 meters. 
-- @return true if drop location is found, and false if no drop location is found. 
function ItemLiveModel:CalculateFreeFallDropLocation(srcEntity, dropLocation, maxFallDistance)
	maxFallDistance = maxFallDistance or 10;
	local x, y, z = dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ;
	-- TODO: if the current drop location is on a vertical physical mesh face, 
	-- we need to move the location a half block size towards to the eye location, before picking new physical mesh. 
	local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y+0.1, z, 0, -1, 0, maxFallDistance)
	local lastEntity = dropLocation.target;
	local lastMountPointIndex = dropLocation.mountPointIndex;
	
	if(entity and entity:HasRealPhysics())then
		local canDropOnMountPoints;
		if(entity:GetMountPoints() and entity:GetMountPoints():GetCount() > 0) then
			-- check we will drop to the closest mount point that is lower than y
			local closestDist = 9999
			for i = 1, entity:GetMountPoints():GetCount() do
				local x2, y2, z2 = entity:GetMountPoints():GetMountPositionInWorldSpace(i)
				if(y >= y2) then
					local dist = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
					if(dist < closestDist and dist <= BlockEngine.blocksize * 0.5) then
						local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x2, y2, z2, true, entity)
						if(totalStackHeight) then
							x, y, z = x2, y2 + totalStackHeight, z2;
							dropLocation.target = entity;
							dropLocation.mountPointIndex = i;
							dropLocation.facing = entity:GetMountPoints():GetMountFacingInWorldSpace(i)
							if(srcEntity.GetYawOffset) then
								dropLocation.facing = dropLocation.facing + srcEntity:GetYawOffset();
							end
							canDropOnMountPoints = true;
						end
					end
				end
			end
		end
		if(not canDropOnMountPoints) then
			-- we will drop to physical mesh interaction point
			local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x1, y1, z1)
			if(totalStackHeight) then
				x, y, z = x1, y1+totalStackHeight, z1;
				dropLocation.target = entity;
				dropLocation.mountPointIndex = -1;
			end
		end
	end

	local aabb = srcEntity:GetInnerObjectAABB()
	local dx, _, dz = aabb:GetExtendValues()
	dx = dx * 2
	dz = dz * 2
	local maxLength = math.max(dx, dz);
	
	local block_id, solid_y, x1, y1, z1 = self:GetFirstObstructionBlockBelow(dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ)
	if(block_id) then
		if((not dropLocation.mountPointIndex) or y1 > y) then
			-- we will drop to block's bottom center
			local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x1, y1, z1)
			if(totalStackHeight) then
				x, y, z = x1, y1+totalStackHeight, z1;
				dropLocation.target = block_id;
				dropLocation.mountPointIndex = nil;
			end
			if(maxLength > BlockEngine.blocksize * 2) then
				-- we need to check if the target block (hole) is big enough for the entity. 
				local newY = self:GetFreeSpaceHeightBySize(x, y, z, maxLength)
				if(newY) then
					y = newY;
					dropLocation.y = math.max(dropLocation.y, newY);
				end
			end
		end
	elseif(not dropLocation.mountPointIndex) then
		-- no physical mesh or obstruction block to fall on. 
		return false;
	end

	dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ = x, y, z;
	return true;
end

-- get newY coordinate where (x, newY, z) is big enought for size. 
-- @param x, y, z: real world position
-- @param maxLookupDistance: if nil, default to 2. 
-- @return size: usually bigger than 1, smaller than 3. 
-- return block y position, where 
function ItemLiveModel:GetFreeSpaceHeightBySize(x, y, z, size, maxLookupDistance)
	maxLookupDistance = maxLookupDistance or 2;
	local newY = y;
	local bx, by, bz = BlockEngine:block(x, y + 0.1, z)
	local maxRadius = math.min(4, math.floor(size/BlockEngine.blocksize/2));

	local function HasFreeSpaceRadius(radius, dy)
		local innerRadius = radius - 1;
		local outerRadius = radius;
		if(outerRadius > 0) then
			local bHasOuterSpace;
			local innerRadiusSq = innerRadius^2;
			local outerRadiusSq = outerRadius^2;
			for dx=-outerRadius, outerRadius do
				for dz=-outerRadius, outerRadius do
					local distSq = dx ^ 2 + dz ^2;
					if(distSq <=innerRadiusSq) then
						local block = BlockEngine:GetBlock(bx+dx, by+dy, bz+dz)
						if((block and (block.obstruction or block.solid))) then
							return false;
						end
					elseif(distSq <= outerRadiusSq) then
						local block = BlockEngine:GetBlock(bx+dx, by+dy, bz+dz)
						if(not (block and (block.obstruction or block.solid))) then
							bHasOuterSpace = true
						end
					end
				end
			end
			return bHasOuterSpace;
		end
	end

	for dy = 0, math.floor(maxLookupDistance) do
		local block = BlockEngine:GetBlock(bx, by+dy, bz)
		if((block and (block.obstruction or block.solid))) then
			return;
		elseif(HasFreeSpaceRadius(maxRadius, dy)) then
			return y + dy * BlockEngine.blocksize;
		end
	end
end

-- we will see the target location's four directions, and if there is a nearby wall, we will return the walls facing. 
-- @param entity: this is usually the dragging entity.
-- @param x, y, z: usually the drop location of the entity. if nil, we will use the entity's current position. 
-- @param radius: default to half block size
function ItemLiveModel:GetNearbyWallFacing(entity, x, y, z, radius)
	if(not x) then
		x, y, z = entity:GetPosition()
	end
	if(not radius) then
		radius = BlockEngine.half_blocksize + 0.01;
	end
	local bx, by, bz = BlockEngine:block(x, y + 0.1, z)
	local bfx, bfy, bfz = BlockEngine:block_float(x, y+0.1, z)
	local distSqWall = 999;
	local wallSide;
	local wallFacing;
	for side = 0, 3 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local block = BlockEngine:GetBlock(bx + dx, by, bz + dz)
		if(block and block.obstruction) then
			local distSq = (dx~=0 and math.abs(bx + dx/2 + 0.5 - bfx) or math.abs(bz + dz/2 + 0.5 - bfz)) ^ 2
			if(distSq < distSqWall)  then
				distSqWall = distSq
				wallSide = side;
				wallFacing = Direction.directionTo3DFacing[wallSide]
			end
		end
		local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y, z, dx, 0, dz, radius)
		if(entity and x1) then
			local distSq = (x1 - x) ^ 2 + (z1 - z) ^ 2
			if(distSq < distSqWall)  then
				distSqWall = distSq
				wallSide = side;
				wallFacing = Direction.directionTo3DFacing[wallSide]
			end
		end
	end
	return wallFacing;
end


-- @param x, y, z: real world position, where x, z is usually near block center. 
-- return block_id, blockY, realX, realY, realZ
function ItemLiveModel:GetFirstObstructionBlockBelow(x, y, z)
	local bx, by1, bz = BlockEngine:block(x, y, z)
	y = y + 0.1
	bx, by, bz = BlockEngine:block(x, y, z)
	
	-- if first block is obstruction, we will try at most two blocks above. 
	local b = BlockEngine:GetBlock(bx, by, bz)
	local offset = 1;
	if(b and b.obstruction) then
		local bSearchUpward = true;
		if(by1 < by) then
			local b1 = BlockEngine:GetBlock(bx, by1, bz)
			if(not b1 or not b1.obstruction) then
				bSearchUpward = false;
				offset = -1;
			end
		end
		if(bSearchUpward and not b.solid) then
			local aabb = b:GetCollisionBoundingBoxFromPool(bx,by,bz)
			if(aabb and not aabb:ContainsPoint(x, y, z, 0.05)) then
				bSearchUpward = false
				local _, minY, _ = aabb:GetMinValues()
				if(y < minY) then
					offset = 0
				else
					offset = 1
				end
			end
		end
		if(bSearchUpward) then
			b = BlockEngine:GetBlock(bx, by+1, bz)
			if(b and b.obstruction) then
				b = BlockEngine:GetBlock(bx, by+2, bz)
				if(b and b.obstruction) then
					-- no drop location can be found. 
					return
				else
					offset = 2
				end
			else
				offset = 1
			end
		end
	else
		offset = 0
	end
	local block = commonlib.gettable("MyCompany.Aries.Game.block");
	local block_id, solid_y = BlockEngine:GetNextBlockOfTypeInColumn(bx,by+offset,bz, block.attributes.obstruction, maxFallDistance)
	if(block_id) then
		local x1, y1, z1 = BlockEngine:real_bottom(bx, solid_y + 1, bz)
		local blockTemplate = block_types.get(block_id);
		if(blockTemplate) then
			local aabb = blockTemplate:GetCollisionBoundingBoxFromPool(bx, solid_y, bz)
			if(aabb) then
				local _, topY, _ = aabb:GetMaxValues()
				y1 = topY;
			end
		end
		return block_id, solid_y, x1, y1, z1;
	end
end

-- return true if there is no solid blocks or physical meshes between the eye position and the given point
-- @param x,y,z: a point in 3d world space
-- @return boolean
function ItemLiveModel:CanSeePoint(x, y, z)
	local eyePos = Cameras:GetCurrent():GetEyePosition()
	local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
	local dir = mathlib.vector3d:new_from_pool(x - eyeX, y - eyeY, z - eyeZ)
	local length = dir:length();
	dir:normalize()
	local dirX, dirY, dirZ = dir[1], dir[2], dir[3];
	
	-- try picking physical mesh
	local pt = ParaScene.Pick(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length + 0.1, "point")
	if(pt:IsValid())then
		local x1, y1, z1 = pt:GetPosition()
		if((((x1-x)^2) + ((y1 - y)^2) + ((z1-z) ^2)) > 0.001) then
			return false;
		end
	end
	-- try to pick block 
	if(BlockEngine:RayPicking(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length - 0.1)) then
		return false;
	end
	return true
end


-- @param x,y,z: ray origin in world space
-- @param dirX, dirY, dirZ: ray direction, default to 0, -1, 0
-- @param maxDistance: default to 10
-- @return entityLiveModel, hitX, hitY, hitZ: return entity live model that is hit by the ray. 
function ItemLiveModel:RayPickPhysicalLiveModel(x, y, z, dirX, dirY, dirZ, maxDistance)
	local pt = ParaScene.Pick(x, y, z, dirX or 0, dirY or -1, dirZ or 0, maxDistance or 10, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity and entity:isa(EntityManager.EntityLiveModel)) then
				local x1, y1, z1 = pt:GetPosition();
				return entity, x1, y1, z1;
			end
		end
	end
end

-- get top draggable entity in vertical range (0,1), whose x, z coordinates are almost the same. 
-- please note srcEntity may already be top entity and will be returned. 
-- @return topEntity: 
function ItemLiveModel:GetTopStackEntityFromEntity(srcEntity)
	if(srcEntity) then
		local topEntity = srcEntity;
		-- for object with mount points or physics or non-stackable, or object that has attached to some other object, it is always the top entity. 
		if(not srcEntity:HasMountPoints() and not srcEntity:HasRealPhysics() and srcEntity:IsStackable() and not srcEntity:GetLinkToTarget()) then
			local x, y, z = srcEntity:GetPosition()
			local MountedEntityCount = 0;
			local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
			if(mountedEntities) then
				table.sort(mountedEntities, function(left, right)
					local _, y1, _ = left:GetPosition()
					local _, y2, _ = right:GetPosition()
					return y1 < y2;
				end)
				-- stackable object are always picked first. 
				local bFoundEntity
				for _, entity in ipairs(mountedEntities) do
					if(entity ~= topEntity and entity:GetCanDrag()) then
						local x1, y1, z1 = entity:GetPosition()
						if(not entity:IsStackable()) then
							topEntity = entity;
							y = y1;
							bFoundEntity = true
							break;
						end
					end
				end
				if(not bFoundEntity) then
					-- now check for stackable entities on top
					for _, entity in ipairs(mountedEntities) do
						if(entity ~= topEntity and entity:GetCanDrag()) then
							local x1, y1, z1 = entity:GetPosition()
							if(entity:IsStackable()) then
								if(y1 > y) then
									local distSq = ((x1 - x)^2) + ((z1 - z)^2);
									if(distSq < 0.02) then
										-- vertically stacked and with correct stack height
										if(math.abs(topEntity:GetStackHeight() + y - y1) < 0.01) then
											topEntity = entity;
											y = y1;
											bFoundEntity = true
										else
											break;
										end
									end
								end
							end
						end
					end
				end
			end
		end
		return topEntity;
	end
end

-- @param draggingEntity: the entity that is dragging
-- @param x, y, z: mount point position. 
-- @param isMountPoint: if this is a mount point
-- @param targetEntity: if the x, y, z belongs to a point on targetEntity, this is provided. 
-- @return stackHeight, stackOnEntity: the first parameter is preferred stackHeight over x, y, z: if nil, it means that we can not stack on the location. 
-- the second parameter is the top entity that is stacked on. 
function ItemLiveModel:GetStackHeightOnLocation(draggingEntity, x, y, z, isMountPoint, targetEntity)
	local totalStackHeight, stackOnEntity, stackOnEntityY;

	if(isMountPoint) then
		local isMountedEntitiesStackable;
		local MountedEntityCount = 0;
		local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
		if(mountedEntities) then
			for _, entity in ipairs(mountedEntities) do
				if(not entity:HasLinkParent(draggingEntity) and entity~=targetEntity) then
					if(entity:GetLinkToTarget() == targetEntity) then
						local x1, y1, z1 = entity:GetPosition();
						if(math.abs(x1 - x) + math.abs(z1 - z) < 0.1) then
							MountedEntityCount = MountedEntityCount + 1
							if(entity:IsStackable()) then
								totalStackHeight = (totalStackHeight or 0) + entity:GetStackHeight();
								if(not stackOnEntity or stackOnEntityY > y1) then
									stackOnEntity, stackOnEntityY = entity, y1;
								end
								isMountedEntitiesStackable = true
							end
						end
					end
				end
			end
		end
		-- do not mount on point if they are non-stackable objects
		if(MountedEntityCount == 0 or (isMountedEntitiesStackable and draggingEntity:IsStackable())) then
			return totalStackHeight or 0, stackOnEntity
		end
	else
		totalStackHeight = 0
		local isMountedEntitiesStackable;
		local MountedEntityCount = 0;
		local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
		if(mountedEntities) then
			table.sort(mountedEntities, function(left, right)
				local _, y1, _ = left:GetPosition()
				local _, y2, _ = right:GetPosition()
				return y1 < y2;
			end)
			if(targetEntity) then
				-- remove all entities below the targetTarget. 
				local count = 0
				for i, entity in ipairs(mountedEntities) do
					if(entity==targetEntity) then
						count = i;
						break;
					end
				end
				while(count > 0) do
					count = count - 1;
					commonlib.removeArrayItem(mountedEntities, 1)
				end
			end
			for _, entity in ipairs(mountedEntities) do
				if(not entity:HasLinkParent(draggingEntity) and entity~=targetEntity) then
					local x1, y1, z1 = entity:GetPosition();
					if((math.abs(x1 - x) + math.abs(z1 - z)) < 0.1) then
						MountedEntityCount = MountedEntityCount + 1
						if(entity:IsStackable() and entity:GetCanDrag()) then
							local x1, y1, z1 = entity:GetPosition()
							local distSq = ((x1 - x)^2) + ((z1 - z)^2);
							if(distSq < 0.02 and (y1-y) > -0.001 and y1 <= (y + 1)) then
								-- vertically stacked
								totalStackHeight = (totalStackHeight or 0) + entity:GetStackHeight();
								isMountedEntitiesStackable = true
								if(not stackOnEntity or stackOnEntityY > y1) then
									stackOnEntity, stackOnEntityY = entity, y1;
								end
							end
						end
					end
				end
			end
		end
		-- do not mount on point if they are non-stackable objects
		if(MountedEntityCount == 0 or (isMountedEntitiesStackable and draggingEntity:IsStackable())) then
			return totalStackHeight or 0, stackOnEntity
		else
			return 0;
		end
	end
end

-- get nearby drop points, starting from the one that is closest to the eye position. 
-- @return array of {x,y,z}, candidates for nearby drop points close to x, y, z 
function ItemLiveModel:GetNearbyBlockDropPoints(x, y, z)
	local bx, by, bz = BlockEngine:block(x, y+0.1, z);
	local eyePos = Cameras:GetCurrent():GetEyePosition()
	local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
	local dir = mathlib.vector3d:new_from_pool(eyeX - x, 0, eyeZ - z)
	local length = dir:length() - 0.1;
	dir:normalize()
	local dx = (dir[1] > 0.7) and 1 or ((dir[1] < -0.7) and -1 or 0)
	local dz = (dir[3] > 0.7) and 1 or ((dir[3] < -0.7) and -1 or 0)
	local points = {}
	points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz+dz)}
	if(math.abs(dx) == 1 and math.abs(dz) == 1) then
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz)}	
		points[#points+1] = {BlockEngine:real_bottom(bx, by, bz+dz)}
	elseif(math.abs(dx) == 1) then
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz+1)}	
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz-1)}
	else
		points[#points+1] = {BlockEngine:real_bottom(bx+1, by, bz+dz)}	
		points[#points+1] = {BlockEngine:real_bottom(bx-1, by, bz+dz)}
	end
	return points;
end

-- get nearby drop points, starting from the one that is closest to the eye position. 
-- @param targetEntity: which physical model to drop upon. 
-- @param x, y, z: this is usually a hit point on targetEntity's physical mesh. 
-- @param objRadius: default to 0.  we have to ensure that the drop point is almost flat in the given radius for the drop to be valid. 
--  this is usually the aabb radius of the dropping object in xz plane. 
--  we will sort result, where the drop point that is big enough to contain the object is moved to the front.
-- @param gridSize: default to targetEntity:GetGridSize() or 0.25.
-- @return array of {x,y,z}, candidates for nearby drop points close to x, y, z 
function ItemLiveModel:GetNearbyPhysicalModelDropPoints(targetEntity, x, y, z, objRadius, gridSize)
	if(targetEntity and targetEntity:HasRealPhysics()) then
		if(not gridSize and targetEntity.GetGridSize) then
			gridSize = targetEntity:GetGridSize()
		end
		gridSize = gridSize or (0.25 * BlockEngine.blocksize);
		
		x, z = mathlib.SnapToGrid(x, gridSize), mathlib.SnapToGrid(z, gridSize)
		local eyePos = Cameras:GetCurrent():GetEyePosition()
		local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
		local dir = mathlib.vector3d:new_from_pool(eyeX - x, 0, eyeZ - z)
		local length = dir:length() - 0.1;
		dir:normalize()
		local dx = (dir[1] > 0.7) and 1 or ((dir[1] < -0.7) and -1 or 0)
		local dz = (dir[3] > 0.7) and 1 or ((dir[3] < -0.7) and -1 or 0)
		local points = {}

		local function addPoint_(x, y, z)
			local maxFallDistance = 10;
			local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y+0.1, z, 0, -1, 0, maxFallDistance)
			if(entity == targetEntity) then
				points[#points+1] = {x1, y1, z1}
			end
		end
		addPoint_(x, y, z)
		addPoint_(x+dx*gridSize, y, z+dz*gridSize)
		if(math.abs(dx) == 1 and math.abs(dz) == 1) then
			addPoint_(x+dx*gridSize, y, z)	
			addPoint_(x, y, z+dz*gridSize)
		elseif(math.abs(dx) == 1) then
			addPoint_(x+dx*gridSize, y, z+1*gridSize)	
			addPoint_(x+dx*gridSize, y, z-1*gridSize)
		else
			addPoint_(x+1*gridSize, y, z+dz*gridSize)	
			addPoint_(x-1*gridSize, y, z+dz*gridSize)
		end
		if(objRadius and objRadius > 0.1) then
			-- sorting result, the drop point that is big enough to contain the object is moved to the front
			for index = 1, #points do
				local point = points[index];
				local x, y, z = point[1], point[2], point[3];
				local count = 6;
				local isBigEnough = true;
				-- try replacing with best height
				if(not points[1].isBigEnough or math.abs(points[1][2]-y) > math.abs(points[index][2]-y)) then
					for i = 1, count do
						local angle = math.pi * 2 / count * i;
						local x1 = x + math.cos(angle) * objRadius
						local z1 = z + math.sin(angle) * objRadius
						local maxFlatDiff = 0.2
						local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x1, y+0.1, z1, 0, -1, 0, maxFlatDiff+0.1)
						if(entity ~= targetEntity or (y1 - y) >= maxFlatDiff) then
							isBigEnough = false
							break;
						end
					end
					if(isBigEnough) then
						points[index].isBigEnough = true;
						-- try replacing with best height
						points[1], points[index] = points[index], points[1]
					end
				end
			end
		end
		return points;
	end
end

local rays = {}
function ItemLiveModel:UpdateDraggingEntity(draggingEntity, result, targetEntity, event)
	if(not result) then
		result, targetEntity = self:CheckMousePick(event)
	end
	if(draggingEntity and draggingEntity.dragParams) then
		local dragParams = draggingEntity.dragParams;
		local lastDropLocation = dragParams.dropLocation;
		local hasFound;

		-- for custom char items mounting on custom characters, we will first try using the center of the dragging entity, instead of the bottom center. 
		if(draggingEntity:GetCategory() == "customCharItem" and result.x) then
			local draggingAABB = draggingEntity:GetInnerObjectAABB()
			local eyePos = Cameras:GetCurrent():GetEyePosition()
			local x, y, z = draggingAABB:GetCenterValues();
			local dx, dy, dz = draggingAABB:GetExtendValues();
			local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
			local dir
			for i= 1, 4 do
				if(i==1) then
					dir = mathlib.vector3d:new_from_pool(x - eyeX, y - eyeY, z - eyeZ)
				elseif(i==2) then
					dir = mathlib.vector3d:new_from_pool(x - eyeX, y + dy - eyeY, z - eyeZ)
				elseif(i==3) then
					dir = mathlib.vector3d:new_from_pool(x+dx - eyeX, y - eyeY, z+dz - eyeZ)
				else
					dir = mathlib.vector3d:new_from_pool(x-dx - eyeX, y - eyeY, z-dz - eyeZ)
				end
				dir:normalize()
				rays[i] = mathlib.ShapeRay:new():init(eyePos, dir)
			end

			local bx, by, bz = draggingEntity:GetBlockPos()
			local entities = EntityManager.GetEntitiesByMinMax(bx-1, by-1, bz-1, bx+1, by+1, bz+1, EntityManager.EntityLiveModel)
			if(entities) then
				local lastDist = 9999
				local candidateEntity;
				for _, entity in ipairs(entities) do
					if(entity:HasCustomGeosets()) then
						for i=1, #rays do
							if(rays[i]:intersectsAABB(entity:GetInnerObjectAABB())) then
								local dist = entity:DistanceSqTo(bx, by, bz)
								if(dist < lastDist) then
									candidateEntity = entity;
								end
								break;
							end
						end
					end
				end
				if(candidateEntity) then
					local x, y, z = SelectionManager:GetMouseInteractionPointWithAABB(candidateEntity:GetInnerObjectAABB(), event and event.x, event and event.y);
					if(not x) then
						x, y, z = result.physicalX or result.blockRealX or result.x, result.physicalY or result.blockRealY or result.y, result.physicalZ or result.blockRealZ or result.z;
					end
					dragParams.dropLocation = {target = candidateEntity, x=x, y=y, z=z, dropX = x, dropY = y, dropZ = z, mountPointIndex = -1, isCustomCharItem = true}
					hasFound = true
				end
			end
		end

		-- finding a right location to put down.
		if(targetEntity) then
			if(not hasFound and targetEntity:GetMountPointsCount() > 0) then
				local bInside, mp, distance;
				if(targetEntity:HasRealPhysics() and result.x) then
					-- for physical model, we need to check if hit point is inside the AABB of mount points. 	
					bInside, mp = targetEntity:GetMountPoints():IsPointInMountPointAABB(result.x, result.y, result.z, 0, 0.1, 0)
				else
					mp, distance = targetEntity:GetMountPoints():GetMountPointByXY(event and event.x, event and event.y);
				end
				if(mp) then
					local x, y, z = targetEntity:GetMountPoints():GetMountPositionInWorldSpace(mp:GetIndex())
					local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, true, targetEntity)
					if(totalStackHeight) then
						local dropX, dropY, dropZ = x, y + totalStackHeight, z;
						local facing = targetEntity:GetMountPoints():GetMountFacingInWorldSpace(mp:GetIndex())
						if(targetEntity:HasRealPhysics()) then
							if(result.x) then
								x, y, z = result.x, result.y, result.z;
							end
						else
							local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB(), event and event.x, event and event.y);
							if(x1) then
								x, y, z = x1, y1, z1
							end
						end
						if(draggingEntity.GetYawOffset and facing) then
							facing = facing + draggingEntity:GetYawOffset();
						end
						dragParams.dropLocation = {target = targetEntity, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = mp:GetIndex(), mountFacing = facing}
						hasFound = true	
					end
				end
			end
			if(not hasFound and targetEntity:HasRealPhysics() and result.x) then
				-- try nearby drop points. 
				local x, y, z = result.x, result.y, result.z
				local dropX, dropY, dropZ = x, y, z;
				local radius = draggingEntity.GetDropRadius and draggingEntity:GetDropRadius();
				local points = self:GetNearbyPhysicalModelDropPoints(targetEntity, dropX, dropY, dropZ, radius)
				if(points) then
					for _, point in ipairs(points) do
						if(self:CanSeePoint(point[1], point[2], point[3])) then
							dropX, dropY, dropZ = point[1], point[2], point[3];
							hasFound = true	
							local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, false, targetEntity)
							dropY = dropY + (totalStackHeight or 0);

							local facing
							if(draggingEntity:IsAutoTurningDuringDragging()) then
								facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
								if(draggingEntity.GetYawOffset and facing) then
									facing = facing + draggingEntity:GetYawOffset();
								end
								facing = self:GetValidateFacing(facing, draggingEntity)
							end
							dragParams.dropLocation = {target = targetEntity, x=x, y=y, z=z, dropX = dropX, dropY = dropY, dropZ = dropZ, mountPointIndex = -1, facing = facing}
							break;
						end
					end
				end
			end

			-- is custom char item mounting character. 
			if(not hasFound and self:CanEntityReceiveCustomCharItem(targetEntity, draggingEntity)) then
				local x, y, z = result.x, result.y, result.z
				if(x) then
					local aabb = targetEntity:GetInnerObjectAABB()
					x, y, z = SelectionManager:GetMouseInteractionPointWithAABB(aabb, event and event.x, event and event.y);
					if(x) then
						dragParams.dropLocation = {target = targetEntity, x=x, y=y, z=z, dropX = x, dropY = y, dropZ = z, mountPointIndex = -1, isCustomCharItem = true}
						hasFound = true
					end
				end
			end

			if(not hasFound and targetEntity:GetLinkToTarget()) then
				local linkTarget = targetEntity:GetLinkToTarget()
				local x, y, z = targetEntity:GetPosition();
				if(linkTarget:GetMountPoints()) then
					local mp = linkTarget:GetMountPoints():GetMountPointByXYZ(x, y, z, true)
					if(mp) then
						local x, y, z = linkTarget:GetMountPoints():GetMountPositionInWorldSpace(mp:GetIndex())
						local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, true, linkTarget)
						if(totalStackHeight) then
							local dropX, dropY, dropZ = x, y + totalStackHeight, z;
							local facing = linkTarget:GetMountPoints():GetMountFacingInWorldSpace(mp:GetIndex())

							local bHasIntersectPoint;
							if(not targetEntity:HasRealPhysics()) then
								local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB(), event and event.x, event and event.y);
								if(x1) then
									x, y, z = x1, y1, z1
									bHasIntersectPoint = true
								end
							end
							if(not bHasIntersectPoint) then
								if(result.physicalX) then
									x, y, z = result.physicalX, result.physicalY, result.physicalZ
								elseif(result.x) then
									x, y, z = result.x, result.y, result.z;
								end
							end
							if(facing and draggingEntity.GetYawOffset) then
								facing = facing + draggingEntity:GetYawOffset();
							end
							dragParams.dropLocation = {target = targetEntity, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = mp:GetIndex(), mountFacing = facing}
							hasFound = true	
						end	
					end
				end
				if(not hasFound) then
					-- most likely, linkTarget has real physics, we will stack on top of the linked entity. 
					local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z)
					if(totalStackHeight) then
						local dropX, dropY, dropZ = x, y + totalStackHeight, z;

						local bHasIntersectPoint;
						if(not targetEntity:HasRealPhysics()) then
							local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB(), event and event.x, event and event.y);
							if(x1) then
								x, y, z = x1, y1, z1
								bHasIntersectPoint = true
							end
						end
						if(not bHasIntersectPoint) then
							if(result.physicalX) then
								x, y, z = result.physicalX, result.physicalY, result.physicalZ
							elseif(result.x) then
								x, y, z = result.x, result.y, result.z;
							end
						end
						local facing
						if(draggingEntity:IsAutoTurningDuringDragging()) then
							facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
							if(draggingEntity.GetYawOffset and facing) then
								facing = facing + draggingEntity:GetYawOffset();
							end
							facing = self:GetValidateFacing(facing, draggingEntity)
						end
						dragParams.dropLocation = {target = linkTarget, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = -1, facing = facing}
						hasFound = true	
					end
				end
			end
		end
		if(not hasFound and result.side == 4 and not targetEntity and not result.physicalX) then
			-- do not drop on bottom side of the block
			hasFound = true
			dragParams.dropLocation = nil;
		end
		if(not hasFound and result.blockX) then
			-- try free fall on to blocks, mount point or pure physical meshes. 
			-- we will only free fall on block centers even for physical meshes
			local x, y, z;
			local bx, by, bz = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side);
			
			if(result.x) then
				x, y, z = result.x, result.y, result.z;
				if(targetEntity and not targetEntity:HasRealPhysics()) then
					local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB(), event and event.x, event and event.y);
					if(x1) then
						x, y, z = x1, y1, z1
					else
						x, y, z = result.physicalX or result.blockRealX or x, result.physicalY or result.blockRealY or y, result.physicalZ or result.blockRealZ or z;
					end
				end
			else
				x, y, z = BlockEngine:real_bottom(bx, by, bz)
			end
			local dropX, dropY, dropZ = BlockEngine:real_bottom(bx, by, bz)
			dropY = y;

			-- we have to ensure that we can see the drop point without any block of physical mesh blocking it from the current eye position. 
			if(not self:CanSeePoint(dropX, dropY, dropZ)) then
				-- try nearby drop points. 
				local points = self:GetNearbyBlockDropPoints(dropX, dropY, dropZ)
				if(points) then
					for _, point in ipairs(points) do
						if(self:CanSeePoint(point[1], dropY, point[3])) then
							dropX, dropY, dropZ = point[1], dropY, point[3];
							break;
						end
					end
				end
			end
			local facing
			if(draggingEntity:IsAutoTurningDuringDragging()) then
				facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
				if(draggingEntity.GetYawOffset and facing) then
					facing = facing + draggingEntity:GetYawOffset();
				end
				facing = self:GetValidateFacing(facing, draggingEntity)
			end
			dragParams.dropLocation = {target = result.block_id, targetEntity = targetEntity, x=x, y=y, z=z, dropX = dropX, dropY = dropY, dropZ = dropZ, bx = bx, by = by, bz = bz, side = 5, facing = facing}
			if(not self:CalculateFreeFallDropLocation(draggingEntity, dragParams.dropLocation)) then
				if(false and result.blockSide and result.blockSide~=result.side and not result.physicalX) then
					-- tricky: for glass plane overlapping with another non-physical entity, we will also force trying block picking's opposite side
					dragParams.dropLocation.dropX, dragParams.dropLocation.dropY, dragParams.dropLocation.dropZ = nil, nil, nil;
					bx, by, bz = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.blockSide);
					dropX, dropY, dropZ = BlockEngine:real_bottom(bx, by, bz)
					dropY = y;
					dragParams.dropLocation.dropX, dragParams.dropLocation.dropY, dragParams.dropLocation.dropZ = dropX, dropY, dropZ;
					if(not self:CalculateFreeFallDropLocation(draggingEntity, dragParams.dropLocation)) then
						dragParams.dropLocation.dropX, dragParams.dropLocation.dropY, dragParams.dropLocation.dropZ = nil, nil, nil;
					end
				else
					dragParams.dropLocation.dropX, dragParams.dropLocation.dropY, dragParams.dropLocation.dropZ = nil, nil, nil;
				end
			end
		end
		if(dragParams.dropLocation) then
			-- make the model a bit higher than the drop location. 
			local dragDisplayOffsetY = draggingEntity:GetDragDisplayOffsetY() or 0.3;
			local x, y, z = dragParams.dropLocation.x, dragParams.dropLocation.y + dragDisplayOffsetY, dragParams.dropLocation.z;
			local oldX, oldY, oldZ = draggingEntity:GetPosition()
			
			local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos()
			local distSq = (lookatX - x)^2 + (lookatY - y)^2 + (lookatZ - z)^2
			if(distSq < (self.maxDragViewDistance^2)) then
				mouseRay = Cameras:GetCurrent():GetMouseRay(event and event.x, event and event.y, mathlib.Matrix4.IDENTITY);
				self:UpdateEntityDragPositionAndAnim(draggingEntity, x, y, z, oldX, oldY, oldZ)
			else
				dragParams.dropLocation = lastDropLocation;
			end
		end
	end
end

function ItemLiveModel:StopSmoothMoveTo(draggingEntity)
	if(draggingEntity) then
		if(draggingEntity.targetFacing_) then
			draggingEntity:SetFacing(draggingEntity.targetFacing_)
			draggingEntity.targetFacing_ = nil;
		end
		draggingEntity.motionSpeed = 0;
		self:SmoothMoveTo(draggingEntity)
	end
end

-- @param facing: targetFacing
-- @param newX, newY, newZ: target location. 
function ItemLiveModel:SmoothMoveTo(draggingEntity, facing, newX, newY, newZ)
	local bReached = true;
	if(newX) then
		draggingEntity:SetPosition(newX, newY, newZ)
	end
	-- turning speed per tick
	local turningSpeed = 0.1
	if(facing) then
		draggingEntity.targetFacing_ = facing;
		local newFacing;
		newFacing, bReached = mathlib.SmoothMoveAngle(draggingEntity:GetFacing(), facing, turningSpeed)
		draggingEntity:SetFacing(newFacing)
	end
	if(draggingEntity.targetFacing_ or newX) then
		draggingEntity.smoothAnimTimer = draggingEntity.smoothAnimTimer or commonlib.Timer:new({callbackFunc = function(timer)
			local bReached = true
			if(draggingEntity.targetFacing_) then
				local newFacing, bReached1 = mathlib.SmoothMoveAngle(draggingEntity:GetFacing(), draggingEntity.targetFacing_, turningSpeed)
				draggingEntity:SetFacing(newFacing)
				if(bReached1) then
					draggingEntity.targetFacing_ = nil;
				end
				bReached = bReached and bReached1;
			end
			if(draggingEntity.motionSpeed) then
				draggingEntity.motionSpeed = math.max(0, draggingEntity.motionSpeed - math.max((draggingEntity.motionSpeed-0.1)*0.4, 0.005));
				bReached = bReached and (draggingEntity.motionSpeed == 0);
				self:UpdateEntityAnimationByMotionSpeed(draggingEntity, draggingEntity.motionSpeed)
			end
			if(bReached) then
				draggingEntity:SetAnimation(draggingEntity:GetIdleAnim());
				timer:Change()
			end
		end})
		if(not draggingEntity.smoothAnimTimer:IsEnabled()) then
			draggingEntity.smoothAnimTimer:Change(30, 30)
		end
		self:UpdateEntityAnimationByMotionSpeed(draggingEntity, draggingEntity.motionSpeed)
	elseif(draggingEntity.smoothAnimTimer) then
		draggingEntity:SetAnimation(draggingEntity:GetIdleAnim());
		draggingEntity.smoothAnimTimer:Change()
	end
end

function ItemLiveModel:UpdateEntityAnimationByMotionSpeed(entity, motionSpeed)
	if(motionSpeed) then
		local animId = 0
		if(motionSpeed > 0.1) then
			animId = 5;
		end
		entity:SetAnimation(animId);
	end
end

-- @param entity: can be nil
function ItemLiveModel:GetValidateFacing(facing, entity)
	if(facing) then
		return mathlib.SnapToGrid(facing, self.autoTurningGridSnap)
	end
end

function ItemLiveModel:UpdateEntityDragPositionAndAnim(draggingEntity, newX, newY, newZ, oldX, oldY, oldZ)
	-- update motionSpeed;
	local dragParams = draggingEntity.dragParams;
	if(not dragParams) then
		return
	end
	draggingEntity.motionSpeed = (draggingEntity.motionSpeed or 0) + math.sqrt((newX - oldX) ^ 2) + ((newY - oldY) ^ 2) + ((newZ - oldZ) ^ 2)
	draggingEntity.motionSpeed = math.min(2, draggingEntity.motionSpeed);

	local targetFacing;
	if(draggingEntity:IsAutoTurningDuringDragging()) then
		if(dragParams.dropLocation and (dragParams.dropLocation.mountFacing or dragParams.dropLocation.facing)) then
			-- if the dragging entity is mounted on something or subject to wall facing, we will use its facing directly.
			targetFacing = dragParams.dropLocation.mountFacing or dragParams.dropLocation.facing
		else
			-- the user will drag at least this distance before we will recalculate facing relative to last position. 
			local minTurningDragDistance = 0.2
			dragParams.lastFacingX = dragParams.lastFacingX or newX
			dragParams.lastFacingZ = dragParams.lastFacingZ or newZ

			local length = math.sqrt(((newX - dragParams.lastFacingX) ^ 2) + ((newZ - dragParams.lastFacingZ) ^ 2))
			if(length > minTurningDragDistance) then
				dragParams.lastFacingX, dragParams.lastFacingZ = newX, newZ;
				targetFacing = Direction.GetFacingFromOffset(newX - oldX, 0, newZ - oldZ)
				if(draggingEntity.GetYawOffset) then
					targetFacing = targetFacing + draggingEntity:GetYawOffset();
				end
			end	
		end
		if(not dragParams.dropLocation or not dragParams.dropLocation.mountFacing) then
			targetFacing = self:GetValidateFacing(targetFacing, draggingEntity)
		end
	end
	self:SmoothMoveTo(draggingEntity, targetFacing, newX, newY, newZ)
end

-- return isHover, hoverOnEntity: the first return value is true, if it is already a hover event. 
-- the second parameter is the entity that is hovered on by the draggingEntity. 
function ItemLiveModel:UpdateOnHoverMousePointAABB(draggingEntity, event, bReset)
	draggingEntity = draggingEntity and self:GetDraggingEntity(event);
	if(not draggingEntity) then
		return;
	end
	draggingEntity.hoverTimer = draggingEntity.hoverTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if(not draggingEntity:IsDragging()) then
			timer:Change();
		else
			self:UpdateOnHoverMousePointAABB(draggingEntity)
		end
	end})
	draggingEntity.hoverTimer:Change(200, 200);
	if(bReset) then 
		draggingEntity.mousePointAABB = draggingEntity.mousePointAABB or mathlib.ShapeAABB:new();
		if(event) then
			draggingEntity.mousePointAABB:SetPointAABB(mathlib.vector3d:new({event.x, event.y, 0}))
		end
		draggingEntity.hoverBeginTime = commonlib.TimerManager.GetCurrentTime();
		draggingEntity.lastHoverDraggingEntity = draggingEntity
		draggingEntity.lastHoverOnEntity = event and self:GetHoverEntity(event) or draggingEntity.lastHoverOnEntity;
		
	elseif(draggingEntity.hoverBeginTime and draggingEntity.mousePointAABB) then
		local curHoverOnEntity = event and self:GetHoverEntity(event) or draggingEntity.lastHoverOnEntity;
		
		local curTime = commonlib.TimerManager.GetCurrentTime();
		if(event) then
			draggingEntity.mousePointAABB:Extend(event.x, event.y, 0)
		end
		local maxDiff = draggingEntity.mousePointAABB:GetMaxExtent()
		if(maxDiff > self.maxHoverMoveDistance or not curHoverOnEntity or (curHoverOnEntity~=draggingEntity.lastHoverOnEntity or draggingEntity~=draggingEntity.lastHoverDraggingEntity)) then
			draggingEntity.isHovering = nil;
			self:UpdateOnHoverMousePointAABB(draggingEntity, event, true)
		elseif( (curTime - draggingEntity.hoverBeginTime) > self.hoverInterval and draggingEntity) then
			self:UpdateOnHoverMousePointAABB(draggingEntity, event, true)
			draggingEntity.isHovering = (draggingEntity.isHovering or 0) + 1;

			local hoverOnEntity = draggingEntity.lastHoverOnEntity;
			if(type(hoverOnEntity) == "table" and hoverOnEntity.OnHover) then
				hoverOnEntity:OnHover(draggingEntity)
			end
			return true, draggingEntity.lastHoverOnEntity;
		end
	end
end

function ItemLiveModel:mouseMoveEvent(event)
	local mousePressEntity = self:GetMousePressEntity(event);
	if(mousePressEntity) then
		event:accept();
	end
	local draggingEntity = self:GetDraggingEntity(event);

	if(event and event.touchSession and not event.touchSession:IsEnabled()) then
		self:RestoreDraggingEntity(event)
		return
	end

	if(mousePressEntity and event:GetDragDist() > 20) then
		if(not draggingEntity) then
			local topEntity = self:GetTopStackEntityFromEntity(mousePressEntity)
			local bCanDrag, draggableParent;
			if(topEntity and not topEntity:HasFocus()) then
				bCanDrag, draggableParent = topEntity:GetCanDrag(true)
			end
			if(bCanDrag) then
				topEntity = draggableParent or topEntity;
				self:StartDraggingEntity(topEntity, event)
				self:UpdateOnHoverMousePointAABB(topEntity, event, true)

				if(event.ctrl_pressed and GameLogic.GameMode:IsEditor()) then
					-- Ctrl + drag to clone
					local draggingEntity = self:GetDraggingEntity(event);
					local entity = self:CloneDraggingEntityAndRestore(draggingEntity)
					if(entity) then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
						local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})
						task:CreateEntity(entity)
						if(draggingEntity.dragTask) then
							draggingEntity.dragTask:AddBatchCommand(task)
						end
					end
				end
			end
		end
	end
	if(draggingEntity) then
		-- repeat last mouse move event, just in case the camera is moving or the scene is changing
		draggingEntity.lastDragMoveEvent = draggingEntity.lastDragMoveEvent or MouseEvent:new():init("mouseMoveEvent");
		draggingEntity.lastDragMoveEvent.x, draggingEntity.lastDragMoveEvent.y = event.x, event.y
		draggingEntity.lastDragMoveEvent.touchSession = event.touchSession;

		Cameras:GetCurrent():ScheduleCameraMove(function()
			self:handleMouseMoveEventImp(draggingEntity.lastDragMoveEvent)
		end)
	end
end

-- Tricky: this function is called in ScheduleCameraMove, just before scene rendering to ensure 
-- there is no flickering when camera is moving while dragging entities. 
function ItemLiveModel:handleMouseMoveEventImp(event)
	local draggingEntity = self:GetDraggingEntity(event);
	if(draggingEntity and self:GetDraggingEntity(draggingEntity.lastDragMoveEvent) == draggingEntity and draggingEntity:IsDragging()) then
		local result, targetEntity = self:CheckMousePick(event)
		self:UpdateDraggingEntity(draggingEntity, result, targetEntity, event)
		self:UpdateOnHoverMousePointAABB(draggingEntity, event)
		self:UpdateDragReceiverHighlight(draggingEntity)

		commonlib.TimerManager.SetTimeout(function()
			Cameras:GetCurrent():ScheduleCameraMove(function()
				self:handleMouseMoveEventImp(event)
			end)
		end, 10, "ItemLiveModelMouseMoveTimer")
	end
end

-- drag and drop is disabled when the entity is being dragged or dropped. 
function ItemLiveModel:CanDragDropEntity(entity, bCheckLinkParent)
	return entity and entity.dropAnimTimer == nil and entity:GetCanDrag(bCheckLinkParent)
end

function ItemLiveModel:StartDraggingEntity(entity, event)
	local draggingEntity = self:GetDraggingEntity(event);
	if(draggingEntity) then
		self:DropDraggingEntity(draggingEntity, event)
	end
	self:SetDraggingEntity(entity, event);
	
	if(GameLogic.GameMode:IsEditor()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})
		task:StartDraggingEntity(entity);
		entity.dragTask = task;
	end
	
	local dragParams = {
		pos = {entity:GetPosition()},
		facing = entity:GetFacing(),
		linkTo = entity:GetLinkToName(),
		hasRealPhysics = entity:HasRealPhysics(),
	};
	entity:BeginDrag();
	entity:UnLink();
	entity.isHovering = nil;
	entity.dragParams = dragParams;
end

function ItemLiveModel:play_drop_sound(x,y,z)
	if(self.create_sound) then
		self.create_sound:play2d();
	end
end

function ItemLiveModel:MountEntityToTargetMountPoint(entity, mountTarget, mountPointIndex)
	if(entity and mountTarget) then
		entity:MountTo(mountTarget, mountPointIndex, true)
	end
end

-- call this during framemove 
function ItemLiveModel:UpdateDragReceiverHighlight(entity)
	local m_x, m_y = ParaUI.GetMousePosition();
	local temp = ParaUI.GetUIObjectAtPoint(m_x, m_y);
	if(temp:IsValid()) then
		local mcmlNode = pe_mc_slot.GetNodeByMousePosition(m_x, m_y, 2);
		if(mcmlNode and mcmlNode.contView) then
			local uiname = mcmlNode:GetAttributeWithCode("uiname") or ""
			if(uiname:match("^MovieClipController") or uiname:match("^ChestPage")) then
				pe_mc_slot.OnDragMove()
				return
			end
		end
	end
	pe_mc_slot.HideGlobalDragTipBox()
end

-- drop to movieclip controller's slot ui if slot is empty or it will drop to the first non-empty slot in the slot container. 
-- @return true if we are dropping on a UI slot. 
function ItemLiveModel:HandleDroppingOnUISlot(entity, dragParams)
	pe_mc_slot.HideGlobalDragTipBox()
	local m_x, m_y = ParaUI.GetMousePosition();
	local mcmlNode = pe_mc_slot.GetNodeByMousePosition(m_x, m_y, 2);
	if(mcmlNode and mcmlNode.contView and dragParams and dragParams.pos) then
		local uiname = mcmlNode:GetAttributeWithCode("uiname") or ""
		if(uiname:match("^ChestPage")) then
			local firstEmptyIndex;
			for i = 1, mcmlNode.contView:GetSlotCount() do
				local itemStack = mcmlNode.contView:GetSlotItemStack(i)
				if (not itemStack or itemStack.count == 0) then
					firstEmptyIndex = firstEmptyIndex or i;
				end
			end
			local targetIndex;
			local itemStack = mcmlNode.contView:GetSlotItemStack(mcmlNode.slot_index)
			if (not (itemStack and itemStack.count > 0)) then
				targetIndex = mcmlNode.slot_index
			else
				targetIndex = firstEmptyIndex
			end
			if(targetIndex) then
				local slot = mcmlNode.contView:GetSlot(targetIndex);
				if(not slot) then return; end
				local item = entity:GetItemClass()
				if(item) then
					local item_stack = item:ConvertEntityToItem(entity);
					slot:AddItem(item_stack);
				end
			end
			return true;
		elseif(uiname:match("^MovieClipController")) then
			-- turn into an ItemTimeSeriesNPC
			local firstEmptyIndex;
			for i = 1, mcmlNode.contView:GetSlotCount() do
				local itemStack = mcmlNode.contView:GetSlotItemStack(i)
				if (itemStack and itemStack.count > 0) then
					if (itemStack.id == block_types.names.TimeSeriesNPC) then
						local timeseries = itemStack.serverdata and itemStack.serverdata.timeseries
						if(timeseries) then
							local name = timeseries.name and timeseries.name.data and timeseries.name.data[1]
							if(name == entity:GetName()) then
								return true
							end
						end
					end
				else
					firstEmptyIndex = firstEmptyIndex or i;
				end
			end
			local targetIndex;
			local itemStack = mcmlNode.contView:GetSlotItemStack(mcmlNode.slot_index)
			if (not (itemStack and itemStack.count > 0)) then
				targetIndex = mcmlNode.slot_index
			else
				targetIndex = firstEmptyIndex
			end
			if(targetIndex) then
				local slot = mcmlNode.contView:GetSlot(targetIndex);
				if(not slot) then return; end
				local x, y, z = unpack(dragParams.pos);
				local facing = dragParams.facing;
				local assetfile = entity:GetModelFile() or entity:GetMainAssetPath();
				local skin = entity.GetSkin and entity:GetSkin()
				local timeseries = {
					name={times={0,},data={entity:GetName(),},ranges={{1,1,},},type="Discrete",name="name",},
					isAgent={times={0,},data={true,},ranges={{1,1,},},type="Discrete",name="isAgent",},
					x={times={0,},data={x,},ranges={{1,1,},},type="Linear",name="x",},
					y={times={0,},data={y,},ranges={{1,1,},},type="Linear",name="y",},
					z={times={0,},data={z,},ranges={{1,1,},},type="Linear",name="z",},
					facing={times={0,},data={facing,},ranges={{1,1,},},type="LinearAngle",name="facing",},
					scaling={times={0,},data={entity:GetScaling(),},ranges={{1,1,},},type="Linear",name="scaling",},
					assetfile={times={0,},data={assetfile},ranges={{1,1,},},type="Discrete",name="assetfile",},
				}
				timeseries.skin = skin and {times={0,},data={skin,},ranges={{1,1,},},type="Discrete",name="skin",}
				local liveEntityItem = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1, {timeseries = timeseries});
				slot:AddItem(liveEntityItem);
				-- TODO: shall we unlink? since it is controlled by movie block. 
				-- entity:UnLink()
			end
			return true;
		end
	end
end

-- drop entity to the 3d scene or on other entity or on movie clip's <pe:slot> UI item. 
-- @param callbackFunc: called when the drop operation ends. 
-- @param restoreFunc: called if not nil when restore will happen
function ItemLiveModel:DropEntity(entity, callbackFunc, restoreFunc)
	if(entity and entity:IsDropFallEnabled() and entity.dragParams) then
		local dragParams = entity.dragParams;
		local dropLocation;
		local old_x, old_y, old_z, old_facing;
		local old_linkTo;
		entity.restoreDragParams = {pos = dragParams.pos, facing = dragParams.facing, linkTo = dragParams.linkTo ,restoreFunc = restoreFunc}
		local isDroppingOnUISlot = self:HandleDroppingOnUISlot(entity, dragParams)
		if(not isDroppingOnUISlot and dragParams.dropLocation and dragParams.dropLocation.x and dragParams.dropLocation.dropX) then
			dropLocation = dragParams.dropLocation
		else
			old_x, old_y, old_z = unpack(dragParams.pos);
			old_facing = dragParams.facing;
			old_linkTo = dragParams.linkTo;
			dropLocation = {x=old_x, y=old_y, z=old_z, facing = old_facing, dropX = old_x, dropY = old_y, dropZ = old_z};
		end
		
		self:StopSmoothMoveTo(entity);
		
		local destX, destY, destZ, facing = dropLocation.dropX or dropLocation.x, dropLocation.dropY or dropLocation.y, dropLocation.dropZ or dropLocation.z, dropLocation.facing;
		-- drop animation
		local fromX, fromY, fromZ = entity:GetPosition()
		
		local t_xz = 0;
		local t_y = 0;
		local speedY = 0;
		entity.dropAnimTimer = commonlib.Timer:new({callbackFunc = function(timer)
			-- move with constant speed horizontally, and with some gravity accelerations vertically.  
			t_xz = math.min(1, t_xz + 0.2);
			t_y = math.min(1, t_y + speedY);
			speedY = speedY + 0.1;
			local x = fromX * (1 - t_xz) + destX * t_xz;
			local y = fromY * (1 - t_y) + destY * t_y;
			local z = fromZ * (1 - t_xz) + destZ * t_xz;
			entity:SetPosition(x, y, z)
			if(t_xz == 1 and t_y == 1) then
				if(dropLocation.isCustomCharItem and dropLocation.target) then
					-- only send mount event, without actually linking the dragging entity to target, the target will handle mount operation by itself. 
					dropLocation.target:OnMount(nil, nil, entity)
				elseif(dropLocation.mountPointIndex and dropLocation.target) then
					self:MountEntityToTargetMountPoint(entity, dropLocation.target, dropLocation.mountPointIndex)
				end
				timer:Change();
				entity.dropAnimTimer = nil;
				self:play_drop_sound();
				if(entity.dragTask) then
					entity.dragTask:DropDraggingEntity()
					entity.dragTask = nil;
				end
				-- restore old position
				if(old_x) then
					entity:SetPosition(old_x, old_y, old_z);
					entity:SetFacing(old_facing);
					if(old_linkTo) then
						entity:LinkToEntityByName(old_linkTo)
					end	
				end
				entity:EndDrag(dropLocation)
				
				if(callbackFunc) then
					callbackFunc(entity)
				end
			end
		end})
		entity.dropAnimTimer:Change(30, 30)

		if(self.isEntityAlwaysFacingCamera and entity:IsAutoTurningDuringDragging()) then
			if(not facing and not dropLocation.mountFacing and not (entity.isHovering and entity.isHovering >= 2)) then
				-- we will always face the camera, if auto facing is enabled and entity is not mounted or has wall facing. 
				-- and it is not hovering at the drop location. 
				facing = Direction.GetFacingFromCamera(nil, nil, nil, destX, destY, destZ) + math.pi
				if(entity.GetYawOffset) then
					facing = facing + entity:GetYawOffset();
				end
				facing = self:GetValidateFacing(facing, entity)
			end
		end

		if(facing) then
			entity:SetFacing(facing);
		end
	elseif(entity) then
		-- just leave as it is
		entity:EndDrag()
		if(callbackFunc) then
			callbackFunc(entity)
		end
	end
end

-- collecting user stats
function ItemLiveModel:SendUserStats(entity, dragParams)
	if(not GameLogic.GameMode:IsEditor()) then
		local mountTargetName, mountPointIndex, dropX, dropY, dropZ;
		if(dragParams and dragParams.dropLocation) then
			if(type(dragParams.dropLocation.target) == "table") then
				mountTargetName = dragParams.dropLocation.target.name;
			else
				mountTargetName = dragParams.dropLocation.target
			end
			mountPointIndex = dragParams.dropLocation.mountPointIndex
			dropX = dragParams.dropLocation.dropX
			dropY = dragParams.dropLocation.dropY
			dropZ = dragParams.dropLocation.dropZ
		end
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.live_model.drag", { 
			projectId = GameLogic.options:GetProjectId() or 0, 
			filename = entity:GetModelFile(), 
			name = entity:GetName(),
			mname = mountTargetName,
			mindex = mountPointIndex,
			dx = dropX, dy = dropY, dz = dropZ,
		});
	end
end

function ItemLiveModel:DropDraggingEntity(draggingEntity, event, callbackFunc,restoreFunc)
	local entity = draggingEntity or self:GetDraggingEntity(event);
	if(entity) then
		local dragParams = entity.dragParams
		if(dragParams) then
			self:DropEntity(entity, callbackFunc,restoreFunc)
			entity.dragParams = nil;
		end
		self:SetDraggingEntity(nil, event);
		self:SendUserStats(entity, dragParams)
	end
	Game.SelectionManager:SetEntityFilterFunction(nil)
end

function ItemLiveModel:RestoreDraggingEntity(event)
	local entity = self:GetDraggingEntity(event);
	if(entity and entity.dragParams) then
		entity.dragParams.dropLocation = nil;
		self:DropDraggingEntity(entity, event)
	end
end

-- only spawn entity if player is holding a LiveModel item in right hand. 
-- @param serverdata: default to item stack in player's hand item
function ItemLiveModel:SpawnNewEntityModel(bx, by, bz, facing, serverdata)
	local filename, xmlNode;
	if(not serverdata) then
		local itemStack = EntityManager.GetPlayer().inventory:GetItemInRightHand()
		if(itemStack and itemStack.id == block_types.names.LiveModel) then
			filename = itemStack:GetDataField("tooltip");
			xmlNode = itemStack:GetDataField("xmlNode");
			if(xmlNode and xmlNode.attr) then
				xmlNode.attr.x = nil;
				xmlNode.attr.y = nil;
				xmlNode.attr.z = nil;
				xmlNode.attr.bx = nil;
				xmlNode.attr.by = nil;
				xmlNode.attr.bz = nil;
				xmlNode.attr.name = nil;
				xmlNode.attr.linkTo = nil;
				xmlNode.class = nil;
				xmlNode.item_id = nil;
			end
		end
	end
	if(not filename or filename == "") then
		return;
	end
	if (not facing) then
		facing = Direction.GetFacingFromCamera()
		facing = Direction.NormalizeFacing(facing)
	end
	local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by,bz=bz, 
		item_id = block_types.names.LiveModel, facing=facing}, xmlNode);
	if(not xmlNode) then
		entity:SetModelFile(filename)
	end
	entity:Refresh();
	entity:Attach();
	return entity
end

--@return the cloned entity
function ItemLiveModel:CloneDraggingEntityAndRestore(entity)
	-- clone the dragging entity if ctrl key is pressed. 
	if(entity and entity.dragParams) then
		local old_x, old_y, old_z, old_facing;
		local old_linkTo;
			
		old_x, old_y, old_z = unpack(entity.dragParams.pos);
		old_facing = entity.dragParams.facing;
		old_linkTo = entity.dragParams.linkTo;
		-- restore old position
		if(old_x) then
			local entity = entity:CloneMe()
			entity:SetPosition(old_x, old_y, old_z);
			entity:SetFacing(old_facing);
			if(old_linkTo) then
				entity:LinkToEntityByName(old_linkTo)
			end	
			return entity;
		end
	end
end

-- whether filename is a block template file. 
function ItemLiveModel:IsBlockTemplate(filename)
	return filename and filename:match("%.blocks%.xml$") and true;
end

function ItemLiveModel:mouseReleaseEvent(event)
	if(event and event.touchSession and not event.touchSession:IsEnabled()) then
		self:RestoreDraggingEntity(event)
		return
	end
	local result, targetEntity = self:CheckMousePick(event)
	
	local draggingEntity = self:GetDraggingEntity(event);
	if(draggingEntity) then
		self:DropDraggingEntity(draggingEntity, event);
		event:accept();
	else
		if(event.ctrl_pressed and not event.shift_pressed and event:isClick() and GameLogic.GameMode:IsEditor()) then
			-- ctrl + left click to select block in edit mode
			if(event:button() == "left") then
				Game.SelectionManager:SetEntityFilterFunction(nil)

				local result = self:MousePickBlock(event)
				if(result and result.blockX) then
					local bx, by, bz = result.blockX, result.blockY, result.blockZ
					if(result.entity) then
						bx, by, bz = result.entity:GetBlockPos();
					end
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
					local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
					if(SelectBlocks.GetCurrentInstance()) then
						SelectBlocks.GetCurrentInstance().ExtendAABB(bx, by, bz)
					else
						local task = SelectBlocks:new({blockX = bx, blockY = by, blockZ = bz})
						task:Run();
					end
					event:accept();
				end
			end
		elseif(not event.ctrl_pressed and event.shift_pressed and event:isClick()) then
			-- Do nothing to allow leaking to default context
		elseif(not event.ctrl_pressed and event:isClick()) then
			local normalTargetEntity;
			if(GameLogic.GameMode:IsEditor() and event:button() == "right") then
				-- just in case, we right click to edit a non-pickable live entity model
				Game.SelectionManager:SetEntityFilterFunction(nil)
				local result = self:MousePickBlock(event)
				if(result) then
					normalTargetEntity = result.entity
				end
			end			
			local clickEntity = normalTargetEntity or targetEntity
			if(clickEntity and clickEntity:isa(EntityManager.EntityLiveModel)) then
				if(clickEntity:OnClick(result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side)) then
					event:accept();
				end
			elseif(event:button() == "right" or (event:button() == "left" and GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false))) then
				if(result.block_id and result.block_id>0) then
					-- if it is a right click, first try the game logics if it is processed. such as an action neuron block.
					if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
						-- this fixed a bug where block entity is larger than the block like the physics block model.
						local bx, by, bz = result.entity:GetBlockPos();
						isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
					else
						isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
					end
				end
				if(not isProcessed) then
					if(result.blockX and result.side) then
						local itemStack = EntityManager.GetPlayer().inventory:GetItemInRightHand()
						if(itemStack and itemStack.id == block_types.names.LiveModel) then
							local loadPath = itemStack:GetDataField("loadPath");
							if loadPath and loadPath~= "" then
								local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
								GameLogic.RunCommand(string.format("/loadtemplate -rename %s %d %d %d %s",true,bx,by,bz,loadPath))
								event:accept();
							else
								local local_filename = itemStack:GetDataField("tooltip");
								local filename = local_filename;
								if (filename and not self:IsBlockTemplate(filename) and filename:match("^temp/onlinestore/")) then
									filename = commonlib.Encoding.Utf8ToDefault(filename)
									local _filename = "onlinestore/"..filename:match("[^/\\]+$")
									if(ParaIO.DoesFileExist(Files.GetWritablePath()..filename, true)) then
										if ParaIO.CopyFile(Files.GetWritablePath()..filename, Files.WorldPathToFullPath(_filename), true) then
											itemStack:SetTooltip(commonlib.Encoding.DefaultToUtf8(_filename))
											NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
											local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
											if(EditModelTask.GetInstance()) then
												EditModelTask.GetInstance():RefreshPage()
											end
											filename = _filename
											local_filename = commonlib.Encoding.DefaultToUtf8(_filename)
											Files.FindFile(filename);
											filename = Files.WorldPathToFullPath(filename)
										end
									end
								end
								local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
								local entity = self:SpawnNewEntityModel(bx, by, bz)
								if(entity) then
									-- let it fall down: simulate a drag and drop at click point
									self:StartDraggingEntity(entity, event)
									self:UpdateDraggingEntity(entity, result, targetEntity, event)
									self:DropDraggingEntity(entity, event);
									if(entity.dragTask) then
										entity.dragTask:SetCreateMode()
									end
									event:accept();
								end
							end
						end
					end
				else
					event:accept();
				end
			end
		end	
	end
	
	if(self:GetMousePressEntity(event)) then
		self:SetMousePressEntity(nil, event);
		event:accept();
	end
	Game.SelectionManager:SetEntityFilterFunction(nil)
	self:SetHoverEntity(nil, event);
end
