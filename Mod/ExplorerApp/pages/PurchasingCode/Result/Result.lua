--[[
Title: Result
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Result = NPL.load("(gl)Mod/ExplorerApp/pages/PurchasingCode/Result/Result.lua")
------------------------------------------------------------
]]

local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local PurchasingCode = NPL.load("(gl)Mod/ExplorerApp/pages/PurchasingCode/PurchasingCode.lua")
local SetCoins = NPL.load('../../SetCoins/SetCoins.lua')

local Result = NPL.export()

Result.getCoins = ''

function Result:ShowPage(coins)
    self.balance = Wallet:GetUserBalance()
    self.getCoins = coins

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/PurchasingCode/Result/Result.html", "Mod.ExplorerApp.PurchasingCode.Result", 0, 0, "_fi", false, 3)
end

function Result:SetPage()
    Mod.WorldShare.Store:Set("page/Result", document:GetPageCtrl())
end

function Result:ClosePage()
    local ResultPage = Mod.WorldShare.Store:Get('page/Result')

    if (ResultPage) then
        SetCoins:ShowPage()
        ResultPage:CloseWindow()
    end
end

function Result:PurchasingCode()
    self:ClosePage()
    PurchasingCode:ShowPage()
end