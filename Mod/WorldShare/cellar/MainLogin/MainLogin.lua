--[[
Title: Main Login
Author: big  
CreateDate: 2019.12.25
ModifyDate: 2022.04.24
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
MainLogin:ShowUpdatePassword()
------------------------------------------------------------
]]
-- libs
NPL.load("(gl)script/ide/Encoding.lua");
local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
local PlayerAssetFile = commonlib.gettable('MyCompany.Aries.Game.EntityManager.PlayerAssetFile')
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua")
local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
local KeepworkServiceSchoolAndOrg = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua')
local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')

-- bottles
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local RedSummerCampMainPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua')
local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

-- parser
local MdParser = NPL.load('(gl)Mod/WorldShare/parser/MdParser.lua')

local MainLogin = NPL.export()

-- for register
MainLogin.m_mode = 'account'
MainLogin.account = ''
MainLogin.password = ''
MainLogin.phonenumber = ''
MainLogin.phonepassword = ''
MainLogin.phonecaptcha = ''
MainLogin.bindphone = nil

function MainLogin:GetLoginBackground()
    if System.options.ZhyChannel ~= "" then
        return 'Texture/ZhihuiYun/Login/kao_1280x720_32bits.png#0 0 1280 720'
    end
    if System.options.isChannel_430 then
        return 'Texture/Aries/Creator/Paracraft/WorldShare/school_dengluye_1280x720_32bits.png'
    elseif System.options.isEducatePlatform then
        return 'Texture/Aries/Creator/Paracraft/WorldShare/zhihuijiaoyu_1280x720_32bits.png'
    else
        -- return 'Texture/Aries/Creator/Paracraft/WorldShare/dengluye_1280x720_32bits.png'
        -- return 'background-color:#fff4d4';
        return 'background-color:#333333';
    end
end

function MainLogin:Init()
    if System.options.mc == true then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua")
        local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
        GameMainLogin:next_step({ IsLoginModeSelected = false })
    end
end

function MainLogin:TokenTimeOutReLogin()
    MainLogin.reLogin = true
    local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
    LoginModal:Init(function(bIsSucceed)
        if not bIsSucceed then
            local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop")
            Desktop.ForceExit(false)
        end
    end)
end

function MainLogin:Show()
    if Mod.WorldShare.Store:Get('user/clientForceUpdated') then
        return
    end

    ParaUI.GetUIObject('root'):RemoveAll()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua")
    local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
    GameMainLogin:ShowLoginBackgroundPage(true, true, true, true)
    TipRoadManager:ReCreateRoads()

    local platform = System.os.GetPlatform()
    local isTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil);

    if platform == 'android' or
       platform == 'ios' or
       (isTouchDevice and isTouchDevice =='true') then
        local UserProtocolPre = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua");
        if UserProtocolPre then
            UserProtocolPre.CheckShow();
        end
        if (System.os.IsEmscripten() and not KeepworkServiceSession:IsSignedIn()) then
            MainLogin:CmdAutoLogin(function(bIsSuccessed, reason, message)
                self:ShowMobile()
                if (bIsSuccessed) then
                    commonlib.TimerManager.SetTimeout(function()
                        self:Next()
                    end, 0)
                end
            end)
            return;
        end
        self:ShowMobile()
        return
    end

    if (System.os.IsEmscripten() and not KeepworkServiceSession:IsSignedIn()) then
        MainLogin:CmdAutoLogin(function(bIsSuccessed, reason, message)
            self:Show3();
            if (bIsSuccessed) then
                commonlib.TimerManager.SetTimeout(function()
                    self:Next()
                end, 0)
            end
        end)
        return;
    end

    self:Show3()
end

-- 自动登录后行为处理可以在此处添加
function MainLogin:CmdAutoLogin(callback)
    local login_callback = function(bIsSuccessed, reason, message) 
        NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
        if (type(callback) == "function") then
            callback(bIsSuccessed, reason, message);
        end      
    end

    if (System.options.cmdline_token) then
        MainLogin:LoginWithToken(System.options.cmdline_token, login_callback)
    else
        local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
        if PWDInfo and PWDInfo.token and not System.options.IgnoreRememberAccount then
            MainLogin:LoginWithToken(PWDInfo.token, login_callback)
        else
            login_callback(false);
        end
    end
end

function MainLogin:ShowMobile()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginMobile.html',
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
        bToggleShowHide = false
    })

    self:ShowExtra()
    self:ShowMobileLogin()
end

function MainLogin:Show2()
    Mod.WorldShare.Utils.ShowWindow({
        url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLogin.html', 
        name = 'MainLogin', 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -1,
        allowDrag = false,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
    })

    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if not MainLoginPage then
        return
    end

    self:ShowExtra()
    self:SelectMode()
end

