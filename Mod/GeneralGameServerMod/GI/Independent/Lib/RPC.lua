--[[
Title: RPC
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local RPC = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/RPC.lua");
------------------------------------------------------------
]]

local RPC = inherit(ToolBase, module("RPC"));

RPC:Property("ConnectCallBack");

local __username__ = GetUserName();

EventType.USER_DATA = "USER_DATA";
EventType.SHARE_DATA = "SHARE_DATA";
EventType.SHARE_DATA_ITEM = "SHARE_DATA_ITEM";

local __share_data__ = {};          -- 共享数据
local __all_user_data__ = {};       -- 所有用户数据
local __all_entity_data__ = {};     -- 所有实体数据

local function SetUserData(userdata)
    local username = userdata.__username__;
    __all_user_data__[username] = __all_user_data__[username] or {};
    partialcopy(__all_user_data__[username], userdata);
    __all_user_data__[username].__username__ = username;
    TriggerEventCallBack(EventType.USER_DATA, __all_user_data__[username]);
end

local function GetUserData(username)
    username = username or __username__;
    __all_user_data__[username] = __all_user_data__[username] or {};
    return __all_user_data__[username];
end

local function SetShareData(sharedata)
    partialcopy(__share_data__, sharedata);
    TriggerEventCallBack(EventType.SHARE_DATA, __share_data__);
end

function RPC:Init(opts)
    if (opts) then
        if (opts.threadName) then __rpc_virtual_connection__:SetRemoteThreadName(opts.threadName) end 
        if (opts.ip or opts.port) then __rpc_virtual_connection__:SetNid(AddNPLRuntimeAddress(opts.ip, opts.port)) end 
        if (opts.worldKey) then SetWorldKey(opts.worldKey) end
    end
    
    return self;
end

function RPC:Connect(callback)
    self:SetConnectCallBack(callback);
    print("====================request login=======================")
    RPC_Call("Login", {
        username = GetUserName(),
        worldId = GetWorldId(),
        worldName = "",
        worldKey = GetWorldKey(),
    }, function(data)
        print("===================response login=======================");
        __share_data__ = data.__share_data__ or {};
        __all_user_data__ = data.__all_user_data__ or {};
        __all_entity_data__ = data.__all_entity_data__ or {};

        local callback = self:GetConnectCallBack();
        return type(callback) == "function" and callback(data);
    end);
end

function RPC:Send(data)
    RPC_Broadcast(data);
end

function RPC:SendTo(username, data)
    RPC_Call("BroadcastTo", {username = username, data = data});
end

function RPC:OnRecv(callback)
    RPC_OnBroadcast(callback);
end

function RPC:OnDisconnected(callback)
    RPC_OnDisconnected(callback);
end

function RPC:OnClosed(callback)
    RPC_OnClosed(callback);
end

function RPC:OnNetClosed(callback)
    RPC_OnConnectClosed(callback);
end

function RPC:OnUserData(...)
    RegisterEventCallBack(EventType.USER_DATA, ...);
end

function RPC:SetUserData(userdata)
    if (type(userdata) ~= "table") then return end
    userdata.__username__ = __username__;
    SetUserData(userdata);
    RPC_Call("SetUserData", userdata);
end

function RPC:Lock()
    if (self.__is_locking__) then return false end 
    self.__is_locking__ = true;
    local lock_state = nil;
    RPC_Call("Lock", nil, function(success)
        lock_state = success;
    end);
    while (lock_state == nil) do
        sleep();
    end 
    return lock_state;
end

function RPC:Unlock()
    if (self.__is_unlocking__) then return false end 
    self.__is_unlocking__ = true;
    local unlock_state = nil;
    RPC_Call("Unlock", nil, function(success)
        unlock_state = success;
    end);
    while (unlock_state == nil) do
        sleep();
    end 
    return unlock_state;
end

function RPC:GetUserData(username)
    return GetUserData(username);
end

function RPC:GetAllUserData()
    return __all_user_data__;
end

function RPC:OnShareData(...)
    RegisterEventCallBack(EventType.SHARE_DATA, ...);
end

function RPC:SetShareData(sharedata)
    if (type(sharedata) ~= "table") then return end
    -- 触发数据项更新
    for key, val in pairs(sharedata) do
        TriggerEventCallBack(string.format("%s_%s", EventType.SHARE_DATA_ITEM, key), val, __share_data__[key]);
    end
    SetShareData(sharedata);
    RPC_Call("SetShareData", sharedata);
end

function RPC:OnShareDataItem(key, callback)
    RegisterEventCallBack(string.format("%s_%s", EventType.SHARE_DATA_ITEM, key), callback);
end

function RPC:GetShareData()
    return __share_data__;
end

RPC:InitSingleton();

RPC_On("SetUserData", function(userdata)
    SetUserData(userdata);
end);

RPC_On("SetShareData", function(sharedata)
    SetShareData(sharedata);
end);

RPC_On("ReLogin", function() 
    RPC:Connect();
end); 
