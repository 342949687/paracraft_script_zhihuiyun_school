--[[
Title: Offline Account Manager
Author(s): big
CreateDate: 2021.09.08
ModifyDate: 2021.09.24
Desc: 
use the lib:
------------------------------------------------------------
local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')
------------------------------------------------------------
]]

local OfflineAccountManager = NPL.export()

function OfflineAccountManager:ShowActivationPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/OfflineAccount/ActivationPage.html',
        'Mod.WorldShare.OfflineAccount.ActivationPage',
        0,
        0,
        '_fi',
        false,
        1
    )
end

function OfflineAccountManager.OnKeepWorkLogin_Callback(success)
    local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
    local hasJoinedSchool = GameLogic.GetFilters():apply_filters('store_get', 'user/hasJoinedSchool');
    if not isVerified or not hasJoinedSchool then
        GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
            local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
            KeepWorkItemManager.LoadProfile(false, function()
            end)
        end)

        return success
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/YellowCodeLimitPage.lua");
	local YellowCodeLimitPage = commonlib.gettable("MyCompany.Aries.Game.YellowCodeLimitPage");
	YellowCodeLimitPage.CheckShow()
    return success
end

function OfflineAccountManager.SetOfflineAppCommandLine()
    local oldCmdLine = ParaEngine.GetAppCommandLine();
	local newCmdLine = oldCmdLine;
    newCmdLine = newCmdLine.." Offline=\"true\"" 
    ParaEngine.SetAppCommandLine(newCmdLine);
    System.options.isOffline = true
end

function OfflineAccountManager.ResetOfflineStatus()
    local oldCmdLine = ParaEngine.GetAppCommandLine();
	local newCmdLine = oldCmdLine;
    --这个不能置空，只能改成false，底层逻辑限制
    newCmdLine = newCmdLine:gsub("Offline=\"true\"" ,"Offline=\"false\"") 
    ParaEngine.SetAppCommandLine(newCmdLine);
    System.options.isOffline = false
end