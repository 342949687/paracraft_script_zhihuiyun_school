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

--提交世界走正常的上传世界逻辑，点击提交按钮
-------------------------------------------------------
]]
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

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        self.CurrentCreateWorldName = worldPath
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
            local msg = msg.msg
            local score,isUp
            if type(msg) == "string" then
                msg = commonlib.LoadTableFromString(msg);
            end
            score,isUp = msg.score,msg.isUp
            CompetitionManager:SetAnswerScore(score,isUp)
        end);
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
    end
end

function CompetitionManager.SyncWorldInfoFinish(bSuccess)
    if not bSuccess then
        GameLogic.AddBBS(nil,L"更新世界信息失败~")
        return
    end
    local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
    CompetitionManager:UploadCompeteScore(currentWorld)
end


function CompetitionManager.SyncWorldEnded()
    
end

function CompetitionManager:CheckIsInCompete()
    return self.compete_data and type(self.compete_data) == "table"
end

function CompetitionManager:SetCompeteData(data)
    self.compete_data = data
    self:StartCompete()
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
    print(commonlib.debugstack())
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

function CompetitionManager:GetFolderName()
    local competeData = CompetitionManager:GetCompeteData()
    local dateStr = os.date("%Y_%m_%d",CompetitionUtils.GetServerTime())
    local worldName =  "exam_world" .. dateStr .."_"..(competeData.competePaperId or 0)
    local username = Mod.WorldShare.Store:Get("user/username");
    local worldPath = "worlds/DesignHouse/".. worldName
    if username and username ~= "" then
        worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. worldName
    end
    return worldName,worldPath
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

function CompetitionManager:CreateWorld()
    local worldName,worldPath = self:GetFolderName()
    local function tryFunc(callback)
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
    if (not ParaIO.DoesFileExist(worldPath)) then
        local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
        CreateWorld:CreateWorldByName(worldName, "superflat",false)
    end
    tryFunc(function()
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
        end)
    end)
end

function CompetitionManager:ForkWorkd(worldId)
    local worldName,worldPath = self:GetFolderName()
    local function tryFunc(callback)
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
    print("worldName========",worldName,worldPath)
    if (not ParaIO.DoesFileExist(worldPath)) then
        local cmd = format(
            "/createworld -name \"%s\" -parentProjectId %d -update -fork %d",
            worldName,
            worldId,
            worldId
        );
        print("cmd=========",cmd)
        GameLogic.RunCommand(cmd);
    elseif not self:CheckIsRemoteWorld(worldPath) then
        -- self.CurrentCreateWorldName = worldName
        GameLogic.GetFilters():apply_filters('OnWorldCreate', worldName)
    end
    tryFunc(function()
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
        end)
    end)
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
                    self:ForceSubmitScore()
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

function CompetitionManager:SetAnswerScore(score,isUp)
    self.answer_score = score
    if isUp then
        self:UploadCompeteScore(score)
    end
end

function CompetitionManager:GetAnswerScore()
    return self.answer_score
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
                GameLogic.AddBBS("CompetitionManager",L"获取世界信息失败，code==="..err)
            end
        end)
        return
    end
    if score and type(score) == "number" then
        self:UpdateAnswerScore(score)
    end
end

function CompetitionManager:SubmitAnswerRecord(key,value)
    if not self.compete_data then
        return 
    end
    if not key or not value then
        return 
    end
    local desc = key == "score" and L"成绩上报成功，请切换试卷页面继续操作" or L"世界提交成功，请切换试卷页面继续操作"
    local currentWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
    local params = {}
    params.competeId = self.compete_data.competeId
    local answerSheetRecordId = self.compete_record_data.id or 0
    local competeQuestionId = self.compete_data.competeQuestionId or 0
    local answerRecord = {
            projectId = currentWorld.kpProjectId,
            answerSheetRecordId = answerSheetRecordId,
            competeQuestionId = competeQuestionId,
            answer = {
                item={
                    {submited = true}
                }
            },
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
            -- commonlib.TimerManager.SetTimeout(function()
            --     self:OpenWebPaperUrl()
            -- end,1000)
        else
            GameLogic.AddBBS("CompetitionManager",L"上报成绩失败，code==="..err)
            echo(msg,true)
            echo(data,true)
        end
    end)
end

function CompetitionManager:UpdateAnswerScore(score)
    self:SubmitAnswerRecord("score",score)
end

function CompetitionManager:UpdateAnswerWorld(commitId)
    self:SubmitAnswerRecord("commitId",commitId)
end



function CompetitionManager:ForceSubmitScore()
    commonlib.TimerManager.SetTimeout(function()
        self:SubmitWorld()
    end,500)
end


function CompetitionManager:DoExitWorld()
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












