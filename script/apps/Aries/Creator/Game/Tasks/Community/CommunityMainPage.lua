--[[
    author: pbb
    date: 2014-04-11
    description:
        This script is the main page of the community function.
    uselib:
        local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
        CommunityMainPage.Show()
]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CommunityMainPage = NPL.export()

local base_texture_path = "Texture/Aries/Creator/keepwork/"
local tabData = {
    {value = L"创作",name ="create",icon=base_texture_path.."community_32bits.png#634 214 32 32", icon1 = base_texture_path.."community_32bits.png#598 214 32 32"},
    {value = L"探索",name ="explore",icon=base_texture_path.."community_32bits.png#626 142 32 32", icon1 = base_texture_path.."community_32bits.png#590 142 32 32"},
    {value = L"商城",name ="mall",icon=base_texture_path.."community_32bits.png#630 2 32 32", icon1 = base_texture_path.."community_32bits.png#602 38 32 32"},
	{value = L"学习",name ="study",icon=base_texture_path.."community_32bits.png#746 38 32 32", icon1 = base_texture_path.."community_32bits.png#734 74 32 32"},
    {value = L"会员",name ="vip",icon=base_texture_path.."community_32bits.png#742 146 32 32", icon1 = base_texture_path.."community_32bits.png#734 110 32 32"},
}

CommunityMainPage.selectedTab = -1
local page
function CommunityMainPage.OnInit()
    page = document:GetPageCtrl()
end
--#A8A7B0FF
--#FFFFFFFF
--#D9D9D9FF
function CommunityMainPage.Show(bShowTitleClose)
    if System.os.GetPlatform() ~= "win32" and System.os.GetPlatform() ~= "mac" then
        return
    end
	CommunityMainPage.ClearProjectFrameData()
	CommunityMainPage.ClearExploreFrameData()
    local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.html",
			name = "CommunityMainPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
			cancelShowAnimation = true,
			-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
	CommunityTitleInfo.ShowPage(bShowTitleClose)
	
	CommunityMainPage.ReportLoginTime()

	CommunityMainPage.mytimer = CommunityMainPage.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		local x, y = ParaUI.GetMousePosition();
		local temp = ParaUI.GetUIObjectAtPoint(x, y);
		print("xxxxxxxxxxxxxxxx",temp.name,temp.id,temp.uiname,temp.parent.name,temp.parent.id,temp.parent.uiname,x, y)
	end})
	-- CommunityMainPage.mytimer:Change(0, 200);
	
	CommunityMainPage.selectedTab = -1
	CommunityMainPage.OnChangeTabview(1)
end

function CommunityMainPage.OnClose()
	if page then
		page:CloseWindow();
        page = nil
	end
end

function CommunityMainPage.GetCategoryDSIndex()
	return CommunityMainPage.selectedTab
end

function CommunityMainPage.GetMenuData()
	return tabData
end

function CommunityMainPage.OnChangeTabview(index)
	local tabId = tonumber(index)
	if tabId and tabId > 0 and tabId <= #tabData then
		CommunityMainPage.ChangeTab(tabId)
	end
end

function CommunityMainPage.ChangeTab(tabId)
	if tabId == #tabData then
		local token = Mod.WorldShare.Store:Get("user/token")
		local url = "https://community-dev.kp-para.cn/client/recharge?token="..(token or "")
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipPage.lua")
        local CommunityVipPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityVipPage")
		CommunityVipPage:OpenBrowser("community_browser",url,function()
			
		end)
		return
	end
	if tabId == 4 then
		GameLogic.AddBBS(nil,L"功能未开放")
		return
	end
	if CommunityMainPage.selectedTab ~= tabId then
		if tabId ~= 1 then
			CommunityMainPage.ClearProjectFrameData()
		end
		if tabId ~= 2 then
			CommunityMainPage.ClearExploreFrameData()
		end
		CommunityMainPage.selectedTab = tabId
		CommunityMainPage.RefreshPage()
	end
end

function CommunityMainPage.ClearExploreFrameData()
	local ExploreMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.lua")
	ExploreMainPage.ClearData()
end

function CommunityMainPage.ClearProjectFrameData()
	Mod.WorldShare.Store:Remove('world/searchText')
	local ProjectMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.lua")
	ProjectMainPage.ClearFrameData()
end

function CommunityMainPage.GetMenuFrame()
	if CommunityMainPage.selectedTab > 0 and CommunityMainPage.selectedTab <= #tabData then
		if CommunityMainPage.selectedTab == 1 then
			return "script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.html"
		elseif CommunityMainPage.selectedTab == 2 then
			return "script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.html"
		elseif CommunityMainPage.selectedTab == 3 then
			return "script/apps/Aries/Creator/Game/Tasks/Community/CommunityMallPage.html"
		elseif CommunityMainPage.selectedTab == 4 then
		end
	end
	return ""
end	

function CommunityMainPage.ReportLoginTime()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	QuestAction.ReportLoginTime()
end

function CommunityMainPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function CommunityMainPage.ShowMoreMenu()
	if not page then
		return
	end
	local moreMenu = ParaUI.GetUIObject("main_other_panel")
	if moreMenu and moreMenu:IsValid() then
		moreMenu.visible = not moreMenu.visible
	end
end

function CommunityMainPage.HideMoreMenu()
	if not page then
		return
	end
	local moreMenu = ParaUI.GetUIObject("main_other_panel")
	if moreMenu and moreMenu:IsValid() then
		moreMenu.visible = false
	end
end

function CommunityMainPage.OnClickAbout()
	GameLogic.RunCommand("/menu help.about");
end

function CommunityMainPage.OnClickFeedback()
	GameLogic.RunCommand("/menu help.bug");
end

function CommunityMainPage.OpenSetting()
	local CommunitySetting = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunitySetting.lua")
	CommunitySetting.ShowPage()
end

function CommunityMainPage.OpenVersion()
	print("OpenVersion===========")
	MyCompany.Aries.Game.MainLogin:ShowUpdatePage(true)
end
