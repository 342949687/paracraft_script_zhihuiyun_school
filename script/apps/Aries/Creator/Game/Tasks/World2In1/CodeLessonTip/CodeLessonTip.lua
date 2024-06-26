--[[
author:yangguiyi
date:
Desc:
use lib:

local CodeLessonTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.lua") 
CodeLessonTip.ShowView()
]]

-- selection group index used to show the frame
local groupindex_hint_auto = 6;
local groupindex_wrong = 3;
local groupindex_hint = 5; -- when placeable but not matching hand block

local target_desc_list = {
    [1] = [[
        观察地图，用代码控制运动员从起点移动至光圈处<div style="height: 4px;"></div>
        到达光圈处后，说出“yeah”即可通过<div style="height: 4px;"></div>
        运用“前进”和“说”代码块来实现运动员的移动和说话<div style="height: 4px;"></div>
    ]],
    [2] = [[
        观察地图，用代码控制运动员移动至光圈处<div style="height: 4px;"></div>
        注意路径中需要跳过大水坑<div style="height: 4px;"></div>
        运用“前进”代码块来实现运动员移动<div style="height: 4px;"></div>
        运用“位移”代码块来跳过水坑<div style="height: 4px;"></div>        
    ]],
    [3] = [[
        观察地图，用代码控制运动员移动至光圈处<div style="height: 4px;"></div>
        注意有分岔路，需要选择正确的路<div style="height: 4px;"></div>
        运用“前进”代码块让运动员移动<div style="height: 4px;"></div>
        运用“旋转”代码块让运动员转向<div style="height: 4px;"></div>
        再移动到光圈处，说出“yeah”即可通过<div style="height: 4px;"></div>
    ]],
    [4] = [[
        观察地图，用代码控制运动员去拿到球<div style="height: 4px;"></div>        
        运用“旋转到”代码块让运动员直接转到指定角度<div style="height: 4px;"></div>
        运用“说”代码块让运动员说话<div style="height: 4px;"></div>
        再移动到光圈处，说出“yeah”即可通过<div style="height: 4px;"></div>
    ]],
    [5] = [[
        观察地图，用代码控制运动员去NPC处拿球<div style="height: 4px;"></div>        
        路上需要跨过栅栏障碍，碰到后任务失败<div style="height: 4px;"></div>
        运用“旋转到”代码块让运动员转到指定角度<div style="height: 4px;"></div>
        运用“播放动作编号”和“等待”代码块让运动员做出指定动作<div style="height: 4px;"></div>
        然后移动到终点即可完成任务<div style="height: 4px;"></div>
    ]],
    [6] = [[
        观察地图，用代码控制运动员移动到终点处<div style="height: 4px;"></div>
        当脚下的方块id是52时顺时针转向<div style="height: 4px;"></div>       
        运用“如果那么”和“是否碰到”代码块来判断是否踩到方块<div style="height: 4px;"></div>
        运用“旋转”和“前进”代码块让运动员转向和移动<div style="height: 4px;"></div>
        运用“缩放到百分之”代码块让运动员放大到原来的2倍<div style="height: 4px;"></div>
        走到终点后，需要将运动员放大2倍即完成任务<div style="height: 4px;"></div>
    ]],
    [7] = [[
        观察地图，用代码控制运动员移动到光圈处<div style="height: 4px;"></div>
        当脚下的方块id是52时顺时针转向<div style="height: 4px;"></div>       
        运用“如果那么”和“是否碰到”代码块来判断是否踩到方块<div style="height: 4px;"></div>
        运用“旋转”和“前进”代码块让运动员转向和移动<div style="height: 4px;"></div>
        运用“说”代码块让运动员说话<div style="height: 4px;"></div>
        走到终点后，需要说出“jump”即完成任务<div style="height: 4px;"></div>
    ]],
    [8] = [[
        观察地图，用代码控制运动员移动到光圈处<div style="height: 4px;"></div>
        当脚下的方块id是52时顺时针转90度，否则则逆时针转90度<div style="height: 4px;"></div>        
        运用“如果那么否则”和“是否碰到”代码块来判断是否踩到方块<div style="height: 4px;"></div>
        运用“旋转”和“前进”代码块让运动员转向和移动<div style="height: 4px;"></div>
        运用“说”代码块让运动员说话<div style="height: 4px;"></div>
        走到终点后，需要说出“yeah”即完成任务<div style="height: 4px;"></div>
    ]],
    [9] = [[
        观察地图，用代码控制运动员绕跑道一圈回到起点<div style="height: 4px;"></div>
        重复走和转向将跑道上的3个踏板都走到<div style="height: 4px;"></div>        
        运用“旋转”和“前进”代码块让运动员转向和移动<div style="height: 4px;"></div>
        运用“循环”代码块来重复执行<div style="height: 4px;"></div>
        运用“说”代码块让运动员说话<div style="height: 4px;"></div>
        然后回到起点后，需要说出“win”即完成任务<div style="height: 4px;"></div>
    ]],
    [10] = [[
        观察地图，用代码控制运动员避开水坑到达光圈处<div style="height: 4px;"></div>
        需要重复前进并判断脚下方块来选择正确的方向<div style="height: 4px;"></div>        
        运用“循环”代码块来重复执行<div style="height: 4px;"></div>
        运用“如果那么否则”和“是否碰到”代码块来判断是否踩到方块<div style="height: 4px;"></div>
        运用“旋转”和“前进”代码块让运动员转向和移动<div style="height: 4px;"></div>
        运用“说”代码块让运动员说话<div style="height: 4px;"></div>
        走到光圈处后，需要说出“win”即完成任务<div style="height: 4px;"></div>
    ]],
    [1.1]=[[用代码控制角色走到光圈处<div style="height: 4px;"></div>走到门口时，需要回答问题打开门<div style="height: 4px;"></div>运用“前进”和“说”代码块来移动和回答]],
    [1.2]=[[在岩浆之前穿过桥，打开门，最后到达终点]],
    [1.3]=[[向前走到传送点，说出正确的数字传送到下一个点<div style="height: 4px;"></div>然后继续前进，直到走到光圈处]],
    [2.1]=[[向前走到围栏前，跳起来跨过围栏到达光圈处]],
    [2.2]=[[向前跑到光圈处，并且跨过中间的围栏]],
    [2.3]=[[向前移动爬上山顶，到达光圈处]],
    [3.1]=[[沿着路走到光圈处目标介绍（镜头+文字）：]],
    [3.2]=[[沿着正确的道路走到光圈处]],
    [3.3]=[[沿着路找到黄色钥匙<div style="height: 4px;"></div>用黄色钥匙打开黄色的门拿到灰色钥匙<div style="height: 4px;"></div>再用灰色钥匙打开灰色门，最后走到光圈处]],
    [4.1]=[[沿着路走到门口，回答问题后开门<div style="height: 4px;"></div>继续走到光圈处即可]],
    [4.2]=[[走到门外的踏板，打开石门<div style="height: 4px;"></div>再走木质踏板，打开木门<div style="height: 4px;"></div>继续走到光圈处即可]],
    [4.3]=[[找到门外的黄色钥匙并打开黄色门<div style="height: 4px;"></div>再走到木质踏板，打开木门<div style="height: 4px;"></div>再走到石质踏板，打开石门<div style="height: 4px;"></div>然后找到白色钥匙并打开白色门<div style="height: 4px;"></div>继续走到光圈处即可]],
    [5.1]=[[走到门前做出对应动作打开门<div style="height: 4px;"></div>继续走到光圈处即可]],
    [5.2]=[[找到门外的黄色钥匙并打开黄色门<div style="height: 4px;"></div>然后找到白色钥匙并打开白色门<div style="height: 4px;"></div>继续走到光圈处即可]],
    [5.3]=[[走到宝箱前做出动作，打开宝箱获得斧头<div style="height: 4px;"></div>继续沿着路走，做出动作来砍掉挡路的树<div style="height: 4px;"></div>然后走到光圈处即可]],
    [6.1]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号则右转<div style="height: 4px;"></div>直到走到光圈处即可]],
    [6.2]=[[每次向前移动5步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则去踩左侧的踏板开门，然后返回<div style="height: 4px;"></div>如此重复，直到走到光圈处即可]],
    [6.3]=[[每次向前移动5步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则说“芝麻开门”，大门打开<div style="height: 4px;"></div>如此重复，直到走到光圈处即可]],
    [7.1]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则踩左侧的2个踏板将灯点亮，然后再回到主路<div style="height: 4px;"></div>如此重复，所有灯点亮后大门打开，走到光圈处即可]],
    [7.2]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则右转向前爬上台阶<div style="height: 4px;"></div>如此重复，走到光圈处即可]],
    [7.3]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则左转向前<div style="height: 4px;"></div>若遇到门，则说“开门”将门打开<div style="height: 4px;"></div>如此重复，走到光圈处即可]],
    [8.1]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则右转，否则左转<div style="height: 4px;"></div>如此重复，走到光圈处即可]],
    [8.2]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则左转踩踏板点亮灯，再返回<div style="height: 4px;"></div>若不是20号，则右转踩踏板点亮灯，再返回<div style="height: 4px;"></div>如此重复，点亮所有灯后，大门打开，继续走到光圈处即可]],
    [8.3]=[[每次向前移动10步，然后检查脚下方块编号<div style="height: 4px;"></div>方块编号若为20号，则右转，否则则左转<div style="height: 4px;"></div>继续前进5格，再次检查脚下方块编号<div style="height: 4px;"></div>若是94号，则爬上台阶，否则则爬下台阶<div style="height: 4px;"></div>如此重复，继续走到光圈处即可]],
    [9.1]=[[仔细观察地图，运用循环走到光圈处]],
    [9.2]=[[运用循环走到光圈处<div style="height: 4px;"></div>每条路走到底，需要说出“传送”去到下一条路<div style="height: 4px;"></div>走完4条路，即可传送到光圈处<div style="height: 4px;"></div>仔细观察地图，寻找规律，运用2次循环完成任务]],
    [9.3]=[[运用循环走到光圈处<div style="height: 4px;"></div>环绕爬上楼，即可到达光圈处<div style="height: 4px;"></div>仔细观察地图，寻找规律，找出每次循环所需操作]],
    [10.1]=[[运用循环走到光圈处<div style="height: 4px;"></div>每次向前移动，然后检查脚下方块<div style="height: 4px;"></div>如果是71号，则左转，如果是134号，则右转<div style="height: 4px;"></div>其他情况则不转方向<div style="height: 4px;"></div>仔细观察地图，寻找规律，找出每次循环所需操作]],
    [10.2]=[[运用循环走到光圈处<div style="height: 4px;"></div>每次向前移动，然后检查脚下方块<div style="height: 4px;"></div>如果是20号，则做出177号动作来砍树<div style="height: 4px;"></div>如果是56号，则右转，如果是58号，则左转<div style="height: 4px;"></div>仔细观察地图，寻找规律，找出每次循环所需操作]],
    [10.3]=[[运用循环走到光圈处<div style="height: 4px;"></div>每次向前移动，然后检查脚下方块编号<div style="height: 4px;"></div>如果是20号，则做出177号动作来砍树<div style="height: 4px;"></div>如果是94号，则右转，如果是56号，则左转<div style="height: 4px;"></div>如果是19号，则跨过水坑<div style="height: 4px;"></div>仔细观察地图，寻找规律，找出每次循环所需操作]],
}