function MainLogin:Show3()
    local html_url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLogin.html'
    if System.options.ZhyChannel ~= "" then
        html_url = "script/apps/Aries/Creator/Game/ZhiHuiYun/Login/MainLogin.html"
    elseif System.options.isEducatePlatform then
    	html_url = "script/apps/Aries/Creator/Game/Educate/Login/MainLogin.html"
    end
    if not System.options.isCommunity then
        Mod.WorldShare.Utils.ShowWindow({
            url = html_url, 
            name = 'MainLogin', 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = -1,
            allowDrag = false,
            directPosition = true,
            align = '_fi',
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            cancelShowAnimation = true,
        })
    
        local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')
    
        if not MainLoginPage then
            return
        end
    end

    local paramWorld  = ParaEngine.GetAppCommandLineByParam('world', nil) 
    local hideExtra = paramWorld ~= nil and paramWorld ~= ""
    if System.options.ZhyChannel ~= "" then
        self:ShowExtraZhiHuiYun()
    else
        if not System.options.isEducatePlatform then
            self:ShowExtra()
        else
            self:ShowExtra431()
        end
    end

    -- if not System.options.isChannel_430 and not System.options.isEducatePlatform and not hideExtra  then
    if false then --屏蔽公告
        self:ShowAnnouncement()
    end

    -- tricky: Delay show login because in this step some UI library may be not loaded.
    Mod.WorldShare.Utils.SetTimeOut(function()
        self:ShowLogin()
    end, 0)
end

local function GetLoginPageUrl(isModal)
    local htmlUrl = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLoginCommunity.html?is_modal=' .. (isModal and 'true' or 'false')
    if System.options.isEducatePlatform then
        htmlUrl = 'script/apps/Aries/Creator/Game/Educate/Login/MainLoginLogin.html?is_modal=' .. (isModal and 'true' or 'false')
    end
    if System.options.isCommunity then
        htmlUrl = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/MainLoginLoginCommunity.html' 
    end
    
    if System.options.ZhyChannel ~= "" then
        htmlUrl = 'script/apps/Aries/Creator/Game/ZhiHuiYun/Login/MainLoginLogin.html?is_modal=' .. (isModal and 'true' or 'false')
    end

    if isModal then
        local KickOut = NPL.load('(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua')
        htmlUrl = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLogin.html?is_modal=' .. (isModal and 'true' or 'false')
        if System.options.isEducatePlatform then
            htmlUrl = 'script/apps/Aries/Creator/Game/Educate/Login/MainLoginLoginModal.html'
            if KickOut.isKickOutPageOpened then
                htmlUrl = 'script/apps/Aries/Creator/Game/Educate/Login/MainLoginLoginKickOut.html'
            end
        end
        if System.options.isCommunity then
            htmlUrl = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/MainLoginLoginCommunityModal.html' 
            if KickOut.isKickOutPageOpened then
                htmlUrl = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/MainLoginLoginCommunityKickOut.html'
            end
        end
    end
    -- print("htmlUrl======================: ", htmlUrl)
    return htmlUrl
end 

