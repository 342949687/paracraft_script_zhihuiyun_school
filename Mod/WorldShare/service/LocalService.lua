﻿--[[
Title: LocalService
Author(s): big
CreateDate: 2016.12.11
ModifyDate: 2022.5.26
Desc: 
use the lib:
------------------------------------------------------------
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
------------------------------------------------------------
]]

--------- thread part ---------
NPL.load("(gl)script/ide/commonlib.lua")
NPL.load("(gl)script/ide/System/Concurrent/rpc.lua")

local rpc = commonlib.gettable('System.Concurrent.Async.rpc')

rpc:new():init(
    'Mod.WorldShare.service.LocalService.MoveZipToFolderThread',
    function(self, msg)
        local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
        LocalService:MoveZipToFolderThread(msg.rootFolder, msg.zipPath)

        return true 
    end,
    'Mod/WorldShare/service/LocalService.lua'
)

rpc:new():init(
    'Mod.WorldShare.service.LocalService.MoveFolderToZipThread',
    function(self, msg)
        local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
        LocalService:MoveFolderToZipThread(msg.rootFolder, msg.zipPath)

        return true
    end,
    'Mod/WorldShare/service/LocalService.lua'
)
--------- thread part ---------

-- libs
local SystemEncoding = commonlib.gettable("System.Encoding")
local CommonlibEncoding = commonlib.gettable("commonlib.Encoding")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local WorldInfo = commonlib.gettable("MyCompany.Aries.Game.WorldInfo")

local LocalService = NPL.export()

LocalService.filter = "*"
LocalService.nMaxFileLevels = 0
LocalService.nMaxFilesNum = 10000
LocalService.output = {}
LocalService.isGetContent = true
LocalService.isGetFolder = false

