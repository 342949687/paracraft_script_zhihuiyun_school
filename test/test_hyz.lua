--[[
for i=0,9 do 
    registerKeyPressedEvent(""..i, function(msg)
    local T = NPL.load("(gl)test/test_hyz.lua",true)
        
        local funcName = "test_"..i 
        --print(T)
        local func = T[funcName]
        if func then 
            func()
        end
    
    end)
end

]]
local M = NPL.export()
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UpdateSyncer = NPL.load("Mod/GeneralGameServerMod/Command/AutoUpdater/UpdateSyncer.lua",true);
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
local Cameras = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Cameras.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
local client = UpdateSyncer

NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
local ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");

local function ftpdownload(url)
	luaopen_cURL();
	local c = cURL.easy_init()
	local result;
	
	c:setopt_url(url);
	c:perform({writefunction = function(str) 
		if(result) then
			result = result..str;
		else
			result = str;
		end	
	end});
	return result;
end;

local config = {
	address = "10.27.1.94",
	user = "admin",
	passwd = "SPHEMiDZ4R3Mhf7",
	ftplistURL="ftp://10.27.1.94/paracraft/apk/xxx.txt",	
}

local function ftpxxx()
	local fw=ParaIO.open("ftp.txt","w");
	fw:WriteString("open "..config.address.."\n");
	fw:WriteString(config.user.."\n");
	fw:WriteString(config.passwd.."\n");

	fw:WriteString("cd paracraft\n");
	-- fw:WriteString("cd apk\n");
	fw:WriteString('mkdir "'.."xxx1"..'"\n');
	fw:WriteString("bye\n");  
	fw:close();

	local curDir = ParaIO.GetCurDirectory(0);
	local ftppara="-s:"..curDir.."ftp.txt";
	print("ftppara",ftppara)
	-- if (ParaGlobal.ShellExecute("open", "ftp.exe", ftppara, curDir, 5)) then 
	-- 	log(tostring("assets files uploaded successfully !\n"));
	-- end;   

	local file = io.popen("ftp "..ftppara)
	if file then
		local output = file:read('*all')
		file:close()

		print("output",output)
	end

end

local function ftp_download(localPath,name)
	local curDir = ParaIO.GetCurDirectory(0);

	local ftpPath = curDir.."/ftp.txt"
	local fw=ParaIO.open(ftpPath,"w");
	fw:WriteString("open "..config.address.."\n")
	fw:WriteString(config.user.."\n")
	fw:WriteString(config.passwd.."\n")

	local str = [[
		cd paracraft
		mkdir "dev_update_source"
		cd dev_update_source
		get %s %s
		bye
	]]
	str = string.format(str,name,localPath)
	-- print("----------str",str)
	fw:WriteString(str)
	fw:close();

	local cmdStr = "ftp -s:"..ftpPath
	local file = io.popen(cmdStr)
	if file then
		local output = file:read('*all')
		file:close()
		ParaIO.DeleteFile(ftpPath)
		print("output",output)
		return output
	end
end

local ShootingTool
local _i = 0
function M.test_1()
	-- ftpxxx()

	-- ftp_download("D:/work/para_code/git/paracraft_script/bin/ver.txt","version")

	print("ftpdownload",ftpdownload("ftp://10.27.1.94/paracraft/dev_update_source/filelist"))
	print("ftpdownload",ftpdownload("ftp://10.27.1.94/paracraft/dev_update_source/version"))

	-- local UserProtocolPre = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua",true);
    --     if UserProtocolPre then
    --         UserProtocolPre.CheckShow();
    --     end
end
--[[
职位描述
参与产品需求分析、技术评审，将产品需求细化为开发任务，并分配任务，掌握开发进度。
使用当前主流Android/iOS技术方案，优化公司移动端App用户体验，提升开发效率。
负责app技术攻坚，编写维护技术文档，带领团队积累、进步。
管理驱动客户端开发团队，促成部门与上下游部门进行积极有效的沟通。

职位要求
本科及以上学历，计算机相关专业，5年以上移动开发经验。
熟悉Android和Ios，参与或主导过成熟项目，对app开发有自己的理解。
执行力强，有项目、团队管理经验优先
]]
local Cameras = commonlib.gettable("System.Scene.Cameras");

