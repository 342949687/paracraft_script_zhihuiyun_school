--[[
Title: RedSummerCampMainPage
Author(s): 
Date: 2021/7/6
Desc:  the main 2d page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
RedSummerCampMainPage.Show();
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local RedSummerCampMainPage = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Tasks.RedSummerCampMainPage",RedSummerCampMainPage)
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local ClassSchedule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSchedule.lua") 
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local Notice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua");
local VipRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
local ZhiHuiYun = commonlib.gettable("MyCompany.Aries.Game.GameLogic.ZhiHuiYun")
local page
local click_help_num = 0
local notice_time = 3000
RedSummerCampMainPage.UserData = {}
RedSummerCampMainPage.ItemData = {
	{name="大赛", is_show_vip=false, is_show_recommend=true, node_name = "shentongbei", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_1_220x220_32bits.png#0 0 220 220"},
	{name="入门必看", is_show_vip=false, is_show_recommend=false, node_name = "course_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/rumengbikan_226x206_32bits.png#0 0 226 206"},
	-- {name="乐园设计师", is_show_vip=false, is_show_recommend=false, node_name = "leyuan", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/8_219X202_32bits.png#0 0 220 220"},
	-- {name="讲好“中国好故事”", is_show_vip=false, is_show_recommend=false, node_name = "china_story", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/xinchangzheng_220x220_32bits.png#0 0 220 220"},
	{name="3D动画编程赛", is_show_vip=false, is_show_recommend=false, node_name = "animation_race", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/animation_race_220X220_32bits.png#0 0 220 220"},
	{name="推荐作品", is_show_vip=false, is_show_recommend=false, node_name = "explore", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_4_220x220_32bits.png#0 0 220 220"},
	{name="虚拟校园", is_show_vip=false, is_show_recommend=false, node_name = "ai_school", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_5_220x220_32bits.png#0 0 220 220"},
	{name="家长指南", is_show_vip=false, is_show_recommend=false, node_name = "parent_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_6_220x220_32bits.png#0 0 220 220"},
}

local androidFlavor = System.os.GetAndroidFlavor();

if (androidFlavor == "huawei") then
	RedSummerCampMainPage.ItemData[4] = {
		name = "优秀作品",
		is_show_vip = false,
		is_show_recommend = false,
		node_name = "explore",
		img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_4_220x220_32bits.png#0 0 220 220"
	};
end

local notice_desc = {
	-- {desc = [[教师节活动奖励新鲜出炉！！！]], name="teacher_day"},
	-- {desc = [[国庆学习有豪礼，学习进步在坚持！]], name="nationak_day"},
	-- {desc = [[关于举办"神通杯"第一届全国学校联盟中小学计算机编程大赛的通知]], name="shentongbei"},
	-- {desc = [[金秋九月，开学课程抢鲜学]], name="course_page"},
	-- {desc = [[学3D动画编程，参加青少年 “讲好中国故事“ 创意编程大赛]], name="zhengcheng"},
	-- {desc = [[全新世界“圣诞树”等你来体验]], name="ai_school"},
	-- {desc = [[冬令营课程包全新上线]], name="ai_school"},
}

RedSummerCampMainPage.RightBtData = {
	{node_name = "skin", red_icon_name="skin_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/2_63X57_32bits.png#0 0 64 74"},
	{node_name = "certificate", red_icon_name="certificate_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/1_63X57_32bits.png#0 0 64 74"},
	{node_name = "friend", red_icon_name="friend_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/3_63X57_32bits.png#0 0 64 74"},
	{node_name = "email", red_icon_name="email_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/4_63X57_32bits.png#0 0 64 74"},
	{node_name = "task", red_icon_name="task_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/5_63X57_32bits.png#0 0 64 74"},
	{node_name = "rank", red_icon_name="rank_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/6_51X53_32bits.png#0 0 64 74"},
}
local notice_text_index = 1

local cur_notice_node_index = 2
function RedSummerCampMainPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampMainPage.OnCreate
	page.OnClose = RedSummerCampMainPage.OnClose
	
end

function RedSummerCampMainPage.Show()
	if System.options.ZhyChannel == "zhy_competition_debugger" then
		ZhiHuiYun:EnterCompetitionProgramChecker()
		return

		
		-- commonlib.TimerManager.SetTimeout(function()
		-- 	GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 50819))
		-- end,2000)
	end

	-- zhy_competition 初赛 zhy_competition2 复赛
	if System.options.ZhyChannel == "zhy_competition" then
		ZhiHuiYun:EnterCompetition()
		return
	end

	if System.options.isPapaAdventure then
		NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
        local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
		PapaAPI:ExitGame()
		PapaAPI:EnterVueHome()
		PapaAPI:OnDisplayModeChange("show")
		PapaAPI:OnDisplayModeChange("ingame")
		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
	local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
	MallManager.getInstance():Init()

	NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
	local parent_id = type(WorldCommon.GetParentProjectId) =="function" and WorldCommon.GetParentProjectId() or nil
	if parent_id then
		local cur_project_id = GameLogic.options:GetProjectId()
		if tonumber(parent_id) ~= tonumber(cur_project_id) then
			GameLogic.GetFilters():add_filter("enter_world_fail",RedSummerCampMainPage.EnterWorldFail)
			GameLogic.RunCommand(format('/loadworld -s -force %s', parent_id))
			return
		end

		WorldCommon.SetParentProjectId()
	end
	

	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SysInfoStatistics.lua");
	local SysInfoStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.SysInfoStatistics")
	
	commonlib.TimerManager.SetTimeout(function()
		if platform=="android" or platform=="ios" or platform=="mac" then
			local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
			if PlatformBridge.IsAgreePrivacy() then
				PlatformBridge.onAgreeUserPrivacy()
			end
		end
		SysInfoStatistics.checkGetSysInfoAndUpload()
	end,500)

	if System.options.isEducatePlatform then
		local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
        EducateMainPage.ShowPage()
		return
	end

	if RedSummerCampMainPage.hasFirstShow==nil then 
		RedSummerCampMainPage.hasFirstShow = true
		
		commonlib.TimerManager.SetTimeout(function()
			ClassSchedule.CheckJumpToSchedule()
		end,100)
	end
	if not RedSummerCampMainPage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", RedSummerCampMainPage.RefreshPage);
		GameLogic.GetFilters():add_filter("update_msgcenter_unread_num", function(num)
			RedSummerCampMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
		end);
		GameLogic.GetFilters():add_filter("role_page_close", function()
			commonlib.TimerManager.SetTimeout(function()  
				RedSummerCampMainPage.RefreshPage()
			end, 200);
			
		end);

		GameLogic.GetFilters():add_filter("user_skin_change", function()
			commonlib.TimerManager.SetTimeout(function()  
				RedSummerCampMainPage.RefreshPage()
			end, 200);
		end);

		GameLogic.GetFilters():add_filter("on_start_login", function()
			RedSummerCampMainPage.hasFirstShow = nil
		end);

		GameLogic.GetFilters():add_filter("on_permission_load", RedSummerCampMainPage.RefreshPage);

		RedSummerCampMainPage.BindFilter = true
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/YellowCodeLimitPage.lua");
	local YellowCodeLimitPage = commonlib.gettable("MyCompany.Aries.Game.YellowCodeLimitPage");
	YellowCodeLimitPage.CheckShow()

	if System.options.isChannel_430 or (System.os.GetPlatform() == "mac" or System.os.GetPlatform() == "ios") then
		local RedSummerCampSchoolMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.lua");
		RedSummerCampSchoolMainPage.Show();
		return 
	end
	

	CustomCharItems:Init();

	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end

	if System.options.isCommunity then
		local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
        CommunityMainPage.Show(true)
		return
	end

	if page then
		page:CloseWindow(true)
		RedSummerCampMainPage.OnClose()
	end
	RedSummerCampMainPage.ClearTween()
	RedSummerCampMainPage.InitUserData()
	notice_text_index = 1

	if not RedSummerCampMainPage.BindFilter then
	end

	if System.options.isHideVip then
		RedSummerCampMainPage.RightBtData = commonlib.filter(RedSummerCampMainPage.RightBtData,function (item)
			return item.node_name ~= "skin"
		end)
	end

	local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.html",
			name = "RedSummerCampMainPage.Show", 
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

	RedSummerCampPPtPage.OpenLastPPtPage()

	RedSummerCampMainPage.HasClickFriend = false
	RedSummerCampMainPage.HasClickQuest = false

	commonlib.TimerManager.SetTimeout(function()  
		if Notice.CheckCanShow() and not RedSummerCampMainPage.isShowNotice then
			Notice.Show(0 ,100)
			RedSummerCampMainPage.isShowNotice = true
		end  
	end, 1000);
	

	VipRewardPage.ShowPage()
	QuestAction.ReportLoginTime()
	FriendManager.CloseAllFriendPage()
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
			RedSummerCampMainPage.RefreshPage()
		end)
	end
	
	if RedSummerCampMainPage.NoticeDesc == nil then
		keepwork.config.all({},function(err, msg, data)
			if err == 200 then
				local configs = data.configs
				for key, v in pairs(configs) do
					if v.name == "scrollbar" then
						RedSummerCampMainPage.NoticeDesc = v.config
						break
					end
				end
			end

			if RedSummerCampMainPage.NoticeDesc then
				table.sort(RedSummerCampMainPage.NoticeDesc,function(a,b)
					local sort_a = a.order and tonumber(a.order) or 999
					local sort_b = b.order and tonumber(b.order) or 999
					return sort_a < sort_b;
				end)
			end
			if page then
				page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
			end
			-- RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
			-- 	RedSummerCampMainPage.StartNoticeAnim()
			-- end})
			-- RedSummerCampMainPage.Timer:Change(notice_time, nil);
		end)
	else
		if page then
			page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
		end
		RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampMainPage.StartNoticeAnim()
		end})
		RedSummerCampMainPage.Timer:Change(notice_time, nil);
	end

	local isVerified = true--GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	local hasJoinedSchool = true--GameLogic.GetFilters():apply_filters('store_get', 'user/hasJoinedSchool');
	if not isVerified or not hasJoinedSchool then
		local func = function()
			local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
			local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
			if not (session and type(session) == 'table' and session.doNotNoticeVerify) then
				GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
					KeepWorkItemManager.LoadProfile(false, function()
						RedSummerCampMainPage.RefreshPage()
					end)
				end)
			end
		end
		if System.options.isChannel_430 then
			func()
		else
			if not isVerified then
				func()
			end
		end
	end
	