local CodeLessonTip = NPL.export()

local CodeDifficultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeDifficultView.lua") 
local CodeResultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeResultView.lua") 
local CodeLessonGoodView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonGoodView.lua") 

NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");

local page
function CodeLessonTip.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = CodeLessonTip.OnCreate
    page.OnClose = CodeLessonTip.OnClose
end

function CodeLessonTip.OnCreate()
    CodeLessonTip.RefreshSize()
    CodeLessonTip.RefreshNodeVisible()

    local node = page:FindControl("bottom_node")
    local bg_node = page:FindControl("bottom_node_bg")
    if node and node:IsValid() then
        node.width = bg_node.width
    end
end

function CodeLessonTip.OnClose()
    
    GameLogic.GetCodeGlobal():BroadcastTextEvent("CodeLessonTipVisibleChange");
    GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", CodeLessonTip.CodeWinChangeVisible, CodeLessonTip);
end

function CodeLessonTip.Report(type, lx_index, cast)
    cast = cast or "on_lesson_end"
    local report_msg = {}
    report_msg.lesson_type = "code"
    report_msg.lesson_index = math.floor(CodeLessonTip.lesson_index)
    report_msg.report_type = type
    report_msg.is_lx = lx_index or CodeLessonTip.lx_index > 0
    report_msg.step_num = 1
    report_msg.lx_index = CodeLessonTip.lx_index or 1
    report_msg.is_last_lesson = type == "program" and CodeLessonTip.lesson_config.is_last_lesson or false
    report_msg.is_last_step = true
    GameLogic.GetCodeGlobal():BroadcastTextEvent(cast, report_msg);