function _CanSeePoint(x, y, z)
	local eyePos = Cameras:GetCurrent():GetEyePosition()
	local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
	local dir = mathlib.vector3d:new_from_pool(x - eyeX, y - eyeY, z - eyeZ)
	local length = dir:length();
	dir:normalize()
	local dirX, dirY, dirZ = dir[1], dir[2], dir[3];
	
	-- try picking physical mesh
	local pt = ParaScene.Pick(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length + 0.1, "point")
	if(pt:IsValid())then
		local x1, y1, z1 = pt:GetPosition()
		if((((x1-x)^2) + ((y1 - y)^2) + ((z1-z) ^2)) > 0.001) then
			return false;
		end
	end
	-- try to pick block 
	if(BlockEngine:RayPicking(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length - 0.1)) then
		return false;
	end

	print("eyeX, eyeY, eyeZ, dirX, dirY, dirZ",eyeX, eyeY, eyeZ, dirX, dirY, dirZ)
	return true
end

M.set_screenSize = function(w,h)
	local att = ParaEngine.GetAttributeObject();
	att:SetField("ScreenResolution", {w,h}); 
	att:CallField("UpdateScreenMode");
end

M.set_fov = function(fov)
	local att = ParaCamera.GetAttributeObject();
	att:SetField("FieldOfView", fov)
	
	-- GameLogic.AddBBS(nil,old.."")
end

M.func_add_fov = function()

end

function M.test_2()
	-- local attr = ParaMovie.GetAttributeObject();
	-- attr:SetField("StereoCaptureMode", 0);

	-- -- M.set_screenSize(2160,1080)
	-- M.set_screenSize(1280,1280)
	-- ParaEngine.GetAttributeObject():SetField("LockWindowSize", false);

	local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua",true);

	local script_dir = "D:/work/para_code/git/paracraft_script/"
	-- ParacraftCI.Build_main_full_pkg(script_dir)
	ParacraftCI.Build_main150727_pkg(nil,"29001","master")
	
	ParacraftCI.checkBuildAndUploadFtp({
		-- build_pkg = true,
		-- build_mod = true,
	})
end

_G._xx_yaw = _G._xx_yaw or 0
function M.test_3( ... )
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua")
	-- local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
	-- MobileUIRegister.SetMobileUIEnable(false)

	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua",true)
	-- local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
	-- MobileUIRegister.SetMobileUIEnable(true)

	-- -- GameLogic.AddBBS(nil,"开启mobile")

	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SystemSettingsPage.lua");
	-- local SystemSettingsPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SystemSettingsPage");
	-- SystemSettingsPage.OnCancel()

	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SystemSettingsPage.lua",true);
	-- local SystemSettingsPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SystemSettingsPage");
	-- SystemSettingsPage.ShowPage()

	-- -- NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
	-- -- local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
	-- -- TextureModPage.ClosePage(true)

	-- -- NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua",true);
	-- -- local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
	-- -- TextureModPage.ShowPage(true)

	-- ParaEngine.GetAttributeObject():GetChild("ViewportManager"):SetField("OmniForceLookatDistance",8)
	-- local attr = ParaMovie.GetAttributeObject();
	-- attr:SetField("StereoCaptureMode", 8); --目标单眼
	-- GameLogic.options:EnableStereoMode(8)

	-- local _yaw = -1.25
	-- GameLogic.RunCommand(string.format("/camerayaw %s",_yaw))
	-- -- GameLogic.AddBBS(1,"set _yaw:".._yaw)

	-- local UserProtocolPre = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua");
    --     if UserProtocolPre then
    --         UserProtocolPre.CheckShow();
    --     end

	local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua",true);

	local script_dir = "D:/work/para_code/git/paracraft_script/"
	ParacraftCI.Build_main_full_pkg(script_dir)