function LocalService:LoadFiles(path, NotGetContent, isGetFolder)
    if not path or type(path) ~= 'string' or #path == 0 then
        return {}
    end

    if string.sub(path, #path, #path) == "/" then
        path = string.sub(path, 0, #path - 1)
    end

    self.output = {}
    self.isGetContent = not NotGetContent
    self.isGetFolder = isGetFolder

    local result = self:Find(path)

    self:FilesFind(result, path)

    -- convert default string to utf-8 string
    for _, item in ipairs(self.output) do
        item.filename = CommonlibEncoding.DefaultToUtf8(item.filename)
    end

    return self.output
end

function LocalService:Find(path)
    return commonlib.Files.Find({}, path, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)
end

function LocalService:FilesFind(result, path, subPath)
    local curResult = result
    local curPath = path
    local curSubPath = subPath

    if curResult and type(curResult) == "table" then
        local convertLineEnding = {[".xml"] = true, [".bmax"] = true, [".txt"] = true, [".md"] = true, [".lua"] = true}
        local zipFile = {[".xml"] = true, [".bmax"] = true}

        for key, item in ipairs(curResult) do
            if item.fileattr == 32 then
                -- file
                item.file_path = curPath .. "/" .. item.filename

                if curSubPath then
                    item.filename = curSubPath .. "/" .. item.filename
                end

                local sExt = item.filename:match("%.[^&.]+$")

                if sExt == ".bak" then
                    item = false
                else
                    if self.isGetContent then
                        local bConvert = false
    
                        if convertLineEnding[sExt] and zipFile[sExt] then
                            bConvert = not self:IsZip(item.file_path)
                        elseif (convertLineEnding[sExt]) then
                            bConvert = true
                        end
 
                        if bConvert then
                            item.file_content_t = self:GetFileContent(item.file_path):gsub("\r\n", "\n") or ""
                            item.filesize = #item.file_content_t or 0
                            item.sha1 = SystemEncoding.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                        else
                            item.file_content_t = self:GetFileContent(item.file_path) or ""
                            item.sha1 = SystemEncoding.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                        end
                    end

                    self.output[#self.output + 1] = item
                end
            else
                local newPath = curPath .. "/" .. item.filename
                local newResult = self:Find(newPath)
                local newSubPath = nil

                if curSubPath then
                    newSubPath = curSubPath .. "/" .. item.filename
                else
                    newSubPath = item.filename
                end

                -- folder
                if self.isGetFolder then
                    local curItem = item
                    curItem.filename = newSubPath
                    self.output[#self.output + 1] = curItem
                end

                self:FilesFind(newResult, newPath, newSubPath)
            end
        end
    end
end

function LocalService:GetFileContent(filePath)
    local file = ParaIO.open(filePath, "r")

    if file:IsValid() then
        local fileContent = file:GetText(0, -1)
        file:close()
        return fileContent or ""
    end

    return ""
end

function LocalService:Write(worldpath, path, content)
    if not worldpath or not path or type(content) ~= 'string' then
        return false
    end

    path = CommonlibEncoding.Utf8ToDefault(path)

    local allPath = {}

    for segmentation in string.gmatch(path, "[^/]+") do
        allPath[#allPath + 1] = segmentation
    end

    worldpath = worldpath:gsub("[/\\]$", "")
    
    for key, item in ipairs(allPath) do
        if key ~= #allPath then
            local curFolderPath = ''

            for i=1, key do
                curFolderPath = format("%s/%s", curFolderPath, allPath[i] or '')
            end

            local curCreatePath = format("%s/%s/", worldpath, curFolderPath)
            ParaIO.CreateDirectory(curCreatePath)
        end
    end

    local writePath = format("%s/%s", worldpath, path)

    local write = ParaIO.open(writePath, "w")

    write:write(content, #content)
    write:close()
end

function LocalService:Delete(worldpath, filename)
    worldpath = worldpath:gsub("[/\\]$", "")

    local deletePath = format("%s/%s", worldpath, CommonlibEncoding.Utf8ToDefault(filename or ''))

    ParaIO.DeleteFile(deletePath)
end

-- public static function
-- @return true if filename is zip or pkg file
function LocalService:IsZip(path)
    local file = ParaIO.open(path, "r")
    local fileType = nil

    if (file:IsValid()) then
        local o = {}
        file:ReadBytes(4, o)

        if (o[1] == 80 and o[2] == 75) then
            fileType = "zip"
		elseif (o[1] == 0x2e and o[2] == 0x70 and o[3] == 0x6b and o[4] == 0x67) then -- 2e 70 6b 67 is hex of ".pkg"
            fileType = "pkg"
        end

        file:close()
    end

    return fileType ~= nil
end

function LocalService:MoveFolderToZip(rootFolder, zipPath, callback)
    Mod.WorldShare.service.LocalService.MoveFolderToZipThread(
        '(worker_move_folder_to_zip)',
        {
            rootFolder = rootFolder,
            zipPath = zipPath
        },
        function(err, msg)
            if callback and type(callback) == 'function' then
                callback()
            end
        end
    )
end

function LocalService:MoveFolderToZipThread(rootFolder, zipPath)
    local fileList = LocalService:LoadFiles(rootFolder, true, false)
    
    if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
        return
    end

    local writer = ParaIO.CreateZip(zipPath, '')

    for key, item in ipairs(fileList) do
        writer:ZipAdd(commonlib.Encoding.Utf8ToDefault(item.filename), item.file_path)
    end

    writer:close();
end

function LocalService:MoveZipToFolder(rootFolder, zipPath, callback)
    Mod.WorldShare.service.LocalService.MoveZipToFolderThread(
        '(worker_move_zip_to_folder)',
        {
            rootFolder = rootFolder,
            zipPath = zipPath,
        },
        function(err, msg)
            if callback and type(callback) == 'function' then
                callback()
            end
        end
    )
end

function LocalService:MoveZipToFolderThread(rootFolder, zipPath)
    if not rootFolder or not ParaAsset.OpenArchive(zipPath, true) then
        LOG.std(nil,"info","LocalService:MoveZipToFolderThread","open archive error")
        return false
    end

    ParaIO.CreateDirectory(rootFolder)

    local zipParentDir = zipPath:gsub("[^/\\]+$", "")
    local fileList = {}

    -- ":.", any regular expression after : is supported. `.` match to all strings.
    commonlib.Files.Find(fileList, '', 0, 10000, ":.", zipPath)

    for key, item in ipairs(fileList) do
        if item.filesize > 0 then
            local segmentationArray = {}

            for segmentation in string.gmatch(item.filename, "[^/]+") do
                segmentationArray[#segmentationArray + 1] = segmentation
            end

            if #segmentationArray > 1 then
                -- create folder and copy file
                local folderPath = rootFolder

                for Skey, SItem in ipairs(segmentationArray) do
                    if Skey == #segmentationArray then
                        -- file
                        local filename = SItem

                        -- tricky: we do not know which encoding the filename in the zip archive is,
                        -- so we will assume it is utf8, we will convert it to default and then back to utf8.
                        -- if the file does not change, it might be utf8. 
                        local trueFilename = ''
                        local defaultEncodingFilename = CommonlibEncoding.Utf8ToDefault(filename)

                        if defaultEncodingFilename == filename then
                            trueFilename = filename
                        else
                            if CommonlibEncoding.DefaultToUtf8(defaultEncodingFilename) == filename then
                                trueFilename = defaultEncodingFilename
                            else
                                trueFilename = filename
                            end
                        end

                        filename = trueFilename

                        local readFile = ParaIO.open(zipParentDir .. item.filename, "r")

                        if readFile:IsValid() then
                            local content = readFile:GetText(0, -1)
                            local filePath = folderPath .. filename
                            local writeFile = ParaIO.open(filePath, "w")

                            if writeFile:IsValid() then
                                writeFile:write(content, #content)
                                writeFile:close()
                            end

                            readFile:close()
                        end
                    else
                        local foldername = SItem

                        -- tricky: we do not know which encoding the filename in the zip archive is,
                        -- so we will assume it is utf8, we will convert it to default and then back to utf8.
                        -- if the file does not change, it might be utf8. 
                        local trueFolderName = ''
                        local defaultEncodingFolderName = CommonlibEncoding.Utf8ToDefault(foldername)

                        if defaultEncodingFolderName == foldername then
                            trueFolderName = foldername
                        else
                            if CommonlibEncoding.DefaultToUtf8(defaultEncodingFolderName) == foldername then
                                trueFolderName = defaultEncodingFolderName
                            else
                                trueFolderName = foldername
                            end
                        end

                        foldername = trueFolderName

                        -- folder
                        folderPath = folderPath .. foldername .. '/'

                        ParaIO.CreateDirectory(folderPath)
                    end
                end
            else
                -- just copy file
                local readFile = ParaIO.open(zipParentDir .. item.filename, "r")

                if readFile:IsValid() then
                    local content = readFile:GetText(0, -1)
                    local filePath = rootFolder .. segmentationArray[1]
                    local writeFile = ParaIO.open(filePath, "w")

                    if writeFile:IsValid() then
                        writeFile:write(content, #content)
                        writeFile:close()
                    end

                    readFile:close()
                end
            end
        end
    end

    ParaAsset.CloseArchive(zipPath)
end

-- get all world total files size
function LocalService:GetWorldSize(worldpath)
    local files =
        commonlib.Files.Find(
        {},
        worldpath,
        5,
        5000,
        function(item)
            return true
        end
    )

    local filesTotal = 0
    for key, value in ipairs(files) do
        filesTotal = filesTotal + tonumber(value.filesize)
    end

    return filesTotal
end

function LocalService:GetZipWorldSize(path)
    return ParaIO.GetFileSize(path)
end

function LocalService:GetZipProjectId(path)
    local parentPath = path:gsub('[^/\\]+$', '')

    ParaAsset.OpenArchive(path, true)

    local projectId = 0
    local output = {}

    commonlib.Files.Find(output, '', 0, self.nMaxFilesNum, ':tag.xml', path)

    if #output ~= 0 then
        local zipFileName = nil

        if #output > 1 then
            for key, item in ipairs(output) do
                if string.match(item.filename, '[^/]+/tag.xml') == item.filename then
                    zipFileName = item.filename
                end
            end
        else
            zipFileName = output[1].filename
        end

        if zipFileName then
            local xmlRoot = ParaXML.LuaXML_ParseFile(parentPath .. zipFileName)

            local worldInfo = WorldInfo:new()

            if xmlRoot then
                local node

                for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
                    worldInfo:LoadFromXMLNode(node);
                    break
                end
            end

            if worldInfo and type(worldInfo) == 'table' then
                projectId = worldInfo.kpProjectId
            end
        end
    end

    ParaAsset.CloseArchive(path)

    if not projectId then
        projectId = 0
    end

    return projectId
end

function LocalService:GetRevision(worldpath)
    if not string.match(worldpath, '/$') then
        worldpath = worldpath .. '/'
    end

    local file = ParaIO.open(worldpath .. 'revision.xml', 'r')

    if file:IsValid() then
        revision = file:GetText(0, -1)
        file:close()
    end

    if not revision then
        revision = 0
    end

    return tonumber(revision)
end

function LocalService:GetZipRevision(path)
    local parentPath = path:gsub('[^/\\]+$', '')

    ParaAsset.OpenArchive(path, true)

    local revision = 0
    local output = {}

    commonlib.Files.Find(output, '', 0, self.nMaxFilesNum, ':revision.xml', path)

    if #output ~= 0 then
        local zipFileName = nil

        if #output > 1 then
            for key, item in ipairs(output) do
                if string.match(item.filename, '[^/]+/revision.xml') == item.filename then
                    zipFileName = item.filename
                end
            end
        else
            zipFileName = output[1].filename
        end

        if zipFileName then
            local file = ParaIO.open(parentPath .. zipFileName, 'r')

            if file:IsValid() then
                revision = file:GetText(0, -1)
                file:close()
            end
        end
    end

    ParaAsset.CloseArchive(path)

    if not revision then
        revision = 0
    end

    return revision
end

function LocalService:IsFileExistInZip(path, filter)
    ParaAsset.OpenArchive(path, true)

    local output = {}

    commonlib.Files.Find(output, "", 0, self.nMaxFilesNum, filter or "", path)

    ParaAsset.CloseArchive(path)

    if #output > 0 then
        return true
    else
        return false
    end
end

function LocalService:SetTag(worldpath, newTag)
    if type(worldpath) == "string" and type(newTag) == "table" then
        local saveWorldHandler = SaveWorldHandler:new():Init(worldpath)

        if saveWorldHandler then
            return saveWorldHandler:SaveWorldInfo(newTag)
        else
            return false
        end
    end
end

function LocalService:GetTag(worldpath)
    if not worldpath then
        return {}
    end

    local saveWorldHandler = SaveWorldHandler:new():Init(worldpath)

    if not saveWorldHandler then
        return {}
    end

    local tag = saveWorldHandler:LoadWorldInfo()

    if tag and type(tag) == 'table' then
        return tag
    else
        return {}
    end
end

function LocalService:GetClientVersion(node)
    return System and System.options and System.options.ClientVersion and System.options.ClientVersion
end

function LocalService:ClearUserWorlds()
    local userworldsPath = format("%s/%s", LocalLoadWorld.GetWorldFolderFullPath(), "userworlds")

    local fileLists = commonlib.Files.Find(nil, userworldsPath, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)

    for key, item in ipairs(fileLists) do
        if item.fileattr and item.fileattr == 16 then
            if (GameLogic.RemoveWorldFileWatcher) then
                GameLogic.RemoveWorldFileWatcher()
            end

            commonlib.Files.DeleteFolder(format("%s/%s", userworldsPath, item.filename))
        end

        if item.fileattr and item.fileattr == 0 then
            ParaIO.DeleteFile(format("%s/%s", userworldsPath, item.filename))
        end
    end
end

function LocalService:TouchFolder(...)
    commonlib.Files.TouchFolder(...)
end
