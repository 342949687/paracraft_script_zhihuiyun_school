--[[
Title: educate Competition funcions
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua")
local CompetitionManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager")

--提交分数使用如下，进入竞赛世界，调用命令
参数：  isUp 是否需要提交分数到服务器 
        score 当前分数
cmd("/sendevent SubmitCompeteScore {score = 10,isUp=true}")
--broadcast("SubmitCompeteScore", {score = 10,isUp=true})
-自定义
broadcast("SubmitCompeteScore", {
    score={
        {key="score",value=10,name="分数",isScore=true},
        {key="time",value=20,name="时间"}
    },
    isUp = true
})
--提交世界走正常的上传世界逻辑，点击提交按钮
-------------------------------------------------------
]]
local CompeteRepairPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteRepairPage.lua")
local CompetitionCreatePaper = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionCreatePaper.lua")
local KpChatChannel = NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua')
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
local EducateProjectManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProjectManager.lua")
local CompetitionManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager"));

function CompetitionManager:Init()
    self.compete_data = nil
    self.isWorldLoaded = false
    self.isSwfpageClosed = false
    self.isFirstSyncWorld = false
    self.isCompeteFinish = false
    self.isSubmitScore = false
    EducateProjectManager.Init()
    CompetitionApi.InitCompeteApi()
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  CompetitionManager.OnSwfLoadingCloesed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  CompetitionManager.OnSwfLoadingCloesed);

    GameLogic:Disconnect("WorldLoaded", CompetitionManager, CompetitionManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", CompetitionManager, CompetitionManager.OnWorldLoaded, "UniqueConnection");

    GameLogic:Disconnect("WorldUnloaded", CompetitionManager, CompetitionManager.OnWorldUnload, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", CompetitionManager, CompetitionManager.OnWorldUnload, "UniqueConnection");
    
    GameLogic.GetFilters():remove_filter("SyncWorldFinishBegin", CompetitionManager.OnSyncWorldFinishStart);
    GameLogic.GetFilters():add_filter("SyncWorldFinishBegin", CompetitionManager.OnSyncWorldFinishStart);

    GameLogic.GetFilters():remove_filter("SyncWorldFinish", CompetitionManager.OnSyncWorldFinish);
    GameLogic.GetFilters():add_filter("SyncWorldFinish", CompetitionManager.OnSyncWorldFinish);

    GameLogic.GetFilters():remove_filter("SyncWorldEnded", CompetitionManager.SyncWorldEnded);
    GameLogic.GetFilters():add_filter("SyncWorldEnded", CompetitionManager.SyncWorldEnded);

    GameLogic.GetFilters():remove_filter("SyncWorldInfoFinish", CompetitionManager.SyncWorldInfoFinish);
    GameLogic.GetFilters():add_filter("SyncWorldInfoFinish", CompetitionManager.SyncWorldInfoFinish);

    -- GameLogic.GetFilters():remove_filter("WorldName.ResetWindowTitle", CompetitionManager.ResetWindowTitle);
    -- GameLogic.GetFilters():add_filter("WorldName.ResetWindowTitle", CompetitionManager.ResetWindowTitle);

    GameLogic.GetFilters():add_filter(
        'save_world_info',
        function(ctx, node)
            self:SaveWorldInfo(ctx, node)
            return ctx,node
        end
    )

    GameLogic.GetFilters():add_filter(
        'load_world_info',
        function(ctx, node)
            self:LoadWorldInfo(ctx, node)
            return ctx,node
        end
    )

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        self.CurrentCreateWorldName = worldPath
        self.isFirstSyncWorld = true
        return worldPath
    end)

    GameLogic.GetFilters():add_filter("EducateLogout",  function(desc,callback)
        if callback and type(callback) == "function" then
            GameLogic.GetFilters():apply_filters('logout')
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
            GameLogic.CheckSignedIn(desc or L"请先登录！", function(bSucceed)
                if bSucceed then
                    callback()
                end
            end);
        end
        return desc,callback
    end)

    GameLogic.GetEvents():RemoveEventListener("createworld_callback",CompetitionManager.CreateWorldCallback, CompetitionManager, "CompetitionManager")
    GameLogic.GetEvents():AddEventListener("createworld_callback", CompetitionManager.CreateWorldCallback, CompetitionManager, "CompetitionManager");
end

function CompetitionManager.ResetWindowTitle(windowTitle,systemWindowTitle)
    if not CompetitionManager:CheckIsSpecialWorld() then
        return windowTitle
    end
    return systemWindowTitle
end

function CompetitionManager:LoadWorldInfo(ctx,node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end
    if self.compete_paper_data and self.compete_info_data then
        node.attr.change = ctx.channel or 2
    end
end

function CompetitionManager:SaveWorldInfo(ctx,node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end
    if self.compete_paper_data and self.compete_info_data then
        ctx.channel = ctx.channel or 2
    end
end

function CompetitionManager.CreateWorldCallback(_, event)
    local worldPath = commonlib.Encoding.DefaultToUtf8(event.world_path)
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        CompetitionManager.CurrentCreateWorldName = worldName
    end
end

function CompetitionManager:OnWorldLoaded()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        self.isWorldLoaded = true
        CompetitionManager:CheckCompeteStatus()
        CompeteRepairPage.CloseView()
    end,0)
end

function CompetitionManager:OnWorldUnload()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
       CompetitionCreatePaper.ClosePage()
    end,0)
end

function CompetitionManager.OnSwfLoadingCloesed()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        CompetitionManager.isSwfpageClosed = true
        CompetitionManager:CheckCompeteStatus()
        GameLogic.GetCodeGlobal():RegisterTextEvent("SubmitCompeteScore", function(args,msg)
            CompetitionManager:SetIsSubmitScore(true)
            local msg = msg.msg
            local score,isUp
            if type(msg) == "string" then
                msg = commonlib.LoadTableFromString(msg);
            end
            score,isUp = msg.score,msg.isUp
            if score and type(score) == "number" then
                CompetitionManager:SetAnswerScore(score,isUp)
                return
            end
            if score and type(score) == "table" then
                CompetitionManager:SetCustomAnswerScore(score,isUp)
                return
            end
        end);
        GameLogic.GetCodeGlobal():RegisterTextEvent("RepairCompeteWorld", function(args,msg)
            local msg = msg.msg
            if msg and (msg.isCustomUI == true or msg.isCustomUI == "true") then
                CompetitionManager:RepairCompeteWorld()
                return
            end
            CompetitionManager:ShowCommonMsgBox(nil,function(result)
                if result then
                    CompetitionManager:RepairCompeteWorld()
                end
            end)
        end)
    end,0)
