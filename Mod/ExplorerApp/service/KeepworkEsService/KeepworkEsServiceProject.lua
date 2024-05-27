--[[
Title: Keepwork Es Service Projects
Author(s):  big
CreateDate: 2019.2.21
ModifyDate: 2022.7.27
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkEsServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkEsService/KeepworkEsServiceProject.lua')
------------------------------------------------------------
]]

-- api
local EsProjectsApi = NPL.load('(gl)Mod/ExplorerApp/api/Es/Projects.lua')
local KeepworkProjectsApi = NPL.load("(gl)Mod/ExplorerApp/api/Keepwork/KeepworkProjectsApi.lua")

local KeepworkEsServiceProject = NPL.export()

function KeepworkEsServiceProject:GetEsProjectsByFilter(filter, sort, pages, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local sysTags = Mod.WorldShare.Utils.UrlEncode(Mod.WorldShare.Utils.Implode('|', filter))

    local params = {
        ['sys_tags'] = sysTags,
        page = pages and pages.page and pages.page or 1,
        ['per-page'] = pages and pages.perPage and pages.perPage or 10,
        sort = sort
    }

    EsProjectsApi:Projects(params, function(data, err)
        if not data or
            type(data) ~= 'table' or
            not data.hits or
            type(data.hits) ~= 'table' then
            return
        end

        local ids = {}

        for key, item in ipairs(data.hits) do
            ids[#ids + 1] = item.id
        end

        KeepworkProjectsApi:Search(ids, function(searchData, err)
            if not searchData or
               type(searchData) ~= 'table' or
               not searchData.rows or
               type(searchData.rows) ~= 'table' then
                return
            end

            for key, item in ipairs(data.hits) do
                for sKey, sItem in ipairs(searchData.rows) do
                    if item.id == sItem.id then
                        item.level = sItem.level
                        item.user = sItem.user
                        item.isSystemGroupMember = sItem.isSystemGroupMember
                        item.isFreeWorld = sItem.isFreeWorld
                        item.timeRules = sItem.timeRules
                        item.visibility = sItem.visibility
                        item.extra = sItem.extra
                        break
                    end
                end
            end

            callback(data, err)
        end)
    end)
end

function KeepworkEsServiceProject:Search(query, pages, callback)
    if not query or (type(query) ~= 'string' and type(query) ~= 'number') then
        return false
    end

    local params = {
        type = 'paracraft',
        page = pages and pages.page and pages.page or 1,
        ['per-page'] = pages and pages.perPage and pages.perPage or 10,
        q = Mod.WorldShare.Utils.UrlEncode(query)
    }

    EsProjectsApi:Projects(params, function(data, err)
        local ids = {}

        for key, item in ipairs(data.hits) do
            ids[#ids + 1] = item.id
        end

        KeepworkProjectsApi:Search(ids, function(searchData, err)
            if not searchData or
               type(searchData) ~= 'table' or
               not searchData.rows or
               type(searchData.rows) ~= 'table' then
                return
            end

            for key, item in ipairs(data.hits) do
                for sKey, sItem in ipairs(searchData.rows) do
                    if item.id == sItem.id then
                        item.level = sItem.level
                        item.user = sItem.user
                        item.isSystemGroupMember = sItem.isSystemGroupMember
                        item.isFreeWorld = sItem.isFreeWorld
                        item.timeRules = sItem.timeRules
                        item.visibility = sItem.visibility
                        item.extra = sItem.extra
                        break
                    end
                end
            end

            callback(data, err)
        end)
    end)
end