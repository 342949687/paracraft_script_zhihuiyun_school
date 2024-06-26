--[[
Title: Create Page
Author(s): big
CreateDate: 2020.09.01
ModifyDate: 2021.09.16
Desc: 
use the lib:
------------------------------------------------------------
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
------------------------------------------------------------
]]

-- libs
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local VipTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/VipTypeWorld.lua')
local ShareTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/ShareTypeWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
local Opus = NPL.load('(gl)Mod/WorldShare/cellar/Opus/Opus.lua')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local SyncToLocal = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua')
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

local Create = NPL.export()

Create.currentMenuSelectIndex = 1
Create.page = 1
Create.perPage = 3
Create.worldListType = "ALL"
function Create:Show()
    if System.options.isEducatePlatform  then
        return
    end

    if (System.options.isPapaAdventure) then
        GameLogic.GetFilters():apply_filters("EnterWorldFailed")
        return
    end

    if System.options.isCommunity then
        GameLogic.AddBBS(nil,L"进入世界失败，请重试~~")
        return 
    end
    Opus:Show()
end

function Create:ShowCreateEmbedChanel(channelId,width,height,x,y,useDesginResolution,zorder)
    local channelId = channelId or "paracraft_431"
    local CreateEmbedPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreateEmbedPage then
        CreateEmbedPage:CloseWindow()
    end
    self:UnRegisterComponents()
    self:RegisterComponents(channelId)

    Create.currentMenuSelectIndex = 1
    local view_width = width or 1132
    local view_height = height or 500
    local x = x or -view_width/2
    local y = y or -view_height/2

    local params = {
        url = 'script/apps/Aries/Creator/Game/Educate/Project/CreateEmbed.educate.html',
        name = 'Mod.WorldShare.Create',
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or 0,
        allowDrag = false,
        bShow = nil,
        directPosition = true,
        align = '_ct',
        x = x,
        y = y,
        width = view_width,
        height = view_height,
        cancelShowAnimation = true,
        bToggleShowHide = false,
        click_through = false,
    }
    if useDesginResolution then
        params.DesignResolutionWidth = 1280
        params.DesignResolutionHeight = 720
    end

    Mod.WorldShare.Utils.ShowWindow(params)

    self.page = 1
    self.perPage = 3
    self.worldIndex = 1
    self:GetWorldList(self.statusFilter)
end

function Create:ShowCreateEmbed(width, height, x, y, useDesginResolution)
    local CreateEmbedPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreateEmbedPage then
        CreateEmbedPage:CloseWindow()
    end

    self:RegisterComponents()

    Create.currentMenuSelectIndex = 1

    y = y or -400
    
    local params = {
        url = '(ws)Create/CreateEmbed.html',
        name = 'Mod.WorldShare.Create',
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
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
        bToggleShowHide = false,
        click_through = false,
    }

    if useDesginResolution then
        params.DesignResolutionWidth = 1280
        params.DesignResolutionHeight = 720
    end

    Mod.WorldShare.Utils.ShowWindow(params)

    self.page = 1
    self.perPage = 3
    self.worldIndex = 1
    Compare:MoveOlderWorldToNewFolder()
    self:GetWorldList(self.statusFilter)
end

function Create:RegisterComponents(channelId)
-- components
    local ParacraftEditWorldComponent
    if channelId and channelId == "paracraft_431" then
        ParacraftEditWorldComponent = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Project/ParacraftEditWorld/ParacraftEditWorldComponent.lua')
    else
        ParacraftEditWorldComponent = NPL.load('(gl)Mod/WorldShare/cellar/Create/Components/ParacraftEditWorld/ParacraftEditWorldComponent.lua')
    end
    Map3DSystem.mcml_controls.RegisterUserControl('pe:paracraft_edit_world', ParacraftEditWorldComponent)
end

function Create:UnRegisterComponents()
    Map3DSystem.mcml_controls.UnRegisterUserControl('pe:paracraft_edit_world')
end

function Create:Close()
    self.statusFilter = nil

    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return
    end

    self:UnRegisterComponents()

    CreatePage:CloseWindow()
end 

function Create:OnSwitchWorld(index)
    if not index then
        return
    end

    self:UpdateWorldInfo(index)
