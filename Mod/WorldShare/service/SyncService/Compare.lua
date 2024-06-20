--[[
Title: Compare
Author(s): big
CreateDate: 2018.06.20
ModifyDate: 2021.09.10
Desc: 
use the lib:
------------------------------------------------------------
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
------------------------------------------------------------

status meaning:
1:local only
2:network only
3:both
4:local newest
5:network newest

]]

-- lib
local Encoding = commonlib.gettable('commonlib.Encoding')
local WorldRevision = commonlib.gettable('MyCompany.Aries.Creator.Game.WorldRevision')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local DesktopMenu = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.DesktopMenu')
local DesktopMenuPage = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage')

-- service 
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('../LocalService/LocalServiceWorld.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceWorld = NPL.load('../KeepworkService/KeepworkServiceWorld.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')

-- helper
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- UI
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')

local Compare = NPL.export()

local REMOTEBIGGER = 'REMOTEBIGGER'
local JUSTLOCAL = 'JUSTLOCAL'
local JUSTREMOTE = 'JUSTREMOTE'
local LOCALBIGGER = 'LOCALBIGGER'
local EQUAL = 'EQUAL'

Compare.REMOTEBIGGER = REMOTEBIGGER
Compare.JUSTLOCAL = JUSTLOCAL
Compare.JUSTREMOTE = JUSTREMOTE
Compare.LOCALBIGGER = LOCALBIGGER
Compare.EQUAL = EQUAL
Compare.compareFinish = true

function Compare:Init(worldPath, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    self.worldPath = worldPath
    self.callback = callback

    Mod.WorldShare.Store:Set('world/currentRevision', 0)
    Mod.WorldShare.Store:Set('world/remoteRevision', 0)
    Mod.WorldShare.Store:Set('world/remoteRevisionDatetime', 0)
    Mod.WorldShare.Store:Set('world/remoteRevisionUsername', '')

    if not self:IsCompareFinish() then
        return
    end

    self:SetFinish(false)
    self:CompareRevision()
end

function Compare:IsCompareFinish()
    return self.compareFinish == true
end

function Compare:SetFinish(value)
    self.compareFinish = value
end

function Compare:CompareRevision()
    local worldTagPath = self.worldPath .. 'tag.xml'

    if not ParaIO.DoesFileExist(worldTagPath) then
        self:SetFinish(true)
        self.callback(self.JUSTREMOTE, 2)
        return
    end

    local worldTag = LocalService:GetTag(self.worldPath)

    -- Entered world project Id may be changed
    if Mod.WorldShare.Store:Get('world/isEnterWorld') then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
        if currentEnterWorld and currentEnterWorld.worldpath == self.worldPath then
            worldTag.kpProjectId = currentEnterWorld.kpProjectId
        end
    end

    local localRevision = WorldRevision:new():init(self.worldPath):Checkout()

    if worldTag and tonumber(worldTag.kpProjectId) == 0 then
        Mod.WorldShare.Store:Set('world/currentRevision', localRevision)
        self:SetFinish(true)
        self.callback(self.JUSTLOCAL, 1)
        return
    end

    local function HandleRevision(data, err, commitInfo)
        if err == 0 or err == 502 then
            self:SetFinish(true)
            self.callback()
            return
        end

        local remoteRevision = tonumber(data) or 0

        Mod.WorldShare.Store:Set('world/currentRevision', localRevision)
        Mod.WorldShare.Store:Set('world/remoteRevision', remoteRevision)

        if commitInfo and commitInfo.datetime and commitInfo.username then
            -- set commit datetime and username
            Mod.WorldShare.Store:Set('world/remoteRevisionDatetime', commitInfo.datetime)
            Mod.WorldShare.Store:Set('world/remoteRevisionUsername', commitInfo.username)
        end

        self:SetFinish(true)

        if localRevision < remoteRevision then
            self.callback(self.REMOTEBIGGER, 5)
            return
        end

        if localRevision > remoteRevision then
            self.callback(self.LOCALBIGGER, 4)
            return
        end

        if localRevision == remoteRevision then
            self.callback(self.EQUAL, 3)
            return
        end
    end

    GitService:GetWorldRevision(worldTag.kpProjectId, true, HandleRevision)
end

function Compare:GetCurrentWorldInfo(callback)
    local currentWorld

    Mod.WorldShare.MsgBox:Show(L'正在准备数据，请稍候...')

    local function afterGetInstance(worldData)
        Mod.WorldShare.MsgBox:Close()
    
        -- lock share world
        if KeepworkService:IsSignedIn() and
           not GameLogic.IsReadOnly() and
           Mod.WorldShare.Utils:IsSharedWorld(currentWorld) and
           currentWorld.kpProjectId and
           currentWorld.kpProjectId ~= 0 and
           currentWorld.status ~= 1 then
            if not Mod.WorldShare.Store:Get('world/forceOpenMultiPlayerWorld') then
                KeepworkServiceWorld:UpdateLockHeartbeatStart(
                    currentWorld.kpProjectId,
                    'exclusive',
                    currentWorld.revision,
                    nil,
                    nil
                )
            end

            Mod.WorldShare.Store:Remove('world/forceOpenMultiPlayerWorld')
        end

        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
        Mod.WorldShare.Store:Set('world/currentEnterWorld', currentWorld)

        KeepworkServiceWorld:RefreshAnonymousWorld(worldData)

        -- update world tag
        if currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
            WorldCommon.SetWorldTag('kpProjectId', currentWorld.kpProjectId)
        else
            WorldCommon.SetWorldTag('kpProjectId', nil)
        end

        DesktopMenu.LoadMenuItems(true)
        DesktopMenuPage.OnWorldLoaded()
        DesktopMenuPage.Refresh()

        GameLogic.options:ResetWindowTitle() -- update newset worldinfo

        if callback and type(callback) == 'function' then
            callback()
        end
    end

    if Mod.WorldShare.Store:Get('world/readonly') then
        System.World.readonly = true
        GameLogic.options:ResetWindowTitle()
        Mod.WorldShare.Store:Remove('world/readonly')
    end

    if GameLogic.IsReadOnly() then
        local originWorldPath = ParaWorld.GetWorldDirectory()
        local worldTag = WorldCommon.GetWorldInfo() or {}
        local currentRevision = WorldRevision:new():init(originWorldPath):Checkout()
        local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false

        if not worldTag.kpProjectId or worldTag.kpProjectId == 0 then
            worldTag.kpProjectId = string.match(Game.loadworld_params.worldpath, '/(%d+)_')
        end

        if KeepworkServiceSession:IsSignedIn() and
           worldTag.kpProjectId and
           tonumber(worldTag.kpProjectId) ~= 0 then
            KeepworkServiceProject:GetProject(worldTag.kpProjectId, function(data, err)
                if err == 0 then
                    Mod.WorldShare.MsgBox:Close()
                    return
                end

                local shared = false
                if data and data.memberCount and data.memberCount > 1 then
                    shared = true
                end
                
                KeepworkServiceProject:GetMembers(worldTag.kpProjectId, function(membersData, err)
                    membersData = membersData or {}
                    local members = {}

                    for key, item in ipairs(membersData) do
                        members[#members + 1] = item.username
                    end

                    if data and data.project then
                        if data.project.visibility == 0 then
                            data.project.visibility = 0
                        else
                            data.project.visibility = 1
                        end
                    end

                    if worldTag.fromProjects then
                        local fromProjectsTable = {}

                        for item in string.gmatch(worldTag.fromProjects, '[^,]+') do
                            fromProjectsTable[#fromProjectsTable + 1] = item  
                        end
                    end

                    local fromProjectId = 0

                    if fromProjectsTable and #fromProjectsTable > 0 then
                        fromProjectsTable = fromProjectsTable[#fromProjectsTable]
                    end

                    currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
                        text = worldTag.name,
                        foldername = Mod.WorldShare.Utils.GetFolderName(),
                        name = worldTag.name or '',
                        revision = data.revision,
                        size = 0,
                        modifyTime = '',
                        lastCommitId = data.commitId, 
                        worldpath = originWorldPath,
                        status = 3, -- status should be equal
                        project = data.project,
                        user = {
                            id = data.userId,
                            username = data.username,
                        }, -- { id = xxxx, username = xxxx }
                        kpProjectId = worldTag.kpProjectId,
                        fromProjectId = fromProjectId,
                        parentProjectId = data.parentId,
                        IsFolder = false,
                        is_zip = true,
                        shared = shared,
                        communityWorld = worldTag.communityWorld,
                        isVipWorld = worldTag.isVipWorld,
                        instituteVipEnabled = worldTag.instituteVipEnabled,
                        memberCount = data.memberCount,
                        members = members,
                        remotefile = data.world and data.world.archiveUrl,
                        level = data.level,
                        platform = data.platform,
                        channel = data.channel,
                    })

                    Mod.WorldShare.Store:Set('world/currentRevision', GameLogic.options:GetRevision())
                    afterGetInstance(data)
                end)
            end)
        else
            local currentRemoteFile = Mod.WorldShare.Store:Get('world/currentRemoteFile')

            currentWorld = LocalServiceWorld:GenerateWorldInstance({
                IsFolder = false,
                is_zip = true,
                kpProjectId = worldTag.kpProjectId,
                fromProjectId = worldTag.fromProjectId,
                parentProjectId = worldTag.parentProjectId,
                text = worldTag.name,
                size = 0,
                foldername = Mod.WorldShare.Utils.GetFolderName(),
                modifyTime = '',
                worldpath = originWorldPath,
                revision = currentRevision,
                isVipWorld = worldTag.isVipWorld,
                communityWorld = worldTag.communityWorld,
                instituteVipEnabled = worldTag.instituteVipEnabled,
                shared = localShared,
                name = worldTag.name,
                remotefile = currentRemoteFile,
                platform = worldTag.platform,
            })

            Mod.WorldShare.Store:Set('world/currentRevision', GameLogic.options:GetRevision())
            afterGetInstance()
        end
    else
        local worldpath = ParaWorld.GetWorldDirectory()

        WorldCommon.LoadWorldTag(worldpath)
        local worldTag = WorldCommon.GetWorldInfo() or {}

        if KeepworkServiceSession:IsSignedIn() and
           worldTag.kpProjectId and
           tonumber(worldTag.kpProjectId) ~= 0 then
            local kpProjectId = tonumber(worldTag.kpProjectId)
            local fromProjectId = worldTag.fromProjectId
            local parentProjectId = worldTag.parentProjectId

            KeepworkServiceProject:GetProject(kpProjectId, function(data, err)
                data = data or {}
                local userId = Mod.WorldShare.Store:Get('user/userId')
                local shared = false

                if data.managed == 1 then
                    shared = true
                else
                    if data and data.memberCount and data.memberCount > 1 then
                        shared = true
                    end
                end

                if userId ~= data.userId then
                    local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false
    
                    if not shared or not localShared then
                        -- covert to new world when different user world
                        currentWorld = LocalServiceWorld:GenerateWorldInstance({
                            IsFolder = true,
                            is_zip = false,
                            text = worldTag.name,
                            foldername = Mod.WorldShare.Utils.GetFolderName(),
                            worldpath = worldpath,
                            kpProjectId = 0,
                            fromProjectId = fromProjectId,
                            parentProjectId = parentProjectId,
                            name = worldTag.name,
                            revision = WorldRevision:new():init(worldpath):GetDiskRevision(),
                            communityWorld = worldTag.communityWorld,
                            isVipWorld = worldTag.isVipWorld,
                            instituteVipEnabled = worldTag.instituteVipEnabled,
                            shared = false,
                            size = LocalService:GetWorldSize(worldpath),
                            platform = worldTag.platform,
                        })
                        afterGetInstance()
                        return
                    end
                end

                self:Init(worldpath, function(result)
                    local status

                    if result == self.JUSTLOCAL then
                        status = 1
                    elseif result == self.JUSTREMOTE then
                        status = 2
                    elseif result == self.REMOTEBIGGER then
                        status = 5
                    elseif result == self.LOCALBIGGER then
                        status = 4
                    elseif result == self.EQUAL then
                        status = 3
                    end

                    KeepworkServiceProject:GetMembers(kpProjectId, function(membersData, err)
                        local members = {}

                        if not membersData then
                            membersData = {}
                        end
    
                        for key, item in ipairs(membersData) do
                            members[#members + 1] = item.username
                        end

                        if data and data.project then
                            if data.project.visibility == 0 then
                                data.project.visibility = 0
                            else
                                data.project.visibility = 1
                            end
                        end

                        currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
                            IsFolder = true,
                            is_zip = false,
                            text = worldTag.name,
                            foldername = Mod.WorldShare.Utils.GetFolderName(),
                            worldpath = worldpath,
                            kpProjectId = kpProjectId,
                            fromProjectId = fromProjectId,
                            parentProjectId = data.parentId,
                            name = worldTag.name,
                            status = status,
                            revision = data.revision,
                            lastCommitId = data.commitId, 
                            project = data.project,
                            user = {
                                id = data.userId,
                                username = data.username,
                            },
                            shared = shared,
                            communityWorld = worldTag.communityWorld,
                            isVipWorld = worldTag.isVipWorld,
                            instituteVipEnabled = worldTag.instituteVipEnabled,
                            memberCount = data.memberCount,
                            members = members,
                            size = LocalService:GetWorldSize(worldpath),
                            level = data.level,
                            platform = data.platform,
                            channel = data.channel,
                        })
                        currentWorld.visibility = data.visibility or 0
                        local username = Mod.WorldShare.Store:Get('user/username')
                        local bIsExisted = false

                        for key, item in ipairs(members) do
                            if item == username then
                                bIsExisted = true
                            end
                        end

                        if bIsExisted then
                            System.World.readonly = false
                            GameLogic.options:ResetWindowTitle()
                        else
                            System.World.readonly = true
                            GameLogic.options:ResetWindowTitle()
                        end

                        afterGetInstance(data)
                    end)
                end)
            end)

            return
        else
            local localShared = string.match(worldpath or '', 'shared') == 'shared' and true or false

            currentWorld = LocalServiceWorld:GenerateWorldInstance({
                IsFolder = true,
                is_zip = false,
                text = worldTag.name,
                foldername = Mod.WorldShare.Utils.GetFolderName(),
                worldpath = worldpath,
                kpProjectId = worldTag.kpProjectId,
                fromProjectId = worldTag.fromProjectId,
                parentProjectId = worldTag.parentProjectId,
                name = worldTag.name,
                revision = WorldRevision:new():init(worldpath):GetDiskRevision(),
                communityWorld = worldTag.communityWorld,
                isVipWorld = worldTag.isVipWorld,
                instituteVipEnabled = worldTag.instituteVipEnabled,
                shared = localShared,
                platform = worldTag.platform,
            })

            if Mod.WorldShare.Utils:IsSharedWorld(currentWorld) then
                System.World.readonly = true
                GameLogic.options:ResetWindowTitle()
            end

            local username = Mod.WorldShare.Store:Get('user/username')

            afterGetInstance({ username =  username })
        end
    end
end

function Compare:CheckWorldExist(worldName,callback)
    local localWorlds = LocalServiceWorld:GetWorldList()
    if not KeepworkService:IsSignedIn() or System.options.isOffline then
        local currentWorldList = localWorlds
        local isMatch = false
        for key, item in ipairs(currentWorldList) do
            if item and worldName and item.foldername and string.lower(item.foldername) == string.lower(worldName) then
                isMatch = true
                break
            end
            if item and worldName and item.name and string.lower(item.name) == string.lower(worldName) then
                isMatch = true
                break
            end
        end
        Mod.WorldShare.Store:Set('world/compareFullWorldList', currentWorldList)
        if type(callback) == 'function' then
            callback(isMatch,currentWorldList)
        end
        return 
    end
    KeepworkServiceWorld:MergeRemoteWorldList(
        localWorlds,
        function(currentWorldList) 
            if not currentWorldList then
                if type(callback) == 'function' then
                    callback(false)
                end
                return
            end          
            local isMatch = false
            for key, item in ipairs(currentWorldList) do
                if item and worldName and item.foldername and string.lower(item.foldername) == string.lower(worldName) then
                    isMatch = true
                    break
                end
                if item and worldName and item.name and string.lower(item.name) == string.lower(worldName) then
                    isMatch = true
                    break
                end
            end
            Mod.WorldShare.Store:Set('world/compareFullWorldList', currentWorldList)
            if type(callback) == 'function' then
                callback(isMatch,currentWorldList)
            end
        end,
        true
    )
end

--获取所有的世界列表
function Compare:GetFullWorldList(callback)
    local fullWorldList = {}
    if not KeepworkService:IsSignedIn() or System.options.isOffline then
        local localWorlds = LocalServiceWorld:GetWorldList() or {}
        for key,item in pairs(localWorlds) do
            if item and not item.shared and not item.is_zip then
                local temp = {}
                temp.id = item.kpProjectId
                temp.name = item.foldername
                temp.worldTagName = item.name
                fullWorldList[#fullWorldList + 1] = temp
            end
        end
        Mod.WorldShare.Store:Set('world/fullWorldList', fullWorldList)
        if callback and type(callback) == 'function' then
            callback(fullWorldList)
        end
        return
    end
    self:CheckWorldExist(nil,function(isMatch,worldList)
        local localWorlds = worldList or {}
        for key,item in pairs(localWorlds) do
            if item and not item.shared and not item.is_zip then
                local temp = {}
                temp.id = item.kpProjectId
                temp.name = item.foldername
                temp.worldTagName = item.name
                fullWorldList[#fullWorldList + 1] = temp
            end
        end
        KeepworkServiceProject:GetFullWorldList(function(data,err)
            if err == 200 then
                if System.options.isDevMode then
                    echo(data,true)
                    print("fullWorldList===========",err)
                end
                local remoteData = (data and data.projects) and data.projects or {}
                for rKey,rItem in pairs(remoteData) do
                    local isExist = false
                    for key,item in pairs(localWorlds) do
                        if item.kpProjectId ~= 0 and rItem.id == item.kpProjectId and rItem.isDeleted == 0 then
                            isExist = true
                            break
                        end
                    end
                    if not isExist then
                        fullWorldList[#fullWorldList + 1] = rItem
                    end
                end
                Mod.WorldShare.Store:Set('world/fullWorldList', fullWorldList)
                if callback and type(callback) == 'function' then
                    callback(fullWorldList)
                end
            else
                Mod.WorldShare.Store:Set('world/fullWorldList', fullWorldList)
                if callback and type(callback) == 'function' then
                    callback(fullWorldList)
                end
                LOG.std(nil,"info","Compare","get full world list error code is %d",err)
            end
        end)    
    end)
    
end

function Compare:MoveOlderWorldToNewFolder()
    local folderList = {}

    local files = commonlib.Files.Find({}, "worlds/DesignHouse", 0, 500, "*")
    for _, file in ipairs(files) do
        if file and file.fileattr == 16 then
            if file.filename ~= '_shared' and
               file.filename ~= '_user' and
               file.filename ~= 'backups' and
               file.filename ~= 'blocktemplates' and
               file.filename ~= 'userworlds' then
                folderList[#folderList + 1] = file.filename
            end
        end
    end

    for key, item in ipairs(folderList) do
        local worldpath = 'worlds/DesignHouse/' .. item

        local curWorldUsername = Mod.WorldShare:GetWorldData('username', worldpath)
        local backUpWorldPath
        
        if curWorldUsername then
            backUpWorldPath =
                'worlds/DesignHouse/_user/' ..
                curWorldUsername ..
                '/' ..
                commonlib.Encoding.Utf8ToDefault(item)

            commonlib.Files.MoveFolder(worldpath, backUpWorldPath)
            ParaIO.DeleteFile(worldpath)
        end
    end
end

function Compare:GetNewWorldName(oldName, callback)
    if not oldName or oldName == "" then
        return oldName
    end
    local pattern =  "[%[#&*%-%+%.%(%)%$%'%,%]]"
    self:GetFullWorldList(function()
        local old_world_name =   string.gsub(oldName, pattern, "")
        local currentWorldList = Mod.WorldShare.Store:Get('world/fullWorldList') or {}
        local mapNames = {}
        local mapTagNames = {}
        local mapDeleted = {}
        local maxIndex = 0
        local worldName = oldName
        local regexStr = "^"..old_world_name.."_(%d+)$"
        for _, world in ipairs(currentWorldList) do
            
            local world_name = string.gsub(world.name, pattern, "")
            local worldTagName = string.gsub(world.worldTagName, pattern, "")
            local match1 = string.match(world_name,regexStr)
            local match2 = string.match(worldTagName,regexStr)
            if match1 and tonumber(match1) > maxIndex and tonumber(match1) < 1000 then
                maxIndex = tonumber(match1)
            end

            if match2 and tonumber(match2) > maxIndex and tonumber(match2) < 1000 then
                maxIndex = tonumber(match2)
            end
            mapNames[world.name] = true
            mapTagNames[world.worldTagName] = true
            mapDeleted[world.name] = world.isDeleted == 1
        end
        
        for i = 0, maxIndex + 1 do
            local world_name = oldName.."_"..tostring(i)
            if i == 0 then
                world_name = oldName
            end
            if not mapNames[world_name] and not mapTagNames[world_name] then
                worldName = world_name
                break
            end
        end
        local last_world_name = worldName
        for i = 0 ,maxIndex do
            local world_name = oldName.."_"..tostring(i)
            if i == 0 then
                world_name = oldName
            end
            if not mapDeleted[world_name] then
                last_world_name = world_name
                break
            end
        end
        if System.options.isDevMode then
            print("GetNewWorldName===========",old_world_name,maxIndex,worldName,mapNames[worldName] , mapTagNames[worldName])
            echo(currentWorldList,true)
            echo(mapNames,true)
            echo(mapTagNames,true)
            echo(mapDeleted,true)
        end
        local username = Mod.WorldShare.Store:Get("user/username");
        local worldPath = "worlds/DesignHouse/".. worldName
        local last_world_path = "worlds/DesignHouse/".. last_world_name
        if username and username ~= "" then
            worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. worldName
            last_world_path = "worlds/DesignHouse/_user/" .. username .. "/" .. last_world_name
        end
        if callback and type(callback) == "function" then
            callback(worldName,worldPath,last_world_name,last_world_path)
        end
    end)
end

function Compare:RefreshDeletedWorldList(callback)
    if not KeepworkService:IsSignedIn() or System.options.isOffline then
        if callback and type(callback) == 'function' then
            callback(false)
        end
        return
    end
    KeepworkServiceWorld:MergeRemoteDeletedWorldList(nil,function(result)
        if not result or type(result) ~= 'table' then
            return
        end
        local currentWorldList = result
        local searchText = Mod.WorldShare.Store:Get('world/searchText')

        if type(searchText) == 'string' and searchText ~= '' then
            local searchWorldList = {}

            for key, item in ipairs(currentWorldList) do
                if item and item.text and string.match(string.lower(item.text), string.lower(searchText))then
                    searchWorldList[#searchWorldList + 1] = item
                elseif item and item.kpProjectId and string.match(string.lower(item.kpProjectId), string.lower(searchText)) then
                    searchWorldList[#searchWorldList + 1] = item
                end
            end

            currentWorldList = searchWorldList
        end

        if not System.options.isInternal then
            if System.options.isEducatePlatform then
                currentWorldList = commonlib.filter(currentWorldList, function (item)
                    local foldername = item.foldername or ""
                    local isExamWorld =  foldername:match("^exam_world%d+_%d+_%d+_%d+") 
                    return (item.channel and item.channel ~= 2) and not isExamWorld
                end)
            else
                currentWorldList = commonlib.filter(currentWorldList, function (item)
                    return (item.channel and item.channel == 0)
                end)
            end

        end
        Mod.WorldShare.Store:Set('world/compareWorldList', currentWorldList)
        if callback and type(callback) == 'function' then
            callback(currentWorldList)
        end
    end)
end

function Compare:RefreshWorldList(callback, statusFilter,worldTypeFilter)
    if worldTypeFilter and worldTypeFilter == 'DELETED' then
        self:RefreshDeletedWorldList(callback)
        return
    end

    self:GetFullWorldList()
    
    if not KeepworkService:IsSignedIn() or System.options.isOffline then
        local currentWorldList = LocalServiceWorld:GetWorldList(true)

        local searchText = Mod.WorldShare.Store:Get('world/searchText')

        if type(searchText) == 'string' and searchText ~= '' then
            local searchWorldList = {}

            for key, item in ipairs(currentWorldList) do
                if item and item.text and string.match(string.lower(item.text), string.lower(searchText))then
                    searchWorldList[#searchWorldList + 1] = item
                elseif item and item.kpProjectId and string.match(string.lower(item.kpProjectId), string.lower(searchText)) then
                    searchWorldList[#searchWorldList + 1] = item
                end
            end

            currentWorldList = searchWorldList
        end

        local searchFolderName = Mod.WorldShare.Store:Get('world/searchFolderName')

        if type(searchFolderName) == 'string' and searchFolderName ~= '' then
            local searchWorldList = {}

            for key, item in ipairs(currentWorldList) do
                if item and item.foldername and item.foldername == searchFolderName then
                    searchWorldList[#searchWorldList + 1] = item
                end
            end

            currentWorldList = searchWorldList
        end
        if not System.options.isInternal then --System.options.isEducatePlatform and 
            if System.options.isEducatePlatform then
                currentWorldList = commonlib.filter(currentWorldList, function (item)
                    local foldername = item.foldername or ""
                    local isExamWorld =  foldername:match("^exam_world%d+_%d+_%d+_%d+") 
                    return (item.channel and item.channel ~= 2) and not isExamWorld
                end)
            else
                currentWorldList = commonlib.filter(currentWorldList, function (item)
                    return (item.channel and item.channel == 0)
                end)
            end
        end
        self.SortWorldList(currentWorldList)
        Mod.WorldShare.Store:Set('world/compareWorldList', currentWorldList)

        if callback and type(callback) == 'function' then
            callback(currentWorldList)
        end
    else
        local localWorlds = LocalServiceWorld:GetWorldList()
        KeepworkServiceWorld:MergeRemoteWorldList(
            localWorlds,
            function(currentWorldList)
                if statusFilter and statusFilter == 'LOCAL' then
                    local filterCurrentWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and
                           type(item) == 'table' and
                           (not item.status or tonumber(item.status) ~= 2) then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                end

                if statusFilter and statusFilter == 'ONLINE' then
                    local filterCurrentWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and
                           type(item) == 'table' and
                           item.status and
                           tonumber(item.status) ~= 1
                            then
                            filterCurrentWorldList[#filterCurrentWorldList + 1] = item
                        end
                    end

                    currentWorldList = filterCurrentWorldList
                end

                local searchText = Mod.WorldShare.Store:Get('world/searchText')

                if type(searchText) == 'string' and searchText ~= '' then
                    local searchWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and item.text and string.match(string.lower(item.text), string.lower(searchText))then
                            searchWorldList[#searchWorldList + 1] = item
                        elseif item and item.kpProjectId and string.match(string.lower(item.kpProjectId), string.lower(searchText)) then
                            searchWorldList[#searchWorldList + 1] = item
                        end
                    end

                    currentWorldList = searchWorldList
                end

                local searchFolderName = Mod.WorldShare.Store:Get('world/searchFolderName')

                if type(searchFolderName) == 'string' and searchFolderName ~= '' then
                    local searchWorldList = {}

                    for key, item in ipairs(currentWorldList) do
                        if item and item.foldername and item.foldername == searchFolderName then
                            searchWorldList[#searchWorldList + 1] = item
                        end
                    end

                    currentWorldList = searchWorldList
                end
                for key, item in ipairs(currentWorldList) do
                    if item and item.project and item.project.channel then
                        item.channel = item.project.channel
                    end
                end
                if System.options.isDevMode then
                    print("currentWorldList=============")
                    -- echo(currentWorldList,true)
                end
                if not System.options.isInternal then --System.options.isEducatePlatform and 
                    if System.options.isEducatePlatform then
                        currentWorldList = commonlib.filter(currentWorldList, function (item)
                            local foldername = item.foldername or ""
                            local isExamWorld =  foldername:match("^exam_world%d+_%d+_%d+_%d+") 
                            return (item.channel and item.channel ~= 2) and not isExamWorld
                        end)
                    else
                        currentWorldList = commonlib.filter(currentWorldList, function (item)
                            return (item.channel and item.channel == 0)
                        end)
                    end

                end

               
                

                if worldTypeFilter and worldTypeFilter == 'SHARED' then
                    currentWorldList = commonlib.filter(currentWorldList, function (item)
                        return item.shared == true and not self:IsMineWorld(item)
                    end)
                elseif worldTypeFilter and worldTypeFilter == 'MINE' then
                    currentWorldList = commonlib.filter(currentWorldList, function (item)
                        return self:IsMineWorld(item)
                    end)
                end
                self.SortWorldList(currentWorldList)
                Mod.WorldShare.Store:Set('world/compareWorldList', currentWorldList)
                if type(callback) == 'function' then
                    callback(currentWorldList)
                end
            end
        )
    end
end

function Compare:IsMineWorld(world)
    if not world or type(world) ~= 'table' then
        return false
    end
    if world.is_zip == true then
        return false
    end
    local is_shared = world.shared
    if is_shared then
        local user = world.user
        if not user or type(user) ~= 'table' or not user.username then
            return false
        end
        
        local username = Mod.WorldShare.Store:Get("user/username");
        if username == user.username then
            return true
        else
            return false
        end
    else
        return true
    end
end

function Compare.SortWorldList(currentWorldList)
    if type(currentWorldList) == 'table' and #currentWorldList > 0 then
        table.sort(currentWorldList, function(a, b)
            if not a or
               not a.modifyTime or
               not b or
               not b.modifyTime then
                return false
            end

            return a.modifyTime > b.modifyTime
        end)
    end
end

function Compare:GetSelectedWorld(index)
    local compareWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    if compareWorldList then
        return compareWorldList[index]
    else
        return nil
    end
end

function Compare:GetWorldIndexByFoldername(foldername, share, iszip)
    local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')

    if not currentWorldList or type(currentWorldList) ~= 'table' then
        return false
    end

    for index, item in ipairs(currentWorldList) do
        if foldername == item.foldername and
           share == item.shared and
           iszip == item.is_zip then
            return index
        end
    end
end

function Compare:CheckRevision(worldPath, callback)
    local revisionPath = worldPath .. 'revision.xml'

    if ParaIO.DoesFileExist(revisionPath) then
       return
    end

    local file = ParaIO.open(revisionPath, 'w');
    file:WriteString('1')
    file:close();
end

function Compare:IgnoreFiles(worldPath, localFiles)
    local filePath = format('%s/.paraignore', worldPath)
    local file = ParaIO.open(filePath, 'r')
    local content = file:GetText(0, -1)
    file:close()

    local ignoreFiles = {
        '.git/',
        '.codeblock/',
        '.vscode/',
    }

    if #content > 0 then
        for item in string.gmatch(content, '[^\r\n]+') do
            ignoreFiles[#ignoreFiles + 1] = item
        end
    end

    local i = 1
    while i <= #localFiles do
        local isIgnore = false
        
        for FKey, FItem in ipairs(ignoreFiles) do
            -- use plain text find instead of using regular expression
            if string.find(localFiles[i].filename, FItem, 1, true) then
                isIgnore = true
                break
            end
        end

        if isIgnore then
            localFiles[i] = localFiles[#localFiles]
            localFiles[#localFiles] = nil;
        else
            i = i + 1
        end
    end

    return localFiles
end
