--[[
    author:{pbb}
    time:2023-02-09 17:50:48
    uselib:
        local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
        EducateProject.ShowCreate()
        EducateProject.ShowPage()
]]
local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
local EducateProject = NPL.export()
local page,page_root
function EducateProject.OnInit()
    page = document:GetPageCtrl()
    if page then
        EducateProject.ShowCreate()
    end

end

function EducateProject.ShowCreate()
    if Opus and type(Opus.ShowCreate) == "function" then
        local width = 1132
        local height = 470
        local x = -510
        local y = -220
        Opus:ShowCreate(nil,width,height,x,y,true,-1)
    end
    EducateProject.GetUserWorldUsedSize()
end

function EducateProject.CloseCreate(bDestroy)
    Opus:CloseOpus()
    EducateProject.CloseMenu(bDestroy)
end

function EducateProject.GetUserWorldUsedSize()
    print("GetUserWorldUsedSize=====================")
    keepwork.world.gettotalsize({},function(err,msg,data)
        if err == 200 and data then
            if System.options.isDevMode then
                print("err=========",err)
                echo(data,true)
            end
            local gbSize = 1024*1024*1024 --1GB
            local totalSize = tonumber(data.total) or 0 --总容量
            local surplus = tonumber(data.surplus) or 0 --剩余容量
            surplus = math.max(surplus,0)
            local use = tonumber(data.use) or 0 --使用容量
            EducateProject.surplus = surplus
            if surplus then
                local objText = ParaUI.GetUIObject("project_memui")
                if objText:IsValid() then
                    if surplus >= 0 and surplus < gbSize then
                        objText.text = "剩余存档空间："..(math.floor((surplus/1024/1024)*10)/10).."MB"
                    else
                        objText.text = "剩余存档空间："..(math.floor((surplus/gbSize)*10)/10).."GB"
                    end
                end
            end
        else
            if err == 401 then
                GameLogic.AddBBS(nil,"用户登录态失效，请重新登录")
                GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                    EducateProject.GetUserWorldUsedSize()
                    EducateProject.RefreshPage()
                end)
                return
            end
            local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
            EducateMainPage.LoginOutByErrToken(err)
        end
    end)
end

function EducateProject.SyncLocalWorld(worldPath)
    if not worldPath or worldPath == "" then
        return
    end
    local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
    local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
    local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
    local userPath = LocalServiceWorld:GetUserFolderPath()
    local worldName = worldPath:gsub(userPath,""):gsub("/","")
    local currentWorld = LocalServiceWorld:SetWorldInstanceByFoldername(worldName)
    if currentWorld then
        Mod.WorldShare.Store:Set('world/currentEnterWorld', currentWorld)
        ShareWorld:SyncWorld(function(bSuccess)
            if bSuccess then
                GameLogic.AddBBS(nil,L"保存世界成功")
            else
                GameLogic.AddBBS(nil,L"保存世界失败")
            end
            EducateProject.RefreshPage()
        end)
        return
    end
    GameLogic.AddBBS(nil,L"保存世界失败")
end

function EducateProject.RefreshPage()
    if page then
        EducateProject.CloseCreate()
        page:Refresh(0.1)
    end
end

function EducateProject.ShowOptionMenu()
    EducateProject.bIsShowMenu = not EducateProject.bIsShowMenu
    local nodeMenuPos = ParaUI.GetUIObject("option_menu_pos");
    if not nodeMenuPos or not nodeMenuPos:IsValid() then
        print("界面异常")
        return 
    end
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        local x,y,width,height = nodeMenuPos:GetAbsPosition()
        local __this = ParaUI.CreateUIObject("container","edu_project_menu", "_lt",x + 18,y + 34,150,100);
        __this.zorder = 100
        __this.background = ""
        __this:AttachToRoot();
        EducateProject.nodeContainer = __this

        local btnNode=ParaUI.CreateUIObject("button","p3d_button", "_lt",10,10,120,30);
        btnNode.text="导入p3d文件";
        btnNode.background="Texture/Aries/Creator/keepwork/ClassManager/gray_button_32bits.png;0 0 16 16:7 7 7 7";
        btnNode:SetScript("onclick",function()
            EducateProject.CloseMenu()
            commonlib.TimerManager.SetTimeout(function()  
                GameLogic.RunCommand("/menu file.importp3dfile")
            end, 200);
            
        end)
        __this:AddChild(btnNode)
        
        btnNode=ParaUI.CreateUIObject("button","project_button", "_lt",10,50,120,30);
        btnNode.text="激活更多存档";
        btnNode.background="Texture/Aries/Creator/keepwork/ClassManager/gray_button_32bits.png;0 0 16 16:7 7 7 7";
        btnNode:SetScript("onclick",function()
            local ProjectActivationList = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ProjectActivationList.lua")
            EducateProject.CloseMenu()
            ProjectActivationList.ShowPage()
        end)
        __this:AddChild(btnNode)
        
    end
    EducateProject.nodeContainer.visible = EducateProject.bIsShowMenu
end

function EducateProject.CloseMenu(bDestroy)
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        return 
    end
    EducateProject.bIsShowMenu = false
    EducateProject.nodeContainer.visible = EducateProject.bIsShowMenu
    if bDestroy then
        ParaUI.Destroy("edu_project_menu");
    end
end

function EducateProject.RefreshMenu()
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        return 
    end
    local nodeMenuPos = ParaUI.GetUIObject("option_menu_pos");
    if not nodeMenuPos or not nodeMenuPos:IsValid() then
        return 
    end
    local x,y,width,height = nodeMenuPos:GetAbsPosition()
    EducateProject.nodeContainer.x = x
    EducateProject.nodeContainer.y = y
end

