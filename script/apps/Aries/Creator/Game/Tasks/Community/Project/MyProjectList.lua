--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local MyProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/MyProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local MyProjectList = NPL.export()

local self = MyProjectList

MyProjectList.select_tab = -1
MyProjectList.sort_index = -1
MyProjectList.sort_order = -1
MyProjectList.currentWorldList = {}
MyProjectList.pageList = {}
MyProjectList.curPage = 1
MyProjectList.perPage = 12
MyProjectList.select_project_index = 1
MyProjectList.statusFilter = nil
MyProjectList.is_modify_world_name = false

local menu_data_sources = {
    {name="all", status="all",value=L"全部" },
    {name="online",  status="ONLINE",value=L"在线存档" },
    {name="local" , status="LOCAL",value=L"本地存档" },
    {name="recycle" , status="RECYCLE",value=L"回收站" },
}

local sort_data = {
    {name=L"创建时间", value="createTime"},
    {name=L"编辑时间", value="editTime"},
}

local page
function MyProjectList.OnInit()
    --TODO: init
    page = document:GetPageCtrl()
    if page then
        if MyProjectList.select_tab == -1 then
            MyProjectList.ChangeMenuTab(1)
        end
    end
end

function MyProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
        print("refresh my project page")
    end
end

function MyProjectList.OnClose()
    self.select_tab = -1
    self.sort_index = -1
    self.sort_order = -1
    self.searchText = nil
end

function MyProjectList.GetMenuData()
    return menu_data_sources
end

function MyProjectList.GetCategoryDSIndex()
    return MyProjectList.select_tab
end

function MyProjectList.ClearData()
    MyProjectList.is_modify_world_name = false
    MyProjectList.sort_index = -1
    MyProjectList.sort_order = -1
    MyProjectList.select_project_index = 1
    MyProjectList.curPage = 1
    MyProjectList.perPage = 12
    MyProjectList.statusFilter = nil
end

function MyProjectList.ChangeMenuTab(index)
    if index and index == MyProjectList.select_tab then
        return
    end
    MyProjectList.select_tab = index
    MyProjectList.ClearData()
    MyProjectList.RefreshPage()
    
    local status = menu_data_sources[index].status
    MyProjectList.GetProjectList(status)
end

function MyProjectList.GetSortData()
    return sort_data
end

function MyProjectList.GetSortType()
    return MyProjectList.sort_order
end

function MyProjectList.IsSortSelected(index)
    return index == MyProjectList.sort_index
end

function MyProjectList.OnSortProject(index)
    if not index then
        return
    end
    if index == MyProjectList.sort_index then
        if MyProjectList.sort_order == 0 then
            MyProjectList.sort_order = 1
        else
            MyProjectList.sort_order = 0
        end
    else
        MyProjectList.sort_index = index
        MyProjectList.sort_order = 0
    end
    MyProjectList.is_modify_world_name = false
    MyProjectList.select_project_index = 1
    MyProjectList.RefreshPage()
    MyProjectList.GetPageList()
end

function MyProjectList.GetPageList()
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
        --排序
        if MyProjectList.sort_index > 0 then
            local sortKey = sort_data[MyProjectList.sort_index].value
            local sortOrder = MyProjectList.sort_order == 0 and "DESC" or "ASC"
            table.sort(self.pageList, function(a, b)
                if sortKey == "createTime" then
                    if sortOrder == "DESC" then
                        return a.createTime > b.createTime
                    elseif sortOrder == "ASC" then
                        return a.createTime <= b.createTime
                    end
                elseif sortKey == "editTime" then
                    if sortOrder == "DESC" then
                        return a.modifyTime > b.modifyTime
                    elseif sortOrder == "ASC" then
                        return a.modifyTime <= b.modifyTime
                    end
                end
            end)
        end

        local gvw_name = "gw_world_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            --worldDsNode:SetAttribute('DataSource', self.pageList or {})
            pe_gridview.DataBind(worldDsNode, gvw_name, false);
        end
    end
end

function MyProjectList.GetSelectWorld(index)
    return Create:GetSelectWorld(index)
end

