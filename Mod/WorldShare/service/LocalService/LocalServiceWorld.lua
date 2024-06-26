--[[
Title: LocalService World
Author(s):  big
CreateDate: 2020.2.12
ModifyDate: 2022.6.28
Place: Foshan
use the lib:
------------------------------------------------------------
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
------------------------------------------------------------
]]

-- service
local LocalService = NPL.load('../LocalService.lua')
local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkServiceSession = NPL.load('../KeepworkService/KeepworkServiceSession.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')

-- libs
NPL.load('(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua")

local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local FileDownloader = commonlib.gettable('Mod.WorldShare.service.FileDownloader.FileDownloader')
local LocalLoadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.LocalLoadWorld')
local WorldRevision = commonlib.gettable('MyCompany.Aries.Creator.Game.WorldRevision')
local SaveWorldHandler = commonlib.gettable('MyCompany.Aries.Game.SaveWorldHandler')
local RemoteServerList = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteServerList')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local ParaWorldLoginAdapter = commonlib.gettable('MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter')

-- parse
local MdParser = NPL.load('(gl)Mod/WorldShare/parser/MdParser.lua')

local LocalServiceWorld = NPL.export()

function LocalServiceWorld:GetDefaultSaveWorldPath()
    return 'worlds/DesignHouse'
end

function LocalServiceWorld:GetUserFolderPath()
    local username = self:GetLocalUsername()
    local folderPath = self:GetDefaultSaveWorldPath()
    if username then
        local curUserFolderPath = folderPath .. '/_user/' .. username

        if not ParaIO.DoesFileExist(curUserFolderPath .. '/', false) then
            ParaIO.CreateDirectory(curUserFolderPath .. '/')
        end

        return curUserFolderPath
    end
    return folderPath
end

function LocalServiceWorld:GetLocalUsername()
	local username = Mod.WorldShare.Store:Get('user/username') or System.User.username
	return username;
end

function LocalServiceWorld:BuildLocalWorldList()
	-- get all contents in folder. 
    -- clear ds
    self.dsWorlds = {}
    self.SelectedWorld_Index = nil

    local folderPath = self:GetDefaultSaveWorldPath() -- design house folder
    local username = self:GetLocalUsername()
    local curUserFolderPath = self:GetUserFolderPath()
    local myHomeWorldName

    if username then
        myHomeWorldName = username .. '_main'

        -- move old home world to new world folder.
        if ParaIO.DoesFileExist(folderPath .. '/' .. myHomeWorldName .. '/tag.xml', false) then
            commonlib.Files.MoveFolder(
                folderPath .. '/' .. myHomeWorldName .. '/',
                curUserFolderPath .. '/' .. myHomeWorldName
            )
        end

        -- create home world if not exist
        if not ParaIO.DoesFileExist(curUserFolderPath .. '/' .. myHomeWorldName .. '/tag.xml', false) then
            self:CreateHomeWorld(myHomeWorldName)
        end
    end

    local function Handle(path)
        local output = self:SearchFiles(nil, path, LocalLoadWorld.MaxItemPerFolder)
        if output and #output > 0 then
            for _, item in ipairs(output) do
                local bLoadedWorld
                local xmlRoot = ParaXML.LuaXML_ParseFile(path .. "/" .. item.filename .. '/tag.xml')
    
                if xmlRoot then
                    for node in commonlib.XPath.eachNode(xmlRoot, '/pe:mcml/pe:world') do
                        if node.attr then
                            local display_name = node.attr.name or item.filename
                            local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
    
                            if filenameUTF8 ~= node.attr.name then
                                -- show dir name if differs from world name
                                display_name = format("%s(%s)", node.attr.name or '', filenameUTF8)
                            end
    
                            if myHomeWorldName and item.filename == myHomeWorldName then
                                -- use a different display format
                                display_name = node.attr.name or filenameUTF8
                            end
    
                            -- only add world with the same nid
                            LocalServiceWorld:AddWorldToDS({
                                worldpath = path .. '/' .. item.filename, 
                                foldername = filenameUTF8,
                                Title = display_name,
                                writedate = item.writedate,
                                createdate = item.createdate,
                                filesize = item.filesize,
                                nid = node.attr.nid,
                                author = item.author or 'None',
                                mode = item.mode or 'survival',
                                progress = item.progress or '0', -- the max value of the progress is 1
                                costTime = item.progress or '0:0:0', -- the format of costTime: 'day:hour:minute'
                                grade = item.grade or 'primary', -- maybe grade is 'primary' or 'middle' or 'adventure' or 'difficulty' or 'ultimate'
                                ip = item.ip or '127.0.0.1',
                                order = item.order,
                                IsFolder = true,
                                time_text = item.time_text,
                                channel = item.channel or 0,
                            })
    
                            bLoadedWorld = true
    
                            break
                        end
                    end
                end
    
                if not bLoadedWorld and
                   ParaIO.DoesFileExist(path .. '/' .. item.filename .. '/worldconfig.txt') then
                    local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
    
                    LOG.std(nil, 'info', 'LocalServiceWorld', 'missing tag.xml in %s', filenameUTF8)
    
                    LocalServiceWorld:AddWorldToDS({
                        worldpath = path .. '/' .. item.filename, 
                        foldername = filenameUTF8,
                        Title = filenameUTF8,
                        writedate = item.writedate,
                        filesize = item.filesize,
                        order = item.order,
                        IsFolder=true,
                        channel = item.channel or 0,
                    })
    
                    bLoadedWorld = true
                end	
            end
        end
    
        -- add *.zip world package file 
        local output = LocalLoadWorld.SearchFiles(nil, path, LocalLoadWorld.MaxItemPerFolder, '*.zip')

        if output and #output > 0 then    
            for _, item in ipairs(output) do
                local zip_filename = path .. '/' .. item.filename
                local world_name = zip_filename:match('([^/\\]+)%.zip$')
    
                if world_name then
                    world_name = commonlib.Encoding.DefaultToUtf8(world_name:gsub('^[%d_]*', ''))
                end
    
                LocalServiceWorld:AddWorldToDS({
                    worldpath = zip_filename, 
                    Title = world_name or '',
                    writedate = item.writedate,
                    filesize = item.filesize,
                    costTime = item.progress or '0:0:0',
                    nid = 0,
                    order = item.order,
                    IsFolder = false,
                    time_text = item.time_text,
                    channel = item.channel or 0,
                })	
            end
        end
    end

    -- add folders in worlds/DesignHouse
    if not System.options.isEducatePlatform or (System.options.isEducatePlatform  and System.options.isOffline) then
        Handle(folderPath)
    end
    -- add folders in worlds/DesignHouse/_user/<username>
    if not System.options.isEducatePlatform or (System.options.isEducatePlatform and not System.options.isOffline) then
        if curUserFolderPath and curUserFolderPath ~= "" and curUserFolderPath:find("_user/") then
            Handle(curUserFolderPath)
        end
    end
    table.sort(self.dsWorlds, function(a, b)
        return (a.order or 0) > (b.order or 0)
    end)

	return self.dsWorlds	
end

-- add a given world to datasource
function LocalServiceWorld:AddWorldToDS(worldInfo)
	if LocalLoadWorld.AutoCompleteWorldInfo(worldInfo) then
		table.insert(self.dsWorlds, worldInfo)
	end
end

-- only return the sub folders of the current folder
-- @param rootFolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootFolder file name.
function LocalServiceWorld:SearchFiles(output, rootFolder, nMaxFilesNum, filter)
	if rootFolder == nil then
        return
    end

	if filter == nil then
        filter = '*.'
    end

	output = output or {}

	local sInitDir

	if commonlib.Files.IsAbsolutePath(rootFolder) then
		sInitDir = rootFolder .. '/'
	else
        if System.os.GetPlatform() ~= 'win32' then
            sInitDir = ParaIO.GetWritablePath() .. rootFolder .. '/'
        else
            sInitDir = ParaIO.GetCurDirectory(0) .. rootFolder .. '/'
        end
	end

	local search_result = ParaIO.SearchFiles(sInitDir, filter, '', 0, nMaxFilesNum or 5000, 0)
	local nCount = search_result:GetNumOfResult()
	local nextIndex = #output + 1

	local i

    for i = 0, nCount - 1 do 
		output[nextIndex] = search_result:GetItemData(i, {})

        local date = output[nextIndex].writedate
		local year, month, day, hour, mins = string.match(date, "(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D+(%d+)")
		year, month, day,hour, mins = tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0, tonumber(hour) or 0, tonumber(mins) or 0
		output[nextIndex].order = (year * 380 + (month - 1) * 31 + day - 1) * 1440 + (hour - 1) * 60 + mins - 1
		output[nextIndex].time_text = string.format("%d年%d月%d日(%d点%d分)", year, month, day, hour, mins)
		nextIndex = nextIndex + 1
	end

	-- sort output by file.writedate
	table.sort(output, function(a, b)
		return a.order > b.order
	end)

	search_result:Release()

    return output
end

function LocalServiceWorld:CreateHomeWorld(myHomeWorldName)
    local username = Mod.WorldShare.Store:Get('user/username') or System.User.keepworkUsername
    if not username then
        LOG.std(nil,"info","LocalServiceWorld","user name is nil")
        return
    end
	local worldPath = CreateNewWorld.CreateWorld({
		worldname = myHomeWorldName, 
		title = format(L'%s的家园', username),
		creationfolder = self:GetUserFolderPath(),
		world_generator = 'paraworldMini',
		seed = worldname,
		inherit_scene = true,
		inherit_char = true,
	})

    KeepworkServiceWorld:OnCreateHomeWorld(worldPath, myHomeWorldName)

	return worldPath
end

function LocalServiceWorld:GetWorldList(isOffline)
    local localWorlds = self:BuildLocalWorldList()
    local filterLocalWorlds = {}

    -- not main world filter
    for key, item in ipairs(localWorlds) do
        if KeepworkServiceSession:IsSignedIn() then
            local username = Mod.WorldShare.Store:Get('user/username')

            if item and item.foldername then
                local matchFoldername = string.match(item.foldername, '(.+)_main$')

                if matchFoldername then
                    if matchFoldername == username then
                        filterLocalWorlds[#filterLocalWorlds + 1] = item
                    end
                else
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            else
                if not item.IsFolder then
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            end
        else
            if item and item.foldername and not string.match(item.foldername, '_main$') then
                filterLocalWorlds[#filterLocalWorlds + 1] = item
            else
                if not item.IsFolder then
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            end
        end
    end

    localWorlds = filterLocalWorlds

    local sharedWorldList = (System.options.isEducatePlatform or isOffline) and {} or self:GetSharedWorldList()

    for key, item in ipairs(sharedWorldList) do
        localWorlds[#localWorlds + 1] = item
    end
    local worldList = {}

    for key, value in ipairs(localWorlds) do
        local foldername = ''
        local Title = ''
        local text = ''
        local is_zip
        local revision = 0
        local kpProjectId = 0
        local parentProjectId = 0
        local size = 0
        local name = ''
        local isVipWorld = false
        local instituteVipEnabled = false
        local modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.writedate)
        local createTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.createdate)
        local platform = 'paracraft'
        local channel = 0
        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'
            is_zip = false
            revision = WorldRevision:new():init(value.worldpath):GetDiskRevision()
            foldername = value.foldername
            Title = value.Title

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()
            text = tag.name
            kpProjectId = tag.kpProjectId
            size = tag.size
            name = tag.name
            isVipWorld = tag.isVipWorld
            instituteVipEnabled = tag.instituteVipEnabled
            parentProjectId = tag.parentProjectId
            platform = tag.platform
            channel = tag.channel or 0
        else
            local zipFilename = string.match(value.worldpath, '/([^/.]+)%.zip$')
            zipFilename = commonlib.Encoding.DefaultToUtf8(zipFilename)

            foldername = zipFilename
            Title = zipFilename
            text = zipFilename

            is_zip = true
        end

        worldList[#worldList + 1] = self:GenerateWorldInstance({
            IsFolder = value.IsFolder,
            is_zip = is_zip,
            kpProjectId = kpProjectId,
            parentProjectId = parentProjectId,
            text = text,
            size = size,
            foldername = foldername,
            modifyTime = modifyTime,
            createTime = createTime,
            worldpath = value.worldpath,
            name = name,
            revision = revision,
            isVipWorld = isVipWorld,
            instituteVipEnabled = instituteVipEnabled,
            shared = value.shared or false,
            platform = platform,
            channel = channel,
        })
    end

    return worldList
end

function LocalServiceWorld:GetSharedWorldList()
    local dsWorlds = {}
    local SelectedWorld_Index = nil
    local username = self:GetLocalUsername()

    local function AddWorldToDS(worldInfo)
        if LocalLoadWorld.AutoCompleteWorldInfo(worldInfo) then
            table.insert(dsWorlds, worldInfo)
        end
    end

    local sharedWorldPath = self:GetDefaultSaveWorldPath() .. '/_shared/'

    if not ParaIO.DoesFileExist(sharedWorldPath) then
        return dsWorlds
    end

    local sharedFiles = LocalService:Find(sharedWorldPath)

    for key, item in ipairs(sharedFiles) do
        if item and item.filesize == 0 and item.filename ~= username then
            local folderPath = sharedWorldPath .. item.filename 

            local output = self:SearchFiles(nil, folderPath, LocalLoadWorld.MaxItemPerFolder)

            if output and #output > 0 then
                for _, item in ipairs(output) do
                    local bLoadedWorld
                    local xmlRoot = ParaXML.LuaXML_ParseFile(folderPath .. '/' .. item.filename .. '/tag.xml')
        
                    if xmlRoot then
                        for node in commonlib.XPath.eachNode(xmlRoot, '/pe:mcml/pe:world') do
                            if node.attr then
                                local display_name = node.attr.name or item.filename
                                local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
        
                                if filenameUTF8 ~= node.attr.name then
                                    -- show dir name if differs from world name
                                    display_name = format('%s(%s)', node.attr.name or '', filenameUTF8)
                                end

                                local worldpath = folderPath .. '/' .. item.filename
                                local remotefile = 'local://' .. worldpath
                                local worldUsername = Mod.WorldShare:GetWorldData('username', worldpath .. '/') or ''

                                -- only add world with the same nid
                                AddWorldToDS(
                                    {
                                        worldpath = worldpath,
                                        remotefile = remotefile,
                                        foldername = filenameUTF8,
                                        Title = worldUsername .. '/' .. display_name,
                                        writedate = item.writedate,
                                        filesize = item.filesize,
                                        nid = node.attr.nid,
                                        -- world's new property
                                        author = item.author or 'None',
                                        mode = item.mode or 'survival',
                                        -- the max value of the progress is 1
                                        progress = item.progress or '0',
                                        -- the format of costTime:  'day:hour:minute'
                                        costTime = item.progress or '0:0:0',
                                        -- maybe grade is 'primary' or 'middle' or 'adventure' or 'difficulty' or 'ultimate'
                                        grade = item.grade or 'primary',
                                        ip = item.ip or '127.0.0.1',
                                        order = item.order,
                                        IsFolder = true,
                                        time_text = item.time_text,
                                        shared = true,
                                    }
                                )
        
                                bLoadedWorld = true
                                break
                            end
                        end
                    end

                    if not bLoadedWorld and ParaIO.DoesFileExist(folderPath .. '/' .. item.filename .. '/worldconfig.txt') then
                        local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
        
                        LOG.std(nil, 'info', 'LocalWorld', 'missing tag.xml in %s', filenameUTF8)
                        AddWorldToDS(
                            {
                                worldpath = folderPath..'/'..item.filename, 
                                foldername = filenameUTF8,
                                Title = filenameUTF8,
                                writedate = item.writedate, filesize=item.filesize,
                                order = item.order,
                                IsFolder=true
                            }
                        )	
                        bLoadedWorld = true
                    end	
                end
            end
        end
    end

    table.sort(dsWorlds, function(a, b)
        return (a.order or 0) > (b.order or 0)
    end)

    return dsWorlds
end

function LocalServiceWorld:SetWorldInstanceByFoldername(foldername)
    if not foldername or type(foldername) ~= 'string' then
        return
    end

    local worldpath =
        format(
            '%s/%s/',
            self:GetDefaultSaveWorldPath(),
            commonlib.Encoding.Utf8ToDefault(foldername)
        )

    if not ParaIO.DoesFileExist(worldpath) then
        worldpath =
            format(
                '%s/%s/',
                self:GetUserFolderPath(),
                commonlib.Encoding.Utf8ToDefault(foldername)
            )
    end

    local currentWorld = nil

    local worldTag = LocalService:GetTag(worldpath) or {}
    local revision = WorldRevision:new():init(worldpath):GetDiskRevision()
    local shared = string.match(worldpath, 'shared') == 'shared' and true or false
    
    if worldTag.name ~= commonlib.Encoding.DefaultToUtf8(foldername) then
        text = worldTag.name
    end

    local fromProjectId = 0

    if worldTag.fromProjects then
        local fromProjectsTable = {}

        for item in string.gmatch(worldTag.fromProjects, '[^,]+') do
            fromProjectsTable[#fromProjectsTable + 1] = item  
        end

        if fromProjectsTable and #fromProjectsTable > 0 then
            fromProjectId = fromProjectsTable[#fromProjectsTable]
        end
    end

    currentWorld = self:GenerateWorldInstance({
        IsFolder = true,
        is_zip = false,
        text = worldTag.name,
        foldername = foldername,
        worldpath = worldpath,
        kpProjectId = worldTag.kpProjectId,
        parentProjectId = worldTag.parentProjectId,
        fromProjectId = fromProjectId,
        name = worldTag.name,
        modifyTime = 0,
        revision = revision,
        isVipWorld = worldTag.isVipWorld,
        communityWorld = worldTag.communityWorld,
        instituteVipEnabled = worldTag.instituteVipEnabled,
        shared = shared,
        platform = worldTag.platform,
        channel = worldTag.channel or 0,
    })

    Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

    return currentWorld
end

function LocalServiceWorld:GetMainWorldProjectId()
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()    
    if IsSummerUser then
        return Mod.WorldShare.Utils:GetConfig('campWorldId')
    end
    if not ParaWorldLoginAdapter or not ParaWorldLoginAdapter.ids then
        return false
    end

    local ids = ParaWorldLoginAdapter.ids[KeepworkService:GetEnv()]

    if ids and ids[1] then
        return ids[1]
    else
        return false
    end
end

function LocalServiceWorld:SetCommunityWorld(bValue)
    WorldCommon.SetWorldTag('communityWorld', bValue)
    GameLogic.QuickSave()
end

function LocalServiceWorld:IsCommunityWorld()
    local isCommunityWorld = WorldCommon.GetWorldTag('communityWorld')
    return isCommunityWorld == true or isCommunityWorld == "true"
end

-- exec from save_world_info filter
function LocalServiceWorld:SaveWorldInfo(ctx, node)
    if (type(ctx) ~= 'table' or
        type(node) ~= 'table' or
        type(node.attr) ~= 'table') then
        return false
    end

    node.attr.clientversion = LocalService:GetClientVersion() or ctx.clientversion
    node.attr.communityWorld = ctx.communityWorld or false
    node.attr.instituteVipEnabled = ctx.instituteVipEnabled or false
    node.attr.kpProjectId = ctx.kpProjectId and tonumber(ctx.kpProjectId) or 0
    node.attr.parentProjectId = ctx.parentProjectId and tonumber(ctx.parentProjectId) or 0
    node.attr.redirectLoadWorld = ctx.redirectLoadWorld or ''
    node.attr.instituteVipChangeOnly = ctx.instituteVipChangeOnly or false
    node.attr.instituteVipSaveAsOnly = ctx.instituteVipSaveAsOnly or false
end

function LocalServiceWorld:LoadWorldInfo(ctx, node)
    if type(ctx) ~= 'table' or
       type(node) ~= 'table' or
       type(node.attr) ~= 'table' then
        return false
    end

    ctx.communityWorld = ctx.communityWorld == 'true' or ctx.communityWorld == true
    ctx.instituteVipEnabled = ctx.instituteVipEnabled == 'true' or ctx.instituteVipEnabled == true
    ctx.kpProjectId = tonumber(ctx.kpProjectId) or 0
    ctx.parentProjectId = tonumber(ctx.parentProjectId) or 0
    ctx.redirectLoadWorld = ctx.redirectLoadWorld or ''
    ctx.instituteVipChangeOnly = ctx.instituteVipChangeOnly == 'true' or ctx.instituteVipChangeOnly == true
    ctx.instituteVipSaveAsOnly = ctx.instituteVipSaveAsOnly == 'true' or ctx.instituteVipSaveAsOnly == true
end

function LocalServiceWorld:CheckWorldIsCorrect(world)
    if not world or type(world) ~= 'table' or not world.worldpath then
        return
    end

    local output = commonlib.Files.Find({}, world.worldpath, 0, 500, 'worldconfig.txt')

    if not output or #output == 0 then
        return false
    else
        return true
    end
end

function LocalServiceWorld:GenerateWorldInstance(params)
    if not params or type(params) ~= 'table' then
        return {}
    end

    local remotefile = ''

    if params.remotefile then
        remotefile = params.remotefile
    else
        remotefile = format('local://%s', (params.worldpath or ''))
    end

    return {
        IsFolder = params.IsFolder == 'true' or params.IsFolder == true,
        is_zip = params.is_zip == 'true' or params.is_zip == true,
        kpProjectId = params.kpProjectId and tonumber(params.kpProjectId) or 0,
        fromProjectId = params.fromProjectId and tonumber(params.fromProjectId) or 0,
        hasPid = params.kpProjectId and params.kpProjectId ~= 0 and true or false,
        text = params.text or '',
        size = params.size or 0,
        foldername = params.foldername or '',
        modifyTime = params.modifyTime or '',
        createTime = params.createTime or '',
        worldpath = params.worldpath or '',
        remotefile = remotefile,
        revision = params.revision or 0,
        isVipWorld = params.isVipWorld or false,
        communityWorld = params.communityWorld or false,
        instituteVipEnabled = params.instituteVipEnabled or false,
        shared = params.shared or false,
        name = params.name or '',
        parentProjectId = params.parentProjectId or 0,
        platform = params.platform or 'paracraft',
        channel = tonumber(params.channel) or 0,
    }
end

function LocalServiceWorld:GetTagValue(tagPath,key)
    if not tagPath or tagPath == '' or not key or key == '' then
        return
    end

    if not ParaIO.DoesFileExist(tagPath) then
        return
    end

    local xmlRoot = ParaXML.LuaXML_ParseFile(tagPath)
    local data;
    if(xmlRoot) then
        for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
            data = node.attr
            break
        end
        return data and data[key]
    end 
end


function LocalServiceWorld:CheckCanForkWorld(fileList)
    if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
        return false
    end

    local worldPath 
    for key, item in ipairs(fileList) do
        if item.fileattr == 32 and item.filesize > 0 and item.filename:find("/tag.xml") then
            worldPath = item.file_path
            break
        end
    end
    if not worldPath or worldPath == '' or not ParaIO.DoesFileExist(worldPath)  then
        return false
    end

    local hasCopyright = self:GetTagValue(worldPath,'hasCopyright')
    if hasCopyright == 'true' or hasCopyright == true then
        return false
    end
    return true
end

-- mode: user , admin
function LocalServiceWorld:DownLoadZipWorld(foldername, username, lastCommitId, worldpath, callback,kpProjectId,mode)
    local qiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(foldername, username, lastCommitId)
    local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(foldername, username, lastCommitId,kpProjectId)
    local tryTimes = 0

    local function MoveZipToFolder()
        LocalService:MoveZipToFolder('temp/world_temp_download/', 'temp/archive.zip', function()
            local fileList = LocalService:LoadFiles('temp/world_temp_download/', true, true)

            if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
                return
            end

            if mode == 'user' and not self:CheckCanForkWorld(fileList) then
                if callback and type(callback) == 'function' then
                    callback(false)
                end
                ParaIO.DeleteFile('temp/world_temp_download/')
                return
            end
            
            local zipRootPath = ''

            if fileList[1] and fileList[1].filesize == 0 then
                zipRootPath = fileList[1].filename
            end

            ParaIO.CreateDirectory(worldpath)

            for key, item in ipairs(fileList) do
                if key ~= 1 then
                    local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename:gsub(zipRootPath .. '/', ''))

                    if item.filesize == 0 then
                        local folderPath = worldpath .. relativePath .. '/'

                        ParaIO.CreateDirectory(folderPath)
                    else
                        local filePath = worldpath .. relativePath

                        ParaIO.MoveFile(item.file_path, filePath)
                    end
                end
            end

            ParaIO.DeleteFile('temp/world_temp_download/')

            if callback and type(callback) == 'function' then
                callback(true)
            end
        end)
    end

    local function Download(url)
        local fileDownloader = FileDownloader:new()
        fileDownloader.isSlient = true

        fileDownloader:Init(
            foldername,
            url,
            'temp/archive.zip',
            function(bSuccess, downloadPath)
                if bSuccess then
                    MoveZipToFolder()
                else
                    if tryTimes > 1 then
                        if callback and type(callback) == 'function' then
                            callback(false)
                        end

                        return
                    end
                    tryTimes = tryTimes + 1

                    Download(cdnArchiveUrl)
                end
            end,
            'access plus 5 mins',
            false
        )
    end

    Download(qiniuZipArchiveUrl)
end

function LocalServiceWorld:EncryptWorld(originFile, encryptFile)
    if not originFile or
       type(originFile) ~= 'string' or
       not ParaIO.DoesFileExist(originFile) or
       not encryptFile or
       type(encryptFile) ~= 'string' or
       encryptFile == '' then
        return
    end

    local base = ParaIO.GetWritablePath()

    originFile = originFile:gsub('^' .. base, '')
    encryptFile = encryptFile:gsub('^' .. base, '')

    return ParaAsset.GeneratePkgFile(originFile, encryptFile)
end

function LocalServiceWorld:GetWhiteList()
    local filePath = 'Mod/WorldShare/data/WorldWhiteList.md'

    local readFile = ParaIO.open(filePath, 'r')
    local whiteList = {}

    if readFile:IsValid() then
        local content = readFile:GetText(0, -1)

        local _, items = MdParser:MdToTable(content)
        
        for key, item in ipairs(items) do
            if item and type(item) == 'table' then
                for IKey, IItem in pairs(item) do
                    if IKey ~= 'displayName' then
                        whiteList[#whiteList + 1] = tonumber(IItem)
                    end
                end
            end
        end

        readFile:close()
    end

    return whiteList
end

function LocalServiceWorld:OnSaveWorld()
    if not Mod.WorldShare.Store:Get('world/currentRevision') then
        return
    end

    local currentRevision = tonumber(Mod.WorldShare.Store:Get('world/currentRevision'))
    currentRevision = currentRevision + 1
    Mod.WorldShare.Store:Set('world/currentRevision', currentRevision)
end