end


function CompetitionManager.OnSyncWorldFinishStart()

end

function CompetitionManager.OnSyncWorldFinish(...)
    if not CompetitionManager.compete_data or type(CompetitionManager.compete_data) ~= "table" then
        return 
    end
    CompetitionCreatePaper.is_submiting = false
    local create_world_name = CompetitionManager.CurrentCreateWorldName
    if not create_world_name or create_world_name == "" then --非首次上传
        
    else
        CompetitionManager.CurrentCreateWorldName = ""
        GameLogic.AddBBS("CompetitionManager",L"首次同步世界成功")
        CompetitionManager.isFirstSyncWorld = true
    end
end

function CompetitionManager.SyncWorldInfoFinish(bSuccess)
    if not bSuccess then
        GameLogic.AddBBS(nil,L"更新世界信息失败~")
        return
    end
    if CompetitionManager.isFirstSyncWorld and not CompetitionManager.isSubmitScore then 
        CompetitionManager.isFirstSyncWorld = false
        return 
    end
    if not CompetitionManager:IsCustomCompete() then
        local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
        CompetitionManager:UploadCompeteScore(currentWorld)
        return
    end
    CompetitionManager:UploadCustomCompeteScore()
end


function CompetitionManager.SyncWorldEnded()
    
end

function CompetitionManager:CheckIsInCompete()
    return self.compete_data and type(self.compete_data) == "table"
end

function CompetitionManager:SetCompeteData(data)
    if not self.CompeteStartImp then
        self.CompeteStartImp = commonlib.debounce(function()
            self:StartCompete()
        end,5000)
    end
    self.compete_data = data
    self.isCompeteFinish = false
    self.CompeteStartImp()
end

function CompetitionManager:UpdateCompeteData(params)
    if not self.compete_data then
        self.compete_data = {}
    end
    if params and type(params) == "table" then
        for k,v in pairs(params) do
            self.compete_data[k] = v
        end
    end
end

function CompetitionManager:GetCompeteData()
    return self.compete_data
end

function CompetitionManager:GetCompeteInfoData()
    return self.compete_info_data
end

function CompetitionManager:GetCompeteRecordData()
    return self.compete_record_data
end

function CompetitionManager:GetCompetePaperData()
    return self.compete_paper_data
end

function CompetitionManager:ClearCompeteData()
    print("ClearCompeteData============")
    -- print(commonlib.debugstack())
    self.LeaveCompeteRoom()
    self.compete_data = nil --比赛信息
    self.compete_info_data = nil --考试信息 --提交和定时更新时间
    self.compete_paper_data = nil --试卷信息
    self.compete_record_data = nil --答卷记录
    if self.timer then
        self.timer:Change()
    end
    if self.adjustTimer then
        self.adjustTimer:Change()
    end
end

function CompetitionManager:GetFolderName(callback)
    local competeData = self:GetCompeteData()
    local compete_info_data = self:GetCompeteInfoData()
    local create_compete_time = commonlib.timehelp.GetTimeStampByDateTime(compete_info_data.createdAt)
    local server_time = CompetitionUtils.GetServerTime()
    local username = Mod.WorldShare.Store:Get('user/username')
    GameLogic.SendErrorLog("CompetitionManager","compete debug info ,competeInfo is"..commonlib.serialize_compact({username = username,competeData,compete_info_data}))
    LOG.std(nil,"info","CompetitionManager","CompetitionManager GetFolderName time is "..(os.date("%Y-%m-%d %H:%M:%S",create_compete_time) or 0).." server_time is "..(os.date("%Y-%m-%d %H:%M:%S", server_time) or 0))
    local dateStr = os.date("%Y_%m_%d",create_compete_time or server_time)
    local world_name =  "exam_world" .. dateStr .."_"..(competeData.competePaperId or 0)
    self.compete_data.world_name = world_name
    local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
    Compare:GetNewWorldName(world_name, callback)
