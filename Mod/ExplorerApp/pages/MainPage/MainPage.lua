--[[
Title: Explorer App Page
Author(s):  big
CreateDate: 2019.01.21
ModifyDate: 2022.7.28
Place: Foshan
use the lib:
------------------------------------------------------------
local MainPage = NPL.load('(gl)Mod/ExplorerApp/pages/MainPage/MainPage.lua')
------------------------------------------------------------
]]

-- libs
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua')

local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local Screen = commonlib.gettable('System.Windows.Screen')
local LocalLoadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.LocalLoadWorld')
local Translation = commonlib.gettable('MyCompany.Aries.Game.Common.Translation')

-- databse
local ProjectsDatabase = NPL.load('(gl)Mod/ExplorerApp/database/Projects.lua')

-- components
local RegisterComponents = NPL.load('(gl)Mod/ExplorerApp/components/RegisterComponents.lua')

-- services
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkEsServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkEsService/KeepworkEsServiceProject.lua')
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkServiceSchoolAndOrg = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua')
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

-- api
local KeepworkCommonApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkCommonApi.lua")

-- UI
local Toast = NPL.load('(gl)Mod/ExplorerApp/pages/Toast/Toast.lua')

local MainPage = NPL.export()

MainPage.categorySelected = {}
MainPage.categoryTree = {}
MainPage.worksTree = {}
MainPage.curPage = 1
MainPage.mainId = 0
MainPage.curSelected = 1
MainPage.sortList = {
    recommend = { value = L'推荐', key = 'recommend' },
    synthesize = { value = L'综合', key = 'synthesize' },
    updatedAt = { value = L'最新', key = 'updated_at' },
    score = { value = L'热门', key = 'score' },
}
MainPage.LimitUserOpenShareWorld = false
MainPage.isHoliday = false
MainPage.isVip = false
MainPage.isOrgan = false

function MainPage:ShowPage(callback, classId, defaulOpenValue)
    if callback and type(callback) == 'function' then
        self.CloseCallback = callback
    end

    self.defaulOpenValue = defaulOpenValue

    RegisterComponents:Install()

    local params = Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/ExplorerApp/pages/MainPage/Theme/MainPage.html',
            name = 'Mod.ExplorerApp.MainPage',
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = '_fi',
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
        }
    )

    params._page.OnClose = function()
        self.worksTree = {}
        self.curPage = 1
        self.mainId = 0

        RegisterComponents:Uninstall()
    end

    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')

    if MainPagePage then
        GameLogic.IsVip('LimitUserOpenShareWorld', false, function(result)
            self.LimitUserOpenShareWorld = result

            GameLogic.IsVip('Vip', false, function(result)
                self.isVip = result
                
                GameLogic.IsVip('IsOrgan', false, function(result)
                    self.isOrgan = result

                    KeepworkCommonApi:Holiday(nil, function(data, err)
                        if data and
                           type(data) == 'table' and
                           type(data.isHoliday) == 'boolean' then
                            self.isHoliday = data.isHoliday
                        end
        
                        if classId and type(classId) == 'number' then
                            self:SetCategoryTree(true)
                            self.curPage = 1
                            self:SetMyClassListWorksTree(classId)
                        else
                            self:SetCategoryTree()     
                        end
                    end)
                end, 'Institute')

            end, 'Vip')
        end)
    end
end

function MainPage:ShowExporerEmbed(width, height, x, y)
    self:CloseExplorerEmbed()

    RegisterComponents:Install()

    y = y or -545

    local params = Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/ExplorerApp/pages/MainPage/Theme/ExplorerEmbed.html',
            name = 'Mod.ExplorerApp.MainPage.ExplorerEmbed',
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = '_ct',
            x = -768 / 2,
            y = y / 2,
            width = 1024,
            height = 580,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
        }
    )

    params._page.OnClose = function()
        self.worksTree = {}
        self.curPage = 1
        self.mainId = 0

        RegisterComponents:Uninstall()
    end
end

