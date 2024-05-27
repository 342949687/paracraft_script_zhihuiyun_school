--[[
Title: ProactiveEnd
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local ProactiveEnd = NPL.load("(gl)Mod/ExplorerApp/pages/GameProcess/ProactiveEnd/ProactiveEnd.lua")
------------------------------------------------------------
]]

local MainPage = NPL.load("(gl)Mod/ExplorerApp/pages/MainPage.lua")
local AudioEngine = commonlib.gettable("AudioEngine")

local ProactiveEnd = NPL.export()

function ProactiveEnd:ShowPage()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/pages/GameProcess/ProactiveEnd/ProactiveEnd.html", "Mod.ExplorerApp.GameProcess.ProactiveEnd", 0, 0, "_fi", false)
end

function ProactiveEnd:ExitIcon()
    local params = {
        url = "Mod/ExplorerApp/pages/GameProcess/ProactiveEnd/Exit.html",
        name = "Mod.ExplorerApp.GameProcess.Exit",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        allowDrag = false,
        bShow = true,
        directPosition = true,
        align = "_rt",
        x = -50,
        y = 25,
        width = 17,
        height = 17,
        cancelShowAnimation = true,
        bToggleShowHide = true
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function ProactiveEnd:OnWorldLoad()
    self:ExitIcon()
end

function ProactiveEnd:SetPage()
    Mod.WorldShare.Store:Set("page/ProactiveEnd", document:GetPageCtrl())
end

function ProactiveEnd:ClosePage()
    local ProactiveEndPage = Mod.WorldShare.Store:Get('page/ProactiveEnd')

    if (ProactiveEndPage) then
        ProactiveEndPage:CloseWindow()
        Mod.WorldShare.Store:Remove('page/ProactiveEnd')
    end
end

function ProactiveEnd:Toggle()
    local ProactiveEndPage = Mod.WorldShare.Store:Get('page/ProactiveEnd')

    if not ProactiveEndPage then
        self:ShowPage()
    else
        self:ClosePage()
    end
end

function ProactiveEnd:Exit()
    self:ClosePage()
    Mod.WorldShare.Store:Set('explorer/reduceRemainingTime', 0)
    Mod.WorldShare.Store:Set('explorer/warnReduceRemainingTime', 0)
    Mod.WorldShare.Store:Set('explorer/canGoBack', false)
    AudioEngine.StopAllSounds()
    MainPage:ShowPage()
end