end

function CompetitionManager:IsExamWorld(name)
    local foldername = name or ""
    local regexStr = "^exam_world%d+_%d+_%d+_%d+"
    return foldername:match(regexStr)
end

--type:loadworld 加载世界  forkworld fork世界 createworld 创建世界
function CompetitionManager:StartCompete()
    local competeDt = self:GetCompeteData()
    if competeDt then
        CompetitionApi.GetCompeteInfo({
            router_params = {
                id = competeDt.competeContentId,
            }
        },function(err,msg,data)
            if err == 200 then
                self.compete_info_data = data
                local mainWorldId = competeDt.projectId
                local action_type = competeDt.type
                if mainWorldId and tonumber(mainWorldId) > 0 then
                    if action_type == "loadworld" then
                        local strCommand = string.format("/loadworld -s -auto %d",tonumber(mainWorldId))
                        GameLogic.RunCommand(strCommand)
                    elseif action_type == "forkworld" then
                        self:ForkWorkd(mainWorldId)
                    elseif action_type == "createworld" then
                        self:CreateWorld()
                    end
                else
                    GameLogic.AddBBS("CompetitionManager",L"赛事配置的世界为空，正在进入默认世界~~~")
                    commonlib.TimerManager.SetTimeout(function()
                        self:CreateWorld()
                    end,1000)
                end
            else
                if err == 401 then
                    GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                        self:StartCompete()
                    end)
                end
                local str = err == 401 and "获取赛事详情失败，请重新登录" or L"获取赛事详情失败，code===="..err
                GameLogic.AddBBS("CompetitionManager",str)
            end
        end)
    else
        _guihelper.MessageBox(L"赛事配置有误，请联系主办方")
    end
end

function CompetitionManager:DelayLoadWorld(worldPath,callback)
    if not worldPath or worldPath == "" then
        return
    end
    local tryTime = 0;
    local timer;
    timer = commonlib.Timer:new({
        callbackFunc = function()
            if (tryTime >= 120) then
                timer:Change(nil, nil);
                GameLogic.AddBBS("CompetitionManager",L"加载世界超时...")
                return;
            end

            if (ParaIO.DoesFileExist(worldPath)) then
                timer:Change(nil, nil);
                if callback then
                    callback()
                end
            end
            
            tryTime = tryTime + 1;
        end
    }, 500);
    timer:Change(0, 500);
end

function CompetitionManager:CheckCompeteOldData()
    local competeData = self:GetCompeteData()
    local competePaperId = (competeData.competePaperId or 0)
    local currentWorldList = Mod.WorldShare.Store:Get('world/fullWorldList') or {}
    local competeStr = "_"..competePaperId
    local competeStr1 = "exam_world(%d+)_(%d+)_(%d+)_(%d+)" --跨天导致的
    local competeStr2 = "exam_world(%d+)_(%d+)_(%d+)_(%d+)_(%d+)" --旧bug导致的
    --local year, month, day, hour, min, sec = date_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local worldList = {}
    for k,v in pairs(currentWorldList) do
        local name1 = v.name or ""
        local isDeleted = v.isDeleted == 1
        local year,month,day,paperId = name1:match(competeStr1)
        local year1,month1,day1,paperId1,index = name1:match(competeStr2)
        if not isDeleted and paperId and tonumber(paperId) > 0 and paperId == competePaperId then
            local temp = {}
            temp.name = name1
            temp.year = tonumber(year)
            temp.month = tonumber(month)
            temp.day = tonumber(day)
            temp.paperId = tonumber(paperId)
            temp.index = tonumber(index or 0)
            temp.time_stamp = os.time({year=temp.year,month=temp.month,day=temp.day,hour=0,min=0,sec=0})
            table.insert(worldList,temp)
        end
    end

    table.sort(worldList,function(a,b)
        if a.time_stamp == b.time_stamp then
            return a.index < b.index
        end
        return a.time_stamp < b.time_stamp
    end)
    if #worldList > 0 then
        local data = worldList[1]
        local username = Mod.WorldShare.Store:Get("user/username");
        local worldName = data.name
        local worldPath = "worlds/DesignHouse/".. worldName
        if username and username ~= "" then
            worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. worldName
        end
        return worldName,worldPath
    end
end