end

function Create:UpdateWorldInfo(worldIndex)
    local currentSelectedWorld = Compare:GetSelectedWorld(worldIndex)

    if not currentSelectedWorld  then
        return
    end

    if currentSelectedWorld.status ~= 2 then
        local compareWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')
    
        if not currentSelectedWorld.is_zip then
            local filesize = LocalService:GetWorldSize(currentSelectedWorld.worldpath)
            local worldTag = LocalService:GetTag(currentSelectedWorld.worldpath)
            if worldTag.size and tonumber(worldTag.size) ~= filesize then
                worldTag.size = filesize
                LocalService:SetTag(currentSelectedWorld.worldpath, worldTag)
            end
            compareWorldList[worldIndex].size = filesize
        else
            compareWorldList[worldIndex].revision = LocalService:GetZipRevision(currentSelectedWorld.worldpath)
            compareWorldList[worldIndex].size = LocalService:GetZipWorldSize(currentSelectedWorld.worldpath)
        end

        Mod.WorldShare.Store:Set('world/compareWorldList', compareWorldList)
    end

    Mod.WorldShare.Store:Set('world/currentWorld', currentSelectedWorld)

    self.worldIndex = worldIndex

    self:Refresh(0.01)
end

function Create:Refresh()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return false
    end

    CreatePage:Refresh(0.01)
end

function Create:IsRefreshing()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreatePage and CreatePage.refreshing then
        return true
    else
        return false
    end
end

function Create:SetRefreshing(status)
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return false
    end

    CreatePage.refreshing = status and true or false
    CreatePage:Refresh(0.01)
end