function MainPage:CloseExplorerEmbed()
    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if ExplorerEmbedPage then
        ExplorerEmbedPage:CloseWindow()
    end
end

function MainPage:Refresh(times)
    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')

    if MainPagePage then
        if type(self.CloseCallback) == 'function' then
            self.CloseCallback()
        end

        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
    local MainPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')

    if not MainPage then
        return false
    end

    local height = math.floor(Screen:GetHeight())
    local width = math.floor(Screen:GetWidth())

    local areaNode = MainPage:GetNode('area')
    areaNode:SetCssStyle('height', height)
    areaNode:SetCssStyle('width', width)

    local stripNode = MainPage:GetNode('strip')
    stripNode:SetCssStyle('margin-left', (width - 960) / 2)

    local areaContentNode = MainPage:GetNode('area_content')
    areaContentNode:SetCssStyle('height', (height - 45))
    areaContentNode:SetCssStyle('margin-left', (width - 960) / 2)

    MainPage:Refresh(0)
end

function MainPage:GetMyClassList(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    KeepworkServiceSchoolAndOrg:GetUserAllSchools(function(data, err)
        if not data or not data.id then
            callback({})
            return
        end

        KeepworkServiceSchoolAndOrg:GetMyClassList(data.id, function(data, err)
            if not data or type(data) ~= 'table' then
                return
            end

            for key, item in ipairs(data) do
                item.tagname = item.name
                item.id = 'c' .. item.id
                item.parentId = -3
            end

            callback(data)
        end)
    end)
end

function MainPage:SetCategoryTree(notGetWorks)
    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')

    if not MainPagePage then
        return
    end

    if System.options.isChannel_430 then
        self:GetMyClassList(
            function(classData, err)
                table.insert(
                    classData,
                    1,
                    {
                        id = 'c0',
                        parentId = 0,
                        tagname = '全校',
                    }
                )

                self.categoryTree = {
                    {
                        id = -3,
                        parentId = 0,
                        level = 2,
                        value = '我的学校',
                        color = 'YELLOW',
                        extra = {
                            enTagname = 'myschool',
                        },
                        children = classData
                    },
                }

                self.categorySelected = { id = -3, value = '我的学校', color = 'YELLOW' }
        
                MainPagePage:GetNode('categoryTree'):SetUIAttribute('DataSource', self.categoryTree)

                if not notGetWorks then
                    self:SetMyClassListWorksTree(-1)
                end
            end
        )
    else
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

                self:GetMyClassList(
                    function(classData, err)
                        table.insert(
                            classData,
                            1,
                            {
                                id = 'c0',
                                tagname = '全校',
                                parentId = 0,
                            }
                        )

                        local myschoolData = {
                            tagname = '我的学校',
                            parentId = 0,
                            extra = {
                                enTagname = 'myschool',
                            },
                            children = classData,
                            id = -3,
                        }
        
                        table.insert(data.rows, 3, myschoolData)
        
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
        
                                if curItem and curItem.value == '大赛作品' then
                                    curItem.color = 'YELLOW'
                                elseif curItem and curItem.value == '我的学校' then
                                    curItem.color = 'YELLOW'
                                elseif curItem and curItem.value == '编程' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '短片' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '场景' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '机器人' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '计算机' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '互动' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '科学' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '语文' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '人文' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '艺术' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '数学' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '生物' then
                                    curItem.color = 'BLACK'
                                elseif curItem and curItem.value == '设计' then
                                    curItem.color = 'BLACK'
                                end
        
                                self.categoryTree[#self.categoryTree + 1] = curItem

                                if self.defaulOpenValue and curItem.value == self.defaulOpenValue then
                                    self.categorySelected = curItem
                                    self.defaulOpenValue = nil
                                end
                            end
        
                            if item.tagname == 'paracraft专用' then
                                self.mainId = item.id
                            end
                        end
        
                        MainPagePage:GetNode('categoryTree'):SetUIAttribute('DataSource', self.categoryTree)
        
                        if not notGetWorks then
                            self:SetWorksTree(self.categorySelected)
                        end
                    end
                )
            end
        )
    end
end

function MainPage:SetMenuItem(categoryItem)
    self:SetCategoryItem(categoryItem)

    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')
    ExplorerEmbedPage:CallMethod('worksTree', 'ScrollToRow', 1)

    -- show fetching message
    ExplorerEmbedPage:CallMethod('worksTree', 'SetDataSource', function() end)
    ExplorerEmbedPage:CallMethod('worksTree', 'DataBind')

    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')
    MainPagePage:SetValue('search_value', '')

    self:Refresh(0)
end

function MainPage:SetCategoryItem(categoryItem)
    self.categorySelected = categoryItem
end

function MainPage:SetMyClassListWorksTree(classId)
    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if not ExplorerEmbedPage then
        return
    end

    if not classId then
        classId = self.classId
    else
        self.classId = classId
        self.worksTree = {}
        self.curSelected = 1
        self.isSearching = false
        self.isFavorite = false
        self.isClassList = true
        self.isHistory = false
    end

    if classId == -1 then
        classId = nil
    end

    KeepworkServiceProject:GetMySchoolProjects(
        classId,
        { page = self.curPage },
        function(data, err)
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
                visibility = item.visibility,
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

                ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
            end)
        else
            self:HandleWorldsTree(rows, function(rows)
                self.worksTree = rows

                ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
            end)
        end
    end)
