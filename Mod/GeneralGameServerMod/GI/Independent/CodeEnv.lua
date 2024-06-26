--[[
Title: CodeEnv
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local CodeEnv = NPL.load("Mod/GeneralGameServerMod/GI/Independent/CodeEnv.lua");
------------------------------------------------------------
]]
local lfs = commonlib.Files.GetLuaFileSystem();

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local SceneContext = NPL.load("./SceneContext.lua");

local API = NPL.load("./API/API.lua", IsDevEnv);
local SceneAPI = NPL.load("./API/SceneAPI.lua", IsDevEnv);
local PlayerAPI = NPL.load("./API/PlayerAPI.lua", IsDevEnv);
local SystemAPI = NPL.load("./API/SystemAPI.lua", IsDevEnv);
local EventAPI = NPL.load("./API/EventAPI.lua", IsDevEnv);
local UIAPI = NPL.load("./API/UIAPI.lua", IsDevEnv);
local EntityAPI = NPL.load("./API/EntityAPI.lua", IsDevEnv);
local BlockAPI = NPL.load("./API/BlockAPI.lua", IsDevEnv);
local MovieAPI = NPL.load("./API/MovieAPI.lua", IsDevEnv);
-- local UtilityAPI = NPL.load("./API/UtilityAPI.lua", IsDevEnv);
-- local GGSAPI = NPL.load("./API/GGSAPI.lua", IsDevEnv);
local NetAPI = NPL.load("./API/NetAPI.lua", IsDevEnv);
local RPCAPI = NPL.load("./API/RPCAPI.lua", IsDevEnv);
local FileAPI = NPL.load("./API/FileAPI.lua", IsDevEnv);
local CodeBlockAPI = NPL.load("./API/CodeBlockAPI.lua", IsDevEnv);

local CodeEnv = commonlib.inherit(nil, NPL.export());

CodeEnv.lfs = lfs;
CodeEnv.ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
CodeEnv.vector3d = commonlib.gettable("mathlib.vector3d");
CodeEnv.IsDevEnv = IsDevEnv;
CodeEnv.Debug = GGS.Debug;
CodeEnv.DebugStack = DebugStack;

CodeEnv.EventEmitter = EventEmitter;
CodeEnv.SceneContext = SceneContext;

CodeEnv.pack = CommonLib.pack;
CodeEnv.unpack = CommonLib.unpack;
CodeEnv.select = CommonLib.select;

CodeEnv.null_function = function() end 


