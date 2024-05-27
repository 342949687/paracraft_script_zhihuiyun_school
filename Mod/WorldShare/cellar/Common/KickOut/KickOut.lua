--[[
Title: Kick Out Page
Author(s):  big
Date: 2021.2.3
Desc: 
use the lib:
------------------------------------------------------------
local KickOut = NPL.load('(gl)Mod/WorldShare/cellar/Common/KickOut/KickOut.lua')
KickOut:ShowKickOutPage(1)
------------------------------------------------------------
]]

-- libs
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

local KickOut = NPL.export()

function KickOut:ShowKickOutPage(reason)
    -- 修改密码之后的退出 由接口返回的回调来处理
    if reason == 2 then
        return
    end

    if self.isKickOutPageOpened then 
        return false
    end

    self.isKickOutPageOpened = true

    NplBrowserPlugin.CloseAllBrowsers()
    GameLogic.RunCommand("/macro stop")
    if System.options.isPapaAdventure then
        NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
        local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
        PapaAPI:SetDisplayMode("show")
        PapaAPI:AccountKickOut()
        GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
        return 
    end
    
    Mod.WorldShare.MsgBox:Show(L'您的账号已经在其他地方登录，正在登出...', nil, nil, 460, nil, 1000)
    Mod.WorldShare.Store:Set('user/logoutUsername', Mod.WorldShare.Store:Get('user/username'))
    Mod.WorldShare.Utils.SetTimeOut(function()
        Mod.WorldShare.MsgBox:Close()

        if KeepworkServiceSession:IsSignedIn() then
            -- OnKeepWorkLogout
            KeepworkServiceSession:Logout('KICKOUT', function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
            end)
        else
            -- OnKeepWorkLogout
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", false)
        end
        local url = 'Mod/WorldShare/cellar/Common/KickOut/KickOut.html?reason=' .. reason or 1
        if System.options.isEducatePlatform then
            url = 'script/apps/Aries/Creator/Game/Educate/Login/KickOut.html?reason='.. reason or 1
        end
        Mod.WorldShare.Utils.ShowWindow(
            0,
            0,
            url,
            'Mod.WorldShare.Common.KickOut',
            0,
            0,
            '_fi',
            false,
            10000
        )
    end, 2000)
end