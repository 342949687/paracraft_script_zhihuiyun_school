--[[
    author:pbb
    date:
    Desc:
    use lib:
        local LessonBoxTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxTip.lua") 
        LessonBoxTip.ShowView()
]]

-- selection group index used to show the frame
local groupindex_hint_auto = 6;
local groupindex_wrong = 3;
local groupindex_hint = 5; -- when placeable but not matching hand block

--check_button_status
local check_width_bak = 0
local check_height_bak = 0
local ChatWindow = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatWindow");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local LessonBoxCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxCompare.lua");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");

NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local LessonBoxTip = NPL.export()

local compare_type = -1
local tip_timer
local scale_timer
local errblock_timer 
local check_timer = nil
local lockarea_timer
LessonBoxTip.CheckBLockTips={
    [5]="我已经无法形容我的心情了！你已经可以担当一名小老师了！一起进行下一步吧！",
    [4]="我的天！你简直是一个天才！事不宜迟，马上开始下一步！",
    [3]="棒极了！你是我见到过的最聪明的学生！我想你已经等不及要下一步的吧？",
    [2]="太棒了！让我们进入下一步吧！",
    [1]="很好！那么让我们立即进入下一步！",
    [-1]="唔？好像有不对的地方，让我们再做一遍吧！",
    [-2]="可惜，还是有不对的地方，再好好检查一下？",
    [-3]="呃……这个可能确实有点难，好好回忆一下我的提示，再做一遍看看？",
    [-4]="还是不太对！别灰心，这个很容易，让我们再试一次！",
    [-5]="不要放弃！距离成功已经很接近了！让我们再来一次！",
    [-6]="好吧，我承认这个确实有一点难，我带着你手把手做一次吧？",
}

LessonBoxTip.RoleAni={
    [5]={{3,"Texture/blocks/Paperman/eye/eye_boy_I_01.png"},{4,"Texture/blocks/Paperman/mouth/mouth_girl_03_01.png"}},
    [4]={{3,"Texture/blocks/Paperman/eye/eye_boy_I_01.png"},{4,"Texture/blocks/Paperman/mouth/mouth_boy_05_01.png"}},
    [3]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"},{4,"Texture/blocks/Paperman/mouth/mouth_boy_05_01.png"}},
    [2]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"},{4,"Texture/blocks/Paperman/mouth/mouth_04.png"}},
    [1]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"}},
    [-1]={{3,"Texture/blocks/Paperman/eye/eye_boy_L_01.png"}},
    [-2]={{3,"Texture/blocks/Paperman/eye/eye_boy_M_01.png"}},
    [-3]={{3,"Texture/blocks/Paperman/eye/eye_boy_R_01.png"}},
    [-4]={{3,"Texture/blocks/Paperman/eye/eye_boy_M_01.png"}},
    [-5]={{3,"Texture/blocks/Paperman/eye/eye_boy_S_01.png"}},
    [-6]={{3,"Texture/blocks/Paperman/eye/eye_boy_T_01.png"}},
}

LessonBoxTip.CheckMovieTips={
    {type = "slot",text = "没能在电影方块中找到对应的【%s】，请先检查一下是否正确添加了【%s】，或是调换了位置？"},
    {type = "timelength",text = "电影方块的时长错了，正确的时长是【%s】，请重新设定"},
    {type = "timeline",text = "没能在【%s】上找到关键帧，请再核对一下"},
}

LessonBoxTip.CompareTypeToDesc={
    ["text"] = "摄像机-文字",
    ["time"] = "摄像机-时间",
    ["cmd"] = "摄像机-命令",
    ["child_movie_block"] = "摄像机-子电影块",
    ["backmusic"] = "摄像机-背景音乐",
    ["lookat"] = "摄像机-位置",
    ["rotation"] = "摄像机-三轴旋转",
    ["parent"] = "摄像机-父链接",
    ["actor_ani"] = "角色-动作",
    ["actor_bone"] = "角色-骨骼",
    ["actor_pos"] = "角色-位置",
    ["actor_turn"] = "角色-转身",
    ["actor_rotation"] = "角色-三轴旋转",
    ["actor_scale"] = "角色-大小",
    ["actor_head"] = "角色-头部运动",
    ["actor_speed"] = "角色-运动速度",
    ["actor_model"] = "角色-模型",
    ["actor_opcatiity"] = "角色-透明度",
    ["actor_parent"] = "角色-父链接",
    ["actor_name"] = "角色-名称",
    ["weather"] = "天气",
}

LessonBoxTip.NomalTip = {
    check="仔细观察一下我这边，在绿色的格子中，摆放合适的方块吧！",
    movietarget="在电影方块中，%s",
    notfinish="像我这样，完成全部的操作吧！",
    no_change="这一步不需要改动地图，在熟悉完老师讲授的知识后，点击“开始检查”即可",
}

local VoiceType = {
    ["build"] = 10006,
    ["anim"] = 5118,
}
local checkIndex = 0
local page = nil
local page_root = nil
local lessonConfig = nil
local checkBtnType ="start"
local isFinishStage = false
LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
LessonBoxTip.m_nCreateBoxCount = 0
LessonBoxTip.m_nCurStageIndex = 0
LessonBoxTip.m_nMaxStageIndex = 0
LessonBoxTip.m_ClickFollow = false
LessonBoxTip.m_tblAllStageConfig = {}

function LessonBoxTip.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = LessonBoxTip.OnClose
    if page and page:IsVisible() then
        page_root = page:GetParentUIObject()  
    end
end

function LessonBoxTip.OnClose()
    MovieClipController.OnClose()
    MovieClipController.SetCompareData()
    GameLogic.GetCodeGlobal():BroadcastTextEvent("stopAnimRepeatMovie");
end

function LessonBoxTip.ShowView()
    local view_width = 620
    local view_height = 220
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxTip.html",
        name = "LessonBoxTip.ShowView", 
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
    if params._page then
        page = params._page
    end
    
    LessonBoxTip.UpdateCheckBtnScale()
    LessonBoxTip.RegisterEvent()
    commonlib.TimerManager.SetTimeout(function ()
        LessonBoxTip.InitTeacherPlayer()
    end, 100);
    GameLogic.GetFilters():apply_filters("update_dock",true);
    MovieClipController.OnClose()
end


function LessonBoxTip.RegisterEvent()
    GameLogic:Connect("WorldUnloaded", LessonBoxTip, LessonBoxTip.OnWorldUnload, "UniqueConnection");
    World2In1.SetIsLessonBox(true)
end

function LessonBoxTip.OnWorldUnload()
    LessonBoxTip.EndTip()
    checkIndex = 0
    page = nil
    page_root = nil
    lessonConfig = nil
    checkBtnType ="start"
    LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.m_nCurStageIndex = 0
    LessonBoxTip.m_nMaxStageIndex = 0
    LessonBoxTip.m_ClickFollow = false
    LessonBoxTip.m_tblAllStageConfig = {}
    LessonBoxTip.UnregisterHooks()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    LessonBoxTip.ClosePage()
    LessonBoxTip.StopStageMovie()
    LessonBoxTip.EndAllTimer()
    ChatWindow.is_shown = true
    isFinishStage = false
end