end

function _PrepareApp()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareApp.lua",true);
	local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");
	-- PrepareApp.start()
	-- PrepareApp.ShowExitAlert("网络连接失败，请检查网络")

    PrepareApp.ShowPage()
	

	-- commonlib.TimerManager.SetTimeout(function()
	-- 	self:next_step({PrepareApp = true});
	-- end,1000)
end

function M.test_4( ... )
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Login/YellowCodeLimitPage.lua",true);
	-- local YellowCodeLimitPage = commonlib.gettable("MyCompany.Aries.Game.YellowCodeLimitPage");
	
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua")
	-- local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
	-- MobileUIRegister.SetMobileUIEnable(false)
	-- GameLogic.AddBBS(nil,"关闭mobile")

	
	-- local _yaw = GameLogic.RunCommand("/camerayaw")
	-- _yaw = _yaw+math.pi*0.5;
	-- if _yaw>math.pi*2 then
	-- 	_yaw = _yaw - math.pi*2
	-- end
	-- GameLogic.RunCommand(string.format("/camerayaw %s",_yaw))
	-- GameLogic.AddBBS(1,"+ _yaw:"..math.floor(_yaw*100)/100)

	-- ParaMovie.TakeScreenShot("D:/work/test_capture.png")


	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
	-- local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
	-- VideoRecorder.StartRecotdOmni({
	-- 	OmniForceLookatDistance=0,
	-- 	OmniAlwaysUseUpFrontCamera=false,
	-- })
	-- ParaUI.GetUIObject("root").visible = false

	local fov_v = ParaCamera.GetAttributeObject():GetField("FieldOfView", 0)
	local fov_h = math.atan(1280/720 * math.tan(fov_v/2))*2
	local degree = fov_h*180/3.141592653
	GameLogic.AddBBS(2,"fov_v:"..fov_v.."  fov_h:"..fov_h.."  degree:"..degree)
end

local portNum = 40

function M.test_5( ... )
	-- GameLogic.AddBBS(nil,"播放开始动画")
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/ReplayManager.lua",true);
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordUserPath.lua",true);
	-- local RecordUserPath = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordUserPath");

	-- RecordUserPath:_loadHistory()

	-- -- RecordUserPath.SetConfig({
	-- -- 	TIME_SPEED = 10,
	-- -- })
	-- -- RecordUserPath:PlayPathAnimsFromBorn()
	-- RecordUserPath:StopAllEntityAni()
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordUserPath.lua",true);
	-- local RecordUserPath = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordUserPath");
	-- RecordUserPath:PlayPathAnimsFromBorn({
	-- 	speed = 8,
	-- 	maxTime = 2000,
	-- 	withCameraOn = true,
	-- },function()
	-- 	-- GameLogic.AddBBS(99,"kkkk")
	-- end)

	-- if _G._xxTimer_sss then
	-- 	_G._xxTimer_sss:Change()
	-- 	_G._xxTimer_sss = nil 
	-- end

	-- local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	-- for i=0,portNum do
	-- 	local viewport = ParaEngine.GetViewportAttributeObject(i);
	-- 	local fov = viewport:GetField("ods_fov",0)*180/3.141592653
	-- 	GameLogic.AddBBS(nil,"fov:"..math.floor(fov*100)/100)
	-- 	viewport:SetField("ods_fov",(fov+1)*3.1415926/180)
	-- end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/ODSStereoEffect.lua",true);
	local ODSStereoEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.ODSStereoEffect");
	local effect = ODSStereoEffect:new():Init(GameLogic.GetShaderManager());
	GameLogic.GetShaderManager():RegisterEffect(effect);


	GameLogic.AddBBS(nil,"开启 effect")
	local effect = GameLogic.GetShaderManager():GetEffect("ODSStereo");
	if(effect) then
		effect:SetEnabled(true);
	end
	-- ParaUI.GetUIObject("root").visible = false
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/TipBox/TipBox.lua",true)
	-- local TipBox = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.TipBox")
	-- TipBox.ShowPage({
	-- 	text = "代码模式需要手动输入代码，请使用电脑下载帕拉卡客户端，在电脑端使用鼠标键盘编辑输入代码体验更佳。"
	-- })
