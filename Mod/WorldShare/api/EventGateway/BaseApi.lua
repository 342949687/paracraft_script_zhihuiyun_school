--[[
Title: Event Gateway Base API
Author(s):  big
Date:  2020.11.2
Place: Foshan
use the lib:
------------------------------------------------------------
local EventGatewayBaseApi = NPL.load("(gl)Mod/WorldShare/api/EventGateway/BaseApi.lua")
------------------------------------------------------------
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load("../BaseApi.lua")

local EventGatewayBaseApi = NPL.export()

EventGatewayBaseApi.noShowLog = true

function EventGatewayBaseApi:GetApi()
    return Config.eventGatewayList[BaseApi:GetEnv()] or ""
end

-- private
function EventGatewayBaseApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if not headers.notTokenRequest and token and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function EventGatewayBaseApi:Get(url, params, headers, success, error, noTryStatus, timeout)
    local fullUrl = self:GetApi() .. url

    BaseApi:Get(fullUrl, params, self:GetHeaders(headers), success, self:ErrorCollect("GET", fullUrl, url, error), noTryStatus, timeout, self.noShowLog)
end

-- public
function EventGatewayBaseApi:Post(url, params, headers, success, error, noTryStatus, timeout)
    local fullUrl = self:GetApi() .. url

    BaseApi:Post(fullUrl, params, self:GetHeaders(headers), success, self:ErrorCollect("POST", fullUrl, url, error), noTryStatus, timeout, self.noShowLog)
end

-- public
function EventGatewayBaseApi:Put(url, params, headers, success, error, noTryStatus, timeout)
    local fullUrl = self:GetApi() .. url

    BaseApi:Put(fullUrl, params, self:GetHeaders(headers), success, self:ErrorCollect("PUT", fullUrl, url, error), noTryStatus, timeout, self.noShowLog)
end

-- public
function EventGatewayBaseApi:Delete(url, params, headers, success, error, noTryStatus, timeout)
    local fullUrl = self:GetApi() .. url

    BaseApi:Delete(fullUrl, params, self:GetHeaders(headers), success, self:ErrorCollect("DELETE", fullUrl, url, error), noTryStatus, timeout, self.noShowLog)
end

-- public
function EventGatewayBaseApi:ErrorCollect(method, fullUrl, url, error)
    return BaseApi:Logger(method, fullUrl, url, error)
end
