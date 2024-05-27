--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/ProgramChecker/ProgramCheckerPage.lua");
local ProgramCheckerPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerPage")
ProgramCheckerPage.Show()
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/ProgramChecker/ProgramCheckerData.lua");

local ProgramCheckerPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerPage")
-- local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local ZhiHuiYun = commonlib.gettable("MyCompany.Aries.Game.GameLogic.ZhiHuiYun")
local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")
local ProgramCheckerData = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerData")

local page
GameLogic.IsInDebugPlan = true
ProgramCheckerPage.ModList = {
	TimeSetting = 1, -- 设置时间
	CheckerStep1 = 2, -- 步骤1 下载世界
	CheckerStep2 = 3, -- 步骤2 性能测试
	CheckerStep3 = 4, -- 步骤3
	CheckerStep4 = 5, -- 步骤4
	CheckerResult = 6,-- 测试结果
}

ProgramCheckerPage.CurMod = ProgramCheckerPage.ModList.TimeSetting

function ProgramCheckerPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = ProgramCheckerPage.OnCreate
	page.OnClose = ProgramCheckerPage.OnClose
end


function ProgramCheckerPage.OnCreate()
	-- print(">>>>>>>>>>>>>>>>>>>>>>ProgramCheckerPage.OnCreate()", ProgramCheckerPage.CurMod)
	-- echo(ProgramCheckerData.ReportData, true)
	if ProgramCheckerPage.CurMod == ProgramCheckerPage.ModList.CheckerStep1 then
		ProgramCheckerPage.OnStep1()
	elseif ProgramCheckerPage.CurMod == ProgramCheckerPage.ModList.CheckerStep2 then
		ProgramCheckerPage.OnStep2()
	elseif ProgramCheckerPage.CurMod == ProgramCheckerPage.ModList.CheckerStep3 then
		ProgramCheckerPage.OnStep3()
	elseif ProgramCheckerPage.CurMod == ProgramCheckerPage.ModList.CheckerStep4 then
		ProgramCheckerPage.OnStep4()
	elseif ProgramCheckerPage.CurMod == ProgramCheckerPage.ModList.CheckerResult then
		ProgramCheckerPage.OnStepResult()
	end
end

function ProgramCheckerPage.OnClose()
	ProgramCheckerPage.StepTimer:Change()
	ProgramCheckerPage.StepTimer = nil
end

