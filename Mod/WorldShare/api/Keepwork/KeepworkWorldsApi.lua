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
    --世界列表暂时不缓存数据，date:20240313,pbb
    KeepworkBaseApi:Get(url, nil, nil, success, error,nil, nil, nil, nil, true)
end

-- url: /worlds/%s
-- method: GET
-- params:
--[[
    x-page
    x-per-page
]]
-- return: object
function KeepworkWorldsApi:GetWorldDeletedList(xPerPage, xPage, success, error)
    local url = '/joinedWorlds'

    if type(xPerPage) == 'number' then
        url = url .. '?x-per-page=' .. xPerPage

        if type(xPerPage) == 'number' then
            url = url .. '&x-page=' .. xPage
        end
    end
    url = url.. '&isDeleted=1'
    KeepworkBaseApi:Get(url, nil, nil, success, error,nil, nil, nil, nil, true)
end

-- 暂时先这样改，后面得后端优化
-- v2.1.0 去掉worldTagName查询，直接通过worldName获取世界信息，防止回收站上线以后出现世界混乱的问题
function KeepworkWorldsApi:GetWorldByName(foldername, success, error, isRefresh)
    self:GetWorldByWorldName(foldername, success, error, isRefresh)
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
