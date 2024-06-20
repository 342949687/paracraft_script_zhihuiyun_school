--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun.lua");
local ZhiHuiYun = commonlib.gettable("MyCompany.Aries.Game.GameLogic.ZhiHuiYun")
ZhiHuiYun.OnInit()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/HttpApi/ZhiHuiYunHttpApi.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginPage.lua");

local ZhiHuiYun = commonlib.gettable("MyCompany.Aries.Game.GameLogic.ZhiHuiYun")
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local encode_key = "YAAANAGAUAIAYAI"
local ReportFilePath = "temp/zhy_report_log/"
local ReportFileName = ReportFilePath .. "zhy_report_log.txt"
local ZhiHuiYunLoginPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.Login.ZhiHuiYunLoginPage")
local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")
-- 对应服务器那边的channeltype
ZhiHuiYun.ServerChannelType = {
    WEB = 0, -- 网页端注册
    CLIENT = 1, -- 客户端注册
    COMPETITION1 = 2, -- 赛事    后台注册
}

function ZhiHuiYun:OnInit()
    self:InitZhiHuiYunHttpApi()
    self:InitFilters()
    self:InitSchoolConfig()
    self:InitSchoolBlacklist()
    self:InitReport()
end

function ZhiHuiYun:InitZhiHuiYunHttpApi()
    ZhiHuiYunHttpApi.Init()
end

function ZhiHuiYun:InitFilters()
    -- GameLogic.GetFilters():apply_filters("zhihuiyun.school.config", "")
    -- 获取学校配置
    GameLogic.GetFilters():add_filter(
        'zhihuiyun.school.config',
        function(key)
            return self:GetSchoolConfig(key) or "";
        end
    )

    -- GameLogic.GetFilters():apply_filters("zhihuiyun.school.config.name")
    GameLogic.GetFilters():add_filter(
        'zhihuiyun.school.config.name',
        function(key)
            return self:GetSchoolConfig("school_name");
        end
    )

    -- GameLogic.GetFilters():apply_filters("zhihuiyun.school.config.id")
    GameLogic.GetFilters():add_filter(
        'zhihuiyun.school.config.id',
        function(key)
            return self:GetSchoolConfig("school_id");
        end
    )

    -- 上报相关
    GameLogic.GetFilters():add_filter(
        'zhihuiyun.school.record_log',
        function(info)
            info = info or {}
            return self:SetRecordData(info);
        end
    )

        -- 登录相关
        GameLogic.GetFilters():add_filter(
            'zhihuiyun.common.login',
            function()
                if not System.options.ZhyChannel or System.options.ZhyChannel ~= "zhy_competition_course" then
                    return true
                end

                ZhiHuiYunLoginPage.Show()
                return false
            end
        )
end

function ZhiHuiYun:Login(callback, user_data, use_tip)
    if use_tip == nil then
        use_tip = true
    end
    if System.User.zhy_userdata then
        callback(200)
        return
    end

    local headers = {
        ['User-Agent'] = 'Apifox/1.0.0 (https://www.apifox.cn)',
        ['Content-Type'] = 'application/json',
        ['Accept'] = '*/*',
        ['Host'] = 'api.jisiyun.net',
        ['Connection'] = 'keep-alive',
    }

    local data_raw = {
        username= user_data.username,
        password= user_data.password,
    }
    if not System.User then
        System.User = {}
    end

    System.User.zhy_userdata = nil
    System.os.GetUrl({url = "https://api.jisiyun.net/users/login",json=true, method="POST", headers = headers, form=data_raw}, function(err, msg, data)
        print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYun:Login", err)
        echo(data, true)
        echo(data_raw, true)


        if err == 200 then
            System.User.zhy_userdata = data.data
            System.User.zhy_userdata.password = user_data.password
        else
            data = commonlib.Json.Decode(data)
            if data and data.code and data.code ~= 0 then
                System.User.zhy_userdata = nil
                if use_tip then
                    GameLogic.AddBBS(nil, data.message, 3000, '255 0 0')
                end
                
                -- return
            end
        end
        
        if callback then
            callback(err, msg, data)
        end
    end)
