--[[
Title: JumpAppStoreDialog
Author(s): huangyz, big
CreateDate: 2022.10.20
ModifyDate: 2023.03.04
use the lib:
-------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/cellar/JumpAppStoreDialog/JumpAppStoreDialog.lua");
local JumpAppStoreDialog = commonlib.gettable("Mod.WorldShare.cellar.JumpAppStoreDialog");
-------------------------------------------------------
]]

local JumpAppStoreDialog = commonlib.gettable("Mod.WorldShare.cellar.JumpAppStoreDialog");
local page;

JumpAppStoreDialog.style = 1;
JumpAppStoreDialog.ignore = false;

function JumpAppStoreDialog:OnInit()
    page = document:GetPageCtrl();
end

function JumpAppStoreDialog.Show(latestVer,curVer,jumpUrl)
    JumpAppStoreDialog._jumpUrl = jumpUrl or "https://www.paracraft.cn/download";

    System.App.Commands.Call(
        "File.MCMLWindowFrame",
        {
            url = format("Mod/WorldShare/cellar/JumpAppStoreDialog/JumpAppStoreDialog.html?latestVersion=%s&curVersion=%s", latestVer, curVer), 
            name = "JumpAppStoreDialog", 
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 10002,
            allowDrag = false,
            isTopLevel = true,
            directPosition = true,
            align = "_ct",
            x = -210,
            y = -100,
            width = 420,
            height = 250,
        }
    );

    JumpAppStoreDialog._isDownloadFinished = false;
end

function JumpAppStoreDialog.OnClickUpdate()
    ParaGlobal.ShellExecute("openExternalBrowser", JumpAppStoreDialog._jumpUrl, "", "", 1);
end

function JumpAppStoreDialog.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function JumpAppStoreDialog.OnClickCancel()
    JumpAppStoreDialog.ClosePage()
    JumpAppStoreDialog.ignore = true;
    if (JumpAppStoreDialog.ignoreCallback and type(JumpAppStoreDialog.ignoreCallback) == "function") then
        JumpAppStoreDialog.ignoreCallback();
    end
end

return JumpAppStoreDialog;