function MainLogin:ShowLogin(isModal, zorder)
    if KeepworkServiceSession:IsSignedIn() and isModal then
        return
    end

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if MainLoginLoginPage then
        MainLoginLoginPage:CloseWindow()
    end

    local params = {
        url = GetLoginPageUrl(isModal),
        name = 'Mod.WorldShare.cellar.MainLogin.Login',
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or -1,
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
    }

    if not isModal then
        params.DesignResolutionWidth = 1280
        params.DesignResolutionHeight = 720
    end

    Mod.WorldShare.Utils.ShowWindow(params)

    MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if not MainLoginLoginPage then
        return
    end
    if System.options.isEducatePlatform and not System.os.IsEmscripten() then
        local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
        if PWDInfo and not System.options.IgnoreRememberAccount then
            MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')
        end
        return --智慧教育不会走下面的自动登录流程
    end

    if isModal and MainLoginLoginPage then
        local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
        if PWDInfo and PWDInfo.remember_pwd then
            MainLoginLoginPage:SetValue('account', PWDInfo.account or '')
            MainLoginLoginPage:SetValue('password_show', PWDInfo.remember_pwd or '')
            MainLoginLoginPage:SetValue('password_hide', PWDInfo.remember_pwd or '')
            MainLoginLoginPage:SetValue('password', PWDInfo.remember_pwd or '')
            local remember_pwd = MainLoginLoginPage:GetNode('remember_pwd')
            if remember_pwd then
                remember_pwd:SetAttribute('checked', false)
            end
            MainLoginLoginPage:Refresh(0.01)
        else
            MainLoginLoginPage:SetUIValue('account', '')
            MainLoginLoginPage:SetValue('password_show', '')
            MainLoginLoginPage:SetValue('password_hide', '')
            MainLoginLoginPage:SetValue('password', '')
            local remember_pwd = MainLoginLoginPage:GetNode('remember_pwd')
            if remember_pwd then
                remember_pwd:SetAttribute('checked', false)
            end
            MainLoginLoginPage:Refresh(0.01)
        end
    end

    if KeepworkServiceSession:IsSignedIn() then
        MainLoginLoginPage:FindControl('phone_mode').visible = false
        MainLoginLoginPage:FindControl('account_mode').visible = false
        MainLoginLoginPage:FindControl('auto_login_mode').visible = true

        if MainLoginLoginPage:FindControl('change_button') then
            MainLoginLoginPage:FindControl('change_button').visible = true
        end

        if MainLoginLoginPage:FindControl('update_password_button') then
            MainLoginLoginPage:FindControl('update_password_button').visible = true
        end
        MainLoginLoginPage:SetUIValue('auto_username', Mod.WorldShare.Store:Get('user/username') or '')

        if MainLoginLoginPage:FindControl('title_login') then
            MainLoginLoginPage:FindControl('title_login').visible = false
        end
        if MainLoginLoginPage:FindControl('title_username') then
            MainLoginLoginPage:FindControl('title_username').visible = true
        end
    else
        local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
        if PWDInfo and not System.options.IgnoreRememberAccount then
            if System.options.ZhyChannel == "" then
                MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')
            end

            if PWDInfo.rememberMe then
                -- zhy不用自动登录
                if System.options.ZhyChannel ~= "" then
                    return
                end

                local password = PWDInfo.password or ''
                MainLoginLoginPage:SetUIValue('password_show', password)
                MainLoginLoginPage:SetUIValue('password_hide', password)
                MainLoginLoginPage:SetUIValue('password', password)
                MainLoginLoginPage:SetUIValue('account', PWDInfo.account or '')
            end
            
            if PWDInfo.autoLogin then
                if (not System.os.IsEmscripten()) then
                    if (not System.options.cmdline_world or System.options.cmdline_world ~= "") then
                        return;
                    end
                end

                -- zhy不用自动登录
                if System.options.ZhyChannel ~= "" then
                    return
                end

                GameLogic.GetFilters():apply_filters('on_start_login');
                MainLogin:LoginWithToken(PWDInfo.token, function(bSsucceed, reason, message)
                    if bSsucceed then
                        MainLoginLoginPage:SetUIValue('auto_login_name', true)
                        MainLoginLoginPage:SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')

                        local phone_mode = MainLoginLoginPage:FindControl('phone_mode')
                        local account_mode = MainLoginLoginPage:FindControl('account_mode')
                        local auto_login_mode = MainLoginLoginPage:FindControl('auto_login_mode')

                        if phone_mode then
                            phone_mode.visible = false
                        end

                        if account_mode then
                            account_mode.visible = false
                        end

                        if auto_login_mode then
                            auto_login_mode.visible = true
                        end

                        local change_button = MainLoginLoginPage:FindControl('change_button')

                        if change_button then
                            change_button.visible = true
                        end

                        local update_password_button = MainLoginLoginPage:FindControl('update_password_button')

                        if update_password_button then
                            update_password_button.visible = true
                        end

                        MainLoginLoginPage:SetUIValue('auto_username', PWDInfo.account or '')

                        local title_login = MainLoginLoginPage:FindControl('title_login')
                        local title_username = MainLoginLoginPage:FindControl('title_username')

                        if title_login then
                            title_login.visible = false
                        end

                        if title_username then
                            title_username.visible = true
                        end

                        if Mod.WorldShare.Store:Get('user/isSettingLanguage') then
                            Mod.WorldShare.Store:Set('user/isSettingLanguage', false)
                            return
                        end

                        commonlib.TimerManager.SetTimeout(function()
                            self:Next()
                        end,0)
                    end
                end)
            else
                if Mod.WorldShare.Store:Get('user/isSettingLanguage') then
                    Mod.WorldShare.Store:Set('user/isSettingLanguage', false)
    
                    local token = ParaEngine.GetAppCommandLineByParam('temptoken', nil)
                    if not token or token == '' then
                        Mod.WorldShare.Store:Remove('user/token')
                        return
                    end
    
                    GameLogic.GetFilters():apply_filters('on_start_login');
    
                    MainLogin:LoginWithToken(
                        token,
                        function(bSsucceed, reason, message)
                            if bSsucceed then
                                MainLoginLoginPage:SetUIValue('auto_login_name', true)
                                MainLoginLoginPage:SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
            
                                MainLoginLoginPage:FindControl('phone_mode').visible = false
                                MainLoginLoginPage:FindControl('account_mode').visible = false
                                MainLoginLoginPage:FindControl('auto_login_mode').visible = true

                                if MainLoginLoginPage:FindControl('change_button') then
                                    MainLoginLoginPage:FindControl('change_button').visible = true
                                end

                                MainLoginLoginPage:FindControl('update_password_button').visible = true
                                MainLoginLoginPage:SetUIValue('auto_username', PWDInfo.account or '')
            
                                MainLoginLoginPage:FindControl('title_login').visible = false
                                MainLoginLoginPage:FindControl('title_username').visible = true
                            end
                        end
                    )
                end
            end
        end
    end
end

function MainLogin:ShowMobileLogin()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginMobileLoginCommunity.html',
        'Mod.WorldShare.cellar.MainLogin.MainMobileLogin',
        0,
        0,
        '_fi',
        false,
        -1,
        nil,
        false
    )
end