function LessonBoxTip.InitTeacherPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("teacher_role")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                player:SetScale(1)
                player:SetFacing(1.57);
                player:SetField("HeadUpdownAngle", 0.3);
                player:SetField("HeadTurningAngle", 0);

                local file = ""
                if lessonConfig.teacher_asset_file then
                    file = lessonConfig.teacher_asset_file or ""
                else
                    file = "character/CC/02human/paperman/principal.x"
                    if lessonConfig.lesson_type == "anim" then
                        file = "character/CC/02human/paperman/Female_teachers.x"
                    end
                end
                player:SetField("assetfile",file)
            end
        end
    end
end

local reset_timer = nil
function LessonBoxTip.PlayRoleAni(index)
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("teacher_role")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            local aniConfig = LessonBoxTip.RoleAni[index]
            if aniConfig then
                for i=1,#aniConfig do
                    local cur = aniConfig[i]
                    player:SetReplaceableTexture(cur[1],ParaAsset.LoadTexture("",cur[2],1))
                end
            end
            if(reset_timer) then
                reset_timer:Change();
            end
            reset_timer = commonlib.TimerManager.SetTimeout(function ()
                player:SetReplaceableTexture(3,player:GetDefaultReplaceableTexture(3))
                player:SetReplaceableTexture(4,player:GetDefaultReplaceableTexture(4))
            end, 1500);
        end
    end
end

function LessonBoxTip.AddOperateCount(count)
    if type(count) == "number" then
        LessonBoxTip.m_nCreateBoxCount = LessonBoxTip.m_nCreateBoxCount + count
        return 
    end
    LessonBoxTip.m_nCreateBoxCount = LessonBoxTip.m_nCreateBoxCount + 1