function MyProjectList.GetCurWorldInfo(infoType,worldIndex)
    return Create:GetCurWorldInfo(infoType, worldIndex)
end

function MyProjectList.IsProjectSelected(index)
    return index and index == MyProjectList.select_project_index
end

function MyProjectList.GetWorldListType()
    if MyProjectList.select_tab == 4 then
        return "DELETED"
    end
    return "MINE"
end

function MyProjectList.IsSelectRecycle()
    return MyProjectList.select_tab == 4
end

function MyProjectList.GetProjectList(status,callback)
    if status == "all" then
        statusFilter = nil
    else
        statusFilter = status
    end
    local worldListType = MyProjectList.GetWorldListType()
    self.statusFilter = statusFilter
    Create:SetWorldListType(worldListType)
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

function MyProjectList.OnSwitchWorld(index)
    if not index then
        return
    end
    MyProjectList.select_project_index = index
    print("OnSwitchWorld============", index)
    Create:OnSwitchWorld(index)
end

function MyProjectList.WorldRename(currentItemIndex, tempModifyWorldname, callback)
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

function MyProjectList.ShowExtraPanel()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return {}
    end
    local ctl = MyProjectList.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "MyProjectList.contextMenuCtrl",
			width = 114,
			height = 164, 
			DefaultNodeHeight = 36,
			onclick = MyProjectList.OnClickContextMenuItem,
		};
		MyProjectList.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        if self.IsSelectRecycle() then
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"恢复" .. "", Name = "restore", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"彻底删除" .. "", Name = "clear", Type = "Menuitem", onclick = nil, }))
        else
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"项目主页" .. "", Name = "web", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"切换版本" .. "", Name = "revision", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"打开文件夹" .. "", Name = "folder", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除世界" .. "", Name = "delete", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"修改世界名称" .. "", Name = "edit", Type = "Menuitem", onclick = nil, }))
        end
    end
    ctl:Show(mouse_x, mouse_y);
end

function MyProjectList.HideExtraPanel()

end

function MyProjectList.OnClickContextMenuItem(node)
	local name = node.Name
    MyProjectList.OnClickExtra(name)
end

function MyProjectList.OnClickExtra(name)
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
            MyProjectList.GetPageList()
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
                                    MyProjectList.GetProjectList(self.statusFilter)
                                else
                                    DeleteWorld:DeleteLocal(function()
                                        MyProjectList.GetProjectList(self.statusFilter)
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
        MyProjectList.OnDeleteProject()

    elseif name == "restore" then
        MyProjectList.RestoreWorld(currentWorld)
    elseif name == "clear" then
        MyProjectList.ForceDeletedWorld(currentWorld)
    elseif name == "edit" then
        MyProjectList.is_modify_world_name = true
        MyProjectList.RefreshPage()
    end
end

function MyProjectList.ForceDeletedWorld(currentWorld)
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    keepwork.project.forcedelete({
        router_params = {
                id = currentWorld.kpProjectId,
        }
    },function(err,msg,data)
        if err == 200 then
            GameLogic.AddBBS(nil, L'删除成功')
            
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.RestoreWorld(currentWorld)
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    keepwork.project.update({
        router_params = {
            id = currentWorld.kpProjectId,
        },
        isDeleted=0,
    },function(err,msg,data)
        if err == 200 then
            GameLogic.AddBBS(nil, L'恢复世界成功')
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.OnMouseWheel()

end

function MyProjectList.SearchProject(searchText)
    MyProjectList.GetProjectList(self.statusFilter)
end

function MyProjectList.OnCreateProject()
    local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
    CreateWorld:CreateNewWorld(nil, function()
        MyProjectList.RefreshPage(0.01)
    end)
end

function MyProjectList.OnOpenProject(index)
    if not index then
        return
    end
    Create:EnterWorld(index)
end

function MyProjectList.OnSyncProject(index)
    if not index then
        return
    end
    MyProjectList.OnSwitchWorld(index)
    Create:Sync(function(result)
        if result then
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.OnDeleteProject()
    Create:DeleteWorld(MyProjectList.select_project_index,function()
        MyProjectList.GetProjectList(self.statusFilter)
    end)
end
