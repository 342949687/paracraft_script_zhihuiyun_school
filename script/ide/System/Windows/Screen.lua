--[[
Title: Screen
Author(s): LiXizhi, big
CreateDate: 2015.8.20
ModifyDate: 2022.2.16
Desc: a singleton class for current screen. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
echo({Screen:GetWidth(), Screen:GetHeight(), Screen:GetUIScaling()})
Screen:ChangeUIDesignResolution(1280, 720)
Screen:RestoreUIDesignResolution()
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local Screen = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.Screen"));
Screen:Property({"Name", "Screen"});
Screen:Property({"m_width", nil, "GetWidth"});
Screen:Property({"m_height", nil, "GetHeight"});

Screen:Signal("sizeChanged", function(width, height) end)

function Screen:ctor()
	commonlib.EventSystem.getInstance():AddEventListener("RendererRecreated", function(self)
		self:OnSizeChange(self:GetWidth(), self:GetHeight());
	end, self);
end

function Screen:GetGUIRoot()
	if(not self.root or not self.root:IsValid()) then
		self.root = ParaUI.GetUIObject("root");
	end
	return self.root;
end

function Screen:GetWidth()
	return self:GetGUIRoot().width;
end

function Screen:GetHeight()
	return self:GetGUIRoot().height;
end

function Screen:OnSizeChange(width, height)
	if(self.last_width ~= width or self.last_height~=height) then
		self.last_width, self.last_height = width, height;
		self:GetUIScaling(true);
		self:sizeChanged(width, height);

		if (System.os.GetPlatform() == "mac" and System.os.CompareParaEngineVersion('1.9.1.0')) then
			local att = ParaEngine.GetAttributeObject();
			local screenSize = att:GetField("ScreenResolution", {1280, 720});

			if (screenSize and (screenSize[1] <= 320 or screenSize[2] <= 240)) then
				att:SetField("ScreenResolution", {320, 240});
			end
		end
	end
end

function Screen:SetMinimumScreenSize(minWidth, minHeight)
	self.minScreenWidth = minWidth or 1280
	self.minScreenHeight = minHeight or 720
	ParaUI.SetMinimumScreenSize(self.minScreenWidth, self.minScreenHeight,true);
end

function Screen:GetMinimumScreenSize()
	if(not self.minScreenWidth or not self.minScreenHeight) then
		local size = self:GetGUIRoot():GetField("MinimumScreenSize", {800, 600});
		self.minScreenWidth, self.minScreenHeight = size[1], size[2]
	end
	return self.minScreenWidth, self.minScreenHeight;
end

-- restore resolution to default
function Screen:RestoreUIDesignResolution(callbackFunc)
	if(System.options.IsTouchDevice) then
		local minWidth, minHeight = self:GetMinimumScreenSize()
		self:ChangeUIDesignResolution(minWidth, minHeight, callbackFunc)
	else
		self:ChangeUIDesignResolution(nil, nil, callbackFunc)
	end
end

-- @param scaling: if nil, it is user specified. 
function Screen:SetUserUIScaling(userUIScaling)
	self.userUIScaling = userUIScaling;
	self:SetUIScale(userUIScaling, userUIScaling);
end

-- this may be nil if user did not specify it explicitly. 
function Screen:GetUserUIScaling()
	return self.userUIScaling;
end

function Screen:GetDesignUIResolution()
	return self.curDesignUIWidth, self.curDesignUIHeight;
end

function Screen:GetWindowSolution()
	local frame_size;
	if System.os.GetPlatform()=="win32" then
		frame_size = ParaEngine.GetAttributeObject():GetField("VisibleSize")
	end
	if frame_size==nil then
		frame_size = ParaEngine.GetAttributeObject():GetField("WindowResolution", {1280, 720});
	end
	local frame_width = frame_size[1];
	local frame_height = frame_size[2];

	if (frame_height == 0) then
		-- in case "WindowResolution" API is not supported, such as on mac platform, we will use UI resolution instead.  
		local scaling = self:GetUIScaling(true);
		frame_width = math.floor(Screen:GetWidth() * scaling[1] + 0.5);
		frame_height = math.floor(Screen:GetHeight() * scaling[2] + 0.5);
	end

	return frame_width, frame_height;
end

-- get unscaled screen resolution. 
-- @NOTE: This function only return creation window size, which is pretty buggy. 
function Screen:GetScreenSolution()
	local frame_size = ParaEngine.GetAttributeObject():GetField("ScreenResolution", {1280, 720});
	local frame_width = frame_size[1];
	local frame_height = frame_size[2];

	if (frame_height == 0) then
		-- in case "ScreenResolution" API is not supported, such as on mac platform, we will use UI resolution instead.  
		local scaling = self:GetUIScaling(true);
		frame_width = math.floor(Screen:GetWidth() * scaling[1] + 0.5);
		frame_height = math.floor(Screen:GetHeight() * scaling[2] + 0.5);
	end

	return frame_width, frame_height;
end

function Screen:AutoAdjustUIScalingImp()
	local width, height = self.curDesignUIWidth, self.curDesignUIHeight;

	if (not width or not height) then
		local winWidth, winHeight = self:GetWindowSolution();
		local minWidth, minHeight = self:GetMinimumScreenSize();
		local userUIScaling = self:GetUserUIScaling();
		local UIScaling = 1;

		if (System.os.GetPlatform() == "mac") then
			if (winWidth >= minWidth * 2 and
				winHeight >= minHeight * 2) then
				-- user is using 2K or 4K monitor, we will scale by 2 or 4. 
				local ultraDisplayFactor = math.min(winWidth / minWidth, winHeight / minHeight);

				if (ultraDisplayFactor >= 2) then
					ultraDisplayFactor = 2;
				elseif (ultraDisplayFactor >= 4) then
					ultraDisplayFactor = 4;
				end

				UIScaling = ultraDisplayFactor;
			else
				UIScaling = userUIScaling;
			end
		else
			if (not userUIScaling) then
				if (winWidth >= minWidth * 2 and
					winHeight >= minHeight * 2) then
					-- user is using 2K or 4K monitor, we will scale by 2 or 4. 
					local ultraDisplayFactor = math.min(winWidth / minWidth, winHeight / minHeight);
	
					if (ultraDisplayFactor > 2.2 and ultraDisplayFactor < 4.4) then
						ultraDisplayFactor = 2; -- 2k monitor
					else
						ultraDisplayFactor = 4; -- 4k monitor
					end
	
					UIScaling = ultraDisplayFactor;
				end
			else
				UIScaling = userUIScaling;
			end
		end

		self:SetUIScale(UIScaling, UIScaling)
	else
		local minWidth, minHeight = self:GetMinimumScreenSize()
		width = math.max(minWidth, width);
		height = math.max(minHeight, height);

		local scaleWidth, scaleHeight = self:GetUIScale(true);
		local curScreenWidth, curScreenHeight = Screen:GetWidth(), Screen:GetHeight();
		local frame_width = scaleWidth * curScreenWidth;
		local frame_height = scaleHeight * curScreenHeight;

		-- local frame_size = ParaEngine.GetAttributeObject():GetField("ScreenResolution", {1280,720});
		-- local frame_height = frame_size[2];
		-- if(frame_height == 0) then
		-- 	frame_height = Screen:GetHeight();
		-- 	LOG.std(nil, "error", "TouchDevice", "ScreenResolution not implemented");
		-- end
		-- LOG.std(nil, "info", "Screen", {frame_size, ui_height = Screen:GetHeight()});

		local scalingX = frame_width / width;
		local scalingY = frame_height / height;
		local scaling = math.min(scalingX, scalingY);

		if (scaling ~= scaleWidth) then	
			LOG.std(nil, "info", "Screen", "design resolution is changed to %d, %d", width or 0, height or 0);
			self:SetUIScale(scaling)
		end	
	end
end

local designRes = {};
function Screen:PushDesignResolution(width, height)
	designRes[#designRes + 1] = {width, height}
	self:ChangeUIDesignResolution(width, height)
end

function Screen:PopDesignResolution()
	if(#designRes > 0) then
		local res = designRes[#designRes]
		designRes[#designRes] = nil;
		local width, height = res[1], res[2]
		if(#designRes > 0) then
			local res = designRes[#designRes]
			local width, height = res[1], res[2]
			self:ChangeUIDesignResolution(width, height)
		else
			self:RestoreUIDesignResolution();
		end
		return width, height;
	else
		self:RestoreUIDesignResolution();
	end
end

function Screen:GetTopDesignResolution()
	if #designRes>0 then
		local res = designRes[#designRes]
		local width, height = res[1], res[2]
		return width, height
	else
		return self:GetWindowSolution()
	end
end

function Screen:ScheduleUIResolutionUpdate(delayTime, callbackFunc)
	self:Disconnect("sizeChanged", self, self.AutoAdjustUIScalingImp);
	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		if(Screen:GetWidth() > 0) then
			timer:Change();
			self:AutoAdjustUIScalingImp();
			if(callbackFunc) then
				callbackFunc();
			end
			self:Connect("sizeChanged", self, self.AutoAdjustUIScalingImp, "UniqueConnection");
		end
	end})
	self.mytimer:Change(0, delayTime or 300);
end

-- this function is useful when you want to match a given design resolution as much as possible for the entire UI. 
-- in touch devices, we may use a common design resolution like 1280*720. 
-- @param width, height: we will ensure the adjusted ui resolution is bigger than width*height. 
-- and at least one side equals to width or height.
-- If nil, we will make UIScale to 1, 1
-- @param callbackFunc: the callback function when resolution is ready. 
function Screen:ChangeUIDesignResolution(width, height, callbackFunc)
	self.curDesignUIWidth, self.curDesignUIHeight = width, height;
	self:ScheduleUIResolutionUpdate(nil, callbackFunc)
end


local ui_scaling

-- @param scalingX: default to 1
-- @param scalingY: default to scalingX
function Screen:SetUIScale(scalingX, scalingY)
	scalingX = scalingX or 1
	scalingY = scalingY or scalingX

	LOG.std(nil, "info", "Screen", "set UIScale to %f, %f", scalingX, scalingY);
	ui_scaling = ui_scaling or {};
	ui_scaling[1], ui_scaling[2] = scalingX, scalingY;
	ParaUI.GetUIObject("root"):SetField("UIScale", ui_scaling);
end

-- return scaleX, scaleY
function Screen:GetUIScale(bForceUpdate)
	local scaling = self:GetUIScaling(bForceUpdate)
	return scaling[1], scaling[2]
end

-- return {scaleX, scaleY}
function Screen:GetUIScaling(bForceUpdate)
	if(not ui_scaling) then
		ui_scaling = {1, 1}
		bForceUpdate = true;
	end
	if(bForceUpdate) then
		return self:GetGUIRoot():GetField("UIScale", ui_scaling)
	else
		return ui_scaling;
	end
end


Screen:InitSingleton();
