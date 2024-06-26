--[[
Title: Keepwork Service Project
Author(s):  big
CreateDate: 2019.02.18
ModifyDate: 2022.6.28
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
------------------------------------------------------------
]]

local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local Encoding = commonlib.gettable('commonlib.Encoding')

-- service
local KeepworkServiceSession = NPL.load('./KeepworkServiceSession.lua')

-- api
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')
local KeepworkProjectStarApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectStarApi.lua')
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldsApi.lua')
local KeepworkMembersApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkMembersApi.lua')
local KeepworkAppliesApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkAppliesApi.lua')

local KeepworkServiceProject = NPL.export()

function KeepworkServiceProject:OnWorldLoad()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and currentEnterWorld.kpProjectId then
        self:Visit(currentEnterWorld.kpProjectId)
    end
end

-- This api will create a keepwork paracraft project and associated with paracraft world.
function KeepworkServiceProject:CreateProject(foldername, platform, callback)
    if not KeepworkServiceSession:IsSignedIn() or
       not foldername or
       not platform or
       not callback or
       type(callback) ~= 'function' then
        return
    end

    KeepworkProjectsApi:CreateProject(foldername, platform, callback, callback)
end

-- update projectinfo
function KeepworkServiceProject:UpdateProject(kpProjectId, params, callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    KeepworkProjectsApi:UpdateProject(kpProjectId, params, callback)
end

-- get projectinfo
function KeepworkServiceProject:GetProject(kpProjectId, callback, noTryStatus)
    KeepworkProjectsApi:GetProject(kpProjectId, callback, callback, noTryStatus)
end

-- get project members
function KeepworkServiceProject:GetMembers(pid, callback)
    KeepworkMembersApi:Members(pid, 5, -1, callback, callback)
end

-- add members
function KeepworkServiceProject:AddMembers(pid, users, callback)
    if not pid or type(users) ~= 'table' then
        return false
    end

    KeepworkMembersApi:Bulk(pid, 5, users, callback, callback)
end

-- handle apply
function KeepworkServiceProject:HandleApply(id, isAllow, callback)
    KeepworkAppliesApi:AppliesId(id, isAllow, callback, callback)
end

-- apply
function KeepworkServiceProject:Apply(message, callback)
    local userId = Mod.WorldShare.Store:Get('user/userId')

    if not userId then
        return false
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    KeepworkAppliesApi:PostApplies(currentWorld.kpProjectId, 5, 0, userId, message, callback, callback)
end

-- remove user from member
function KeepworkServiceProject:RemoveUserFromMember(id, callback)
    KeepworkMembersApi:DeleteMembersId(id, callback, callback)
end

-- get apply list
function KeepworkServiceProject:GetApplyList(pid, callback)
    KeepworkAppliesApi:Applies(pid, 5, 0, callback, callback)
end

-- get project id by worldname
function KeepworkServiceProject:GetProjectIdByWorldName(foldername, shared, callback)
    if not callback or type(callback) ~= 'function' then
        GameLogic.AddBBS(nil,"获取世界数据异常",3000,"255 0 0")
        LOG.std(nil,"info","KeepworkServiceProject","get worldinfo error"..tostring(foldername).." callfunc nil")
        return
    end

    if not KeepworkServiceSession:IsSignedIn() then
        GameLogic.AddBBS(nil,"你已离线，请退出重新登录",3000,"255 0 0")
        LOG.std(nil,"info","KeepworkServiceProject","get worldinfo error"..tostring(foldername).." user logout")
        return
    end

    local userId = tonumber(Mod.WorldShare.Store:Get('user/userId'))

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if not data or type(data) ~= 'table' then
            GameLogic.AddBBS(nil,"获取世界数据异常",3000,"255 0 0")
            LOG.std(nil,"info","KeepworkServiceProject","get worldinfo error"..tostring(foldername)..","..tostring(err))
            return
        end

        local bIsExist = false
        local world

        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
        local curWorldId;
        if currentWorld then
            curWorldId = currentWorld.kpProjectId;
        end

        for key, item in ipairs(data) do
            if item.user and item.user.id == userId then
                -- remote world info mine
                if not shared then
                    bIsExist = true
                    world = item
                    break
                end
            else
                -- remote world info shared
                if shared then
                    bIsExist = true
                    world = item
                    break
                end
            end
        end
        -- fixed by LiXizhi: for some external bugs, we located a shared world with same name as local world.
        if(bIsExist and curWorldId and world and world.projectId~=curWorldId) then
            echo({"error: TODO for BIG: fix this, as this should never happen!"})
            for key, item in ipairs(data) do
                if(curWorldId == item.projectId) then
                    world = item
                    break
                end
            end     
        end
        
        if bIsExist then
            if not world or
               type(world) ~= 'table' or
               not world.projectId then
                callback()
                return
            end

            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

            if currentWorld then
                currentWorld.kpProjectId = world.projectId
                Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
            end
    
            callback(world.projectId)
        else
            callback()
        end
    end,function(data, err)
        if err == 401 then
            GameLogic.AddBBS(nil, L'请先登录')
            GameLogic.GetFilters():apply_filters('logout')
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
            GameLogic.CheckSignedIn(desc or L"请先登录！", function(bSucceed)
                if bSucceed then
                    self:GetProjectIdByWorldName(foldername, shared, callback)
                end
            end);
        end
    end)