end

function MainPage:SetMyFavoriteWorksTree()
    GameLogic.IsVip('LimitUserOpenShareWorld', false, function(result)
        self.LimitUserOpenShareWorld = result

        GameLogic.IsVip('Vip', false, function(result)
            self.isVip = result
            
            GameLogic.IsVip('IsOrgan', false, function(result)
                self.isOrgan = result

                KeepworkCommonApi:Holiday(nil, function(data, err)
                    if data and
                       type(data) == 'table' and
                       type(data.isHoliday) == 'boolean' then
                        self.isHoliday = data.isHoliday
                    end

                    self:SetMyFavoriteWorksTreeImp()
                end)
            end, 'Institute')
        end, 'Vip')
    end)
end

function MainPage:SetMyFavoriteWorksTreeImp()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if not ExplorerEmbedPage then
        return
    end

    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10)

    self.curSelected = 1
    self.isSearching = false
    self.isClassList = false
    self.isFavorite = true
    self.isHistory = false
    self.categorySelected = {}

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
            self:HandleWorldsTree(rows, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end

                ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
            end)
        else
            self:HandleWorldsTree(rows, function(rows)
                self.worksTree = rows

                ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
            end)
        end
    end)
end

function MainPage:SetMyHistoryWorksTree()
    GameLogic.IsVip('LimitUserOpenShareWorld', false, function(result)
        self.LimitUserOpenShareWorld = result

        GameLogic.IsVip('Vip', false, function(result)
            self.isVip = result
            
            GameLogic.IsVip('IsOrgan', false, function(result)
                self.isOrgan = result

                KeepworkCommonApi:Holiday(nil, function(data, err)
                    if data and
                       type(data) == 'table' and
                       type(data.isHoliday) == 'boolean' then
                        self.isHoliday = data.isHoliday
                    end

                    self:SetMyHistoryWorksTreeImp()
                end)
            end, 'Institute')
        end, 'Vip')
    end)
end