function ProgramCheckerPage.Close()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function ProgramCheckerPage.Show()
	-- if true then
	-- 	GameLogic.RunCommand("/loadworld worlds/DesignHouse/_user/yangguiyi/trade")
	-- end
	GameLogic.RunCommand("/loadworld worlds/DesignHouse/temp_world")

	ProgramCheckerData.Init()
	-- ParaIO.DeleteFile("config/gameclient.config.xml");
	local params = {
		url = "script/apps/Aries/Creator/Game/ZhiHuiYun/ProgramChecker/ProgramCheckerPage.html", 
		name = "ProgramCheckerPage.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		zorder = 9999,
		bShow = bShow,
		isTopLevel = true,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		cancelShowAnimation = true,
		enable_esc_key = System.options.isZhihuiyunDebug
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
	local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
	MainLogin:CloseBackgroundPage()

    GameLogic.GetFilters():add_filter("on_program_checker_auto_save", function()
		local data = ProgramCheckerData.GetData("task4_record") or {}
		data.autoSave = 1
		ProgramCheckerData.SetData("task4_record", data)
    end);

    GameLogic.GetFilters():add_filter("on_program_checker_step2_end", function()
		if ProgramCheckerPage.on_program_checker_step2_end then
			ProgramCheckerPage.on_program_checker_step2_end()
		end
    end);

    GameLogic.GetFilters():add_filter("on_program_checker_step3_end", function(write_count)
		if ProgramCheckerPage.on_program_checker_step3_end then
			ProgramCheckerPage.on_program_checker_step3_end(write_count)
		end
    end);

    GameLogic.GetFilters():add_filter("downloadFile_notify", function(downloadState, text, currentFileSize, totalFileSize)
		if ProgramCheckerPage.downloadFile_notify then
			ProgramCheckerPage.downloadFile_notify(downloadState, text, currentFileSize, totalFileSize)
		end
    end);

	-- 捕获错误日志
	GameLogic.GetFilters():add_filter("on_error_report", function()
		if ProgramCheckerPage.on_error_report then
			ProgramCheckerPage.on_error_report()
		end
	end);

    GameLogic.GetFilters():add_filter("on_program_checker_manul_save", function()
		if ProgramCheckerPage.on_program_checker_manul_save then
			ProgramCheckerPage.on_program_checker_manul_save()
		end
    end);

    GameLogic.GetFilters():add_filter("on_program_checker_step4_end", function()
		if ProgramCheckerPage.on_program_checker_step4_end then
			ProgramCheckerPage.on_program_checker_step4_end()
		end
    end);

	-- 设置ip
	ProgramCheckerData.SetData("ip", "")
	ZhiHuiYun:GetIpInfo(function(ip_info)
		ProgramCheckerData.SetData("ip", ip_info.ip)
	end)

	-- 硬件软件相关
	ProgramCheckerData.SetData("reg_info", 0)
	ProgramCheckerData.SetData("username", System.User.zhy_userdata.username)
	ProgramCheckerData.SetData("userId", System.User.zhy_userdata.id)

	local statistic_record = {
		uploadWorld = 1,
		avg_uploadSpeed = "0KB/s",
		min_uploadSpeed = "0KB/s",
		max_uploadSpeed = "0KB/s",
	}
	ProgramCheckerData.SetData("statistic_record", statistic_record)
	ZhiHuiYun:GetMachineInfo(function(info)
		-- local hardware_info = {}
		ProgramCheckerData.SetData("hardware_info", info)
		local os_info = {}
		for key, value in pairs(info.osInfo) do
			os_info[key] = value
		end
		ProgramCheckerData.SetData("os_info", os_info)

	end)
end

function ProgramCheckerPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function ProgramCheckerPage.HideAdvice()
	local advice_container = page:FindControl("advice_container")
	advice_container.visible = false
end

function ProgramCheckerPage.ShowAdvice()
	local advice_container = page:FindControl("advice_container")
	advice_container.visible = true
end

function ProgramCheckerPage.OnStart()
	-- local advice_container = page:FindControl("advice_container")
	-- advice_container.visible = true
	local time_hour_value = tonumber(page:GetValue("HourInput"))
	
	if not time_hour_value or time_hour_value > 23 or time_hour_value < 0 or time_hour_value - math.floor(time_hour_value) ~= 0 then
		page:SetValue("error_code", "小时设置有误")
		return
	end

	local time_min_value = tonumber(page:GetValue("MinInput"))
	if not time_min_value or time_min_value > 59 or time_min_value < 0 or time_min_value - math.floor(time_min_value) ~= 0 then
		page:SetValue("error_code", "分钟设置有误")
		return
	end

	local time_sec_value = tonumber(page:GetValue("SecInput"))
	if not time_sec_value or time_sec_value > 59 or time_sec_value < 0 or time_sec_value - math.floor(time_sec_value) ~= 0 then
		page:SetValue("error_code", "秒设置有误")
		return
	end

	-- 转换下时间 如果时间在当前时间之前 则报错
	local server_time_stamp = ProgramCheckerPage.GetServerTime()
	local year = os.date("%Y", server_time_stamp)	
    local month = os.date("%m", server_time_stamp)
	local day = os.date("%d", server_time_stamp)
    local set_time_stamp = os.time({year = year, month = month, day = day, hour=time_hour_value, min=time_min_value, sec=time_sec_value})
	if set_time_stamp < server_time_stamp then
		page:SetValue("error_code", "时间设置有误，已不在设置的时间范围内")
		return
	end

	local set_plan_name = page:GetValue("PlanName")

	if not set_plan_name or set_plan_name == "" then
		page:SetValue("error_code", "测试计划输入有误")
		return
	end

	local len = commonlib.utf8.len(set_plan_name);
	if len > 35 then
		page:SetValue("error_code", "测试计划输入过长")
		return
	end

	local hour_input = page:FindUIControl("HourInput")
	hour_input.enabled = false

	local min_input = page:FindUIControl("MinInput")
	min_input.enabled = false

	local sec_input = page:FindUIControl("SecInput")
	sec_input.enabled = false

	local plan_name = page:FindUIControl("PlanName")
	plan_name.enabled = false
	
	local start_bt = page:FindUIControl("PlanStartBt")
	-- start_bt.x = start_bt.x + 10
	start_bt.enabled = false

	page:SetValue("error_code", "")

	local left_time = set_time_stamp - server_time_stamp
	
	-- GameLogic.AddBBS(nil, "启动时间设置成功");

	ProgramCheckerData.SetData("name", set_plan_name)

    local start_server_time = ProgramCheckerPage.GetServerTime()
    ProgramCheckerPage.StepTimer = ProgramCheckerPage.GetStepTimer()
	ProgramCheckerPage.StepTimer.callbackFunc = function(timer)
        local minutes = math.floor(left_time / 60)
        local remaining_seconds = left_time % 60
        local time_desc = string.format("预计启动还剩%02d:%02d", minutes, remaining_seconds)
		page:SetValue("PlanStartBt", time_desc)

		if left_time <= 0 then
			ProgramCheckerPage.StepTimer:Change()
			ProgramCheckerPage.Next()
		end

		left_time = left_time - 1
    end

	ProgramCheckerPage.StepTimer:Change(0, 1000)
	-- commonlib.TimerManager.SetTimeout(function()
	-- 	ProgramCheckerPage.Next()
	-- end,left_time * 1000)
end

function ProgramCheckerPage.OnReset()
	-- if System.options.isZhihuiyunDebug then
	-- 	ProgramCheckerPage.Close()
	-- end
	
	ProgramCheckerPage.StepTimer:Change()
	ProgramCheckerPage.StepTimer = nil
	-- GameLogic.RunCommand("/loadworld -s home")
	GameLogic.RunCommand("/loadworld worlds/DesignHouse/temp_world")
	
	commonlib.TimerManager.SetTimeout(function()
		ParaIO.DeleteFile("worlds/DesignHouse/userworlds/")
		ProgramCheckerPage.CurMod = ProgramCheckerPage.ModList.TimeSetting
		ProgramCheckerPage.RefreshPage()
	end,500)
end


function ProgramCheckerPage.Next()
	ProgramCheckerPage.CurMod = ProgramCheckerPage.CurMod + 1
	ProgramCheckerPage.RefreshPage()
end

function ProgramCheckerPage.GetServerTime()
	return GameLogic.GetFilters():apply_filters('service.session.get_current_server_time') or os.time()
end

function ProgramCheckerPage.GetStepTimer()
	if ProgramCheckerPage.StepTimer then
		return ProgramCheckerPage.StepTimer
	end

	ProgramCheckerPage.StepTimer = commonlib.Timer:new()
	return ProgramCheckerPage.StepTimer
end

-- 获取当前用时字符串
function ProgramCheckerPage.GetTimeDesc()
	if not ProgramCheckerPage.SettingStartTime then
		return 0
	end

	local start_time = ProgramCheckerPage.SettingStartTime
	local cur_time = ProgramCheckerPage.GetServerTime()
	local seconds = cur_time - start_time
	local minutes = math.floor(seconds / 60)
	local remaining_seconds = seconds % 60
	local time_desc = string.format("%02d:%02d", minutes, remaining_seconds)

	return time_desc,seconds
end

function ProgramCheckerPage.OnStep1()
	ParaIO.DeleteFile("worlds/DesignHouse/userworlds/")

	-- 起一个计时器用于计时跟计算网速
	ProgramCheckerPage.SettingStartTime = ProgramCheckerPage.GetServerTime()
	ProgramCheckerPage.StepTimer = ProgramCheckerPage.GetStepTimer()
	local last_current_bytes = ParaEngine.GetAsyncLoaderBytesReceived(-1);
	local start_bytes = last_current_bytes
	local min_speed = 10*1000*1000 --10mb/s
	local max_speed = 0
	local step_start_time = ProgramCheckerPage.GetServerTime()

	local function get_dow_speed_desc(dow_speed)
		-- dow_speed 单位 字节/s
		if dow_speed > 1000000 then
			return string.format("%.2f Mb/s", dow_speed/1000000)
		else
			return string.format("%.2f Kb/s", dow_speed/1000)
		end
	end

	ProgramCheckerPage.StepTimer.callbackFunc = function(timer)
		if not page then
			ProgramCheckerPage.StepTimer:Change()
			ProgramCheckerPage.StepTimer = nil
			return
		end

        local report_key = "task1_record"
        local report_data = ProgramCheckerData.GetData(report_key) or {}
		-- 更新时间
		local time_desc = ProgramCheckerPage.GetTimeDesc()
		page:SetValue("cur_use_time", time_desc)
		report_data.usedTime = time_desc

		-- 网络速度处理
		local cur_bytes_all = ParaEngine.GetAsyncLoaderBytesReceived(-1);
		local cur_dow_bytes = cur_bytes_all - last_current_bytes --这是每一秒下载的字节数
		last_current_bytes = cur_bytes_all

		-- 计算平均速度
		--先获取耗时
		local cur_time = ProgramCheckerPage.GetServerTime()
		local dow_bytes_all = cur_bytes_all - start_bytes

		local use_time = cur_time - step_start_time
		if use_time > 0 then
			local avg_dow_speed = dow_bytes_all / (cur_time - step_start_time)
			if tonumber(avg_dow_speed) then
				local avg_speed_desc = get_dow_speed_desc(avg_dow_speed)
				page:SetValue("avg_dow_speed", avg_speed_desc)
				report_data.avg_downloadSpeed = avg_speed_desc
			end
		end


		-- 最低速度
		if (cur_dow_bytes > 0 and cur_dow_bytes < min_speed) then
			min_speed = cur_dow_bytes
			local min_speed_desc = get_dow_speed_desc(cur_dow_bytes)
			page:SetValue("min_dow_speed", min_speed_desc)
			report_data.min_downloadSpeed = min_speed_desc
		end

		-- 最高速度
		if (cur_dow_bytes > max_speed) then
			max_speed = cur_dow_bytes
			local max_speed_desc = get_dow_speed_desc(cur_dow_bytes)
			page:SetValue("max_dow_speed", max_speed_desc)
			report_data.max_downlodaSpeed = max_speed_desc
		end


		ProgramCheckerData.SetData(report_key, report_data)
	end
	ProgramCheckerPage.StepTimer:Change(0, 1000);

	-- if System.options.isZhihuiyunDebug then
	-- 	local reset_bt = page:FindUIControl("ResetBt")
	-- 	reset_bt.visible = true
	-- end

	-- 下载世界filter
	-- 先进度条归零
	local total_widt = 417
	local pro_object = page:FindUIControl("pro_loading_world")
	pro_object.width = 0
	ProgramCheckerPage.downloadFile_notify = function(downloadState, text, currentFileSize, totalFileSize)
		-- downloadState 0 下载中 1 下载完成 2 下载失败
		if ProgramCheckerPage.CurMod ~= ProgramCheckerPage.ModList.CheckerStep1 then
			return
		end

		if not page then
			return
		end

		if downloadState == 0 then
			local cur_dow_size = currentFileSize
			local total_size = totalFileSize
			pro_object.width = cur_dow_size / total_size * total_widt

		elseif downloadState == 1 then
			commonlib.TimerManager.SetTimeout(function()
				ProgramCheckerPage.Next()
			end,500)
		else
			local reset_bt = page:FindUIControl("ResetBt")
			reset_bt.visible = true
		end
	end

	GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 2614293))