end

function RedSummerCampMainPage.OnClose()
	RedSummerCampMainPage.ClearTween()
	GameLogic.GetFilters():remove_filter("enter_world_fail",RedSummerCampMainPage.EnterWorldFail)
end

function RedSummerCampMainPage.Close()
	if page then
		page:CloseWindow()
		RedSummerCampMainPage.OnClose()
		page = nil
	end
end

function RedSummerCampMainPage.ClearTween()
	if RedSummerCampMainPage.tween_y_1 then
		RedSummerCampMainPage.tween_y_1:Stop()
		RedSummerCampMainPage.tween_y_2:Stop()
		RedSummerCampMainPage.tween_y_1 = nil
		RedSummerCampMainPage.tween_y_2 = nil
	end

	if RedSummerCampMainPage.Timer then
		RedSummerCampMainPage.Timer:Change()
		RedSummerCampMainPage.Timer = nil
	end
end

function RedSummerCampMainPage.OnCreate()
	local module_ctl = page:FindControl("main_user_player")
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local obj = scene:GetObject(module_ctl.obj_name);
		obj:SetScale(1)
	end

	-- 去掉所有的红点提示，业务已经下架了
	-- RedSummerCampMainPage.HandleQuestRedTip()
	-- RedSummerCampMainPage.HandleFriendsRedTip()
	-- RedSummerCampMainPage.UpdateVideoRedTip()
	-- DockPage.HandMsgCenterMsgData(function()
	-- 	-- Email.OpenEmailPage()
	-- end)
	-- RedSummerCampMainPage.UpdateRedTip()

	RedSummerCampMainPage.UpdateVideoRedTip()
