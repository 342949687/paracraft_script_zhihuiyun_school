--[[
Author: wxa
Date: 2020-10-26
Desc: 冬令营开幕式 
-----------------------------------------------
local WinterCamp = NPL.load("Mod/GeneralGameServerMod/Tutorial/Demo/WinterCamp.lua");

世界ID release: 1471  online: 41570

电影匹配的代码方块前缀代码
```lua
setMovie("MovieChannelName", 0, 0, 0);  -- 参数根据实际改之
getActor():SetName("ActorName");        -- 演员名 
```

更新 ggs 模块代码, 拷贝本文件内容至代码方块
开幕配声文件放置 assets/school_xxx.ogg (xxx 为学校ID) 默认配声文件 assets/principal_speech.ogg
响铃声音文件放置 assets/ring.mp3   Note: 文件都是相对当前世界根目录
开幕动画电影频道 OpeningCeremony
开幕电影激活按钮方块位置 OpeningCeremonyMovieActiveBlockPos = {x = 0, y = 0, z = 0};    更改x,y,z 为正确位置
开幕动画电影时长 OpeningCeremonyTime=10  -- 单位秒
导游电影激活按钮方块位置  GuideMovieActiveBlockPos = {x = 0, y = 0, z = 0};             更改x,y,z 为正确位置
导游演员名称: guide 
导游动画电影频道: GuideMovie 

指定时间测试, 解除 IsDevEnv=true 的注释, 更新 local ServerTimeStamp = os.time({year=2021, month=1, day=25, hour=10, min=35, sec=57, isdst=false}) * 1000; 中时间值为服务器时间的起始值
-----------------------------------------------
]]

local IsDevEnv = true;
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua", IsDevEnv);
local KeepworkAPI = TutorialSandbox:GetKeepworkAPI();
local MessageBox = TutorialSandbox:GetSystemMessageBox();
local ServerTimeStamp = os.time({year=2021, month=1, day=25, hour=10, min=59, sec=50, isdst=false}) * 1000;
local ClientTimeStamp = TutorialSandbox:GetTimeStamp();
local GuideActorName = "guide";
local GuideMovieActiveBlockPos = {x = 19327, y = 12, z = 19462};                      -- 19327,12,19462
local OpeningCeremonyMovieActiveBlockPos = {x = 19139, y = 12, z = 19189};            -- 19139,12,19189
local OpeningCeremonyTime = 150;
local WinterCamp = gettable("WinterCamp");

TutorialSandbox:Reset(nil, false);

function GetCurrentTimeStamp()
    return TutorialSandbox:GetTimeStamp() - ClientTimeStamp + ServerTimeStamp;
end

-- {year=2021, month=1, day=18, hour=18, min=3, sec=28, wday=2, yday=18, isdst=false}
function GetCurrentDateObject()
    return os.date("*t", math.floor(GetCurrentTimeStamp() / 1000));
end

-- 获取一天内的秒数
function GetDaySecond()
    local curdate = GetCurrentDateObject(curdate);
    return curdate.hour * 3600 + curdate.min * 60 + curdate.sec;
end

-- 冬令营开幕
function IsWinterCampStartDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and curdate.month == 1 and curdate.day == 25;
end

-- 冬令营上课
function IsWinterCampAttendClassDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and ((curdate.month == 1 and curdate.day >= 25) or (curdate.month == 2 and curdate.day < 6));
end

-- 冬令营结束
function IsWinterCampEndDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and curdate.month >= 2 and curdate.day >= 6;
end

-- 是否是vip学校学生
function IsVipSchoolStudent()
    return TutorialSandbox:GetSystemUser().isVipSchool;
end

-- 是否允许进入会场
function IsAllowInAuditorium()
    return IsVipSchoolStudent() or IsVip() or false;
end

-- 是否是vip
function IsVip()
    return TutorialSandbox:GetSystemUser().isVip;
end

-- 学校ID
function GetSchoolId()
    return TutorialSandbox:GetUserInfo().schoolId or 0;
end

-- 播放导游电影
function PlayGuideMovies()
    local movieBlockPosList = {
        -- 导游电影方块坐标列表
        19328,10,19464,
        19328,10,19463,
        -- ...
        19328,10,19455,
    };
    for _, pos in ipairs(movieBlockPosList) do
        setMovie("curmovie", pos[1], pos[2], pos[3]);
        playMovie("curmovie",  0,  -1);
        stopMovie("curmovie");
    end
end

registerBroadcastEvent("PlayGuideMovies", function(msg)
    PlayGuideMovies();
end);

