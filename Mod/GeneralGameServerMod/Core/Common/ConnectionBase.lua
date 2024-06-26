--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");
local ConnectionBase = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.ConnectionBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local ConnectionBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ConnectionThread = {};  -- 链接所在线程
local AllConnections = {};    -- 线程所有链接
local NextConnectionId = 0;

ConnectionBase:Property("ConnectionId", 0);
ConnectionBase:Property("Nid", "");
ConnectionBase:Property("ThreadName", "gl");
ConnectionBase:Property("RemoteNeuronFile", "Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");   -- 对端处理文件
ConnectionBase:Property("LocalNeuronFile", "Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");    -- 本地处理文件
ConnectionBase:Property("ConnectionClosed", false, "IsConnectionClosed");
ConnectionBase:Property("SynchronousSend", false, "IsSynchronousSend");   -- 是否采用同步发送数据包模式
ConnectionBase:Property("SynchronousSendTimeout", 3);                     -- 同步发送超时时间


function ConnectionBase:ctor()
    NextConnectionId = NextConnectionId + 1;
	self:SetConnectionId(NextConnectionId);
end

-- get ip address. return nil or ip address
function ConnectionBase:GetIPAddress()
	return NPL.GetIP(self:GetNid());
end

function ConnectionBase:Init(opts)
    if (type(opts) ~= "table") then return self end
    if (opts.threadName) then self:SetThreadName(opts.threadName) end
    if (opts.remoteNeuronFile) then self:SetRemoteNeuronFile(opts.remoteNeuronFile) end
    if (opts.localNeuronFile) then self:SetLocalNeuronFile(opts.localNeuronFile) end
    
    if (opts.nid) then 
        self:SetNid(opts.nid);
    elseif (opts.ip and opts.port) then
        self:SetNid("ggs_" .. tostring(self:GetConnectionId()));
        NPL.AddNPLRuntimeAddress({host = tostring(opts.ip), port = tostring(opts.port), nid = self:GetNid()});
    end

    AllConnections[self:GetNid()] = self;

    return self;
end

function ConnectionBase:GetRemoteAddress(neuronfile)
	return string.format("(%s)%s:%s", self:GetThreadName() or "gl", self:GetNid() or "", neuronfile or self:GetRemoteNeuronFile());
end

-- this function is only called for a client to establish a connection with remote server.
-- on the server side, accepted connections never need to call this function. 
-- @param timeout: the number of seconds to timeout. if 0, it will just ping once. 
-- @param callback_func: a function(bSuccess) end.  If this function is provided, this function is asynchronous. 
function ConnectionBase:Connect(timeout, callback_func)
	if(self.is_connecting) then return end
	self.is_connecting = true;
	local address = self:GetRemoteAddress();
	local data = {thread_name = __rts__:GetName(), neuron_file = self:GetLocalNeuronFile()};
	if(not callback_func) then
		-- if no call back function is provided, this function will be synchronous. 
		if( NPL.activate_with_timeout(timeout or 1, address, data) ~=0 ) then
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "failed to connect to server %s", self:GetNid());
		else
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "connection with %s is established", self:GetNid());	
			self:SetConnectionClosed(false);
			return 0;
		end
	else
		-- if call back function is provided, we will do asynchronous connect. 
		local intervals = {300, 500, 100, 1000, 1000, 1000, 1000}; -- intervals to try
		local try_count = 0;
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			try_count = try_count + 1;
			if(NPL.activate(address, data) ~=0) then
				if(intervals[try_count]) then
					timer:Change(intervals[try_count], nil);
				else
					-- timed out. 
					self.is_connecting = nil;
					callback_func(false);
					self:CloseConnection("ConnectionNotEstablished");
				end	
			else
				-- connected 
				self.is_connecting = nil;
				self:SetConnectionClosed(false);
				callback_func(true)
			end
		end})

		mytimer:Change(10, nil);
		return 0;
	end
end

-- 关闭连接
function ConnectionBase:CloseConnection(reason)
	NPL.reject({["nid"] = self:GetNid(), ["reason"] = reason});
	AllConnections[self:GetNid()] = nil;
    self:SetConnectionClosed(true);
    self:OnClose(reason);
end

-- send message immediately to c++ queue
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is this file. 
function ConnectionBase:Send(msg, neuronfile)
	if (self:IsConnectionClosed()) then return end
	
    msg, neuronfile = self:OnSend(msg, neuronfile);

	local address = self:GetRemoteAddress(neuronfile);
	local ret = 0;
	if (self:IsSynchronousSend()) then
		ret = NPL.activate_with_timeout(self:GetSynchronousSendTimeout(), address, msg);
	else
		ret = NPL.activate(address, msg);
	end

	if(ret ~= 0) then
		LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
		self:CloseConnection("发包失败");
	end
end

-- 发送消息
function ConnectionBase:OnSend(msg, neuronfile)
	return msg, neuronfile;
end

-- 接受消息
function ConnectionBase:OnReceive(msg)
end

-- 链接关闭
function ConnectionBase:OnClose()
end

-- 新链接
function ConnectionBase:OnConnection()
	NPL.activate("(main)Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua", {action = "ConnectionEstablished", threadName = __rts__:GetName(), ConnectionNid = self:GetNid()});
end

-- 获取连接
function ConnectionBase:GetConnectionByNid(nid)
	return AllConnections[nid];
end

function ConnectionBase:OnActivate(msg)
	local nid = msg and (msg.nid or msg.tid);
	if (not nid) then return self:handleMsg(msg) end
	local connection = AllConnections[nid];
    if(connection) then return connection:OnReceive(msg) end
	-- 新建连接
	connection = self:new():Init({nid=nid, threadName = msg.thread_name, remoteNeuronFile = msg.neuron_file});
	connection:OnConnection();
	connection:handleMsg(msg);
end

function ConnectionBase:handleMsg(msg)
end

NPL.this(function() 
	local nid = msg and (msg.nid or msg.tid);
	local action = msg and msg.action;
	local threadName = __rts__:GetName();

	if (nid) then return ConnectionBase:OnActivate(msg) end
	
	if (action == "ConnectionEstablished") then
		ConnectionThread[msg.ConnectionNid] = msg.threadName; 
	elseif (action == "ConnectionDisconnected") then
		local connection = AllConnections[msg.ConnectionNid];
		if (connection) then connection:CloseConnection("链接断开") end
	else 
		ConnectionBase:handleMsg(msg);
	end
end);


CommonLib.OnNetworkEvent(function(msg)
	local nid = msg.nid or msg.tid;
	local threadName = ConnectionThread[nid] or "main";
	if(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		NPL.activate(string.format("(%s)Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua", threadName), {action = "ConnectionDisconnected", ConnectionNid = nid});
	elseif (msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
	end

end);