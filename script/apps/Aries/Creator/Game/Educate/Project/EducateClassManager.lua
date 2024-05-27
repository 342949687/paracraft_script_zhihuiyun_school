local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KpChatChannel = NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua')

local EducateClassManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager"));

function EducateClassManager:Init()
    self.isWorldLoaded = false
    self.isSwfpageClosed = false
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  EducateClassManager.OnSwfLoadingCloesed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  EducateClassManager.OnSwfLoadingCloesed);

    GameLogic:Disconnect("WorldLoaded", EducateClassManager, EducateClassManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", EducateClassManager, EducateClassManager.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        self.CurrentCreateWorldName = worldPath
        return worldPath
    end)
    GameLogic.GetEvents():RemoveEventListener("createworld_callback",EducateClassManager.CreateWorldCallback, EducateClassManager, "EducateClassManager")
    GameLogic.GetEvents():AddEventListener("createworld_callback", EducateClassManager.CreateWorldCallback, EducateClassManager, "EducateClassManager");
end

function EducateClassManager.CreateWorldCallback(_, event)
    local worldPath = commonlib.Encoding.DefaultToUtf8(event.world_path)
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        EducateClassManager.CurrentCreateWorldName = worldName
    end
end

function EducateClassManager:OnWorldLoaded()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        self.isWorldLoaded = true
        EducateClassManager:CheckClassStatus()
    end,0)
end

function EducateClassManager.OnSwfLoadingCloesed()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        EducateClassManager.isSwfpageClosed = true
        EducateClassManager:CheckClassStatus()
        
    end,0)
end

function EducateClassManager:CheckClassStatus()

end

function EducateClassManager.SetClassData(class_data)
    EducateClassManager.class_data = class_data
end

function EducateClassManager.JoinClassRoom()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    if not not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","EducateClassManager","课堂socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__platformClassroom_EDU_"..classId.."__"
            KpChatChannel.client:Send("app/join",{ rooms = { room }, });

            EducateClassManager.SendJoinRecord()
        end,5*1000)
        return
    end

    local room = "__platformClassroom_EDU_"..classId.."__"
    KpChatChannel.client:Send("app/join",{ rooms = { room }, });
end 

function EducateClassManager.LeaveClassRoom()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    if not not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","EducateClassManager","课堂socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__platformClassroom_EDU_"..classId.."__"
            KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
        end,5*1000)
        return
    end
    local room = "__platformClassroom_EDU_"..classId.."__"
    KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
end


function EducateClassManager.SendJoinRecord()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    --上报加入课堂的记录
    keepwork.classrooms.signin({
        classroomId = (data and data.id) and data.id or 0,
    },function(err,msg,data)
        if err == 200 then 
            -- 上报成功，发送socket通知教师端
            commonlib.TimerManager.SetTimeout(function()
                
            end,2*1000)
        end
    end)
end


local EDU_CONFIG = {
    STAGE = "http://edu-dev.kp-para.cn/",
    RELEASE = "http://edu-rls.kp-para.cn/",
    ONLINE = "https://edu.palaka.cn/",
}
function EducateClassManager.OpenClassWeb()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local userToken = GameLogic.GetFilters():apply_filters("store_get", "user/token")
    userToken = userToken or System.User.keepworktoken
	local http_env = HttpWrapper.GetDevVersion()
    local baseUrl = EDU_CONFIG[http_env]
    local lessonId = EducateClassManager.class_data.lessonId
    local lessonPackageId = EducateClassManager.class_data.lessonPackageId
    local classroomId = EducateClassManager.class_data.id or "0"
    local classroomName = (EducateClassManager.class_data.orgClass and EducateClassManager.class_data.orgClass.name) and EducateClassManager.class_data.orgClass.name or ""
    local openUrl = baseUrl.."?token="..userToken.."&redirect="..Mod.WorldShare.Utils.EncodeURIComponent("/study?lessonId="..lessonId.."&packageId="..lessonPackageId.."&classroomId="..classroomId.."&className="..classroomName)
    if System.os.GetPlatform() == "win32" then
        GameLogic.RunCommand("/open "..openUrl);
        return
    end
    GameLogic.RunCommand("/open -e "..openUrl)
    
end