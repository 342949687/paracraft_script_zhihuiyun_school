--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local CollectProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CollectProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkEsServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkEsService/KeepworkEsServiceProject.lua')
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

local CollectProjectList = NPL.export()
local self = CollectProjectList

CollectProjectList.curPage = 1
CollectProjectList.select_project_index = 1
CollectProjectList.worksTree = {}

local page

function CollectProjectList.OnInit()
    page = document:GetPageCtrl()
    if page then
        CollectProjectList.GetProjectList()
    end
end

function CollectProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
    end
    print("Refresh collect project list Page")
end



function CollectProjectList.GetProjectList()
    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10)
    local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
    KeepworkServiceProject:GetMyFavoriteProjects({ page = self.curPage }, function(data, err)
        Mod.WorldShare.MsgBox:Close()

        if not data or
            type(data) ~= 'table' or
            not data.rows or
            type(data.rows) ~= 'table' or
            err ~= 200 then
            return
        end

        local mapData = {}

        -- map data struct
        for key, item in ipairs(data.rows) do
            local isVipWorld = false

            if item.extra and item.extra.isVipWorld == 1 then
                isVipWorld = true
            end

            mapData[#mapData + 1] = {
                id = item.id,
                name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or '',
                cover =
                    item.extra and
                    type(item.extra.imageUrl) == 'string' and
                    item.extra.imageUrl ~= '' and
                    item.extra.imageUrl or
                    'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268',
                username = item.user and type(item.user.username) == 'string' and item.user.username or '',
                updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or '',
                user = item.user and type(item.user) == 'table' and item.user or {},
                isVipWorld = isVipWorld,
                total_view = item.visit,
                total_like = item.star,
                total_mark = item.favorite,
                total_comment = item.comment,
                level = item.level or 0,
                user = item.user,
                isSystemGroupMember = item.isSystemGroupMember,
                isFreeWorld = item.isFreeWorld,
                timeRules = item.timeRules,
                visibility = item.visibility,
                extra = item.extra,
            }
        end

        local rows = mapData

        if self.curPage ~= 1 then
            self.HandleWorldsTree(rows, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end

                if page then
                    local gvw_name = "gw_collect_ds";
                    local  worldDsNode = page:GetNode(gvw_name);
                    if(worldDsNode) then
                        pe_gridview.DataBind(worldDsNode, gvw_name, false);
                    end
                end
            end)
        else
            self.HandleWorldsTree(rows, function(rows)
                self.worksTree = rows
                echo(self.worksTree,true)
                if page then
                    local gvw_name = "gw_collect_ds";
                    local  worldDsNode = page:GetNode(gvw_name);
                    if(worldDsNode) then
                        pe_gridview.DataBind(worldDsNode, gvw_name, false);
                    end
                end
            end)
        end
    end)
end

function CollectProjectList.HandleWorldsTree(rows, callback)
    if not rows or type(rows) ~= 'table' then
        return false
    end

    local projectIds = {}

    for key, item in ipairs(rows) do
        item.isFavorite = false
        item.isStar = false
        item.type = nil

        projectIds[#projectIds + 1] = item.id
    end

    if KeepworkServiceSession:IsSignedIn() then
        keepwork.project.favorite_search({
            objectType = 5,
            objectId = {
                ['$in'] = projectIds,
            }, 
            userId = Mod.WorldShare.Store:Get('user/userId'),
        }, function(status, msg, data)
            if data and
               type(data) == 'table' and
               data.rows and
               type(data.rows) == 'table' and
               #data.rows ~= 0 then
                for key, item in ipairs(rows) do
                    for dKey, dItem in ipairs(data.rows) do
                        if tonumber(item.id) == tonumber(dItem.objectId) then
                            item.isFavorite = true
                        end
                    end
                end
            end

            WorldShareKeepworkServiceProject:GetStaredProjects(projectIds, function(data, err)
                if data and next(data) then
                    for key, item in ipairs(rows) do
                        for dKey, dItem in ipairs(data.rows) do
                            if tonumber(item.id) == tonumber(dItem.projectId) then
                                item.isStar = true
                            end
                        end
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(rows)
                end
            end)
        end)
    else
        if callback and type(callback) == 'function' then
            callback(rows)
        end
    end
end

function CollectProjectList.OnOpenProject(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return
    end
    local username = Mod.WorldShare.Store:Get('user/username')
    local user = curItem.user
    if (user and user.username == username) then
        GameLogic.RunCommand('/loadworld -s -auto ' .. curItem.id)
        return
    end

    local isCanEnter = true
    if curItem.visibility == 1 then
        if not KeepworkServiceSession:IsSignedIn() then
            isCanEnter = false 
        end
        if curItem.level == 0 then
            isCanEnter = false
        end
    end

    if curItem.isSystemGroupMember and curItem.level == 0 then
        isCanEnter = false
    end

    local extra = curItem.extra
    if not curItem.isSystemGroupMember and
            ((extra.vipEnabled and extra.vipEnabled == 1) or
            (extra.isVipWorld and extra.isVipWorld == 1)) then
            if not KeepworkServiceSession:IsSignedIn() then
                isCanEnter = false
            else
                if not GameLogic.IsVip() then
                    isCanEnter = false
                end
            end
    end
    if isCanEnter then
        GameLogic.RunCommand('/loadworld -s -auto ' .. curItem.id)
    else
        GameLogic.AddBBS(nil,"该项目暂无访问权限！",3000,"255 0 0")
    end
end

function CollectProjectList.OnSwitchWorld(index)
    if self.select_project_index ~= index then
        self.select_project_index = index
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_collect_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end
end

function CollectProjectList.IsProjectSelected(index)
    if index == self.select_project_index then
        return true
    end

    return false
end

function CollectProjectList.SearchProject(searchText)
    if not searchText or type(searchText) ~= 'string' or searchText == '' then
        return
    end
    --CollectProjectList.GetProjectList(searchText)
end


--收藏
function CollectProjectList.OnFavoriteProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.favorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = true
        worldinfo.total_mark = worldinfo.total_mark + 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_collect_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--取消收藏
function CollectProjectList.OnUnfavoriteProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.unfavorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = false
        worldinfo.total_mark = worldinfo.total_mark - 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_collect_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--点赞
function CollectProjectList.OnStarProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = true
        worldinfo.total_like = worldinfo.total_like + 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_collect_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--取消点赞
function CollectProjectList.OnUnstarProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = false
        worldinfo.total_like = worldinfo.total_like - 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_collect_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end