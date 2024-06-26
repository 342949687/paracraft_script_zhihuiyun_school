--[[
Title: Main Login
Author(s): Big
CreateDate: 2021.2.25
ModifyDate: 2021.9.10
Desc: 
use the lib:
------------------------------------------------------------
local MainLoginFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MainLogin/MainLoginFilter.lua')
MainLoginFilter:Init()
------------------------------------------------------------
]]

-- libs
local RestartTable = commonlib.gettable('RestartTable')

-- UI
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')

local MainLoginFilter = NPL.export()

function MainLoginFilter:Init()
    -- replace load world page
    GameLogic.GetFilters():add_filter(
        'cellar.main_login.show_login_mode_page',
        function()
            -- inject
            -- sync system.User info to Store user
            Mod.WorldShare.Store:Set('user/token', System.User.keepworktoken)
            Mod.WorldShare.Store:Set('user/username', RestartTable.username)
            Mod.WorldShare.Store:Set('user/whereAnonymousUser', RestartTable.whereAnonymousUser)

            MainLogin:Show()
            return false
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.main_login.get_login_background',
        function()
            return MainLogin:GetLoginBackground()
        end
    )

    GameLogic.GetFilters():add_filter("user_token_will_time_out",MainLogin.TokenTimeOutReLogin)
end