function MainLogin:ShowMobileRegister()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginMobileRegister.html',
        'Mod.WorldShare.cellar.MainLogin.MainMobileRegister',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowMobileSetUser()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginMobileSetUser.html',
        'Mod.WorldShare.cellar.MainLogin.MainMobileSetUser',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowLoginNew()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLoginNew.html',
        'Mod.WorldShare.cellar.MainLogin.LoginNew',
        0,
        0,
        '_fi',
        false,
        -1
    )

    local MainLoginLoginNewPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginNew')

    if not MainLoginLoginNewPage then
        return
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo and not System.options.IgnoreRememberAccount then
        MainLoginLoginNewPage:SetUIValue('account', PWDInfo.account or '')
        self.account = PWDInfo.account
    end
end

function MainLogin:ShowLoginAtSchool(mode)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginLoginAtSchool.html',
        'Mod.WorldShare.cellar.MainLogin.LoginAtSchool',
        0,
        0,
        '_fi',
        false,
        -1
    )

    if params then
        params._page.mode = mode
    end

    local MainLoginLoginAtSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginAtSchool')

    if not MainLoginLoginAtSchoolPage then
        return
    end

    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()

    if PWDInfo and not System.options.IgnoreRememberAccount then
        MainLoginLoginAtSchoolPage:SetUIValue('account', PWDInfo.account or '')
        self.account = PWDInfo.account
    end
end

function MainLogin:ShowRegisterNew(mode)
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginRegisterNew.html',
        'Mod.WorldShare.cellar.MainLogin.RegisterNew',
        0,
        0,
        '_fi',
        false,
        1
    )
end

function MainLogin:ShowRegister(isModal, callback, zorder)
    self.registerCallback = callback
    local htmlUrl = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginRegister.xml?is_modal=' .. (isModal and 'true' or 'false')
    if System.options.isCommunity then
        htmlUrl = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/MainLoginCommunityRegister.html?is_modal=' .. (isModal and 'true' or 'false')
    end
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        htmlUrl,
        'Mod.WorldShare.cellar.MainLogin.Register',
        0,
        0,
        '_fi',
        false,
        zorder or -1
    )
end

function MainLogin:ShowUpdatePassword()
    local htmlUrl = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginUpdatePassword.xml'
    if System.options.isCommunity then
        htmlUrl = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/MainLoginCommunityUpdatePassword.html'
    end
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        htmlUrl,
        'Mod.WorldShare.cellar.MainLogin.UpdatePassword',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowParent()
    Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginParent.html',
        'Mod.WorldShare.cellar.MainLogin.Parent',
        0,
        0,
        '_fi',
        false,
        -1
    )
end

function MainLogin:ShowWhere(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginWhere.html',
        'Mod.WorldShare.cellar.MainLogin.Where',
        0,
        0,
        '_fi',
        false,
        -1
    )

    params._page.callback = function(where)
        if callback and type(callback) == 'function' then
            callback(where)
        end
    end
end

function MainLogin:SelectMode(callback)
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginSelectMode.html',
        'Mod.WorldShare.cellar.MainLogin.SelectMode',
        0,
        0,
        '_fi',
        false,
        -1
    )

    params._page.callback = function(mode)
        if callback and type(callback) == 'function' then
            callback(mode)
            return
        end

        if mode == 'HOME' then
            self:ShowLoginNew()
        elseif mode == 'SCHOOL' then
            self:ShowLoginAtSchool('SCHOOL')
        elseif mode == 'LOCAL' then
            self:ShowLoginAtSchool('LOCAL')
        end
    end
end

function MainLogin:ShowExtra()
    Mod.WorldShare.Utils.ShowWindow(
        400,
        140,
        'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        680,
        320,
        '_rb',
        false,
        0,
        nil,
        false
    )
end
--Utils.ShowWindow(option, height, url, name, x, y, align, allowDrag, zorder, isTopLevel, bToggleShowHide, clickThrough)
function MainLogin:ShowExtra431()
    Mod.WorldShare.Utils.ShowWindow(
        220,
        220,
        'script/apps/Aries/Creator/Game/Educate/Login/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        80,
        520,
        '_lb',
        false,
        0,
        nil,
        false
    )
end

function MainLogin:ShowExtraZhiHuiYun()
    Mod.WorldShare.Utils.ShowWindow(
        220,
        220,
        'script/apps/Aries/Creator/Game/ZhiHuiYun/Login/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        80,
        520,
        '_lb',
        false,
        0,
        nil,
        false
    )
end

function MainLogin:ShowAnnouncement()
    if System.options.isHideVip then
        return
    end

    local url = 'https://api.keepwork.com/core/v0/repos/official%2Fparacraft/files/official%2Fparacraft%2FAnnouncement%2Fannouncement.md'

    HttpRequest:Get(url, nil, nil, function(data, err)
        local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

        if not MainLoginPage then
            return
        end

        self.announcement = MdParser:MdToHtml(data, true)

        Mod.WorldShare.Utils.ShowWindow(
            {
                url = 'Mod/WorldShare/cellar/MainLogin/Theme/MainLoginAnnouncement.html',
                name = 'Mod.WorldShare.cellar.MainLogin.Announcement',
                isShowTitleBar = false,
                DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
                style = CommonCtrl.WindowFrame.ContainerStyle,
                zorder = 0,
                allowDrag = false,
                bShow = nil,
                directPosition = true,
                align = '_ctl',
                x = 65,
                y = 72,
                width = 300,
                height = 421,
                cancelShowAnimation = true,
                bToggleShowHide = true,
            }
        )
    end)
