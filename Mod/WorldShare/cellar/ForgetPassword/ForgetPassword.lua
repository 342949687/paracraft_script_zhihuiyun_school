--[[
Title: forget password
Author(s):  big
Date: 2019.9.23
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local ForgetPassword = NPL.load("(gl)Mod/WorldShare/cellar/ForgetPassword/ForgetPassword.lua")
ForgetPassword:ShowPage()
------------------------------------------------------------
]]

local Validated = NPL.load("(gl)Mod/WorldShare/helper/Validated.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/Service/KeepworkService/KeepworkServiceSession.lua")

local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')

local ForgetPassword = NPL.export()

function ForgetPassword:ShowPage(isKick)
    self.isKick = isKick

    local url = 'Mod/WorldShare/cellar/ForgetPassword/Theme/ForgetPassword.html'
    if System.options.isEducatePlatform then
        url = 'script/apps/Aries/Creator/Game/Educate/Login/ForgetPassword.html'
    end
    if System.options.isCommunity then
        url = 'script/apps/Aries/Creator/Game/Tasks/Community/Login/ForgetPasswordCommunity.html'
    end

    local params =
        Mod.WorldShare.Utils.ShowWindow(
            0,
            0,
            url,
            'Mod.WorldShare.ForgetPassword',
            0,
            0,
            '_fi',
            false,
            10,
            nil,
            nil,
            nil,
            true
        )
end

function ForgetPassword:Reset()
    local ForgetPasswordPage = Mod.WorldShare.Store:Get("page/Mod.WorldShare.ForgetPassword")

    if not ForgetPasswordPage then
        return false
    end

    local key = ForgetPasswordPage:GetValue('key')
    local captcha = ForgetPasswordPage:GetValue('captcha')
    local password = ForgetPasswordPage:GetValue('password')

    if not Validated:Email(key) and not Validated:Phone(key) then
        GameLogic.AddBBS(nil, L"账号格式错误", 3000, "255 0 0")
        return false
    end

    if captcha == '' then
        GameLogic.AddBBS(nil, L"验证码不能为空", 3000, "255 0 0")
        return false
    end
    
    if not Validated:Password(password) then
        GameLogic.AddBBS(nil, L"密码至少位6位", 3000, "255 0 0")
        return false
    end

    KeepworkServiceSession:ResetPassword(key, password, captcha, function(data, err)
        if err == 200 and data == 'OK' then
            GameLogic.AddBBS(nil, L"重置密码成功", 3000, "0 255 0")

            Mod.WorldShare.Utils.SetTimeOut(function()
                Desktop.ForceExit(false)
            end, 3000)
            return true
        end

        if type(data) ~= 'table' then
            return false
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"重置密码失败，错误信息：", data.message, data.code), 5000, "255 0 0")
    end)
end
