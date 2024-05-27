--[[
Title: Purchasing Code
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local PurchasingCode = NPL.load("(gl)Mod/ExplorerApp/pages/PurchasingCode/PurchasingCode.lua")
------------------------------------------------------------
]]

local Notice = NPL.load("./Notice/Notice.lua")
local Result = NPL.load("./Result/Result.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local ParacraftDevices = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/ParacraftDevices.lua')

local PurchasingCode = NPL.export()

PurchasingCode.balance = 0

function PurchasingCode:ShowPage()
    self.balance = Wallet:GetUserBalance()

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/PurchasingCode/PurchasingCode.html", "Mod.ExplorerApp.PurchasingCode", 0, 0, "_fi", false, 3)
end

function PurchasingCode:SetPage()
    Mod.WorldShare.Store:Set("page/PurchasingCode", document:GetPageCtrl())
end

function PurchasingCode:ClosePage()
    local PurchasingCodePage = Mod.WorldShare.Store:Get('page/PurchasingCode')

    if (PurchasingCodePage) then
        PurchasingCodePage:CloseWindow()
    end
end

function PurchasingCode:GetNotice()
    self:ClosePage()
    Notice:ShowPage()
end

function PurchasingCode:Confirm()
    local PurchasingCodePage = Mod.WorldShare.Store:Get('page/PurchasingCode')

    if not PurchasingCodePage then
        return false
    end

    local code = PurchasingCodePage:GetValue('code')

    if not code or #code == 0 then
        _guihelper.MessageBox(L"请输入激活码")
        return false
    end

    ParacraftDevices:Recharge(code, function(data, err)
        if err ~= 200 then
            _guihelper.MessageBox(L"此激活码已被使用")
            return false
        end

        self.balance = self.balance + tonumber(data)
        Wallet:SetUserBalance(self.balance)
        self:ClosePage()
        Result:ShowPage(data)
    end)

end