--[[
    author:{pbb}
    time:2024-05-12 13:50:48
    uselib:
        local ExploreMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.lua")
        ExploreMainPage.ShowPage()
]]
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkEsServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkEsService/KeepworkEsServiceProject.lua')
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

local ExploreMainPage = NPL.export()
local self = ExploreMainPage

ExploreMainPage.worksTree = {}
ExploreMainPage.categoryTree = {}
ExploreMainPage.categorySelected = {}
ExploreMainPage.categorySelectedIndex = 1
ExploreMainPage.curSelected = 1
ExploreMainPage.mainId = 0
ExploreMainPage.curPage = 1
ExploreMainPage.classId = nil
ExploreMainPage.is_loaded = false
ExploreMainPage.sortList = {
    recommend = { value = L'推荐', key = 'recommend' },
    synthesize = { value = L'综合', key = 'synthesize' },
    updatedAt = { value = L'最新', key = 'updated_at' },
    score = { value = L'热门', key = 'score' },
}
local page
function ExploreMainPage.OnInit()
    page = document:GetPageCtrl()
    if page and not self.is_loaded then
        self.is_loaded = true
        self:SetCategoryTree()
    end
end

function ExploreMainPage.ClearData()
    self.is_loaded = false
    self.worksTree = {}
    self.categoryTree = {}
    self.categorySelected = {}
    self.categorySelectedIndex = 1
    self.curSelected = 1
    self.mainId = 0
    self.curPage = 1
    self.classId = nil
    self.is_loaded = false
end

function ExploreMainPage.ShowPage()
    ExploreMainPage.categorySelectedIndex = 1
    local view_width, view_height = 1090,640
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.html",
        name = "ExploreMainPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    self:SetCategoryTree()
end