function CompetitionManager:CreateWorld()
    self:GetFolderName(function(worldName,worldPath,last_world_name,last_world_path)
        local lastname,lastpath = self:CheckCompeteOldData()
        if lastname and lastpath then
            self.compete_data.world_name = ""
            last_world_name = lastname
            last_world_path = lastpath
        end
        self.compete_data.worldPath = last_world_path
        self.compete_data.new_world_name = last_world_name
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", CompetitionManager.OnBeforeLoadWorld); 
        if (not ParaIO.DoesFileExist(last_world_path)) then
            local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
            CreateWorld:CreateWorldByName(worldName, "superflat",false)
        end
        self:DelayLoadWorld(last_world_path,function()
            local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
            SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
                GameLogic.RunCommand(string.format('/loadworld %s', last_world_path))
                local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
                Progress.syncInstance = nil
            end)
        end)
    end)
end

function CompetitionManager:ForkWorkd(worldId)
    self:GetFolderName(function(worldName,worldPath,last_world_name,last_world_path)
        local lastname,lastpath = self:CheckCompeteOldData()
        if lastname and lastpath then
            self.compete_data.world_name = ""
            last_world_name = lastname
            last_world_path = lastpath
        end
        self.compete_data.worldPath = last_world_path
        self.compete_data.new_world_name = last_world_name
        print("worldName========",worldName,worldPath,last_world_name,last_world_path)
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", CompetitionManager.OnBeforeLoadWorld); 
        if (not ParaIO.DoesFileExist(last_world_path)) then
            local cmd = format(
                "/createworld -name \"%s\" -parentProjectId %d -update -fork %d -mode admin",
                last_world_name,
                worldId,
                worldId
            );
            print("cmd=========",cmd)
            GameLogic.RunCommand(cmd);
        elseif not self:CheckIsRemoteWorld(last_world_path) then
            -- self.CurrentCreateWorldName = worldName
            GameLogic.GetFilters():apply_filters('OnWorldCreate', last_world_name)
        end
        self:DelayLoadWorld(last_world_path,function()
            local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
            SyncWorld:CheckAndUpdatedByFoldername(last_world_name,function ()
                if CompetitionManager:CheckWorldValid(last_world_path) then
                    GameLogic.RunCommand(string.format('/loadworld %s', last_world_path))
                    local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
                    Progress.syncInstance = nil
                else
                    GameLogic.AddBBS("CompetitionManager",L"加载世界失败，当前世界的数据已损坏")
                    ParaIO.DeleteFile(last_world_path)
                    commonlib.SendErrorLog("CompetitionManager","load world failed","world file is uncorrect============")
                end
            end)
        end)
    end)
    
end