end

function MainLogin:Refresh(times)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if MainLoginPage then
        MainLoginPage:Refresh(times or 0.01)
    end
end

function MainLogin:Close()
    local MainLoginPage = Mod.WorldShare.Store:Get('page/MainLogin')

    if MainLoginPage then
        MainLoginPage:CloseWindow()
    end

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if MainLoginLoginPage then
        MainLoginLoginPage:CloseWindow()
    end

    local MainLoginRegisterPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register')

    if MainLoginRegisterPage then
        MainLoginRegisterPage:CloseWindow()
    end

    local MainLoginParentPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Parent')

    if MainLoginParentPage then
        MainLoginParentPage:CloseWindow()
    end

    local MainLoginExtraPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Extra')

    if MainLoginExtraPage then
        MainLoginExtraPage:CloseWindow()
    end

    local MainLoginAnnouncementPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.MainLoginAnnouncement')

    if MainLoginAnnouncementPage then
        MainLoginAnnouncementPage:CloseWindow()
    end
end

function MainLogin:IsValidCmdLine()
    local cmdline_world = System.options.cmdline_world
    if not cmdline_world or cmdline_world == '' then
        return false
    end
    if cmdline_world:match('^https?://') 
        or cmdline_world:match("loadworld")
        or cmdline_world:match("edu_do_works")
        or (tonumber(cmdline_world) and tonumber(cmdline_world) > 0) then
        return true
    end
    return false
end

function MainLogin:SetTokenLoginProgress(bStart)
    if self:IsValidCmdLine() or not System.options.isEducatePlatform then
        return
    end
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local userName = Mod.WorldShare.Store:Get('user/userName')
    if bStart and userId then
        self.preUserId = userId
        -- self.preUserName = userName
        print('preUserId:', self.preUserId, 'preUserName:', self.preUserName)
        return
    end
    if not bStart and self.preUserId then
        if userId and userId ~= self.preUserId then
            --换了token，如果在世界里面需要退出
            print('userId:', userId, 'userName:', userName,"game is started:", Game.is_started)
            if Game.is_started then
                local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
                WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
                return true
            end
        end
    end
end

function MainLogin:LoginWithToken(token, callback)
    if not token or #token == 0 or System.options.IgnoreRememberAccount then
        if callback and type(callback) == 'function' then
            callback(false, 'RESPONSE', L'TOKEN已过期', 0)
        end
        return
    end
    self:SetTokenLoginProgress(true)
    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候(TOKEN登录)...', 15000, L'链接超时', 450, 120)
    KeepworkServiceSession:LoginWithToken(token, function(response, err)
        if err ~= 200 or not response then
            Mod.WorldShare.MsgBox:Close()

            if response and response.code and response.message then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s(%d)', response.message, response.code))
                end
            else
                if err == 0 then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE', format(L'*网络异常或超时，请检查网络(%d)', err or 0))
                    end
                else
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE',  format(L'*系统维护中(%d)', err or 0))
                    end
                end
            end

            return
        end

        if response and type(response) ~= "table" then
            if callback and type(callback) == 'function' then
                callback(false, 'RESPONSE',  format(L'*数据异常(%d)', err))
            end
            return
        end
        if not response.token then
            response.token = token
        end
        response.autoLogin = true
        -- response.rememberMe = true

        KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
            Mod.WorldShare.MsgBox:Close()
            
            if not bSucceed then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s', message))
                end
                return
            end
            if self:SetTokenLoginProgress() then
                commonlib.TimerManager.SetTimeout(function()
                    if callback and type(callback) == 'function' then
                        callback(true)
                    end
                end, 1000)
            else
                if callback and type(callback) == 'function' then
                    callback(true)
                end
            end
        end)
    end)
end

function MainLogin:MobileRegisterWithPhoneNumber(...)
    KeepworkServiceSession:RegisterWithPhoneAndLogin(...)
end

function MainLogin:MobileLoginWithPhoneNumber(phoneNumber, captcha, callback)
    if not Validated:Phone(phoneNumber) then
        if callback and type(callback) == 'function' then
            callback(false, 'ACCOUNT', L'*手机号码格式错误')
        end
        return
    end

    if not captcha then
        if callback and type(callback) == 'function' then
            callback(false, 'CAPTCHA', L'*验证码不能为空')
        end
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候(验证码登录)...', 15000, L'链接超时', 450, 120)

    KeepworkServiceSession:LoginWithPhoneNumber(phoneNumber, captcha, function(response, err)
        if not response then
            if callback and type(callback) == 'function' then
                callback(false, 'RESPONSE', L"网络请求返回异常")
            end
            return
        end
        response.autoLogin = true
        response.rememberMe = true

        KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
            Mod.WorldShare.MsgBox:Close()

            if not bSucceed then
                if callback and type(callback) == 'function' then
                    callback(false, 'RESPONSE', format(L'*%s', message))
                end
                return
            end

            if callback and type(callback) == 'function' then
                callback(bSucceed)
            end
        end)
    end)
