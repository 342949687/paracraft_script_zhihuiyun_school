--[[
Title: Paracraft debug
Author(s): LiXizhi
Date: 2021/12/5
Desc: for printing logs in main thread, this is a singleton class.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");
local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
ParacraftDebug:Connect("onMessage", function(errorMsg, stackInfo)   end);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local ParacraftDebug = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug"));

--  function(errorMsg, stackInfo)   end
ParacraftDebug:Signal("onMessage");

function ParacraftDebug:ctor()
	ParacraftDebug.Restart()
end

-- static function 
function ParacraftDebug.Restart()
	commonlib.debug.SetNPLRuntimeErrorCallback(ParacraftDebug.OnNPLErrorCallBack)
	if(commonlib.debug.SetNPLRuntimeDebugTraceLevel) then
		commonlib.debug.SetNPLRuntimeDebugTraceLevel(5);
	end
end

function ParacraftDebug.OnNPLErrorCallBack(errorMessage)
	log(errorMessage);
	local stackInfo;
	if(type(errorMessage) == "string") then
		local title;
		title, stackInfo = errorMessage:match("^([^\r\n]+)\r?\n(.*)$")
		if(stackInfo) then
			errorMessage = title;
		end
	end
	ParacraftDebug:onMessage(errorMessage, stackInfo);

	ParacraftDebug:SendErrorLog("NplRuntimeError", {
		errorMessage = errorMessage,
		stackInfo = stackInfo,
	})
end

--检查有没有错误日志文件（crash时会复制一份到temp/log.crash.txt），有的话读取最后面的200行，上报
function ParacraftDebug:CheckSendCrashLog()
	if not (keepwork and keepwork.burieddata and keepwork.burieddata.uploadLog) then
		return
	end
	local writablePath = ParaIO.GetWritablePath()
	local path = writablePath.."temp/log.crash.txt"
	local bakPath = writablePath.."temp/log.crash.txt.bak"
	if ParaIO.DoesFileExist(path) then
		LOG.std(nil,"info","ParacraftDebug","proccessing and uploading temp/log.crash.txt")
		local file = ParaIO.open(path,"r")
		if not file:IsValid() then
			return
		end
		local filesize = file:GetFileSize();
		local trailingCharCount = 3000;
		local str = file:GetText(math.max(0, filesize - trailingCharCount), math.max(-filesize, -trailingCharCount))
		file:close();
		local arr = commonlib.split(str,"\r\n")
		
		local uselessLines = {
			"unload unused asset file",
			"gateway/events/send",
		}
		
		local acc = 0
		local retTab = {}
		for i=#arr ,1,-1 do
			local line = arr[i]
			local skip = false
			for k,v in pairs(uselessLines) do
				if string.find(line,v) then
					skip = true
					break;
				end
			end
			if not skip then
				acc = acc + 1
				table.insert(retTab,line)
			end
			if acc==400 then
				break
			end
		end

		local errlog = table.concat(retTab,"\r\n")
		self:SendErrorLog("CrashErr",{
			logtxt = errlog
		})

		-- backup the file
		ParaIO.MoveFile(path,bakPath)
	end
end

local _errorMessageSet = {}
-- send runtime error log to our log service
function ParacraftDebug:SendErrorLog(logType,obj)
	if type(obj)~="table" then
		return
	end
	if not (keepwork and keepwork.burieddata and keepwork.burieddata.uploadLog) then
		return
	end
	if obj.errorMessage and obj.errorMessage:match("bad allocation") then
		collectgarbage("collect");
	end

	GameLogic.GetFilters():apply_filters('on_error_report')
	local recordKey = string.gsub(obj.stackInfo or "","[^0-9a-zA-Z]+","")
	if _errorMessageSet[recordKey] then
		if System.options.isDevMode then
			print("------重复的报错不上传",recordKey)
			echo(obj,true)
		end
		return
	end
	_errorMessageSet[recordKey] = true

	if System.options.isDevMode and logType~="DevDebugLog" then
		print("-------isDevMode不发送错误日志:",logType)
		echo(obj,true)
		return
	end

	obj.ip = NPL.GetExternalIP()
    obj.machineID = GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID', ''))
    obj.version = GameLogic.options.GetClientVersion()
    obj.channelId = System.options.channelId
    obj.commandLine = ParaEngine.GetAppCommandLine()
    obj.isDevEnv = System.options.isDevEnv
    obj.isDevMode = System.options.isDevMode
    obj.mc = System.options.mc
	obj.platform = System.os.GetPlatform()

	obj.cur_worldPath = GameLogic.GetWorldDirectory()

	local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
	local curProjectId = world_data and world_data.kpProjectId
	obj.cur_worldId = curProjectId

	if obj.platform=="android" or obj.platform=="ios" or obj.platform=="mac" then
        local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
        local sysInfo = PlatformBridge.getDeviceInfo() 
        local appInfo = PlatformBridge.getAppInfo()

        for k,v in pairs(appInfo) do
			if obj[k]==nil then
            	obj[k] = v
			end
        end
		for k,v in pairs(sysInfo) do
			if obj[k]==nil then
            	obj[k] = v
			end
        end
    end

	local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
	if SessionsData then
		local bak_sessions = SessionsData:GetSessions()
		if bak_sessions then
			obj.softwareUUID = bak_sessions.softwareUUID
			obj.account_curent = bak_sessions.selectedUser
		end
	end

	keepwork.burieddata.uploadLog({
        type = logType,
        logs = {obj}
    },function(err,msg,data)
        if System.options.isDevMode then
            print("send npl error log resp,code=",err)
        end
    end)
end

ParacraftDebug:InitSingleton();

-- if System.options.isDevMode and _G.__DebugParaIODebug==nil then
-- 	_G.__DebugParaIODebug = true
-- 	local _DeleteFile = ParaIO.DeleteFile;
-- 	ParaIO.DeleteFile = function(path)
-- 		print("------deletefile test file:",path)
-- 		if GameLogic and GameLogic.IsStarted then
-- 			local xxpath = GameLogic.GetWorldDirectory().."blocktemplates/"
-- 			local isExist_1 = ParaIO.DoesFileExist(xxpath)
-- 			local ret = _DeleteFile(path);
-- 			local isExist_2 = ParaIO.DoesFileExist(xxpath)
-- 			print("isExist_1 and not isExist_2",isExist_1 and not isExist_2)
-- 			if isExist_1 and not isExist_2 then
-- 				ParacraftDebug:SendErrorLog("DevDebugLog", {
-- 					desc = "blocktemplates/ is deleted",
-- 					debugTag = "ParaIO.DeleteFile",
-- 					stackInfo = commonlib.debugstack()
-- 				})
-- 				_guihelper.MessageBox("blocktemplates已经被删除，请保存log.txt，并联系开发或测试");
-- 				print(commonlib.debugstack())
-- 			end
-- 			return ret;
-- 		else
-- 			return _DeleteFile(path);
-- 		end
-- 	end

-- 	local _MoveFile = ParaIO.MoveFile;
-- 	ParaIO.MoveFile = function(src,dest)
-- 		print("------movefile test file:",src,dest)
-- 		if GameLogic and GameLogic.IsStarted then
-- 			local xxpath =GameLogic.GetWorldDirectory().."blocktemplates/"
-- 			local isExist_1 = ParaIO.DoesFileExist(xxpath)
-- 			local ret = _MoveFile(src,dest);
-- 			local isExist_2 = ParaIO.DoesFileExist(xxpath)
-- 			if isExist_1 and not isExist_2 then
-- 				ParacraftDebug:SendErrorLog("DevDebugLog", {
-- 					desc = "blocktemplates/ is deleted",
-- 					debugTag = "ParaIO.MoveFile",
-- 					stackInfo = commonlib.debugstack(),
-- 				})
-- 				_guihelper.MessageBox("blocktemplates已经被删除，请保存log.txt，并联系开发或测试");
-- 				print(commonlib.debugstack())
-- 			end
-- 			return ret;
-- 		else
-- 			return _MoveFile(src,dest);
-- 		end
-- 	end
	
-- end