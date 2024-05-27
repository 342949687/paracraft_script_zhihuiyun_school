--[[
Title: Password
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Password = NPL.load("(gl)Mod/ExplorerApp/pages/Password/Password.lua")
------------------------------------------------------------
]]
local SetCoins = NPL.load("../SetCoins/SetCoins.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local UpdatePassword = NPL.load("./UpdatePassword/UpdatePassword.lua")

local Password = NPL.export()

Password.password = ''
Password.mode = 'enter'

function Password:ShowPage()
    Password.password = ''

    if not Wallet:GetUserPassword() then
        Password.mode = 'set'
    end

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/Password/Password.html", "Mod.ExplorerApp.Password", 0, 0, "_fi", false, 3)

    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if PasswordPage then
        self:FocusPassword()
    end
end

function Password:SetPage()
    Mod.WorldShare.Store:Set("page/Password", document:GetPageCtrl())
end

function Password:ClosePage()
    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if (PasswordPage) then
        PasswordPage:CloseWindow()
    end
end

function Password:Refresh(time)
    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if (PasswordPage) then
        PasswordPage:Refresh(time or 0.01)
    end
end

function Password:FocusPassword()
    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if not PasswordPage then
        return false
    end

    PasswordPage:FindControl('password'):Focus()
end

function Password:ClearPassword()
    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if not PasswordPage then
        return false
    end

    PasswordPage:SetValue('password', '')
    self.password = ''
    self:Refresh(0)
end

function Password:Confirm()
    if not self.password then
        return false
    end

    if self.mode == 'enter' then
        if string.reverse(self.password) == Wallet:GetUserPassword('password') then
            self:ClosePage()
            SetCoins:ShowPage()
        else
            _guihelper.MessageBox(L'密码错误')
            self:ClearPassword()
            self:FocusPassword()
        end
    end

    if self.mode == 'set' then
        if #self.password < 4 then
            _guihelper.MessageBox(L'密码长度不对')
            self:ClearPassword(0)
            self:FocusPassword()
            return false
        end

        Wallet:SetUserPassword(string.reverse(self.password))
        self:ClosePage()
        self.mode = 'enter'
        SetCoins:ShowPage()
    end
end

function Password:UpdateViewPassword()
    local PasswordPage = Mod.WorldShare.Store:Get('page/Password')

    if not PasswordPage then
        return false
    end

    local password = PasswordPage:GetValue('password')

    if not password then
        return false
    end

    if #password > 4 or string.match(password, "[^%d]+") then
        PasswordPage:SetValue('password', Password.password)
        return false
    end

    Password.password = password
    PasswordPage:SetValue('password', password)

    self:Refresh(0)
    self:FocusPassword()
end

function Password:UpdatePassword()
    self:ClosePage()
    UpdatePassword:ShowPage()
end