end

function RedSummerCampMainPage.GetAutoNoticeText()
	if not RedSummerCampMainPage.NoticeDesc then
		return ""
	end

	local notice_desc = RedSummerCampMainPage.NoticeDesc
	local data = notice_desc[notice_text_index]
	notice_text_index = notice_text_index + 1

	if notice_text_index > #notice_desc then
		notice_text_index = 1
	end

	return data.title
end

function RedSummerCampMainPage.OpenHelpPage(btnId)
	local btn = page:FindUIControl(btnId);
	if(btn and btn:IsValid()) then
		local x,y,width, height = btn:GetAbsPosition();
		if true then
			click_help_num = click_help_num + 1
			local pageUrl = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampHelperMenu.html?x=%s & y=%s",x,y+70)
			if click_help_num > 10 then
				pageUrl = pageUrl .. " & isTest=1"
				click_help_num = 0
			end
			local params = {
				url = pageUrl,
				name = "RedSummerCampHelperMenu.Show", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				enable_esc_key = true,
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
				zorder = 1,
			};
			System.App.Commands.Call("File.MCMLWindowFrame", params);	
			return
		end
		local KpQuickWord = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpQuickWord.lua");
		local ctl = CommonCtrl.GetControl("Help_Tree");

		if(ctl == nil)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "Help_Tree",
				width = 160,
				subMenuWidth = 300,
				height = 350, -- add 30(menuitemHeight) for each new line. 
				AutoPositionMode = "_lt",
				--style = CommonCtrl.ContextMenu.DefaultStyleThick,
				{
					borderTop = 4,
					borderBottom = 4,
					borderLeft = 18,
					borderRight = 10,
					
					fillLeft = 0,
					fillTop = -15,
					fillWidth = 0,
					fillHeight = -24,
					
					titlecolor = "#e1ccb6",
					level1itemcolor = "#e1ccb6",
					level2itemcolor = "#ffffff",
					
					-- menu_bg = "Texture/Aries/Chat/newbg1_32bits.png;0 0 128 192:40 41 20 17",
					menu_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
					menu_lvl2_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
					shadow_bg = nil,
					separator_bg = "", -- : 1 1 1 4
					item_bg = "Texture/Aries/Chat/fontbg1_32bits.png;0 0 103 26: 1 1 1 1",
					expand_bg = "Texture/Aries/Chat/arrowup_32bits.png; 0 0 15 16",
					expand_bg_mouseover = "Texture/Aries/Chat/arrowon_32bits.png; 0 0 15 16",
					
					menuitemHeight = 30,
					separatorHeight = 2,
					titleHeight = 26,
					
					titleFont = "System;14;bold";
				},
			};
	
			RedSummerCampMainPage.OpenTreeNode()
		end
		
		if(not x or not width) then
			x,y,width, height = ParaUI.GetUIObject("BattleChatBtn"):GetAbsPosition();
		end

		ctl:Show(x, y+70);
	end