end
--/select 18870,13,19151(-19,1,-19)
function LessonBoxTip.InitLessonConfig(config, is_only_init)
    if config then
        lessonConfig = commonlib.copy(config)
        LessonBoxTip.is_pass_lesson = config.is_pass_lesson
        --echo(config,true)
        LessonBoxTip.InitLessonData()
        LessonBoxTip.m_nMaxStageIndex = #lessonConfig.taskCnf
        LessonBoxTip.m_nCurStageIndex = LessonBoxTip.m_nCurStageIndex + 1

        local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
        if taskCnf.templateteacher then
            lessonConfig.templateteacher = taskCnf.templateteacher
        end

        if taskCnf.templatemy then
            lessonConfig.templatemy = taskCnf.templatemy
        end

        if taskCnf.regionMy then
            lessonConfig.regionMy = taskCnf.regionMy
        end

        if taskCnf.regionOther then
            lessonConfig.regionOther = taskCnf.regionOther
        end
        
        -- echo(lessonConfig.taskCnf,true)
        -- print("maxstage============",LessonBoxTip.m_nMaxStageIndex,#lessonConfig.taskCnf)
        LessonBoxTip.PrepareStageScene(is_only_init)
    end
end

function LessonBoxTip.ClearLearnArea(area)
    if not area or not area.pos or not area.size then
        return 
    end
    GameLogic.RunCommand(string.format("/select %d,%d,%d (%d %d %d)",area.pos[1],area.pos[2],area.pos[3],area.size[1],area.size[2],area.size[3]))
    GameLogic.RunCommand("/del")
    GameLogic.RunCommand("/select -clear")
end

local Isprepare = false
local isStopMovieBySelf = false
--18663,12,19336(49,1,20)
function LessonBoxTip.PrepareStageScene(is_only_init)
    if not lessonConfig then
        GameLogic.AddBBS(nil,"课程初始化失败")
        return 
    end
    Isprepare = true
    isFinishStage = false
    isStopMovieBySelf = false
    LessonBoxTip.EndTip()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local moivePos = taskCnf.moviePos

    local stagePos = lessonConfig.teachStage
    if stagePos[1] and moivePos[1] then
        GameLogic.GetPlayer():MountEntity(nil);
        GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
    end
    local lookPos = lessonConfig.lookPos
    if lookPos then
        GameLogic.RunCommand(string.format("/lookat %d,%d,%d",lookPos[1],lookPos[2],lookPos[3]))
    end
    LessonBoxTip.PlayLessonMusic("lesson")
    ChatWindow.is_shown = false
    -- print("runcommand showMask===============start")
    GameLogic.RunCommand("/sendevent showMask")
    -- print("runcommand showMask===============end")

    -- if moivePos[1] then

    -- end 
    if not is_only_init then
        GameLogic.RunCommand("/sendevent hideNpc")
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playstagemovie", {config = taskCnf});
        GameLogic.RunCommand("/ggs user hidden");
    end
end


function LessonBoxTip.StopStageMovie()
    isStopMovieBySelf = true
    GameLogic.GetCodeGlobal():BroadcastTextEvent("stopStageMovie");
end

function LessonBoxTip.StartCurStage()
    -- print("StartCurStage=============== 18692,13,19355")
    if isStopMovieBySelf then
        isStopMovieBySelf = false
        -- print("cccccccccccccccc")
        return 
    end
    local taskArea = lessonConfig.stageArea
    local posTeacher = lessonConfig.templateteacher
    local posMy = lessonConfig.templatemy
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    -- print("clear start")
    if taskArea then
        LessonBoxTip.ClearLearnArea(taskArea)
    end
    
    -- print("clear end")
    LessonBoxTip.ShowView()
    commonlib.TimerManager.SetTimeout(function()
        Isprepare = false
        local endTemp = taskCnf.finishtemplate
        local startTemp = taskCnf.starttemplate
        -- print("temp========",endTemp,startTemp)
        -- print(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        -- print(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        -- echo(lessonConfig,true)
        GameLogic.RunCommand("/clearbag")
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        local stagePos = lessonConfig.myStage
        if lessonConfig.is_lx and lessonConfig.myLxStage then
            stagePos = lessonConfig.myLxStage
        end

        if stagePos[1] then
            GameLogic.GetPlayer():MountEntity(nil);
            GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
            --GameLogic.RunCommand("/camerayaw 1.57")
            commonlib.TimerManager.SetTimeout(function()
                if stagePos[1] then
                    GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
                end
            end,500)
        end
        LessonBoxTip.PlayLessonMusic("lesson_operate")
        LessonBoxTip.StartTip()
        LessonBoxTip.StartLearn()
    end,300)
end

function LessonBoxTip.ResetMyArea()
    if not lessonConfig then
        return 
    end
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local startTemp = taskCnf.starttemplate
    local posMy = lessonConfig.templatemy
    local regionsrc = lessonConfig.regionMy
    LessonBoxTip.ClearLearnArea(regionsrc)

    if lessonConfig.lesson_type == "anim" then
        MovieClipController.SetIsShowCompareError(false)
        MovieClipController.SetCompareErrorBg()
    end
    commonlib.TimerManager.SetTimeout(function()
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.AddBBS("resetArea","区域已恢复到初始状态")
        LessonBoxTip.RenderBlockTip()

        if lessonConfig.lesson_type == "anim" then
            local entity_answer = EntityManager.GetBlockEntity(posMy[1], posMy[2], posMy[3])
            if entity_answer then
                movice_clip = entity_answer:GetMovieClip();
                -- 激活电影以对比
                if not MovieClipController.IsVisible() then
                    MovieManager:SetActiveMovieClip(movice_clip);
                    MovieManager:SetActiveMovieClip(nil);
                end
            end

        end

    end,500)
end

function LessonBoxTip.ResetTeacherArea()
    if not lessonConfig then
        return 
    end
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local finishtemplate = taskCnf.finishtemplate
    local templateteacher = lessonConfig.templateteacher
    local regionOther = lessonConfig.regionOther
    LessonBoxTip.ClearLearnArea(regionOther)

    commonlib.TimerManager.SetTimeout(function()
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",templateteacher[1],templateteacher[2],templateteacher[3],finishtemplate))
        LessonBoxTip.RenderBlockTip()

        if lessonConfig.lesson_type == "anim" then
            local entity = EntityManager.GetBlockEntity(templateteacher[1], templateteacher[2], templateteacher[3])
            if entity then
                local movice_clip = entity:GetMovieClip();
                -- 激活电影以对比
                if not MovieClipController.IsVisible() then
                    MovieManager:SetActiveMovieClip(movice_clip);
                    MovieManager:SetActiveMovieClip(nil);
                end
            end

        end
    end,200)
end

function LessonBoxTip.InitLessonData()
    checkIndex = 0
    checkBtnType ="start"
    LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.CreatePos = nil
    LessonBoxTip.SrcBlockOrigin = nil
    LessonBoxTip.m_nCurStageIndex = 0
    LessonBoxTip.m_nMaxStageIndex = 0
end

function LessonBoxTip.RegisterHooks()
	GameLogic.events:AddEventListener("CreateBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.events:AddEventListener("CreateDiffIdBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.events:AddEventListener("DestroyBlockTask", LessonBoxTip.OnDestroyBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.GetFilters():add_filter("BatchModifyBlocks",function(blocks, is_delete)
        -- echo(commonlib.debugstack(),true)
        -- print("block num changes============",blocks and #blocks or 0)
        -- echo(blocks)
        if type(blocks) == "number" then
            LessonBoxTip.AddOperateCount(blocks)
        elseif type(blocks) == "table" then
            LessonBoxTip.AddOperateCount(#blocks)
        end
        
        return blocks, is_delete
    end)
end

function LessonBoxTip.UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip);
    GameLogic.events:RemoveEventListener("CreateDiffIdBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip);
    GameLogic.events:RemoveEventListener("DestroyBlockTask", LessonBoxTip.OnDestroyBlockTask, LessonBoxTip);
    GameLogic.GetFilters():remove_filter("BatchModifyBlocks", function() end);
    LessonBoxTip.EndTip()
end

function LessonBoxTip.OnDestroyBlockTask(self,event)
    -- print("OnCreateBlockTask=================1'")
    --echo(self,true)
    -- echo(event,true)
	if(event.x) then
        LessonBoxTip.AddOperateCount()
        local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
		local x, y, z = unpack(startPos);
		x, y, z = event.x - x, event.y -y, event.z-z;
        -- echo(startPos)
        -- echo(LessonBoxTip.CreatePos)
		local block = LessonBoxTip.FindBlock(x, y, z);
        -- echo(block and block[4] > 6)
		if(block) then --and block[4] == event.block_id
            LessonBoxTip.FinishBlock(x, y, z)
		end
	end
end

function LessonBoxTip.OnCreateBlockTask(self,event)
    -- print("OnCreateBlockTask=================1'")
    --echo(self,true)
    -- echo(event,true)
	if(event.x) then
        LessonBoxTip.AddOperateCount()
        local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
		local x, y, z = unpack(startPos);
		x, y, z = event.x - x, event.y -y, event.z-z;
        -- echo(startPos)
        -- echo(LessonBoxTip.CreatePos)
		local block = LessonBoxTip.FindBlock(x, y, z);
        -- echo(block and block[4] > 6)
		if(block) then --and block[4] == event.block_id
            LessonBoxTip.FinishBlock(x, y, z)
		end
	end
end

function LessonBoxTip.UpdateCreateResult()

end



function LessonBoxTip.StartLearn()
    -- print("StartLearn=================")
    if LessonBoxCompare and lessonConfig then
        LessonBoxTip.CompareMovieResult = nil
        -- GameLogic.RunCommand(string.format("/loadtemplate 18873,12,19156 %s",lessonConfig.starttemplate))
        local regionsrc = lessonConfig.regionMy
        local regiondest = lessonConfig.regionOther
        -- print("StartLearn=================1")
        --echo({regionsrc,regiondest})
        local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
        if taskCnf and taskCnf.starttemplate == taskCnf.finishtemplate then
            LessonBoxTip.SetTaskTip("no_change")
            LessonBoxTip.SetRoleName()
            LessonBoxTip.SetLessonTitle()
        else
            -- print("bbbbbbbbbbbbbbb", lessonConfig.lesson_type)
            if lessonConfig.lesson_type == "anim" and lessonConfig.course_index ~= 1 then
                if not LessonBoxCompare.BindAnimLessonFilter then
                    LessonBoxCompare.BindAnimLessonFilter = true
                    GameLogic.GetFilters():add_filter("OpenMovieClipController", LessonBoxTip.OpenMovieClipController);
                    GameLogic.GetFilters():add_filter("OnClickCloseMovieClip", LessonBoxTip.OnClickCloseMovieClip);
                end
                
                -- 比较电影
                LessonBoxCompare.CompareAnimLesson(regionsrc, regiondest)
            else
                LessonBoxCompare.CompareBulidLesson(regionsrc,regiondest)
            end
        end

        commonlib.TimerManager.SetTimeout(function()
            -- 播放重复电影 弱提示 
            GameLogic.GetCodeGlobal():BroadcastTextEvent("playAnimRepeatMovie");
        end,200)
    end
end

-- regiondest 标准答案
-- regionsrc 自己
function LessonBoxCompare.CompareAnimLesson(regiondest, regionsrc)

    local my_movice_pos = regiondest.pos
    local entity_my = EntityManager.GetBlockEntity(my_movice_pos[1], my_movice_pos[2], my_movice_pos[3])
    if not entity_my then
        return
    end
    local movice_clip = entity_my:GetMovieClip();
    -- 激活电影以对比
    if not MovieClipController.IsVisible() then
        MovieManager:SetActiveMovieClip(movice_clip);
        MovieManager:SetActiveMovieClip(nil);
    end


    local answer_movice_pos = regionsrc.pos
    local entity_answer = EntityManager.GetBlockEntity(answer_movice_pos[1], answer_movice_pos[2], answer_movice_pos[3])
    if entity_answer then
        movice_clip = entity_answer:GetMovieClip();
        -- 激活电影以对比
        if not MovieClipController.IsVisible() then
            MovieManager:SetActiveMovieClip(movice_clip);
            MovieManager:SetActiveMovieClip(nil);
        end
    end


    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex] or {}
    local result_list = LessonBoxCompare.CompareMovieAll(entity_answer, entity_my, taskCnf.teach_point)

    -- print("rrrrrrrrrrrrrrrrrrrrrrresult_list")
    -- echo(result_list, true)
    LessonBoxTip.CompareMovieResult = result_list
    MovieClipController.SetCompareData(result_list)
    MovieClipController:OnMovieClipRemotelyUpdated()

    LessonBoxTip.SetLessonTitle()
    local str = lessonConfig.teacher_say or ""
    -- local str = string.format(LessonBoxTip.NomalTip.movietarget, lesson_desc)
    LessonBoxTip.SetTaskTip(nil, str)
    LessonBoxTip.SetRoleName()
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.RenderBlockTip()
end

-- 建造课比较
function LessonBoxCompare.CompareBulidLesson(regionsrc,regiondest)
    LessonBoxCompare.CompareTwoAreas(regionsrc,regiondest,function(needbuild,pivotConfig)
        --echo(needbuild)
        LessonBoxTip.AllNeedBuildBlock = needbuild.blocks
        LessonBoxTip.CurNeedBuildBlock = needbuild.blocks
        LessonBoxTip.CreatePos = pivotConfig.createpos
        LessonBoxTip.SrcBlockOrigin = pivotConfig.srcPivot
        LessonBoxTip.SetLessonTitle()
        compare_type = needbuild.nAddType
        if(#needbuild.blocks == 0 and needbuild.nAddType == 3)then
            local movieBlocks = needbuild.movies
            local codeBlocks = needbuild.codes
            LessonBoxTip.CompareCode(codeBlocks)
        else
            -- LessonBoxTip.AutoEquipHandTools()
            LessonBoxTip.RegisterHooks()
            commonlib.TimerManager.SetTimeout(function()
                LessonBoxTip.SetTaskTip("check")
                LessonBoxTip.SetRoleName()
                LessonBoxTip.UpdateNextBtnStatus()
                LessonBoxTip.RenderBlockTip()
            end,200)
        end
    end)
end

function LessonBoxTip.CompareCode(blocks)
    if type(blocks) == "table" then
        if #blocks == 0 then
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
            GameLogic.AddBBS(nil,"当前小节已完成，你可以点击检查进入下一小节")
            commonlib.TimerManager.SetTimeout(function()
                LessonBoxTip.ClearErrorBlockTip()
                LessonBoxTip.RemoveErrBlockTip()
                LessonBoxTip.ClearBlockTip()
                -- LessonBoxTip.GotoNextStage()
                
            end,1000)
        else
            for i=1,#blocks do
                local possrc,posdest = LessonBoxTip.AddTwoPosition(blocks[i][1],LessonBoxTip.CreatePos),LessonBoxTip.AddTwoPosition(blocks[i][2],LessonBoxTip.SrcBlockOrigin)
                local entitySrc = EntityManager.GetBlockEntity(possrc)
                local entityDest = EntityManager.GetBlockEntity(posdest)
                local bSame,nType = LessonBoxCompare.CompareCode(entitySrc,entityDest)
                if not bSame then
                    
                    break
                end
            end
        end
    end
end

function LessonBoxTip.AddTwoPosition(pos1,pos2)
    if not pos1 or not pos2 then
        return 
    end
    local newPos = {}
    newPos = {pos1[1]+pos2[1],pos1[2]+pos2[2],pos1[3]+pos2[3]}
    return newPos
end

function LessonBoxTip.RenderBlockTip()
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.CurNeedBuildBlock do
        local block = LessonBoxTip.CurNeedBuildBlock[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint_auto);
        -- print("pos=========",x,y,z)
    end
end

function LessonBoxTip.ClearBlockTip()
    if not lessonConfig then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do 
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_auto);
        -- print("ClearBlockTip===========")
    end
end

function LessonBoxTip.RenderErrorBlockTip()
    --clear
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.NeedChangeBlocks do 
        local block = LessonBoxTip.NeedChangeBlocks[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
    end
    --set
    local block = LessonBoxTip.NeedChangeBlocks[checkIndex]
    if block then
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, true, groupindex_wrong);
        LessonBoxTip.UpdateErrArrow({block[1],block[2],block[3]})
    end    
end

function LessonBoxTip.UpdateErrArrow(pos)
    if not pos or not LessonBoxTip.CreatePos or not LessonBoxTip.CreatePos[1] or not LessonBoxTip.SrcBlockOrigin[1] then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    local leftPos = {startPos[1]+pos[1],startPos[2]+pos[2],startPos[3]+pos[3]}
    startPos = LessonBoxTip.SrcBlockOrigin and LessonBoxTip.SrcBlockOrigin or lessonConfig.regionOther.pos
    local rightPos = {startPos[1]+pos[1],startPos[2]+pos[2],startPos[3]+pos[3]}
    GameLogic.GetCodeGlobal():BroadcastTextEvent("showArrow", {leftpos=leftPos,rightpos = rightPos});
end

function LessonBoxTip.ClearErrorBlockTip()
    if not lessonConfig then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.NeedChangeBlocks do 
        local block = LessonBoxTip.NeedChangeBlocks[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
    end
    GameLogic.RunCommand("/sendevent hideArrow")
end

function LessonBoxTip.FindBlock(x, y, z)
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        if block[1] == x and block[2] == y and block[3] == z then
            return block
        end
    end
end

function LessonBoxTip.FinishBlock(x, y, z)
    for i = 1,#LessonBoxTip.CurNeedBuildBlock do
        local block = LessonBoxTip.CurNeedBuildBlock[i]
        if block[1] == x and block[2] == y and block[3] == z then
            block.finish = true
        end
    end
end

function LessonBoxTip.CheckFinishAll()
    local curOperateNum = LessonBoxTip.m_nCreateBoxCount
    -- print("num=============",LessonBoxTip.m_nCreateBoxCount,#LessonBoxTip.CurNeedBuildBlock)
    if curOperateNum >= #LessonBoxTip.CurNeedBuildBlock then
        return true
    end
    return false
    -- local isFinish = true
    -- for i = 1,#LessonBoxTip.CurNeedBuildBlock do
    --     local block = LessonBoxTip.CurNeedBuildBlock[i]
    --     if not block.finish then
    --         isFinish = false
    --         break
    --     end
    -- end
    -- return isFinish
end

function LessonBoxTip.AutoEquipHandTools()
    if not lessonConfig then
        return 
    end
    local part = {}
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        if block and block[4] then
            part[block[4]] = block[4]
        end
    end
    local temp = {}
    for k,v in pairs(part) do
        temp[#temp + 1] = v
    end
    -- echo(temp)

    local player = EntityManager.GetPlayer();
    local count = #temp

    for idx =1, 9 do
        if(idx<=count) then
            player.inventory:SetItemByBagPos(idx, temp[idx]);
            -- print("SetItemByBagPos",idx,temp[idx])
        else
            player.inventory:SetItemByBagPos(idx, 0);
        end
    end
    player.inventory:SetHandToolIndex(1);    
end




function LessonBoxTip.SetRoleName()
    if page and lessonConfig then
        local name = lessonConfig.teacherName or "校长" 
        -- print("SetRoleName===",name)
        page:SetValue("role_name", name);
        
    end
end

function LessonBoxTip.SetTaskTip(type, text)
    if page then
        local strTip = text or LessonBoxTip.NomalTip[type]
        page:SetValue("role_tip", strTip);
        if strTip then
            LessonBoxTip.PlayTextByTeacher(strTip)
        end
    end
end

function LessonBoxTip.SetErrorTip(index)
    if page then
        index = index or 1
        local strTip = str or LessonBoxTip.CheckBLockTips[index]
        page:SetValue("role_tip", strTip);
        if strTip then
            LessonBoxTip.PlayRoleAni(index)
            LessonBoxTip.PlayTextByTeacher(strTip)
        end
    end
end

function LessonBoxTip.SetLessonTitle()
    if lessonConfig and page then
        local curStage = LessonBoxTip.m_nCurStageIndex
        local taskCnf = lessonConfig.taskCnf[curStage]
        local strTitle = string.format("%s步骤%d-%s",lessonConfig.stageTitle,lessonConfig.learnIndex,taskCnf.name) 
        page:SetValue("lesson_title", strTitle);
    end
end

function LessonBoxTip.ReplayMovie()
    if LessonBoxTip.CheckHasePlayMovie() or Isprepare == true then
        GameLogic.AddBBS(nil,"当前正在播放其他的动画或动画没有准备好,请稍后")
        return
    end
    LessonBoxTip.EndTip()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local moivePos = taskCnf.moviePos
    if moivePos[1] then
        LessonBoxTip.ClosePage() 
        local stagePos = lessonConfig.teachStage
        if stagePos[1] then
            GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
        end
        local lookPos = lessonConfig.lookPos
        if lookPos then
            GameLogic.RunCommand(string.format("/lookat %d,%d,%d",lookPos[1],lookPos[2],lookPos[3]))
        end
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playstagemovie", {config = taskCnf,isOnlyPlay = true, isInLesson=true});
    end
end

--请按照园长的讲解，在自己的区域也练习一遍吧！
function LessonBoxTip.ResumeLessonUI()
    
    LessonBoxTip.ShowView()
    LessonBoxTip.SetLessonTitle()
    LessonBoxTip.SetTaskTip("check")
    LessonBoxTip.SetRoleName()
    LessonBoxTip.UpdateNextBtnStatus()
    GameLogic.RunCommand("/sendevent showNpc")
    GameLogic.RunCommand("/sendevent showMask")
    local stagePos = lessonConfig.myStage
    if lessonConfig.is_lx and lessonConfig.myLxStage then
        stagePos = lessonConfig.myLxStage
    end
    if stagePos[1] then
        GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
    end
    GameLogic.RunCommand("/tip")
    LessonBoxTip.StartTip()
    commonlib.TimerManager.SetTimeout(function()
        LessonBoxTip.RenderBlockTip()
    end,200)
    commonlib.TimerManager.SetTimeout(function()
        if stagePos[1] then
            GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
        end

        if lessonConfig.lesson_type == "anim" and lessonConfig.course_index ~= 1 then
            local regionsrc = lessonConfig.regionMy
            local regiondest = lessonConfig.regionOther
            LessonBoxCompare.CompareAnimLesson(regionsrc, regiondest)
        end
    end,500)
end

function LessonBoxTip.StartTip(strType)
    tip_timer = tip_timer or commonlib.Timer:new({callbackFunc = function(timer)
		GameLogic.AddBBS(nil,"请按照讲解练习一遍吧，练习好后点击按钮【开始检查】查看结果！",3000)
	end})
	tip_timer:Change(0, 10000);
end

function LessonBoxTip.EndTip()
    if tip_timer then
        tip_timer:Change()
    end
end

function LessonBoxTip.CheckHaseNextErr(nDis)
    if LessonBoxTip.NeedChangeBlocks[checkIndex + nDis] ~= nil then
        return true
    end
    return false
end

function LessonBoxTip.ClosePage() 
    if page then
        page:CloseWindow()
        page = nil
    end
    if errblock_timer then
        errblock_timer:Change()
        errblock_timer = nil
    end
    if scale_timer then
        scale_timer:Change()
        scale_timer = nil
        check_width_bak = 0
        check_height_bak = 0
    end
end

function LessonBoxTip.IsCompareAutoBlock()
    local blocks = LessonBoxTip.AllNeedBuildBlock
    if blocks and #blocks > 0 then
        for i=1,#blocks do
            if blocks[i][4] == 267 or blocks[i][4] == 103  then
                return true
            end
        end
    end
    return false
end

function LessonBoxTip.IsShowFollowBt()
    if not lessonConfig then
        return false
    end
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if taskCnf and taskCnf.follow and taskCnf.follow[1] then
        return true
    end

    return false
end

function LessonBoxTip.IsShowMoviceBt()
    if not lessonConfig then
        return false
    end
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if taskCnf and taskCnf.moviePos and taskCnf.moviePos[1] then
        return true
    end

    return false
end

function LessonBoxTip.StartCheck()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if (taskCnf and taskCnf.starttemplate == taskCnf.finishtemplate) or LessonBoxTip.is_pass_lesson then
        LessonBoxTip.RemoveErrBlockTip()
        LessonBoxTip.SetErrorTip(1)
        isFinishStage = true
        GameLogic.AddBBS(nil,"当前小节已完成，即将进入下一小节的学习")
        commonlib.TimerManager.SetTimeout(function()
            LessonBoxTip.ClearErrorBlockTip()
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.ClearBlockTip()
            LessonBoxTip.GotoNextStage()
        end,4000)

        return
    end

    if check_timer then
        check_timer:Change()
    end   
    check_timer = commonlib.TimerManager.SetTimeout(function()
        if lessonConfig.lesson_type == "anim" and lessonConfig.course_index ~= 1 then
            LessonBoxTip.StartCheckAnim()
            return
        end

        if LessonBoxTip.CheckHasePlayMovie() then
            GameLogic.AddBBS(nil,"先去老师区域，看完操作演示吧")
            return
        end
        if isFinishStage then
            GameLogic.AddBBS(nil,"当前小节已经完成了，正在跳转下一小节，请等待")
            return
        end
        if not LessonBoxTip.CheckFinishAll() and not LessonBoxTip.IsCompareAutoBlock() then
            if compare_type == 1  or compare_type == 3 then
                LessonBoxTip.RemoveErrBlockTip()
                LessonBoxTip.SetTaskTip("notfinish")
                compare_type = -1
                return 
            end
        end
        checkBtnType = "stop"
        LessonBoxTip.UpdateCheckBtnStatus(checkBtnType)
        LessonBoxTip.ClearBlockTip()
        LessonBoxTip.ClearErrorBlockTip()
        if LessonBoxCompare and lessonConfig then
            local regionsrc = lessonConfig.regionMy
            local regiondest = lessonConfig.regionOther
            LessonBoxCompare.CompareTwoAreas(regionsrc,regiondest,function(needbuild,pivot)
                -- echo(needbuild,true)
                local isCorrect = false
                local blocks = needbuild.blocks
                if needbuild.nAddType ~= 3 then
                    -- LessonBoxTip.m_nCorrectCount = 0
                    LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount - 1
                    LessonBoxTip.NeedChangeBlocks = blocks
                    checkIndex = 1
                    LessonBoxTip.RenderErrorBlockTip()
                    LessonBoxTip.UpdateNextBtnStatus()
                else
                    if #blocks == 0 then
                        if LessonBoxTip.m_nCorrectCount < 0 then
                            LessonBoxTip.m_nCorrectCount = 0
                        end
                        isCorrect = true
                        LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount + 1
                    else
                        if LessonBoxTip.m_nCorrectCount > 0 then
                            LessonBoxTip.m_nCorrectCount = 0
                        end
                        LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount - 1
                        LessonBoxTip.NeedChangeBlocks = blocks
                        checkIndex = 1
                        LessonBoxTip.RenderErrorBlockTip()
                        LessonBoxTip.UpdateNextBtnStatus()
                    end
                end
                if isCorrect then
                    LessonBoxTip.RemoveErrBlockTip()
                    LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
                    isFinishStage = true
                    local finish_desc = lessonConfig.is_lx and "当前练习已完成" or "当前小节已完成，即将进入下一小节的学习"
                    GameLogic.AddBBS(nil,finish_desc)
                    commonlib.TimerManager.SetTimeout(function()
                        LessonBoxTip.ClearErrorBlockTip()
                        LessonBoxTip.RemoveErrBlockTip()
                        LessonBoxTip.ClearBlockTip()
                        if lessonConfig.is_lx then
                            LessonBoxTip.OnRetunMacro(true)
                        else
                            LessonBoxTip.GotoNextStage()
                        end
                        
                    end,5000)
                    return
                end
                if LessonBoxTip.m_nCorrectCount <= -5 then
                    if taskCnf.follow and taskCnf.follow[1] then
                        _guihelper.MessageBox("开启教学模式，跟着帕帕卡卡拉拉一起手把手一步一步完成课程的学习吧！",function()
                            LessonBoxTip.OnStartMacroLearn()
                        end)
                    end

                    if lessonConfig.is_lx then
                        LessonBoxTip.m_nCorrectCount = -5
                    end
                end
                if LessonBoxTip.m_nCorrectCount < - 6 then LessonBoxTip.m_nCorrectCount = -6  end
                if LessonBoxTip.m_nCorrectCount > 5 then LessonBoxTip.m_nCorrectCount = 5 end
                if LessonBoxTip.m_nCorrectCount <=5 and LessonBoxTip.m_nCorrectCount >= -6 then
                    LessonBoxTip.RemoveErrBlockTip()
                    LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
                    LessonBoxTip.DelayShowErrBlockTip()
                    
                end
            end)
        end
    end,500)
end


function LessonBoxTip.DelayShowErrBlockTip()
    if errblock_timer then
        errblock_timer:Change();
    end
    errblock_timer = commonlib.TimerManager.SetTimeout(function ()
        if lessonConfig.lesson_type == "anim" then
            LessonBoxTip.SetAnimErrorTip()
        else
            LessonBoxTip.SetErrBlockTip()
        end
        
    end, 3000);
end
function LessonBoxTip.UpdateCheckBtnStatus(type)
    if type == "stop" then
        local back1 = "Texture/Aries/Creator/keepwork/macro/lessonbox/btn_sc_128X47_32bits.png;0 0 128 47"
        local back2 = "Texture/Aries/Creator/keepwork/macro/lessonbox/btn_sc1_128X47_32bits.png;0 0 128 47"
        
        local btnObject = ParaUI.GetUIObject("lesson_check_button")
        if (btnObject) then
            btnObject.background = back2
            commonlib.TimerManager.SetTimeout(function()
                btnObject.background = back1
            end,1000)
        end
    end
end

-- @param maxScaling: default to 0.9. usually between [0.8, 1.2]
function LessonBoxTip.UpdateCheckBtnScale(maxScaling)
    local btnObject = ParaUI.GetUIObject("lesson_check_button")
    if (btnObject and btnObject:IsValid()) then
		maxScaling = maxScaling or 0.9;
		local curScaling = 1;
		local scale_state = "add"
		local scaleStep = math.abs(maxScaling - 1) / 20;
		local maxScale = math.max(1, maxScaling)
		local minScale = math.min(1, maxScaling)
        scale_timer = commonlib.Timer:new({callbackFunc = function(timer)
            if scale_state == "add" then
                curScaling = curScaling + scaleStep
				if(curScaling > maxScale) then
					curScaling = maxScale;
					scale_state = "reduce"
				end
            elseif scale_state == "reduce" then
				curScaling = curScaling - scaleStep
				if(curScaling < minScale) then
					curScaling = minScale;
					scale_state = "add"
				end
            end
			btnObject.scalingx = curScaling
			btnObject.scalingy = curScaling
        end})
        scale_timer:Change(0, 30);
    end
end

function LessonBoxTip.UpdateNextBtnStatus()
    local btnNextObject = ParaUI.GetUIObject("lesson_next_button")
    local btnPreObject = ParaUI.GetUIObject("lesson_pre_button")
    btnNextObject.visible = false
    if LessonBoxTip.CheckHaseNextErr(1) then
        btnNextObject.visible = true
    end
    btnPreObject.visible = false
    if LessonBoxTip.CheckHaseNextErr(-1) then
        btnPreObject.visible = true
    end
end

function LessonBoxTip.StopCheck()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    checkIndex = 0
    LessonBoxTip.NeedChangeBlocks = {}
    LessonBoxTip.UpdateNextBtnStatus()
end

function LessonBoxTip.OnClickPre()
    if not LessonBoxTip.CheckHaseNextErr(-1) then
        GameLogic.AddBBS(nil,"没有更多的错误方块了")
        return 
    end
    checkIndex = checkIndex - 1
    LessonBoxTip.RenderErrorBlockTip()
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.SetErrBlockTip()
end

function LessonBoxTip.OnClickNext()
    if not LessonBoxTip.CheckHaseNextErr(1) then
        GameLogic.AddBBS(nil,"没有更多的错误方块了")
        return 
    end
    checkIndex = checkIndex + 1
    LessonBoxTip.RenderErrorBlockTip()
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.SetErrBlockTip()
end

--[[红色方框中的方块错了，正确的应该是【iocn】【方块名称】（编号：【方块编号】）。]]
function LessonBoxTip.SetErrBlockTip()
    if not page or not page_root or not page:IsVisible() then
        print("界面初始化失败~")
        return
    end
    local posSrc = LessonBoxTip.SrcBlockOrigin
    local block = LessonBoxTip.NeedChangeBlocks[checkIndex]
    local startPos = posSrc or lessonConfig.regionOther.pos
    local myRegionPos = LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    if block then
        if page then
            page:SetValue("role_tip", "");
        end
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        -- 我模板中的方块位置
        local my_block_x,my_block_y,my_block_z = myRegionPos[1]+block[1],myRegionPos[2]+block[2],myRegionPos[3]+block[3]
        local blockId,blockData = BlockEngine:GetBlockIdAndData(x,y,z)
        local myblockId,myblockData = BlockEngine:GetBlockIdAndData(my_block_x,my_block_y,my_block_z)

        -- print("blockId========",blockId,type(blockId),x,y,z)
        local block_item = ItemClient.GetItem(blockId);
        if blockId == 0 or block_item == nil or blockId == myblockId then
            -- GameLogic.RunCommand(string.format("/goto %d %d %d",x,y,z))
            local strErrTip = string.format("红色方框里面不应该有方块，请将其清除。")
            if blockId ~= 0 and blockId == myblockId then
                strErrTip = "红色方框中的方块是正确的，但是它的颜色、方向或者状态不对，请仔细观察并调整"
            end
            
            LessonBoxTip.PlayTextByTeacher(strErrTip)
            local txtErrTip = ParaUI.GetUIObject("lessonbox_err_text")
            if not txtErrTip:IsValid() then
                txtErrTip = ParaUI.CreateUIObject("text", "lessonbox_err_text", "_lt", 240, 70, 330, 100);
                page_root:AddChild(txtErrTip)
            end
            txtErrTip.zorder = 3
            txtErrTip.font = "System;16;normal";
            txtErrTip.text = strErrTip;

            local imgBlock = ParaUI.GetUIObject("lessonbox_err_block")
            if imgBlock and imgBlock:IsValid() then
                ParaUI.Destroy("lessonbox_err_block")
            end
            return
        end
        local background = block_item:GetIcon(blockData):gsub("#", ";");
        local name = block_item:GetStatName()
        --print("block=========",name,background,tooltip)
        -- 电灯特殊处理
        if blockId == 207 then
            blockId = 199
        end

        local strErrTip = string.format("红色方框中的方块错了，正确的应该是【     】【%s】（编号：【%d】）。",name,blockId)
        LessonBoxTip.PlayTextByTeacher(strErrTip)
        local txtErrTip = ParaUI.GetUIObject("lessonbox_err_text")
        if not txtErrTip:IsValid() then
            txtErrTip = ParaUI.CreateUIObject("text", "lessonbox_err_text", "_lt", 240, 70, 330, 100);
            page_root:AddChild(txtErrTip)
        end
        txtErrTip.zorder = 3
        txtErrTip.font = "System;16;normal";
        txtErrTip.text = strErrTip;
        

        if background then
            local imgBlock = ParaUI.GetUIObject("lessonbox_err_block")
            if not imgBlock:IsValid() then
                imgBlock = ParaUI.CreateUIObject("button", "lessonbox_err_block", "_lt", 528, 68, 26, 26);
                page_root:AddChild(imgBlock)
            end
            imgBlock.enable = false
            imgBlock.background = background
        end
    end  
end

function LessonBoxTip.RemoveErrBlockTip()
    if page_root then
        ParaUI.Destroy("lessonbox_err_text")
        ParaUI.Destroy("lessonbox_err_block")
    end
end

function LessonBoxTip.OnStartMacroLearn()
    LessonBoxTip.m_ClickFollow = true
    local taskArea = lessonConfig.stageArea
    local posTeacher = lessonConfig.templateteacher
    local posMy = lessonConfig.templatemy
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]

    if taskArea then
        LessonBoxTip.ClearLearnArea(taskArea)
    end
    
    LessonBoxTip.EndTip()
    commonlib.TimerManager.SetTimeout(function()
        local endTemp = taskCnf.finishtemplate
        local startTemp = taskCnf.starttemplate
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        LessonBoxTip.ClearBlockTip()
        LessonBoxTip.ClearErrorBlockTip()
        LessonBoxTip.ClosePage()
        LessonBoxTip.StopStageMovie()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playFollowMacro", {macroPos = taskCnf.follow, macro_center_pos = taskCnf.macro_center_pos});
    end,200)
end

function LessonBoxTip.OnRetunMacro(isFinish)
    LessonBoxTip.ClosePage() 
    LessonBoxTip.UnregisterHooks()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    LessonBoxTip.StopStageMovie()
    LessonBoxTip.EndTip()
    GameLogic.RunCommand("/sendevent hideNpc")
    GameLogic.RunCommand("/ggs user visible");
    LessonBoxTip.PlayLessonMusic("free_world")
    GameLogic.GetCodeGlobal():BroadcastTextEvent("enterMacroMode", {isFinish = isFinish or false, is_lx = lessonConfig.is_lx});
end

function LessonBoxTip.CheckHasePlayMovie()
    local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
	-- if(#MovieManager.active_clips > 0) then
	-- 	return true
	-- end
    return false
end

function LessonBoxTip.FinishCurStageMacro()
    LessonBoxTip.GotoNextStage()
end

function LessonBoxTip.GotoNextStage()
    LessonBoxTip.ClosePage() 
    GameLogic.RunCommand("/sendevent hideNpc")
    GameLogic.RunCommand("/sendevent showMask")
    checkIndex = 0
    checkBtnType ="start"
    isFinishStage = false
    -- LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.CreatePos = nil
    LessonBoxTip.SrcBlockOrigin = nil
    LessonBoxTip.m_nCurStageIndex = LessonBoxTip.m_nCurStageIndex + 1
    --print("LessonBoxTip stage===========",LessonBoxTip.m_nCurStageIndex,LessonBoxTip.m_nMaxStageIndex,LessonBoxTip.m_nCurStageIndex )
    if LessonBoxTip.m_nCurStageIndex > LessonBoxTip.m_nMaxStageIndex then
        LessonBoxTip.m_nCurStageIndex = 0
        LessonBoxTip.m_nMaxStageIndex = 0
        -- GameLogic.AddBBS(nil,"当前步骤的所有课程已经全部完成，你可以点击下一个步骤继续学习")
        LessonBoxTip.OnRetunMacro(true)
        return 
    end
    LessonBoxTip.EndTip()
    LessonBoxTip.UpdateCheckBtnStatus(checkBtnType)
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.PrepareStageScene()
end

function LessonBoxTip.ExitLesson()
    
end


function LessonBoxTip.LockLessonArea()
    lockarea_timer = lockarea_timer or commonlib.Timer:new({callbackFunc = function(timer)
		if World2In1.GetCurrentType() == "course" then
            local player = EntityManager.GetPlayer()
            if player then
                local x, y, z = player:GetBlockPos();
                local dis = 50
                local minX, minY, minZ = 18626,3,19010;
                local maxX = minX+128 ;
                local maxZ = minZ+128*3 ;
                local newX = math.min(maxX-5, math.max(minX + 2, x));
                local newZ = math.min(maxZ-5, math.max(minZ , z));
                local newY = math.max(minY-1, y);
                if(x~=newX or y~=newY or z~=newZ) then
                    player:SetBlockPos(newX, 12, newZ)
                end
            end
        end
	end})
	lockarea_timer:Change(1000, 500);
    
end

function LessonBoxTip.EndLockArea()
    if lockarea_timer then
        lockarea_timer:Change()
        lockarea_timer = nil
    end
end

function LessonBoxTip.EndAllTimer()
    if lockarea_timer then
        lockarea_timer:Change()
        lockarea_timer = nil
    end
    if tip_timer then
        tip_timer:Change()
        tip_timer = nil
    end
    if scale_timer then
        scale_timer:Change()
        scale_timer = nil
    end
    if errblock_timer then
        errblock_timer:Change()
        errblock_timer = nil
    end
    if check_timer then
        check_timer:Change()
        check_timer = nil
    end
end

function LessonBoxTip.PlayLessonMusic(strType)
    local strType = strType or "free_world"
    if strType == "login" then
        World2In1.PlayLogoMusic()
    elseif strType == "free_world" then
        World2In1.PlayWorldMusic()
    elseif strType == "lesson" then
        World2In1.PlayLessonMusic()
    elseif strType == "lesson_operate" then
        World2In1.PlayOperateMusic()
    elseif strType == "creator" then
        World2In1.PlayCreatorMusic()
    elseif strType == "other" then
        World2In1.PlayOtherMusic()
    end
end

function LessonBoxTip.DelayUpdateTeacherSay()
    if(LessonBoxTip.teacher_say_timer) then
        LessonBoxTip.teacher_say_timer:Change();
    end

    LessonBoxTip.teacher_say_timer = LessonBoxTip.teacher_say_timer or commonlib.Timer:new({callbackFunc = function(timer)
        if lessonConfig then
            local str = lessonConfig.teacher_say or ""
            -- local str = string.format(LessonBoxTip.NomalTip.movietarget, lesson_desc)
            LessonBoxTip.SetTaskTip(nil, str)
        end
	end})
	LessonBoxTip.teacher_say_timer:Change(4000, nil);
end

function LessonBoxTip.SetAnimErrorTip()
    local result_list = LessonBoxTip.CompareMovieResult
    if not result_list then
        return
    end
    local say_text
    local result
    local remind_type

    if result_list["actor_parent"] then
        say_text = string.format("【%s】设定错误", LessonBoxTip.CompareTypeToDesc["actor_parent"])
        page:SetValue("role_tip", say_text)
        LessonBoxTip.DelayUpdateTeacherSay()
        return
    end

    -- 找slot/timelength/timeline
    for index, v in ipairs(LessonBoxTip.CheckMovieTips) do
        result = result_list[v.type]
        if result then
            remind_type = v.type
            say_text = v.text
            if v.type == "timelength" then
                say_text = string.format(v.text, result.stander_answer)
            elseif v.type == "timeline" or v.type == "slot" then
                -- 是右边网格中的数据的话 给的是有错误的演员or摄影机的名字
                local diff_type_name
                if v.type == "timeline" then
                    diff_type_name = ""
                end

                for index = 1, 48 do
                    local slot_data = result[index]
                    if slot_data then
                        if type(slot_data) == "table" then
                            for key, name in pairs(slot_data) do
                                if name then
                                    if v.type == "timeline" then
                                        key = LessonBoxCompare.GetMovieMenuName(key)
                                        local movie_menu_name = MovieClipTimeLine:GetVariableDisplayName(key) or ""
                                        name = name .. "-" .. movie_menu_name
                                    end
                                    say_text = string.format(v.text, name)
                                    break
                                end
                           end
                        else
                            say_text = string.format(v.text, slot_data, slot_data)
                        end
                    end
                end 
            end
            break
        end
    end

    if not result then
        for remind_type, result in pairs(result_list) do
            if result then
                say_text = string.format("【%s】设定错误", LessonBoxTip.CompareTypeToDesc[remind_type])
                break
            end
        end
    end

    if say_text then
        page:SetValue("role_tip", say_text)
        LessonBoxTip.DelayUpdateTeacherSay()
    end
end

function LessonBoxTip.StartCheckAnim()
    local regionsrc = lessonConfig.regionMy
    local regiondest = lessonConfig.regionOther
    -- 如果打开着老师的电影方块 不让比较
    if MovieClipController.IsVisible() then
        local answer_movice_pos = regiondest.pos
        local entity_answer = EntityManager.GetBlockEntity(answer_movice_pos[1], answer_movice_pos[2], answer_movice_pos[3])
        if entity_answer == MovieClipController.activeClip:GetEntity() then
            GameLogic.AddBBS(nil,"请关闭老师的电影方块后再点击检查", 3000, "255 0 0")
            return
        end
    end



    LessonBoxCompare.CompareAnimLesson(regionsrc, regiondest)

    if not LessonBoxTip.CompareMovieResult then
        return
    end
    local has_error = false
    for key, v in pairs(LessonBoxTip.CompareMovieResult) do
        if v then
            has_error = true
            break
        end
    end

    if has_error then
        LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount - 1
        MovieClipController.SetIsShowCompareError(true)
        MovieClipController.SetCompareErrorBg()
    else

        -- 作对了进入下一节
        LessonBoxTip.RemoveErrBlockTip()
        LessonBoxTip.SetErrorTip(1)
        isFinishStage = true
        local finish_desc = lessonConfig.is_lx and "当前练习已完成" or "当前小节已完成，即将进入下一小节的学习"
        GameLogic.AddBBS(nil,finish_desc)
        commonlib.TimerManager.SetTimeout(function()
            LessonBoxTip.ClearErrorBlockTip()
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.ClearBlockTip()
            -- if lessonConfig.is_lx then
            --     LessonBoxTip.OnRetunMacro(true)
            -- else
            --     LessonBoxTip.GotoNextStage()
            -- end
            LessonBoxTip.OnRetunMacro(true)
        end,5000)
        return
    end
    if LessonBoxTip.m_nCorrectCount <= -5 then
        local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex] or {}
        if taskCnf.follow and taskCnf.follow[1] then
            _guihelper.MessageBox("开启教学模式，跟着帕帕卡卡拉拉一起手把手一步一步完成课程的学习吧！",function()
                LessonBoxTip.OnStartMacroLearn()
            end)
        end

        if lessonConfig.is_lx then
            LessonBoxTip.m_nCorrectCount = -5
        end
    end
    if LessonBoxTip.m_nCorrectCount < - 6 then LessonBoxTip.m_nCorrectCount = -6  end
    if LessonBoxTip.m_nCorrectCount > 5 then LessonBoxTip.m_nCorrectCount = 5 end
    if LessonBoxTip.m_nCorrectCount <=5 and LessonBoxTip.m_nCorrectCount >= -6 then
        LessonBoxTip.RemoveErrBlockTip()
        LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
        LessonBoxTip.DelayShowErrBlockTip()
        
    end
end

function LessonBoxTip.OpenMovieClipController()
    if not page or not page_root or not page:IsVisible() then
        return
    end

    GameLogic.GetCodeGlobal():BroadcastTextEvent("stopAnimRepeatMovie");
end

function LessonBoxTip.OnClickCloseMovieClip()
    if not page or not page_root or not page:IsVisible() then
        return
    end
    if not lessonConfig or not lessonConfig.regionOther then
        return
    end
    if MovieClipController.activeClip then
        local regiondest = lessonConfig.regionOther
        local answer_movice_pos = regiondest.pos
        local entity_answer = EntityManager.GetBlockEntity(answer_movice_pos[1], answer_movice_pos[2], answer_movice_pos[3])
        -- 说明关掉的就是老师方块
        if entity_answer == MovieClipController.activeClip:GetEntity() then
            LessonBoxTip.ResetTeacherArea()
        end
    end

end

function LessonBoxTip.PlayTextByTeacher(text)
    local lesson_type = lessonConfig.lesson_type or ""
    local voice_type = VoiceType[lesson_type] or 10006
    if lessonConfig.voice_type then
        voice_type = lessonConfig.voice_type
    end
    
    SoundManager:PlayText(text,voice_type)
end