--[[
Title: Explorer App
Author(s): big
CreateDate: 2019.01.18
ModifyDate: 2021.12.16
Desc: This is explorer app
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load('(gl)Mod/ExplorerApp/main.lua')
local ExplorerApp = commonlib.gettable('Mod.ExplorerApp')
------------------------------------------------------------
]]

NPL.load('(gl)script/ide/System/Core/UniString.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Common/Translation.lua')

-- store
local ExplorerStore = NPL.load('(gl)Mod/ExplorerApp/store/ExplorerStore.lua')

-- pages
local MainPage = NPL.load('(gl)Mod/ExplorerApp/pages/MainPage/MainPage.lua')
local GameOver = NPL.load('(gl)Mod/ExplorerApp/pages/GameProcess/GameOver/GameOver.lua')

-- utils
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- filters
local Filters = NPL.load('(gl)Mod/ExplorerApp/filters/Filters.lua')

local ExplorerApp = commonlib.inherit(commonlib.gettable('Mod.ModBase'), commonlib.gettable('Mod.ExplorerApp'))

ExplorerApp:Property({'Name', 'ExplorerApp', 'GetName', 'SetName', { auto = true }})
ExplorerApp:Property({'Desc', 'This is explorer app', 'GetDesc', 'SetDesc', { auto = true }})
ExplorerApp.version = '0.0.5'

LOG.std(nil, 'info', 'ExplorerApp', 'explorer app version %s', ExplorerApp.version)

function ExplorerApp:init()
    Filters:Init()
end

function ExplorerApp:Init(callback, classId, defaulOpenValue)
    if not Mod or not Mod.WorldShare then
        _guihelper.MessageBox(L'ExplorerApp 依赖 WorldShare Mod')
        return false
    end

    -- register explorer store to store list
    Mod.WorldShare.Store:RegisterStore('explorer', ExplorerStore)

    MainPage:ShowPage(callback, classId, defaulOpenValue)
end

function ExplorerApp:OnWorldLoad()
end