end

local listOfHelpNode = {
	{
		text = "教学视频",
		cmdName = "help.videotutorials"
	},
	{
		text = "官方文档",
		cmdName = "help.learn"
	},
	{
		text = "推荐课程",
		cmdName = "help.dailycheck"
	},
	{
		text = "提问",
		cmdName = "help.ask"
	},
	{
		type = "Separator"
	},
	{
		text = "提交意见或反馈",
		cmdName = "help.bug"
	},
	{
		text = "关于Paracraft",
		cmdName = "help.about"
	},
}

function RedSummerCampMainPage.OpenTreeNode()
	local ctl = CommonCtrl.GetControl("Help_Tree");
	if(ctl) then
		local node = ctl.RootNode;
		-- clear all children first
		node:ClearAllChildren();
		-- by categories
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "Quickwords", Name = "actions", Type = "Group", NodeHeight = 0 });

		for _, item in ipairs(listOfHelpNode) do
			node:AddChild(CommonCtrl.TreeNode:new({
				Text = item.text, Name = "xx", 
				Type = if_else(item.type, item.type, "Menuitem"),
				NodeHeight = 26,
				onclick = function ()
					if item.cmdName then
						GameLogic.RunCommand("/menu "..item.cmdName);
					end
				end,
			}));
		end
	end
end

function RedSummerCampMainPage.IsVisible()
	return page and page:IsVisible()
end

