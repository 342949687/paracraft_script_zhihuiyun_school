--[[
Title: Base Reqeust API
Author(s):  big
Date:  2023.3.26
Place: Foshan
use the lib:
------------------------------------------------------------
local BaseRequestApi = NPL.load("(gl)Mod/WorldShare/api/BaseRequestApi.lua")
------------------------------------------------------------
local marketingRequest = BaseRequestApi.CreateRequest(BaseRequestApi.apis.marketing);
]]

local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
local BaseApi = NPL.load('./BaseApi.lua')

local BaseRequestApi = commonlib.inherit(nil, NPL.export())

BaseRequestApi.apis = {
    marketing = Config.marketing[BaseApi:GetEnv()] or ""
}

function BaseRequestApi:CreateRequest(api)
    local ins = self:new()

    ins.baseUrl = api

    return ins
end

function BaseRequestApi:ctor()
end

-- private
function BaseRequestApi:GetApi()
    return self.baseUrl
end

-- private
function BaseRequestApi:GetHeaders(headers)
    headers = type(headers) == 'table' and headers or {}

    local token = Mod.WorldShare.Store:Get("user/token")

    if token and not headers.notTokenRequest and not headers["Authorization"] then
        headers["Authorization"] = format("Bearer %s", token)
    end

    headers.notTokenRequest = nil

    return headers
end

-- public
function BaseRequestApi:Get(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Get(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function BaseRequestApi:Post(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Post(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function BaseRequestApi:Put(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Put(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end

-- public
function BaseRequestApi:Delete(url, params, headers, callback, error, noTryStatus)
    url = self:GetApi() .. url

    BaseApi:Delete(url, params, self:GetHeaders(headers), callback, error, noTryStatus)
end
