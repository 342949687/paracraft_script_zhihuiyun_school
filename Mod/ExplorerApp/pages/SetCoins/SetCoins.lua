--[[
Title: Set Coins
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local SetCoins = NPL.load("(gl)Mod/ExplorerApp/pages/SetCoins/SetCoins.lua")
------------------------------------------------------------
]]

local PurchasingCode = NPL.load("../PurchasingCode/PurchasingCode.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local MainPage = NPL.load("(gl)Mod/ExplorerApp/pages/MainPage.lua")

local SetCoins = NPL.export()

SetCoins.balance = 0
SetCoins.playerBalance = 0

function SetCoins:ShowPage()
    self.balance = Wallet:GetUserBalance()
    self.playerBalance = Wallet:GetPlayerBalance()

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/SetCoins/SetCoins.html", "Mod.ExplorerApp.SetCoins", 0, 0, "_fi", false, 3)
end

function SetCoins:SetPage()
    Mod.WorldShare.Store:Set("page/SetCoins", document:GetPageCtrl())
end

function SetCoins:ClosePage()
    local SetCoinsPage = Mod.WorldShare.Store:Get('page/SetCoins')

    if (SetCoinsPage) then
        SetCoinsPage:CloseWindow()
    end
end

function SetCoins:Refresh(time)
    local SetCoinsPage = Mod.WorldShare.Store:Get('page/SetCoins')

    if (SetCoinsPage) then
        SetCoinsPage:Refresh(time or 0.01)
    end
end

function SetCoins:PurchasingCode()
    self:ClosePage()
    PurchasingCode:ShowPage()
end

function SetCoins:AddPlayerCoins(count)
    if not count then
        return false
    end

    local playerBalance = self.playerBalance

    playerBalance = playerBalance + tonumber(count)

    if playerBalance <= self.balance then
        self.playerBalance = playerBalance
        self:Refresh()
    end
end

function SetCoins:ClearPlayerCoins()
    self.playerBalance = 0
    self:Refresh()
end

function SetCoins:Confirm()
    Wallet:SetUserBalance(self.balance)
    Wallet:SetPlayerBalance(self.playerBalance)

    self:ClosePage()
    MainPage:UpdateCoins()
end