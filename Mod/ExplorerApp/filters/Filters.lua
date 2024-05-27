--[[
Title: filters
Author(s): big
CreateDate: 2021.03.05
ModifyDate: 2021.12.17
Desc: 
use the lib:
------------------------------------------------------------
local Filters = NPL.load('(gl)Mod/ExplorerApp/filters/Filters.lua')
Filters:Init()
------------------------------------------------------------
]]

local ExplorerApp = commonlib.gettable('Mod.ExplorerApp')

-- pages
local MainPage = NPL.load('(gl)Mod/ExplorerApp/pages/MainPage/MainPage.lua')

local Filters = NPL.export()

function Filters:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.explorer.show',
        function(...)
            ExplorerApp:Init(...);
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.explorer.close',
        function()
            MainPage:Close();
        end
    )
end