-- 播放开幕电影
function PlayOpeningCeremonyMovies()
    local movieBlockPosList = {
        -- 导游电影方块坐标列表
        19328,10,19464,
        19328,10,19463,
        -- ...
        19328,10,19455,
    };
    for _, pos in ipairs(movieBlockPosList) do
        setMovie("curmovie", pos[1], pos[2], pos[3]);
        playMovie("curmovie",  0,  -1);
        stopMovie("curmovie");
    end
end

registerBroadcastEvent("PlayOpeningCeremonyMovies", function(msg)
    PlayOpeningCeremonyMovies();
end);

-- 开营典礼
function WinterCamp:OpeningCeremony(second)
    TutorialSandbox:SetKeyboardMouse(false, false);
    -- 播放声音
    local filename = string.format("school_%s.ogg", GetSchoolId());
    if (not TutorialSandbox:IsExistFile(filename)) then filename = "assets/principal_speech.ogg" end
    -- print(string.format("开幕典礼, 开始时间 = %ss 声音文件 = %s", second, filename));
    -- playSound(filename, nil, second);
    playSound(filename);
    -- 播放动画
    if (IsAllowInAuditorium()) then
        -- playMovie("OpeningCeremony", second * 1000, -1);
        -- stopMovie("OpeningCeremony");
        -- TutorialSandbox:ActivateBlock(OpeningCeremonyMovieActiveBlockPos.x, OpeningCeremonyMovieActiveBlockPos.y, OpeningCeremonyMovieActiveBlockPos.z);
        -- wait(OpeningCeremonyTime);
        PlayOpeningCeremonyMovies();
    end
    TutorialSandbox:SetKeyboardMouse(true, true);
end

-- 开始开幕式
function WinterCamp:StartOpeningCeremony()
    local sounds = {};
    local seconds = {
        10 * 3600 + 20 * 60,  -- 10:20:00 
        10 * 3600 + 28 * 60,  -- 10:28:00 
        10 * 3600 + 30 * 60,  -- 10:30:00 

        13 * 3600 + 20 * 60,  -- 13:20:00 
        13 * 3600 + 28 * 60,  -- 13:28:00 
        13 * 3600 + 30 * 60,  -- 13:30:00 
        
        15 * 3600 + 50 * 60,  -- 15:50:00 
        15 * 3600 + 58 * 60,  -- 15:58:00 
        16 * 3600 + 0 * 60,   -- 16:00:00 
        
        17 * 3600 + 50 * 60,  -- 17:50:00 
        17 * 3600 + 58 * 60,  -- 17:58:00 
        18 * 3600 + 0 * 60,   -- 18:00:00 
    }
    local sounds = {};
    -- 主逻辑循环
    while(true) do 
        local second = GetDaySecond();
        local waitSecond, soundNo = 600, nil;
        for i = 1, #seconds do
            if (i % 3 == 0 and second >= seconds[i] and second < (seconds[i] + 600)) then
                soundNo, waitSecond = i, 1;
                break;
            elseif (i % 3 > 0 and math.abs(seconds[i] - second) < 5) then
                soundNo, waitSecond = i, 20;
                break;
            else
                soundNo, waitSecond = nil, 600;
            end
            if (seconds[i] > second) then
                soundNo, waitSecond = nil, seconds[i] - second;
                break;
            end
        end
        -- print(string.format("StartOpeningCeremony wait = %ss sound_no = %s", waitSecond, soundNo));
        if (soundNo ~= nil) then
            local no = math.ceil(soundNo / 2);
            local sound = sounds[no] or {};
            sounds[no] = sound;
            if (soundNo % 3 == 1 and not sound.isStartBefore10Minute) then 
                tip("冬令营开营典礼马上就要开始了，请尽快前往大礼堂")
                playSound("assets/ring.mp3");
                sound.isStartBefore10Minute = true;
            elseif (soundNo % 3 == 2 and not sound.isStartBefore2Minute) then
                tip("冬令营开营典礼将在两分钟后开始，请尽快前往大礼堂")
                playSound("assets/ring.mp3");
                sound.isStartBefore2Minute = true;
            elseif (soundNo % 3 == 0) then
                self.isOpeningCeremonyTime, self.openingCeremonyTimeSecond, self.openingCeremonyNo = true, seconds[soundNo], math.ceil(soundNo / 3);
                if (not sound.isOpeningCeremony) then
                    self:OpeningCeremony(second - self.openingCeremonyTimeSecond);
                    sound.isOpeningCeremony = true;
                end
                local remainSecond = seconds[soundNo] + 600 - GetDaySecond();   -- 10 分钟剩余的秒数
                if (remainSecond > 0) then wait(remainSecond) end
                self.isOpeningCeremonyTime, self.openingCeremonyTimeSecond, self.openingCeremonyNo = false, nil, nil;
            else
            end
        end
        wait(waitSecond);
    end