function RedSummerCampMainPage.StartNoticeAnim()
	-- RedSummerCampMainPage.ClearTween()
	if RedSummerCampMainPage.tween_y_1 then
		RedSummerCampMainPage.tween_y_1:Stop()
		RedSummerCampMainPage.tween_y_2:Stop()
	end
	if RedSummerCampMainPage.Timer then
		RedSummerCampMainPage.Timer:Change()
		RedSummerCampMainPage.Timer = nil
	end
	
	if not page or not page:IsVisible() then
		if page and not page:IsVisible() then
			page:CloseWindow()
			RedSummerCampMainPage.OnClose()
			page = nil
		end
		return
	end

	local time = 1
	local default_height = 62
	local notice_container_1 = ParaUI.GetUIObject("notice_container_1");
	if notice_container_1.y > 5 then
		notice_container_1.y = -default_height
		page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
	end

	if RedSummerCampMainPage.tween_y_1 == nil then
		RedSummerCampMainPage.tween_y_1 =CommonCtrl.Tween:new{
			obj=notice_container_1,
			prop="y",
			begin=notice_container_1.y,
			change=default_height,
			duration=time,
		}
	else
		RedSummerCampMainPage.tween_y_1.obj=notice_container_1
		RedSummerCampMainPage.tween_y_1.prop="y"
		RedSummerCampMainPage.tween_y_1.begin=notice_container_1.y
		RedSummerCampMainPage.tween_y_1.change=default_height
		RedSummerCampMainPage.tween_y_1.duration=time
	end


	RedSummerCampMainPage.tween_y_1.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampMainPage.tween_y_1:Start();

	local notice_container_2 = ParaUI.GetUIObject("notice_container_2");
	if notice_container_2.y > 5 then
		notice_container_2.y = -default_height
		page:SetValue("notic_text2", RedSummerCampMainPage.GetAutoNoticeText())
	end

	if RedSummerCampMainPage.tween_y_2 == nil then
		RedSummerCampMainPage.tween_y_2 =CommonCtrl.Tween:new{
			obj=notice_container_2,
			prop="y",
			begin=notice_container_2.y,
			change=default_height,
			duration=time,
			MotionFinish = function()
				-- RedSummerCampMainPage.ClearTween()
				RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
					RedSummerCampMainPage.StartNoticeAnim()
				end})
				RedSummerCampMainPage.Timer:Change(notice_time, nil);
			end
		}
	else
		RedSummerCampMainPage.tween_y_2.obj=notice_container_2
		RedSummerCampMainPage.tween_y_2.prop="y"
		RedSummerCampMainPage.tween_y_2.begin=notice_container_2.y
		RedSummerCampMainPage.tween_y_2.change=default_height
		RedSummerCampMainPage.tween_y_2.duration=time
		RedSummerCampMainPage.tween_y_2.MotionFinish = function()
			-- RedSummerCampMainPage.ClearTween()
			RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
				RedSummerCampMainPage.StartNoticeAnim()
			end})
			RedSummerCampMainPage.Timer:Change(notice_time, nil);
		end
	end

	RedSummerCampMainPage.tween_y_2.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampMainPage.tween_y_2:Start();
end

function RedSummerCampMainPage.InitUserData()
	local profile = KeepWorkItemManager.GetProfile()
	if (profile.username == nil or profile.username == "") then
		KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
			if data.username and data.username ~= "" then
				RedSummerCampMainPage.RefreshPage()
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
		UserData.limit_nickname = RedSummerCampMainPage.GetLimitLabel(UserData.nickname, 26)
	end
	-- UserData.nickname  = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"

	UserData.limit_username = UserData.username

	-- profile.school = {}
	-- profile.school.name = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"
	UserData.has_school = profile.school ~= nil and profile.school.name ~= nil
	if UserData.has_school then
		UserData.school_name = profile.school and profile.school.name or ""
		-- UserData.limit_school_name = RedSummerCampMainPage.GetLimitLabel(UserData.school_name,18)
		UserData.limit_school_name = UserData.school_name
	else
		UserData.limit_school_name = "尚未关联学校"
	end

	UserData.has_real_name = profile.realname ~= nil and profile.realname ~= ""
	
	UserData.is_vip = profile.vip == 1
	RedSummerCampMainPage.UserData = UserData
end

function RedSummerCampMainPage.GetHeadUrl()

	if profile.portrait and profile.portrait ~= "" then
		return profile.portrait
	end
	return ""
end

function RedSummerCampMainPage.GetUserData(name)
	return RedSummerCampMainPage.UserData[name] or ""
end

function RedSummerCampMainPage.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function RedSummerCampMainPage.GetLearnHistroy()
	return RedSummerCampCourseScheduling.GetTodayHistroy()
end