end

function MainLogin:MobileLoginAction(account, password, callback)
    if not Validated:AccountCompatible(account) then
        if callback and type(callback) == 'function' then
            callback(false, 'ACCOUNT', L'*用户名不合法')
        end
        return
    end

    if not Validated:Password(password) then
        if callback and type(callback) == 'function' then
            callback(false, 'PASSWORD', L'*密码不合法')
        end
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 15000, L'链接超时', 300, 120)

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE', format(L'*%s(%d)', response.message, response.code))
                    end
                else
                    if err == 0 then
                        if callback and type(callback) == 'function' then
                            callback(false, 'RESPONSE', format(L'*网络异常或超时，请检查网络(%d)', err))
                        end
                    else
                        if callback and type(callback) == 'function' then
                            callback(false, 'RESPONSE',  format(L'*系统维护中(%d)', err))
                        end
                    end
                end

                return
            end

            response.autoLogin = true
            response.rememberMe = true

            KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
                Mod.WorldShare.MsgBox:Close()

                if not bSucceed then
                    if callback and type(callback) == 'function' then
                        callback(false, 'RESPONSE',   format(L'*%s', message))
                    end
                    return
                end

                if callback and type(callback) == 'function' then
                    callback(true)
                end

                local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

                if AfterLogined and type(AfterLogined) == 'function' then
                    AfterLogined(true)
                    Mod.WorldShare.Store:Remove('user/AfterLogined')
                end
            end)
        end
    )
end

function MainLogin:LoginAction(callback)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if not MainLoginPage then
        return false
    end

    MainLoginPage:FindControl('account_field_error').visible = false
    MainLoginPage:FindControl('password_field_error').visible = false

    local account = MainLoginPage:GetValue('account')
    local password = MainLoginPage:GetValue('password')

    local pwdNode = MainLoginPage:GetNode('remember_password_name')
    local rememberMe = false

    if pwdNode then
        local rememberMe = pwdNode.checked
    end

    local autoLoginNode = MainLoginPage:GetNode('auto_login_name')
    local autoLogin = false

    if autoLoginNode then
        autoLogin = autoLoginNode.checked
    end

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 15000, L'链接超时', 320, 120, nil, nil, nil, true)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()
        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response or type(response) ~= "table" then
                Mod.WorldShare.MsgBox:Close()
                if response and type(response) ~= "table" then
                    _guihelper.MessageBox(format(L'服务器数据错误(%d/%s)', err or 0, tostring(response)))
                    return
                end
                if response and response.code and response.message then
                    if response.code == 77 then
                        _guihelper.MessageBox(format(L'*%s(%d)', response.message, response.code))
                    end

                    MainLoginPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))

                    local accountFieldError = MainLoginPage:FindControl('account_field_error')

                    if accountFieldError then
                        accountFieldError.visible = true
                    end

                    MainLogin:CheckAutoRegister(account, password, callback)
                else
                    if err == 0 then
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))

                        local accountFieldError = MainLoginPage:FindControl('account_field_error')

                        if accountFieldError then
                            accountFieldError.visible = true
                        end
                    else
                        MainLoginPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))

                        local accountFieldError = MainLoginPage:FindControl('account_field_error')

                        if accountFieldError then
                            accountFieldError.visible = true
                        end
                    end

                    if callback and type(callback) == 'function' then
                        callback(false)
                    end
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            if string.find(password, 'paracraft.cn') == 1 then
                response.rememberMe = true
            end

            local remember_pwd = MainLoginPage:GetValue('remember_pwd')
            local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
            if System.options.ZhyChannel ~= "" then
                response.rememberMe = true
            end
            if remember_pwd then
                KeepworkServiceSession:SaveSigninInfo(
                    {
                        account = account,
                        loginServer = KeepworkService:GetEnv(),
                        remember_pwd = password
                    }
                )
            else
                KeepworkServiceSession:SaveSigninInfo(
                    {
                        account = account,
                        loginServer = KeepworkService:GetEnv(),
                        remember_pwd = ''
                    }
                )
            end

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:LoginActionNew(callback)
    local MainLoginNewPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginNew')

    if not MainLoginNewPage then
        return false
    end

    MainLoginNewPage:FindControl('account_field_error').visible = false
    MainLoginNewPage:FindControl('password_field_error').visible = false

    local account = MainLoginNewPage:GetValue('account')
    local password = MainLoginNewPage:GetValue('password')

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginNewPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginNewPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginNewPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginNewPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 15000, L'链接超时', 300, 120)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()

        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginNewPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))
                    MainLoginNewPage:FindControl('account_field_error').visible = true
                else
                    if err == 0 then
                        MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginNewPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginNewPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginNewPage:FindControl('account_field_error').visible = true
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(false)
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:LoginAtSchoolAction(callback)
    local MainLoginAtSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.LoginAtSchool')

    if not MainLoginAtSchoolPage then
        return false
    end

    MainLoginAtSchoolPage:FindControl('account_field_error').visible = false
    MainLoginAtSchoolPage:FindControl('password_field_error').visible = false

    local account = MainLoginAtSchoolPage:GetValue('account')
    local password = MainLoginAtSchoolPage:GetValue('password')

    local validated = true

    if not Validated:AccountCompatible(account) then
        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', L'*账号不合法')
        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
        validated = false
    end

    if not Validated:Password(password) then
        MainLoginAtSchoolPage:SetUIValue('password_field_error_msg', L'*密码不合法')
        MainLoginAtSchoolPage:FindControl('password_field_error').visible = true
        validated = false
    end

    if not validated then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 15000, L'链接超时', 300, 120)

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()

        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end

        if not bSucceed then
            MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*%s', message))
            MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
            return
        end

        local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

        if type(AfterLogined) == 'function' then
            AfterLogined(true)
            Mod.WorldShare.Store:Remove('user/AfterLogined')
        end
    end

    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()

                if response and response.code and response.message then
                    MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*%s(%d)', response.message, response.code))
                    MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                else
                    if err == 0 then
                        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                    else
                        MainLoginAtSchoolPage:SetUIValue('account_field_error_msg', format(L'*系统维护中(%d)', err))
                        MainLoginAtSchoolPage:FindControl('account_field_error').visible = true
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(false, err)
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function MainLogin:RegisterWithAccount(callback, autoLogin)
    if not Validated:Account(self.account) then
        return
    end

    if not Validated:Password(self.password) then
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120, 10)

    KeepworkServiceSession:RegisterWithAccount(
        self.account,
        self.password,
        function(state)
            Mod.WorldShare.MsgBox:Close()

            if not state then
                GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
                return
            end
            
            if state.id then
                if state.code then
                    if tonumber(state.code) == 429 then
                        _guihelper.MessageBox(L'操作过于频繁，请在一个小时后再尝试。')
                    else
                        GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
                    end
                else
                    -- set default user role
                    local filename = self.GetValidAvatarFilename('boy01')
                    GameLogic.options:SetMainPlayerAssetName(filename)

                    -- register success
                end

                if self.callback and type(self.callback) == 'function' then
                    self.callback(true)
                end

                if callback and type(callback) == 'function' then
                    callback(true)
                end

                if state.isGetVip then
                    local VipRewardPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua');
                    VipRewardPage.SetShow(true);
                end

                return
            end

            GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
        end,
        autoLogin
    )
