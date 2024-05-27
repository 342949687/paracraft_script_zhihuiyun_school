--[[
    Desc: mqtt manager
    Last Modified: 2024-01-2 10:56
    Modified By: pbb
    Version: 1.0
    Company: palaka
    Use Lib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
        local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");

]]
local MqttApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttApi.lua")
local MqttManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager"));
local perPage = 20
function MqttManager:ctor()
    
end

function MqttManager.getInstance()
	if not MqttManager.sInstance then
		MqttManager.sInstance = MqttManager:new();
	end
	return MqttManager.sInstance;
end

function MqttManager:AddProject(name,callback)
    MqttApi.CreateProject({
        name = name
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadProjectList(callback)
    MqttApi.GetProjects({}, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteProject(id,callback)
    MqttApi.DeleteProject({
        router_params = {id = id},
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:UpdateProject(id,name,callback)
    MqttApi.UpdateProject({
        router_params = {id = id},
        name = name
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadTopicList(curPage,iotProjectId,callback)
    MqttApi.GetTopics({
        ["x-per-page"] = perPage,
		["x-page"] = curPage or 1,
        iotProjectId = iotProjectId,
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:AddTopic(iotProjectId,desc,callback)
    MqttApi.CreateTopic({
        iotProjectId = iotProjectId,
        desc = desc
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteTopic(topicId,callback)
    MqttApi.DeleteTopic({
        router_params = {id = topicId},
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:UpdateTopic(topicId,desc,callback)
    MqttApi.UpdateTopic({
        router_params = {id = topicId},
        desc = desc
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:ClearTopic(topicId,callback)
    MqttApi.ClearTopic({
        router_params = {id = topicId},
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

--device
function MqttManager:LoadDeviceList(curPage,iotProjectId,callback)
    MqttApi.GetDevices({
        ["x-per-page"] = perPage,
		["x-page"] = curPage or 1,
        iotProjectId = iotProjectId,
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:AddDevice(iotProjectId,name,callback)
    print("AddDevice===========",iotProjectId,name)
    MqttApi.CreateDevice({
        iotProjectId = iotProjectId,
        desc = name
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteDevice(deviceId,callback)
    MqttApi.DeleteDevice({
        router_params = {id = deviceId},
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadTopicDataList(topicId,callback)
    MqttApi.GetTopicData({
        router_params = {id = topicId},
    }, function(err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end
