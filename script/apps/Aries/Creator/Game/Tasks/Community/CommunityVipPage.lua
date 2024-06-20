--[[
    author: pbb
    date: 2024-04-12
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipPage.lua")
        local CommunityVipPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityVipPage")
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityAPI.lua");
local CommunityAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityAPI");
local CommunityVipPage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityVipPage"))

NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");

CommunityVipPage.default_window_name = "NplBrowserWindow_Instance";
CommunityVipPage.default_url = "www.keepwork.com";
CommunityVipPage.browser_name = "community_nplbrowser_instance"
function CommunityVipPage:Init()
    self.curBrowserName = ""
    self.pageCtrl  = nil
    self.displayMode = nil
end

function CommunityVipPage:InitUI()
    self.pageCtrl = document:GetPageCtrl()
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function CommunityVipPage:OnWorldUnloaded()
    self.displayMode = nil
end

function CommunityVipPage:Show(name, url,callback)
    self:Init()
    url = url or self.default_url;
    name = name or self.default_window_name;

    self.name = name;
    self.url = url;
    self.withControl = false;
    self.callback = callback;
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipPage.html", 
        name = "CommunityVipPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 100,
        directPosition = true,
        click_through = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        -- DesignResolutionWidth = 1280,
        -- DesignResolutionHeight = 720,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);
    System.Windows.Screen:Connect("sizeChanged", self, self.OnResize, "UniqueConnection");
    GameLogic.GetFilters():add_filter("nplbrowser_checked", self.OnResize);
    self.params = params;

    local pageCtrl = params._page;

    if (pageCtrl) then
        self.pageCtrl = pageCtrl;

        pageCtrl.OnClose = function()
            self:SetVisible(false)
        end
    end
end

local function GetTruePixel(px)
    if (System.os.GetPlatform() == "win32" or
        System.os.GetPlatform() == "ios" or
        System.os.GetPlatform() == "mac" or
        System.os.GetPlatform() == "android") then
        local uiScales = System.Windows.Screen:GetUIScaling(true);

        if (uiScales[1] ~= 1 or uiScales[2] ~= 1) then
            px = math.floor(px * uiScales[1]);
        end

        return px;
    else
        return px;
    end
end

function CommunityVipPage:CloseWindow()
    if self.pageCtrl then
        self.pageCtrl:CloseWindow();
        self.pageCtrl = nil;
    end
end

function CommunityVipPage.OnResize()
    if (CommunityVipPage.pageCtrl) then
        if (CommunityVipPage.displayMode and
            CommunityVipPage.displayMode.callback) then
                CommunityVipPage.displayMode.callback();
            return;
        end
        BackgroundMusic:Silence()
        CommunityVipPage:SetContainerVisible(true)
        local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
        local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
        NplBrowserPlugin.ChangePosSize({
            id = CommunityVipPage.browser_name,
            x = 0,
            y = 0,
            width = screenWidth,
            height = screenHeight,
        });
    end
end

function CommunityVipPage:GotoUrl(name,url,callback)
    if self.url and self.url == url then
        self:HideBrowser(false)
        return
    end
    self.url = url;
    self:RegisterEvent();

    self:Show(name, url, callback);
    print("CommunityVipPage:GotoUrl==============", name, url)
    CommunityAPI:Init(self.browser_name);
end

function CommunityVipPage:OpenUrl(url)
    if self.pageCtrl then
        self.url = url;
        self.pageCtrl:CallMethod(self.browser_name, "Reload", self.url)
    end
end

function CommunityVipPage:GotoEmpty()
    if self.pageCtrl then
        self.pageCtrl:CallMethod(self.browser_name, "Reload", NplBrowserPlugin.about_blank_url);
    end
end

function CommunityVipPage:OpenBrowser(name,url,callback)
    if (System.options.enable_npl_brower and not NplBrowserLoaderPage.IsLoaded() and not System.os.IsWindowsXP()) then
        print("CommunityVipPage:OpenBrowser==", name, url)
		if (not CommunityVipPage.isLoading) then
			CommunityVipPage.isLoading = true;
			NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
			local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
            NplBrowserLoaderPage.Check(function(bLoaded)
				if (bLoaded) then
                    self:GotoUrl(name,url,callback)
                else
                    _guihelper.MessageBox(L"加载内置浏览器失败，请重启！");
				    CommunityVipPage.isLoading = false
				end
			end)
		else
			_guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		end

		return;
    end

    self:GotoUrl(name,url,callback)
end

function CommunityVipPage:RegisterEvent()
    if self.register then
        return
    end

    self.register = true;
    
    CommunityAPI:Connect("displayModeChanged", self, self.OnDisplayModeChange, "UniqueConnection");
    GameLogic.GetFilters():add_filter("DesktopModeChanged", function(mode)
        local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
        if not IsMobileUIEnabled then
            self:OnChangeDesktopMode(mode);
        end
        return mode
    end);
end

function CommunityVipPage:OnChangeDesktopMode(mode)
    if not self.mode or self.mode ~= "mini" or not mode or mode == "" then
        return
    end
    if mode == "movie" then
        self:HideBrowser(true);
    else
        self:HideBrowser(false);
    end
end

function CommunityVipPage:OnDisplayModeChange(mode)
    self.mode = mode
    if (mode == "mini") then
        BackgroundMusic:Recover()
        self:HideBrowser(false)
        self.displayMode = {
            mode = "mini",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
                local containerWidth = GetTruePixel(160);
                local containerHeight = GetTruePixel(90);

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = GetTruePixel(28),--screenWidth - containerWidth - GetTruePixel(20),
                    y = screenHeight - containerHeight - GetTruePixel(28),
                    width = containerWidth,
                    height = containerHeight,
                });
                self:SetContainerVisible(false)
            end
        };

        self.displayMode.callback();
    elseif (mode == "ingame") then
        BackgroundMusic:Silence()
        self:HideBrowser(false);
        self.displayMode = {
            mode = "ingame",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = 0,
                    y = 0,
                    width = screenWidth,
                    height = screenHeight,
                });
                self:SetContainerVisible(true)
            end
        };

        self.displayMode.callback();
    elseif (mode == "max") then
        BackgroundMusic:Silence()
        self:HideBrowser(false);
        self.displayMode = {
            mode = "max",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
                local containerWidth = GetTruePixel(1155);
                local containerHeight = GetTruePixel(650);

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = (screenWidth - containerWidth) / 2,
                    y = (screenHeight - containerHeight) / 2,
                    width = containerWidth,
                    height = containerHeight,
                });
                self:SetContainerVisible(false)
            end
        };

        self.displayMode.callback();
    elseif (mode == "hide") then
        BackgroundMusic:Recover()
        self.displayMode = nil;
        CommunityVipPage.OnResize();
        self:HideBrowser(true);
    elseif (mode == "show") then
        BackgroundMusic:Silence()
        self.displayMode = nil;
        CommunityVipPage.OnResize();
        self:HideBrowser(false);
    elseif(mode == "button") then
        BackgroundMusic:Recover()
        self.displayMode = nil;
        CommunityVipPage.OnResize();
        self:HideBrowser(true);
    end