function RedSummerCampMainPage.GetLearnContent()
	local histroy = RedSummerCampMainPage.GetLearnHistroy()
	local function strings_split(str, sep) 
		local list = {}
		local str = str .. sep
		for word in string.gmatch(str, '([^' .. sep .. ']*)' .. sep) do
			list[#list+1] = word
		end
		return list
	end
	if histroy then
		local content= histroy.content or ""
		local lines = strings_split(content,"<br/>")
		if lines and type(lines) == "table" then
			return lines[1]
		end
	end
end

function RedSummerCampMainPage.OnClickLearn()
	local dataHistroy = RedSummerCampMainPage.GetLearnHistroy()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.main_world_learn", {useNoId=true});
	if dataHistroy then
		RedSummerCampCourseScheduling.ShowPPTPage(dataHistroy.key,dataHistroy.pptIndex)
	else
    	RedSummerCampCourseScheduling.ShowView()
	end
end

function RedSummerCampMainPage.ClickRealName()
	GameLogic.GetFilters():apply_filters(
		'show_certificate',
		function(result)
			if (result) then
				KeepWorkItemManager.LoadProfile(false, function()
					RedSummerCampMainPage.RefreshPage()
				end)
			end
		end
	);
end

function RedSummerCampMainPage.ClickSchool()
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			RedSummerCampMainPage.RefreshPage()
		end)
	end);
end

function RedSummerCampMainPage.GetVipIcon()
	local profile = KeepWorkItemManager.GetProfile()
	local user_tag = KpUserTag.GetMcml(profile);
	return user_tag
end

function RedSummerCampMainPage.OnClickNotice(index)
	local notic_text = "notic_text" .. index
	local value = page:GetValue(notic_text)

	local click_data
	if RedSummerCampMainPage.NoticeDesc then
		for k, v in pairs(RedSummerCampMainPage.NoticeDesc) do
			if string.find(value, v.title) then
				click_data = v
				break
			end
		end
	end

	if click_data and click_data.url and click_data.url ~= "" then
		ParaGlobal.ShellExecute("open", click_data.url, "", "", 1); 
	else
		Notice.Show(1 ,100)
	end
end

function RedSummerCampMainPage.OpenPage(name)
    if(name == "course_page")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.course_page", {useNoId=true});
        local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
        RedSummerCampRecCoursePage.Show();
    elseif(name == "shentongbei")then
        -- local Page = NPL.load("script/ide/System/UI/Page.lua");
        -- Page.ShowShenTongBeiPage();
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.match", {useNoId=true});
		local RacePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/RacePage.lua");
        RacePage.Show();
    elseif(name == "teacher_day")then
		local ActTeacher = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.lua") 
		ActTeacher.ShowView()
    elseif(name == "nationak_day")then
		local ActNationalDay = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Activity/ActNationalDay/ActNationalDay.lua") 
		ActNationalDay.ShowPage()
    elseif(name == "my_works")then
        local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
        Opus:Show()
    elseif(name == "zhengcheng")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("zhengcheng");
    elseif(name == "ai_school")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.ai_school", {useNoId=true});
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("ai_school");
    elseif(name == "parent_page")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.parent_page", {useNoId=true});
        local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
    elseif(name == "summer_camp")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("summer_camp");
    elseif(name == "main_world")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.main_world", {useNoId=true});
		-- local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
		-- RedSummerCampMainWorldPage.Show();
		RedSummerCampCourseScheduling.ShowView()
	elseif(name == "leyuan")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.leyuan", {useNoId=true});
		local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("leyuan");
	elseif(name == "china_story")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.china_story", {useNoId=true});
		local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("china_story");
	elseif(name == "animation_race")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.animation_race", {useNoId=true});
		local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("animation_race");
    elseif(name == "explore")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.explore", {useNoId=true});
		GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
	elseif(name == "superAnimal") then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.super_pet", {useNoId=true});
		local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
        RedSummerCampPPtPage.Show("superAnimal");
    end
end

function RedSummerCampMainPage.QuickStart()
	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
	Opus:Show()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openopus", {useNoId=true});
	-- local last_world_id = GameLogic.GetPlayerController():LoadRemoteData("summer_camp_last_worldid", 0);
	-- if last_world_id and last_world_id > 0 then
	-- 	GameLogic.RunCommand(format('/loadworld -s -force %d', last_world_id))
	-- else
	-- 	local id_list = {
	-- 		ONLINE = 70351,
	-- 		RELEASE = 20669,
	-- 	}
	-- 	local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	-- 	local httpwrapper_version = HttpWrapper.GetDevVersion();
	-- 	local world_id = id_list[httpwrapper_version]
	-- 	GameLogic.RunCommand(format('/loadworld -s -force %d', world_id))
	-- end
end

function RedSummerCampMainPage.IsFinishVideo()
	local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
	return ParacraftLearningRoomDailyPage.HasCheckedToday()
end