end

--lesson_config 课程配置
--lesson_index 第几节课
function CodeLessonTip.ShowView(lesson_config, lesson_index, is_show_lt_Bt)
    if not lesson_config or not lesson_index then
        return
    end
    CodeLessonTip.lesson_config = lesson_config
    CodeLessonTip.lesson_index = lesson_index
    CodeLessonTip.lx_index = (CodeLessonTip.lesson_index - math.floor(CodeLessonTip.lesson_index)) * 10
    CodeLessonTip.IsShowCodeWin = CodeLessonTip.IsEditorOpen()
    CodeLessonTip.ClickDifficultTimes = 0
    CodeLessonTip.IsShowLTBt = true
    if is_show_lt_Bt ~= nil then
        CodeLessonTip.IsShowLTBt = is_show_lt_Bt
    end

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.html",
        name = "CodeLessonTip.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = false,
        zorder = -13,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    -- if System.options.isDevMode then
    --     if CodeLessonTip.window then
    --         CodeLessonTip.window:destroy()
    --         CodeLessonTip.window = nil
    --     end
    -- end

	-- if(not CodeLessonTip.WindowNodeLT) then
	-- 	CodeLessonTip.WindowNodeLT = CodeLessonTip.CreateWindow();
	-- end
	-- CodeLessonTip.WindowNodeLT:Show({
	-- 	name="CodeLessonTip.ShowView", 
	-- 	url="script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTipLT.html",
    --     enable_esc_key = true,
	-- 	alignment="_lt", left=0, top=0, width = 600, height = 500, zorder = 0,
	-- });
    GameLogic.GetFilters():apply_filters("update_dock",true);
    if not CodeLessonTip.Bind then
        CodeLessonTip.Bind = true
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeLessonTip, CodeLessonTip.RefreshSize, "UniqueConnection");
    end

    CodeLessonTip.defaul_dist = GameLogic.options:GetCameraObjectDistance();
	CodeLessonTip.defaul_pitch = ParaCamera.GetAttributeObject():GetField("CameraLiftupAngle");
	CodeLessonTip.defaul_facing = ParaCamera.GetAttributeObject():GetField("CameraRotY");

    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", CodeLessonTip.CodeWinChangeVisible, CodeLessonTip, "CodeLessonTip");

    CodeLessonTip.ShowVisible(true)
    
    GameLogic.GetCodeGlobal():BroadcastTextEvent("on_lesson_start");
