--[[
Title: create world command
Author(s): big
Date: 2021.4.27
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorldCommand = NPL.load('(gl)Mod/WorldShare/command/CreateWorldCommand.lua')
-------------------------------------------------------
]]

-- load libs
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')
local Commands = commonlib.gettable('MyCompany.Aries.Game.Commands')
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")

-- bottles
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')

-- services
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

local CreateWorldCommand = NPL.export()

function CreateWorldCommand:Init()
    local createworld = {
        name="createworld", 
        quick_ref='/createworld [-name] worldname [-parentProjectId id] [-update] [-fork id] [-redirectLoadWorld cmd]',
        desc=[[create a new world by world name or from an existing world
@param -name: new world name
@param -worldGenerator: world type
@param -parentProjectId: parent world Id
@param -update: update world if remote world exist
@param -fork: create a new world from an existing world
@param -redirectLoadWorld: set a redirect command in world tag
@param -forkType: fork type ,default is nil ,if the command is from keepwork, forkType can be 'keepwork' 
e.g.
/createworld test
/createworld -name "my_new_world"
/createworld -name "my_new_world" -worldGenerator paraworldMini
/createworld -name "my_new_world" -parentProjectId 888
/createworld -name "my_new_world" -parentProjectId 888 -update -fork 888 -redirectLoadWorld "/loadworld -s 888"
        ]],
        mode_deny = "",
        handler = function(cmd_name, cmd_text, cmd_params)
            --if not KeepworkServiceSession:IsSignedIn() then
            --    return
            --end

            local option = ''
            local name = ''
            local worldGenerator = ''
            local parentProjectId = 0
            local isUpdate = false
            local fromProjectId = 0
            local isRedirectLoadWorld = false
            local redirectLoadWorld = ''
            local forkType
            local beforeCmdText = ''

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if not option or option == 'name' then
                name, cmd_text = CmdParser.ParseFilename(cmd_text)
            else
                return
            end
            if(not name or name == "") then
                return
            end

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'worldGenerator' then
                worldGenerator, cmd_text = CmdParser.ParseString(cmd_text)
            else
                cmd_text = beforeCmdText
            end

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'parentProjectId' then
                parentProjectId, cmd_text = CmdParser.ParseInt(cmd_text)
            else
                cmd_text = beforeCmdText
            end

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'update' then
                isUpdate = true
            else
                cmd_text = beforeCmdText
            end

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'fork' then
                fromProjectId, cmd_text = CmdParser.ParseInt(cmd_text)
            else
                cmd_text = beforeCmdText
            end

            beforeCmdText = cmd_text
            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'redirectLoadWorld' then
                isRedirectLoadWorld = true
                redirectLoadWorld = cmd_text
                redirectLoadWorld = string.match(redirectLoadWorld, '^"(.+)"')
            end

            if option == 'forkType' then
                forkType = cmd_text
            end
            
            if forkType and forkType == 'keepwork' then
                if not KeepworkServiceSession:IsSignedIn() then
                    GameLogic.AddBBS(nil,"请先登录")
                    return
                end
            end

            local worldPath

            if KeepworkServiceSession:IsSignedIn() then
                worldPath = LocalServiceWorld:GetUserFolderPath() .. '/' .. commonlib.Encoding.Utf8ToDefault(name) .. '/'
            else
                worldPath = LocalServiceWorld:GetDefaultSaveWorldPath() .. '/' .. commonlib.Encoding.Utf8ToDefault(name) .. '/'
            end
            
            local tagPath = worldPath .. 'tag.xml'

            local isLocalWorldExisted = false

            if ParaIO.DoesFileExist(tagPath) then
                isLocalWorldExisted = true
            end

            local function SetParentProjectIdAndRedirectLoadWorld()
                local tag = LocalService:GetTag(worldPath)

                if parentProjectId ~= 0 then
                    tag.parentProjectId = parentProjectId
                end

                if isRedirectLoadWorld then
                    tag.redirectLoadWorld = redirectLoadWorld
                end

                if worldGenerator and worldGenerator ~= '' then
                    tag.world_generator = worldGenerator
                end

                if System.options.isEducatePlatform then
                    tag.platform = System.options.appId
                end

                LocalService:SetTag(worldPath, tag)

                if forkType and forkType == 'keepwork' then
                    commonlib.TimerManager.SetTimeout(function()
                        GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
                    end,500)
                    
                end
            end

            local function CreateWorldLocally_()
                local params = {
                    worldname = commonlib.Encoding.Utf8ToDefault(name),
                    title = name,
                    creationfolder = CreateNewWorld.GetWorldFolder(),
                    world_generator = worldGenerator,
                    seed = name,
                    inherit_scene = true,
                    inherit_char = true,
                }
    
                local worldPath, errorMsg = CreateNewWorld.CreateWorld(params)

                if worldPath then
                    SetParentProjectIdAndRedirectLoadWorld()
                    GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                end
            end
            
            if not KeepworkServiceSession:IsSignedIn() then
                if not isLocalWorldExisted then
                    if fromProjectId ~= 0 then
                        KeepworkServiceProject:GetProject(fromProjectId, function(data, err)
                            if not data or
                               type(data) ~= 'table' or
                               not data.name or
                               not data.username or
                               not data.world or
                               not data.world.commitId then
                                return
                            end
                    
                            LocalServiceWorld:DownLoadZipWorld(
                                data.name,
                                data.username,
                                data.world.commitId,
                                worldPath,
                                function()
                                    local tag = LocalService:GetTag(worldPath)

                                    if not tag and type(tag) ~= 'table' then
                                        return
                                    end
                                    self:ClearOtherData(tag,worldPath)
                                    if not tag.fromProjects then
                                        tag.fromProjects = tostring(tag.kpProjectId)
                                    else
                                        tag.fromProjects = tag.fromProjects .. ',' .. tostring(tag.kpProjectId)
                                    end

                                    tag.kpProjectId = nil
                                    tag.name = name

                                    LocalService:SetTag(worldPath, tag)

                                    SetParentProjectIdAndRedirectLoadWorld()
                                    GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                                end
                            )
                        end)
                    else
                        CreateWorldLocally_();
                    end

                    return
                end
                SetParentProjectIdAndRedirectLoadWorld()
                GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                return
            end

            KeepworkServiceWorld:GetMyWorldByWorldName(name, function(data)
                local isRemoteWorldExisted = false

                if data then
                    isRemoteWorldExisted = true
                end

                if not isLocalWorldExisted and isRemoteWorldExisted then
                    LocalServiceWorld:DownLoadZipWorld(
                        data.worldName,
                        data.user.username,
                        data.commitId,
                        worldPath,
                        function()
                            SetParentProjectIdAndRedirectLoadWorld()
                            GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                        end
                    )

                    return
                end

                if isLocalWorldExisted and not isRemoteWorldExisted then
                    SetParentProjectIdAndRedirectLoadWorld()
                    GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)

                    return
                end

                if isLocalWorldExisted and isRemoteWorldExisted then
                    if isUpdate then
                        SyncWorld:CheckAndUpdatedByFoldername(name, function()
                            SetParentProjectIdAndRedirectLoadWorld()
                            GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                        end)
                        return
                    end

                    SetParentProjectIdAndRedirectLoadWorld()
                    GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)

                    return
                end

                if not isLocalWorldExisted and not isRemoteWorldExisted then
                    if fromProjectId ~= 0 then
                        KeepworkServiceProject:GetProject(fromProjectId, function(data, err)
                            if not data or
                               type(data) ~= 'table' or
                               not data.name or
                               not data.username or
                               not data.world or
                               not data.world.commitId then
                                return
                            end
                    
                            LocalServiceWorld:DownLoadZipWorld(
                                data.name,
                                data.username,
                                data.world.commitId,
                                worldPath,
                                function()
                                    local tag = LocalService:GetTag(worldPath)

                                    if not tag and type(tag) ~= 'table' then
                                        return
                                    end
                                    self:ClearOtherData(tag,worldPath)
                                    if not tag.fromProjects then
                                        tag.fromProjects = tostring(tag.kpProjectId)
                                    else
                                        tag.fromProjects = tag.fromProjects .. ',' .. tostring(tag.kpProjectId)
                                    end

                                    tag.kpProjectId = nil
                                    tag.name = name

                                    LocalService:SetTag(worldPath, tag)

                                    SetParentProjectIdAndRedirectLoadWorld()
                                    GameLogic.RunCommand('/sendevent createworld_callback '..worldPath)
                                end
                            )
                        end)
                    else
                        CreateWorldLocally_();
                    end

                    return
                end
            end)
        end,
    }

    Commands['createworld'] = createworld

    return createworld
end

function CreateWorldCommand:ClearOtherData(tag,folderName)
    local setAttrValueDefault = function (attrs)
		for key, value in pairs(attrs) do
			if tag and tag[value] ~=nil then
				tag[value] = nil
			end
		end
	end
    local keys = {"communityWorld","instituteVipChangeOnly","instituteVipEnabled","instituteVipSaveAsOnly","isVipWorld",
	"totalEditSeconds","totalClicks","totalKeyStrokes","totalSingleBlocks","totalWorkScore","editCodeLine","world_edit_code"}
    setAttrValueDefault(keys)

    local deleteList = {
        "user_action_path.xml","block_hotVal_map.xml","user_code_data.xml","user_bones_data.xml","codeblock.txt",
        "stats/user_action_path.xml","stats/block_hotVal_map.xml","stats/user_code_data.xml","stats/user_bones_data.xml","stats/codeblock.txt",
    }
    for k,v in ipairs(deleteList) do
        local path = folderName.."/"..v 
        if ParaIO.DoesFileExist(path) then
            ParaIO.DeleteFile(path)
        end
    end
end