end

function ProgramCheckerPage.OnStep2()
    local engine_attr = ParaEngine.GetAttributeObject();
    local all_fps = 0
    local min_fps = 99
    local max_fps = 0

	local total_widt = 417
	local pro_object = page:FindUIControl("pro_step2")
	pro_object.width = 0
	local all_time = 267

    local start_server_time = ProgramCheckerPage.GetServerTime()
    ProgramCheckerPage.StepTimer = ProgramCheckerPage.GetStepTimer()
	ProgramCheckerPage.StepTimer.callbackFunc = function(timer)
        local report_key = "task2_record"
        local report_data = ProgramCheckerData.GetData(report_key) or {}

        local cur_fps = engine_attr:GetField("FPS", 0)
        -- 平均帧数
        all_fps = all_fps + cur_fps
		local duration = math.max(ProgramCheckerPage.GetServerTime() - start_server_time, 1)

        local avg_fps = math.min(math.floor(all_fps/duration), 60)
		page:SetValue("avg_fps_speed", avg_fps .. "fps")
        report_data.avg_FPS = avg_fps
        
        -- 最小帧数
        if cur_fps < min_fps then
            min_fps = cur_fps
			page:SetValue("min_fps_speed", min_fps .. "fps")
            report_data.min_FPS = min_fps
        end
        -- 最大帧数
        if cur_fps > max_fps then
            max_fps = cur_fps
			page:SetValue("max_fps_speed", max_fps .. "fps")
            report_data.max_FPS = max_fps
        end

		
        local minutes = math.floor(duration / 60)
        local remaining_seconds = duration % 60
        local time_desc = string.format("%02d:%02d", minutes, remaining_seconds)
		page:SetValue("cur_use_time2", time_desc)
        report_data.usedTime = time_desc

		-- 进度条
		pro_object.width = math.min(duration / all_time * total_widt, total_widt)

        ProgramCheckerData.SetData(report_key, report_data)

    end

	ProgramCheckerPage.StepTimer:Change(0, 1000)

	ProgramCheckerPage.on_error_report = function()
		if ProgramCheckerPage.CurMod ~= ProgramCheckerPage.ModList.CheckerStep2 then
			return
		end
		
		local switch_theme_data = ProgramCheckerData.GetTask2ItemData("switchTheme") or {}
		local error_count = switch_theme_data.encounterError or 0
		error_count = error_count + 1
		switch_theme_data.encounterError = error_count

		ProgramCheckerData.SetTask2ItemData("switchTheme", switch_theme_data)
	end

	ProgramCheckerPage.on_program_checker_step2_end = function()
		-- print(">>>>>>>>>>>>>>>>>>>>>>>>>on_program_checker_step2_end")
		-- echo(ProgramCheckerData.GetData("task2_record"), true)
		if ProgramCheckerPage.StepTimer then
			ProgramCheckerPage.StepTimer:Change()
			ProgramCheckerPage.StepTimer = nil
		end

		pro_object.width = total_widt
		commonlib.TimerManager.SetTimeout(function()
			ProgramCheckerPage.Next()
		end,500)
	end

	local reset_bt = page:FindUIControl("ResetBt2")
	reset_bt.visible = true