end

NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorderSettings.lua");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");

local _recordTimer = nil
function M.StartRecotrOmni(delayTime)
	VideoRecorderSettings.SetPreset("mp4 ODS single eye");
    VideoRecorderSettings.SetFPS(60);
	VideoRecorder.BeginCaptureImp(function()
		if _recordTimer then
			_recordTimer:Change()
			_recordTimer = nil
		end
		if delayTime and delayTime>0 then
			_recordTimer = commonlib.TimerManager.SetTimeout(function()
				VideoRecorder.EndCapture()
			end,delayTime)
		end
	end)

end

function M.EndRecordOmni()
	if _recordTimer then
		_recordTimer:Change()
		_recordTimer = nil
	end
	VideoRecorder.EndCapture()
end


function M.test_6( ... )
	-- if _G.xxTimer_1 then
	-- 	_G.xxTimer_1:Change(0)
	-- 	_G.xxTimer_1 = nil
	-- end
	-- local x, y, z, block_id, data,flag = 19210,15,19184,257,15,3;
	-- data = 14
	-- BlockEngine:SetBlock(x, y, z, block_id, data,flag)

	-- local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	-- for i=0,portNum do
	-- 	local viewport = ParaEngine.GetViewportAttributeObject(i);
	-- 	local fov = viewport:GetField("ods_fov",0)*180/3.141592653
	-- 	GameLogic.AddBBS(nil,"fov:"..math.floor(fov*100)/100)
	-- 	viewport:SetField("ods_fov",(fov-1)*3.1415926/180)
	-- end

	GameLogic.AddBBS(nil,"关闭 effect")
	local effect = GameLogic.GetShaderManager():GetEffect("ODSStereo");
	if(effect) then
		effect:SetEnabled(false);
	end
end

local function _floor(x)
	return math.floor(x*100)/100
end

function M.test_7( ... )
	-- local x, y, z, block_id, data,flag = 19212,15,19184,257,15,3;
	-- data = 15
	-- BlockEngine:SetBlock(x, y, z, block_id, data,flag)

	-- local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	-- local viewport = ParaEngine.GetViewportAttributeObject(2);

	-- local width = viewport:GetField("width",1)
	-- local height = viewport:GetField("height",1)
	-- local fov = _floor(viewport:GetField("ods_fov",0)*180/3.141592653)
	-- local radian = fov*3.1415926/180;

	-- local tanFov = _floor(math.tan(radian))
	-- local half_tanFov = _floor(math.tan(radian/2))
	-- local aspect = _floor(width/height)

	-- print("=========ggggddd",string.format("fov:%s, tanFov:%s, half_tanFov:%s, aspect:%s, half_tanFov*aspect=%s,1/x=%s",fov,tanFov,half_tanFov,aspect,_floor(half_tanFov*aspect),_floor(1/(half_tanFov*aspect))))

	-- ParaEngine.SetRenderTarget2(0,"ods_render_target");
	-- local _Texture0 = ParaAsset.LoadTexture("ods_render_target","ods_render_target",0) 

	-- local _yaw = GameLogic.RunCommand("/camerayaw")
	-- GameLogic.RunCommand(string.format("/camerayaw %s",_yaw+0.001))
	-- GameLogic.AddBBS(1,"+ _yaw:".._yaw)

	ParaUI.GetUIObject("root").visible = false
	GameLogic.options:SetRenderMethod("1",true)
end

local rot_y = 0
local pitch = 0

