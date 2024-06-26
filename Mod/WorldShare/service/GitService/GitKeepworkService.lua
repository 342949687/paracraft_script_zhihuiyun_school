--[[
Title: GitlabService
Author(s):  big
CreateDate: 2019.12.10
UpdateDate: 2022.7.11
Desc: 
use the lib:
------------------------------------------------------------
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
------------------------------------------------------------
]]

-- api
local KeepworkReposApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkReposApi.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')

-- service
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')

-- config
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')

local GitKeepworkService = NPL.export()

function GitKeepworkService:GetQiNiuArchiveUrl(foldername, username, commitId)
    if System.os.IsWindowsXP() then
        return self:GetCdnArchiveUrl(foldername, username, commitId)
    else
        return format(
                    '%s/%s-%s.zip',
                    Config:GetValue('qiniuGitZip'),
                    GitService:GetRepoPath(foldername, username),
                    commitId
                )
    end
end

function GitKeepworkService:GetCdnArchiveUrl(foldername, username, commitId,kpProjectId)
    local baseUrl = ''

    if System.os.IsWindowsXP() then
        baseUrl = Config:GetValue('xpGitZip')
    else
        baseUrl = Config:GetValue('keepworkApiCdnList')
    end
    local repopath_decode = GitService:GetRepoPathUnEncode(foldername, username)
    local repopath = GitService:GetRepoPath(foldername, username)
    local url = '%s/repos/%s/download?ref=%s'
    if kpProjectId and tonumber(kpProjectId) > 0 then
        local signStr = repopath_decode..":"..kpProjectId
        local signature = ParaMisc.md5(signStr or "")
        url = url.."&signature="..signature
    end
    local reUrl = format(url,baseUrl,repopath,commitId)
    return reUrl
end

function GitKeepworkService:GetContentWithRaw(foldername, username, path, commitId, callback, cdnState)
    KeepworkReposApi:Raw(
        foldername,
        username,
        path,
        commitId,
        function(data, err)
            if type(callback) == 'function' then
                callback(data, err)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end,
        cdnState
    )
end

function GitKeepworkService:Upload(foldername, username, path, content, callback)
    KeepworkReposApi:CreateFile(
        foldername,
        username,
        path,
        content,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:Update(foldername, username, path, content, callback)
    KeepworkReposApi:UpdateFile(
        foldername,
        username,
        path,
        content,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:DeleteFile(foldername, username, path, callback)
    KeepworkReposApi:RemoveFile(
        foldername,
        username,
        path,
        function()
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function GitKeepworkService:DownloadZIP(foldername, username, commitId, callback)
    KeepworkReposApi:Download(foldername, username, commitId, callback, callback)
end

local recursiveData = {}
function GitKeepworkService:GetTree(foldername, username, commitId, callback)
    KeepworkReposApi:Tree(foldername, username, commitId, function(data, err)
        if not data or type(data) ~= 'table' then
            return
        end

        local _data = {}

        for key, item in ipairs(data) do
            if item.isBlob then
                _data[#_data + 1] = item
            end

            if item.isTree and item.children then
                recursiveData = {}
                self:GetRecursive(item.children)

                for RKey, RItem in ipairs(recursiveData) do
                    if RItem.isBlob then
                        _data[#_data + 1] = RItem
                    end
                end

                recursiveData = {}
            end
        end

        if callback and type(callback) == 'function' then
            callback(_data, err)
        end
    end, callback)
end

function GitKeepworkService:GetRecursive(children)
    if type(children) ~= 'table' then
        return false
    end

    for key, item in ipairs(children) do
        if item.isBlob then
            recursiveData[#recursiveData + 1] = item
        end

        if item.isTree and item.children then
            self:GetRecursive(item.children)
        end
    end
end

function GitKeepworkService:GetCommits(foldername, username, callback)
    KeepworkReposApi:CommitInfo(foldername, username, callback)
end

function GitKeepworkService:GetWorldRevision(kpProjectId, isGetMine, callback)
    KeepworkProjectsApi:GetProject(
        kpProjectId,
        function(data, err)
            if isGetMine then
                if data and
                   type(data) ~= 'table' or
                   not data.id or
                   tonumber(data.id) ~= tonumber(kpProjectId) then
                    if type(callback) == 'function' then
                        callback(0,0)
                    end

                    return
                end
            end

            if data and
               type(data) ~= 'table' or
               not data.username or
               not data.name or
               not data.world then
                if type(callback) == 'function' then
                    callback(0,0)
                end
                return
            end

            local revision = 0
            local commitInfo = {}

            if data.world and
               data.world.extra and
               data.world.extra.commitIds and
               #data.world.extra.commitIds > 0 then
                commitInfo = data.world.extra.commitIds[#data.world.extra.commitIds]

                if commitInfo and commitInfo.revision then
                    revision = tonumber(commitInfo.revision)
                end
            end

            if callback and type(callback) == 'function' then
                callback(revision, err, commitInfo)
            end

            -- local folderName = data.name
            -- --家园的处理
            -- if data.name ~= data.world.worldName then
            --     folderName = data.world.worldName
            -- end
            -- KeepworkReposApi:Raw(
            --     folderName,
            --     data.username,
            --     'revision.xml',
            --     data.world.commitId,
            --     function(data, err)
            --         if callback and type(callback) == 'function' then
            --             callback(tonumber(data) or 0, err)
            --         end
            --     end,
            --     function()
            --         if callback and type(callback) == 'function' then
            --             callback(0, err)
            --         end
            --     end,
            --     nil,
            --     {0, 403}
            -- )
        end,
        function(_, err)
            callback(0, err)
        end
    )
end


