--[[
Title: educate Competition utils
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
-------------------------------------------------------
]]
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local CompetitionUtils = NPL.export()

function CompetitionUtils.IsLogined()
    return GameLogic.GetFilters():apply_filters('is_signed_in')
end

function CompetitionUtils.GetServerTime()
    if GameLogic.IsDevMode() then
        return os.time()
    end
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return time_stamp or os.time()
end

function CompetitionUtils.ZipWorld(zip_file_name)
    GameLogic.QuickSave();
    local world_dir = GameLogic.GetWorldDirectory()
    local SystemUserName = commonlib.getfield("System.User.username")
    local userName = GameLogic.GetFilters():apply_filters("store_get", "user/username");
    local extend_name = ".zip"
    local zip_name 
    if zip_file_name and zip_file_name ~= "" then
        zip_name = zip_file_name
    else
        zip_name = os.date('%m%d', CompetitionUtils.GetServerTime()).."_jiao_yu_ji_jin_exam_world"
        if userName and userName ~= "" then
            zip_name = zip_name.."_"..userName..extend_name
        elseif SystemUserName and SystemUserName ~= "" then
            zip_name = zip_name.."_"..SystemUserName..extend_name
        end
    end
    
    local work_name = zip_name
    local zip_path = Files.GetTempPath() .. zip_name
    zip_path = commonlib.Encoding.Utf8ToDefault(zip_path)
    NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
    local ZipFile = commonlib.gettable("System.Util.ZipFile");
    local zipFile = ZipFile:new();
    if (zipFile:open(zip_path, "w")) then
        zipFile:AddDirectory("exam_world/", world_dir .. "*.*", 10);
        zipFile:ZipAddData("exam_world/Judges.txt", "true");
        zipFile:close();
        return zip_path
    end
    return ""
end

--文件路径和文件名
function CompetitionUtils.UpLoadFileToQiNiu(filepath, filename,isUpWorld,call_back_func)
    local function uploadFile(filepath, filename,userId)
        local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector")
        local time = CompetitionUtils.GetServerTime()
        local md5 = GameMemoryProtector.hash_func_md5(filename .. time)
        local key
        if isUpWorld then
            key= string.format("world-share-%s-%s.zip", userId, md5)
        else
            key = filename
        end

        CompetitionApi.GetSharedToken({
            router_params = {
                id = key
            }
        },function(err,msg,data)
            if err == 200 then
                local token = data.data.token
                local content
                local file = ParaIO.open(filepath, "rb");
                if (not file:IsValid()) then
                    file:close();
                    return;
                end
                content = file:GetText(0, -1);
                GameLogic.GetFilters():apply_filters('qiniu_upload_file', token, key, filename, content,function(result, upcode)
                    if upcode ~= 200 then
                        call_back_func(false,upcode,"提交失败，七牛文件上传失败")
                        return;
                    end
                    local url = "https://qiniu-public-temporary.keepwork.com/" .. key
                    if isUpWorld then
                        local baseUrl = "https://webparacraft.keepwork.com?worldfile="
                        local httpwrapper_version = HttpWrapper.GetDevVersion();
                        if httpwrapper_version == "STAGE" or httpwrapper_version == "RELEASE" then
                            url = "https://qiniu-public-temporary-dev.keepwork.com/" .. key
                            baseUrl = "https://emscripten.keepwork.com?worldfile="
                        end
                        url = commonlib.Encoding.url_encode(url)
                        url = baseUrl..url
                    end
                    call_back_func(true,url)                    
                end)
            else
                call_back_func(false,err,"获取文件token失败，请重试")
            end
        end)
    end
    if CompetitionUtils.IsLogined() then
        local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
        uploadFile(filepath, filename,userId)
    else
        GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
            local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
            uploadFile(filepath, filename,userId)
        end)
    end
end

function CompetitionUtils.GetTimeFormat(startTime,endTime)
    local startTimestamp,endTimestamp,startTimeStr,endTimeStr
    startTimestamp = commonlib.timehelp.GetTimeStampByDateTime(startTime)
    startTimeStr = os.date("%Y-%m-%d %H:%M:%S",startTimestamp)
    endTimestamp = commonlib.timehelp.GetTimeStampByDateTime(endTime)
    endTimeStr = os.date("%Y-%m-%d %H:%M:%S",endTimestamp)

    return startTimeStr.."~"..endTimeStr,startTimestamp,endTimestamp
end

function CompetitionUtils.GetTimeFormatWithSpacing(timeStr)
    local startTimestamp = commonlib.timehelp.GetTimeStampByDateTime(timeStr)
    local startTimeStr = os.date("%Y-%m-%d  %H:%M",startTimestamp)
    return startTimeStr,startTimestamp
end

function CompetitionUtils.GetTimeFormatStr(time_stamp)
    local time_stamp = time_stamp or 0
    local day = math.floor(time_stamp / 86400)
	local hour = math.floor((time_stamp - day * 86400) / 3600)
	local min = math.floor((time_stamp - day * 86400 - hour * 3600) / 60)
	local second = time_stamp - day * 86400 - hour * 3600 - min * 60
    if day > 0 then
        return string.format("%02d天%02d时%02d分%02d秒",day,hour,min,second)
    end
    if hour > 0 then
        return string.format("%02d时%02d分%02d秒",hour,min,second)
    end
    if min > 0 then
        return string.format("%02d分%02d秒",min,second)
    end
    return string.format("%02d秒",second)
end

function CompetitionUtils.GetWebParacraftUrl(type)
    local baseUrl = "https://webparacraft.keepwork.com?http_env=ONLINE"
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == "STAGE" or httpwrapper_version == "RELEASE" then
        baseUrl = "https://emscripten.keepwork.com?http_env="..httpwrapper_version
    end
    if type and type == "world" then
        return baseUrl.."&worldfile="
    end

    if type and type == "pid" then
        return baseUrl.."&pid="
    end
    return baseUrl
end