function M.test_8()
	-- if _G.xxTimer_1 then
	-- 	_G.xxTimer_1:Change(0)
	-- 	_G.xxTimer_1 = nil
	-- end
	-- local x, y, z, block_id, data,flag = 19212,15,19186,257,15,3;
	-- local _func 
	-- _func = function(idx)
	-- 	if idx==48 then
	-- 		return
	-- 	end
	-- 	data = idx 
	-- 	GameLogic.AddBBS(1,"data:"..data,10*1000)
	-- 	BlockEngine:SetBlock(x, y, z, block_id, data,flag)
	-- 	_G.xxTimer_1 = commonlib .TimerManager.SetTimeout(function()
	-- 		_func(idx+1)
	-- 	end,5*1000)
	-- end

	-- _func(10)

	-- ParaUI.GetUIObject("root").visible = not ParaUI.GetUIObject("root").visible
	-- if ParaUI.GetUIObject("root").visible then 
		-- M.set_screenSize(1280,720)
		-- commonlib.TimerManager.SetTimeout(function()
		-- 	GameLogic.options:EnableStereoMode(0)
		-- end,1000)
	-- else
		-- M.set_screenSize(2048,2048)
		-- commonlib.TimerManager.SetTimeout(function()
		-- 	GameLogic.options:EnableStereoMode(6)
		-- end,1000)
	-- end

	-- local _yaw = GameLogic.RunCommand("/camerayaw")
	-- GameLogic.RunCommand(string.format("/camerayaw %s",_yaw-0.001))
	-- GameLogic.AddBBS(1,"- _yaw:".._yaw)

	ParaUI.GetUIObject("root").visible = true
end

function test_update()
	System.options.appId = "paracraft_430"
	local gamename = "Paracraft"
	gamename = GameLogic.GetFilters():apply_filters('GameName', gamename)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua",true);
	local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
	local _updater = ClientUpdater430:new({gamename=gamename});
	GameLogic.GetFilters():apply_filters("ShowClientUpdaterNotice");
	_updater.autoUpdater.configs.version_url = string.format("http://yapi.kp-para.cn/mock/565/version-control/version.xml?appId=%s&machineCode=%s",System.options.appId,ParaEngine.GetAttributeObject():GetField('MachineID', ''))
	_updater:Check(function(bNeedUpdate, latestVersion,curVersion,bAllowSkip,needAppStoreUpdate)
		GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");
		print("-----hyz 181 bNeedUpdate",bNeedUpdate)
		if bNeedUpdate==nil then --表示更新失败
			GameLogic.AddBBS(nil,L"检查更新失败")
		elseif bNeedUpdate then
			--不是是最新版，作为局域网客户端开启，随时准备进行同步
			GameLogic.GetFilters():apply_filters('start_lan_client',{
				realLatestVersion=latestVersion,
				isAutoInstall=not bAllowSkip,
				needShowDownloadWorldUI=not bAllowSkip,
				onUpdateError = function()
				end
			})
			print("bAllowSkip",bAllowSkip)
			if bAllowSkip then
				_updater:checkNeedSlientDownload(); --局域网内，可以跳过更新的情况下，去看看是否需要静默更新
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.lua");
				local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog")
				
				ClientUpdateDialog.Show(latestVersion,curVersion,gamename,function()
					local ret = GameLogic.GetFilters():apply_filters('check_is_downloading_from_lan',{
						needShowDownloadWorldUI = true,
						installIfAlldownloaded = true
					})
					if ret and ret._hasStartDownloaded then --点击更新按钮后，再查一遍是否已经再局域网开始更新了
						print("-------已经开始局域网更新了")
						return
					end
					_updater:Download(true);
				end)
			end
		elseif needAppStoreUpdate then --需要跳转应用商店更新
		else
			--已经是最新版了，开启服务器
			GameLogic.GetFilters():apply_filters('start_lan_server',{
				realLatestVersion=latestVersion,
				_updater = _updater
			})
		end
	end)

	-- _updater:WriteConfigForLauncher()
end