end

function CodeLessonTip.CodeWinChangeVisible(event)
    CodeLessonTip.IsShowCodeWin = CodeLessonTip.IsEditorOpen()
    CodeLessonTip.RefreshSize()
    CodeLessonTip.RefreshNodeVisible()
end

function CodeLessonTip.RefreshNodeVisible()
    if not page then
        return
    end

    local node = page:FindControl("bt_return")
    if node and node:IsValid() then
        if CodeLessonTip.lesson_config.return_bt_visible ~= nil then
            node.visible = CodeLessonTip.lesson_config.return_bt_visible
        else
            node.visible = not CodeLessonTip.IsShowCodeWin
        end
    end
    
    -- node = page:FindControl("bottom_node")
    -- if node and node:IsValid() then
    --     node.visible = CodeLessonTip.IsShowCodeWin == true
    -- end
end

function CodeLessonTip.IsShow()
    return page and page:IsVisible()
end

function CodeLessonTip.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

    -- local bShow = event.bShow
    local viewport = ViewportManager:GetSceneViewport();
    local view_x,view_y,view_width,view_height = viewport:GetUIRect()
    local root = ParaUI.GetUIObject("CodeLessonTipRoot");
    root.width = view_width
    root.height = view_height
end

function CodeLessonTip.GetTargetDesc()
    if CodeLessonTip.lesson_config and CodeLessonTip.lesson_config.target_desc then
        return CodeLessonTip.lesson_config.target_desc
    end
    return target_desc_list[CodeLessonTip.lesson_index] or ""
end

-- 目标介绍
function CodeLessonTip.ClickTargetIntroduce()
    GameLogic.GetCodeGlobal():BroadcastTextEvent("playCodeTargetMovice");
    if CodeLessonTip.lx_index == 0 then
        CodeLessonTip.Report("introduce", false, "CodeLessonClickReport")
    end
    