end

-- 随机开幕式位置
function WinterCamp:RandomOpeningCeremonyPosition()
    -- （19223,12,19250）附近，X、Z（+/- 3）
    local x = math.random(19220, 19226);
    local y = 12;
    local z = math.random(19247, 19253);
    TutorialSandbox:SetPlayerBlockPos(x, y, z);
end

-- 禁飞检测
function WinterCamp:ForbidFlyCheck()
    run(function()
        while(true) do
            local x, y, z = TutorialSandbox:GetPlayerBlockPos();
            local isInnerAuditorium = false;
            if (x >= 19241 and x <= 19285 and z >= 19230 and z <= 19270) then isInnerAuditorium = true end
            TutorialSandbox:SetCanFly(not isInnerAuditorium);
            if (isInnerAuditorium and not IsAllowInAuditorium()) then 
                -- 不允许进入会场
                TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                MessageBox("冬令营就要开始了！你所在的学校已经有128名同学报名了冬令营的会员活动！你也快来参加吧！", function(res)
                    if(res == 6) then
                        -- GameLogic.GetFilters():apply_filters("cellar.vip_notice.init");
                        -- GameLogic.GetFilters():apply_filters("VipNotice", true, "vip_wintercamp1_join", function() end);
                        local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
                        MacroCodeCampActIntro.ShowView();
                    end
                end, 10, nil,nil,nil,nil, {ok = "我要报名"});
            elseif (isInnerAuditorium and IsAllowInAuditorium()) then
                -- 允许进入会场
                if (self.isOpeningCeremonyTime) then
                    if (self.isJoinOpeningCeremony == nil) then
                        local second = GetDaySecond();
                        if ((second - self.openingCeremonyTimeSecond) < 300) then
                            self.isJoinOpeningCeremony = true;
                            -- 随机位置
                            self:RandomOpeningCeremonyPosition();
                        else
                            TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                            self.isJoinOpeningCeremony = false;
                            if (self.openingCeremonyNo < 4) then
                                MessageBox("你已迟到五分钟，请下一场再进来，切记不可再迟到");
                            else
                                MessageBox("你已迟到五分钟，错过了开营典礼。明天上课请不要再迟到了！");
                            end
                        end
                    else
                        -- print(self.isJoinOpeningCeremony and "正在参加开幕典礼" or "迟到太久无法进入");
                        TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                    end
                else
                    self.isJoinOpeningCeremony = nil;
                end
            end

            wait(1);
        end
    end)
    
    -- 这个会场最好四面都有隐形墙比较好, 程序检测都是隔几秒检测一次, 这个间隔时间由于用户飞行过快很容易就飞进去了    
end

-- 导游
function WinterCamp:GuideLogic()
    local actor = getActor(GuideActorName);
    while(not actor) do
        wait(2);
        actor = getActor(GuideActorName);
    end

    local guides = {};
    local seconds = {
        10 * 3600 + 45 * 60,  -- 10:45:00 11:00:00
        11 * 3600 + 15 * 60,  -- 11:15:00 11:30:00
        12 * 3600 + 15 * 60,  -- 12:15:00 12:30:00
        13 * 3600 + 45 * 60,  -- 13:45:00 14:00:00
        14 * 3600 + 15 * 60,  -- 14:15:00 14:30:00
        15 * 3600 + 15 * 60,  -- 15:15:00 15:30:00
        16 * 3600 + 15 * 60,  -- 16:15:00 16:30:00
        16 * 3600 + 45 * 60,  -- 16:45:00 17:00:00
        18 * 3600 + 15 * 60,  -- 18:15:00 18:30:00
        18 * 3600 + 45 * 60,  -- 18:45:00 19:00:00
    }
    local _15min = 15 * 60;
    runForActor(actor, function()
        while (true) do
            local second = GetDaySecond();
            local waitSecond, remainMinute, guideNo = 600, 0, nil;

            for i = 1, #seconds do
                if (second > seconds[i] and (seconds[i] + _15min) >= second) then
                    guideNo = i;
                    waitSecond = 60;
                    local remainWaitSecond = _15min + seconds[i] - second;  -- 剩余秒数
                    
                    remainMinute = math.floor(remainWaitSecond / 60);
                    remainWaitSecond = remainWaitSecond % 60;
                    if (remainWaitSecond > 0) then wait(remainWaitSecond) end

                    break; 
                end
                if (seconds[i] > second) then
                    waitSecond = seconds[i] - second;
                    break;
                end
            end
            
            -- print(string.format("wait = %ss, guide_no = %s", waitSecond, guideNo));

            if (guideNo) then
                local guide = guides[guideNo] or {};
                guides[guideNo] = guide;

                if (not guide.isFinish) then
                    guide.isFinish = true;
                end

                if (actor) then
                    actor:SetBlockPos(19263,14,19250);
                end
                
                for i = 1, remainMinute do
                    if (i % 2 == 1) then
                        say("游学活动就要开始了啦");
                    else
                        say("同学们请做好准备！");
                    end
                    wait(60);
                end

                -- 激活导游电影 
                -- playMovie("GuideMovie", 0, -1);
                -- stopMovie("GuideMovie");
                TutorialSandbox:ActivateBlock(GuideMovieActiveBlockPos.x, GuideMovieActiveBlockPos.y, GuideMovieActiveBlockPos.z);

            end
            
            wait(waitSecond);
        end
    end)
    
