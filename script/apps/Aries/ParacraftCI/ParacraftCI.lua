--[[
Title: 
Author: chenjinxian
Date: 2020/7/1
Desc: 
-----------------------------------------------
local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua");
ParacraftCI.StaticInit();
-----------------------------------------------
]]

local ParacraftCI = NPL.export();

ParacraftCI.UpdateScript = 1;
ParacraftCI.UpdateAllMod = 2;
ParacraftCI.UpdateWorldShare = 3;
ParacraftCI.UpdateBuildMod = 4;
ParacraftCI.Finished = 5;
ParacraftCI.ShowBranches = 6;
ParacraftCI.UpdateState = 0;
ParacraftCI.WorldShareBranches = {};
ParacraftCI.GGSBranches = {};

function ParacraftCI.StaticInit()
	ParacraftCI.Reset();
	commonlib.TimerManager.SetTimeout(function()  
		local ci = ParaEngine.GetAppCommandLineByParam("open_ci", false);
		if (ci) then
			ParacraftCI.ShowPage();
		end
	end, 2000)
end

local page;
function ParacraftCI.OnInit()
	page = document:GetPageCtrl();
end
function ParacraftCI.ShowPage(state)
	if (page) then
		page:CloseWindow();
	end
	ParacraftCI.UpdateState = state or 0;
	local params = {
		url = "script/apps/Aries/ParacraftCI/ParacraftCI.html",
		name = "ParacraftCI.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -480 / 2,
		y = -340 / 2,
		width = 480,
		height = 340,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

end

function ParacraftCI.Reset()
	ParacraftCI.UpdateState = 0;
	ParacraftCI.WorldShareBranches = {};
	ParacraftCI.GGSBranches = {};
end

function ParacraftCI.OnClose()
	ParacraftCI.Reset();
	page:CloseWindow();
end

function ParacraftCI.GetStateText()
	if (ParacraftCI.UpdateState > 0 and ParacraftCI.UpdateState < ParacraftCI.Finished) then
		return ParacraftCI.StateText[ParacraftCI.UpdateState];
	else
		return L"准备更新";
	end
end

function ParacraftCI.StartUpdate()
	local update_script = page:GetUIValue("UpdateScript", false);
	local update_mod = page:GetUIValue("UpdateMod", true);
	local update_worldshare= page:GetUIValue("UpdateWorldShare", true);
	local update_GGS= page:GetUIValue("UpdateGeneralGameServerMod", true);
	if (update_script) then
		ParacraftCI.GetScript();
	end
	if (update_mod) then
		ParacraftCI.GetBuildInMod();
		ParacraftCI.GetAllMode();
		return;
	end
	if (update_worldshare) then
		local cmd = [[
			pushd "ParacraftBuildinMod/npl_packages/WorldShare"
			git pull
			popd
		]]
		local result = System.os.run(cmd);
	end
	if (update_GGS) then
		local cmd = [[
			pushd "ParacraftBuildinMod/npl_packages/GeneralGameServerMod"
			git pull
			popd
		]]
		local result = System.os.run(cmd);
	end
	if (update_worldshare) then
		ParacraftCI.ShowWorldShareBranches()
	end
	if (update_GGS) then
		ParacraftCI.ShowGGSBranches()
	end

	if ((not update_mod) and (not update_worldshare) and (not update_GGS)) then
		ParacraftCI.ShowPage(ParacraftCI.Finished);
	end
end

function ParacraftCI.ExitApp()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
	local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
	Desktop.ForceExit(false);
end

function ParacraftCI.GetScript()
	local cmd = [[
		@echo off 
		CALL :InstallPackage paracraft_svn https://github.com/tatfook/paracraft_svn
		EXIT /B %ERRORLEVEL%

		:InstallPackage
		if exist "%1\README.md" (
			pushd %1
			git reset --hard
			git pull
			popd
		) else (
			rmdir /s /q "%CD%\%1"
			git clone %2
		)
		EXIT /B 0
	]]

	local result = System.os.run(cmd);
	if (result) then
		return true;
	end
end

function ParacraftCI.GetBuildInMod()
	local cmd = [[
		@echo off 
		CALL :InstallPackage ParacraftBuildinMod git@github.com:tatfook/ParacraftBuildinMod.git
		EXIT /B %ERRORLEVEL%

		:InstallPackage
		if exist "%1\README.md" (
			pushd %1
			git reset --hard
			git pull
			popd
		) else (
			rmdir /s /q "%CD%\%1"
			git clone %2
		)
		EXIT /B 0
	]]

	local result = System.os.run(cmd);
	if (result) then
		return true;
	end
end

function ParacraftCI.GetAllMode()
	local cmd = [[
		@echo off 
		pushd "ParacraftBuildinMod"
		if not exist "npl_packages" ( mkdir npl_packages )

		pushd "npl_packages"

		REM set GitURL=https://github.com/
		set GitURL=git@github.com:
		 
		CALL :InstallPackage AutoUpdater NPLPackages/AutoUpdater
		CALL :InstallPackage STLExporter LiXizhi/STLExporter
		CALL :InstallPackage BMaxToParaXExporter tatfook/BMaxToParaXExporter

		CALL :InstallPackage NPLCAD tatfook/NPLCAD
		CALL :InstallPackage NplCadLibrary NPLPackages/NplCadLibrary
		CALL :InstallPackage ModelVoxelizer NPLPackages/ModelVoxelizer

		CALL :InstallPackage NplCad2 tatfook/NplCad2

		CALL :InstallPackage WorldShare tatfook/WorldShare
		CALL :InstallPackage ExplorerApp tatfook/ExplorerApp
		CALL :InstallPackage EMapMod tatfook/EMapMod
		CALL :InstallPackage CodeBlockEditor tatfook/CodeBlockEditor
		CALL :InstallPackage PluginBlueTooth NPLPackages/PluginBlueTooth
		CALL :InstallPackage GoogleAnalytics NPLPackages/GoogleAnalytics
		CALL :InstallPackage ParaWorldClient tatfook/ParaworldClient
		CALL :InstallPackage Agents NPLPackages/Agents

		CALL :InstallPackage PyRuntime tatfook/PyRuntime

		CALL :InstallPackage NplMicroRobot tatfook/NplMicroRobot
		CALL :InstallPackage HaqiMod tatfook/HaqiMod
		CALL :InstallPackage GeneralGameServerMod tatfook/GeneralGameServerMod

		CALL :InstallPackage CodePkuCommon tatfook/CodePkuCommon.git
		CALL :InstallPackage CodePku tatfook/CodePku.git

		popd
		popd

		EXIT /B %ERRORLEVEL%

		rem install function here
		:InstallPackage
		if exist "%1\README.md" (
			pushd %1
			git remote set-url origin %GitURL%%2
			git reset --hard
			git pull
			popd
		) else (
			rmdir /s /q "%CD%\%1"
			git clone %GitURL%%2
		)
		EXIT /B 0
	]]

	local result = System.os.run(cmd);
	if (result) then
		ParacraftCI.ShowWorldShareBranches();
		ParacraftCI.ShowGGSBranches();
	end
end

function ParacraftCI.ShowWorldShareBranches()
	local cmd = [[
		pushd "ParacraftBuildinMod/npl_packages/WorldShare"
		git branch -r
		popd
	]]
	local result = System.os.run(cmd);
	if (result) then
		ParacraftCI.WorldShareBranches = commonlib.split(result, "\n");

		ParacraftCI.UpdateState = ParacraftCI.ShowBranches;
		if (page) then
			page:Refresh(0);
			page:SetValue("WorldShare", ParacraftCI.WorldShareBranches[1]);
			if (#ParacraftCI.GGSBranches > 0) then
				page:SetValue("GeneralGameServerMod", ParacraftCI.GGSBranches[1]);
			end
		end
	end
end

function ParacraftCI.ShowGGSBranches()
	local cmd = [[
		pushd "ParacraftBuildinMod/npl_packages/GeneralGameServerMod"
		git branch -r
		popd
	]]
	local result = System.os.run(cmd);
	if (result) then
		ParacraftCI.GGSBranches = commonlib.split(result, "\n");

		ParacraftCI.UpdateState = ParacraftCI.ShowBranches;
		if (page) then
			page:Refresh(0);
			page:SetValue("GeneralGameServerMod", ParacraftCI.GGSBranches[1]);
			if (#ParacraftCI.WorldShareBranches > 0) then
				page:SetValue("WorldShare", ParacraftCI.WorldShareBranches[1]);
			end
		end
	end
end

function ParacraftCI.GetWorldShareBranches()
	local branches = {};
	for i = 1, #ParacraftCI.WorldShareBranches do
		local name = ParacraftCI.WorldShareBranches[i];
		table.insert(branches, {text=name, value=name});
	end
	return branches;
end

function ParacraftCI.GetGGSBranches()
	local branches = {};
	for i = 1, #ParacraftCI.GGSBranches do
		local name = ParacraftCI.GGSBranches[i];
		table.insert(branches, {text=name, value=name});
	end
	return branches;
end

function ParacraftCI.OnSelectWorldShare(name, value)
	page:SetValue("WorldShare", value);
end

function ParacraftCI.OnSelectGGS(name, value)
	page:SetValue("GeneralGameServerMod", value);
end

function ParacraftCI.SwitchWorldShare()
	local branch = page:GetValue("WorldShare", "master");
	if (branch and #branch > 0) then
		local name = string.sub(branch, string.find(branch, '/')+1);
		if (string.find(name, "master")) then
			name = "master";
		end
		local cmd = string.format([[
			pushd "ParacraftBuildinMod/npl_packages/WorldShare"
			git checkout %s
			git pull
			popd
		]], name);
		local result = System.os.run(cmd);
		if (result) then
			return true;
		end
	end
end

function ParacraftCI.SwitchGGS()
	local branch = page:GetValue("GeneralGameServerMod", "master");
	if (branch and #branch > 0) then
		local name = string.sub(branch, string.find(branch, '/')+1);
		if (string.find(name, "master")) then
			name = "master";
		end
		local cmd = string.format([[
			pushd "ParacraftBuildinMod/npl_packages/GeneralGameServerMod"
			git checkout %s
			git pull
			popd
		]], name);
		local result = System.os.run(cmd);
		if (result) then
			return true;
		end
	end
end

NPL.load("(gl)script/ide/Files.lua");
local lfs = commonlib.Files.GetLuaFileSystem();

local function _createDir(path)
	if not ParaIO.DoesFileExist(path) then
		if System.os.GetPlatform()=="win32" then 
			ParaIO.CreateDirectory(path)
		else
			return lfs.mkdir(path)
		end
        
    end
end 

local function _deleteFile(path)
	if ParaIO.DoesFileExist(path) then
		if System.os.GetPlatform()=="win32" then 
			ParaIO.DeleteFile(path)
		else
			os.remove(path)
		end
	end
end

function ParacraftCI.BuildMod(targetBranch)
	targetBranch = targetBranch or "master"

	local curDir = ParaIO.GetWritablePath();
	local tempDir = curDir.."temp/"
	_createDir(tempDir)
	local modPath = tempDir.."/ParacraftBuildinMod/ParacraftBuildinMod.zip"
	local cmdStr;
	if System.os.GetPlatform()=="win32" then 
		cmdStr = [[
			@echo off
			set tempDir=@tempDir@
			cd /d %tempDir%

			set curDir=%cd%
			
			if exist "%curDir%\ParacraftBuildinMod\.git" (
				echo run git pull ParacraftBuildinMod
				cd ParacraftBuildinMod
				git pull
			) else (
				git clone https://github.com/tatfook/ParacraftBuildinMod.git
				cd ParacraftBuildinMod
			)

			call InstallPackages.bat @targetBranch@
			call build_without_update.bat
		]]
	else
		cmdStr = [[
			tempDir=@tempDir@
			cd  $tempDir

			if [ -d "ParacraftBuildinMod/.git" ];then 
				echo run git pull ParacraftBuildinMod
				cd ParacraftBuildinMod
				git pull
			else
				echo clone https://github.com/tatfook/ParacraftBuildinMod.git:
				git clone https://github.com/tatfook/ParacraftBuildinMod.git
				cd ParacraftBuildinMod
			fi

			sh ./InstallPackages.sh @targetBranch@
			sh ./build_without_update.sh
		]]
	end
	
	cmdStr = string.gsub(cmdStr,"@tempDir@",tempDir)
	cmdStr = string.gsub(cmdStr,"@targetBranch@",targetBranch)
	local result = System.os.run(cmdStr);
	print("===========result of clone or pull ParacraftBuildinMod:")
	echo(result,true)
	print("===========result end")
	if result==nil then
		echo(cmdStr)
	end
	print("======modPath",modPath)
	if not ParaIO.DoesFileExist(modPath) then
		print("error build ParacraftBuildinMod failed!")
		return
	end

	return modPath
end

-- build main_full.pkg
function ParacraftCI.Build_main_full_pkg(script_dir)
	local time_o,time_zip,time_pkg;
	local _start = os.clock()
	local function _getUsedTime()
		local _now = os.clock()
		local ret = _now - _start
		_start = _now
		return ret;
	end

	script_dir = script_dir or ""
	script_dir = script_dir .. "/"
	script_dir = string.gsub(script_dir,"//","/")

	--compile script/*.lua to bin/script/*.o
	local error_count = NPL.CompileFiles("script/*.lua", "-stripcomments", 100,script_dir); 
	time_o = _getUsedTime()

	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/PackageMakerPage.lua");
	local PackageMakerPage = Map3DSystem.App.Assets.PackageMakerPage;
	
	local pkg = {src="bin/main_full.zip", dest="bin/main_full.pkg", txtPathList={"packages/redist/main_script_complete-1.0.txt",} }
	if(not pkg) then
		return
	end

	--make zip
	PackageMakerPage.BuildPackageByGroupPath(pkg.txtPathList,pkg.src,script_dir)
	time_zip = _getUsedTime()
	
	--main_full.zip to main_full.pkg
	ParaAsset.GeneratePkgFile(script_dir..pkg.src, script_dir..pkg.dest);
	time_pkg = _getUsedTime()
	

	local pkgPath = script_dir..pkg.dest
	
	print("-----------编译脚本耗时:",time_o)
	print("-----------压缩zip耗时:",time_zip)
	print("-----------zip编译pkg耗时:",time_pkg,pkgPath)
	if error_count>0 then
		GameLogic.AddBBS("desktop", L"有编译错误，请重新检查", 5000, "255 0 0"); 
	end

	-- ParaIO.DeleteFile(script_dir.."bin/script/")
	return error_count;
end

--build main150727.pkg
--默认编译dev与master的差分增量包，如果指定commitIdOrTag，则以commitIdOrTag为差分目标
--目前(2023/2/2)的外网main.pkg的tag是29001，所以commitIdOrTag参数为："29001"
function ParacraftCI.Build_main150727_pkg(script_dir,commitIdOrTag,targetBranch)
	targetBranch = targetBranch or "dev" --差分源
	--如果不传入script_dir目录，则直接在temp目录下创建，并克隆
	if script_dir=="" or script_dir==nil then
		local curDir = ParaIO.GetWritablePath();
		local tempDir = curDir.."temp/"
		_createDir(tempDir)

		local cmdStr;
		if System.os.GetPlatform()=="win32" then 
			cmdStr = [[
				@echo off

				set tempDir=@tempDir@
				cd /d %tempDir%

				set curDir=%cd%

				if exist "%curDir%\paracraft_script\.git" (
					echo run git pull paracraft_script
					cd paracraft_script
					git pull
				) else (
					git clone http://code.kp-para.cn/paracraft/paracraft_script.git
				)
			]]
		else 
			cmdStr = [[
				tempDir=@tempDir@
				cd $tempDir

				if [ -d "paracraft_script/.git" ];then
					echo run git pull paracraft_script
					cd paracraft_script
					git pull
				else
					git clone http://code.kp-para.cn/paracraft/paracraft_script.git
				fi
			]]
		end
		cmdStr = string.gsub(cmdStr,"@tempDir@",tempDir)
		print("cmdStr",cmdStr)
		local result = System.os.run(cmdStr);
		print("===========result of clone or pull paracraft_script:")
		echo(result,true)
		print("===========result end")

		script_dir = tempDir.."/paracraft_script/"
	end
	if not ParaIO.DoesFileExist(script_dir) then
		print("Build_main150727_pkg error script_dir is not exist",script_dir)
		return
	end
	local time_o,time_zip,time_pkg;
	local _start = os.clock()
	local function _getUsedTime()
		local _now = os.clock()
		local ret = _now - _start
		_start = _now
		return ret;
	end

	local temp_diff_path = script_dir.."temp_diff.txt"
	_deleteFile(temp_diff_path)

	-- 使用git 命令行，对比dev分支和上一个打了tag的master分支，或者对比当前dev和commitIdOrTag
	-- 只比较script/、config/、npl_packages/这三个文件夹；
	-- 存放差异文件列表到temp_diff_path
	commitIdOrTag = commitIdOrTag or ""
	local cmdStr;
	if System.os.GetPlatform()=="win32" then 
		cmdStr = [[
			@echo off

			set script_dir=@script_dir@
			cd /d %script_dir%

			set paramCommitId="@commitId@"
			if %paramCommitId% == "" (
				goto COMMIT_START
			) else (
				set commitId_old=%paramCommitId%
				goto COMMIT_END
			)

			:COMMIT_START
			rem 取master分支最近一次打了tag的（认为是最近一次发版前的提交）commitId
			git checkout master
			git reset --hard
			git pull
			for /F %%i in ('"git describe --abbrev=0"') do ( set tag_old=%%i)
			if %tag_old% == "" (
				for /F %%i in ('git rev-parse HEAD') do ( set commitId_old=%%i)
			) else (
				for /F %%i in ('git rev-parse %tag_old%') do ( set commitId_old=%%i)
			)
			:COMMIT_END

			git checkout @targetBranch@
			git reset --hard
			git pull
			rem 取dev分支最新的commidId
			for /F %%i in ('git rev-parse HEAD') do ( set commitId_new=%%i)


			echo commitId_old=%commitId_old%
			echo commitId_new=%commitId_new%

			set curDir=%cd%
			set temp_diff_path=%script_dir%temp_diff.txt
			if exist %temp_diff_path% (
				cd /d %script_dir%
				del temp_diff.txt /f /s /q
				cd /d %curDir%
			)

			rem 存到文件
			echo flush diff list to %temp_diff_path%
			git diff %commitId_new% %commitId_old% --name-only script npl_packages config>> "%temp_diff_path%"

			rem pasue
		]]
		cmdStr = string.gsub(cmdStr,"@script_dir@",script_dir)
		cmdStr = string.gsub(cmdStr,"@commitId@",commitIdOrTag)
		cmdStr = string.gsub(cmdStr,"@targetBranch@",targetBranch)
		
		local bat_path = script_dir.."tempBat.bat"
		print("bat_path",bat_path)

		local file=io.open(bat_path,"a")
		io.output(file)-- 设置默认输出文件
		io.write(cmdStr)
		io.close()

		os.execute(bat_path)

		_deleteFile(bat_path)
	else
		cmdStr = [[
			# 支持传参进来，用作差分基准的commitId

			script_dir=@script_dir@
			cd $script_dir
			paramCommitId="@commitId@"
			echo paramCommitId:$paramCommitId
			if [ -z "$paramCommitId" ]; then
				echo "xxxx"
				git checkout master
				git reset --hard
				git pull
				tag_old=`git describe --abbrev=0`
				if [ -z "$tag_old" ]; then
					commitId_old=`git rev-parse HEAD`
				else
					commitId_old=`git rev-parse $tag_old`
				fi
			else
				commitId_old=$paramCommitId
			fi

			git checkout @targetBranch@
			git reset --hard
			git pull
			commitId_new=`git rev-parse HEAD`

			echo commitId_old:$commitId_old
			echo commitId_new:$commitId_new

			if [ -f "temp_diff.txt" ];then
			rm -f temp_diff.txt
			fi

			echo "生成temp_diff.txt"
			echo git diff $commitId_new $commitId_old --name-only script npl_packages config
			echo `git diff $commitId_new $commitId_old --name-only script npl_packages config` > temp_diff.txt
		]]
		cmdStr = string.gsub(cmdStr,"@script_dir@",script_dir)
		cmdStr = string.gsub(cmdStr,"@commitId@",commitIdOrTag)
		cmdStr = string.gsub(cmdStr,"@targetBranch@",targetBranch)

		print("Build_main150727_pkg cmdStr：",cmdStr)
		local result = System.os.run(cmdStr);
		print("Build_main150727_pkg ===========result：")
		echo(result,true)
		if (result) then
		end
	end
	
	
	if not ParaIO.DoesFileExist(temp_diff_path) then
		print("error",string.format("%s is not exist",temp_diff_path))
		return
	end

	local diff_data = commonlib.Files.GetFileText(temp_diff_path)

	print(diff_data)

	-- 获取差异文件列表
	local diffList = {}
	local line;
    for line in string.gmatch(diff_data,"([^\r\n%s]*)\r?\n?%s?") do
        if(line and line ~= "")then
			table.insert(diffList,line)
		end
	end
	print("==========diff list")
	echo(diffList,true)


	local error_count = 0
	for k,filepath in pairs(diffList) do 
		if filepath:match(".lua") or filepath:match(".npl") then
			local ret = NPL.CompileFiles(script_dir..filepath, "-stripcomments",nil,script_dir); 
			if ret>0 then 
				print("编译失败",filepath)
			end
			error_count = error_count + ret
		else
			ParaIO.CopyFile(script_dir..filepath,script_dir.."bin/"..filepath,true)
		end
	end
	time_o = _getUsedTime()

	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/PackageMakerPage.lua");
	local PackageMakerPage = Map3DSystem.App.Assets.PackageMakerPage;

	local rootPath = script_dir.."bin/"
	local zipPath = "main150727.zip"
	local pkgPath = "main150727.pkg"
	
	do
		--make zip
		local allPathList = {
			{
				filterList={ "*.*" },
				list={}
			}
		}
		for k,v in pairs(diffList) do 
			local filepath = script_dir..v;
			if v:match(".lua") or v:match(".npl") then
				v = string.gsub(v,".lua",".o")
				v = string.gsub(v,".npl",".o")
				filepath = rootPath..v
			end
			allPathList[1].list[filepath] = filepath
		end
		echo(allPathList,true)
		if(#allPathList > 0) then
			NPL.load("(gl)script/installer/BuildParaWorld.lua");
			if(commonlib.BuildParaWorld.BUILD_FROM_MAC)then
				PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile_temp(allPathList,zipPath,script_dir)	
			else
				PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile(allPathList,zipPath,script_dir)	
			end
			ParaIO.MoveFile(script_dir..zipPath,script_dir.."bin/"..zipPath)
		end
		time_zip = _getUsedTime()
	end
	
	--main_full.zip to main_full.pkg
	ParaAsset.GeneratePkgFile(rootPath..zipPath, rootPath..pkgPath);
	time_pkg = _getUsedTime()

	print("-----------编译脚本耗时:",time_o)
	print("-----------压缩zip耗时:",time_zip)
	print("-----------zip编译pkg耗时:",time_pkg)
	if error_count>0 then
		GameLogic.AddBBS("desktop", L"有编译错误，请重新检查", 5000, "255 0 0"); 
	end
	return rootPath..pkgPath;
end