end

function MainLogin:RegisterWithPhone(callback)
    if not Validated:Phone(self.phonenumber) then
        return false
    end

    if not Validated:Password(self.password) then
        return false
    end

    if not Validated:Account(self.account) then
        return false
    end

    if not self.phonecaptcha or self.phonecaptcha == '' then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120)

    KeepworkServiceSession:RegisterWithPhone(self.account, self.phonenumber, self.phonecaptcha, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
            else
                -- set default user role
                local filename = self.GetValidAvatarFilename('boy01')
                GameLogic.options:SetMainPlayerAssetName(filename)

                -- register success
            end

            if self.callback and type(self.callback) == 'function' then
                self.callback(true)
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end
            
            if state.isGetVip then
                local VipRewardPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua');
                VipRewardPage.SetShow(true);
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
    end)
end

function MainLogin:ExecuteCmdLineCmd()
    local isEducateCommand = System.options.cmdline_secretkey and System.options.cmdline_secretkey ~= ""
    if System.options.isEducatePlatform and isEducateCommand then
        local userId = Mod.WorldShare.Store:Get('user/userId') or ""
        local token = System.options.cmdline_token or ""
        local myKey = ParaMisc.md5(userId.."+"..token);
        -- LOG.std(nil, 'info', 'MainLogin', "myKey:========="..myKey.."，cmdline_secretkey========="..(System.options.cmdline_secretkey or ""))
        -- LOG.std(nil, 'info', 'MainLogin', "token=========="..(System.options.cmdline_token or ""))
        -- LOG.std(nil, 'info', 'MainLogin', "userId=========="..userId)
        -- LOG.std(nil, 'info', 'MainLogin', "cmdline_cmd========="..(System.options.cmdline_cmd or ""))
        if (myKey and myKey ~= "" and myKey ~= System.options.cmdline_secretkey) or not System.options.cmdline_secretkey or System.options.cmdline_secretkey == "" then
            System.options.cmdline_secretkey = nil
            System.options.cmdline_token = nil
            System.options.cmdline_world = nil
            GameLogic.AddBBS(nil,L"功能访问码错误，稍后登录智慧教育平台")
            return false
        end
    end
    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
    if System.options.cmdline_cmd and System.options.cmdline_cmd ~= '' then
        local cmd = System.options.cmdline_cmd or '';
        CommandManager:RunCommand(cmd);
        System.options.cmdline_cmd = nil;

        return true;
    end

    return false;
end

function MainLogin:Next(isLocal)
    if isLocal == true then
        System.options.loginmode = 'local'
    else
        System.options.loginmode = nil
    end

    if System.options.cmdline_world and System.options.cmdline_world ~= '' then
        self:Close()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua")
        local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
        GameMainLogin:CheckLoadWorldFromCmdLine()
        return
    end

    if (self:ExecuteCmdLineCmd()) then 
        return 
    end 

    if System.options.loginmode == 'local' then
        OfflineAccountManager:ShowActivationPage()
    else
        self:Close()
        RedSummerCampMainPage.Show()
    end
    self:JudgeTokenEnough()