end

function CodeLessonTip.ClickRefresh()
    GameLogic.options:SetCameraObjectDistance(CodeLessonTip.defaul_dist)
    local att = ParaCamera.GetAttributeObject();
    att:SetField("CameraLiftupAngle", CodeLessonTip.defaul_pitch);
    att:SetField("CameraRotY", CodeLessonTip.defaul_facing);
end

function CodeLessonTip.ClickAdd()
    local dist = GameLogic.options:GetCameraObjectDistance();
    GameLogic.options:SetCameraObjectDistance(dist - 1)
end

function CodeLessonTip.ClickSub()
    local dist = GameLogic.options:GetCameraObjectDistance();
    GameLogic.options:SetCameraObjectDistance(dist + 1)
end

function CodeLessonTip.ExitLesson()
    if page then
        page:CloseWindow();
    end
    CodeLessonTip.CloseCodeGoodView()
    CodeLessonTip.CloseCodeDiffView()
    GameLogic.GetFilters():apply_filters("update_dock",false);
    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickCodeExit");
end
-- 点击退出
function CodeLessonTip.ClickExit()
    _guihelper.MessageBox("确定退出当前课程？",CodeLessonTip.ExitLesson)
end

-- 点击返回
function CodeLessonTip.ClickReturn()
    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickCodeReturn");
end

-- 点击思路提示
function CodeLessonTip.ClickSolutionTip()
    CodeLessonTip.cur_diff_index = 0
    CodeLessonTip.ShowVisible(false)
    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickSimPass");
    CodeLessonTip.Report("simPass", false, "CodeLessonClickReport")
end

-- 点击难点讲解
function CodeLessonTip.ClickDifficult(index)
    CodeLessonTip.ShowCodeDiffView(tonumber(index))

    CodeLessonTip.ClickDifficultTimes = CodeLessonTip.ClickDifficultTimes + 1
    if CodeLessonTip.ClickDifficultTimes >= 2 then
        CodeLessonTip.Report("cruxAnswer", false, "CodeLessonClickReport")
    end
   
end

-- 点击完整解答
function CodeLessonTip.ClickAnswer()
    CodeLessonTip.ShowCodeAnswerView()
    CodeLessonTip.Report("completeAnswer", false, "CodeLessonClickReport")
end

-- 代码编辑器是否打开
function CodeLessonTip.IsEditorOpen()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    return CodeBlockWindow.IsVisible();
end

-- 获取难点讲解数据
function CodeLessonTip.GetButtonData()
    local difficultyExplain = CodeLessonTip.lesson_config.difficultyExplain    
    return difficultyExplain or {}
end

