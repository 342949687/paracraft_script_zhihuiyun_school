--[[
Title: TimeUp
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Password = NPL.load("(gl)Mod/ExplorerApp/pages/GameProcess/TimeUp/TimeUp.lua")
------------------------------------------------------------
]]

local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')

local TimeUp = NPL.export()

function TimeUp:ShowPage()
    self.playerBalance = Wallet:GetPlayerBalance()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/GameProcess/TimeUp/TimeUp.html", "Mod.ExplorerApp.GameProcess.TimeUp", 0, 0, "_fi", false)
end

function TimeUp:SetPage()
    Mod.WorldShare.Store:Set("page/TimeUp", document:GetPageCtrl())
end

function TimeUp:ClosePage()
    local TimeUpPage = Mod.WorldShare.Store:Get('page/TimeUp')

    if (TimeUpPage) then
        TimeUpPage:CloseWindow()
    end
end

function TimeUp:Confirm()

end