--[[
Title: Command Install
Author(s): LiXizhi
Date: 2014/1/22
Desc: slash command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandInstall.lua");
-------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

Commands["install"] = {
	name="install", 
	quick_ref="/install [-mod|bmax] [-filename str] [-ext str][-reload true][-hidetip true][-hideinhand true][-event eventName][url]", 
	desc=[[install a texture package, mod or bmax file from url
/install http://cc.paraengine.com/twiki/pub/CCWeb/Installer/blocktexture_FangKuaiGaiNian_16Bits.zip
/install -mod https://keepwork.com/wiki/mod/packages/packages_install/paracraft?id=12
/install -mod https://cdn.keepwork.com/paracraft/Mod/MovieCodecPluginV9.zip
/install -bmax -filename car https://cdn.keepwork.com/paracraft/officialassets/car.bmax
/install -ext bmax -filename car https://cdn.keepwork.com/paracraft/officialassets/car.bmax
/install -ext fbx -filename car https://cdn.keepwork.com/paracraft/officialassets/car.fbx
/install -ext x -filename car https://cdn.keepwork.com/paracraft/officialassets/car.x
/install -ext blocks -filename car https://cdn.keepwork.com/paracraft/officialassets/car.blocks.xml
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		
		local options = {};
		local option, value;
		while(true) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(not option) then
				break;
			elseif(option == "filename") then
				-- supporting spaces in filename
				local pre_cmd_text = cmd_text;
				value, cmd_text = cmd_text:match("^%s*(.+)%s+(https?://.*)$");
				if cmd_text then
					if(value and value ~= "") then
						value = value:gsub("[& ]+", "_");
					end
					options[option] = value;
				else
					cmd_text = pre_cmd_text;
					value, cmd_text = cmd_text:match("^%s*(.+)%s+(worlds/DesignHouse/.*)$");
					if(value and value ~= "") then
						value = value:gsub("[& ]+", "_");
					end
					options[option] = value;
				end

			elseif(option == "md5" or option == "crc32"  or option == "ext" ) then
				value, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
				options[option] = value;
			elseif(option == "reload")then
				value, cmd_text = CmdParser.ParseBool(cmd_text);
				options[option] = value or value == nil;
			elseif(option == "hideinhand")then
				value, cmd_text = CmdParser.ParseBool(cmd_text);
				options[option] = value or value == nil;
			elseif(option == "hidetip")then
				value, cmd_text = CmdParser.ParseBool(cmd_text);
				options[option] = value or value == nil;
			elseif(option == "event")then
				value, cmd_text = CmdParser.ParseString(cmd_text);
                options[option] = value;
			else
				options[option] = true;
			end
		end

		if(not cmd_text) then
			return 
		end
		local url = cmd_text:gsub("^%s*", ""):gsub("%s*$", "");
		if(options["mod"]) then
			if(url:match("^https?://")) then
				if(url:match("%.zip[^/]*$")) then
					-- download zip directly
					NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
					local ModManager = commonlib.gettable("Mod.ModManager");
					ModManager:GetLoader():InstallFromUrl(url, function(bSucceed, msg, package) 
						LOG.std(nil, "info", "CommandInstall", "bSucceed:  %s: %s", tostring(bSucceed), msg or "");
						if(bSucceed and package) then
							ModManager:GetLoader():LoadPlugin(package.name);
							ModManager:GetLoader():RebuildModuleList();
							ModManager:GetLoader():EnablePlugin(package.name, true, true);
							ModManager:GetLoader():SaveModTableToFile();
						end
					end);
				else
					GameLogic.RunCommand("/show mod")
					ParaGlobal.ShellExecute("open", url, "", "", 1);
				end
			end
		elseif((options["bmax"] or options["ext"]) and options["filename"]) then
			local isLocal = url:match("^worlds/DesignHouse/") 
			if(url:match("^https?://") or isLocal) then
				local filename = options["filename"];
				local ext = options["ext"] or "bmax";
				if(ext ~= "bmax" and ext ~= "x" and ext ~= "fbx" and ext ~= "glb" and ext ~= "gltf" and ext ~= "glb" and ext ~= "gltf" and ext ~= "blocks" and ext ~= "liveModel") then
					LOG.std(nil, "warn", "CommandInstall", "unknown file extension %s for %s", ext, filename);
					return;
				end
				if((ext == "blocks" or ext == "blocks.xml" or ext == "template" or ext == "liveModel") and not filename:match("%.blocks%.xml$")) then
					filename = filename..".blocks.xml";
				elseif(not filename:match("%."..ext.."$")) then
					filename = filename.."."..ext;
				end
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				local dest = ""
				if filename:match("^temp/personnalstore/") or filename:match("^temp/onlinestore/") then
					dest = Files.GetWritablePath()..commonlib.Encoding.Utf8ToDefault(filename)
				else
					filename = "blocktemplates/"..filename;
					if not isLocal then
						dest = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename))
					else
						dest = url
					end
				end
				local function TakeBlockModel_(filename)
					if(options.event ~= "" and options.event ~= nil) then
						GameLogic.GetFilters():apply_filters(options.event, {filename = options["filename"],dir = dest});
					end
					if not options.hidetip then
						GameLogic.AddBBS("install", format(L"模型已经安装到 %s", filename), 3000, "0 255 0");
					end
					if not options.hideinhand then
						if ext == "liveModel" then
							GameLogic.RunCommand(string.format("/take LiveModel {tooltip=%q}", filename));
						else
							GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", filename));
						end
					end
				end

				GameLogic.GetFilters():apply_filters("OnInstallModel", filename, url);


				if(ParaIO.DoesFileExist(dest, true) and not options["reload"]) then
					TakeBlockModel_(filename)
				else
					NPL.load("(gl)script/ide/System/localserver/factory.lua");
					local cache_policy = System.localserver.CachePolicy:new("access plus 1 year");
					local ls = System.localserver.CreateStore();
					if(not ls) then
						log("error: failed creating local server resource store \n")
						return
					end
					if not options.hidetip then
						GameLogic.AddBBS("install", L"正在下载请稍后", 3000, "0 255 0");
					end
					ls:GetFile(cache_policy, url, function(entry)
						if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
							ParaIO.CreateDirectory(dest);
							if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
								Files.NotifyNetworkFileChange(dest)
								TakeBlockModel_(filename)
							else
								LOG.std(nil, "warn", "CommandInstall", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
							end
						end
					end);	
				end
			end
		else
			if(url:match("^https?://")) then
				-- if it is a texture package mod, download and install
				if(url:match("/blocktexture_")) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
					local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
					FileDownloader:new():Init("TexturePack", url, "worlds/BlockTextures/", function(bSucceed, localFileName)
						if(bSucceed) then
							NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
							local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
							TextureModPage.OnApplyTexturePack(localFileName);
							TextureModPage.ShowPage(true);
						else
							_guihelper.MessageBox(localFileName);
						end
					end);
				else
					-- TODO: for world or other mods
				end
			end
		end
	end,
};

Commands["rsync"] = {
	name="rsync", 
	quick_ref="/rsync [-asset] [src]", 
	desc=[[sync all files from source folder. 
-asset only sync remote asset manifest files from src. 
examples:
/rsync -asset D:\lxzsrc\ParaCraftSDKGit\build\ParacraftBuild\res
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		if(options["asset"]) then
			-- sync asset manifest only
			NPL.load("(gl)script/ide/Files.lua");
			local src_folder = cmd_text;
			src_folder = src_folder:gsub("^%s+", "");
			src_folder = src_folder:gsub("%s+$", "");
			if(src_folder ~= "") then
				local result = commonlib.Files.Find({}, src_folder, 10, 50000, function(item)
					return true;
				end)
				if(result) then
					NPL.load("(gl)script/ide/FileLoader.lua");
					local fileLoader = CommonCtrl.FileLoader:new();
					fileLoader:SetMaxConcurrentDownload(5);

					-- reset all replace files just in case texture pack is in effect. 
					ParaIO.LoadReplaceFile("", true);

					for _, file in ipairs(result) do
						if(file.filename and file.filesize~=0) then
							echo(file.filename);
							fileLoader:AddFile(file.filename);
						end
					end
					LOG.std(nil, "info", "rsync", "%d files synced in folder %s", #result, src_folder);
					GameLogic.AddBBS("rsync", string.format("rsync %d files", #result));

					fileLoader:AddEventListener("loading",function(self,event)
						if(event and event.percent)then
							GameLogic.AddBBS("rsync", string.format("rsync progress: %f%%", event.percent*100));
						end
					end,{});
					fileLoader:AddEventListener("finish",function(self,event)
						GameLogic.AddBBS("rsync", string.format("rsync finished: %d files", #result));
					end,{});
					fileLoader:Start();
				end
			end
		end
	end,
};

Commands["signtool"] = {
	name="signtool", 
	quick_ref="/signtool [filename]", 
	desc=[[only used internally, code signing executable files.
If no files are provided, we will sign all default files
e.g.
/signtool
/signtool D:\lxzsrc\ParaEngine\ParaWorld\Paracraft.exe
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local result;
		if(not cmd_text:match("%w")) then
			result = System.os.run("start bin\\SignParaEngineClient.bat");
		else
			local filename = cmd_text;
			result = System.os.run("start bin\\SignParaEngineClient.bat "..filename);
		end
		if(result) then
			_guihelper.MessageBox(result);
		end
	end,
};

Commands["makepkg"] = {
	name="makepkg", 
	quick_ref="/makepkg zip_src|package.txt [pkg_dest]", 
	desc=[[make src zip file to dest pkg file. If dest is not provided, the src zip file extension is changed to pkg. 
pkg is an encrpted zip file and can be used interchangably with zip file in paracraft. 
e.g.
/makepkg test.zip  -- generate test.pkg
/makepkg main_mobile_res   -- internally used

It also takes a text file name, whose content is same as .gitignore, but has the reverse meaning. 
e.g. the following generate paracraft-mini.pkg and paracraft-mini.zip according to package list file
/makepkg packages/redist/paracraft-mini.txt 

]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local src, dest;
		src, cmd_text = CmdParser.ParseFilename(cmd_text);
		dest, cmd_text = CmdParser.ParseOption(cmd_text);

		if(src == "main_mobile_res") then
			NPL.load("(gl)script/installer/BuildParaWorld.lua");
			local error_count = commonlib.BuildParaWorld.MakeZipPackage({"main_mobile_res"}) or 0;
			commonlib.BuildParaWorld.EncryptZipFiles({"main_mobile_res"});
			_guihelper.MessageBox(format("error_count: %d. main_mobile_res.pkg已经生成并覆盖好了，请上传p4. ", error_count or 0), function()
				local absPath = string.gsub(ParaIO.GetWritablePath().."installer/", "/", "\\");
				ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
			end)
		elseif(src) then
			if(src:match("%.zip$")) then
				if(not dest) then
					dest = src:gsub("zip$", "pkg")
				end
				ParaAsset.GeneratePkgFile(src, dest);
			elseif(src:match("%.txt$")) then
				-- make package from reverse of git ignore file
				local packagename = src:match("[^/\\]+$");
				packagename = "installer/"..packagename;
				local zipFileName = packagename:gsub("txt$", "zip")

				NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
				local ZipFile = commonlib.gettable("System.Util.ZipFile");
				local zipFile = ZipFile:new();
				ParaIO.DeleteFile(zipFileName)
				if(zipFile:open(zipFileName, "w")) then
					-- compile to bin folder
					zipFile:SetAutoCompileNPLFile(true)
					local stats = zipFile:AddFromPackageListFile(src)
					zipFile:close();
					zipFile:SaveAsPKG();
					_guihelper.MessageBox(format(L"%s已经生成. %s <br/>是否要打开目录?", zipFileName, commonlib.serialize_compact(stats)), function()
						local absPath = string.gsub(ParaIO.GetWritablePath().."installer/", "/", "\\");
						ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
					end)
				end
			end
		end
	end,
};


Commands["makeapp"] = {
	name="makeapp", 
	quick_ref="/makeapp [UImode] [apk|zip|clean|ppt] [-android|windows]", 
	desc=[[make current world into a standalone app.
It can be windows exe file or android apk file.
e.g.
/makeapp 
/makeapp -android  clean and rebuild android apk file
/makeapp zip -android  only zip everything under temp/paracraft_android folder
/makeapp apk  same as zip -android
/makeapp clean -android  clean everything under temp/paracraft_android folder
/makeapp ppt 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local method, option;
		local beforeCmdText = cmd_text;
		UImode, cmd_text = CmdParser.ParseWord(cmd_text);

		if (not UImode or UImode ~='UImode') then
			cmd_text = beforeCmdText;
		else
			local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
			local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
			local channel = tonumber((WorldCommon.GetWorldTag("channel") or 0))
			if (channel ~= 0)then
				GameLogic.AddBBS("makeapp", L"生成可执行程序失败，当前世界不允许生成可执行程序", 3000, "255 0 0")
				return
			end
			if currentEnterWorld and currentEnterWorld.channel and currentEnterWorld.channel ~= 0 then
				GameLogic.AddBBS("makeapp", L"生成可执行程序失败，当前世界不允许生成可执行程序", 3000, "255 0 0")
				return
			end

			local foldername = currentEnterWorld.foldername or ""
			local regexStr = "^exam_world%d+_%d+_%d+_%d+"
			local regexStr1 = "^%d%d%d%d%d%d%d%d_%d+_%d+"
			if string.match(foldername,regexStr) then
				GameLogic.AddBBS("makeapp", L"生成可执行程序失败，当前世界不允许生成可执行程序", 3000, "255 0 0")
				return
			end
			if System.options.isEducatePlatform then
				local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
				if not is_signed_in then
					GameLogic.GetFilters():apply_filters('check_signed_in', '请先登录', function(result)
						if result == true then
							commonlib.TimerManager.SetTimeout(function()
								NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
								local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
								local task = MyCompany.Aries.Game.Tasks.MakeApp:new()
								task:Run(MakeApp.mode.UI);
							end, 500)
						end
					end)
					return
				end
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
			local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
			local task = MyCompany.Aries.Game.Tasks.MakeApp:new()
			task:Run(MakeApp.mode.UI);
			return;
		end

		method, cmd_text = CmdParser.ParseWord(cmd_text);
		option, cmd_text = CmdParser.ParseOption(cmd_text);

		if(method == "apk") then
			method = "zip"
			option = "android"
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
		local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
		local task = MyCompany.Aries.Game.Tasks.MakeApp:new()

		if(method == "ppt") then
			task:Run(MakeApp.mode.ppt);
		elseif (option == 'android') then
			task:Run(MakeApp.mode.android, method);
		else
			task:Run();
		end
	end,
};

Commands["prepareasset"] = {
	name="prepareasset", 
	quick_ref="/prepareasset filename", 
	desc=[[prepare (download) the given asset file to disk without loading it. 
@return 0 if download has begun, 1 if file is already downloaded, -1 if failed, -2 if input is not an asset file.
e.g.
/prepareasset audio/ambForest.ogg
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local src;
		src, cmd_text = CmdParser.ParseFilename(cmd_text);
		if(src) then
			return ParaIO.SyncAssetFile_Async(src, "");
		end
	end,
};