end

function MainLogin:JudgeTokenEnough()
    local platform = System.os.GetPlatform();
    local isTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil);

    if not (platform == 'android' or platform == 'ios' or (isTouchDevice and isTouchDevice =='true'))then
        KeepworkServiceSession:JudgeTokenEnough()
    end
end

-- Depreciated
function MainLogin:EnterUserConsole(isOffline)
    self:Next(isOffline)
end

function MainLogin:GetHistoryUsers()
    if System.options.IgnoreRememberAccount then
        return {}
    end
    return SessionsData:GetSessions().allUsers
end

function MainLogin:Exit()
    Desktop.ForceExit()
end

function MainLogin.GetValidAvatarFilename(playerName)
    if playerName then
        PlayerAssetFile:Init()
        return PlayerAssetFile:GetValidAssetByString(playerName)
    end
end

-- 自动注册功能 账号不存在 用户的密码为：paracraft.cn+1位以上的数字 则帮其自动注册
function MainLogin:CheckAutoRegister(account, password, callback)
    local MainLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
    local start_index,end_index = string.find(password, 'paracraft.cn')
    local school_id = string.match(password, 'paracraft.cn(%d+)')
    if string.find(password, 'paracraft.cn') == 1 and school_id then
        if MainLoginPage then
            MainLoginPage:SetUIValue('account_field_error_msg', '')
        end
        
        KeepworkServiceSession:CheckUsernameExist(account, function(bIsExist)
            if not bIsExist then
                -- 查询学校
                KeepworkServiceSchoolAndOrg:SearchSchoolBySchoolId(tonumber(school_id), function(data)
                    if data and data[1] and data[1].id then
                        
                        MainLogin:AutoRegister(account, password, callback, data[1])
                    end
                end)
            else
                _guihelper.MessageBox(string.format('用户名%s已经被注册，请更换用户名，建议使用名字拼音加出生日期，例如： zhangsan2010', account))
            end
        end)
    else
        if callback and type(callback) == 'function' then
            callback(false)
        end
    end
end

function MainLogin:AutoRegister(account, password, login_cb, school_data)
    if not Validated:Account(account) then
        _guihelper.MessageBox([[1.账号需要4位以上的字母或字母+数字组合；<br/>
        2.必须以字母开头；<br/>
        <div style='height: 20px;'></div>
        *推荐使用<div style='color: #ff0000;float: lefr;'>名字拼音+出生年份，例如：zhangsan2010</div>]]);
        return false
    end

    if not Validated:Password(password) then
        _guihelper.MessageBox(L'*密码不合法')
        return false
    end

    keepwork.tatfook.sensitive_words_check({
        word = account,
    }, function(err, msg, data)
        if err == 200 then
            -- 敏感词判断
            if data and #data > 0 then
                local limit_world = data[1]
                local begain_index, end_index = string.find(account, limit_world)
                local begain_str = string.sub(account, 1, begain_index-1)
                local end_str = string.sub(account, end_index+1, #account)
                
                local limit_name = string.format([[%s<div style='color: #ff0000;float: lefr;'>%s</div>%s]], begain_str, limit_world, end_str)
                _guihelper.MessageBox(string.format('您设定的用户名包含敏感字符 %s，请换一个。', limit_name))
                return
            end

            local region_desc = ''
            local region = school_data.region
            if region then
                local state = region.state and region.state.name or ''
                local city = region.city and region.city.name or ''
                local county = region.county and region.county.name or ''
                region_desc = state .. city .. county
            end
            
            local register_str = string.format('%s是新用户，你是否希望注册并默认加入学校%s：%s%s', account, school_data.id, region_desc, school_data.name)
            
            _guihelper.MessageBox(register_str, function()
                MainLogin.account = account
                MainLogin.password = password
    
                self.callback = nil
                MainLogin:RegisterWithAccount(function()
                    -- page:SetValue('account_result', account)
                    -- page:SetValue('password_result', password)
                    -- set_finish()
                    login_cb(true)

                    MainLogin:UpdatePasswordRemindVisible(true)
                    Mod.WorldShare.MsgBox:Show(L'正在加入学校，请稍候...', 10000, L'链接超时', 500, 120)
                    Mod.WorldShare.Utils.SetTimeOut(function()
                        KeepworkServiceSchoolAndOrg:ChangeSchool(school_data.id, function(bSuccessed)
                            Mod.WorldShare.MsgBox:Close()
                        end) 
                    end, 500)
                end, false)
            end)
        end
    end)
end

function MainLogin:UpdatePasswordRemindVisible(flag)
    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
    if MainLoginLoginPage==nil then --runtime error
        return
    end
    local remind = MainLoginLoginPage:FindControl('update_button_remind')
    local password = MainLoginLoginPage:GetValue('password')

    if not remind or not password then
        return
    end

    if flag and string.find(password, 'paracraft.cn') == 1 then
        remind.visible = true
    else
        remind.visible = false
    end
end