end

function ProgramCheckerPage.OnStep3()
	GameLogic.GetCodeGlobal():BroadcastTextEvent("CheckWriten");
    local engine_attr = ParaEngine.GetAttributeObject();
    local all_fps = 0
    local min_fps = 99
    local max_fps = 0

	local total_widt = 417
	local pro_object = page:FindUIControl("pro_step2")
	pro_object.width = 0
	local all_time = 7

    local start_server_time = ProgramCheckerPage.GetServerTime()
    ProgramCheckerPage.StepTimer = ProgramCheckerPage.GetStepTimer()
	ProgramCheckerPage.StepTimer.callbackFunc = function(timer)
        local report_key = "task3_record"
        local report_data = ProgramCheckerData.GetData(report_key) or {}

        local cur_fps = engine_attr:GetField("FPS", 0)
        -- 平均帧数
        all_fps = all_fps + cur_fps
		local duration = math.max(ProgramCheckerPage.GetServerTime() - start_server_time, 1)
        local avg_fps = math.min(math.floor(all_fps/duration), 60)
		page:SetValue("avg_fps_speed", avg_fps .. "fps")
        report_data.avg_FPS = avg_fps
        
        -- 最小帧数
        if cur_fps < min_fps then
            min_fps = cur_fps
			page:SetValue("min_fps_speed", max_fps .. "fps")
            report_data.min_FPS = min_fps
        end
        -- 最大帧数
        if cur_fps > max_fps then
            max_fps = cur_fps
			page:SetValue("max_fps_speed", max_fps .. "fps")
            report_data.max_FPS = max_fps
        end

        local minutes = math.floor(duration / 60)
        local remaining_seconds = duration % 60
        local time_desc = string.format("%02d:%02d", minutes, remaining_seconds)
		page:SetValue("cur_use_time2", time_desc)

        report_data.usedTime = time_desc

		-- 进度条
		pro_object.width = math.min(duration / all_time * total_widt, total_widt)

        ProgramCheckerData.SetData(report_key, report_data)

    end

	ProgramCheckerPage.StepTimer:Change(0, 1000)
	ProgramCheckerPage.on_program_checker_step3_end = function(write_count)

		local report_key = "task3_record"
		local report_data = ProgramCheckerData.GetData(report_key) or {}
		report_data.writeCodeBlockResult = 1
		report_data.writeCodeBlockNumber = write_count or 0
		ProgramCheckerData.SetData(report_key, report_data)

		ProgramCheckerPage.StepTimer:Change()
		pro_object.width = total_widt
		-- print(">>>>>>>>>>>>>>>>>>>>>>>>>on_program_checker_step3_end")
		-- echo(ProgramCheckerData.GetData("task3_record"), true)
		commonlib.TimerManager.SetTimeout(function()
			ProgramCheckerPage.Next()
		end,1000)

	end

	local reset_bt = page:FindUIControl("ResetBt2")
	reset_bt.visible = true