function test_update2()
	os.paraEngineVer = "1.1.0.0"
	System.options.appId = "paracraft-android_100"

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
	local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
	local updater = ClientUpdater:new();

	GameLogic.GetFilters():apply_filters("ShowClientUpdaterNotice");
	updater.autoUpdater.configs.version_url = string.format("http://yapi.kp-para.cn/mock/565/version-control/version.xml?appId=%s&machineCode=%s",System.options.appId,ParaEngine.GetAttributeObject():GetField('MachineID', ''))
	updater:Check(function(bNeedUpdate, latestVersion,curVersion,bAllowSkip,needAppStoreUpdate)
		GameLogic.GetFilters():apply_filters("HideClientUpdaterNotice");

		if (bNeedUpdate) then
				updater:Download(function(bSucceed)
					if(bSucceed) then
						GameLogic.AddBBS(nil,"重启")
					else

					end
				end);
		elseif needAppStoreUpdate then --需要跳转应用商店更新
			if bAllowSkip then

			else
				local jumpUrl = updater:getAppStoreUrl()
				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/JumpAppStoreDialog.lua");
				local JumpAppStoreDialog = commonlib.gettable("MyCompany.Aries.Game.Login.Update.JumpAppStoreDialog")
				JumpAppStoreDialog.Show(latestVersion,curVersion,jumpUrl)
			end
		else
			if (comparedVersion == 100) then

				return;
			end

			if (updater:GetCurrentVersion() ~= latestVersion) then
				GameLogic.AddBBS(nil,"重启")
			else

			end
		end
	end);

end

function M.test_9( ... )
	-- local block_id, data,flag = 257,15,3;
	-- local x,y,z = 19217,12,19184
	-- for i=0,48 do
	-- 	data = i
	-- 	z = z - 1
	-- 	BlockEngine:SetBlock(x, y, z, block_id, data,flag)
	-- end

	test_update()

	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/JumpAppStoreDialog.lua",true);
	-- local JumpAppStoreDialog = commonlib.gettable("MyCompany.Aries.Game.Login.Update.JumpAppStoreDialog")
	-- JumpAppStoreDialog.Show("2.0","1.0")

	-- local _updater = ClientUpdater430:new({gamename=gamename});
	-- _updater.autoUpdater:resetVersionUrlWithNew()
end

function _createOrGetCamera()
    local kkxx_camera = _G.kkxx_camera
    if kkxx_camera==nil then
        kkxx_camera = EntityCamera:Create({item_id = block_types.names.TimeSeriesCamera});
        _G.kkxx_camera = kkxx_camera
        kkxx_camera:SetPersistent(false);
		kkxx_camera:Attach();
		-- kkxx_camera:ShowModel();
    end
    return kkxx_camera
end

function getEyePos(x,y,z,dist,pitch,yaw)
	while yaw<0 do
		yaw = yaw + 6.28
	end
	if yaw>=3.14 then
		yaw = yaw - 6.28
	end
	while pitch<0 do
		pitch = pitch + 6.28
	end
	if pitch>=3.14 then
		pitch = pitch - 6.28
	end
    local z2,y2,z2;
    if dist>0 then
        y2 = y + dist*math.abs(math.sin(pitch))
    else
        y2 = y - dist*math.abs(math.sin(pitch))
    end
    local d = dist*math.abs(math.cos(pitch))
	
    if yaw<=0 then
        z2 = z - math.abs(d*math.sin(yaw))
    else
        z2 = z + math.abs(d*math.sin(yaw))
    end
    if math.abs(yaw)<=1.57 then
        x2 = x - math.abs(d*math.cos(yaw))
    else
        x2 = x + math.abs(d*math.cos(yaw))
    end

    return x2,y2,z2
end

-- function M.test_9()
-- 	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SysInfoStatistics.lua",true);
-- 	local SysInfoStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.SysInfoStatistics")
-- 	SysInfoStatistics.checkGetSysInfoAndUpload()

-- end