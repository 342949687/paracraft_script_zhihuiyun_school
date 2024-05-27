--[[
    NPL.load("(gl)script/apps/Aries/ParacraftCI/FtpUtil.lua");
    local FtpUtil = commonlib.gettable("FtpUtil")
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/Files.lua");
local lfs = commonlib.Files.GetLuaFileSystem();

local FtpUtil = commonlib.inherit(nil,commonlib.gettable("FtpUtil"))

local function _createDir(path)
	if not ParaIO.DoesFileExist(path) then
		if System.os.GetPlatform()=="win32" then
			return ParaIO.CreateDirectory(path)
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

local function _checkCreateDirByFilepath(filepath)
	filepath = commonlib.Files.ToCanonicalFilePath(filepath)
    local div = (System.os.GetPlatform()=="win32") and "\\" or "/"
    local patt = string.format("[^%s]+%s",div,div)
    local temp = ""
    for k,v in string.gmatch(filepath,patt) do
        temp = temp .. k
        if not ParaIO.DoesFileExist(temp) then
            _createDir(temp);
        end
    end
end

function FtpUtil:ctor()
    local curDir = ParaIO.GetCurDirectory(0);
    self.rootDir = curDir
end

function FtpUtil:createWithDevUpdateAddress()
    local obj = FtpUtil:new()
    obj.config = {
        address = "10.27.1.94",
        user = "admin",
        passwd = "SPHEMiDZ4R3Mhf7",
    
        version_url="paracraft/dev_update_source/version",
        filelist_url="paracraft/dev_update_source/filelist",
        p4vRevision_url="paracraft/dev_update_source/p4v.revision",
    }

    local tempDir = obj.rootDir.."temp/"
    _createDir(tempDir)
    tempDir = tempDir.."dev_update_source/"
    _createDir(tempDir)

    if ParaIO.DoesFileExist(tempDir) then
        obj.rootDir = tempDir
    end 

    return obj
end

function FtpUtil:upload(localPath,name)
	self:uploadFiles({
		{localPath,name}
	})
end

--上传文件到 ftp://10.27.1.94/paracraft/dev_update_source/ 目录下
--name可以包含文件夹路径（相对于dev_update_source）
function FtpUtil:uploadFiles(list)
	local config = self.config
	local ftpPath = commonlib.Files.ToCanonicalFilePath(self.rootDir.."/ftp.txt")

	
	local cdCmd = ""
	for _,obj in pairs(list) do 
		local localPath,name = obj[1],obj[2]
		name = name:gsub("\\","/")
		name = name:gsub("//","/")

		local div = "/"
		local patt = string.format("[^%s]+%s",div,div)
		local temp = ""
		for k,v in string.gmatch(name,patt) do
			temp = temp .. k
			cdCmd = cdCmd.."mkdir "..temp.."\n"
		end

	end

	local uploadCmd = ""
	for _,obj in pairs(list) do 
		local localPath,name = obj[1],obj[2]
		uploadCmd = uploadCmd..string.format([[put %s %s]],localPath,name).."\n"
	end

	if System.os.GetPlatform()=="win32" then 
		local fw=ParaIO.open(ftpPath,"w");
		fw:WriteString("open "..config.address.."\n")
		fw:WriteString(config.user.."\n")
		fw:WriteString(config.passwd.."\n")

		local str = [[
			%s
			%s
			bye
		]]
		str = string.format(str,cdCmd,uploadCmd)
		-- print("----------str",str)
		fw:WriteString(str)
		fw:close();

		if System.os.GetPlatform()=="win32" and ParaEngine.GetAttributeObject():GetField("DefaultFileAPIEncoding", "")=="utf-8" then
			ftpPath = ParaIO.ConvertPathFromUTF8ToAnsci(ftpPath)
		end
		local cmdStr = "ftp -s:"..ftpPath
		local file = io.popen(cmdStr)
		if file then
			local output = file:read('*all')
			file:close()
			_deleteFile(ftpPath)
			print("output",output)
			return output,cmdStr
		end
	else
		local cmdStr = [[#!/bin/bash
FTP_USER=@ftp_user@
FTP_PASS=@ftp_passwd@
FTP_IP=@ftp_address@
ftp -n -v $FTP_IP << END
user $FTP_USER $FTP_PASS
%s
%s
bye
END]]
		cmdStr = cmdStr:gsub("@ftp_address@",config.address)
		cmdStr = cmdStr:gsub("@ftp_user@",config.user)
		cmdStr = cmdStr:gsub("@ftp_passwd@",config.passwd)
		cmdStr = string.format(cmdStr,cdCmd,uploadCmd)
		commonlib.Files.WriteFile(ftpPath,cmdStr)
		_deleteFile(ftpPath)
		local result = System.os.run(cmdStr);
		-- print("upload result",result)
		return result,cmdStr
	end
end

function FtpUtil:download(localPath,name)
	return self:downloadFiles({
		{localPath,name}
	})
end

--从dev_update_source下载文件
function FtpUtil:downloadFiles(list)
	local config = self.config
	local ftpPath = commonlib.Files.ToCanonicalFilePath(self.rootDir.."/ftp.txt")

	local downloadCmd = ""
	for _,obj in pairs(list) do 
		local localPath,name = obj[1],obj[2]
		-- print("localPath",localPath)
		_checkCreateDirByFilepath(localPath)
		downloadCmd = downloadCmd..string.format([[get %s %s]],name,localPath).."\n"
	end

	if System.os.GetPlatform()=="win32" then 
		local fw=ParaIO.open(ftpPath,"w");
		fw:WriteString("open "..config.address.."\n")
		fw:WriteString(config.user.."\n")
		fw:WriteString(config.passwd.."\n")

		local str = [[
			%s
			bye
		]]
		str = string.format(str,downloadCmd)
		-- print("----------str",str)
		fw:WriteString(str)
		fw:close();

		-- print("==========ftp命令")
		-- echo(commonlib.Files.GetFileText(ftpPath),true)

		if System.os.GetPlatform()=="win32" and ParaEngine.GetAttributeObject():GetField("DefaultFileAPIEncoding", "")=="utf-8" then
			ftpPath = ParaIO.ConvertPathFromUTF8ToAnsci(ftpPath)
			-- print("2 ftpPath",ftpPath)
		end
		local cmdStr = "ftp -s:"..ftpPath
		local file = io.popen(cmdStr)
		if file then
			local output = file:read('*all')
			file:close()
			_deleteFile(ftpPath)
			print("output",output)
			return output,cmdStr
		end
	else
		local cmdStr = [[#!/bin/bash
FTP_USER=@ftp_user@
FTP_PASS=@ftp_passwd@
FTP_IP=@ftp_address@
ftp -n -v $FTP_IP << END
user $FTP_USER $FTP_PASS
%s
bye
END]]
		cmdStr = cmdStr:gsub("@ftp_address@",config.address)
		cmdStr = cmdStr:gsub("@ftp_user@",config.user)
		cmdStr = cmdStr:gsub("@ftp_passwd@",config.passwd)

		cmdStr = string.format(cmdStr,downloadCmd)
		-- print("downloadFiles cmdStr",cmdStr)
		commonlib.Files.WriteFile(ftpPath,cmdStr)
		local result = System.os.run(cmdStr);
		_deleteFile(ftpPath)
		return result,cmdStr
	end
end

--获取ftp上的文件内容
function FtpUtil:getRemoteText(remotePath)
	local tempPath = commonlib.Files.ToCanonicalFilePath(self.rootDir.."/tempfile.text")
	local output = self:download(tempPath,remotePath)
	if ParaIO.DoesFileExist(tempPath) then
		local ret = commonlib.Files.GetFileText(tempPath)
		_deleteFile(tempPath)
		return ret
	else
		print("-------getRemoteText tempPath不存在",tempPath,remotePath)
		print(output)
	end
end

--下载文本文件
local function ftpdownload_text(url)
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