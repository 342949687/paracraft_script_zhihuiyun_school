--[[
Title: Keepwork Projects Service
Author(s): big
CreateDate: 2019.01.25
ModifyDate: 2022.7.27
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
------------------------------------------------------------
]]
-- service
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

-- api
local ExplorerAppKeepworkProjectsApi = NPL.load('(gl)Mod/ExplorerApp/api/Keepwork/KeepworkProjectsApi.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')
local KeepworkSystemTagApi = NPL.load('(gl)Mod/ExplorerApp/api/Keepwork/SystemTag.lua')

local KeepworkServiceProject = NPL.export()

-- get list by ids
function KeepworkServiceProject:GetProjectByIds(projectIds, pages, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    KeepworkProjectsApi:Search(
        pages and pages.perPage and pages.perPage or 10,
        pages and pages.page and pages.page or 1,
        { id = { ['$in'] = projectIds } },
        function(data, err)
            if err ~= 200 or
               not data or
               type(data) ~= 'table' then
                callback()
                return
            end

            local ids = {}

            for key, item in ipairs(data.rows) do
                ids[#ids + 1] = item.id
            end

            ExplorerAppKeepworkProjectsApi:Search(ids, function(searchData, err)
                if not searchData or
                   type(searchData) ~= 'table' or
                   not searchData.rows or
                   type(searchData.rows) ~= 'table' then
                    return
                end

                for key, item in ipairs(data.rows) do
                    for sKey, sItem in ipairs(searchData.rows) do
                        if item.id == sItem.id then
                            item.level = sItem.level
                            break
                        end
                    end
                end

                callback(data, err)
            end)
        end
    )
end

-- redirect to keepwork get project
-- url:/systemTags/search?classify=1
-- method: POST
-- param: x-page number
-- param: x-per-page number
-- param: classifyTags-like string
-- return object
function KeepworkServiceProject:GetProjectDetailById(kpProjectId, callback, noTryStatus)
    WorldShareKeepworkServiceProject:GetProject(kpProjectId, callback, noTryStatus)
end

function KeepworkServiceProject:GetAllTags(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    KeepworkSystemTagApi:Search(
        function(data, err)
            if err ~= 200 or
               not data or
               not data.rows then
                callback()
                return
            end

            for key, item in ipairs(data.rows) do
                if item.children and
                   type(item.children) == 'table' and
                   #item.children > 0 then
                    table.sort(item.children, function(a, b)
                        if not a.extra or
                           not a.extra.sn or
                           not b.extra or
                           not b.extra.sn then
                            return false
                        end

                        return a.extra.sn < b.extra.sn
                    end)
                end
            end

            callback(data, err)
        end,
        callback
    )
end

-- get recommend works
function KeepworkServiceProject:GetRecommandProjects(tagId, mainId, pages, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    if not tagId or
       type(tagId) ~= 'number' or
       type(mainId) ~= 'number' then
        return
    end

    KeepworkProjectsApi:SearchForParacraft(
        pages and pages.perPage and pages.perPage or 10,
        pages and pages.page and pages.page or 1,
        {
            tagIds = { tagId, mainId },
            sortTag = tagId
        },
        function(data, err)
            if not data or
               type(data) ~= 'table' or
               not data.rows or
               type(data.rows) ~= 'table' then
                return
            end

            local ids = {}

            for key, item in ipairs(data.rows) do
                ids[#ids + 1] = item.id
            end

            ExplorerAppKeepworkProjectsApi:Search(ids, function(searchData, err)
                if not searchData or
                   type(searchData) ~= 'table' or
                   not searchData.rows or
                   type(searchData.rows) ~= 'table' then
                    return
                end

                for key, item in ipairs(data.rows) do
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
        end
    )
end

function KeepworkServiceProject:GetMyFavoriteProjects(pages, callback)
    local xPage = pages.page and pages.page or 1
    local xPerPage = pages.perPage and pages.perPage or 10

    ExplorerAppKeepworkProjectsApi:Favorite(
        xPage,
        xPerPage,
        function(data, err)
            if not data or
               type(data) ~= 'table' or
               not data.rows or
               type(data.rows) ~= 'table' then
                return
            end

            local ids = {}

            for key, item in ipairs(data.rows) do
                ids[#ids + 1] = item.id
            end

            ExplorerAppKeepworkProjectsApi:Search(ids, function(searchData, err)
                if not searchData or
                   type(searchData) ~= 'table' or
                   not searchData.rows or
                   type(searchData.rows) ~= 'table' then
                    return
                end

                for key, item in ipairs(data.rows) do
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
        end,
        callback
    )
end

function KeepworkServiceProject:GetMySchoolProjects(classId, pages, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local xPage = pages.page and pages.page or 1
    local xPerPage = pages.perPage and pages.perPage or 7

    ExplorerAppKeepworkProjectsApi:MySchools(
        classId,
        xPage,
        xPerPage,
        function(data, err)
            if not data or
               type(data) ~= 'table' or
               not data.rows or
               type(data.rows) ~= 'table' then
                return
            end

            local ids = {}

            for key, item in ipairs(data.rows) do
                ids[#ids + 1] = item.id
            end

            ExplorerAppKeepworkProjectsApi:Search(ids, function(searchData, err)
                if not searchData or
                   type(searchData) ~= 'table' or
                   not searchData.rows or
                   type(searchData.rows) ~= 'table' then
                    return
                end

                for key, item in ipairs(data.rows) do
                    for sKey, sItem in ipairs(searchData.rows) do
                        if item.id == sItem.id then
                            item.level = sItem.level
                            item.isSystemGroupMember = sItem.isSystemGroupMember
                            item.timeRules = sItem.timeRules
                            break
                        end
                    end
                end

                callback(data, err)
            end)
        end,
        callback
    )
end