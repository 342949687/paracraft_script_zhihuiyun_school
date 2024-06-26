--[[
Title: EditModel Task/Command
Author(s): LiXizhi
Date: 2016/8/30
Desc: There are two modes.
- create mode: this is the default mode which uses the default scene context
- transform mode: use a special scene context
	- left click to select model in the 3d scene
	- TODO: use manipulators to scale, rotate the model
	- TODO: a timer is used to highlight all Model blocks near the player
	- TODO: support undo/redo

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by,bz=bz,});
entity:SetModelFile(filename)
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditModelTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask"));

local curInstance;

-- this is always a top level task. 
EditModelTask.is_top_level = true;

function EditModelTask:ctor()
	self.position = vector3d:new(0,0,0);
	self.transformMode = false;
	self.isWorldTransform = true;
	self.show_drag_bt = true
end

local page;
function EditModelTask.InitPage(Page)
	page = Page;
end

-- get current instance
function EditModelTask.GetInstance()
	return curInstance;
end

-- by default it is in select and create mode. 
function EditModelTask:IsTransformMode()
	return self.transformMode;	
end

-- enable transform mode
function EditModelTask:SetTransformMode(bEnable)
	bEnable	= bEnable == true or bEnable==nil;
	if(self.transformMode ~= bEnable) then
		self.transformMode = bEnable;
		if(EditModelTask.GetInstance()) then
			if(bEnable) then
				self:LoadSceneContext();
				self:GetSceneContext():setMouseTracking(true);
				self:GetSceneContext():setCaptureMouse(true);
			else
				self:SelectModel(nil);
				self:UnloadSceneContext();
			end
			self:RefreshPage();
		end
	end
end

-- static page event handler
function EditModelTask.OnClickToggleMode()
	local self = EditModelTask.GetInstance();
	self:SetTransformMode(not self:IsTransformMode());
end

function EditModelTask:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function EditModelTask:Run()
	curInstance = self;
	self.finished = false;
	if(self:IsTransformMode()) then
		self:LoadSceneContext();
		self:GetSceneContext():setMouseTracking(true);
		self:GetSceneContext():setCaptureMouse(true);
	end
	self:ShowPage();
end

function EditModelTask:OnExit()
	self:SelectModel(nil);
	self:SetFinished();
	self:UnloadSceneContext();
	self:CloseWindow();
	curInstance = nil;
	page = nil;
	self.modelManip = nil;
end

function EditModelTask:UpdateUIFromModel()
	if(self.entityModel and page and not self.isChangingFromUI) then
		page:Refresh(1);
	end
end

function EditModelTask:SelectModel(entityModel)
	if(self.entityModel~=entityModel) then
		self.isWorldTransform = true;
		if(self.entityModel) then
			if(self.entityModel.isLastSkipPicking==false) then
				self.entityModel:SetSkipPicking(false);
			end
			self.entityModel:Disconnect("valueChanged", self, self.UpdateUIFromModel)
		end

		self.entityModel = entityModel;
		if(entityModel) then
			entityModel.isLastSkipPicking = entityModel:IsSkipPicking();
			if(not entityModel.isLastSkipPicking) then
				entityModel:SetSkipPicking(true);
			end
			self.entityModel:Connect("valueChanged", self, self.UpdateUIFromModel, "UniqueConnection")
		end
		self:UpdateManipulators();
	end
end

function EditModelTask.GetItemID()
	local self = EditModelTask.GetInstance();
	if self then
		if(self:GetSelectedModel()) then
			return self:GetSelectedModel():GetItemId()
		else
			if(self.itemInHand) then
				return self.itemInHand.id
			end
		end
	end
end

function EditModelTask:GetSelectedModel()
	return self.entityModel;
end

-- it will first try to reset only local transform if it is not identity. 
function EditModelTask.OnResetModel()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel();
		if(entity) then
			local bIsDynamicPhysics;
			if(entity:IsDynamicPhysicsEnabled()) then
				bIsDynamicPhysics = true;
				entity:EnableDynamicPhysics(false)
			end
			local matLocal = entity:GetModelLocalTransform()
			if(not matLocal or matLocal:isIdentity()) then
				entity:setYaw(0);
				entity:SetRoll(0);
				entity:SetPitch(0);
				entity:setScale(1);
				if(entity.SetOffsetPos) then
					entity:SetOffsetPos({0,0,0});
				end
			else
				entity:SetModelLocalTransform(nil);
			end
			if(bIsDynamicPhysics) then
				entity:EnableDynamicPhysics(true)
			end
		end
	end
