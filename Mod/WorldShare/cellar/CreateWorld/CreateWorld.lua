--[[
Title: CreateWorld
Author(s): big
CreateDate: 2018.08.01
ModifyDate: 2021.09.10
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
------------------------------------------------------------
]]

-- libs
local CreateModulPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua')

NPL.load('(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua')

local CreateNewWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.CreateNewWorld')
local LocalLoadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.LocalLoadWorld')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername, callback,bForceCreate)
    local function Handle()
        self.bForceCreate = bForceCreate
        CreateNewWorld.ShowPage(true,bForceCreate)
        if foldername and type(foldername) == 'string' then
            if CreateNewWorld.page then
                if bForceCreate then
                    CreateNewWorld.LastWorldName = foldername
                end
                CreateNewWorld.page:SetValue('new_world_name', foldername)
                CreateNewWorld.page:Refresh(0.01)
            end
        end
    end

    if KeepworkServiceSession:IsSignedIn() then
        KeepworkServiceWorld:LimitFreeUser(false, function(result)
            if result or System.options.isEducatePlatform then
                Handle()
            else
                if System.options.isChannel_430 then
                    _guihelper.MessageBox(L"您当前只能创建家园与一个存档。", function(result)
                        if result == _guihelper.DialogResult.OK then
                            
                        end
                    end, _guihelper.MessageBoxButtons.OK, nil, nil, nil, nil, {ok=L"确定"});
                else
                    GameLogic.ShowVipGuideTip("UnlimitWorldsNumber")
                end
            end
        end)
    else
		if(System.options.DisableOfflineMode) then
			LoginModal:CheckSignedIn(L'请先登录！', function(bIsSuccessed)
				if bIsSuccessed then
					_guihelper.MessageBox(L'登录成功')

					if callback and type(callback) == 'function' then
						callback()
					end
				end
			end)
		else
			Handle()
		end
    end
end

function CreateWorld.OnClickCreateWorld()
    CreateWorld:OnClickCreateWorldImp()

    return true
end

function CreateWorld.OnBeforeLoadWorld()
    if not CreateWorld.currentWorld then
        return
    end
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    if CreateWorld.bForceCreate then
        local kpProjectId = CreateWorld.currentWorld.id or 0
        WorldCommon.SetWorldTag("kpProjectId", kpProjectId);
    end
    if CreateWorld.currentWorld.isDeleted == 1 then
        WorldCommon.SetWorldTag("name", CreateWorld.currentWorld.name);
    end
    WorldCommon.SaveWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",CreateWorld.OnBeforeLoadWorld);
    CreateWorld.currentWorld = nil
    CreateWorld.bForceCreate = false
end

