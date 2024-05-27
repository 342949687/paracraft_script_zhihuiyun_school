--[[
Title: share world to datasource
Author(s): big
CreateDate: 2017.05.12
ModifyDate: 2023.4.11
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')
ShareWorld:Init()
-------------------------------------------------------
]]

-- libs
NPL.load('(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua')

local SnapshotPage = commonlib.gettable('MyCompany.Apps.ScreenShot.SnapshotPage')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

-- UI
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

local ShareWorld = NPL.export()

function ShareWorld:Init(callback, customShowPage)
    if KeepworkServiceSession:GetUserWhere() == 'LOCAL' and
       not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld then
        return
    end

    self.callback = callback
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local http_env = HttpWrapper.GetDevVersion()
    local bShowShareCode = http_env ~= "LOCAL" and http_env ~= "STAGE" and  http_env ~= "RELEASE" 
    -- read only world
    if (GameLogic.IsReadOnly() or currentEnterWorld.is_zip) and bShowShareCode and not customShowPage then
        -- self:ShowWorldCode(currentEnterWorld.kpProjectId)
        return
    end

    -- confirm preview jpg exist
    if not GameLogic.IsReadOnly() and
       not ParaIO.DoesFileExist(self:GetPreviewImagePath(), false) then
        -- self:TakeSharePageImage()
    end

    -- must login
    if not KeepworkService:IsSignedIn() then
        function Handle()
            KeepworkServiceProject:GetProjectIdByWorldName(
                currentEnterWorld.foldername,
                currentEnterWorld.shared,
                function()
                    Compare:GetCurrentWorldInfo(
                        function()
                            Compare:Init(currentEnterWorld.worldpath, function(result)
                                if result then
                                    if customShowPage and type(customShowPage) == 'function' then
                                        customShowPage()
                                    else
                                        self:ShowPage()
                                    end
                                end
                            end)
                        end
                    )
                end
            )
        end

        LoginModal:ShowPage()
        Mod.WorldShare.Store:Set('user/AfterLogined', Handle)

        return
    end

    Mod.WorldShare.MsgBox:Wait()

    Compare:Init(currentEnterWorld.worldpath, function(result)
        Mod.WorldShare.MsgBox:Close()

        if result then
            if customShowPage and type(customShowPage) == 'function' then
                customShowPage()
            else
                self:ShowPage()
            end
        end
    end)
end

function ShareWorld:CheckRealName(callback)
    if not callback or type(callback) ~= 'function' then
        return false
    end

    if KeepworkServiceSession:IsRealName() then
        callback()
    else
        local username = Mod.WorldShare.Store:Get('user/username')
        local session = SessionsData:GetSessionByUsername(username)

        if not session.doNotNoticeVerify then
            Certificate:Init(function()
                callback()
            end)
        else
            callback()
        end
    end
end

function ShareWorld:ShowPage()
    if System.options.isPapaAdventure then
        NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
        local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
        GameLogic.QuickSave()
        Creation.submitType = 2
        Creation:ShowOpusSubmitPage()
        return
    end
    local params = Mod.WorldShare.Utils.ShowWindow(
        640,
        415,
        'Mod/WorldShare/cellar/ShareWorld/Theme/ShareWorld.html',
        'Mod.WorldShare.ShareWorld'
    )

    local filePath = self:GetPreviewImagePath()

    if params._page then
        if ParaIO.DoesFileExist(filePath) then
            params._page:SetUIValue('share_world_image', filePath)
        else
            params._page:SetUIValue('share_world_image', 'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268')
        end
    end
end

function ShareWorld:GetPreviewImagePath()
    if not ParaWorld.GetWorldDirectory() then
        return ''
    end

    if System.os.GetPlatform() ~= 'win32' then
        return ParaIO.GetWritablePath() .. ParaWorld.GetWorldDirectory() .. 'preview.jpg'
    else
        return ParaWorld.GetWorldDirectory() .. 'preview.jpg'
    end
end

function ShareWorld:GetPage()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.ShareWorld')
end

function ShareWorld:ClosePage()
    if self:GetPage() then
        self:GetPage():CloseWindow()
    end
end

function ShareWorld:Refresh()
    if self:GetPage() then
        self:GetPage():Refresh(0.01)
    end
end

function ShareWorld:GetWorldSize()
    local worldpath = ParaWorld.GetWorldDirectory()

    if not worldpath then
        return 0
    end

    local filesTotal = LocalService:GetWorldSize(worldpath)

    return Mod.WorldShare.Utils.FormatFileSize(filesTotal),filesTotal
end

function ShareWorld:GetRemoteRevision()
    return tonumber(Mod.WorldShare.Store:Get('world/remoteRevision')) or 0
end

function ShareWorld:GetCurrentRevision()
    return tonumber(Mod.WorldShare.Store:Get('world/currentRevision')) or 0
end

