--[[
Title: Panorama
Author(s): big
CreateDate: 2020.10.16
ModifyDate: 2022.7.11
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Panorama = NPL.load('(gl)Mod/WorldShare/cellar/Panorama/Panorama.lua')
Panorama:ShowCreate(true)
------------------------------------------------------------
]]

-- lib
local Screen = commonlib.gettable('System.Windows.Screen')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local EntityManager = commonlib.gettable('MyCompany.Aries.Game.EntityManager')

-- UI
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')

-- service
local KeepworkServicePanorama = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServicePanorama.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')

local Panorama = NPL.export()

function Panorama:ShowCreate(force)
    if (System.os.IsEmscripten()) then
        _guihelper.MessageBox(L"Web版不支持此功能");
        return
    end
    LoginModal:CheckSignedIn(L'登录后才能分享全景图', function(bSucceed)
        if bSucceed then
            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

            if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
                _guihelper.MessageBox(
                    L'你还没将你的世界分享至服务器哦，请先将世界分享至服务器，再进行全景图分享',
                    function(res)
                        ShareWorld:Init(nil, function()
                            self:ShowCreate(force)
                        end)
                    end,
                    _guihelper.MessageBoxButtons.OK
                )

                return
            end

            local width = Screen:GetWidth()
            local height = Screen:GetHeight()

            local scaleWidth = width * 0.6
            local scaleHeight = height * 0.7

            Mod.WorldShare.MsgBox:Show(L'请稍候...')
            KeepworkServiceProject:GetProject(currentEnterWorld.kpProjectId, function(data, err)
                Mod.WorldShare.MsgBox:Close()

                if not force and data and type(data) == 'table' and data.extra and data.extra.cubeMap and #data.extra.cubeMap > 0 then
                    if data.userId then
                        local userId = Mod.WorldShare.Store:Get('user/userId')

                        if data.userId == userId then
                            self:ShowShare(true)
                        else
                            self:ShowShare(false)
                        end
                    else
                        self:ShowShare(false)
                    end
                else
                    if not data.userId then
                        return false
                    end

                    local userId = Mod.WorldShare.Store:Get('user/userId')

                    if data.userId == userId then
                        GameLogic.GetFilters():apply_filters("update_dock",true)
                        local params = Mod.WorldShare.Utils.ShowWindow(
                            width,
                            height,
                            format(
                                'Mod/WorldShare/cellar/Panorama/Create.html?width=%d&height=%d&scaleWidth=%d&scaleHeight=%d',
                                tonumber(width),
                                tonumber(height),
                                scaleWidth,
                                scaleHeight
                            ),
                            'Mod.WorldShare.Panorama.Create',
                            nil,
                            nil,
                            nil,
                            false
                        )
                    else
                        GameLogic.AddBBS(nil, L'这个作品的创建者还没拍摄过全景图哦，暂时无法进行全景图分享。', 4000, '255 0 0')
                    end
                end
            end)
        end
    end)
end

function Panorama:ShowPreview()
    local params = Mod.WorldShare.Utils.ShowWindow(500, 653, '(ws)Panorama/Preview.html', 'Mod.WorldShare.Panorama.Preview')

    if params._page then
        params._page:CallMethod('panorama_preview', 'SetVisible', bShow ~= false) 
        params._page.OnClose = function()
            if params._page then
                params._page:CallMethod('panorama_preview', 'SetVisible', false)
            end
        end
    end
end

function Panorama:ShowShare(beShowButton)
    Mod.WorldShare.MsgBox:Show(L'正在生成小程序二维码...', 8000)
    KeepworkServicePanorama:GenerateMiniProgramCode(function(bSucceed, wxacode)
        Mod.WorldShare.MsgBox:Close()

        if not bSucceed then
            GameLogic.AddBBS(nil, L'生成小程序二维码失败', 3000, '255 0 0')
            return
        end

        local height = 305

        if beShowButton then
            height = 392
        end

        self.wxacodeUrl = wxacode
        local params = Mod.WorldShare.Utils.ShowWindow(520, height, 'Mod/WorldShare/cellar/Panorama/Share.html?height=' .. height, 'Mod.WorldShare.Panorama.Share')
    end)
end

function Panorama:StartShooting()
    -- _guihelper.MessageBox(L'拍摄全景图期间，请勿操作窗口，否则可能导致拍摄失败。', function(res)
    --     if res and res == _guihelper.DialogResult.Yes then
            local entityPlayer = EntityManager.GetFocus()

            if not entityPlayer then
                GameLogic.AddBBS(nil, L'拍摄全景图失败', 3000, '255 0 0')
                return
            end

            local x, y, z = entityPlayer:GetBlockPos()
        
            GameLogic.GetCodeGlobal():RegisterTextEvent('after_generate_panorama', self.AfterGeneratePanorama)

            CommandManager:Run(format('/panorama %d,%d,%d', x, y, z))
    --     end

    -- end,
    -- _guihelper.MessageBoxButtons.YesNo)
end

function Panorama.AfterGeneratePanorama()
    Panorama:FinishShooting()
end

function Panorama:FinishShooting()
    GameLogic.AddBBS(nil, L'生成全景图完成', 3000, '0 255 0')
    GameLogic.GetCodeGlobal():UnregisterTextEvent('after_generate_panorama', self.AfterGeneratePanorama)

    Mod.WorldShare.MsgBox:Show(L'正在上传全景图，请稍候...', 30000, L'分享失败', 320, 120)
    self:UploadPanoramaPhoto(function(bSucceed)
        Mod.WorldShare.MsgBox:Close()

        if not bSucceed then
            return
        end

        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        self.shareUrl = KeepworkService:GetKeepworkUrl() .. '/wx/Pannellum/' .. currentEnterWorld.kpProjectId

        self:ShowPreview()
    end)
end

function Panorama:UploadPanoramaPhoto(callback)
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
        return false
    end

    if not callback or type(callback) ~= 'function' then
        return false
    end

    KeepworkServiceProject:GetProject(currentEnterWorld.kpProjectId, function(data, err)
        if err ~= 200 or not data or not data.id or not data.userId then
            GameLogic.AddBBS(nil, L'项目不存在', 3000, '255 0 0')
            callback(false)
            return
        end

        local userId = Mod.WorldShare.Store:Get('user/userId')

        if data.userId ~= userId then
            GameLogic.AddBBS(nil, L'此项目不属于你，不能分享', 3000, '255 0 0')
            callback(false)
            return
        end

        KeepworkServicePanorama:Upload(function(bSucceed, fileArray)
            if not bSucceed then
                GameLogic.AddBBS(nil, L'上传全景图失败', 3000, '255 0 0')
                callback(false)
                return
            end

            local params = {
                extra = {
                    cubeMap = fileArray
                }
            }

            KeepworkServiceProject:UpdateProject(currentEnterWorld.kpProjectId, params, function(data, err)
                if err ~= 200 then
                    GameLogic.AddBBS(nil, L'上传全景图失败', 3000, '255 0 0')
                    callback(false)
                end

                EventTrackingService:Send(1, 'click.world.after_upload_panorama')
                callback(true)
            end)
        end)
    end)
end

function Panorama.OnShowTopWindow(state, winId)
	if(winId ~= "panorama_preview" and Panorama.previewPage) then
		Panorama.previewPage:CloseWindow();
        Panorama.previewPage = nil;
	end
end
