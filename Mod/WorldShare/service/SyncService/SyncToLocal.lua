--[[
Title: SyncToLocal
Author(s): big
CreateDate: 2018.6.20
ModifyDate: 2022.7.1
Place: Foshan 
use the lib:
------------------------------------------------------------
local SyncToLocal = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua')
------------------------------------------------------------
]]

-- libs
local Encoding = commonlib.gettable('commonlib.Encoding')

-- service
local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkServiceProject = NPL.load('../KeepworkService/KeepworkServiceProject.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')

-- bottles
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')

local SyncToLocal = NPL.export()

local UPDATE = 'UPDATE'
local DELETE = 'DELETE'
local DOWNLOAD = 'DOWNLOAD'

function SyncToLocal:Init(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        return
    end

    self.currentWorld = currentWorld
    self.broke = false
    self.finish = false
    self.callback = callback

    -- we build a world folder path if worldpath is not exit
    if not self.currentWorld.worldpath or self.currentWorld.worldpath == '' then
        local userId = Mod.WorldShare.Store:Get('user/userId')

        -- update shared world path
        if self.currentWorld.user and
           self.currentWorld.user.id and
           tonumber(self.currentWorld.user.id) ~= tonumber(userId) then
            self.currentWorld.worldpath = Encoding.Utf8ToDefault(
                format(
                    '%s/_shared/%s/%s/',
                    LocalServiceWorld:GetDefaultSaveWorldPath(),
                    self.currentWorld.user.username,
                    self.currentWorld.foldername
                )
            )
        else
            self.currentWorld.worldpath =
                Encoding.Utf8ToDefault(
                    format(
                        '%s/%s/',
                        LocalServiceWorld:GetUserFolderPath(),
                        self.currentWorld.foldername
                    )
                )
        end

        self.currentWorld.remotefile = 'local://' .. self.currentWorld.worldpath
    end

    if not self.currentWorld.worldpath or self.currentWorld.worldpath == '' then
        self.callback(false, L'下载失败，原因：下载目录为空')
        return
    end

    self:SetFinish(false)

    if not self.currentWorld.lastCommitId then
        self.callback(false, L'commitId不存在')
        return
    end

    self:Start()

    return self
end

function SyncToLocal:Start()
    self.compareListIndex = 1
    self.compareListTotal = 0

    self.callback(false, { method = 'UPDATE-PROGRESS', current = 0, total = 0, msg = L'正在对比文件列表...' })

    local function Handle(data, err)
        if not data or type(data) ~= 'table' then
            self.callback(false, L'获取列表失败（下载）')
            self:SetFinish(true)
            return
        end

        if self.currentWorld.status == 2 and #data ~= 0 then
            self:DownloadZIP()
            return
        end

        if #data == 0 then
            self.callback(false, 'NEWWORLD')
            self:SetFinish(true)
            return false
        end

        self.localFiles = commonlib.vector:new()
        self.localFiles:AddAll(LocalService:LoadFiles(self.currentWorld.worldpath))
        self.dataSourceFiles = data

        self.localFiles = Compare:IgnoreFiles(self.currentWorld.worldpath, self.localFiles)
        self:GetCompareList()
        self:HandleCompareList()
    end

    GitService:GetTree(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        self.currentWorld.lastCommitId,
        Handle
    )
end

function SyncToLocal:GetCompareList()
    self.compareList = commonlib.vector:new()

    for DKey, DItem in ipairs(self.dataSourceFiles) do
        local bIsExisted = false

        for LKey, LItem in ipairs(self.localFiles) do
            if (DItem.path == LItem.filename) then
                bIsExisted = true
                break
            end
        end

        local currentItem = {
            file = DItem.path,
            status = bIsExisted and UPDATE or DOWNLOAD
        }

        self.compareList:push_back(currentItem)
    end

    for LKey, LItem in ipairs(self.localFiles) do
        local bIsExisted = false

        for DKey, DItem in ipairs(self.dataSourceFiles) do
            if LItem.filename == DItem.path then
                bIsExisted = true
                break
            end
        end

        if not bIsExisted then
            local currentItem = {
                file = LItem.filename,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToLocal:Close(params)
    self.callback(true, { status = 'success', params = params })
end

function SyncToLocal:HandleCompareList()
    local handling = false

    -- return "skip" if equal
    local onProcessOne = function(timer)
        if self.compareListTotal < self.compareListIndex then
            Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
            KeepworkService:SetCurrentCommitId()

            -- sync finish
            self:SetFinish(true)

            self.callback(false, {
                method = 'UPDATE-PROGRESS-FINISH'
            })
        
            self.compareListIndex = 1

            timer:Change(nil, nil)

            return true
        end
        
        if self.broke then
            self.compareListIndex = 1

            self:SetFinish(true)

            LOG.std('SyncToLocal', 'debug', 'SyncToLocal', L'下载被中断')
            timer:Change(nil, nil)

            return true
        end

        if not handling then
            handling = true

            local currentItem = self.compareList[self.compareListIndex]
            
            local function NextItem()
                self.compareListIndex = self.compareListIndex + 1
                handling = false
            end

            if currentItem.status == UPDATE then
                if(self:UpdateOne(currentItem.file, NextItem) == false) then
                    return "skip"
                end
            elseif currentItem.status == DOWNLOAD then
                self:DownloadOne(currentItem.file, NextItem)
            elseif currentItem.status == DELETE then
                self:DeleteOne(currentItem.file, NextItem)
            end
        end
    end

    local handleTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            -- just in case there are many files, we will batch all skiped files in one tick
            for i = 1, 50 do
                if onProcessOne(timer) ~= "skip" then
					break
				end
            end
        end
    })
    handleTimer:Change(0, 1)