function RedSummerCampMainPage.UpdateVideoRedTip()
	local IsFinishVideo = RedSummerCampMainPage.IsFinishVideo()
	if IsFinishVideo then
		local uiObj = ParaUI.GetUIObject("red_tip")
		if uiObj and uiObj:IsValid() then
			uiObj.visible = false
		end
		return
	end
	RedSummerCampMainPage.UpdateRedTipTimer = RedSummerCampMainPage.UpdateRedTipTimer or commonlib.Timer:new({callbackFunc = function(timer)
		local uiObj = ParaUI.GetUIObject("red_tip")
		local IsFinishVideo = RedSummerCampMainPage.IsFinishVideo()
		if uiObj and uiObj:IsValid() then
			uiObj.visible = not IsFinishVideo
		end
		if IsFinishVideo then
			timer:Change()
		end
	end})
	RedSummerCampMainPage.UpdateRedTipTimer:Change(0, 1000);
end

function RedSummerCampMainPage.RefreshPage()
	if page then
		RedSummerCampMainPage.InitUserData()
		page:Refresh(0)
		RedSummerCampMainPage.StartNoticeAnim()
	end
end
function RedSummerCampMainPage.OnClickRightBt(name)
	if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录", function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()
					if page == nil then
						return
					end
					RedSummerCampMainPage.RefreshPage()
					RedSummerCampMainPage.OnClickRightBt(name)
				end, 500)
			end
		end)

		return
	end


    if name == "skin" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openuserskin", {useNoId=true});
		
		local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
		UserInfoPage.ShowPage(System.User.keepworkUsername,"skin")
	elseif name == "certificate" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openuserhonor", {useNoId=true});
		local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
		UserInfoPage.ShowPage(System.User.keepworkUsername,"honor")
	elseif name == "friend" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openfriend", {useNoId=true});
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show();
		RedSummerCampMainPage.ChangeRedTipState("friend_red_icon", false)
	elseif name == "email" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openemail", {useNoId=true});
        Email.Show();		
	elseif name == "task" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.opentask", {useNoId=true});
		local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
		QuestPage.Show();
		RedSummerCampMainPage.HasClickQuest = true
		RedSummerCampMainPage.ChangeRedTipState("task_red_icon", false)
	elseif name == "rank" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openrank", {useNoId=true});
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua").Show();
    end
end

function RedSummerCampMainPage.ClickSchoolName()
	-- if RedSummerCampMainPage.UserData and not RedSummerCampMainPage.UserData.has_school then

	-- end
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			local profile = KeepWorkItemManager.GetProfile()
			-- 是否选择了学校
			if profile and profile.schoolId and profile.schoolId > 0 then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
				local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
				QuestAction.AchieveTask("40003_1", 1, true)
			end

			commonlib.TimerManager.SetTimeout(function()
				RedSummerCampMainPage.RefreshPage()
			end, 500)
		end)
	end);
end

function RedSummerCampMainPage.HandleQuestRedTip()
	local is_all_task_complete = true
	local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
	if QuestProvider:GetInstance().questItemContainer_map then
		local quest_datas = QuestProvider:GetInstance():GetQuestItems() or {}
		for i, v in ipairs(quest_datas) do
			-- 有可以领取任务的时候

			if not v.questItemContainer:IsFinished() then
				is_all_task_complete = false
				break
			end
		end
	end
	RedSummerCampMainPage.ChangeRedTipState("task_red_icon", not is_all_task_complete and not RedSummerCampMainPage.HasClickQuest)
end

function RedSummerCampMainPage.HandleFriendsRedTip()
	if not RedSummerCampMainPage.IsVisible() then
		if RedSummerCampMainPage.CheckRedTipTimer then
			RedSummerCampMainPage.CheckRedTipTimer:Change()
			RedSummerCampMainPage.CheckRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampMainPage.CheckRedTipTimer then
		RedSummerCampMainPage.CheckRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampMainPage.HandleFriendsRedTip()
		end})

		RedSummerCampMainPage.CheckRedTipTimer:Change(60000, 60000);
	end

	FriendManager:LoadAllUnReadMsgs(function ()
		-- 处理未读消息
		if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
			for k, v in pairs(FriendManager.unread_msgs.data) do
				if v.unReadCnt and v.unReadCnt > 0 then
					RedSummerCampMainPage.ChangeRedTipState("friend_red_icon", true)
					break
				end
			end
		end
	end, true);
end