end

-- 冬令营逻辑开始
function WinterCamp:Start()
    -- print("current date", os.date("%Y-%m-%d %H:%M:%S", GetCurrentTimeStamp() / 1000));

    -- 导游
    run(function() 
        self:GuideLogic(actor);
    end);
    
    if (IsWinterCampStartDate()) then
        -- print("=========================OpeningCeremonyDate=========================")
        self.isJoinOpeningCeremony = nil;
        self:ForbidFlyCheck();
        self:StartOpeningCeremony();
    end
    if (IsWinterCampAttendClassDate()) then
        -- print("=========================AttendClassDate=========================")
        self:AttendClassRingCheck();
    elseif (IsWinterCampEndDate()) then
    
    else
    
    end
end

-- 上课铃检测
function WinterCamp:AttendClassRingCheck()
    local sounds = {};
    local seconds = {
        10 * 3600 + 20 * 60,  -- 10:20:00 
        10 * 3600 + 28 * 60,  -- 10:28:00 
        11 * 3600 + 20 * 60,  -- 11:20:00 
        11 * 3600 + 28 * 60,  -- 11:28:00 
        13 * 3600 + 50 * 60,  -- 13:50:00 
        13 * 3600 + 58 * 60,  -- 13:58:00 
        17 * 3600 + 50 * 60,  -- 17:50:00 
        17 * 3600 + 58 * 60,  -- 17:58:00 
    }
    run(function()
        local second = GetDaySecond();
        local waitSecond, soundNo = 600, nil;
        for i = 1, #seconds do
            if (math.abs(seconds[i] - second) < 5) then  -- 误差10s
                soundNo = i;
                waitSecond = 20;
                break;
            end
            if (seconds[i] > second) then
                waitSecond = seconds[i] - second;
                break;
            end
        end
        -- print(string.format("AttendClassRingCheck wait = %ss sound_no = %s", waitSecond, soundNo));
        if (soundNo ~= nil) then
            local no = math.ceil(soundNo / 2);
            local sound = sounds[no] or {};
            sounds[no] = sound;
            if (soundNo % 2 == 1 and not sound.isStartBefore10Minute) then 
                tip("马上就要开始上课了, 请大家尽快前往教学楼集合!")
                playSound("assets/ring.mp3");
                sound.isStartBefore10Minute = true;
            elseif (soundNo % 2 == 0 and not sound.isStartBefore2Minute) then
                tip("两分钟后就要开始上课了, 请大家尽快前往教学楼集合!")
                playSound("assets/ring.mp3");
                sound.isStartBefore2Minute = true;
            else
            end
        end
        wait(waitSecond);
    end)
end

-- 获取服务器时间
local function Main()
    if (IsDevEnv) then return WinterCamp:Start() end

    KeepworkAPI:Get("keepworks/currentTime"):Then(function(response)
        -- 请求成功
        local data = response.data;
        ServerTimeStamp = data.timestamp;
        ClientTimeStamp = TutorialSandbox:GetTimeStamp();

        WinterCamp:Start();
    end):Catch(function(response)
        -- 请求失败
    end);
end

registerStopEvent(function()
    TutorialSandbox:Restore();
end);


Main();