end

function ProgramCheckerPage.OnStep4()
	GameLogic.GetCodeGlobal():BroadcastTextEvent("CheckManulSave");
    local engine_attr = ParaEngine.GetAttributeObject();

	local total_widt = 417
	local pro_object = page:FindUIControl("pro_commit")
	pro_object.width = 0
	local all_time = 25

    local start_server_time = ProgramCheckerPage.GetServerTime()
    ProgramCheckerPage.StepTimer = ProgramCheckerPage.GetStepTimer()
	ProgramCheckerPage.StepTimer.callbackFunc = function(timer)
        local report_key = "task4_record"
        local report_data = ProgramCheckerData.GetData(report_key) or {}

		local auto_save_desc = report_data.autoSave == 1 and "成功" or "进行中..."
		-- local manul_save_desc = report_data.manulSave == 1 and "成功" or "进行中"
		-- local commit_desc = report_data.manulSave == 1 and "进行中" or ""
		-- if report_data.commit == 1 then
		-- 	commit_desc = "成功"
		-- end

		page:SetValue("auto_save", auto_save_desc)
		-- page:SetValue("manul_save", manul_save_desc)
		-- page:SetValue("commit", commit_desc)
		

		local duration = math.max(ProgramCheckerPage.GetServerTime() - start_server_time, 1)
        local minutes = math.floor(duration / 60)
        local remaining_seconds = duration % 60
        local time_desc = string.format("%02d:%02d", minutes, remaining_seconds)
		page:SetValue("cur_use_time3", time_desc)
        report_data.usedTime = time_desc

		-- 进度条
		pro_object.width = math.min(duration / all_time * total_widt, total_widt)

        ProgramCheckerData.SetData(report_key, report_data)

    end

	ProgramCheckerPage.StepTimer:Change(0, 1000)

	ProgramCheckerPage.on_program_checker_manul_save = function()
		local data = ProgramCheckerData.GetData("task4_record") or {}
		data.manulSave = 1
		ProgramCheckerData.SetData("task4_record", data)
		-- 保存完 调用提交
		page:SetValue("manul_save", "完成")
		page:SetValue("commit", "进行中...")
		GameLogic.GetCodeGlobal():BroadcastTextEvent("CheckCommit");
	end

	ProgramCheckerPage.on_program_checker_step4_end = function()
		-- print(">>>>>>>>>>>>>>>>>>>>>>>>>on_program_checker_step3_end")
		-- echo(ProgramCheckerData.GetData("task4_record"), true)
		page:SetValue("commit", "成功")

		ProgramCheckerPage.StepTimer:Change()
		pro_object.width = total_widt
		local plan_name = ProgramCheckerData.GetData("name") or ""
		if string.find(plan_name, "zhihuiyundebug") or System.options.isZhihuiyunDebug then
			local next_bt = page:FindUIControl("next_step_bt")
			next_bt.visible = true
		else
			commonlib.TimerManager.SetTimeout(function()
				ProgramCheckerPage.Next()
			end,1000)
		end
	end