function RedSummerCampMainPage.UpdateRedTip()
	if not RedSummerCampMainPage.IsVisible() then
		if RedSummerCampMainPage.UpdateRedTipTimer then
			RedSummerCampMainPage.UpdateRedTipTimer:Change()
			RedSummerCampMainPage.UpdateRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampMainPage.UpdateRedTipTimer then
		RedSummerCampMainPage.UpdateRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampMainPage.UpdateRedTip()
		end})

		RedSummerCampMainPage.UpdateRedTipTimer:Change(0, 1000);
	end

	RedSummerCampMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
	RedSummerCampMainPage.HandleQuestRedTip()
	RedSummerCampMainPage.UpdateVideoRedTip()
end

function RedSummerCampMainPage.ChangeRedTipState(ui_name, state)
	if not RedSummerCampMainPage.IsVisible() then
		return
	end

	local friend_red_icon = ParaUI.GetUIObject(ui_name)
	
	if friend_red_icon:IsValid() then
		friend_red_icon.visible = state
	end
end

function RedSummerCampMainPage.OpenOlypic()
	-- local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    -- RedSummerCampPPtPage.Show("winterOlympic");
	GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 132939))
end

function RedSummerCampMainPage.GetVipTimeIconDiv(margin_top,click_func_name)
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local profile = KeepWorkItemManager.GetProfile()
	if not profile.vipDeadline or profile.vipDeadline == "" then
		return ""
	end

    local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
	--time_stamp = RedSummerCampMainPage.TimeVip or time_stamp
    local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
    local cur_time_stamp = QuestAction.GetServerTime()

    --test
    -- time_stamp = test_time1 or time_stamp
    -- cur_time_stamp = test2 or cur_time_stamp

    local left_time = time_stamp - cur_time_stamp
	if left_time < 0 then
		return ""
	end

    local min = math.floor(left_time/60)
    local hour = math.floor(min/60) 
    local day = math.floor(hour/24)

	
    if day > 30 then
        return ""
    end

    local show_value = day >= 1 and day or hour
    local unit_icon = day >= 1 and "Texture/Aries/Creator/keepwork/vip/vip_time/tian_10x9_32bits.png#0 0 10 9" or "Texture/Aries/Creator/keepwork/vip/vip_time/xiaoshi_9x8_32bits.png#0 0 9 8"

    local show_value_desc = "0" .. show_value
    local num_margin_left = -8
    local unit_margin_left = -10

    if show_value == 21 then
        num_margin_left = -13
        unit_margin_left = 0
    elseif show_value == 1 then
        num_margin_left = -2
        unit_margin_left = -20 
    elseif show_value == 11 then
        num_margin_left = -5
        unit_margin_left = -15
    elseif show_value >= 20 then
        num_margin_left = -16
        unit_margin_left = 3
    elseif show_value >= 10 then
        num_margin_left = -13
        unit_margin_left = -3 
    end

	margin_top = margin_top or 16
	click_func_name = click_func_name or "OpenVip"
    local div = [[
    <pe:container name="VipLimitTimeIcon" style="float: left;margin-right:15px;margin-top:%s; width: 66px;height: 67px; background: url()">
        <input zorder = "-1" type="button" value='' onclick="%s" is_tool_tip_click_enabled="true" is_lock_position="true" enable_tooltip_hover="true"
            tooltip='page_static://script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/VipTimeToolTip.html'
            style="position:relative;margin-left:0px;margin-top:0px;width:66px;height:70px;background: url(Texture/Aries/Creator/keepwork/vip/vip_time/dipan_66x70_32bits.png#0 0 66 70)" />
        <div style="margin-top: 18px;">
            <pe:textsprite ClickThrough="true" name="VipLimitTimeNum" fontName="VipLimitTime" value = '%s' style="float: left;width: 63px; margin-left:%s;margin-top:2px;font-size:20pt;" />
            <div style="float: left;margin-left: %s;margin-top: 13px; width: 10px;height: 9px; background: url(%s)"></div>
        </div>
    </pe:container>
    ]]

    div = string.format(div, margin_top, click_func_name, show_value_desc, num_margin_left, unit_margin_left, unit_icon)
    return div
end

function RedSummerCampMainPage.EnterWorldFail()
	NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
	WorldCommon.SetParentProjectId()
	GameLogic.GetFilters():remove_filter("enter_world_fail",RedSummerCampMainPage.EnterWorldFail)
	if not RedSummerCampMainPage.IsVisible() then
		RedSummerCampMainPage.Show()
	end
end