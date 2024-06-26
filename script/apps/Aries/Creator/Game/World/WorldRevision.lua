--[[
Title: World Revision
Author(s): LiXizhi
Date: 2014/4/28
Desc: a simple revision system for world files
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local world_revision = WorldRevision:new():init(worlddir);
world_revision:Checkout();
if(not world_revision:Commit()) then
	world_revision:Backup();
	world_revision:Commit(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local WorldRevision = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision"));

local backup_folder = "worlds/DesignHouse/backups/";
-- only backup for the most recent 3 days. default to 3.
local max_days_to_backup = 3;
-- max number of backup on the topmost(most recent date). default to 3. 
local max_backups_on_topday = 3;
-- max number of backup on the older days
local max_backups_on_olderday = 1;

function WorldRevision:ctor()

end

function WorldRevision:init(worlddir)
	-- world directory
	self.worlddir = worlddir or ParaWorld.GetWorldDirectory();
	self.worldname = self.worlddir:match("([^/\\]+)[/\\]?$");
	self.revision_filename = self.worlddir.."revision.xml";
	self.current_revision = self.current_revision or 1;
	self.isModified = false;
	self.isModifiedAndNotBackedup = false;
	return self;
end

-- checkout revision. 
function WorldRevision:Checkout()
	self.current_revision = self:GetDiskRevision();
	self.checkoutTime = commonlib.TimerManager.GetCurrentTime();
	return self.current_revision;
end

-- get the current revision
function WorldRevision:GetRevision()
	return self.current_revision;
end

-- load revision. 
function WorldRevision:GetDiskRevision()
	local revision;
	
	local file = ParaIO.open(self.revision_filename, "r");
	if(file and file:IsValid()) then
		revision = tonumber(file:GetText()) or self.current_revision or 1;
		file:close();
	end
	return revision or 1;
end

function WorldRevision:HasConflict()
	if(self:GetDiskRevision() > self:GetRevision()) then
		return true;
	end
end

function WorldRevision:SetModified()
	self.isModified = true;
	self.isModifiedAndNotBackedup = true;
	self.isModifiedAndNotAutoSaved = true;
end

function WorldRevision:SetUnModified()
	self.isModified = false;
	self.isModifiedAndNotBackedup = false;
	self.isModifiedAndNotAutoSaved = false;
end

function WorldRevision:IsModified()
	return self.isModified;
end

function WorldRevision:IsModifiedAndNotBackedup()
	return self.isModifiedAndNotBackedup;
end

function WorldRevision:IsModifiedAndNotAutoSaved()
	return self.isModifiedAndNotAutoSaved;
end

function WorldRevision:SetStageLocked(stageLocked)
	self.stageLocked = stageLocked
end

function WorldRevision:IsStageLocked()
	return self.stageLocked
end

-- @param bForceCommit: if true, it will commit using current version regardless of conflict. 
-- return true if commited successfully. 
function WorldRevision:Commit(bForceCommit)
	if(bForceCommit or not self:HasConflict()) then
		self.current_revision = self:GetRevision() + 1;
		self:SaveRevision();
		return true
	end
end

function WorldRevision:GetBackupFolderFullPath()
	if(not commonlib.Files.IsAbsolutePath(backup_folder)) then
		return ParaIO.GetWritablePath()..backup_folder;
	else
		return backup_folder;
	end
end

function WorldRevision:GetBackupFileName()
	return string.format("%s%s_%s_%d.zip", self:GetBackupFolderFullPath(),self.worldname, ParaGlobal.GetDateFormat("yyyyMMdd"), self:GetRevision());
end

-- backup current revision to zip file if the zip file does not exist. 
function WorldRevision:Backup()
	self:AutoCleanupBackup();
	local filename = self:GetBackupFileName();
	if(not ParaIO.DoesFileExist(filename)) then
		ParaIO.CreateDirectory(filename);
		self:GeneratePackage(filename);
		LOG.std(nil, "info", "WorldRevision", "save world backup to %s", filename);
		self.lastBackupTime = commonlib.TimerManager.GetCurrentTime();
		self.isModifiedAndNotBackedup = false;
		BroadcastHelper.PushLabel({id="backup", label = format(L"版本%d 备份完毕", self:GetRevision()), max_duration=3000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	else
		LOG.std(nil, "error", "WorldRevision", "backup file already exist %s", filename);
		BroadcastHelper.PushLabel({id="backup", label = format(L"版本%d 之前备份过了", self:GetRevision()), max_duration=3000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

function WorldRevision:GetNonBackupTime()
	local curTime = commonlib.TimerManager.GetCurrentTime();
	local lastBackupTime = self.lastBackupTime or self.checkoutTime or curTime;
	return curTime - lastBackupTime;
end

-- get world directory 
function WorldRevision:GetWorldDirectory()
	return self.worlddir;
end

function WorldRevision:OnOpenRevisionDir()
	local folder = self:GetBackupFileName():gsub("[^/\\]*$", "");
	Map3DSystem.App.Commands.Call("File.WinExplorer", folder);
end

-- automatically delete outdated backup files. 
-- it only keeps max_backups_on_olderday copies on max_days_to_backup, 
-- except for the most recent day where max_backups_on_topday is kept. 
function WorldRevision:AutoCleanupBackup()
	local filename = self:GetBackupFileName();
	
	local result = commonlib.Files.Find({}, self:GetBackupFolderFullPath(), 0, 10000, self.worldname.."*.*");
	table.sort(result, function(a, b)
		return (a.filename > b.filename)
	end)

	local top_date;
	local last_date;
	local filecount_on_last_date = 0;
	local date_count = 0;
	for i, file in ipairs(result) do
		local date, revision = file.filename:match("_(%d+)_(%d+)%.zip$");
		if(date and revision) then
			top_date = top_date or date;
			if(date == (last_date or date)) then
				filecount_on_last_date = filecount_on_last_date + 1;
				date_count = 1;
			else
				filecount_on_last_date = 1;
				date_count = date_count + 1;
			end

			local bDeleteFile;
			if(date_count > max_days_to_backup) then
				bDeleteFile = true;
			else
				if(top_date == date) then
					if(filecount_on_last_date > max_backups_on_topday) then
						bDeleteFile = true;
					end
				else
					if(filecount_on_last_date > max_backups_on_olderday) then
						bDeleteFile = true;
					end
				end
			end
			if(bDeleteFile) then
				local filename = self:GetBackupFolderFullPath()..file.filename;
				ParaIO.DeleteFile(filename);
				LOG.std(nil, "info", "WorldRevision", "auto delete backup %s", filename);
			end
			last_date = date;
		end
	end
end

-- compress and generate zip package for the current world.
-- it will ignore ./blockWorld and package ./blockWorld.lastsave   
-- @param filename: the output zip file. 
function WorldRevision:GeneratePackage(filename)
	-- compress the world in self.source, if it is not already compressed
	local worldpath = self:GetWorldDirectory();
	local zipfile = filename;
	local worldname = self.worldname;

	local function MakePackage_()
		local writer = ParaIO.CreateZip(zipfile,"");

		local result = commonlib.Files.Find({}, self:GetWorldDirectory(), 0, 500, function(item)
			return true;
		end)

		for i, item in ipairs(result) do
			local filename = item.filename;
			local filename_lowercased = string.lower(filename)
			if(filename_lowercased=="blockworld.lastsave") then
				local last_world_folder = worldpath..filename.."/";
				local files = commonlib.Files.Find({}, last_world_folder, 0, 500, function(item)
					return true;
				end)
				-- this fixed a bug when zip fails adding the lastsave folder because it looks like a file instead of folder to zip. 
				local dest_folder = worldname.."/blockWorld.lastsave/";
				for _, file in ipairs(files) do
					if(file.filename) then
						writer:AddDirectory(dest_folder, last_world_folder..file.filename, 0);
					end
				end
			elseif(filename_lowercased=="blockworld" or filename_lowercased:match("^%.%w+/?")) then
				-- ignore blockworld, and folder that begins with . like .codeblock
			elseif(filename) then
				local ext = commonlib.Files.GetFileExtension(filename);
				if(ext) then
					-- add all files
					writer:AddDirectory(worldname, worldpath..filename, 0);
				else
					-- add all folders
					writer:AddDirectory(worldname.."/"..filename.."/", worldpath..filename.."/".."*.*", 6);
				end
			end
		end

		-- writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();
		LOG.std(nil, "info", "WorldRevision", "successfully generated package to %s", commonlib.Encoding.DefaultToUtf8(zipfile))
	end
	
	if(ParaIO.DoesFileExist(zipfile)) then
		ParaAsset.CloseArchive(zipfile);
		ParaIO.DeleteFile(zipfile);
	end
	MakePackage_();
end

function WorldRevision:SaveRevision()
	local revision = self:GetRevision();
	local file = ParaIO.open(self.revision_filename, "w");
	if(file and file:IsValid()) then
		file:WriteString(tostring(revision));
		file:close();
		LOG.std(nil, "info", "WorldRevision", "save revision %d for world %s", revision, self.revision_filename);
	end
end

-- update world file size in tag.xml
-- return the new size
function WorldRevision:UpdateWorldFileSize()
	local files = commonlib.Files.Find({}, GameLogic.GetWorldDirectory(), 5, 5000, function(item)
		return true;
	end);
	local filesTotal = 0;
	for key, value in ipairs(files) do
		-- LOG.std(nil,"debug", "file", value);
		filesTotal = filesTotal + tonumber(value.filesize);
	end
	WorldCommon.world_info.size = filesTotal;
	WorldCommon:SaveWorldTag();
	return filesTotal;
end

-- ticks every second
function WorldRevision:Tick()
	
end

function WorldRevision:DeleteStagedChangesInFolder(autoSaveFolder)
	-- get current directory
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()
	commonlib.Files.DeleteFolder(autoSaveFolder)
end

-- stage changes and generate staged files to auto save for the current world.
-- @param autoSaveFolder: if nil, default to current world and current user under /temp/autosave/ folder. 
-- @param bSaveAsMode: if true, we will not delete dest folder and generate auto save file
function WorldRevision:StageChangesToFolder(autoSaveFolder, bSaveAsMode)
	-- get current directory
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()
	if(not bSaveAsMode) then
		commonlib.Files.DeleteFolder(autoSaveFolder)
	end
	ParaIO.CreateDirectory(autoSaveFolder);

	-- stage all changed entity files
	EntityManager.SaveToFile(autoSaveFolder)

	-- save modified raw files
	BlockEngine:SaveToDirectory(autoSaveFolder)

	--GameLogic.CreateGetEditableWorld():Save()
	
	-- finally write the autosave.xml to disk
	if(not bSaveAsMode) then
		local file = ParaIO.open(autoSaveFolder.."autosave.xml", "w");
		if(file and file:IsValid()) then
			local data = {}
			data.date_time = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("HH:mm:ss");
			data.revision = self:GetRevision();
			data.filename = autoSaveFolder;
			file:WriteString(commonlib.serialize(data, true))
			file:close();
		end
	end
	self.isModifiedAndNotAutoSaved = false;
	LOG.std(nil, "info", "WorldRevision", "staged changes to %s", autoSaveFolder); 
end

function WorldRevision:GetAutoSaveFolderName(worldDir)
	worldDir = worldDir or GameLogic.GetWorldDirectory();
	local userName, worldName = string.match(worldDir, "([^/\\]+)[/\\]([^/\\]+)[/\\]?$");
	userName = userName or "no_user"
	worldName = worldName or "no_world"
	local autoSaveFolder = ParaIO.GetWritablePath().. ("temp/AutoSave/"..userName.."_"..worldName.."/");
	return autoSaveFolder;
end

-- apply last staged auto save files to the current world and change disk file.
-- please note this is a dangerous operation as it will overwrite existing files in current world
-- please note if the revision is bigger, we will ignore the operation. 
-- @param autoSaveFolder: if nil, default to current world and current user under /temp/autosave/ folder. 
-- @param worldDir: if nil, default to current world folder.
function WorldRevision:ApplyChangesFromFolderToWorldDir(autoSaveFolder, worldDir)
	-- get current directory
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()
	worldDir = worldDir or GameLogic.GetWorldDirectory();
	local isCurrentWorld = worldDir == GameLogic.GetWorldDirectory();

	-- copy all files from autoSaveFolder to worldDir
	local result = commonlib.Files.Find({}, autoSaveFolder, 2, 500, "*.*")
	for i, item in ipairs(result) do
		local filename = item.filename;
		ParaIO.CopyFile(autoSaveFolder..filename, worldDir..filename, true);
	end
end

-- return true if staged change has revision equal to the current world's revision.
function WorldRevision:CheckStageFolderVersion(autoSaveFolder)
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()
	
	local autosave = commonlib.LoadTableFromFile(autoSaveFolder.."autosave.xml")
	if(autosave and autosave.revision) then
		return (self:GetRevision() == autosave.revision) 
	end
end

-- return nil or a table of {revision, date_time, }
function WorldRevision:GetStagedFolderInfo(autoSaveFolder)
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()
	
	local autosave = commonlib.LoadTableFromFile(autoSaveFolder.."autosave.xml")
	return autosave
end

-- apply last staged auto save files to the current world in memory without changing any disk file.
-- @param autoSaveFolder: if nil, default to current world and current user under /temp/autosave/ folder. 
function WorldRevision:ApplyChangesFromFolder(autoSaveFolder)
	autoSaveFolder = autoSaveFolder or self:GetAutoSaveFolderName()

	local result = commonlib.Files.Find({}, autoSaveFolder, 2, 500, "*.*")
	local regions = {}
	for i, item in ipairs(result) do
		local filename = autoSaveFolder..item.filename;
		local regionX, regionZ = filename:match("(%d+)_(%d+)%.region%.xml$")
		if(regionX) then
			local key = regionX.."_"..regionZ;
			regions[key] = regions[key] or {};
			local region = regions[key];
			region.x = tonumber(regionX);
			region.z = tonumber(regionZ);
			region.regionEntityFile = filename;
		else
			regionX, regionZ = filename:match("(%d+)_(%d+)%.raw$")
			if(regionX) then
				local key = regionX.."_"..regionZ;
				regions[key] = regions[key] or {};
				local region = regions[key];
				region.x = tonumber(regionX);
				region.z = tonumber(regionZ);
				region.regionRawFile = filename
			end
		end
	end

	for _, region in pairs(regions) do
		local x, z = region.x, region.z;
		if(region.regionRawFile or region.regionEntityFile) then
			local regionContainer;
			if(region.regionEntityFile) then
				regionContainer = EntityManager.GetRegionContainer(x*512, z*512)
				regionContainer:SetRegionFileName(region.regionEntityFile);
				regionContainer:SetModified();
			end

			BlockEngine:GetRegionAttr(x, z, function(attrRegion)
				BlockEngine:ClearRegion(x, z)
				attrRegion:SetField("LoadFromFile", region.regionRawFile or "");
				attrRegion:SetField("IsModified", true);
				if(regionContainer) then
					if(not BlockEngine.IsRegionLoaded(x, z)) then
						local lastId = BlockEngine:GetSessionId()
						local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
							if(lastId == BlockEngine:GetSessionId()) then
								if(BlockEngine.IsRegionLoaded(x, z)) then
									timer:Change()
									regionContainer:SetRegionFileName(nil);
								end
							else
								timer:Change()
							end
						end})
						mytimer:Change(50, 100)
					else
						regionContainer:SetRegionFileName(nil);
					end
				end
			end)
		end
	end
	self:SetModified();
end
