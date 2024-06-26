--[[
Title: operating system parent file
Author(s): LiXizhi
Date: 2016/1/9
Desc: all os module files are included here. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/os.lua");
echo(System.os.GetPlatform()=="win32");
echo(System.os.args("bootstrapper", ""));
echo(System.os.GetCurrentProcessId());
echo(System.os.GetPCStats());
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/run.lua");
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/os/options.lua");
local os = commonlib.gettable("System.os");

-- @return "win32", "linux", "android", "ios", "mac"
function os.GetPlatform()
	if(not os.platform) then
		local platform = ParaEngine.GetAttributeObject():GetField("Platform", 0);
		if(platform == 3) then
			return "win32";
		elseif(platform == 1) then
			return "ios";
		elseif(platform == 2) then
			return "android";
		elseif(platform == 5) then
			return "linux";
		elseif(platform == 8) then
			return "mac";
		elseif(platform == 10) then
			return "emscripten";
		elseif(platform == 13) then
			return "wp8";
		elseif(platform == 14) then
			return "winrt";
		elseif(platform == 0) then
			return "unknown";
		end
	end
	return os.platform;
end

function os.GetParaEngineVersion()
	if not os.paraEngineVer then
		local verStr = ParaEngine.GetVersion()
		local major,minor = unpack(commonlib.split(verStr,"."))
		os.paraEngineVer = verStr
		os.paraEngineMajorVer = tonumber(major)
		os.paraEngineMinorVer = tonumber(minor)
	end
	return os.paraEngineVer,os.paraEngineMajorVer,os.paraEngineMinorVer
end

-- params string:"1.4.1.0" --测试使用
function os.SetParaEngineVersion(strVertion)
	local strVertion = strVertion or "";
	local major, minor ,product_major, product_minor= unpack(commonlib.split(strVertion, "."));
	if major and minor  and product_major and product_minor then
		os.paraEngineVer = strVertion
		os.paraEngineMajorVer = tonumber(major)
		os.paraEngineMinorVer = tonumber(minor)
		GameLogic.AddBBS(nil,L"引擎版本号修改成功")
	end
end

-- @return "DirectX" or "OpenGL"
function os.GetRendererName()
	if not os.rendererName then
		os.rendererName = ParaEngine.GetAttributeObject():GetField("RendererName", "DirectX");
	end
	return os.rendererName;
end


function os.CompareParaEngineVersion(ver)
	local curVer, curMajorVer, curMinorVer = System.os.GetParaEngineVersion();

	local major, minor = unpack(commonlib.split(ver, "."));

	major = tonumber(major);
	minor = tonumber(minor);
	
	-- curVer < ver (smaller) return false
	-- curVer >= ver (bigger) return true

	if (curMajorVer < major) then
		return false;
	else
		if (curMinorVer < minor) then
			return false;
		else
			return true;
		end
	end
end

function os.GetAndroidFlavor()
	local androidFlavor = ParaEngine.GetAppCommandLineByParam("android_flavor", "");
	return string.lower(androidFlavor);
end

local isWindowsXP;
-- if it is old system
function os.IsWindowsXP()
	if(isWindowsXP == nil) then
		isWindowsXP = false;
		if(os.GetPlatform() == "win32") then
			local stats = System.os.GetPCStats();
            if(stats and stats.os) then
                if(stats.os:lower():match("windows xp")) then
                    isWindowsXP = true;
                end
            end
		end
	end
	return isWindowsXP;
end

function os.IsWin32()
	return os.GetPlatform() == "win32";
end

-- obsoleted: use os.IsWin32() instead
function os.IsWindow()
	return os.GetPlatform() == "win32";
end

function os.IsEmscripten()
	return os.GetPlatform() == "emscripten";
end

-- return true if is mobile device
function os.IsMobilePlatform()
	if (os.GetPlatform() == "ios" or os.GetPlatform() == "android") then
		return true;
	else
		return false;
	end
end

-- return true if touch mode
function os.IsTouchMode()
	if (os.GetPlatform() == "ios" or os.GetPlatform() == "android") then
		return true;
	else
		return false;
	end
end

-- whether the device support touch event
-- whenever we receive a mouse down click, this function return false, whenever we receive a touch down event, it return true. 
-- call this function periodically to check if the most recent click is coming from click or touch. 
-- this function is useful for windows platform with touch screen. 
function os.IsLastTouchMode()
	if(os.IsMobilePlatform()) then
		return true;
	else
		return ParaEngine.GetAttributeObject():GetField("IsTouchInputting", false);
	end
end

-- return true if it is 64 bits system. 
function os.Is64BitsSystem()
	if(os.Is64BitsSystem_ == nil) then
		os.Is64BitsSystem_ = ParaEngine.GetAttributeObject():GetField("Is64BitsSystem", false);
	end
	return os.Is64BitsSystem_;
end

-- get command line argument
-- @param name: argument name
-- @param default_value: default value
function os.args(name, default_value)
	return ParaEngine.GetAppCommandLineByParam(name, default_value);
end

-- get process id
function os.GetCurrentProcessId()
	if(not os.pid) then
		os.pid = ParaEngine.GetAttributeObject():GetField("ProcessId", 0)
	end
	return os.pid;
end

local externalStoragePath;
-- this is "" on PC, but is valid on android/ios mobile devices. 
-- this will always ends with "/"
function os.GetExternalStoragePath()
	if(not externalStoragePath) then
		externalStoragePath = ParaIO.GetCurDirectory(22);

		if(ParaIO.GetCurDirectory(0) == externalStoragePath) then
			externalStoragePath = "";
		else
			if(externalStoragePath ~= "" and not externalStoragePath:match("[/\\]$")) then
				externalStoragePath = externalStoragePath .. "/";
			end
		end
	end
	return externalStoragePath;
end


-- a writable directory. on Android,iOS this is the default app internal storage. 
-- when app is uninstalled, data in this directory will be gone. 
function os.GetWritablePath()
	return ParaIO.GetWritablePath();
end

local pc_stats;
-- get a table containing all kinds of stats for this computer. 
-- @return {videocard, os, memory, ps, vs}
function os.GetPCStats()
	if(not pc_stats) then
		pc_stats = {};
		pc_stats.videocard = ParaEngine.GetStats(0);
		pc_stats.os = ParaEngine.GetStats(1);
		
		local att = ParaEngine.GetAttributeObject();
		local sysInfoStr = att:GetField("SystemInfoString", "");
		local name, value, line;
		for line in sysInfoStr:gmatch("[^\r\n]+") do
			name,value = line:match("^(.*):(.*)$");
			if(name == "TotalPhysicalMemory") then
				value = tonumber(value)/1024;
				pc_stats.memory = value;
			else
				-- TODO: other OS settings
			end
		end
		pc_stats.ps = att:GetField("PixelShaderVersion", 0);
		pc_stats.vs = att:GetField("VertexShaderVersion", 0);
		pc_stats.memory = pc_stats.memory or 4086;

		-- uncomment to test low shader 
		--pc_stats.ps = 1;
		--pc_stats.memory = 300

		local att = ParaEngine.GetAttributeObject();
		pc_stats.IsFullScreenMode = att:GetField("IsFullScreenMode", false);
		pc_stats.resolution_x = tonumber(att:GetDynamicField("ScreenWidth", 1020)) or 1020;
		pc_stats.resolution_y = tonumber(att:GetDynamicField("ScreenHeight", 680)) or 680;
		-- pc_stats.IsWebBrowser = System.options and System.options.IsWebBrowser;
	end
	return pc_stats;
end

if(os.IsWindowsXP()) then
	log("Info: windows XP does not support https, we will replace all https calls with http\n")
	local NPL_AppendURLRequest = NPL.AppendURLRequest;
	NPL.AppendURLRequest = function(urlParams, sCallback, sForm, sPoolName)
		if(type(urlParams) == "table" and urlParams.url) then
			-- libcurl.dll under windows XP does not support openssl protocol, we will try using http instead. 
			local url = urlParams.url:gsub("^https://", "http://");
			if(urlParams.url ~= url) then
				-- TODO: for unknown reason, 7niu cdn redirection always uses SSL 
				url = url:gsub("^http://apicdn%.keepwork%.com", "http://api.keepwork.com");
				urlParams.url = url;
				log("Info: replacing https->http:"..url.."\n")
			end
		elseif(type(urlParams) == "string") then
			local url = urlParams:gsub("^https://", "http://")
			if(urlParams ~= url) then
				-- TODO: for unknown reason, 7niu cdn redirection always uses SSL 
				url = url:gsub("^http://apicdn%.keepwork%.com", "http://api.keepwork.com");
				urlParams = url
				log("Info: replacing https->http:"..url.."\n")
			end
		end
		return NPL_AppendURLRequest(urlParams, sCallback, sForm, sPoolName)
	end


	local NPL_AsyncDownload = NPL.AsyncDownload;
	NPL.AsyncDownload = function(urlParams, ...)
		if(type(urlParams) == "string") then
			local url = urlParams:gsub("^https://", "http://")
			if(urlParams ~= url) then
				-- TODO: for unknown reason, 7niu cdn redirection always uses SSL 
				url = url:gsub("^http://apicdn%.keepwork%.com", "http://api.keepwork.com");
				urlParams = url
				log("Info: replacing https->http:"..url.."\n")
			end
		end
		return NPL_AsyncDownload(urlParams, ...)
	end
end