function CodeEnv:ctor()
	self._G = self;
	self.__modules__ = {};        -- 模块
	self.__tables__ = {};         -- 全局表集
	self.__windows__ = {};        -- 窗口
	self.__entities__ = {};       -- 实例
	self.__event_callback__ = {}; -- 事件回调
	self.__all_coroutine_data__ = {};

	-- 循环执行函数
	self.__loop_function__ = function(...)
		local callback = self.pack(...);
		while(type(callback) == "function") do
			self.__xpcall__(callback, self.select(2));
			callback = self.pack(self.__coroutine_yield__());
		end
	end
	-- 不可执行阻塞路基, 专用于唤醒协程, 以便均匀分配tick
	self.__tick_co__ = coroutine.create(self.__loop_function__);
	self.__is_tick_co_env__ = function()
		if (not self.__tick_co__) then return end
		local __cur_co__, __is_main_thread__ = self.__coroutine_running__();
		local __tick_co_status__ = self.__coroutine_status__(self.__tick_co__);
		return not __is_main_thread__ and __cur_co__ == self.__tick_co__ and (__tick_co_status__ == "running" or __tick_co_status__ == "normal");
	end
	self.__activate_tick_callback__ = function (...)
		if (not self.__tick_co__) then return end
		local callback = self.pack(...);
		if (type(callback) ~= "function") then return end
		if (self.__is_tick_co_env__()) then
			return callback(self.select(2));
		else
			self.__coroutine_resume__(self.__tick_co__, ...);
		end
	end

	local __tick_callback_list__ = {};
	self.__activate_tick_event__ = function()
		self.__activate_tick_callback__(function()
			-- self.TriggerEventCallBack(self.EventType.TICK);
			local __event_callback__ = self.__event_callback__[self.EventType.TICK];
			if (not __event_callback__) then return end
			local size = 0;
			for _, callback in pairs(__event_callback__) do
				size = size + 1;
				__tick_callback_list__[size] = callback;
			end
			for i = 1, size do
				(__tick_callback_list__[i])();
				__tick_callback_list__[i] = nil;
			end
		end);
	end

	-- 默认事件处理协程
	self.__event_co__ = coroutine.create(self.__loop_function__);
	
	self.__is_event_co_env__ = function()
		if (not self.__event_co__) then return end
		local __cur_co__, __is_main_thread__ = self.__coroutine_running__();
		local __event_co_status__ = self.__coroutine_status__(self.__event_co__);
		return not __is_main_thread__ and __cur_co__ == self.__event_co__ and (__event_co_status__ == "running" or __event_co_status__ == "normal");
	end

	self.__activate_event_callback__ = function (...)
		if (not self.__event_co__) then return end
		local callback = self.pack(...);
		if (type(callback) ~= "function") then return end
		if (self.__is_event_co_env__()) then
			return callback(self.select(2));
		else
			self.__coroutine_resume__(self.__event_co__, ...);
		end
	end
end

function CodeEnv:InstallAPI(api)
	for key, val in pairs(api) do   -- pairs 不会遍历元表
		self[key] = val;
	end
end

function CodeEnv:InstallLuaAPI()
	self.__select__ = select;
	self.__coroutine_create__ = coroutine.create;
	self.__coroutine_wrap__ = coroutine.wrap;
	self.__coroutine_running__ = coroutine.running;
	self.__coroutine_resume__ = coroutine.resume;
	self.__coroutine_yield__ = coroutine.yield;
	self.__coroutine_status__ = coroutine.status;

	self.__get_coroutine_data__ = function(co, bIsNewNotExist)
		local __co__ = co or (self.__coroutine_running__());
		if (__co__ == nil) then
			__co__ = "__nil__";
			print("-------------error: __coroutine_running__() == nil---------------", (self.__coroutine_running__()));
		end

		if (self.__all_coroutine_data__[__co__]) then return self.__all_coroutine_data__[__co__] end
		if (bIsNewNotExist == false) then return nil end 

		local __data__ = {};
		__data__.__windows__ = __data__.__windows__ or {};
		__data__.__entities__ = __data__.__entities__ or {};
		__data__.__event_callback__ = __data__.__event_callback__ or {};
		__data__.__clean_callback__ = __data__.__clean_callback__ or {};
		__data__.__children_coroutine_data_map__ = {};
		__data__.__parent_coroutine_data__ = nil;
		__data__.__independent__ = false;  -- 默认不独立
		__data__.__co__ = __co__;
		self.__all_coroutine_data__[__co__] = __data__;
		return __data__;
	end
	
	self.__add_clean_coroutine_data_callback__ = function(callback)
		if (type(callback) ~= "function") then return end
		self.__get_coroutine_data__().__clean_callback__[callback] = callback;
	end
	
	self.__remove_clean_coroutine_data_callback__ = function(callback)
		if (type(callback) ~= "function") then return end
		self.__get_coroutine_data__().__clean_callback__[callback] = nil;
	end
	
	self.__clean_coroutine_data__ = function(__co__)
		-- print("========================__clean_coroutine_data__=========================", __co__);

		local __data__ = self.__get_coroutine_data__(__co__);
		local list = {};
		for _, window in pairs(__data__.__windows__) do table.insert(list, window) end
		for i = 1, #list do
			list[i]:CloseWindow();
			list[i] = nil;
		end
		for _, entity in pairs(__data__.__entities__) do table.insert(list, entity) end 
		for i = 1, #list do
			list[i]:Destroy();
			list[i] = nil;
		end
	
		for event_type, callbacks in pairs(__data__.__event_callback__) do
			list[event_type] = list[event_type] or {};
			for callback in pairs(callbacks) do
				list[event_type][callback] = callback;
			end
		end 
	
		for event_type, callbacks in pairs(list) do
			for callback in pairs(callbacks) do
				self.RemoveEventCallBack(event_type, callback);
			end
		end
	
		for _, clean_callback in pairs(__data__.__clean_callback__) do clean_callback() end
		__data__.__clean_callback__ = {};
		
		self.__all_coroutine_data__[__data__.__co__] = nil;
	end
