--[[
    author(s): pbb
    date: 2024/03/19
    uselib:
        local ChangeVersion = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdate/ChangeVersion.lua");
        ChangeVersion.ShowPage(params,OnClickUpdate)
]]

local ChangeVersion = NPL.export()
local page
ChangeVersion.current_version = "1.0.0"
ChangeVersion.latest_version = "1.0.0"
ChangeVersion.mini_version = "1.0.0"
ChangeVersion.OnClickUpdate = nil
ChangeVersion.htmlData = ""

local edu_url = {
    ONLINE = "keepwork/changelog/paracraft/changelog_zh",
    STAGE = "deng123457/docs/changelog/palakaedu",
    RELEASE = ""
}
    
local plaka_url = {
    ONLINE = "keepwork/changelog/paracraft/changelog_zh",
    STAGE = "deng123457/docs/changelog/paracraft",
    RELEASE = ""
}

function ChangeVersion.OnInit()
    page = document:GetPageCtrl()
end

function ChangeVersion.ShowPage(params,OnClickUpdate)
    ChangeVersion.latest_version = params.latestVersion
    ChangeVersion.current_version = params.curVersion
    ChangeVersion.mini_version = params.miniVersion
    ChangeVersion._updater = params.updater
    local gameName = params.gamename
    ChangeVersion.OnClickUpdate = OnClickUpdate
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Login/ClientUpdate/ChangeVersion.html", 
        name = "UpdatePage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 999,
        enable_esc_key = true,
        allowDrag = false,
        --isTopLevel = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    }
    System.App.Commands.Call("File.MCMLWindowFrame",params)
    ChangeVersion.OnGetUpldateLog()
end

function ChangeVersion.OnGetUpldateLog2()
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
    local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
	local MdParser = NPL.load('(gl)Mod/WorldShare/parser/MdParser.lua')
    local update_url = System.options.isEducatePlatform and edu_url or plaka_url
    local env = HttpWrapper.GetDevVersion()
    local url = update_url[env]
	KeepWork.GetRawFileByPath(url, function(err, msg, data)
        print("OnGetUpldateLog===============",err, msg)
		if err == 200 then
            ChangeVersion.htmlData = MdParser:MdToHtml(data, true)
            echo(data)
		    print(ChangeVersion.htmlData)
            if page then
                page:Refresh(0)
            end
        end
	end)
end

function ChangeVersion.OnGetUpldateLog()
    if not ChangeVersion.htmlData or ChangeVersion.htmlData == "" then
        ChangeVersion.OnGetUpldateLog2()
    else
        if page then
            page:Refresh(0)
        end
    end
end

function ChangeVersion.OnClose()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ChangeVersion.OnClickChangeNewVersion()
    ChangeVersion.ShowCheckUpdate(ChangeVersion.latest_version)
end

function ChangeVersion.OnClickChangeLog()

end

function ChangeVersion.OnClickOldVersion()
    ChangeVersion.ShowCheckUpdate(ChangeVersion.mini_version)
end

function ChangeVersion.ShowCheckUpdate(change_version)

    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Login/ClientUpdate/ChangeCheckDialog.html?version="..(change_version or ""), 
        name = "UpdatePage.ShowCheckUpdate", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 999,
        enable_esc_key = true,
        allowDrag = false,
        isTopLevel = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    }
    System.App.Commands.Call("File.MCMLWindowFrame",params)
end

function ChangeVersion.ChangeMiniVersion(version)
    if (ParaIO.DoesFileExist("version.txt")) then
        local file = ParaIO.open("version.txt", "rw");
        if (file:IsValid()) then
            local text = file:GetText();
            local ver = string.gsub(text, "^ver=","") or "";
            if ver == version then
                GameLogic.AddBBS(nil,"当前版本已经是稳定版本");
                ChangeVersion.OnClose()
                file:close(); 
                return
            else
                file:WriteString("ver=0.0.0");
                file:close(); 
            end
        end
        ChangeVersion._updater:Check(function(bNeedUpdate, latestVersion, curVersion, bAllowSkip, needAppStoreUpdate)
            if bNeedUpdate then
                local changeResult = ChangeVersion._updater:ChangeVersion(version)
                if changeResult then
                    ChangeVersion.OnClose()
                    if ChangeVersion.OnClickUpdate then
                        ChangeVersion.OnClickUpdate()
                    end
                end
            end
        end);
    end
end

function ChangeVersion.ChangeLatestVersion(version)
    if (ParaIO.DoesFileExist("version.txt")) then
        local file = ParaIO.open("version.txt", "rw");
        if (file:IsValid()) then
            local text = file:GetText();
            local ver = string.gsub(text, "^ver=","") or "";
            if ver == version then
                GameLogic.AddBBS(nil,"当前版本已经是最新版本");
                ChangeVersion.OnClose()
                file:close(); 
                return
            end
            file:close(); 
        end
    end
    if ChangeVersion.OnClickUpdate and type(ChangeVersion.OnClickUpdate) == "function" then
        ChangeVersion.OnClickUpdate()
    end
end

function ChangeVersion.ChangeVersion(version)
    if ChangeVersion.mini_version == version then
        ChangeVersion.ChangeMiniVersion(version)
        return
    end
    ChangeVersion.ChangeLatestVersion(version)
end