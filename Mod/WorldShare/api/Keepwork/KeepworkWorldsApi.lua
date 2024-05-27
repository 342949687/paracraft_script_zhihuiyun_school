--[[
Title: Keepwork Worlds API
Author(s): big
CreateDate: 2019.11.8
ModifyDate: 2022.7.11
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldsApi.lua')
------------------------------------------------------------
]]
local Encoding = commonlib.gettable('commonlib.Encoding')

local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldsApi = NPL.export()

-- url: /worlds
-- method: GET
-- params:
--[[
    x-page
    x-per-page
]]
-- return: object
function KeepworkWorldsApi:GetWorldList(xPerPage, xPage, success, error)
    local url = '/joinedWorlds'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end

    KeepworkBaseApi:Get(url, nil, nil, success, error)
end

-- 暂时先这样改，后面得后端优化
function KeepworkWorldsApi:GetWorldByName(foldername, success, error, isRefresh)
    self.isGetData1 = false
    self.isGetData2 = false
    self.data1 = nil
    self.data2 = nil
    self.success = success

    self:GetWorldByWorldName(foldername, function(data, err) 
        self.isGetData1 = true
        if (err == 200 and data and #data > 0) then
            self.data1 = data
        end
        self:DoSuccessCall(foldername)
    end, error, isRefresh)

    self:GetWorldByExtraName(foldername, function(data, err) 
        self.isGetData2 = true
        if (err == 200 and data and #data > 0) then
            self.data2 = data
        end
        self:DoSuccessCall(foldername)
    end, error, isRefresh)
end

function KeepworkWorldsApi:DoSuccessCall(foldername)
    if self.isGetData1 and self.isGetData2 then
        if self.success and type(self.success) == "function" then
            local data = self.data1 or self.data2
            self.isGetData1 = false
            self.isGetData2 = false
            self.data1 = nil
            self.data2 = nil
            local success = commonlib.copy(self.success) --防止嵌套使用
            self.success = nil
            success(data or {},200)
        end
    end
end

-- url: /joinedWorlds?worldName=%s
-- method: GET
-- params:
--[[
]]
-- return: object
function KeepworkWorldsApi:GetWorldByWorldName(foldername, success, error, isRefresh)
    local url = format('/joinedWorlds?worldName=%s', Encoding.url_encode(foldername or ''))

    KeepworkBaseApi:Get(url, nil, nil, success, error, nil, nil, nil, nil, isRefresh)
end

-- url: /joinedWorlds?extra.worldTagName=%s
-- method: GET
-- params: 改名之后的世界上面的接口可能会拿不到数据
--[[
]]
function KeepworkWorldsApi:GetWorldByExtraName(foldername, success, error, isRefresh)
    local url = format('/joinedWorlds?extra.worldTagName=%s', Encoding.url_encode(foldername or ''))

    KeepworkBaseApi:Get(url, nil, nil, success, error, nil, nil, nil, nil, isRefresh)
end

-- url: /worlds/%s
-- method: PUT
-- return: object
function KeepworkWorldsApi:UpdateWorldInfo(worldId, params, success, error)
    if not worldId or
       type(worldId) ~= 'number' or
       not params or
       type(params) ~= 'table' then
        return
    end

    local url = format('/worlds/%s', worldId)

    KeepworkBaseApi:Put(url, params, nil, success, error)
end