--[[
Title: Login Modal
Author(s): big
CreateDate: 2018.11.05
ModifyDate: 2022.04.24
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
LoginModal:Init(function(bSucceed) end)
LoginModal:CheckSignedIn('desc', function(bSucceed) end)
------------------------------------------------------------
]]

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")

-- utils
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- bottles
local RegisterModal = NPL.load('(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua')
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')

-- database
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local LoginModal = NPL.export()

-- @param callback: called after successfully signed in. 
function LoginModal:Init(callback,isFromKickOut)
    Mod.WorldShare.Store:Remove('user/AfterLogined')
    self.isFromKickOut = isFromKickOut == true
    if callback and type(callback) == 'function' then
        Mod.WorldShare.Store:Set('user/AfterLogined', function(bIsSucceed)
            return callback(bIsSucceed)
        end)
    end

    self:ShowPage()
end

-- @param desc: login desc
-- @param callback: after login function
function LoginModal:CheckSignedIn(desc, callback)
    if KeepworkServiceSession:IsSignedIn() then
        if callback and type(callback) == 'function' then
            callback(true)
        end

        return true
    else
        Mod.WorldShare.Store:Set('user/loginText', desc)
        self:Init(callback)

        return false
    end
end

function LoginModal:ShowPage()
    MainLogin:ShowLogin(true, 10)
end

function LoginModal:Close(params)
    local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')

    if AfterLogined and type(AfterLogined) == 'function' then
        AfterLogined(params or false)
        Mod.WorldShare.Store:Remove('user/AfterLogined')
    end

    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if MainLoginLoginPage then
        MainLoginLoginPage:CloseWindow()
    end
end

function LoginModal:SetAutoLogin()
    local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue('autoLogin')
    local rememberMe = LoginModalPage:GetValue('rememberMe')
    local password = LoginModalPage:GetValue('password')
    local account = LoginModalPage:GetValue('showaccount')
    
    if autoLogin then
        LoginModalPage:SetValue('rememberMe', true)
    else
        LoginModalPage:SetValue('rememberMe', rememberMe)
    end
    
    LoginModalPage:SetValue('autoLogin', autoLogin)
    LoginModalPage:SetValue('password', password)
    LoginModalPage:SetValue('account', account)
    LoginModalPage:SetValue('showaccount', account)
    self.account = string.lower(account)

    self:Refresh()
end

function LoginModal:SetRememberMe()
    local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')

    if not LoginModalPage then
        return false
    end

    local autoLogin = LoginModalPage:GetValue('autoLogin')
    local password = LoginModalPage:GetValue('password')
    local rememberMe = LoginModalPage:GetValue('rememberMe')
    local account = LoginModalPage:GetValue('showaccount')
    
    if rememberMe then
        LoginModalPage:SetValue('autoLogin', autoLogin)
    else
        LoginModalPage:SetValue('autoLogin', false)
    end
    
    LoginModalPage:SetValue('rememberMe', rememberMe)
    LoginModalPage:SetValue('password', password)
    LoginModalPage:SetValue('account', account)
    LoginModalPage:SetValue('showaccount', account)
    self.account = string.lower(account)

    self:Refresh()
end

function LoginModal:RemoveAccount(username)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')

    if not LoginModalPage then
        return false
    end

    SessionsData:RemoveSession(username)

    if self.account == username then
        self.account = nil

        LoginModalPage:SetValue('autoLogin', false)
        LoginModalPage:SetValue('rememberMe', false)
        LoginModalPage:SetValue('password', '')
        LoginModalPage:SetValue('showaccount', '')
    end

    self:Refresh()
end

function LoginModal:SelectAccount(username)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')

    if not LoginModalPage then
        return false
    end

    local session = SessionsData:GetSessionByUsername(username)

    if not session then
        return false
    end

    self.account = session and session.account or ''

    LoginModalPage:SetValue('autoLogin', session.autoLogin)
    LoginModalPage:SetValue('rememberMe', session.rememberMe)
    LoginModalPage:SetValue('password', session.password)
    LoginModalPage:SetValue('showaccount', session.account or '')

    self:Refresh()