end

function CodeEnv:InstallIndependentAPI(Independent)
	-- 内部函数, 不可随意调用
	self.__yield__ = function(...) Independent:Yield(...) end
	self.__clear__ = function() self:Clear() end 
	self.__restart__ = function() Independent:Restart() end
	self.__start__ = function(...) Independent:Start(...) end
	self.__stop__ = function() Independent:Stop() end
	self.__call__ = function(...) return Independent:Call(...) end
	self.__xpcall__ = function(...) return Independent:XPCall(...) end
	self.__loadfile__ = function(...) return Independent:LoadFile(...) end
	self.__is_running__ = function() return Independent:IsRunning() end 
	self.__safe_callback__ = function(callback) 
		return function(...) 
			Independent:Call(callback, ...) 
		end 
	end 
	self.__loadstring__ = function(...) return Independent:LoadString(...) end
	self.__get_loop_tick_count__ = function() return Independent:GetLoopTickCount() end 
	self.__get_tick_timestamp__ = function() return 1000 / self.__get_loop_tick_count__() end -- 每个tick所用时间
	self.__is_share_mouse_keyboard_event__ = function() return Independent:IsShareMouseKeyBoard() end 
	self.__get_tick_count__ = function() return Independent:GetTickCount() end  
	self.__get_timestamp__ = function() return math.floor(Independent:GetTickCount() * 1000 / Independent:GetLoopTickCount()) end   -- ms
	self.__set_alias_path__ = function(alias, path) Independent.__alias_path_map__[alias] = path end 
	self.__get_module_env__ = function(...) return Independent:GetModuleEnv(...) end
	self.__get_tick_speed__ = function() return Independent:GetTickSpeed() end
	self.__set_tick_speed__ = function(...) return Independent:SetTickSpeed(...) end 
	self.__inject_checkyield_to_code__ = function(...) return Independent:InjectCheckYieldToCode(...) end
end

function CodeEnv:InstallCodeBlockAPI()
	self.__get_code_globals__ = function() return GameLogic.GetCodeGlobal() end 
end

function CodeEnv:Init(Independent)
	self:InstallLuaAPI();
	self:InstallIndependentAPI(Independent);
	self:InstallCodeBlockAPI();
	
	API(self);
	SystemAPI(self);
	EventAPI(self);
	SceneAPI(self);
	PlayerAPI(self);
	UIAPI(self);
	EntityAPI(self);
	BlockAPI(self);
	MovieAPI(self);
	-- UtilityAPI(self);
	-- GGSAPI(self);
	NetAPI(self);
	RPCAPI(self);
	FileAPI(self);
	CodeBlockAPI(self);
	
    return self;
end

function CodeEnv:Clear()
	-- 关闭相关窗口
	for _, window in pairs(self.__windows__) do
		window:CloseWindow();
	end

	-- 安全移除Entity
	for _, entity in ipairs(self.__GetEntityList__()) do
		entity:Destroy();
	end

	if (self.__tick_co__) then coroutine.resume(self.__tick_co__) end 
	if (self.__event_co__) then coroutine.resume(self.__event_co__) end 
	self.__tick_co__ = nil;
	self.__event_co__ = nil;
end