function ShareWorld:OnClick(notShowFinishPage)
    local canBeShare = true
    local msg = ''

    if WorldCommon:IsModified() then
        canBeShare = false
        msg = L'当前世界未保存，是否继续上传世界？'
    end

    if canBeShare and self:GetRemoteRevision() > self:GetCurrentRevision() then
        canBeShare = false
        msg = L'当前本地版本小于远程版本，是否继续上传？'
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not LocalServiceWorld:CheckWorldIsCorrect(currentEnterWorld) then
        local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
        ]]

        local worldConfigFile = ParaIO.open(currentEnterWorld.worldpath .. '/worldconfig.txt', 'w')

        worldConfigFile:write(worldConfig, #worldConfig)
        worldConfigFile:close()
    end

    local function Handle()
        Mod.WorldShare.Store:Set('world/currentWorld', Mod.WorldShare.Store:Get('world/currentEnterWorld'))
        self:CheckCanUpload(function()
            SyncWorld:CheckTagName(function()
                SyncWorld:SyncToDataSource(
                    function(result, msg)
                        Compare:GetCurrentWorldInfo(function()
                            if self.callback and type(self.callback) == 'function' then
                                self.callback(true)
                            end
                        end)
                    end,
                    notShowFinishPage
                )
    
                self:ClosePage()
    
                -- act week
                -- if self:GetCurrentRevision() > self:GetRemoteRevision() then
                --     local ActWeek = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua')
                --     if ActWeek then
                --         ActWeek.AchieveActTarget()
                --     end
                -- end
            end)
        end)
    end

    if not canBeShare then
        _guihelper.MessageBox(
            msg,
            function(res)
                if res and res == 6 then
                    Handle()
                end
            end
        )

        return
    end

    Handle()
end

function ShareWorld:CheckCanUpload(callback)
    if System.options.isPapaAdventure then
        local _,world_size = self:GetWorldSize()
        local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get','world/currentEnterWorld') or {}
        local kpProjectId = currentEnterWorld.kpProjectId or 0
        local params = {}
        if kpProjectId and kpProjectId > 0 then
            -- params.projectId = kpProjectId
        end
        params.fileSize = world_size

        local maxSize = GameLogic.IsVip('LimitWorldSize20Mb',false) == true and 50*1024*1024 or 20*1024*1024
        keepwork.world.checkupload(params,function(err,msg,data)
            if System.options.isDevMode then
                print("err=========",err)
                print("norml maxsize====",maxSize,type(maxSize),world_size,type(world_size))
                echo(data,true)
            end
            if err == 200 and data == true then
                if  world_size < maxSize  then
                    --GameLogic.AddBBS(nil,"空间大小检测通过，开始上传")
                end
                if callback then
                    callback()
                end
            else
                if err == 401 then
                    GameLogic.AddBBS(nil,"上传失败，登录信息获取失败..")
                    return
                end
                GameLogic.AddBBS(nil,"上传失败，远程空间大小不足，请联系客服")
            end
        end)
    else
        callback()
    end
end

function ShareWorld:TakeSharePageImage()
    if SnapshotPage.TakeSnapshot(
        self:GetPreviewImagePath(),
        300,
        200,
        false
       ) then
        self:UpdateImage(true)
    end
end

function ShareWorld:Snapshot()
    -- take a new screenshot
    self:TakeSharePageImage()

    CommandManager:RunCommand('/save')
end

function ShareWorld:UpdateImage(bRefreshAsset)
    if self:GetPage() then
        local filePath = self:GetPreviewImagePath()

        self:GetPage():SetUIValue('share_world_image', filePath)

        -- release asset
        if bRefreshAsset then
            ParaAsset.LoadTexture('', filePath, 1):UnloadAsset()
        end
    end
end

function ShareWorld:ShowWorldCode(projectId)
    Mod.WorldShare.MsgBox:Wait()

    KeepworkServiceProject:GenerateMiniProgramCode(
        projectId,
        function(bSucceed, wxacode)
            Mod.WorldShare.MsgBox:Close()

            if not bSucceed then
                GameLogic.AddBBS(nil, L'生成二维码失败', 3000, '255 0 0')
                return
            end

            Mod.WorldShare.Utils.ShowWindow(
                520,
                305,
                'Mod/WorldShare/cellar/ShareWorld/Code.html?wxacode='.. (wxacode or ''),
                'Mod.WorldShare.ShareWorld.Code'
            )
        end
    )
end

-- get keepwork project url
function ShareWorld:GetShareUrl()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld or
       not currentEnterWorld.kpProjectId or
       currentEnterWorld.kpProjectId == 0 then
        return ''
    end

    return format('%s/pbl/project/%d/', KeepworkService:GetKeepworkUrl(), currentEnterWorld.kpProjectId)
end

function ShareWorld:GetWorldName()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    return currentEnterWorld.text or ''
end