function Create:Sync(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or type(currentWorld) ~= 'table' then
        if callback and type(callback) == 'function' then
            callback(false)
        end
        return
    end
    Mod.WorldShare.MsgBox:Wait()

    Compare:Init(currentWorld.worldpath, function(result)
        Mod.WorldShare.MsgBox:Close()

        if not result then
            GameLogic.AddBBS(nil, L'版本号对比失败', 3000, '255 0 0')
            return
        end

        if result == Compare.JUSTLOCAL then
            SyncWorld:SyncToDataSource(function()
                self:GetWorldList(self.statusFilter,function()
                    if callback and type(callback) == 'function' then
                        callback(true)
                    end
                end)
            end)
        end

        if result == Compare.JUSTREMOTE then
            SyncWorld:SyncToLocal(function()
                SyncWorld:CheckTagName(function(result, remoteName)
                    if result and result == 'remote' then
                        local tag = LocalService:GetTag(currentWorld.worldpath)
    
                        tag.name = remoteName
                        currentWorld.name = remoteName

                        LocalService:SetTag(currentWorld.worldpath, tag)
                        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
                        GameLogic.AddBBS(nil, format(L'更新【%s】名称信息完成', currentWorld.foldername), 3000, '0 255 0')
                    end

                    self:GetWorldList(self.statusFilter,function()
                        if callback and type(callback) == 'function' then
                            callback(true)
                        end
                    end)
                end)
            end)
        end

        if result == Compare.REMOTEBIGGER or
           result == Compare.LOCALBIGGER or
           result == Compare.EQUAL then

            KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(membersData, err)
                if not membersData then
                    membersData = {}
                end

                local members = {}

                for key, item in ipairs(membersData) do
                    members[#members + 1] = item.username
                end

                currentWorld.members = members
                Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
                
                SyncWorld:ShowStartSyncPage(nil, function()
                    self:GetWorldList(self.statusFilter,function()
                        if callback and type(callback) == 'function' then
                            callback(true)
                        end
                    end)
                end)
            end)
        end

        Mod.WorldShare.MsgBox:Close()
    end)
end

function Create.OnMouseWheel()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return
    end

    local worldDS = CreatePage:GetNode('gw_world_ds')
    local curLine = 0

    if worldDS then
        if worldDS:GetChild('pe:treeview') and
           worldDS:GetChild('pe:treeview').control then
            local control = worldDS:GetChild('pe:treeview').control

            if control then
                curLine = math.ceil(control.ClientY / 290)
            end
        end
    end

    local startLine = curLine * 3 - 2
    local startIndex
    local endIndex

    if (startLine - 3) > 0 then
        startIndex = startLine - 3
        endIndex = startIndex + 14
    else
        startIndex = startLine
        endIndex = startIndex + 11
    end

    for key, item in ipairs(Create.pageList) do
        if item and
           (key < startIndex or key > endIndex) then
            if item.status and tonumber(item.status) == 2 then
                local project = item.project

                if project and
                   type(project) == 'table' and
                   project.extra and
                   type(project.extra) == 'table' and
                   project.extra.imageUrl and
                   type(project.extra.imageUrl) == 'string' and
                   project.extra.imageUrl ~= '' then
                    ParaAsset.LoadTexture('', project.extra.imageUrl, 1):UnloadAsset()
                end
            else
                local worldpath = item.worldpath

                if worldpath and type(worldpath) == 'string' then
                    local preview = worldpath .. 'preview.jpg'
                    ParaAsset.LoadTexture('', preview, 1):UnloadAsset()
                end                        
            end
        end
    end
end

function Create:GetPageList()
    if not self.currentWorldList then
        return
    end

    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreatePage then
        self.pageList = {}
        local itemCount = self.page * self.perPage

        for key, item in ipairs(self.currentWorldList) do
            if key <= itemCount then
                self.pageList[#self.pageList + 1] = item
            end
        end

        local  worldDsNode = CreatePage:GetNode('gw_world_ds');
        if(worldDsNode) then
            worldDsNode:SetAttribute('DataSource', self.pageList or {})
        end
        self:Refresh(0.01)
    end
end

function Create:GetWorldList(statusFilter, callback)
    self:SetRefreshing(true)

    Compare:RefreshWorldList(function(currentWorldList)
        self.currentWorldList = currentWorldList
        self:SetRefreshing(false)

        self:GetPageList()

        if callback and type(callback) == 'function' then
            callback(currentWorldList)
        end

        self:OnSwitchWorld(self.worldIndex or 1)
    end, statusFilter,Create.worldListType)
end

function Create:EnterWorld(index, skip)
    local currentSelectedWorld = Compare:GetSelectedWorld(index)

    if not currentSelectedWorld or type(currentSelectedWorld) ~= 'table' then
        return
    end

    LocalServiceHistory:LoadWorld(currentSelectedWorld)
	
    if KeepworkServiceSession:IsSignedIn() or not System.options.DisableOfflineMode then
        -- KeepworkServiceWorld:LimitFreeUser(false, function(result)
        --     if result then
                self:HandleEnterWorld(index, skip)
        --     else
        --         _guihelper.MessageBox(L'操作被禁止了，免费用户最多只能拥有3个本地世界，请删除不要的本地世界，或者联系老师（或家长）开通权限。')
        --     end
        -- end)
    else
        LoginModal:CheckSignedIn(L'请先登录！', function(bIsSuccessed)
            if bIsSuccessed then
                self:GetWorldList(nil, function()
                    local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}

                    for key, item in ipairs(currentWorldList) do
                        if item.kpProjectId == currentSelectedWorld.kpProjectId and
                           item.foldername == currentSelectedWorld.foldername then
                            self:HandleEnterWorld(key)
                            break
                        end
                    end
                end)
            end
        end)
    end
end

function Create:CheckIsProjectMember(kpProjectId,cb)
    KeepworkServiceProject:GetMembers(kpProjectId, function(data, err)
        if data and type(data) ~= 'table' then
            if cb and type(cb) == 'function' then
                cb(false)
            end
            return
        end
        local username = Mod.WorldShare.Store:Get("user/username")
        local isMember = false
        for key, item in ipairs(data) do
            if username == item.username then
                isMember = true
                break
            end
        end
        if cb and type(cb) == 'function' then
            cb(isMember)
        end
    end)
end

function Create:HandleEnterWorld(index, skip)
    local currentSelectedWorld = Compare:GetSelectedWorld(index)

    if not currentSelectedWorld or type(currentSelectedWorld) ~= 'table' then
        return
    end

    -- zip file
    if currentSelectedWorld.is_zip then
        Game.Start(currentSelectedWorld.worldpath)
        return
    end

    -- check world
    if currentSelectedWorld.status ~= 2 then
        if not LocalServiceWorld:CheckWorldIsCorrect(currentSelectedWorld) then
            local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
            ]]

            local worldConfigFile = ParaIO.open(currentSelectedWorld.worldpath .. '/worldconfig.txt', 'w')

            worldConfigFile:write(worldConfig, #worldConfig)
            worldConfigFile:close()
        end
    end

    -- vip world step
    if VipTypeWorld:IsVipWorld(currentSelectedWorld) and not self.vipVerified then
        if not KeepworkServiceSession:IsSignedIn() then
            LoginModal:CheckSignedIn(L'此世界为VIP世界，需要登录后才能继续', function(bIsSuccessed)
                if bIsSuccessed then
                    self:GetWorldList(self.statusFilter, function()
                        local index = Compare:GetWorldIndexByFoldername(
                            currentSelectedWorld.foldername,
                            currentSelectedWorld.shared,
                            currentSelectedWorld.is_zip
                        )
                        self:HandleEnterWorld(index)
                    end)
                end
            end)
        else
            GameLogic.IsVip('Vip', true, function(result)
                if result then
                    self.vipVerified = true
                    self:HandleEnterWorld(index)
                end
            end, 'Vip')
        end

        return
    end

    -- institute vip step
    if VipTypeWorld:IsInstituteVipWorld(currentSelectedWorld) and not self.instituteVerified then
        if not KeepworkServiceSession:IsSignedIn() then
            LoginModal:CheckSignedIn(L'此世界为机构VIP世界，需要登录后才能继续', function(bIsSuccessed)
                if bIsSuccessed then
                    self:GetWorldList(self.statusFilter, function()
                        local index = Compare:GetWorldIndexByFoldername(
                            currentSelectedWorld.foldername,
                            currentSelectedWorld.shared,
                            currentSelectedWorld.is_zip
                        )
                        self:HandleEnterWorld(index)
                    end)
                end
            end)
        else
            VipTypeWorld:CheckInstituteVipWorld(currentSelectedWorld, function(result)
                if result then
                    self.instituteVerified = true
                    self:HandleEnterWorld(index)
                else
                    local username = Mod.WorldShare.Store:Get('user/username')

                    _guihelper.MessageBox(
                        format(
                            L'你没有权限进入此世界（机构VIP）（项目ID：%d）（用户名：%s）',
                            currentSelectedWorld.kpProjectId,
                            username or ''
                        )
                    )
                end
            end)
        end
        return
    end

    -- share world step
    if ShareTypeWorld:IsSharedWorld(currentSelectedWorld) and not self.shareWorldVerified then
        if not KeepworkServiceSession:IsSignedIn() then
            LoginModal:CheckSignedIn(L'此世界为多人世界，请先登录', function(bIsSuccessed)
                if bIsSuccessed then
                    self:GetWorldList(self.statusFilter, function()
                        local index = Compare:GetWorldIndexByFoldername(
                            currentSelectedWorld.foldername,
                            currentSelectedWorld.shared,
                            currentSelectedWorld.is_zip
                        )
                        self:HandleEnterWorld(index)
                    end)
                end
            end)
        else
            local username = Mod.WorldShare.Store:Get('user/username')

            if not currentSelectedWorld.user then
                _guihelper.MessageBox(
                    format(
                        L'你没有权限进入此世界（共享世界）（项目ID：%d）（用户名：%s）',
                        currentSelectedWorld.kpProjectId or 0,
                        username or ''
                    )
                )

                return
            end

            local function Handle()
                if currentSelectedWorld.level == 2 then
                    -- check ouccupy
                    ShareTypeWorld:Lock(currentSelectedWorld, function()
                        self.shareWorldVerified = true
                        self:HandleEnterWorld(index)
                    end)
                elseif currentSelectedWorld.level == 1 then
                    -- download world and encrypted world
                    GameLogic.RunCommand('/loadworld -s -auto ' .. currentSelectedWorld.kpProjectId)
                else
                    _guihelper.MessageBox(
                        format(
                            L'你没有权限进入此世界（共享世界）（项目ID：%d）（用户名：%s）',
                            currentSelectedWorld.kpProjectId,
                            username or ''
                        )
                    )
                end
            end

            self:CheckIsProjectMember(currentSelectedWorld.kpProjectId,function (isMember)
                if isMember then
                    Handle()
                else
                    if username == currentSelectedWorld.user.username then
                        Handle()
                    else
                        GameLogic.IsVip('LimitUserOpenShareWorld', true, function(result)
                            if not result then
                                return
                            end

                            Handle()
                        end)
                    end
                end
            end)
        end

        return
    end

    -- uploaded step
    if currentSelectedWorld.kpProjectId and
       currentSelectedWorld.kpProjectId ~= 0 and
       not KeepworkServiceSession:IsSignedIn() and
       not skip then

	    if(not System.options.DisableOfflineMode and VipTypeWorld:IsWorldInCurrentUserFolder(currentSelectedWorld)) then
			Game.Start(currentSelectedWorld.worldpath)
            self:Close()
			return
		end

        LoginModal:CheckSignedIn(L'请先登录', function(result)
            if result then
                if result == 'THIRD' then
                    return function()
                        self:GetWorldList(self.statusFilter, function()
                            local index = Compare:GetWorldIndexByFoldername(
                                currentSelectedWorld.foldername,
                                currentSelectedWorld.shared,
                                currentSelectedWorld.is_zip
                            )
                            self:HandleEnterWorld(index)
                        end)
                    end
                end

                -- refresh world list after login
                self:GetWorldList(self.statusFilter, function()
                    local index = Compare:GetWorldIndexByFoldername(
                        currentSelectedWorld.foldername,
                        currentSelectedWorld.shared,
                        currentSelectedWorld.is_zip
                    )
                    self:HandleEnterWorld(index)
                end)
            else
                self:HandleEnterWorld(index, true)
            end
        end)
        return
    end

    -- set current world
    self:OnSwitchWorld(index)

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local function DownloadWorldFunc()
        DownloadWorld.ShowPage(format(L'%s（项目ID：%d）', currentWorld.foldername, currentWorld.kpProjectId))

        SyncToLocal:Init(function(result, option)
            if not result then
                if option and type(option) == 'string' then
                    DownloadWorld.Close()

                    if option == 'NEWWORLD' then
                        -- GameLogic.AddBBS(nil, L'服务器未找到您的世界数据，请新建', 3000, '255 255 0')
                        LOG.std(nil, "info", "Create", "can not find world %s in git server", currentWorld.foldername)
                        CreateWorld:CreateNewWorld(currentWorld.foldername,nil,true)
                    end

                    -- GameLogic.AddBBS(nil, option, 3000, '255 0 0')

                    return
                end

                if option and type(option) == 'table' then
                    if option.method == 'UPDATE-PROGRESS-FINISH' then
                        if not LocalServiceWorld:CheckWorldIsCorrect(currentWorld) then
                            -- _guihelper.MessageBox(L'文件损坏，请再试一次。如果还是出现问题，请联系作者或者管理员。')
                            -- return

                            local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
]]

                            local worldConfigFile = ParaIO.open(currentWorld.worldpath .. '/worldconfig.txt', 'w')

                            worldConfigFile:write(worldConfig, #worldConfig)
                            worldConfigFile:close()
                        end

                        DownloadWorld.Close()
                        Game.Start(currentWorld.worldpath)
                    end
                end
            end
        end)
    end

    if currentWorld.status == 2 then
        -- if System.options.isEducatePlatform then
        --     DownloadWorldFunc()
        -- else
        Mod.WorldShare.MsgBox:Wait()
        Compare:Init(currentWorld.worldpath, function(result)
            Mod.WorldShare.MsgBox:Close()

            if result ~= Compare.JUSTREMOTE then
                return
            end
            DownloadWorldFunc()
        end)
        -- end
    else
        if currentWorld.status == 1 or not currentWorld.status then
            Game.Start(currentWorld.worldpath)
            self:Close()
            return
        end

        Mod.WorldShare.MsgBox:Wait()
        Compare:Init(currentWorld.worldpath, function(result)
            Mod.WorldShare.MsgBox:Close()

            if ShareTypeWorld:IsSharedWorld(currentWorld) then
                ShareTypeWorld:CompareVersion(result, function(result)
                    if result == 'SYNC' then
                        SyncWorld:BackupWorld()

                        Mod.WorldShare.MsgBox:Wait()

                        SyncWorld:SyncToLocalSingle(function(result, option)
                            Mod.WorldShare.MsgBox:Close()

                            if result == true then
                                Game.Start(currentWorld.worldpath)
                                self:Close()
                            end
                        end)
                    else
                        Game.Start(currentWorld.worldpath)
                        self:Close()
                    end
                end)
            else
                if result == Compare.REMOTEBIGGER then
                    SyncWorld:ShowStartSyncPage(true, function()
                        self:GetWorldList(self.statusFilter)
                    end)
                else
                    Game.Start(currentWorld.worldpath)
                    self:Close()
                end
            end
        end)
    end

    self.shareWorldVerified = false
    self.vipVerified = false
    self.instituteVerified = false