end

function CommunityVipPage:SetContainerVisible(bShow)
    local container = ParaUI.GetUIObject("community_container")
    if container and container:IsValid() then
        print("container visible===============", bShow)
        -- print(commonlib.debugstack())
        container.visible = bShow == true
    end
end

function CommunityVipPage:HideBrowser(bHide)
    -- local parent = self.pageCtrl and self.pageCtrl:GetParentUIObject() or nil
    -- if parent then
    --     parent.visble = not bHide
    -- end
    -- if bHide then
    --     self.isLoading = false
    --     self:GotoEmpty()
    --     self:CloseWindow()
    --     return
    -- end
    if bHide then
        --self:GotoEmpty()
    end
    self:SetContainerVisible(not bHide)
    self:SetVisible(not bHide);
end

function CommunityVipPage:CloseBrowser()
    if (self.pageCtrl) then
        self.pageCtrl:CloseWindow();
    end

    self:SetVisible(false);
end

function CommunityVipPage:GetWebStatus()
    return self.mode or "ingame"
end

function CommunityVipPage:Goto(url)
    if(not name)then
        return
    end
    self.url = url
    self:Reload(self.url)
end

function CommunityVipPage:Reload(url)
    url = url or self.url
    print("url========",url)
    if(self.pageCtrl)then
        self.pageCtrl:CallMethod(self.browser_name, "Reload", url); 
    end
    self.url = url
end

function CommunityVipPage:SetVisible(b)
    if (self.pageCtrl) then
        self.pageCtrl:CallMethod(self.browser_name, "SetVisible", b); 
    end
end

function CommunityVipPage:Close()
	self:SetVisible(false)
    if(self.pageCtrl)then
		self.pageCtrl:CloseWindow(); 
    end
    if(self.callback)then
        self.callback();
    end
end

-- 初始化成单列模式
CommunityVipPage:InitSingleton();