end

function SyncToLocal:SetFinish(value)
    self.finish = value
end

function SyncToLocal:SetBroke(value)
    self.broke = value
end

function SyncToLocal:GetLocalFileByFilename(filename)
    for key, item in ipairs(self.localFiles) do
        if (item.filename == filename) then
            return item
        end
    end
end

function SyncToLocal:GetRemoteFileByPath(path)
    for key, item in ipairs(self.dataSourceFiles) do
        if (item.path == path) then
            return item
        end
    end
end

-- 下载新文件
function SyncToLocal:DownloadOne(file, callback)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s 下载中', currentRemoteItem.path)
    })

    GitService:GetContentWithRaw(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentRemoteItem.path,
        self.currentWorld.lastCommitId,
        function(content, err)
            if content == false then
                self.compareListIndex = 1
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'同步失败，原因： %s 下载失败', currentRemoteItem.path)
                })
                self:SetBroke(true)
                return false
            end

            LocalService:Write(self.currentWorld.worldpath, currentRemoteItem.path, content)

            self.callback(false, {
                method = 'UPDATE-PROGRESS',
                current = self.compareListIndex,
                total = self.compareListTotal,
                msg = format(L'%s （%s） 下载成功', currentRemoteItem.path, Mod.WorldShare.Utils.FormatFileSize(size, 'KB'))
            })

            if type(callback) == 'function' then
                callback()
            end
        end
    )
end

-- 更新本地文件
-- @return false if files are equal
function SyncToLocal:UpdateOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)
    local currentRemoteItem = self:GetRemoteFileByPath(file)

    if currentLocalItem.sha1 == currentRemoteItem.id then
        self.callback(false, {
            method = 'UPDATE-PROGRESS',
            current = self.compareListIndex,
            total = self.compareListTotal,
            msg = format(L'%s 相等跳过', currentRemoteItem.path)
        })

        if callback and type(callback) == 'function' then
            callback()
        end

        return false
    end

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s 更新中', currentRemoteItem.path)
    })

    GitService:GetContentWithRaw(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        currentRemoteItem.path,
        self.currentWorld.lastCommitId,
        function(content, size)
            if content == false then
                self.compareListIndex = 1
                self.callback(false, {
                    method = 'UPDATE-PROGRESS-FAIL',
                    msg = format(L'同步失败，原因： %s 更新失败', currentRemoteItem.path)
                })
                self:SetBroke(true)
                return false
            end

            LocalService:Write(self.currentWorld.worldpath, currentRemoteItem.path, content)

            self.callback(false, {
                method = 'UPDATE-PROGRESS',
                current = self.compareListIndex,
                total = self.compareListTotal,
                msg = format(L'%s （%s） 更新成功', currentRemoteItem.path, Mod.WorldShare.Utils.FormatFileSize(size, 'KB'))
            })
    
            if type(callback) == 'function' then
                callback()
            end
        end
    )
end

-- 删除文件
function SyncToLocal:DeleteOne(file, callback)
    local currentLocalItem = self:GetLocalFileByFilename(file)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s （%s） 删除中', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.size, 'KB'))
    })

    LocalService:Delete(self.currentWorld.worldpath, currentLocalItem.filename)

    self.callback(false, {
        method = 'UPDATE-PROGRESS',
        current = self.compareListIndex,
        total = self.compareListTotal,
        msg = format(L'%s （%s） 删除成功', currentLocalItem.filename, Mod.WorldShare.Utils.FormatFileSize(currentLocalItem.size, 'KB'))
    })

    if callback and type(callback) == 'function' then
        callback()
    end
end

function SyncToLocal:DownloadZIP()
    if not self.currentWorld or
       not self.currentWorld.kpProjectId or
       self.currentWorld.kpProjectId == 0 then
        return
    end

    ParaIO.CreateDirectory(self.currentWorld.worldpath)

    self.localFiles = LocalService:LoadFiles(self.currentWorld.worldpath)

    if #self.localFiles ~= 0 then
        LOG.std(nil, 'warn', 'WorldShare', 'target directory: %s is not empty, we will overwrite files in the folder', Encoding.DefaultToUtf8(self.currentWorld.worldpath))
        GameLogic.RunCommand(format('/menu %s', 'file.worldrevision'))
    end

    LocalServiceWorld:DownLoadZipWorld(
        self.currentWorld.foldername,
        self.currentWorld.user and self.currentWorld.user.username or nil,
        self.currentWorld.lastCommitId,
        self.currentWorld.worldpath,
        function()
            KeepworkService:SetCurrentCommitId()

            -- update worldinfo because world from internet
            local tag = LocalService:GetTag(self.currentWorld.worldpath)

            if tag then
                self.currentWorld.name = tag.name
                Mod.WorldShare.Store:Set('world/currentWorld', self.currentWorld)
            end

            self:SetFinish(true)
            self.callback(false, {
                method = 'UPDATE-PROGRESS-FINISH'
            })
        end,
        self.currentWorld.kpProjectId
    )
end