end

function EditModelTask:UpdateManipulators()
	self:DeleteManipulators();
	self.modelManip = nil;
	if(self.entityModel) then
		if(self:IsWorldTransformMode()) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelManipContainer.lua");
			local EditModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer");
			local manipCont = EditModelManipContainer:new();
			manipCont:init();
			self:AddManipulator(manipCont);
			self.modelManip = manipCont;
			manipCont:connectToDependNode(self:GetSelectedModel());
		else
			NPL.load("(gl)script/ide/System/Scene/Manipulators/LocalTransformManipContainer.lua");
			local LocalTransformManipContainer = commonlib.gettable("System.Scene.Manipulators.LocalTransformManipContainer");

			local manipCont = LocalTransformManipContainer:new():init();
			self:AddManipulator(manipCont);
			manipCont:connectToDependNode(self:GetSelectedModel());
		end

		self:RefreshPage();
	end
end

function EditModelTask:Redo()
end

function EditModelTask:Undo()
end

function EditModelTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		local window = self:CreateGetToolWindow();
		window:Show({
			name="EditModelTask", 
			url="script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.html",
			alignment="_ctb", left=52, top= -110, width = 700, height = 96, parent = parent
		});
		window:SetUIScaling(1.5,1.5)
		return 
	end
	local window = self:CreateGetToolWindow();
	window:Show({
		name="EditModelTask", 
		url="script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.html",
		alignment="_ctb", left=0, top= -55, width = 420, height = 64, parent = parent
	});
end

function EditModelTask.IsLiveAndPersistent()
	local self = EditModelTask.GetInstance();
	if(self and self.entityModel) then
		if(self.entityModel:IsPersistent() and self.entityModel:isa(EntityManager.EntityLiveModel)) then
			return true
		end
	end
end

function EditModelTask.OpenCodeEditor()
	local self = EditModelTask.GetInstance();
	if(self and self.entityModel) then
		if(not self.entityModel:OpenCodeEditor() and self.entityModel:IsPersistent() and self.entityModel:isa(EntityManager.EntityLiveModel)) then
			local name = self.entityModel:GetName() or ""
			if(name:match("^%d+")) then
				GameLogic.AddBBS(nil, L"请先给角色取个名字，不要以数字开头", 3000, "255 0 0")
				EditModelTask.OnClickProperty();
			else
				_guihelper.MessageBox(format(L"%s 没有同名的代码方块，是否在当前位置创建代码方块?", name), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						local codeEntity = self:CreateCodeBlockWithSameName()
						if(self.entityModel) then
							self.entityModel:OpenCodeEditor()
						end
					end
				end, _guihelper.MessageBoxButtons.YesNo)
			end
		end
	end
end

function EditModelTask:CreateCodeBlockWithSameName()
	if(self.entityModel) then
		local bx, by, bz = EntityManager.GetPlayer():GetBlockPos();
		local block_id1 = BlockEngine:GetBlockId(bx, by, bz);
		local block_id2 = BlockEngine:GetBlockId(bx-1, by, bz);
		local block_id3 = BlockEngine:GetBlockId(bx+1, by, bz);
		local block_id4 = BlockEngine:GetBlockId(bx, by, bz-1);
		if(block_id1 == 0 and block_id2 == 0 and block_id3 == 0 and block_id4 == 0) then
			local name = self.entityModel:GetName() or ""

			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blocks = {
				{bx, by, bz, block_types.names.CodeBlock, nil, {attr={isDeferLoad=true, displayName=name, isBlocklyEditMode=false, isUseNplBlockly=true}, {name = "cmd", "-- TODO \n"}}},
				{bx, by, bz-1, block_types.names.Sign_Post, 3, {attr = {}, {name = "cmd", name}}},
				{bx+1, by, bz, block_types.names.CodeBlock, nil, {attr={isBlocklyEditMode=false, isUseNplBlockly=true}, {name = "cmd", string.format('becomeAgent(%q)\n', name)}}},
				{bx-1, by, bz, block_types.names.Lever, 13}, -- data: 13 powered, 5 non-powered
			}, liveEntities=nil})
			task:Run();
		else
			GameLogic.AddBBS(nil, L"请在空旷的地方创建代码方块", 3000, "255 0 0")
		end
	end