function CreateWorld:OnClickCreateWorldImp()
    local foldername = CreateNewWorld.page:GetValue('new_world_name')
    local currentWorldList = Mod.WorldShare.Store:Get('world/fullWorldList') or {}
    foldername = foldername:gsub('[%s/\\]', '')
    local isFind,currentWorld = false,nil
    for key, item in ipairs(currentWorldList) do
        if item and foldername and (item.name == foldername) then
            -- _guihelper.MessageBox(L'世界名已存在，请列表中进入')
            isFind = true
            currentWorld = item
            break
        end
    end
    if isFind then
        if not self.bForceCreate and (not currentWorld.isDeleted or currentWorld.isDeleted == 0) then
            _guihelper.MessageBox(L'已有相同名称的世界，请重新输入世界名')
            return
        end
        if currentWorld.isDeleted == 1 then
            foldername = foldername.."_"..os.time()
        end
        self.currentWorld = currentWorld
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", CreateWorld.OnBeforeLoadWorld); 
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and currentEnterWorld.foldername == foldername then
        _guihelper.MessageBox(L'世界名已存在，请列表中进入')
        return
    end

    -- 客户端处理敏感词
    local temp = MyCompany.Aries.Chat.BadWordFilter.FilterString(foldername);

    if temp ~= foldername then 
        _guihelper.MessageBox(L"该世界名称不可用，请重新设定")
        return
    end

    local worldPath = ParaIO.GetWritablePath() .. 'worlds/DesignHouse/' .. foldername

    if ParaIO.DoesFileExist(worldPath, true) == true then
        Mod.WorldShare.worldpath = nil -- force update world data.
        local curWorldUsername = Mod.WorldShare:GetWorldData('username', worldPath)
        local backUpWorldPath

        if curWorldUsername then
            backUpWorldPath =
                LocalServiceWorld:GetDefaultSaveWorldPath() ..
                '/_user/' ..
                curWorldUsername ..
                '/' ..
                commonlib.Encoding.Utf8ToDefault(foldername)

            commonlib.Files.MoveFolder(worldPath, backUpWorldPath)

            ParaIO.DeleteFile(worldPath)
        end
    end

    Mod.WorldShare.Store:Remove('world/currentWorld')

	local item = CreateNewWorld.cur_terrain

	-- mini terrain chunk
	if item and item.terrain == "paraworldMini" then
            if CreateNewWorld.HideMiniCreateModul then
                CreateNewWorld.HideMiniCreateModul = false
                self:CreateWorldByName(foldername, "paraworldMini")
            else
                CreateModulPage.Show(foldername)
                CreateNewWorld.ClosePage()
            end
		return
	end

	self:CreateWorldByName(foldername, CreateNewWorld.cur_terrain.terrain)
end

function CreateWorld:CreateWorldByName(worldName, terrain,bOpen)
	worldName = worldName:gsub('[%s/\\]', '')

	local worldNameLocale = commonlib.Encoding.Utf8ToDefault(worldName)

	if worldName == '' then
		_guihelper.MessageBox(L'世界名字不能为空, 请输入世界名称')
		return
	else
		local count = 0

		for uchar in string.gfind(worldName, '([%z\1-\127\194-\244][\128-\191]*)') do
			if #uchar ~= 1 then
				count = count + 2
			else
				count = count + 1
			end
		end

		if count > 66 then
			_guihelper.MessageBox(format(L'世界名字超过%d个字符, 请重新输入', 66))
			return
		end
	end

    local platform = System.options.appId or 'paracraft'

	local params = {
		worldname = worldNameLocale,
		title = worldName,
		creationfolder = self:GetWorldFolder(),
		parentworld = nil,
		world_generator = terrain,
		seed = worldName,
		inherit_scene = true,
		inherit_char = true,
        platform = platform,
	}

	LOG.std(nil, 'info', 'CreateWorld', params)

	GameLogic.GetFilters():apply_filters('user_event_stat', 'world', 'create:' .. tostring(worldName), 10, nil)

	local worldPath, errorMsg = CreateNewWorld.CreateWorld(params)

	if not worldPath then
        local ctrl = CreateNewWorld.page and CreateNewWorld.page:FindControl("world_name_error_tip")
        if ctrl then
            ctrl.visible = true
        end
		if errorMsg then
			_guihelper.MessageBox(errorMsg)
		end
	else
		LOG.std(nil, 'info', 'CreateNewWorld', 'new world created at %s', worldPath)

        CreateNewWorld.ClosePage()

        if bOpen == nil or bOpen == true then
		    WorldCommon.OpenWorld(self:GetWorldFolder() .. '/' .. params.worldname, true)
        end

        GameLogic:UserAction('introduction')
		GameLogic.GetFilters():apply_filters('OnWorldCreate', worldNameLocale)
	end
end

function CreateWorld:GetWorldFolder()
    local username = Mod.WorldShare.Store:Get('user/username')
    if username and not System.options.isOffline then
        return LocalServiceWorld:GetDefaultSaveWorldPath() .. '/_user/' .. username
    else
        return LocalServiceWorld:GetDefaultSaveWorldPath()
    end
end

function CreateWorld.ClosePage()
    CreateNewWorld.ClosePage()
end