-- 打开“太棒了”界面 代码方块中调用
function CodeLessonTip.ShowCodeGoodView()
    if not CodeLessonTip.cur_diff_index then
        return
    end
    local cur_diff_index = CodeLessonTip.cur_diff_index
    CodeLessonTip.cur_diff_index = nil
    local next_cb = function()
        CodeLessonTip.CloseCodeGoodView()
        CodeLessonTip.ShowVisible(true)
        CodeLessonTip.ShowCodeDiffView(cur_diff_index + 1)
    end

    local pass_cb = function()
        CodeLessonTip.CloseCodeGoodView()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("lessonNormalStart");
        CodeLessonTip.ShowVisible(true)
    end

    CodeLessonGoodView.ShowView(cur_diff_index, #CodeLessonTip.lesson_config.difficultyExplain, next_cb, pass_cb)
end

-- 关闭“太棒了”界面
function CodeLessonTip.CloseCodeGoodView()
    CodeLessonGoodView.CloseWindow()
end

-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowCodeDiffView(index)
    CodeLessonTip.cur_diff_index = tonumber(index)
    
    local knowledge_config = CodeLessonTip.lesson_config.knowledge_config
    if knowledge_config then
        local knowledge = knowledge_config.knowledge
        local config = knowledge[CodeLessonTip.cur_diff_index] or {}
        local content = config.content
        content = string.format("是否开始讲解难点“%s”", content)
    
        CodeDifficultView.ShowView(content,function()
            GameLogic.GetCodeGlobal():BroadcastTextEvent("clickDifficult", {diff_index=tonumber(CodeLessonTip.cur_diff_index)});
            CodeLessonTip.ShowVisible(false)
        end, root)
    end

end

-- 关闭“难点讲解”or"完整解答"确定界面
function CodeLessonTip.CloseCodeDiffView()
    CodeDifficultView.CloseWindow()
end

-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowCodeAnswerView()
    CodeLessonTip.cur_diff_index = 100
    local content = "是否开始本课的手把手教学"

    
    CodeDifficultView.ShowView(content,function()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("clickDetailAnswer");
        CodeLessonTip.ShowVisible(false)
    end, true)
end

-- 通关成功or失败界面
-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowResultView(is_success, is_new_save_way, is_return_area)
    local content = "你没通关成功，请再接再厉！"
    if is_success then
        local desc = "你已完成了第%s课(%s)"
        if CodeLessonTip.lx_index > 0 then
            local lesson_index = math.floor(CodeLessonTip.lesson_index)
            content = string.format("你已完成了第%s课练习%s", commonlib.NumberToString(lesson_index), CodeLessonTip.lx_index)
        else
            content = string.format("你已完成了第%s课(%s)", commonlib.NumberToString(CodeLessonTip.lesson_index), CodeLessonTip.lesson_config.lesson_name)
        end
        -- 上报
        CodeLessonTip.Report("program")
    end

    local left_bt_cb = function()
        --CodeLessonTip.ClickExit()
        CodeResultView.CloseWindow()
        
        --GameLogic.GetCodeGlobal():BroadcastTextEvent("startCodeLesson",{lesson_index = start_index});
        if is_success then
            if page then
                page:CloseWindow();
            end
            GameLogic.GetCodeGlobal():BroadcastTextEvent("startCodeLesson",{lesson_index = CodeLessonTip.lesson_index + 1});

        else
            GameLogic.GetCodeGlobal():BroadcastTextEvent("restartCodelesson");
        end
    end

    local right_bt_cb = function()
        CodeLessonTip.ClickExit()
        CodeResultView.CloseWindow()
    end

    local is_last_lesson = CodeLessonTip.lesson_config.is_last_lesson or CodeLessonTip.lx_index > 0
    CodeResultView.ShowView(is_success, content, left_bt_cb, right_bt_cb, is_last_lesson, is_return_area)

    if is_success then
        if not is_new_save_way then
            GameLogic.QuestAction.SetDongaoLessonState("code", CodeLessonTip.lesson_index, true)
        end
        GameLogic.GetCodeGlobal():BroadcastTextEvent("refreshCodeNpcSay");
    end
end


-- 显示or隐藏
function CodeLessonTip.ShowVisible(visible)
    if not page then
        return
    end
    local parent = page:GetParentUIObject()
    if parent then
        parent.visible = visible
        CodeLessonTip.RefreshSize()
    end

    GameLogic.GetCodeGlobal():BroadcastTextEvent("CodeLessonTipVisibleChange");
end

function CodeLessonTip.GetVisible()
    if not page then
        return false
    end

    local parent = page:GetParentUIObject()
    if parent then
        return parent.visible
    end

    return false
end

function CodeLessonTip.OnLeaveWorld()
    local titlename = GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡 Paracraft")
    if System.options.channelId_431 then
        titlename = GameLogic.GetFilters():apply_filters('GameName', L"帕拉卡智慧教育")
    end
    if System.options.isShenzhenAi5 then
        titlename = GameLogic.GetFilters():apply_filters('GameName', L"深教AI4")
    end
    local desc = GameLogic.GetFilters():apply_filters('GameDescription', L"3D动画编程创作工具")

    System.options.WindowTitle = System.options.isEducatePlatform and titlename or string.format("%s -- ver %s", titlename, GameLogic.options.GetClientVersion());
    if System.options.isEducatePlatform then
		ParaEngine.SetWindowText(System.options.WindowTitle);
	else
		ParaEngine.SetWindowText(format("%s : %s", System.options.WindowTitle, desc));
	end

    Mod.WorldShare.Store:Set('world/isShowExitPage', true)
    local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
    RedSummerCampMainPage.Show()

    Mod.WorldShare.Store:Remove('world/currentWorld')
    Mod.WorldShare.Store:Remove('world/currentEnterWorld')
    Mod.WorldShare.Store:Remove('world/isEnterWorld')
end