end

-- @param result: can be nil
function EditModelTask:PickModelAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local modelEntity = BlockEngine:GetBlockEntity(x,y,z) or result.entity;
		if(modelEntity and (modelEntity:isa(EntityManager.EntityBlockModel) or modelEntity:isa(EntityManager.EntityLiveModel))) then
			return modelEntity;
		end
	end
end

function EditModelTask:handleLeftClickScene(event, result)
	if(not event:IsCtrlKeysPressed()) then
		local modelEntity = self:PickModelAtMouse();
		if(modelEntity) then
			self:SelectModel(modelEntity);
			self:SetTransformMode(true);
		else
			self:SetTransformMode(false);
		end
	else
		if(event.alt_pressed and result) then
			-- alt + left click to get the block in hand without destroying it
			if(result.block_id and result.block_id~=0 and result.blockX) then
				GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ, result.side);
			elseif(result.entity and not result.entity:IsLocked()) then
				GameLogic.GetPlayerController():PickItemByEntity(result.entity);
			end
		end
	end
	event:accept();
end

function EditModelTask:handleRightClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		local ctrl_pressed = System.Windows.Keyboard:IsCtrlKeyPressed();
		if(ctrl_pressed) then
			modelEntity:OpenEditor("entity", modelEntity);
		else
			self:SelectModel(modelEntity);
			self:SetTransformMode(true);
		end
	else
		self:SetTransformMode(false);
	end
	event:accept();
end

function EditModelTask:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function EditModelTask:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function EditModelTask:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ADD" or dik_key == "DIK_EQUALS") then
		-- increase scale
		
	elseif(dik_key == "DIK_SUBTRACT" or dik_key == "DIK_MINUS") then
		-- decrease scale
	elseif(dik_key == "DIK_T")then	
		self:OnClickToggleTransformMode()
	elseif(dik_key == "DIK_Z")then
		UndoManager.Undo();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
	end
	self:GetSceneContext():keyPressEvent(event);
end

function EditModelTask:SetItemInHand(itemStack)
	self.itemInHand = itemStack;
end

function EditModelTask:GetModelFileInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("tooltip");
	end
end

function EditModelTask:GetOnClickEventInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("onclickEvent");
	end
end

function EditModelTask.OnClickChangeModelFile()
	local self = EditModelTask.GetInstance();
	if(self and self.itemInHand) then
		local item = self.itemInHand:GetItem();
		if(item and item.SelectModelFile) then
			item:SelectModelFile(self.itemInHand);
		end
	end
end

function EditModelTask:UpdateValueToPage()
	local modelEntity = self:GetSelectedModel()
	if(modelEntity) then
		local mountPivot = modelEntity:GetTagField("mountPivot")
		local mountPivot_checked = modelEntity:GetTagField("mountPivot_checked")
		local mountCount = EditModelTask.GetMountPointCount()
		if mountPivot and mountPivot_checked and tonumber(mountCount) == 0 then
			EditModelTask.OnMountPointCountChanged(1)
			local mountPoint = modelEntity:GetMountPoints():GetMountPoint(1)
			if mountPoint then
				mountPoint:SetFacing(modelEntity:GetFacing())
				local scaling = modelEntity:GetScaling() or 1
				local aabb = modelEntity:GetInnerObjectAABB()
				local dx,dy,dz = aabb:GetExtendValues();
				mountPoint:SetAABBSize((dx * 2)/scaling, (dy*2)/scaling, (dz * 2)/scaling)
				if mountPivot == "top" then
					mountPoint:SetPivot({0,(dy * 2)/scaling,0})
				elseif mountPivot == "mid" then
					mountPoint:SetPivot({0,dy/scaling,0})
				elseif mountPivot == "bottom" then
					mountPoint:SetPivot({0,0,0})
				end
			end
		end

		local needPhysics = modelEntity:GetTagField("needPhysics")
		local needPhysics_checked = modelEntity:GetTagField("needPhysics_checked")
		if needPhysics and needPhysics_checked and not modelEntity:HasRealPhysics()then
			EditModelTask.OnClickTogglePhysics()
		end
	end
	self:RefreshPage()