end

function LoginModal:GetHistoryUsers()
    if System.options.IgnoreRememberAccount then
        return {}
    end
    if self.account and #self.account > 0 then
        local allUsers = commonlib.Array:new(SessionsData:GetSessions().allUsers)
        local beExist = false

        for key, item in ipairs(allUsers) do
            item.selected = nil

            if item.value == self.account then
                item.selected = true
                beExist = true
            end
        end

        if not beExist then
            allUsers:push_front({ text = self.account, value = self.account, selected = true })
        end

        return allUsers
    else
        return SessionsData:GetSessions().allUsers
    end
end


-- 自动注册功能 账号不存在 用户的密码为：paracraft.cn+1位以上的数字 则帮其自动注册
function LoginModal:CheckAutoRegister(account, password, callback, response)
    -- local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')
    local start_index,end_index = string.find(password, "paracraft.cn")
    local school_id = string.match(password, "paracraft.cn(%d+)")
    if string.find(password, "paracraft.cn") == 1 and school_id then
        -- LoginModal:SetUIValue('account_field_error_msg', "")
        KeepworkServiceSession:CheckUsernameExist(account, function(bIsExist)
            if not bIsExist then
                -- 查询学校
                KeepworkServiceSchoolAndOrg:SearchSchoolBySchoolId(tonumber(school_id), function(data)
                    if data and data[1] and data[1].id then
                        
                        LoginModal:AutoRegister(account, password, callback, data[1])
                    end
                end)
            else
                _guihelper.MessageBox(string.format("用户名%s已经被注册，请更换用户名，建议使用名字拼音加出生日期，例如： zhangsan2010", account))
            end
        end)
    else
        GameLogic.AddBBS(nil, format(L'登录失败了, 错误信息：%s(%d)', response.message, response.code), 5000, '255 0 0')
    end
end

function LoginModal:AutoRegister(account, password, login_cb, school_data)
    -- local account = page:GetValue('register_account')
    -- local password = page:GetValue('register_account_password') or ''

    if not Validated:Account(account) then
        _guihelper.MessageBox([[1.账号需要4位以上的字母或字母+数字组合；<br/>
        2.必须以字母开头；<br/>
        <div style="height: 20px;"></div>
        *推荐使用<div style="color: #ff0000;float: lefr;">名字拼音+出生年份，例如：zhangsan2010</div>]]);
        return false
    end


    if not Validated:Password(password) then
        _guihelper.MessageBox(L'*密码不合法')
        return false
    end

    keepwork.tatfook.sensitive_words_check({
        word=account,
    }, function(err, msg, data)
        if err == 200 then
            -- 敏感词判断
            if data and #data > 0 then
                local limit_world = data[1]
                local begain_index, end_index = string.find(account, limit_world)
                local begain_str = string.sub(account, 1, begain_index-1)
                local end_str = string.sub(account, end_index+1, #account)
                
                local limit_name = string.format([[%s<div style="color: #ff0000;float: lefr;">%s</div>%s]], begain_str, limit_world, end_str)
                _guihelper.MessageBox(string.format("您设定的用户名包含敏感字符 %s，请换一个。", limit_name))
                return
            end

            local region_desc = ""
            local region = school_data.region
            if region then
                local state = region.state and region.state.name or ""
                local city = region.city and region.city.name or ""
                local county = region.county and region.county.name or ""
                region_desc = state .. city .. county
            end
            
            local register_str = string.format("%s是新用户， 你是否希望注册并默认加入学校%s：%s%s", account, school_data.id, region_desc, school_data.name)
            
            _guihelper.MessageBox(register_str, function()
                RegisterModal.account = account
                RegisterModal.password = password
    
                RegisterModal:RegisterWithAccount(function()
                    -- page:SetValue('account_result', account)
                    -- page:SetValue('password_result', password)
                    -- set_finish()
                    login_cb(true)
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