end

function KeepworkServiceProject:GetProjectId()
    local urlKpProjectId = self:GetProjectFromUrlProtocol()
    if urlKpProjectId then
        return urlKpProjectId
    end

    local openKpProjectId = Mod.WorldShare.Store:Get('world/openKpProjectId')
    if openKpProjectId then
        return openKpProjectId
    end

    WorldCommon.LoadWorldTag()
    local tagInfo = WorldCommon.GetWorldInfo()

    if tagInfo and tagInfo.kpProjectId and tagInfo.kpProjectId ~= 0 then
        return tagInfo.kpProjectId
    end
end

function KeepworkServiceProject:GetProjectFromUrlProtocol()
    local cmdline = ParaEngine.GetAppCommandLine()
    local urlProtocol = string.match(cmdline or '', 'paracraft://(.*)$')
    urlProtocol = Encoding.url_decode(urlProtocol or '')

    local kpProjectId = urlProtocol:match('kpProjectId="([%S]+)"')

    if kpProjectId then
        return kpProjectId
    end
end

function KeepworkServiceProject:Visit(pid)
    KeepworkProjectsApi:Visit(pid)
end

-- remove a project
function KeepworkServiceProject:RemoveProject(kpProjectId, password, callback)
    if not kpProjectId or
       not password or
       not KeepworkServiceSession:IsSignedIn() then
        return
    end

    KeepworkProjectsApi:RemoveProject(tonumber(kpProjectId), password, callback, callback)
end

-- remove a project with no password
function KeepworkServiceProject:RemoveProjectWithNoPWD(kpProjectId, callback)
    if not kpProjectId or
       not KeepworkServiceSession:IsSignedIn() then
        return
    end

    KeepworkProjectsApi:RemoveProjectWithNoPWD(tonumber(kpProjectId), callback, callback)
end

function KeepworkServiceProject:GenerateMiniProgramCode(projectId, callback)
    if not callback or type(callback) ~= 'function' or not projectId then
        return false
    end

    KeepworkProjectsApi:ShareWxacode(
        tonumber(projectId),
        function(data, err)
            if err ~= 200 or not data or not data.wxacode then
                callback(false)
                return
            end

            callback(true, data.wxacode)
        end,
        function(data, err)
            callback(false)
        end
    )
end

-- get favorited projects
function KeepworkServiceProject:GetStaredProjects(projectIds, callback)
    KeepworkProjectStarApi:Search(projectIds, callback, callback)
end

-- judge project editable
-- true is editable, false is readonly
function KeepworkServiceProject:IsProjectReadOnly(pid, callback)
    if not KeepworkServiceSession:IsSignedIn() or
       not callback or
       type(callback) ~= 'function' then
        return
    end

    self:GetProject(pid, function(data, err)
        if data.level ~= 2 then
            callback(false, data.level)
        else
            callback(true, data.level)
        end
    end)
end

-- level multi-project
function KeepworkServiceProject:LeaveMultiProject(pid, callback)
    KeepworkProjectsApi:Leave(pid, callback, callback)
end

function KeepworkServiceProject:GetFullWorldList(callback)
    KeepworkProjectsApi:FullList(callback,callback)
end