end

function ZhiHuiYun:IsLogin()
    return System.User.zhy_userdata ~= nil
end

function ZhiHuiYun:InitSchoolConfig()
    self.SchoolConfig = nil
    -- 先判断根目录有没zhihuiyun_school_config
    local file_name = "zhihuiyun_school_config.txt"
    local cache_filename = CommonLib.MD5(file_name);
    local encode_file_path = "config/" .. cache_filename

    local has_no_encode_file = ParaIO.DoesFileExist(file_name)

    -- 先看看config目录有没有，有的话读取config目录
    if ParaIO.DoesFileExist(encode_file_path) then
        local file = ParaIO.open(encode_file_path,"r")
        if(file:IsValid())then
            local content = file:GetText();
            file:close();
            content = string.gsub(content, encode_key, "")
            content = System.Encoding.unbase64(content)
            content = commonlib.Json.Decode(content)
            self.SchoolConfig = content
            -- print(">>>>>>>>>>>>>>>>>>self.SchoolConfig")
            -- echo(content, true)
        end
        -- 这两个文件同时存在，有问题
        if has_no_encode_file then
            local debug_reason = "The unencrypted file exists"
            
            -- 尝试进行删除，如果删除不了，那说明
            ParaIO.DeleteFile(file_name)
            if ParaIO.DoesFileExist(file_name) then
                debug_reason = "can not delete the unencrypted file"
            end
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>zhihuiyun_debug:" .. debug_reason)
        end        
        -- commonlib.Json.Encode
        -- commonlib.Json.Decode
    elseif has_no_encode_file then
        -- 将根目录的内容转移到config目录
        local file = ParaIO.open(file_name,"r")
        if(file:IsValid())then
            local content = file:GetText();
            file:close();
            content = commonlib.LoadTableFromString(content);
            self.SchoolConfig = content
        end

        if self.SchoolConfig then
            local content = commonlib.Json.Encode(self.SchoolConfig)
            content = encode_key .. System.Encoding.base64(content)
            ParaIO.CreateDirectory(encode_file_path)
            local file = ParaIO.open(encode_file_path, "w");
            if(file) then
                file:write(content, #content);
                file:close();

                ParaIO.DeleteFile(file_name)
            end
        end
    end
end

function ZhiHuiYun:GetSchoolConfig(key)
    if self.SchoolConfig then
        if key and key ~= "" then
            return self.SchoolConfig[key]
        else
            return self.SchoolConfig
        end
    end
end

---------------------------------------------------------------封禁相关
function ZhiHuiYun:CheckSchoolBlacklist()
    -- 有self.SchoolBlacklist说明有网络且请求成功
    local file_name = "temp/zhihuiyun_b_flag"
    if self.SchoolBlacklist then
        local school_name = self:GetSchoolConfig("school_name")
        if school_name then
            if self.SchoolBlacklist[school_name] then
                if not ParaIO.DoesFileExist(file_name) then
                    ParaIO.CreateDirectory(file_name)
                    local file = ParaIO.open(file_name, "w");
                    local content = "1"
                    if(file) then
                        file:write(content, #content);
                        file:close();
                    end
                end
                self:ForceExit()
            elseif ParaIO.DoesFileExist(file_name) then
                ParaIO.DeleteFile(file_name)
            end
        end
    else
        if ParaIO.DoesFileExist(file_name) then
            self:ForceExit()
        end
    end
end

function ZhiHuiYun:InitSchoolBlacklist()
	NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
	local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
    self.SchoolBlacklist = nil
	GameLogic.KeepWork.GetRawFile("https://keepwork.com/yangguiyi/zhihui_version_config/schoolblacklist", function(err, msg, data)
		if(err == 200) then
            if data then
                self.SchoolBlacklist = commonlib.LoadTableFromString(data) or {};
                self:CheckSchoolBlacklist()
            end
		else
            -- 网络请求失败 看看本地文件
            self:CheckSchoolBlacklist()
		end
	end)
end
---------------------------------------------------------------封禁相关/end

function ZhiHuiYun:ForceExit()
    local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
    Desktop.ForceExit(false)
end

---------------------------------------------------------------数据上报相关
function ZhiHuiYun:InitReport()
    -- 比赛版本不需要上报
    if System.options.ZhyChannel ~= "" and string.find(System.options.ZhyChannel, "competition") then
        return
    end
    self:RequestUserData(function()
        self:ReportLog(function()
            self:StartRecordLog()
        end)
    end)
end
-- 上报
--[[
    curl --location --request POST 'http://api.jisiyun.net/upload' \
    header 'User-Agent: Apifox/1.0.0 (https://www.apifox.cn)' \
    header 'Content-Type: application/json' \
    header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcklkIjoxLCJ1c2VybmFtZSI6ImR1a2VzIiwiY2hhbm5lbCI6MCwiaWF0IjoxNjg1MzQ3NDYyfQ.BPF8Mym63m93lgYDKI-_bIuBzWupm-zDGr9LKegbBwA' \
    header 'Accept: */*' \
    header 'Host: api.jisiyun.net' \
    header 'Connection: keep-alive' \
    data-raw '{
        "filename": "H0001/20240110.json",
        "filecontent": "hello world",
        "filetype": "json"
    }'
]]

function ZhiHuiYun:RequestUserData(callback)
    if self.user_data then
        callback()
        return
    end

    local headers = {
        ['User-Agent'] = 'Apifox/1.0.0 (https://www.apifox.cn)',
        ['Content-Type'] = 'application/json',
        ['Accept'] = '*/*',
        ['Host'] = 'api.jisiyun.net',
        ['Connection'] = 'keep-alive',
    }

    local data_raw = {
        username="yangguiyi",
        password="123456",
    }
    System.os.GetUrl({url = "https://api.jisiyun.net/users/login",json=true, method="POST", headers = headers, form=data_raw}, function(err, msg, data)
        -- print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYun:RequestUserData", err)
        -- echo(data, true)
        if err == 200 then
            self.user_data = data.data
        end
        
        if callback then
            callback()
        end
    end)
end

function ZhiHuiYun:GetUserData()
    return self.user_data
end

function ZhiHuiYun:ReportLog(callback)
    if not self.user_data then
        return
    end

    if ParaIO.DoesFileExist(ReportFileName) then
        local file = ParaIO.open(ReportFileName,"r")
        if(file:IsValid())then
            local content = file:GetText();
            file:close();
            local headers = {
                ['User-Agent'] = 'Apifox/1.0.0 (https://www.apifox.cn)',
                ['Content-Type'] = 'application/json',
                ['Accept'] = '*/*',
                ['Host'] = 'api.jisiyun.net',
                ['Connection'] = 'keep-alive',
                ['Authorization'] = 'Bearer ' .. self.user_data.token
            }
    
            local school_id = self:GetSchoolConfig("school_id") or 0
            local file_name = string.format("%s/%s.json", school_id, os.time())
            local data_raw = {
                filename = file_name,
                filecontent = content,
                filetype = "json"
            }
            local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')
            System.os.GetUrl({url = "http://api.jisiyun.net/upload",json=true, method="POST", headers = headers, form=data_raw}, function(err, msg, data)
                if System.options.isZhihuiyunDebug then
                    print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYun:ReportLog", err)
                    echo(data, true)
                end
                if callback then
                    callback()
                end
            end)
        end
    else
        if callback then
            callback()
        end
    end

end

-- 记录
function ZhiHuiYun:StartRecordLog()
    -- 先删除文件
    
    -- if ParaIO.DoesFileExist(ReportFileName) then
    --     ParaIO.DeleteFile(ReportFileName)
    -- end
    -- 处理数据
    self.login_time_stamp = os.time()
    self.record_data = {
        -- 登录时间
        school_name = self:GetSchoolConfig("school_name") or "",
        login_time = os.date("%Y-%m-%d %H:%M:%S", self.login_time_stamp),
        login_duration = 0,--秒
        micropython_machine_id = 0, --固件ID
        lan_ip_address = NPL.GetExternalIP(),-- 局域网的ip信息
        ip_address = "",
        micropython_code_run_info = {}, -- 烧录代码信息
        machine_info = {}, -- 硬件信息
        course_info = {},
    }

    self:GetIpInfo(function(ip_info)
        self.record_data.ip_address = ip_info.ip
        self:RecordLog()
    end)
    self:GetMachineInfo(function(machine_info)
        self.record_data.machine_info = machine_info
        self:RecordLog()
    end)

    -- 记录登录时长
	-- 定时器
	local tickDuration = 1000 * 60 * 2;  -- 2 min
	-- local tickDuration = 1000 * 20;   -- debug
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
        self.record_data.login_duration = os.time() - self.login_time_stamp
		self:RecordLog()
	end});
	self.timer:Change(tickDuration, tickDuration); -- 两分钟触发一次
end

-- GameLogic.GetFilters():apply_filters("zhihuiyun.school.record_log", {type = "add",key="course_info",item_key=select_data_name, value={course_name=select_data_name, time = os.date("%H:%M:%S", os.time())}})
-- 如果type == add 那将记录多条数据 跟item_key字段配合使用 有item_key会记录到item_key指定位置，没有item_key的话则变成数组自动增量
function ZhiHuiYun:SetRecordData(info)
    local key, value, record_type, item_key = info.key, info.value, info.type, info.item_key
    if not self.record_data or not key or not value then
        return
    end

    if record_type and record_type == "add" then
        local key_data = self.record_data[key] or {}
       
        if key_data and type(key_data) == "table" then
            if item_key then
                key_data[item_key] = value
            else
                key_data[#key_data + 1] = value
            end
            self.record_data[key] = key_data
        else
            self.record_data[key] = value
        end
    else
        self.record_data[key] = value
    end

    -- self.record_data[key] = value
    self:RecordLog()
end

-- 获取硬件信息
function ZhiHuiYun:GetIpInfo(callback)
    -- https://api.ipify.org/?format=json
    System.os.GetUrl("https://api.ipify.org/?format=json", function(err, msg, data)
        if err == 200 then
            if callback then
                callback(data)
            end
        end
    end)
end

-- 获取硬件信息
function ZhiHuiYun:GetMachineInfo(callback)
    local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
    local str_arr = {
        { "osInfo","系统信息","wmic os get ","caption,systemDrive,version,buildNumber" },
        { "cpuInfo","CPU信息","wmic cpu get ","name,manufacturer,maxClockSpeed,processorid" },
        { "memoryInfo","内存信息","wmic memorychip get ","deviceLocator,speed,manufacturer,capacity" },
        { "gpuInfo","显卡信息","wmic path win32_videoController get ","name,adapterRAM" },
    }
    local retMap = {}
    local len = 0
    local acc = 0
    for _,obj in pairs(str_arr) do
        local name = obj[1]
        local cmd = obj[3]
        local keys = commonlib.split(obj[4],",")
        retMap[name] = {}
        for i=1,#keys do 
            local key = string.lower(keys[i])
            keys[i] = key
            
            local cmdStr = cmd..key 
            len = len + 1
            ParaGlobal.ShellExecute("popen",cmdStr,"isAsync",LuaCallbackHandler.createHandler(function(msg)
                local vals_arr = {};
                local out = msg.ret;
                local arr1 = commonlib.split(out,"\n")
                for j=#arr1,1,-1 do
                    if arr1[j]=="" then
                        table.remove(arr1,j)
                    else
                        arr1[j] = arr1[j]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
                    end
                end
                if #arr1>0 then
                    local name1 = string.lower(arr1[1])
                    if key==name1 then
                        for k=2,#arr1 do
                            local val = arr1[k]
                            table.insert(vals_arr,val)
                        end
                    end
                    retMap[name][key] = vals_arr
                end
                acc = acc + 1
                if acc==len then
                    local newRet = {}
                    for _name,_map in pairs(retMap) do
                        local keys = {}
                        for k,vals in pairs(_map) do
                            table.insert(keys,k)
                        end
                        local newArr = {}
                        if #keys>0 then
                            local vals_size = #_map[keys[1]]
                            
                            for j=1,vals_size do
                                local temp = newArr
                                if vals_size>1 then
                                    temp = {}
                                    newArr[j] = temp
                                end
                                for key,vals in pairs(_map) do
                                    temp[key] = ParaMisc.EncodingConvert("gb2312", "utf-8", vals[j])
                                end
                            end
                        end
                        newRet[_name] = newArr
                    end
                    -- print("=======newRet")
                    -- echo(newRet,true)
                    local g = 1024*1024*1024
                    if newRet.gpuInfo.adapterram and tonumber(newRet.gpuInfo.adapterram) then
                        newRet.gpuInfo.adapterram = (math.floor(tonumber(newRet.gpuInfo.adapterram)/g*10)/10).."G"
                    end
                    -- for k,v in pairs(newRet.diskInfo) do
                    --     if v.freespace and tonumber(v.freespace) then
                    --         v.freespace = (math.floor(tonumber(v.freespace)/g*10)/10).."G" --剩余空间
                    --     end
                    --     if v.size and tonumber(v.size) then
                    --         v.size = (math.floor(tonumber(v.size)/g*10)/10).."G" --大小
                    --     end
                    -- end
                    
                    for k,v in pairs(newRet.memoryInfo) do
                        if v.capacity and tonumber(v.capacity) then
                            v.capacity = (math.floor(tonumber(v.capacity)/g*10)/10).."G" --大小
                        end
                    end
                    -- print("test log-----规范化")
                    -- echo(newRet,true)
                    if preInfo and type(preInfo) == "table" then
                        for k,v in pairs(preInfo) do
                            newRet[k] = v
                        end
                    end

                    if callback then
                        callback(newRet)
                    end
                end
            end));
        end
    end
end
-- 写入硬盘
function ZhiHuiYun:RecordLog()
    if not self.record_data then
        print(">>>>>>>>>>>>>>>>>>>>>>zhyError:not record_data")
        return
    end

    local content = commonlib.Json.Encode(self.record_data)
    ParaIO.CreateDirectory(ReportFileName)
    local file = ParaIO.open(ReportFileName, "w");
    -- print("bbbbbbbbbbbbxxxx", file:Is)
    if(file) then
        file:write(content, #content);
        file:close();
    end
end

---------------------------------------------------------------数据上报相关/end


---------------------------------------------------------------赛事相关
function ZhiHuiYun:EnterCompetition()
    local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
    local password = PWDInfo.password or PWDInfo.remember_pwd
    if not PWDInfo or not PWDInfo.account or not password then
        return
    end
    local login_data = {username = PWDInfo.account, password = password}
    self:Login(function(err, msg, data)
        if not System.User.zhy_userdata then
            self:ForceExit()
            return
        end

        if System.options.ZhyChannel == "zhy_competition" and System.User.zhy_userdata.channel ~= ZhiHuiYun.ServerChannelType.COMPETITION1 then
                _guihelper.MessageBox("参赛身份不正确", function()
                    self:ForceExit()
                end, _guihelper.MessageBoxButtons.OK)
            return
        end

        if System.options.AutoEnterPid and System.options.AutoEnterPid ~= "" then
            GameLogic.RunCommand(format('/loadworld -s -force %s', System.options.AutoEnterPid))
        else
            _guihelper.MessageBox("没有指定赛事项目id", function()
                self:ForceExit()
            end, _guihelper.MessageBoxButtons.OK)
        end
        
    end, login_data)
end

function ZhiHuiYun:EnterCompetitionProgramChecker()
    local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
    local PWDInfo = KeepworkServiceSession:LoadSigninInfo()
    local password = PWDInfo.password or PWDInfo.remember_pwd
    if not PWDInfo or not PWDInfo.account or not password then
        return
    end
    local login_data = {username = PWDInfo.account, password = password}
    self:Login(function(err, msg, data)
        if not System.User.zhy_userdata then
            self:ForceExit()
            return
        end

        NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/ProgramChecker/ProgramCheckerPage.lua");
        local ProgramCheckerPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerPage")
        ProgramCheckerPage.Show()
        
    end, login_data)
end
---------------------------------------------------------------赛事相关/end