end

function Create:DeleteWorld(worldIndex,callback)
    self:OnSwitchWorld(worldIndex)

    DeleteWorld:DeleteWorld(function()
        if callback and type(callback) == 'function' then
            callback()
            return
        end
        self:GetWorldList(self.statusFilter)
    end)
end

function Create:WorldRename(currentItemIndex, tempModifyWorldname, callback)
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return
    end

    local currentWorld = Compare:GetSelectedWorld(currentItemIndex)

    if not currentWorld then
        return
    end

    if currentWorld.is_zip then
        GameLogic.AddBBS(nil, L'暂不支持重命名zip世界', 3000, '255 0 0')
        return
    end

    if not tempModifyWorldname or tempModifyWorldname == '' then
        return
    end

    if currentWorld.status ~= 2 then
        if currentWorld.name == tempModifyWorldname then
            return
        end

        local tag = LocalService:GetTag(currentWorld.worldpath)

        -- update local tag name
        tag.name = tempModifyWorldname
        currentWorld.name = tempModifyWorldname

        LocalService:SetTag(currentWorld.worldpath, tag)
        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    end

    if KeepworkServiceSession:IsSignedIn() and
       currentWorld.status and
       currentWorld.status ~= 1 and
       currentWorld.kpProjectId and
       currentWorld.kpProjectId ~= 0 then

        -- update project info
        local tag = LocalService:GetTag(currentWorld.worldpath)

        if currentWorld.status ~= 2 then
            -- update sync world
            -- local world exist

            -- get members for shared world
            KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(data)
                local members = {}

                for key, item in ipairs(data) do
                    members[#members + 1] = item.username
                end
                
                currentWorld.members = members

                Mod.WorldShare.Store:Set('world/currentRevision', currentWorld.revision)
                Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    
                SyncWorld:SyncToDataSource(function(result, msg)
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end)
            end)
        elseif currentWorld.status == 2 then
            -- just remote world exist
            KeepworkServiceWorld:GetWorld(
                currentWorld.foldername,
                currentWorld.shared,
                currentWorld.user.id,
                function(data)
                    local extra = data and data.extra or {}

                    extra.worldTagName = tempModifyWorldname

                    -- local world not exist
                    KeepworkServiceProject:UpdateProject(
                        currentWorld.kpProjectId,
                        {
                            extra = extra
                        },
                        function(data, err)
                            if callback and type(callback) == 'function' then
                                callback()
                            end
                        end
                    )
                end
            )
        end
    else
        if callback and type(callback) == 'function' then
            callback()
        end
    end

    return true
end

function Create:GetCurWorldInfo(infoType, worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = self:GetSelectWorld(index)

    if selectedWorld then
        return selectedWorld[infoType]
    end
end

function Create:GetSelectWorld(index)
    local compareWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    if compareWorldList then
        return compareWorldList[index]
    else
        return nil
    end
end

function Create.FormatStatus(status)
    if status == 1 then
        return L'仅本地'
    elseif status == 2 then
        return L'仅网络'
    elseif status == 3 then
        return L'本地版本与远程数据源一致'
    elseif status == 4 then
        return L'本地版本更加新'
    elseif status == 5 then
        return L'远程版本更加新'
    else
        return L'获取状态中'
    end
end

--设置世界加载的类型，MINE为我的世界，SHARED为共享世界，DELETED为删除的世界，ALL为全部世界
function Create:SetWorldListType(worldType)
    self.worldListType = worldType
end
