--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local ShareProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ShareProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local ShareProjectList = NPL.export()

local self = ShareProjectList

ShareProjectList.currentWorldList = {}
ShareProjectList.pageList = {}
ShareProjectList.curPage = 1
ShareProjectList.perPage = 12
ShareProjectList.select_project_index = 1
ShareProjectList.statusFilter = nil
ShareProjectList.is_modify_world_name = false

local page
function ShareProjectList.OnInit()
    --TODO: init
    page = document:GetPageCtrl()
    if page then
        ShareProjectList.GetProjectList()
    end
end

function ShareProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
        print("refresh share project page")
    end
end

function ShareProjectList.OnClose()
    ShareProjectList.ClearData()
end

function ShareProjectList.ClearData()
    ShareProjectList.is_modify_world_name = false
    ShareProjectList.select_project_index = 1
    ShareProjectList.curPage = 1
    ShareProjectList.perPage = 12
    ShareProjectList.statusFilter = nil
end


function ShareProjectList.GetPageList()
    if not self.currentWorldList then
        return
    end
    local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
    if page then
        self.pageList = {}
        local itemCount = self.curPage * self.perPage

        for key, item in ipairs(self.currentWorldList) do
            if key <= itemCount then
                self.pageList[#self.pageList + 1] = item
            end
        end

        local gvw_name = "gw_share_world_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            --worldDsNode:SetAttribute('DataSource', self.pageList or {})
            pe_gridview.DataBind(worldDsNode, gvw_name, false);
        end
    end
end

function ShareProjectList.GetSelectWorld(index)
    return Create:GetSelectWorld(index)
end

function ShareProjectList.GetCurWorldInfo(infoType,worldIndex)
    return Create:GetCurWorldInfo(infoType, worldIndex)
end

function ShareProjectList.IsProjectSelected(index)
    return index and index == ShareProjectList.select_project_index
end

function ShareProjectList.GetProjectList(statusFilter,callback)
    self.statusFilter = nil
    Create:SetWorldListType("SHARED")
    Create:GetWorldList(self.statusFilter, function(currentWorldList)
        self.currentWorldList = currentWorldList
        print("currentWorldList===========", #self.currentWorldList)
        -- echo(self.currentWorldList,true)
        self.GetPageList()

        if callback and type(callback) == 'function' then
            callback()
        end

    end)
end

function ShareProjectList.OnSwitchWorld(index)
    if not index then
        return
    end
    ShareProjectList.select_project_index = index
    print("OnSwitchWorld============", index)
    Create:OnSwitchWorld(index)
end

function ShareProjectList.WorldRename(currentItemIndex, tempModifyWorldname, callback)
    if not page then
        return
    end

    local currentWorld = Compare:GetSelectedWorld(currentItemIndex)

    if not currentWorld then
        return
    end

    if currentWorld.is_zip then
        GameLogic.AddBBS(nil, L'暂不支持重命名zip世界', 3000, '255 0 0')
        return
    end

    if not tempModifyWorldname or tempModifyWorldname == '' then
        return
    end

    if currentWorld.status ~= 2 then
        if currentWorld.name == tempModifyWorldname then
            return
        end

        local tag = LocalService:GetTag(currentWorld.worldpath)

        -- update local tag name
        tag.name = tempModifyWorldname
        currentWorld.name = tempModifyWorldname

        LocalService:SetTag(currentWorld.worldpath, tag)
        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    end

    if KeepworkServiceSession:IsSignedIn() and
       currentWorld.status and
       currentWorld.status ~= 1 and
       currentWorld.kpProjectId and
       currentWorld.kpProjectId ~= 0 then

        -- update project info
        local tag = LocalService:GetTag(currentWorld.worldpath)

        if currentWorld.status ~= 2 then
            -- update sync world
            -- local world exist

            -- get members for shared world
            KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(data)
                local members = {}

                for key, item in ipairs(data) do
                    members[#members + 1] = item.username
                end
                
                currentWorld.members = members

                Mod.WorldShare.Store:Set('world/currentRevision', currentWorld.revision)
                Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    
                SyncWorld:SyncToDataSource(function(result, msg)
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end)
            end)
        elseif currentWorld.status == 2 then
            -- just remote world exist
            KeepworkServiceWorld:GetWorld(
                currentWorld.foldername,
                currentWorld.shared,
                currentWorld.user.id,
                function(data)
                    local extra = data and data.extra or {}

                    extra.worldTagName = tempModifyWorldname

                    -- local world not exist
                    KeepworkServiceProject:UpdateProject(
                        currentWorld.kpProjectId,
                        {
                            extra = extra
                        },
                        function(data, err)
                            if callback and type(callback) == 'function' then
                                callback()
                            end
                        end
                    )
                end
            )
        end
    else
        if callback and type(callback) == 'function' then
            callback()
        end
    end

    return true
end

function ShareProjectList.ShowExtraPanel()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return {}
    end
    local ctl = ShareProjectList.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "ShareProjectList.contextMenuCtrl",
			width = 114,
			height = 164, 
			DefaultNodeHeight = 36,
			onclick = ShareProjectList.OnClickContextMenuItem,
		};
		ShareProjectList.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"项目主页" .. "", Name = "web", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"切换版本" .. "", Name = "revision", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"打开文件夹" .. "", Name = "folder", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"退出世界" .. "", Name = "exit", Type = "Menuitem", onclick = nil, }))
    end
    ctl:Show(mouse_x, mouse_y);