end

function EditModelTask:GetFacingDegree()
	local facing = 0;
	local modelEntity = self:GetSelectedModel()
	if(modelEntity) then
		facing = modelEntity:GetFacing();
	end
	return math.floor(mathlib.WrapAngleTo180(facing/math.pi*180)+0.5);
end

function EditModelTask:SetFacingDegree(degree)
	local modelEntity = self:GetSelectedModel()
	if(modelEntity and degree) then
		modelEntity:SetFacing(mathlib.ToStandardAngle(degree/180*math.pi));
	end
end

function EditModelTask.OnFacingDegreeChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		self.isChangingFromUI = true;
		self:SetFacingDegree(tonumber(text));
		self.isChangingFromUI = false;
	end
end

function EditModelTask.OnScalingChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity.setScale and text) then
			local scaling = tonumber(text);
			if(scaling and scaling >= (modelEntity.minScale or 0.1) and scaling <= (modelEntity.maxScale or 10)) then
				self.isChangingFromUI = true;
				modelEntity:setScale(scaling);
				self.isChangingFromUI = false;
			end
		end
	end
end

function EditModelTask.OnChangeOnClickEvent(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity.SetOnClickEvent and text) then
			if(text == "") then
				text = nil
			end
			modelEntity:SetOnClickEvent(text)
		end
	end
end

function EditModelTask.OnClickTogglePhysics()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			local modelEntityNew = modelEntity:EnablePhysics(not modelEntity:HasRealPhysics())
			if(modelEntityNew ~= modelEntity and type(modelEntityNew) == "table") then
				self:SelectModel(modelEntityNew)
			end
			self:UpdateValueToPage()
		end
	end
end

function EditModelTask.GetMountPointCount()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity:GetMountPoints()) then
			return modelEntity:GetMountPoints():GetCount()
		end
	end
	return 0
end

function EditModelTask.OnMountPointCountChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		text = tonumber(text)
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity:GetMountPointsCount() ~= text) then
			if(text == 0) then
				if(modelEntity:GetMountPoints()) then
					modelEntity:GetMountPoints():Clear()
				end
			elseif(text) then
				local maxCount = 9;
				if(text > 0 and text <= maxCount) then
					modelEntity:CreateGetMountPoints():Resize(text)
				elseif(page) then
					page:SetUIValue("mountpointCount", maxCount);
				end
			end
			self:UpdateManipulators();
		end
	end
end

function EditModelTask.OnClickDeleteModel()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			if modelEntity:IsLocked() then
				GameLogic.AddBBS(nil, L'模型被锁定无法删除', 5000, '0 255 0')
				return
			end

			self:SetTransformMode(false);
			
			if(GameLogic.GameMode:IsEditor()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
				local dragTask = MyCompany.Aries.Game.Tasks.DragEntity:new({})
				dragTask:DeleteEntity(modelEntity)
			end
			modelEntity:SetDead();
		end
	end
end

function EditModelTask.IsHaveSkin()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel()
		if(entity) then
			if entity.class_name ~= "LiveModel" then
				return true
			end
			return (entity.IsCustomModel and entity:IsCustomModel()) or (entity.HasCustomGeosets and entity:HasCustomGeosets())
		end
	end
	return false
end

function EditModelTask.OnChangeModel()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel()
		if(entity and entity.GetModelFile) then
			local old_value = entity:GetModelFile()
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
			local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
			OpenAssetFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
				if(result and result~="" and result~=old_value) then
					entity:SetModelFile(commonlib.Encoding.DefaultToUtf8(result))
					self:RefreshPage()
				end
			end, old_value, L"选择模型文件", "model")
		end
	end
end