end

ProgramCheckerPage.TryTimes = 0
function ProgramCheckerPage.OnStepResult()
	-- 这里要检测完整性后调用上报接口
	local task1_record_data = ProgramCheckerData.GetData("task1_record") or {}
	local task2_record_data = ProgramCheckerData.GetData("task2_record") or {}
	local task3_record_data = ProgramCheckerData.GetData("task3_record") or {}
	local task4_record_data = ProgramCheckerData.GetData("task4_record") or {}

	page:SetValue("step_1_time", task1_record_data.usedTime or "")
	page:SetValue("step_2_time", task2_record_data.usedTime or "")
	page:SetValue("step_3_time", task3_record_data.usedTime or "")
	page:SetValue("step_4_time", task4_record_data.usedTime or "")
	page:SetValue("avg_dow_speed_all", task1_record_data.avg_downloadSpeed or "")

	-- 平均帧数取第二步跟第三步的平均值
	local step2_avg_fps = task2_record_data.avg_FPS or 0
	local step3_avg_fps = task3_record_data.avg_FPS or 0
	local avg_fps = math.floor((step2_avg_fps + step3_avg_fps)/2)
	page:SetValue("avg_fps_all", avg_fps .. "FPS")
	ProgramCheckerPage.CompareFile(function(request_result, compare_result)
		if not request_result and ProgramCheckerPage.TryTimes < 5 then
			ProgramCheckerPage.TryTimes = ProgramCheckerPage.TryTimes + 1
			ProgramCheckerPage.OnStepResult()
			return
		end

		page:SetValue("all_result", compare_result and "是" or "否")
		ProgramCheckerData.SetData("completeness", compare_result and 1 or 0)


		local start_time = ProgramCheckerPage.SettingStartTime or 0
		local duration = ProgramCheckerPage.GetServerTime() - start_time
		ProgramCheckerData.SetData("teststartTime", tostring(start_time))
		ProgramCheckerData.SetData("duration", duration)

		ZhiHuiYunHttpApi.ReportCompetitionPerformanceTest(ProgramCheckerData.ReportData, function(err, msg, data)
			print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYunHttpApi.ReportCompetitionPerformanceTest", err)
			echo(data, true)
			echo(data_raw, true)

			if err == 200 then
				local end_bt = page:FindUIControl("OnEndBt")
				end_bt.enabled = true
				
			end
		end)
	end)
	
