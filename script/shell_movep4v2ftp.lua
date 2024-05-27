--[[
Title: 
Author(s):  hyz
Date: 2023/2/6

获取p4的最近的文件改变,然后同步到ftp，并更新ftp的清单文件和版本号
------------------------------------------------------------
For server build, the command line to use this shell is below. 
- under windows, it is "bootstrapper=\"script/shell_movep4v2ftp.lua\"". 
- under linux shell script, it is 'bootstrapper="script/shell_movep4v2ftp.lua"'
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/System/os/run.lua");
NPL.load("(gl)script/ide/Files.lua");
local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua");


NPL.load("(gl)script/apps/Aries/ParacraftCI/FtpUtil.lua");
local FtpUtil = commonlib.gettable("FtpUtil")
local ftp_util = FtpUtil.createWithDevUpdateAddress()

local lfs = commonlib.Files.GetLuaFileSystem();

main_state = nil;

local function _createDir(path)
	if not ParaIO.DoesFileExist(path) then
        return lfs.mkdir(path)
    end
end 

local function _deleteFile(path)
	if ParaIO.DoesFileExist(path) then
		os.remove(path)
	end
end

local function _getMd5(path)
	local file = ParaIO.open(path , "rb");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		file:close();

		local md5 = ParaMisc.md5(text)
		return md5
	else
		file:close();
		commonlib.echo(string.format("get md5 failed! %s\n",path))
	end	
end


local curDir = ParaIO.GetCurDirectory(0);
local tempDir = curDir.."temp/"
_createDir(tempDir)
tempDir = tempDir.."dev_update_source_1/"

local p4v_filelistPath = commonlib.Files.ToCanonicalFilePath(tempDir.."/filelist.p4v")
local script_filelistPath = commonlib.Files.ToCanonicalFilePath(tempDir.."/filelist.pkg.")
local mod_filelistPath = commonlib.Files.ToCanonicalFilePath(tempDir.."/filelist.mod.")

local ftpRootUrl = "paracraft/dev_update_source_1"

local remote_p4vListUrl = ftpRootUrl.."/filelist.p4v"
local remote_pkgListUrl = ftpRootUrl.."/filelist.pkg."
local remote_modListUrl = ftpRootUrl.."/filelist.mod."
local remote_p4vRevisionUrl = ftpRootUrl.."/p4v.revision"
local remote_versionUrl = ftpRootUrl.."/version"

--检查p4有无更新，有的话，获取改变的文件的清单
--p4v_diff_num表示p4v拉取最近的多少次提交的changelist
local function checkP4vChangelist(p4v_diff_num)
	local p4address = ""
	if System.os.GetPlatform()=="linux" then
		p4address = "-p 10.27.2.200:1666"
	end
	--通过p4命令，获取最近一次的revisionTag
	local cmdStr = string.format("p4 %s changelists -m 1",p4address)
	local cmdResult = System.os.run(cmdStr)
	if cmdResult==nil or cmdResult=="" then
		commonlib.echo(string.format([[1 run command failed : %s\n,cmdResult = %s\n]],"p4 %s changelists -m 1",p4address,cmdResult));
		return
	end
	local revisionStr = cmdResult:match("%d+")
	if revisionStr==nil or tonumber(revisionStr)==nil then
		commonlib.echo(string.format("get revision failed,cmdResult:%s",cmdResult))
		return
	end
	
	if not ParaIO.DoesFileExist(tempDir) then
		commonlib.echo(string.format("11 create dir:%s\n",tempDir))
		_createDir(tempDir)
	end
	
	local lastRevisionStr = ftp_util:getRemoteText(remote_p4vRevisionUrl) --上次运行的时候，记录的p4 revision
	if p4v_diff_num~=nil and p4v_diff_num~="" then --如果有传参 p4v_diff_num，以传参为准
		lastRevisionStr = (tonumber(revisionStr)-p4v_diff_num)..""
	end
	commonlib.echo(string.format("lastRevisionStr=%s\n",lastRevisionStr))
	if lastRevisionStr==revisionStr then --如果跟上次的相等，就不处理
		return "nochange"
	else
		if lastRevisionStr==nil then --上次的为空,默认取最近的50次提交
			lastRevisionStr = (tonumber(revisionStr)-50)..""
		end
		cmdStr = string.format("p4 %s sync",p4address)
		System.os.run(cmdStr)
	end

	--通过p4命令，获取跟上次运行时相比，有变化的文件列表
	cmdStr = string.format("p4 %s files //paracraft/...@%s,@%s",p4address,lastRevisionStr,revisionStr)
	cmdResult = System.os.run(cmdStr)
	commonlib.echo(string.format("cmdStr=%s,\ncmdResult=%s\n",cmdStr,tostring(cmdResult)))
	if cmdResult==nil or cmdResult=="" then
		commonlib.echo(string.format([[3 run command failed : %s\n,cmdResult = %s\n]],cmdStr,cmdResult));
		return
	end
	local arr = commonlib.split(cmdResult,"\n")

	commonlib.echo("---------arr:\n")
	commonlib.echo(arr,true)

	--获取本地p4目录的client root
	cmdStr = string.format("p4 %s -F %%clientRoot%% -ztag info",p4address)
	local p4vRootPath = System.os.run(cmdStr)
	if p4vRootPath==nil or p4vRootPath=="" then
		commonlib.echo(string.format([[4 run command failed : %s\n,cmdResult = %s\n]],cmdStr,p4vRootPath));
		return
	end
	p4vRootPath = p4vRootPath:gsub("[\n%s]+$", "") --去掉尾部可能的换行和空格

	local includes = {
		".*%.pkg",
		".*%.exe",
		".*%.dll",
		"Texture/.*",
		-- "npl_packages/.*",
		"model/.*",
	}
	local excludes = {
		"main150727.pkg",
		"npl_packages/ParacraftBuildinMod.zip",
	}
	local function checkInclude(path)
		for k,v in pairs(excludes) do 
			if path:match("paracraft/"..v) then
				return false 
			end
		end
		for k,v in pairs(includes) do 
			if path:match("paracraft/"..v) then
				return true 
			end
		end
		return false
	end

	--需要记录的文件绝对路径列表
	local changelist = {}
	for k,v in pairs(arr) do 
		local path = v:match("//(.*)#")
		path = path:gsub("[\n%s]+$", "")
		local isDelete = v:match("delete change (%d+)")
		-- if isDelete then
		-- 	print("===========isDelete",isDelete,path)
		-- end
		if not isDelete and checkInclude(path) then
			local absPath = commonlib.Files.ToCanonicalFilePath(p4vRootPath.."/"..path)
			local filename = path:gsub("^paracraft/","")
			changelist[filename] = absPath
		end
	end
	commonlib.echo("changelist:")
	commonlib.echo(changelist,true)

	return changelist,revisionStr
end

--检查changelist的每个文件的md5码，存成本地filelist，然后跟跟远程的filelist比较
--如果有变化，则返回本地路径
local function checkUpdateFilelist(params)
	local changelist = params.changelist or {}
	local listStr = params.remote_listStr
	local relativeFloder = params.relativeFloder
	
	local md5Set = {}
	for k,v in pairs(changelist) do 
		local md5 = _getMd5(v)
		if md5 then
			local filename = k
			md5Set[filename] = md5
		end
	end
	commonlib.echo("md5Set:")
	commonlib.echo(md5Set,true)

	--修改并上传filelist
	print("1----00=====listStr",listStr)
	local list = {}
	
	if listStr then
		list = commonlib.totable(listStr)
		
		commonlib.echo("list:")
		commonlib.echo(list,true)
	end
	local newMd5Set = {} --有差异的文件列表(只上传有差异的文件)
	for k,v in pairs(md5Set) do 
		local key = relativeFloder.."/"..k
		if list[key]~=v then
			newMd5Set[k] = changelist[k]
		end
		list[key] = v
	end
	
	local newListStr = commonlib.serialize(list,true)

	--清单文件没有发生改变
	if newListStr==listStr then
		print("-------filelist is same,break 22,relativeFloder:",relativeFloder)
		return "nochange",newMd5Set
	end
	
	print("======newMd5Set:")
	echo(newMd5Set,true)

	return newListStr,newMd5Set
end

--远程版本号，记录为日期
local function uploadVersion()
	local versionPath = commonlib.Files.ToCanonicalFilePath(tempDir.."/version")

	local versionStr = os.date("%Y%m%d%H%M%S")
	print("======versionStr",versionStr)
	commonlib.Files.WriteFile(versionPath,versionStr)
	ftp_util:upload(versionPath,ftpRootUrl.."/version")
	_deleteFile(versionPath)
end

--上传最新的p4Revision
local function uploadP4vRevision(revisionStr)
	local revisionPath = commonlib.Files.ToCanonicalFilePath(tempDir.."/revision.temp")
	commonlib.Files.WriteFile(revisionPath,revisionStr)
	ftp_util:upload(revisionPath,ftpRootUrl.."/p4v.revision")
	_deleteFile(revisionPath)
end


local function activate()
	-- commonlib.echo("heart beat: 30 times per sec");
	if(main_state==0) then
		-- this is the main game 
	elseif(main_state==nil) then
		main_state=0;
		log("Hello World from script/shell_movep4v2ftp.lua\n")
		local refresh_p4v = ParaEngine.GetAppCommandLineByParam("refresh_p4v", "")
		local build_pkg = ParaEngine.GetAppCommandLineByParam("build_pkg", "")~="false" --是否打包main150727.pkg，默认为true，除非手动设置为false
		local build_mod = ParaEngine.GetAppCommandLineByParam("build_mod", "")~="false" ----是否打包ParacraftBuildinMod.zip，默认为true，除非手动设置为false
		local pkg_targetBranch = ParaEngine.GetAppCommandLineByParam("pkg_targetBranch", "dev") --打包main150727.pkg的时候，使用哪个分支（默认dev）
		local pkg_compareTagOrId = ParaEngine.GetAppCommandLineByParam("pkg_compareTagOrId", "29001") --打包main150727.pkg的时候，使用哪次提交为对比基准（以最近一次打包main.pkg的时机为准,目前是tag=29001）
		local mod_targetBranch = ParaEngine.GetAppCommandLineByParam("mod_targetBranch", "master") --打包Mod的时候，传入的参数（主要是WorldShare、GGS、AutoUpdater这三个Mod的分支名）
		local p4v_diff_num = ParaEngine.GetAppCommandLineByParam("p4v_diff_num", "") --p4v跟向前多少次的提交比较,可以不传，默认跟上次记录的比较，如果上次没有记录，也没有传参，则默认为50

		print("pkg_targetBranch:",pkg_targetBranch)
		print("pkg_compareTagOrId:",pkg_compareTagOrId)
		print("mod_targetBranch:",mod_targetBranch)
		print("build_mod:",build_mod)
		print("build_pkg:",build_pkg)
		local build_pkgFullPath,build_modFullPath
		if build_pkg then 
			build_pkgFullPath = ParacraftCI.Build_main150727_pkg(nil,pkg_compareTagOrId,pkg_targetBranch);
		end

		if build_mod then 
			build_modFullPath = ParacraftCI.BuildMod(mod_targetBranch);
		end

		repeat 

			local function _dealWithFileList(changelist,remote_listUrl,filelistPath,remoteRelativeFloder)
				local remote_listStr = ftp_util:getRemoteText(remote_listUrl)
				local p4ListStr,newMd5Set = checkUpdateFilelist({
					changelist = changelist,
					relativeFloder = remoteRelativeFloder,
					remote_listStr = remote_listStr,
				})

				commonlib.Files.WriteFile(filelistPath,p4ListStr)
				if filelistPath=="nochange" then
					-- _deleteFile(filelistPath)
					filelistPath = nil
				end
				
				--上传差异文件到ftp
				local uploadArr = {}
				for k,v in pairs(newMd5Set) do
					table.insert(uploadArr,{v,ftpRootUrl.."/"..remoteRelativeFloder.."/"..k})
				end
				-- print("============uploadArr:")
				-- echo(uploadArr,true)
				if #uploadArr>0 then
					local retStr,cmdStr = ftp_util:uploadFiles(uploadArr)
					-- print("======retStr",retStr)
					-- print("======cmdStr",cmdStr)
				end

				--上传清单文件
				if filelistPath then
					ftp_util:upload(filelistPath,remote_listUrl)
					-- _deleteFile(filelistPath)
				end
			end

			--获取p4v的差异列表,sync到本地，然后再同步到ftp
			local p4v_changelist,revisionStr = checkP4vChangelist(p4v_diff_num)
			if p4v_changelist~="nochange" then
				uploadP4vRevision(revisionStr)
				
				_dealWithFileList(p4v_changelist,remote_p4vListUrl,p4v_filelistPath,"p4v_upload")
			else
				commonlib.echo("p4v revision is not change")
				p4v_changelist = nil
			end
			if build_modFullPath then 
				local changelist = {
					["npl_packages/ParacraftBuildinMod.zip"] = build_modFullPath
				}
				_dealWithFileList(changelist,remote_modListUrl..mod_targetBranch,mod_filelistPath..mod_targetBranch,"build_mod_"..mod_targetBranch)
			end
			if build_pkgFullPath then 
				local changelist = {
					["main150727.pkg"] = build_pkgFullPath,
				}
				_dealWithFileList(changelist,remote_pkgListUrl..pkg_targetBranch,script_filelistPath..pkg_targetBranch,"build_pkg_"..pkg_targetBranch)
			end
			
			uploadVersion()

			commonlib.echo("Compile END !");
		until true


		ParaGlobal.Exit(0);
	end	
end
NPL.this(activate);