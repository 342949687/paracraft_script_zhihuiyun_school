--[[
Title: Sort Component
Author(s):  big
Date: 2019.01.25
Place: Foshan
use the lib:
------------------------------------------------------------
local Sort = NPL.load("(gl)Mod/ExplorerApp/pages/Sort/Sort.lua")
------------------------------------------------------------
]]

local MainPage = NPL.load("../MainPage.lua")

local Sort = NPL.export()

Sort.position = {
    x = 0,
    y = 0
}

function Sort:ShowPage(x, y)
    self.position.x = x
    self.position.y = y

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/Sort/Sort.html", "Mod.ExplorerApp.Sort", 0, 0, "_fi", false, 3)
end

function Sort:SetPage()
    Mod.WorldShare.Store:Set("page/Sort", document:GetPageCtrl())
end

function Sort:ClosePage()
    local SortPage = Mod.WorldShare.Store:Get('page/Sort')

    if SortPage then
        SortPage:CloseWindow()
    end
end

function Sort:GetSortIndex()
    return Mod.WorldShare.Store:Get('explorer/selectSortIndex')
end

function Sort:GetSortList()
    return Mod.WorldShare.Store:Get('explorer/sortList')
end

function Sort:SetSortIndex(index)
    MainPage.curPage = 1
    Mod.WorldShare.Store:Set('explorer/selectSortIndex', index)
    self:ClosePage()
    MainPage:UpdateSort()
end