end

function ProgramCheckerPage.OnEnd()
	local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
	Desktop.ForceExit()
end

function ProgramCheckerPage.CompareFile(callback)
	local keepwork_world_detail = commonlib.gettable("keepwork.world.detail");
	local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
	local project_id = currentWorld.kpProjectId
	-- 下载远程文件
	keepwork_world_detail({router_params = {id = project_id}}, function(err, msg, data)
		if (data and data.world and data.world.commitId) then
			local temp_world_path = "temp/miniworlds/competitiontemp_world"
			local file_path = ParaIO.GetWritablePath().. temp_world_path .. "/";
			if ParaIO.DoesFileExist(file_path) then
				ParaIO.DeleteFile(file_path)
			end

			local filename = "miniworld.template.xml"
			GameLogic.GetFilters():apply_filters('get_single_file_by_commit_id',project_id, data.world.commitId, filename, function(content)
				if (not content) then
					-- GameLogic.AddBBS("World2In1", "加载失败，请重新尝试");
					callback(false)
					return;
				end
		
				local template_file = file_path..filename
				ParaIO.CreateDirectory(template_file);
				local file = ParaIO.open(template_file, "w");
				if (file:IsValid()) then
					file:write(content, #content);
					file:close();
					local temp_file_info = {}
					local world_file_info = {}

					local world_file = currentWorld.worldpath .. filename
					local compare_result_temp = ParaIO.GetFileInfo(template_file, temp_file_info)
					local compare_result_world = ParaIO.GetFileInfo(world_file, world_file_info)

					if compare_result_temp and compare_result_world then
						local compare_result = temp_file_info.size == world_file_info.size
						if callback then
							callback(true, compare_result)
						end
					else
						if callback then
							callback(true, false)
						end
					end
				else
					if callback then
						callback(false)
					end
				end
			end, true);
			
		else
			if callback then
				callback(false)
			end
		end
	end);
end