function CompetitionManager:WriteConfigFile(worldPath)
    local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
            ]]

    local worldConfigFile = ParaIO.open(worldPath .. '/worldconfig.txt', 'w')

    worldConfigFile:write(worldConfig, #worldConfig)
    worldConfigFile:close()
end

function CompetitionManager:CheckWorldValid(worldPath)
    if not worldPath or worldPath == "" then
        return false
    end
    local output = commonlib.Files.Find({}, worldPath, 0, 500, "*.*")
    if not output or #output == 0 then
        return false 
    end
    local isFindTag,isFindWorldConfig = false,false
    for k,item in pairs(output) do
        if item.filename == "tag.xml" then
            isFindTag = true
        end
        if item.filename == "worldconfig.txt" then
            isFindWorldConfig = true
        end
    end
    if isFindTag and isFindWorldConfig then
        return true
    end
    if not isFindTag then
        return false
    end
    if not isFindWorldConfig then
        self:WriteConfigFile(worldPath)
        Game.Start(worldPath)
        return true
    end
    return false
end

function CompetitionManager.OnBeforeLoadWorld(worldPath)
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local worldName = CompetitionManager.compete_data and CompetitionManager.compete_data.world_name or ""
    if worldName and worldName ~= "" then
        WorldCommon.SetWorldTag("name", worldName);
        WorldCommon.SaveWorldTag()
    end
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",CompetitionManager.OnBeforeLoadWorld);
    print("CompetitionManager.OnBeforeLoadWorld=================")
end

function CompetitionManager:CheckIsRemoteWorld(worldPath)
    local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
    local tag = LocalService:GetTag(worldPath)
    local kpProjectId = tag and tag.kpProjectId
    return kpProjectId and tonumber(kpProjectId) > 0
end

function CompetitionManager:CheckCompeteStatus()
    --显示创作页面的判断逻辑
    if self.isWorldLoaded and self.isSwfpageClosed then
        local competeDt = self:GetCompeteData()
        if not competeDt then
            -- GameLogic.AddBBS("CompetitionManager","比赛信息为空")
            return
        end
        local projectId = GameLogic.options:GetProjectId()
        local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
        local competeId = competeDt.competeId
        local competePaperId = competeDt.competePaperId
        local enrolmentId = competeDt.enrolmentId
        CompetitionApi.PostCompeteRecord({
            competeId = competeId,
            userId = userId,
            competePaperId = competePaperId,
            enrolmentId = enrolmentId,
        },function(err,msg,data)
            if err == 200 then
                local answerRecords =  (data and data[1]) and data[1] or {}
                self.compete_record_data = answerRecords
                if answerRecords.status == 1 then
                    GameLogic.AddBBS("CompetitionManager",L"答题已结束")
                    return 
                end
                self:CheckCompetePaperStatus()
            else
                GameLogic.AddBBS("CompetitionManager",L"上报答卷记录失败，code==="..err)
            end
        end)
    end
end

function CompetitionManager:CheckCompetePaperStatus()
    local competeDt = self:GetCompeteData()
    local competeQuestionId = competeDt.competeQuestionId
    CompetitionApi.GetRacePaperList({
        router_params = {
            id = competeDt.competePaperId,
        }
    },function(err,msg,data)
        print("err==============",err)
        -- echo(data,true)
        if err == 200 then
            local competePaperDt = {}
            echo(data,true)
            local answerRecord = data.answerSheetRecord or {}
            local real_answer_time = commonlib.timehelp.GetTimeStampByDateTime(answerRecord.createdAt)
            if data and data.questionGroups and #data.questionGroups > 0 then
                for k,v in pairs(data.questionGroups) do
                    if v.type == 5 or v.type == 6 then
                        local competeQuestions = v.competeQuestions or {}
                        for _,competeQuestion in pairs(competeQuestions) do
                            if v.type == 6 then
                                competePaperDt[#competePaperDt + 1] = competeQuestion --进入世界
                            elseif v.type == 5 and competeQuestion.creativeType == 3 then
                                competePaperDt[#competePaperDt + 1] = competeQuestion --fork世界创造
                            end
                        end
                    end
                end
            end
            for k,v in pairs(competePaperDt) do
                if v.id == competeQuestionId then
                    v.real_answer_time = real_answer_time == 0 and os.time() or real_answer_time
                    self.compete_paper_data = v
                end
            end
            self:StartCurrentCompete()
        else
            GameLogic.AddBBS("CompetitionManager",L"获取试卷信息失败，code==="..err)
        end
    end)
end

function CompetitionManager:StartCurrentCompete()
    echo(self.compete_data,true) --比赛信息
    print("compete_data===================================")
    echo(self.compete_info_data,true) --考试信息 --提交和定时更新时间
    print("compete_info_data===================================")
    echo(self.compete_paper_data,true) --试卷信息
    print("compete_paper_data===================================")
    echo(self.compete_record_data,true) --答卷记录
    print("compete_record_data===================================")
    --缺少一个数据，就是表示这次赛事一场
    if self.compete_data and self.compete_info_data and self.compete_record_data and self.compete_paper_data then
        self:UpdateSurplusTime()
        self:AdjustCompeteTime()
        self.JoinCompeteRoom()
        CompetitionCreatePaper.ShowPage()
        commonlib.TimerManager.SetTimeout(function()
            -- NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
            -- local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
            -- local id = WorldCommon.GetWorldTag("kpProjectId");
            -- KpChatChannel.LeaveWorld(id)
        end,5*1000)
    end
end

--校准比赛时间 -- 大概20s一次
function CompetitionManager:AdjustCompeteTime()
    self.adjustTimer = self.adjustTimer or commonlib.Timer:new({callbackFunc = function(timer)
        self:CheckInValidCompete()
    end});
    self.adjustTimer:Change(20*1000, 20*1000);
end

--比赛有效时间判断
function CompetitionManager:CheckInValidCompete(callback)
    local competeDt = self:GetCompeteData()
    if competeDt then
        CompetitionApi.GetCompeteInfo({
            router_params = {
                id = competeDt.competeContentId,
            }
        },function(err,msg,data)
            if err == 200 then
                self.compete_info_data = data
                CompetitionManager:UpdateSurplusTime(callback)
            else
                local str = err == 401 and "获取赛事详情失败，请重新登录" or L"获取赛事详情失败，code===="..err
                GameLogic.AddBBS("CompetitionManager",str)
                if err == 401 then
                    GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                        self:CheckInValidCompete(callback)
                    end)
                end
            end
        end)
    else
        
    end
end

function CompetitionManager:CheckIsSpecialWorld()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    local foldername = currentEnterWorld.foldername or ""
    local regexStr = "^exam_world%d+_%d+_%d+_%d+"
    local regexStr1 = "^%d%d%d%d%d%d%d%d_%d+_%d+_%d+"
    if string.match(foldername,regexStr) or string.match(foldername,regexStr1) then
        return false
    end
    return true
end

function CompetitionManager:UpdateSurplusTime(callback)
    if self.compete_paper_data and self.compete_info_data then
        local real_time = self.compete_paper_data.real_answer_time
        local answer_end_time = commonlib.timehelp.GetTimeStampByDateTime(self.compete_info_data.answerEndAt)
        local server_time = CompetitionUtils.GetServerTime()
        local cutDownTime = self.compete_info_data.isCountDown == 1 and self.compete_info_data.countDown * 60 or 0
        print("answer_end_time=========",answer_end_time,server_time + cutDownTime,server_time,cutDownTime)
        if real_time + cutDownTime <= answer_end_time and cutDownTime ~= 0 then
            answer_end_time = real_time + cutDownTime
        end
        
        self.surplus_time = answer_end_time - server_time
        if callback then
            callback(self.surplus_time)
        else
            self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
                local timestr = CompetitionUtils.GetTimeFormatStr(self.surplus_time)
                self.surplus_time = self.surplus_time - 1
                if self.surplus_time <= 0 then
                    self.surplus_time = 0
                    self.timer:Change()
                    GameLogic.AddBBS("CompetitionManager",L"答题时间结束，正在提交成绩，请稍候....")
                    if not self.isCompeteFinish then
                        self:ForceSubmitScore()
                        self.isCompeteFinish = true
                    end
                    if self.adjustTimer then
                        self.adjustTimer:Change()
                        self.adjustTimer = nil
                    end
                end
                --GameLogic.AddBBS("CompetitionManager","时间剩余===="..timestr)
            end});
            self.timer:Change(0, 1000);
        end
    end