end

function ShareProjectList.OnClickContextMenuItem(node)
	local name = node.Name
    ShareProjectList.OnClickExtra(name)
end

function ShareProjectList.OnClickExtra(name)
    if not name  or name == '' then
        return
    end
    local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
    print("OnClickExtra====================", name)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    if name == "web" then
        local kpProjectId = currentWorld.kpProjectId
        if not kpProjectId or kpProjectId == 0 then
            return
        end
        local url = format('/pbl/project/%d/', kpProjectId)
        Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
    elseif name == "revision" then
        if currentWorld and currentWorld.status == 1 then
            _guihelper.MessageBox(L'此世界仅在本地，无需切换版本')
            return
        end
        local VersionChange = NPL.load('(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua')
        VersionChange:Init(currentWorld.foldername, function()
            ShareProjectList.GetPageList()
        end)
    elseif name == "folder" then
        if System.os.GetPlatform() ~= 'win32' and
            System.os.GetPlatform() ~= 'mac' then
            _guihelper.MessageBox(L'暂不支持当前系统打开文件夹')
            return
        end


        if currentWorld and
            type(currentWorld) == 'table' and
            currentWorld.status and
            currentWorld.status == 2 then
            _guihelper.MessageBox(L'请先下载世界')
            return
        end

        local worldpath = currentWorld.worldpath or ''

        Map3DSystem.App.Commands.Call(
            'File.WinExplorer',
            {
                filepath = ParaIO.GetWritablePath() .. worldpath,
                silentmode = true
            }
        )
    elseif name == "exit" then
        local selectedWorld = currentWorld
        _guihelper.MessageBox(
            format(L'确定要退出《%s》项目？<br />(注意：退出后本地数据也会删除！)', selectedWorld.text),
            function(res)
                if res and res == _guihelper.DialogResult.Yes then
                    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                    if currentWorld.kpProjectId == selectedWorld.kpProjectId then
                        KeepworkServiceProject:LeaveMultiProject(currentWorld.kpProjectId, function(data, err)
                            if err == 200 then
                                if currentWorld.status == 2 then
                                    ShareProjectList.GetProjectList(self.statusFilter)
                                else
                                    DeleteWorld:DeleteLocal(function()
                                        ShareProjectList.GetProjectList(self.statusFilter)
                                    end, true)
                                end
                            end
                        end)
                    end
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    elseif name == "delete" then
        ShareProjectList.OnDeleteProject()
    end
end

function ShareProjectList.OnMouseWheel()

end

function ShareProjectList.SearchProject(searchText)
    self.GetProjectList(self.statusFilter, function()
        
    end)
end

function ShareProjectList.OnOpenProject(index)
    if not index then
        return
    end
    Create:EnterWorld(index)
end

function ShareProjectList.OnSyncProject(index)
    if not index then
        return
    end
    Create:Sync(index)
end

function ShareProjectList.OnDeleteProject()
    Create:DeleteWorld(ShareProjectList.select_project_index,function()
        ShareProjectList.GetProjectList(self.statusFilter)
    end)
end