function EditModelTask.OnChangeSkin()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel()
		if(entity) then
			local assetFilename = entity:GetMainAssetPath();
			if entity.GetSkin then
				local old_value = entity:GetSkin();
			end

			if(entity.IsCustomModel and entity:IsCustomModel()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/EditCCSTask.lua");
				local EditCCSTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCCSTask");
				EditCCSTask:ShowPage(entity, function(ccsString)
					if(ccsString ~= old_value) then
						GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
							if(isVip) then
								entity:SetSkin(ccsString);
							end
						end)
					end
				end);
			elseif(entity.HasCustomGeosets and entity:HasCustomGeosets()) then
				local old_value = entity:GetSkin()
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
				local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
				CustomSkinPage.ShowPage(function(filename, skin)
					if (filename and skin~=old_value) then
						entity:SetSkin(skin);
					end
				end, old_value,assetFilename);
			else
				assetFilename = PlayerAssetFile:GetNameByFilename(assetFilename)
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
				local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
				EditSkinPage.ShowPage(function(result)
					if(result and result~=old_value) then
						GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
							if(isVip) then
								entity:SetSkin(result);
							end
						end)
					end
				end, old_value, "", assetFilename)
			end
		end
	end
end

function EditModelTask.OnClickProperty()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
			local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
			EditModelProperty.ShowForEntity(modelEntity, function(entity)
				local self = EditModelTask.GetInstance();
				if(self) then
					self:SelectModel(entity)
					self:UpdateValueToPage()
				end
			end)
		end
	end
end

function EditModelTask.OnChangeModelType()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			if(self.itemInHand) then
				local oldX, oldY, oldZ = modelEntity:GetPosition();
				if(self.itemInHand.id == block_types.names.BlockModel or self.itemInHand.id == block_types.names.PhysicsModel) then
					-- TODO: convert from physical model to live model
					
				elseif(self.itemInHand.id == block_types.names.LiveModel) then
					-- TODO: convert from live model to physical model

				end
			end
		else
			-- toggle between physical and non-physical block model. 
			if(self.itemInHand) then
				local itemStack = self.itemInHand:Copy();
				if(self.itemInHand.id == block_types.names.BlockModel) then
					itemStack.id = block_types.names.PhysicsModel;
				elseif(self.itemInHand.id == block_types.names.PhysicsModel) then
					itemStack.id = block_types.names.LiveModel;
				elseif(self.itemInHand.id == block_types.names.LiveModel) then
					itemStack.id = block_types.names.BlockModel;
				end
				GameLogic.GetPlayerController():SetBlockInRightHand(itemStack, true)
			end
		end
	end
end

function EditModelTask.GetDraggableText()
	local self = EditModelTask.GetInstance();
	if(self) then
		if(self.itemInHand) then
			if(self.itemInHand.id == block_types.names.LiveModel) then
				return L"可拖动";
			else
				return L"不可拖动";
			end
		end
	end
end

function EditModelTask.OnClickChangeDraggable()
	local self = EditModelTask.GetInstance();
	if(self) then
		if(self.itemInHand) then
			local itemStack = self.itemInHand:Copy();
			if(self.itemInHand.id == block_types.names.BlockModel) then
				itemStack.id = block_types.names.LiveModel;
			elseif(self.itemInHand.id == block_types.names.PhysicsModel) then
				itemStack.id = block_types.names.LiveModel;
			elseif(self.itemInHand.id == block_types.names.LiveModel) then
				itemStack.id = block_types.names.BlockModel;
			end
			GameLogic.GetPlayerController():SetBlockInRightHand(itemStack, true)
		end
	end
end

-- @param sectionIndex: if nil, we will return full name, otherwise it will break into sections. 
-- if 1 it will resturn model file, if 2 it will return unique name
function EditModelTask:GetLongDisplayName(sectionIndex)
	local model = self:GetSelectedModel()
	local name;
	if(model) then
		if(sectionIndex == 1 and model.GetModelFile) then
			name = model:GetModelFile() or ""
		elseif(sectionIndex == 2) then
			name = model:GetName() or ""
		else
			name = model:GetDisplayName();
		end
	end
	return name;
end

function EditModelTask:IsWorldTransformMode()
	return self.isWorldTransform;
end

function EditModelTask:SetDragBtVisible(flag)
	self.show_drag_bt = flag
end

function EditModelTask:GetDragBtVisible()
	return self.show_drag_bt
end

function EditModelTask.OnClickToggleTransformMode()
	local self = EditModelTask.GetInstance();
	if(self) then
		self.isWorldTransform = not self.isWorldTransform;
		self:UpdateManipulators()
	end
end

function EditModelTask.OnClickToggleRotationMode()
	local self = EditModelTask.GetInstance();
	if(self and self.modelManip) then
		self.modelManip:ToggleRotationMode()
	end
end