end


function CompetitionManager:GetSurplusTime()
    return self.surplus_time
end

--[[
    广播消息:暂时只有赛事使用
    event = {  
        eventName: 'edu_compete_submited',  
        payload: {
            action = 'edu_compete_submited',
            userId: 42375,    
            competeQuestionId: 0, // 题目Id    
            answerSheetRecordId: 0, //    
            completeTime: new Date(),  },};
]]

function CompetitionManager.JoinCompeteRoom()
    local answerSheetRecordId = CompetitionManager.compete_record_data and CompetitionManager.compete_record_data.id or nil
    if not answerSheetRecordId then
        return
    end
    if not not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionManager","赛事socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__answerSheetRecord_EDU_"..answerSheetRecordId.."__"
            KpChatChannel.client:Send("app/join",{ rooms = { room }, });
        end,5*1000)
        return
    end

    local room = "__answerSheetRecord_EDU_"..answerSheetRecordId.."__"
    KpChatChannel.client:Send("app/join",{ rooms = { room }, });
end 

function CompetitionManager.LeaveCompeteRoom()
    local answerSheetRecordId = CompetitionManager.compete_record_data and CompetitionManager.compete_record_data.id or nil
    if not answerSheetRecordId then
        return
    end
    if not not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionManager","赛事socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__answerSheetRecord_EDU_"..answerSheetRecordId.."__"
            KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
        end,5*1000)
        return
    end
    local room = "__answerSheetRecord_EDU_"..answerSheetRecordId.."__"
    KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
end

function CompetitionManager.BroadcastMsg(msgdata)
    if (not msgdata or type(msgdata) ~= "table") then
        return
    end
    local broadcastFunc = function()
        local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
        local kp_msg = {
            eventName = "edu_compete_submited",
            room = "__answerSheetRecord_EDU_"..(CompetitionManager.compete_record_data and CompetitionManager.compete_record_data.id or 0).."__",
            payload = {
                action ="edu_compete_submited",
                userId = userId,
                competeQuestionId = msgdata.competeQuestionId or 0,
                answerSheetRecordId = msgdata.answerSheetRecordId or 0,
                completeTime = tonumber(CompetitionUtils.GetServerTime()) * 1000,
            },
        }
        KpChatChannel.client:Send("app/broadcast", kp_msg);
    end

    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionManager","赛事socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            broadcastFunc()
        end,5*1000)
        return
    end
    broadcastFunc()
end

function CompetitionManager:IsCustomCompete()
    if self.compete_paper_data then
        return self.compete_paper_data.isUploadScore == 1
    end
    return false
end

