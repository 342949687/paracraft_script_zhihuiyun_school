--[[
    author: pbb
    date: 2024-05-23
    description:
        This script is the main page of the community function.
    uselib:
        local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
        CommunityTitleInfo.ShowPage()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CommunityTitleInfo = NPL.export()

local page = nil
CommunityTitleInfo.UserData = {}

function CommunityTitleInfo.OnInit()
    page = document:GetPageCtrl()
end

function CommunityTitleInfo.ShowPage(bNotShowClose)
    CommunityTitleInfo.IsNotShowClose = bNotShowClose
    CommunityTitleInfo.InitUserData()
    if page then
        page:CloseWindow()
        page = nil
    end
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.html", 
        name = "CommunityTitleInfo.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 10,
        click_through = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_mt",
            x = 0,
            y = 0,
            width = 0,
            height = 230,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);	

	GameLogic.GetFilters():remove_filter("became_vip", CommunityTitleInfo.OnBecomeVip);
    GameLogic.GetFilters():add_filter("became_vip", CommunityTitleInfo.OnBecomeVip);

    if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
			CommunityTitleInfo.RefreshPage()
		end)
	end

	local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	if not isVerified then
		local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
		local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
		if not (session and type(session) == 'table' and session.doNotNoticeVerify) then
			GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
				KeepWorkItemManager.LoadProfile(false, function()
					CommunityTitleInfo.RefreshPage()
				end)
			end)
		end
	end
    commonlib.TimerManager.SetTimeout(function()
        CommunityTitleInfo.RefreshPage()
    end, 1000)
end

function CommunityTitleInfo.OnBecomeVip()
	CommunityTitleInfo.RefreshPage()
end

function CommunityTitleInfo.RefreshPage()
    CommunityTitleInfo.InitUserData(true)
    if page then
        page:Refresh(0.1)
    end
end

function CommunityTitleInfo.InitUserData()
	local profile = KeepWorkItemManager.GetProfile()
	if (profile.username == nil or profile.username == "") then
		KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
			if data.username and data.username ~= "" then
				CommunityTitleInfo.RefreshPage()
			end
		end)
		return
	end
	
	local UserData = {}
	UserData.nickname = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.nickname)
	UserData.username = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.username or "")

	if UserData.nickname == nil or UserData.nickname == "" then
		UserData.nickname = UserData.username
		UserData.limit_nickname = UserData.username
	else
		UserData.limit_nickname = commonlib.GetLimitLabel(UserData.nickname, 26)
	end
	-- UserData.nickname  = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"

	UserData.limit_username = UserData.username

	-- profile.school = {}
	-- profile.school.name = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"
	UserData.has_school = profile.school ~= nil and profile.school.name ~= nil
	if UserData.has_school then
		UserData.school_name = profile.school and profile.school.name or ""
		UserData.limit_school_name = UserData.school_name
	else
		UserData.limit_school_name = "尚未关联学校"
	end

	UserData.has_real_name = profile.realname ~= nil and profile.realname ~= ""
	
	UserData.is_vip = profile.vip == 1
	CommunityTitleInfo.UserData = UserData
end

function CommunityTitleInfo.GetUserData(name)
	return CommunityTitleInfo.UserData[name] or ""
end

function CommunityTitleInfo.IsGameStarted()
    if CommunityTitleInfo.IsNotShowClose then
        return false
    end
    local is_enter_world = GameLogic.GetFilters():apply_filters('store_get', 'world/isEnterWorld');
    return Game.is_started or is_enter_world
end

function CommunityTitleInfo.ExitToLogin()
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
    Mod.WorldShare.MsgBox:Close()
end

function CommunityTitleInfo.OnClose(bOnlyCloseSelf)
    if page then
        page:CloseWindow(true)
        page = nil
    end
    if not bOnlyCloseSelf then
        local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
        CommunityMainPage.OnClose()
    end
end

function CommunityTitleInfo.ClosePage()
    if page then
		CommunityTitleInfo.OnClose()
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        if KeepworkServiceSession:IsSignedIn() then
            KeepworkServiceSession:Logout(nil, function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
                CommunityTitleInfo.ExitToLogin()
            end)
        else
            CommunityTitleInfo.ExitToLogin()
        end
    end
end

function CommunityTitleInfo.ShowRoleInfoPanel()
	if not page then
		return
	end
	local roleInfoPanel = ParaUI.GetUIObject("main_role_panel")
	if roleInfoPanel and roleInfoPanel:IsValid() then
		roleInfoPanel.visible = not roleInfoPanel.visible
	end
end

function CommunityTitleInfo.HideRoleInfoPanel()
	if not page then
		return
	end
	local roleInfoPanel = ParaUI.GetUIObject("main_role_panel")
	if roleInfoPanel and roleInfoPanel:IsValid() then
		roleInfoPanel.visible = false
	end
end

function CommunityTitleInfo.IsVip()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 or profile.commonVip == 1 then
		return true
	end
	return false
end

function CommunityTitleInfo.GetVipIcon()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 then
		return "Texture/Aries/Creator/keepwork/community_32bits.png#70 238 48 16"
	end
	if profile.commonVip == 1 then
		return "Texture/Aries/Creator/keepwork/community_32bits.png#138 238 48 16"
	end
end

function CommunityTitleInfo.GetVipDeadLine()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 then
        if not profile.vipDeadline then
            return L"永久超级会员"
        end
		local deadline = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
		return os.date("%Y年%m月%d日", deadline)
	end
	if profile.commonVip == 1 then
        if not profile.commonVipDeadline then
            return L"永久会员"
        end
		local deadline = commonlib.timehelp.GetTimeStampByDateTime(profile.commonVipDeadline)
		return os.date("%Y年%m月%d日", deadline)
	end
	
end

function CommunityTitleInfo.OnClickLogOut()
	CommunityTitleInfo.HideRoleInfoPanel()
	CommunityTitleInfo.ClosePage()
end

function CommunityTitleInfo.OnClickVip()
	CommunityTitleInfo.HideRoleInfoPanel()
    local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
	CommunityMainPage.OnChangeTabview(5)
end

function CommunityTitleInfo.OpenUserInfo()
	CommunityTitleInfo.HideRoleInfoPanel()
	local CommunityUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityUserInfo.lua")
     CommunityUserInfo.ShowPage()
end

function CommunityTitleInfo.OpenMessage()
	local CommunityNotification = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/CommunityNotification.lua")
	CommunityNotification.ShowPage()
end

function CommunityTitleInfo.IsVisible()
    local isVisible = page and page:IsVisible()
    return isVisible == true
end