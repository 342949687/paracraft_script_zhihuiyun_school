--[[
Title: SandBox
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SandBox = NPL.load("Mod/GeneralGameServerMod/GI/Independent/SandBox.lua");
------------------------------------------------------------
]]

local Independent = NPL.load("./Independent.lua", IsDevEnv);

local SandBox = commonlib.inherit(Independent, NPL.export());

function SandBox:ctor()
    self:SetErrorExit(false);
    self:SetShareMouseKeyBoard(true);
end

function SandBox:GetAPI()
    self:Start();
	-- print("===========================SandBox:GetAPI==================================", self:IsRunning());
    return self:GetCodeEnv();
end

-- 获取代码方块专属API
function SandBox:GetCodeBlockAPI()
    if (self.CodeBlockAPI and self:IsRunning()) then return self.CodeBlockAPI end

    local API = self:GetAPI();
    self.CodeBlockAPI = {
        API = API,
        
        call = API.__call__,
        
        -- 注册网络消息
        registerNetworkEvent = function(name, callback)
            if (name == "ggs_user_joined") then
                -- 玩家加入 包含自己
                API.GetNetPlayerModule():OnPlayerLogin(callback);
            elseif (name == "ggs_user_left") then
                -- 玩家退出 包含自己
                API.GetNetPlayerModule():OnPlayerLogout(callback); 
            elseif (name == "ggs_started") then
                -- 连接成功 
                API.GetNetModule():Connect(callback);
            elseif (name == "ggs_shutdown") then 
                -- 服务器不关闭
            else
                API.RegisterNetworkEvent(name, callback);
            end
        end,

        -- 广播网络消息
        broadcastNetworkEvent = function(name, msg)
            API.TriggerNetworkEvent(name, msg);
        end,

        -- 显示排行榜
        showRanking = function(...)
            return API.GetNetRankModule():ShowUI(...);
        end,

        -- 设置排行榜字段值
        setRankField = function(key, val)
            API.GetNetRankModule():SetFieldValue(key, val);
        end,

        -- 获取共享数据
        getSharedData = function(key, default_val)
            return API.GetSharedData(key, default_val);
        end,

        -- 设置共享数据
        setSharedData = function(key, val)
            return API.SetSharedData(key, val);
        end,

        -- 监控共享数据
        onSharedDataChanged = function(key, callback)
            return API.OnSharedDataChanged(key, callback);
        end,
        
        -- 获取用户数据 
        getUserData = function(key, default_val, username)
            return API.GetNetStateModule():GetUserState(username):Get(key, default_val);
        end,

        -- 设置用户数据
        setUserData = function(key, value)
            return API.GetNetStateModule():GetUserState(username):Set(key, value);
        end,

        -- 显示用户列表
        showUserList = function(bShow, ...)
            if (bShow == true) then return API.GetNetPlayerModule():ShowPlayerListUI(...) end 
            if (bShow == false) then return API.GetNetPlayerModule():ClosePlayerListUI(...) end
            return API.GetNetPlayerModule():TriggerPlayerListUI(...);
        end,

        -- 遍历玩家
        eachPlayer = function()
            return pairs(API.GetNetModule().GetAllPlayer());
        end
    }

    return self.CodeBlockAPI;
end


function SandBox:Stop()
    self.CodeBlockAPI = nil;
    SandBox._super.Stop(self);
end

SandBox:InitSingleton();