function CompetitionManager:SetCustomAnswerScore(params,isUp)
    if not params or not self:IsCustomCompete() then
        return
    end
    if type(params) == "table" then
        self.custom_answer_score = {}
        local num = #params
        if num > 0 then
            for i = 1,num do
                local item = params[i]
                if item and type(item) == "table" then
                    self.custom_answer_score[#self.custom_answer_score + 1] = item
                end
            end
        else
            self.custom_answer_score = params
        end
    elseif type(params) == "number" then
        self:SetAnswerScore(params,isUp)
    end
    if isUp then
        self:SubmitWorld()
        --self:UploadCustomCompeteScore()
    end
end

function CompetitionManager:UploadCustomCompeteScore()
    if not self.compete_data then
        return 
    end
    local custom_answer_score = self.custom_answer_score or {}
    local score = 0
    for i = 1,#custom_answer_score do
        local item = custom_answer_score[i]
        if type(item) == "table" and item.isScore == true then
            score = tonumber(item.value or 0)
            break
        end
    end
    local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
    local kpProjectId = currentWorld.kpProjectId or 0
    local commitId
    CompetitionApi.GetProjectInfo({
        router_params = {
            id = tonumber(kpProjectId),
        },
    },function(err,msg,data)
        if err == 200 then
            commitId = (data and data.world and data.world.commitId) and data.world.commitId or 0
            local customScore = custom_answer_score
            local extra = {}
            extra.customFields = customScore
            local desc = self.isSubmitScore and L"自定义赛事成绩上报成功，请切换试卷页面继续操作" or L"世界上传成功，请继续操作"
            local answer = {}
            if self.isSubmitScore then
                answer.item = {
                    {
                        submited = true,
                        projectId = kpProjectId,
                    }
                }
                local params = {}
                params.competeId = self.compete_data.competeId
                local answerSheetRecordId = self.compete_record_data.id or 0
                local competeQuestionId = self.compete_data.competeQuestionId or 0
                local answerRecord = {
                    projectId = kpProjectId,
                    answerSheetRecordId = answerSheetRecordId,
                    competeQuestionId = competeQuestionId,
                    answer = answer,
                    extra=extra,
                    questionType = self.compete_paper_data.type
                }
                answerRecord.score = score
                answerRecord.commitId = commitId

                params.answerRecords = {}
                params.answerRecords[#params.answerRecords + 1] = answerRecord
                CompetitionApi.SubmitAnswerRecord(params,function(err,msg,data)
                    if err == 200 then
                        GameLogic.AddBBS("CompetitionManager",desc)
                        self.BroadcastMsg({
                            competeQuestionId = competeQuestionId,
                            answerSheetRecordId = answerSheetRecordId,
                        })
                    else
                        GameLogic.AddBBS("CompetitionManager",L"上报成绩失败，code==="..err)
                        echo(msg,true)
                        echo(data,true)
                    end
                end)
            else
                GameLogic.AddBBS("CompetitionManager",desc)
            end
            
        else
            GameLogic.AddBBS("CompetitionManager",L"获取世界信息失败，code==="..err.."kpProjectId===="..(kpProjectId or 0))
        end
    end)

    
end

function CompetitionManager:SetAnswerScore(score,isUp)
    self.answer_score = score
    if isUp then
        self:UploadCompeteScore(score)
    end
end

function CompetitionManager:GetAnswerScore()
    return self.answer_score
end

function CompetitionManager:SetIsSubmitScore(isSubmitScore)
    self.isSubmitScore = isSubmitScore == true or isSubmitScore == "true"
end

function CompetitionManager:SubmitWorld()
    if not GameLogic.IsReadOnly() then
        GameLogic.RunCommand("/save")
        local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
        ShareWorld:SyncWorld(function()
            GameLogic.AddBBS(nil,L"世界上传成功")
        end)
    else
        local answerScore = self:GetAnswerScore() or 0
        self:UploadCompeteScore(answerScore)
    end
end

function CompetitionManager:UploadCompeteScore(score)
    if score and type(score) == "table" then
        local kpProjectId = score.kpProjectId
        if not kpProjectId then
            local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
            kpProjectId = currentWorld.kpProjectId
        end
        local commitId
        CompetitionApi.GetProjectInfo({
            router_params = {
                id = tonumber(kpProjectId),
            },
        },function(err,msg,data)
            if err == 200 then
                commitId = (data and data.world and data.world.commitId) and data.world.commitId or 0
                self:UpdateAnswerWorld(commitId)
            else
                GameLogic.AddBBS("CompetitionManager",L"获取世界信息失败，code==="..err.."kpProjectId===="..(kpProjectId or 0))
            end
        end)
        return
    end
    if score and type(score) == "number" then
        self:UpdateAnswerScore(score)
    end
end



function CompetitionManager:SubmitAnswerRecord(key,value)
    if not self.compete_data or not self.compete_paper_data or not self.compete_record_data then
        return 
    end
    if not key or not value then
        return 
    end
    if key == "score" and not self.isSubmitScore then
        return 
    end
    
    local desc = key == "score" and L"成绩上报成功，请切换试卷页面继续操作" or L"世界提交成功，请切换试卷页面继续操作"
    if not self.isSubmitScore then
        desc = L"世界上传成功，你可以继续进行创作，然后再次提交世界"
    end
    if self.isSubmitScore then
        local answer = {}
        answer.item = {
            {
                submited = true,
            }
        }
        local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
        local params = {}
        params.competeId = self.compete_data.competeId
        local answerSheetRecordId = self.compete_record_data.id or 0
        local competeQuestionId = self.compete_data.competeQuestionId or 0
        local answerRecord = {
                projectId = currentWorld.kpProjectId or 0,
                answerSheetRecordId = answerSheetRecordId,
                competeQuestionId = competeQuestionId,
                answer = answer,
                questionType = self.compete_paper_data.type
            }
            
        answerRecord[key] = value
        params.answerRecords = {}
        params.answerRecords[#params.answerRecords + 1] = answerRecord
        CompetitionApi.SubmitAnswerRecord(params,function(err,msg,data)
            if err == 200 then
                GameLogic.AddBBS("CompetitionManager",desc)
                self.BroadcastMsg({
                    competeQuestionId = competeQuestionId,
                    answerSheetRecordId = answerSheetRecordId,
                })
            else
                GameLogic.AddBBS("CompetitionManager",L"上报成绩失败，code==="..err)
                echo(msg,true)
                echo(data,true)
            end
        end)
    else
        GameLogic.AddBBS("CompetitionManager",desc)
    end
    
end

function CompetitionManager:UpdateAnswerScore(score)
    self:SubmitAnswerRecord("score",score)
end

function CompetitionManager:UpdateAnswerWorld(commitId)
    self:SubmitAnswerRecord("commitId",commitId)
end



function CompetitionManager:ForceSubmitScore()
    commonlib.TimerManager.SetTimeout(function()
        self.isSubmitScore = true
        self:SubmitWorld(true)
    end,500)
end


function CompetitionManager:DoExitWorld()
    local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
    WorldExitDialog.SetWindowText()

    Mod.WorldShare.Store:Remove('world/currentWorld')
    Mod.WorldShare.Store:Remove('world/currentEnterWorld')
    Mod.WorldShare.Store:Remove('world/isEnterWorld')

    -- TouchMiniKeyboard.CheckShow(false)
    -- WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    CustomCharItems:Init();
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game and Game.is_started) then
        Game.Exit()
    end
end

function CompetitionManager:RealExitWorld()
    local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
    WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
end

function CompetitionManager:OpenWebPaperUrl()
    if self.compete_record_data and self.compete_record_data.competePaperId then
        local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
        local token = commonlib.getfield("System.User.keepworktoken")
        local baseurl = "https://cp.palaka.cn/"
        local url = ""
        local http_env = HttpWrapper.GetDevVersion()
        if http_env == "LOCAL" or http_env == "STAGE" then
            baseurl = "http://cp-dev.kp-para.cn/"
        elseif http_env == "RELEASE" then
            baseurl = "http://cp-rls.kp-para.cn/"
        else
            baseurl = "https://cp.palaka.cn/"
        end
        url= baseurl.."?token="..token.."&redirect=".."exam/"..self.compete_record_data.competePaperId.."/"
        local platform = System.os.GetPlatform()
        if platform == "win32" or platform == "emscripten" then
            GameLogic.RunCommand("/open "..url)
            return
        end
        GameLogic.RunCommand("/open -e "..url)
    end
end

function CompetitionManager:DeleteCompeteWorld(worldData,callback)
    if not worldData or next(worldData) == nil then
        return
    end
    local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
    local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
    local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
    local selectedWorld = worldData
    if selectedWorld and selectedWorld.kpProjectId and selectedWorld.kpProjectId > 0 then
        DeleteWorld:DeleteWorldSilent(function(result)
            if not result then
                GameLogic.AddBBS(nil,"删除错误项目失败，请稍候重试")
                if callback and type(callback) == "function" then
                    callback(false)
                end
                return
            end
            
            if System.options.isDevMode then
                print("delete remote world success =============",selectedWorld.kpProjectId,selectedWorld.name,selectedWorld.worldpath)
                echo(selectedWorld,true)
            end
            --防止数据刷新后，不能删除本地数据
            Mod.WorldShare.Store:Set('world/currentWorld',selectedWorld)
            DeleteWorld:DeleteLocal(function()
                if System.options.isDevMode then
                    print("delete local world success =",selectedWorld.name,selectedWorld.worldpath)
                end
                GameLogic.AddBBS(nil,"删除错误项目成功，稍后会重新进入赛事世界")
                Create:GetWorldList(Create.statusFilter)
                EducateProject.GetUserWorldUsedSize()
                if callback and type(callback) == "function" then
                    callback(true)
                end
            end,true)
        end)  
    else
        DeleteWorld:DeleteLocal(function()
            GameLogic.AddBBS(nil,"删除错误项目成功，稍后会重新进入赛事世界")
            Create:GetWorldList(Create.statusFilter)
            if callback and type(callback) == "function" then
                callback(true)
            end
        end,true)
    end 
end

function CompetitionManager:RepairCompeteWorldFunc()
    local compete_data = commonlib.copy(self.compete_data)
    if not compete_data or next(compete_data) == nil then
        return
    end
    if Game.is_started then
        local worldData = Mod.WorldShare.Store:Get('world/currentWorld') or {}
        local currentWorld =  commonlib.copy(worldData)
        self:DoExitWorld()
        commonlib.TimerManager.SetTimeout(function()
            -- CompeteRepairPage.ShowPage();
            Mod.WorldShare.Store:Set('world/currentWorld',currentWorld)
            self:DeleteCompeteWorld(currentWorld,function(result)
                if result then
                    self:Init()
                    GameLogic.AddBBS(nil,"赛事世界修复成功，正在重新进入赛事世界")
                    self:ClearCompeteData()
                    self:SetCompeteData(compete_data)
                else
                    GameLogic.AddBBS(nil,"赛事世界修复失败，请稍候重试")
                    CompeteRepairPage.CloseView()
                    self:RealExitWorld()
                end
            end)
        end,500)
        return
    end
end

function CompetitionManager:RepairCompeteWorld()
    GameLogic.AddBBS(nil,"正在修复赛事世界,请稍候...")
    CompeteRepairPage.ShowPage();
    commonlib.TimerManager.SetTimeout(function()
        self:RepairCompeteWorldFunc()
    end,1500)
end

function CompetitionManager:ShowCommonMsgBox(msg,callback)
    local RepairDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/RepairDialog.lua")
    RepairDialog.ShowView(msg,callback);
end