function MainPage:SetMyHistoryWorksTreeImp()
    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if not ExplorerEmbedPage then
        return
    end

    self.worksTree = {}
    self.curSelected = 1
    self.isSearching = false
    self.isFavorite = false
    self.isClassList = false
    self.isHistory = true
    self.categorySelected = {}

    local historyItems = LocalServiceHistory:GetWorldRecord()

    local historyIds = {}

    for key, item in ipairs(historyItems) do
        historyIds[#historyIds + 1] = item.projectId
    end

    KeepworkServiceProject:GetProjectByIds(
        historyIds,
        { perPage = 10000 },
        function(data, err)
            if not data or
               type(data) ~= 'table' and
               not data.rows and
               type(data.rows) ~= 'table' then
                return
            end

            local mapData = {}

            for key, item in ipairs(data.rows) do
                for hKey, hItem in ipairs(historyItems) do
                    if item.id == hItem.projectId then
                        item.visitTime = hItem.date
                        break
                    end
                end

                mapData[#mapData + 1] = {
                    id = item.id,
                    name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or '',
                    cover = 
                        item.extra and
                        type(item.extra.imageUrl) == 'string' and
                        item.extra.imageUrl and
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
                    visitTime = item.visitTime,
                    level = item.level or 0,
                    user = item.user,
                    isSystemGroupMember = item.isSystemGroupMember,
                    isFreeWorld = item.isFreeWorld,
                    timeRules = item.timeRules,
                    visibility = item.visibility,
                    extra = item.extra,
                }
            end

            table.sort(mapData, function(a, b)
                if not a or
                   not a.visitTime or
                   not b or
                   not b.visitTime then
                    return false
                end

                return a.visitTime > b.visitTime
            end)

            self:HandleWorldsTree(mapData, function(rows)
                self.worksTree = rows

                ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
            end)
        end
    )
end

function MainPage:SetWorksTree()
    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if not ExplorerEmbedPage then
        return
    end

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
        KeepworkServiceProject:GetRecommandProjects(
            categoryItem.id,
            self.mainId,
            { page = self.curPage },
            function(data, err)
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

                        ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
                    end)
                else
                    self:HandleWorldsTree(rows, function(rows)
                        self.worksTree = rows

                        ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
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
                    ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', {})
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
    
                            ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
                            Mod.WorldShare.MsgBox:Close()
                        end)
                    else
                        self:HandleWorldsTree(rows, function(rows)
                            self.worksTree = rows
    
                            ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
                            Mod.WorldShare.MsgBox:Close()
                        end)
                    end
                end)
            end
        )
    end
end

function MainPage:Search()
    local MainPagePage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')
    local ExplorerEmbedPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage.ExplorerEmbed')

    if not MainPagePage or
       not ExplorerEmbedPage then
        return
    end

    if not self.isSearching then
        self.curSelected = 1
        self.isSearching = true
        self.searchValue = MainPagePage:GetValue('search_value')
    end

    local searchValue = self.searchValue

    if not searchValue or (type(searchValue) ~= 'string' and type(searchValue) ~= 'number') then
        return
    end

    KeepworkEsServiceProject:Search(
        searchValue,
        { page = self.curPage },
        function(data, err)
            if not data or not data.hits then
                return
            end

            Mod.WorldShare.Store:Set('explorer/selectSortIndex', 1)
            self.categorySelected = {}

            if self.curPage ~= 1 then
                self:HandleWorldsTree(data.hits, function(rows)
                    for key, item in ipairs(rows) do
                        self.worksTree[#self.worksTree + 1] = item
                    end

                    MainPagePage:SetValue('search_value', searchValue)
                    MainPagePage:Refresh(0)

                    ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
                end)
            else
                self:HandleWorldsTree(data.hits, function(rows)
                    self.worksTree = rows

                    MainPagePage:SetValue('search_value', searchValue)
                    MainPagePage:Refresh(0)

                    ExplorerEmbedPage:GetNode('worksTree'):SetUIAttribute('DataSource', self.worksTree)
                end)
            end
        end
    )
end

function MainPage:HandleWorldsTree(rows, callback)
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
                for key, item in ipairs(rows) do
                    for dKey, dItem in ipairs(data.rows) do
                        if tonumber(item.id) == tonumber(dItem.projectId) then
                            item.isStar = true
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

function MainPage:SelectProject(index)
    self.curProjectIndex = index

    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return
    end

    GameLogic.RunCommand(format('/loadworld %d', curItem.id))
end

function MainPage:GetPage()
    return Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.MainPage')
end

function MainPage:IsEnglish()
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end