function ExploreMainPage:SetCategoryTree(notGetWorks)
    if not page then
        return
    end
    
    KeepworkServiceProject:GetAllTags(
        function(data, err)
            if err ~= 200 or
                type(data) ~= 'table' or
                not data.rows then
                return
            end

            self.categoryTree = {
                { id = -1, value = L'热门', color = 'YELLOW' },
                { id = -2, value = L'最新', color = 'YELLOW' },
            }

            self.categorySelected = { id = -1, value = L'热门', color = 'YELLOW' }

            local level = 1

            local function get_item_level(item)
                if item.children and
                    type(item.children) == 'table' and
                    #item.children > 0 then
                    level = level + 1

                    for _, child in ipairs(item.children) do
                        get_item_level(child)
                    end
                end
            end

            for key, item in ipairs(data.rows) do
                if item and
                item.tagname ~= 'paracraft专用' and
                item.parentId == 0 then
                    level = 1
                    get_item_level(item)

                    local curItem = {
                        id = item.id,
                        value = item.tagname or '',
                        level = level,
                        children = item.children or {}
                    }

                    if item and item.extra and item.extra.enTagname and self:IsEnglish() then
                        curItem.enValue = item.extra.enTagname
                    end

                    curItem.color = 'YELLOW'

                    self.categoryTree[#self.categoryTree + 1] = curItem

                end

                if item.tagname == 'paracraft专用' then
                    self.mainId = item.id
                end
            end
            
            print("categoryTree=============")
            echo(self.categoryTree, true)
            -- page:GetNode('categoryTree'):SetUIAttribute('DataSource', self.categoryTree)
            if page then
                page:Refresh(0)
            end
            
            if not notGetWorks then
                self:SetWorksTree()
            end

        end
    )
end

function ExploreMainPage:SetWorksTree()
    if not page then
        return
    end
    print("categorySelected===============")
    echo(self.categorySelected, true)
    local categoryItem = self.categorySelected

    if not categoryItem or
       type(categoryItem) ~= 'table' or
       not categoryItem.id then
        return
    end

    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10)

    self.curSelected = 1
    self.isSearching = false
    self.isClassList = false
    self.isFavorite = false
    self.isHistory = false

    if categoryItem.id ~= -1 and categoryItem.id ~= -2 then
        print("loadding other=====================")
        KeepworkServiceProject:GetRecommandProjects(
            categoryItem.id,
            self.mainId,
            { page = self.curPage },
            function(data, err)
                Mod.WorldShare.MsgBox:Close()
                print("err===========", err)
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
                        extra = {
                            award = {     
                                text = item.extra and
                                       type(item.extra.award) == 'table' and
                                       type(item.extra.award.text) == 'string' and
                                       item.extra.award.text or '',
                                desc = item.extra and
                                       type(item.extra.award) == 'table' and
                                       type(item.extra.award.desc) == 'string' and
                                       item.extra.award.desc or '',
                            },
                        },
                        username = item.user and type(item.user.username) == 'string' and item.user.username or '',
                        updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or '',
                        user = item.user and type(item.user) == 'table' and item.user or {},
                        isVipWorld = isVipWorld,
                        total_view = item.visit,
                        total_like = item.star,
                        total_mark = item.favorite,
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
                    self:HandleWorldsTree(rows, function(rows)
                        for key, item in ipairs(rows) do
                            self.worksTree[#self.worksTree + 1] = item
                        end

                        if page then
                            local gvw_name = "gw_explore_ds";
                            local  worldDsNode = page:GetNode(gvw_name);
                            if(worldDsNode) then
                                pe_gridview.DataBind(worldDsNode, gvw_name, false);
                            end
                        end
                    end)
                else
                    self:HandleWorldsTree(rows, function(rows)
                        self.worksTree = rows

                        if page then
                            local gvw_name = "gw_explore_ds";
                            local  worldDsNode = page:GetNode(gvw_name);
                            if(worldDsNode) then
                                pe_gridview.DataBind(worldDsNode, gvw_name, false);
                            end
                        end
                    end)
                end
            end
        )

        return
    else
        -- hotest and newest
        local sort = ''

        if categoryItem.id == -1 then
            sort = self.sortList.score.key
        elseif categoryItem.id == -2 then
            sort = self.sortList.updatedAt.key
        else
            return
        end
        KeepworkEsServiceProject:GetEsProjectsByFilter(
            { 'paracraft专用' },
            sort,
            { page = self.curPage },
            function(data, err)
                if not data or
                   type(data) ~= 'table' or
                   not data.hits or
                   type(data.hits) ~= 'table' or
                   err ~= 200  then
                    self.worksTree = {}
                    if page then
                        local gvw_name = "gw_explore_ds";
                        local  worldDsNode = page:GetNode(gvw_name);
                        if(worldDsNode) then
                            pe_gridview.DataBind(worldDsNode, gvw_name, false);
                        end
                    end
                    Mod.WorldShare.MsgBox:Close()
                    return
                end

                local usernames = {}
    
                for key, item in ipairs(data.hits) do
                    if item and type(item) == 'table' then
                       if item.username and
                          type(item.username) == 'string' then
                            local beExisted = false
        
                            for uKey, uItem in ipairs(usernames) do
                                if uItem and type(uItem) == 'string' and uItem == item.username then
                                    beExisted = true
                                end
                            end
        
                            if not beExisted then
                                usernames[#usernames + 1] = item.username
                            end
                        end

                        if item.visibility and
                           type(item.visibility) == 'string' then
                            if item.visibility == 'public' then
                                item.visibility = 0
                            else
                                item.visibility = 1
                            end
                        end
                    end
                end

                KeepworkServiceSession:GetUsersByUsernames(usernames, function(usersData, usersErr)
                    if not usersData or type(usersData) ~= 'table' or
                       not usersData.rows or type(usersData.rows) ~= 'table' or
                       err ~= 200  then
                        return
                    end
        
                    for key, item in pairs(data.hits) do
                        if item and type(item) == 'table' then
                            for uKey, uItem in ipairs(usersData.rows) do
                                if uItem and type(uItem) == 'table' then
                                    if uItem.username == item.username then
                                        item.user = commonlib.copy(uItem)
                                    end
                                end
                            end
    
                            if item.world_tag_name then
                                item.name = item.world_tag_name
                            end

                            if not item.level then
                                item.level = 0
                            end

                            if not item.cover or item.cover == '' then
                                item.cover = 'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268'
                            end
                        end
                    end

                    local rows = data.hits
        
                    if self.curPage ~= 1 then
                        self:HandleWorldsTree(rows, function(rows)
                            for key, item in ipairs(rows) do
                                self.worksTree[#self.worksTree + 1] = item
                            end
                            
                            if page then
                                local gvw_name = "gw_explore_ds";
                                local  worldDsNode = page:GetNode(gvw_name);
                                if(worldDsNode) then
                                    pe_gridview.DataBind(worldDsNode, gvw_name, false);
                                end
                            end

                            Mod.WorldShare.MsgBox:Close()
                        end)
                    else
                        self:HandleWorldsTree(rows, function(rows)
                            self.worksTree = rows
                            if page then
                                local gvw_name = "gw_explore_ds";
                                local  worldDsNode = page:GetNode(gvw_name);
                                if(worldDsNode) then
                                    pe_gridview.DataBind(worldDsNode, gvw_name, false);
                                end
                            end

                            Mod.WorldShare.MsgBox:Close()
                        end)
                    end
                end)
            end
        )
    end
end

function ExploreMainPage:SetCategoryItem(categoryItem)
    self.categorySelected = categoryItem
    self:SetWorksTree()
end

function ExploreMainPage:HandleWorldsTree(rows, callback)
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

function ExploreMainPage.ChangeMenuTab(index)
    if self.categorySelectedIndex == index then
        return
    end
    self.worksTree = {}
    self.curSelected = 1
    -- self.mainId = 0
    self.curPage = 1
    self.categorySelectedIndex = index
    local categoryItem = self.categoryTree[index]
    self:SetCategoryItem(categoryItem)
    if page then
        page:Refresh(0)
    end
end

function ExploreMainPage.GetCategoryDSIndex()
    return self.categorySelectedIndex
end

function ExploreMainPage.GetMenuData()
    return self.categoryTree
end

function ExploreMainPage:IsEnglish()
    local Translation = commonlib.gettable('MyCompany.Aries.Game.Common.Translation')
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end

function ExploreMainPage.IsProjectSelected(index)
    return self.curSelected == index
end

function ExploreMainPage.OnSwitchWorld(index)
    if index and self.curSelected ~= index then
        self.curSelected = index
        if page then
            local gvw_name = "gw_explore_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end
end

function ExploreMainPage.OnOpenProject(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return
    end

    GameLogic.RunCommand(format('/loadworld -auto %d', curItem.id))
end

--收藏
function ExploreMainPage.OnFavoriteProject(index)
    local worldinfo = ExploreMainPage.worksTree[index]
    if not worldinfo then return end
    keepwork.world.favorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = true
        worldinfo.total_mark = worldinfo.total_mark + 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_explore_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--取消收藏
function ExploreMainPage.OnUnfavoriteProject(index)
    local worldinfo = ExploreMainPage.worksTree[index]
    if not worldinfo then return end
    keepwork.world.unfavorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = false
        worldinfo.total_mark = worldinfo.total_mark - 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_explore_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--点赞
function ExploreMainPage.OnStarProject(index)
    local worldinfo = ExploreMainPage.worksTree[index]
    if not worldinfo then return end
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = true
        worldinfo.total_like = worldinfo.total_like + 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_explore_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end

--取消点赞
function ExploreMainPage.OnUnstarProject(index)
    local worldinfo = ExploreMainPage.worksTree[index]
    if not worldinfo then return end
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = false
        worldinfo.total_like = worldinfo.total_like - 1
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_explore_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end)
end


