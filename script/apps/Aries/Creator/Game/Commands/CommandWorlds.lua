--[[
Title: Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");	
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["save"] = {
	name="save", 
	quick_ref="/save", 
	desc="save the world Ctrl+S", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		local function callback()
			if (GameLogic.GetFilters():apply_filters('is_signed_in'))  then
				if System.options.isEducatePlatform or System.options.channelId_tutorial then
					GameLogic.QuickSave();
				else
					GameLogic.GetFilters():apply_filters(
						"service.keepwork_service_world.limit_free_user",
						false,
						function(result)
							if result then
								GameLogic.QuickSave();
							else
								if GameLogic.GetFilters():apply_filters('check_unavailable_before_open_vip')==true then
									return
								end
								_guihelper.MessageBox(L'操作被禁止了，免费用户最多只能拥有家园+1个本地世界，请删除不要的本地世界，或者联系老师（或家长）开通权限。')
							end
						end,
						true
					);
				end
			else
				GameLogic.QuickSave();
			end
		end

		if GameLogic.GetFilters():apply_filters("SaveWorld", false, callback) then
			return;
		end
		callback();
	end,
};

Commands["autosave"] = {
	name="autosave", 
	quick_ref="/autosave [-checkModified|stage|apply|rollback] [on|off] [mins]", 
	desc=[[automatically save the world every few mins. 
@param interval: how many minutes to auto save the world. 
e.g.
/autosave        :enable auto save
/autosave on     :enable auto save
/autosave off    :disable autosave
/autosave on 10  :enable auto save every 10 minutes
/autosave -stage  :stage current world changes to temp folder which can be recovered later
/autosave -apply : apply staged changes usually from auto save folder in memory.
/autosave -rollback : rollback changes, a restart is preferred over rollback.
/autosave -checkModified on :enable auto save with world modified
/autosave -checkModified on 10:enable auto save with world modified every 10 minutes
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
		local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
		local interval, bEnabled,options;
		options,cmd_text = CmdParser.ParseOptions(cmd_text);
		if options then
			if(options.checkModified) then
				GameLogic.CreateGetAutoSaver():SetCheckModified(options.checkModified)
			elseif(options.stage or options.apply) then
				if(GameLogic.world_revision) then
					if(options.stage) then
						GameLogic.AddBBS("autosave", L"正在自动备份...");
						commonlib.TimerManager.SetTimeout(function()  
							GameLogic.world_revision:StageChangesToFolder();
							GameLogic.AddBBS("autosave", L"自动备份完毕");
						end, 500)
					elseif(options.apply) then
						if(GameLogic.world_revision:CheckStageFolderVersion()) then
							GameLogic.AddBBS("autosave", L"正在从自动备份恢复数据...");
							commonlib.TimerManager.SetTimeout(function()  
								GameLogic.world_revision:ApplyChangesFromFolder();
								GameLogic.AddBBS("autosave", L"数据恢复完毕, 如果正确请尽快存盘");
							end, 500)
						else
							GameLogic.AddBBS("autosave", L"本地数据比备份数据新，操作被忽略");
						end
					end
				end
				return;
			end
		end
		bEnabled, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bEnabled == false) then
			GameLogic.CreateGetAutoSaver():SetTipMode();
			GameLogic.AddBBS("autosave", L"自动保存模式关闭");
		else
			GameLogic.CreateGetAutoSaver():SetSaveMode();
			GameLogic.AddBBS("autosave", L"自动保存模式开启");
		end

		interval, cmd_text = CmdParser.ParseInt(cmd_text);
		if(interval) then
			GameLogic.CreateGetAutoSaver():SetInterval(interval);
		end
	end,
};

Commands["upload"] = {
	name="upload", 
	quick_ref="/upload", 
	desc="upload the world", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(System.options.is_mcworld) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
			local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
			ShareWorldPage.ShowPage()
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
			local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
			WorldUploadPage.ShowPage(true);
		end
	end,
};


Commands["pushworld"] = {
	name="pushworld", 
	quick_ref="/pushworld [displayname]", 
	desc=[[push current world to world stack. The world will be popped from the stack, 
when it is loaded again. 
When there are worlds on the world stack, the esc window will show a big link button to load the world
on top of stack if the current world is different from it. 
@param displayname: the text to display on the big link button which bring the user back to world on top of the stack.
e.g.
/pushworld return to portal world
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldStacks.lua");
		local WorldStacks = commonlib.gettable("MyCompany.Aries.Game.WorldStacks");
		WorldStacks:PushWorld(cmd_text);
	end,
};

-- @param -fork [pid] [newWorldName]: fork a project id and save to a new local world.
-- /loadworld -s -fork 530 new_world_name
Commands["loadworld"] = {
	name="loadworld", 
	quick_ref="/loadworld [-i|e|force|personal|d] [worldname|url|filepath|projectId|home|back]", 
	mode_deny = "", -- allow load world in all game modes
	desc=[[load a world by worldname or url or filepath relative to parent directory
@param -i: interactive mode, which will ask the user whether to use existing world or not. 
@param -e: always use existing world if it exist without checking if it is up to date.  
@param -s: silent load.
@param -d: download the world without loading it. Upon finish, it will /sendevent download_offline_world_finish project_id
@param -forcedownload: always download(again) online world without checking if it is different to local. 
@param -auto|-force: it will check local world revision with remote world, and download ONLY-if remote world is newer. 
@param -inplace: if the entered world is equal to the current world, the subsequent /sendevent command will be executed directly. otherwise, the command will be executed after entering the world. For security reasons, only event that begins with "global" can be sent
@param -personal: login required. always sync online world to local folder, then enter.
e.g.
/loadworld 530
/loadworld https://github.com/xxx/xxx.zip
/loadworld -i https://github.com/xxx/xxx.zip
/loadworld -e https://github.com/xxx/xxx.zip
/loadworld -force 530
/loadworld -personal 530
/loadworld home
/loadworld back
/loadworld -s -inplace 530 | /sendevent globalSetPos  {x, y, z}
/loadworld -d 530
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		cmd_text = GameLogic.GetFilters():apply_filters("cmd_loadworld", cmd_text, options);

		if(not cmd_text) then
			return;
		end

		cmd_text = cmd_text:gsub("\\", "/");
		local filename = cmd_text;
		
		if(filename) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
			local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
			local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
				
			local world;
			local isHttp;

			local function LoadWorld_(world, refreshMode)
				if(world) then
					local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");

						local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
						InternetLoadWorld.LoadWorld(world, nil, refreshMode or "auto", function(bSucceed, localWorldPath)
							DownloadWorld.Close();
						end);
					end});
					-- prevent recursive calls.
					mytimer:Change(1,nil);
				else
					--_guihelper.MessageBox(L"无效的世界文件");
					GameLogic.AddBBS(nil,"进入世界失败，请重试~~~")
					GameLogic.SendErrorLog("CommandWorlds","load world failed","load world failed============"..(cmd_text or ""))

					
					--一般本地目录已经损坏了
					local worldPath  = ""
					if not filename:find("worlds/DesignHouse") then
						local username = Mod.WorldShare.Store:Get("user/username");
						if username and username ~= "" then
							worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. filename
						else
							worldPath = "worlds/DesignHouse/".. filename
						end
					else
						worldPath = filename
					end
					if worldPath ~= "" then --有可能fork失败了，或者加载世界失败了
						local output = commonlib.Files.Find({}, worldPath, 0, 500, 'worldconfig.txt')

						if not output or #output == 0 then
							local delete_result = ParaIO.DeleteFile(worldPath)
							if delete_result ~= 1 then
								print("删除失败···",worldPath)
							end
							GameLogic.GetFilters():apply_filters("user_behavior", 1, "world.fork_or_enter.failed",{world_path=worldPath,result=delete_result,useNoId=true})
						end
					end
				end
			end

			if(filename:match("^https?://")) then
				isHttp = true;
				world = RemoteWorld.LoadFromHref(filename, "self");
				DownloadWorld.ShowPage(filename);
				if(options.i) then
					-- interactive mode, which will ask the user whether to use existing world or not. 
					if(isHttp) then
						local filename = world:GetLocalFileName();
						if(ParaIO.DoesFileExist(filename)) then
							_guihelper.MessageBox(L"世界已经存在，是否重新下载?", function(res)
								if(res == _guihelper.DialogResult.Yes) then
									LoadWorld_(world, "auto");
								elseif(res == _guihelper.DialogResult.No) then
									LoadWorld_(world, "never");
								else
									DownloadWorld.Close();
								end
							end, _guihelper.MessageBoxButtons.YesNoCancel);
						end
					end
					return;
				end
				LoadWorld_(world, options.e and "never" or "auto");
			elseif(filename == "home") then
				GameLogic.CheckSignedIn(L"此功能需要登陆后才能使用",
					function(result)
						if (result) then
							NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
							local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
							local homeWorldPath = LocalLoadWorld.CreateGetHomeWorld()
							if(homeWorldPath) then
								world = RemoteWorld.LoadFromLocalFile(homeWorldPath);
								if(System.world:DoesWorldExist(homeWorldPath, true)) then
									world = RemoteWorld.LoadFromLocalFile(homeWorldPath);
									LoadWorld_(world);
								end
							end
						end
					end)
			else
				local worldpath = commonlib.Encoding.Utf8ToDefault(filename);
				local fileExt = filename:match("%.(%w%w%w)$");

				if(System.world:DoesWorldExist(worldpath, true) or fileExt == "zip" or fileExt == "pkg" or fileExt == "p3d") then
					world = RemoteWorld.LoadFromLocalFile(worldpath);
				else
					if(GameLogic.current_worlddir) then
						-- search relative to current world dir. 
						local parent_dir = GameLogic.current_worlddir:gsub("[^/]+/?$", "")
						local test_worldpath = parent_dir..worldpath;
						if(System.world:DoesWorldExist(test_worldpath, true)) then
							world = RemoteWorld.LoadFromLocalFile(test_worldpath);
						end
					end
				end
				LoadWorld_(world);
			end
			
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
			local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
			InternetLoadWorld.ShowPage(true)
		end
	end,
};

-- alias to /loadworld command
Commands["load"] = {
	name="load", 
	quick_ref="/load [-i|e|force] [worldname|url|filepath|projectId|home]", 
	mode_deny = "", -- allow load world in all game modes
	desc=[[load a world by worldname or url or filepath relative to parent directory
@param -i: interactive mode, which will ask the user whether to use existing world or not. 
@param -e: always use existing world if it exist without checking if it is up to date.  
@param -force: always use online world without checking if it is different to local.  
e.g.
/load 530
/load https://github.com/xxx/xxx.zip
/load -i https://github.com/xxx/xxx.zip
/load -e https://github.com/xxx/xxx.zip
/load -force 530
/load home
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		return Commands["loadworld"].handler(cmd_name, cmd_text, cmd_params);
	end,
};

Commands["terrain"] = {
	name="terrain", 
	quick_ref="/terrain -[r|remove|hole|repair|info|show|hide] [block_radius]", 
	desc=[[make or repair a terrain hole around a block radius (default to 256) of the current player position
/terrain -[remove|hole|r] 256
/terrain -repair 256    repair terrain hole
/terrain -show  show global terrain 
/terrain -hide  hide global terrain 
/terrain -info  query information about the terrain tile 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options = {};
		local option;
		for option in cmd_text:gmatch("%s*%-(%w+)") do 
			options[option] = true;
		end

		local value = cmd_text:match("%s+(%S*)$");

		if(options.show or options.hide) then
			local attr = ParaTerrain.GetAttributeObject()
			local bIsTerrainVisible = attr:GetField("EnableTerrain", true) and attr:GetField("RenderTerrain", true);
			if(options.show and not bIsTerrainVisible) then
				attr:SetField("EnableTerrain", true)
				attr:SetField("RenderTerrain", true)

				local x, y, z = ParaScene.GetPlayer():GetPosition()
				-- we can flatten at the current height if needed
				-- ParaTerrain.Flatten(x,z, 30, 2, y, 1);
				local newY = ParaTerrain.GetElevation(x, z);
				if(newY > y) then
					ParaScene.GetPlayer():SetPosition(x, newY, z)
				end
			elseif(options.hide and bIsTerrainVisible) then
				attr:SetField("EnableTerrain", false)
				attr:SetField("RenderTerrain", false)
			end

			if(options.show) then
				if(System.options.mc and GameLogic.GetSceneContext()) then
					-- leak events to hook chain for old haqi interfaces, such as terrain painting. 
					GameLogic.GetSceneContext():SetAcceptAllEvents(false);
					System.Core.SceneContextManager:SetAcceptAllEvents(false);
				end
				NPL.load("(gl)script/apps/Aries/Creator/MainToolBar.lua");
				local MainToolBar = commonlib.gettable("MyCompany.Aries.Creator.MainToolBar")
				MainToolBar.OnClickTerrainBtn()
			end
		elseif(options.r or options.remove or options.hole or options.repair) then
			-- remove all terrain where the player stand
			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
			if(value) then
				value = tonumber(value);
			end
			local radius = (value or 256)/8;

			local is_making_hole = not options.repair;

			local step = BlockEngine.blocksize*8;
			for i = -radius, radius do 
				for j = -radius, radius do 
					local xx = cx + i * step - 1;
					local zz = cz + j * step - 1;
					if(ParaTerrain.IsHole(xx,zz) ~= is_making_hole) then
						ParaTerrain.SetHole(xx,zz, is_making_hole);
						ParaTerrain.UpdateHoles(xx,zz);
					end
				end
			end
		elseif(options.info or next(options) == nil) then
			-- query info
			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
			local bx, by, bz = BlockEngine:block(cx,cy,cz)
			local tile_x, tile_z = math.floor(bx/512), math.floor(bz/512);
			local o = {
				format("block tile:%d %d", tile_x, tile_z),
				format("block offset:%d %d", bx % 512, bz % 512),
			};
			local text = table.concat(o, "\n");
			LOG.std(nil, "info", "terrain_result", text);
			_guihelper.MessageBox(text);
		end
	end,
};


Commands["loadregion"] = {
	name="loadregion", 
	quick_ref="/loadregion [x y z] [radius]", 
	desc=[[force loading a given region that contains a given point.
/loadregion ~ ~ ~
/loadregion 19200,4,19200
/loadregion 20000 128 20000 200

]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		local x, y, z, radius;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity or EntityManager.GetPlayer());
		if(x) then
			radius, cmd_text = CmdParser.ParseInt(cmd_text);
			radius = radius or 0;
			for i = math.floor((x-radius)/512)*512, math.floor((x+radius)/512)*512, 512 do
				for j = math.floor((z-radius)/512)*512, math.floor((z+radius)/512)*512, 512 do
					ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), i, y, j);
				end
			end
		end
	end,
};


Commands["worldsize"] = {
	name="worldsize", 
	quick_ref="/worldsize radius [center_x center_y center_z]", 
	desc=[[set the world size. mostly used on 32/64bits server to prevent running out of memory. 
Please note, it does not affect regions(512*512) that are already loaded in memory. Combine this with /loadregion command to restrict 
severing of blocks in any shape. 
@param radius: in meters such as 512. 
@param center_x center_y center_z: default to current home position. 
e.g.
/worldsize 256     
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local radius, x,y,z;
		radius, cmd_text = CmdParser.ParseInt(cmd_text);
		if(radius) then
			x,y,z = CmdParser.ParsePos(cmd_text);
			GameLogic.GetWorld():SetWorldSize(x, y, z, radius, BlockEngine.region_height, radius);
		end
	end,
};


Commands["leaveworld"] = {
	name="leaveworld", 
	quick_ref="/leaveworld [-f]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[leaving the world and back to login screen.
@param [-f]: whether to force leave without saving
examples:
/leaveworld -f		:force leaving. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local option, bForceLeave;
		option, cmd_text = CmdParser.ParseOption(cmd_text);
		if(option == "f") then
			bForceLeave = true;
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
		local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
		--Desktop.ForceExit(true);
		--Desktop.OnLeaveWorld(bForceLeave, true);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
		local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
		ParaWorldLoginAdapter:EnterWorld(true);
	end,
};

Commands["saveas"] = {
	name="saveas", 
	quick_ref="/saveas", 
	desc="save the world to another directory", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		WorldCommon.SaveWorldAs()
	end,
};

Commands["setworldinfo"] = {
	name="setworldinfo", 
	quick_ref="/setworldinfo [-isVipWorld true|false]", 
	desc=[[set a given world tag
--this will make world accessible to only vip users
/setworldinfo -isVipWorld true    
/setworldinfo -selectWater true    
/setworldinfo -assetUrl "https://some_cdn_url.zip"
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local option_name = "";
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "isVipWorld") then
				local isVipWorld;
				isVipWorld, cmd_text = CmdParser.ParseBool(cmd_text);
				GameLogic.options:SetVipWorld(isVipWorld);
			elseif(option_name == "assetUrl") then
				local value;
				value, cmd_text = CmdParser.ParseFilename(cmd_text);
				GameLogic.options:SetWorldOption(option_name, value);
			else
				local value;
				value, cmd_text = CmdParser.ParseBool(cmd_text);
				GameLogic.options:SetWorldOption(option_name, value);
			end
		end
	end,
};

Commands["getworldinfo"] = {
	name="getworldinfo", 
	quick_ref="/getworldinfo [name|assetUrl]", 
	desc=[[get a given world tag
/getworldinfo assetUrl
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name = CmdParser.ParseWord(cmd_text)
		if(name) then
			return GameLogic.options:GetWorldOption(name);
		end
	end,
};
Commands["resetworld"] = {
	name="resetworld", 
	quick_ref="/resetworld [-overwrite|replace] [template|projectId]", 
	desc=[[reset a world by template file, replace a world by projectId
@param -overwrite: load template file to overwrite the world. 
@param -replace: download world by projectId, then replace the current world.  
/loadworld -overwrite test.xml
/loadworld -replace 20576
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		if (options.overwrite) then
			if (ParaIO.DoesFileExist(cmd_text)) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
				local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
				ParaWorldMiniChunkGenerator:LoadFromTemplateFile(cmd_text);
			end
		elseif (options.replace) then
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
			WorldCommon.ReplaceWorld(cmd_text);
		end

	end,
};

Commands["clearregion"] = {
	name="clearregion", 
	quick_ref="/clearregion [x y z] [radius]", 
	desc=[[force clear everything in a region
/clearregion ~ ~ ~  clear the region containing the current player
/clearregion 20000 128 20000 200
/clearregion 37 37
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
		local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		local x, y, z, radius;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity or EntityManager.GetPlayer());
		if(x) then
			radius, cmd_text = CmdParser.ParseInt(cmd_text);
			radius = radius or 0;
			for i = math.floor((x-radius)/512)*512, math.floor((x+radius)/512)*512, 512 do
				for j = math.floor((z-radius)/512)*512, math.floor((z+radius)/512)*512, 512 do
					local x = math.floor(i / 512)
					local y = math.floor(j / 512)
					if(x and y and x < 64 and y < 64 and x>=0 and y>=0) then
						local region = ExternalRegion:new():Init(nil, x, y)
						region:ClearRegion()
					end
				end
			end
		else
			x, cmd_text = CmdParser.ParseInt(cmd_text);
			y, cmd_text = CmdParser.ParseInt(cmd_text);
			if(x and y and x < 64 and y < 64 and x>=0 and y>=0) then
				local region = ExternalRegion:new():Init(nil, x, y)
				region:ClearRegion()
			end
		end
	end,
};

Commands["copyregion"] = {
	name="copyregion", 
	quick_ref="/copyregion [-silent|s] fromX fromY toX toY [toWorldName]", 
	desc=[[copy everything from one region to another region
/copyregion 37 37 37 38
-- silently copy region(37,37) to region(37,38) of another world
/copyregion -s 37 37 37 38 lixizhi_main
/copyregion -s 37 37 37 38 c:/temp/absolut_world_path/
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(GameLogic.IsReadOnly()) then
			LOG.std(nil, "warn", "copyregion", "access denied in read only world");
			return
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
		local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local fromX, fromY, toX, toY, toWorldName
		fromX, cmd_text = CmdParser.ParseInt(cmd_text);
		fromY, cmd_text = CmdParser.ParseInt(cmd_text);
		toX, cmd_text = CmdParser.ParseInt(cmd_text);
		toY, cmd_text = CmdParser.ParseInt(cmd_text);
		toWorldName, cmd_text = CmdParser.ParseFilename(cmd_text);
		if(toWorldName) then
			if(not toWorldName:match("[/\\]")) then
				toWorldName = GameLogic.GetWorldDirectory():gsub("[^/]+/?$", commonlib.Encoding.Utf8ToDefault(toWorldName))
			end
			-- TODO: check if the world exists and we own the world, for copy right reasons
		end
		if(fromX and fromY and toX and toY) then
			if(fromX < 64 and fromY < 64 and toX < 64 and toY < 64) then
				local function CopyRegion_()
					local region = ExternalRegion:new():Init(nil, fromX, fromY)
					if(region:HasBlocks()) then
						region:SaveAs(toWorldName, toX, toY)

						if(not toWorldName) then
							local region = ExternalRegion:new():Init(nil, toX, toY)
							region:Load()
						end
					end
				end
				if(options.s or options.silent) then
					CopyRegion_()
				else
					_guihelper.MessageBox(L"[警告] 操作不可逆, 建议先备份世界后再进行。是否任然继续？", function()
						CopyRegion_()
					end)
				end
			end
		end
	end,
};

Commands["moveregion"] = {
	name="moveregion", 
	quick_ref="/moveregion [-silent|s] fromX fromY toX toY [toWorldName]", 
	desc=[[copy everything from one region to another region
/moveregion 37 37 37 38
-- silently copy region(37,37) to region(37,38) of another world
/moveregion -s 37 37 37 38 lixizhi_main
/moveregion -s 37 37 37 38 c:/temp/absolut_world_path/
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(GameLogic.IsReadOnly()) then
			LOG.std(nil, "warn", "moveregion", "access denied in read only world");
			return
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
		local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local fromX, fromY, toX, toY, toWorldName
		fromX, cmd_text = CmdParser.ParseInt(cmd_text);
		fromY, cmd_text = CmdParser.ParseInt(cmd_text);
		toX, cmd_text = CmdParser.ParseInt(cmd_text);
		toY, cmd_text = CmdParser.ParseInt(cmd_text);
		toWorldName, cmd_text = CmdParser.ParseFilename(cmd_text);
		if(toWorldName) then
			if(not toWorldName:match("[/\\]")) then
				toWorldName = GameLogic.GetWorldDirectory():gsub("[^/]+/?$", commonlib.Encoding.Utf8ToDefault(toWorldName))
			end
			-- TODO: check if the world exists and we own the world, for copy right reasons
		end
		if(fromX and fromY and toX and toY) then
			if(fromX < 64 and fromY < 64 and toX < 64 and toY < 64) then
				local function MoveRegion_()
					local region = ExternalRegion:new():Init(nil, fromX, fromY)
					if(region:HasBlocks()) then
						region:SaveAs(toWorldName, toX, toY)

						if(not toWorldName) then
							local region = ExternalRegion:new():Init(nil, toX, toY)
							region:Load()
						end
						region:ClearRegion()
					end
				end
				if(options.s or options.silent) then
					MoveRegion_()
				else
					_guihelper.MessageBox(L"[警告] 操作不可逆, 建议先备份世界后再进行。是否任然继续？", function()
						MoveRegion_()
					end)
				end
			end
		end
	end,
};

Commands["loadregionex"] = {
	name="loadregionex", 
	quick_ref="/loadregionex [world_name] x y", 
	desc=[[load all blocks from "world_path" to region(x,y) of current world.
/loadregionex course_world 37 37
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local world_path;
		world_name, cmd_text = CmdParser.ParseFilename(cmd_text);
		local x, y;
		x, cmd_text = CmdParser.ParseInt(cmd_text);
		y, cmd_text = CmdParser.ParseInt(cmd_text);
		if(world_name and x and y) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
			local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");

			local worldpath;

			if (GameLogic.GetFilters():apply_filters('is_signed_in')) then
				worldpath =
					GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path') ..
					"/" ..
					commonlib.Encoding.Utf8ToDefault(world_name) ..
					"/";

				if not ParaIO.DoesFileExist(worldpath) then
					worldpath = "worlds/DesignHouse/" .. commonlib.Encoding.Utf8ToDefault(world_name);
				end
			else
				worldpath = "worlds/DesignHouse/" .. commonlib.Encoding.Utf8ToDefault(world_name);
			end

			local region = ExternalRegion:new():Init(worldpath, x, y);
			region:Load();
		end
	end,
};


Commands["saveregionex"] = {
	name="saveregionex", 
	quick_ref="/saveregionex [world_name] x y", 
	desc=[[save all blocks in region(x,y) of current world to "world_name".
/saveregionex course_world 37 37
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local world_name;
		world_name, cmd_text = CmdParser.ParseFilename(cmd_text);
		local x, y;
		x, cmd_text = CmdParser.ParseInt(cmd_text);
		y, cmd_text = CmdParser.ParseInt(cmd_text);
		if(world_name and x and y) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
			local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");

			local worldpath;

			if (GameLogic.GetFilters():apply_filters('is_signed_in')) then
				worldpath =
					GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path') ..
					"/" ..
					commonlib.Encoding.Utf8ToDefault(world_name) ..
					"/";

				if not ParaIO.DoesFileExist(worldpath) then
					worldpath = "worlds/DesignHouse/" .. commonlib.Encoding.Utf8ToDefault(world_name);
				end
			else
				worldpath = "worlds/DesignHouse/" .. commonlib.Encoding.Utf8ToDefault(world_name);
			end

			local region = ExternalRegion:new():Init(worldpath, x, y);
			region:Save();
		end
	end,
};

Commands["loadlevel"] = {
	name="loadlevel", 
	quick_ref="/loadlevel [levelname] [-callback  OnLoadLevel]", 
	desc=[[load the game level from "levelname",returns true if the load succeeds
@param -callback the callback after loading the game level
/loadlevel level1 -callback  OnLoadLevel
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local level_name;
		level_name, cmd_text = CmdParser.ParseFilename(cmd_text);
		level_name = level_name or "lastsave"

		local LevelManager = NPL.load("(gl)script/apps/Aries/Creator/Game/World/LevelManager.lua");
		local result = LevelManager.Load(level_name)

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		if options.callback then
			commonlib.TimerManager.SetTimeout(function()  
				GameLogic.RunCommand(string.format("/sendevent %s", cmd_text));
			end, 100);
		end

		return result
	end,
};

Commands["savelevel"] = {
	name="savelevel", 
	quick_ref="/savelevel [levelname] [-region x y] [-exclude_region x y][-with camera|time|sky|bag|pos|] [-check]", 
	desc=[[save game level to "levelname".
@param -region: save all blocks in region(x,y) of current world, if not, save the entire region.
@param -exclude_region: regions to ignore when saving all regions
@param -with: decide which elements to save,if not,save all elements.(bag,pos,camera,time,sky)
@param -check: check that the level exists
/savelevel level1 -check
/savelevel level1 -region 37 37
/savelevel level1 -exclude_region 37 37
/savelevel level1 -region 37 37 -with camera|time|sky|bag|pos|
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local level_name, cmd_text = CmdParser.ParseFilename(cmd_text);
		level_name = level_name or "lastsave"
		-- 处理参数
		local options_cmd_text = commonlib.split(cmd_text,"-")
		local options = {}
		if #options_cmd_text > 0 then
			local cmd_text = options_cmd_text[index]
			for index = 1, #options_cmd_text do
				local cmd_text = "-" .. options_cmd_text[index]
				local option;
				option, cmd_text = CmdParser.ParseOption(cmd_text, true);
				if option then
					options[option] = {}
					if option == "region" or option == "exclude_region" then
						options[option].x = CmdParser.ParseInt(cmd_text)
						options[option].y = CmdParser.ParseInt(cmd_text)
					elseif option == "with" then
						options[option] = commonlib.split(cmd_text,"|")
						-- CmdParser.ParseStringList(cmd_text, options[option])
					end	
				end
			end
		end

		local LevelManager = NPL.load("(gl)script/apps/Aries/Creator/Game/World/LevelManager.lua");
		LevelManager.Save(level_name, options)
	end,
};

Commands["getlevels"] = {
	name="getlevels", 
	quick_ref="/getlevels", 
	desc=[[get all levelNames 
/getlevels
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local LevelManager = NPL.load("(gl)script/apps/Aries/Creator/Game/World/LevelManager.lua");
		local levels = LevelManager.GetLevels()
		local str = ""
		for index = 1, #levels do
			local name = levels[index]
			str = str .. name .. ";"
		end

		return str
	end,
};

Commands["setloginworld"] = {
	name="setloginworld", 
	quick_ref="/setloginworld [projectID]", 
	desc=[[Set up a parent world. Users can then explore and create new worlds, but after all worlds exit, need to return to the parent world
@param self: Indicates the current world id
@param project_id: The parent id
/setloginworld [project_id | self | ]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local param1;
		param1, cmd_text = CmdParser.ParseFilename(cmd_text);
		if param1 == "self" then
			param1 = GameLogic.options:GetProjectId()
		end

		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
		WorldCommon.SetParentProjectId(param1)
	end,
};

Commands['checkworldassessment'] = {
	name="checkworldassessment",
	quick_ref='checkworldassessment [courseId] [projectIds]',
	desc=[[use course config assessment a world
		@param courseId:  the current course id
		@param projectIds: assessment worlds
		/setloginworld [courseId | projectIds ]
		]],
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local param1,param2;
		param1, param2 = CmdParser.ParseFilename(cmd_text);
		local AssessmentQueue = NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/AssessmentQueue.lua")
		AssessmentQueue.Init(param1,param2)
	end,
}

Commands['newworld'] = {
	name="newworld", 
    quick_ref='/newworld worldname [-force] [-worldGenerator name]',
    desc=[[create a new world by world name or from an existing world
@param worldname: this can also be absolute file path like "c:/temp/worldname"
@param -worldGenerator: world type, default to superflat
e.g.
/newworld test
/newworld "test" -force -worldGenerator paraworldMini
]],
    mode_deny = "",
    handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
		local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
		local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
        
		local option = ''
		local forceCreate;
        local name = ''
        local worldGenerator = 'superflat'
        
        option, cmd_text = CmdParser.ParseOption(cmd_text)
        if not option or option == 'name' then
            name, cmd_text = CmdParser.ParseFilename(cmd_text)
        else
            return
        end
        if(not name or name == "") then
            return
        end
		while(true) do
			option, cmd_text = CmdParser.ParseOption(cmd_text)
			if(option == "force") then
				forceCreate = true
			elseif(option == 'worldGenerator') then
				worldGenerator, cmd_text = CmdParser.ParseString(cmd_text)
			else
				break;
			end
		end
        local worldPath
		local creationfolder;
		if(commonlib.Files.IsAbsolutePath(name)) then
			worldPath = name;
			creationfolder, name = worldPath:match("^(.*)/([^/\\]+)$");
			worldPath = worldPath .. "/";
			-- get folder name
			name = name:match("([^/\\]+)$")
		else
			creationfolder = CreateNewWorld.GetWorldFolder();
			worldPath = creationfolder .. '/' .. commonlib.Encoding.Utf8ToDefault(name) .. '/'
		end
            
        local tagPath = worldPath .. 'tag.xml'

        if ParaIO.DoesFileExist(tagPath) then
        	if(forceCreate) then
				ParaIO.DeleteFile(worldPath)
			else
				return
			end
        end

        local params = {
            worldname = commonlib.Encoding.Utf8ToDefault(name),
            title = name,
            creationfolder = creationfolder,
            world_generator = worldGenerator,
            seed = name,
            inherit_scene = true,
            inherit_char = true,
        }
    
		local worldPath, errorMsg = CreateNewWorld.CreateWorld(params)
	end,
}


Commands["freezeworld"] = {
	name="freezeworld", 
	quick_ref="/freezeworld   [true|false]", 
	desc=[[In freezeworld true, only new blocks can be added, and locked blocks which create befoe the freezing command is called
@param true: freeze the world,only can add blocks,can not delete the block befoe the freezing command is called.
@param false: unfreeze the world,you can edit all blocks in this world.
/freezeworld [true|false]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bEnable
		bEnable, cmd_text = CmdParser.ParseBool(cmd_text)
		GameLogic.EditableWorld:FreezeWorld(bEnable)
	end,
};