--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginPage.lua");
local ZhiHuiYunLoginPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.Login.ZhiHuiYunLoginPage")
ZhiHuiYunLoginPage.Show()
]]

local ZhiHuiYunLoginPage = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.Login.ZhiHuiYunLoginPage")
-- local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
local ZhiHuiYun = commonlib.gettable("MyCompany.Aries.Game.GameLogic.ZhiHuiYun")
local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")

ZhiHuiYunLoginPage.ModButtonList = {
    {text="忘记密码?",node_name = "zhihuiyun_login_mod_button_1", iframe_url="script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginForgetPasswordPage.html"},
    {text="咨询建议",node_name = "zhihuiyun_login_mod_button_2", iframe_url="script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginServicePage.html"},
    {text="账号服务",node_name = "zhihuiyun_login_mod_button_3", iframe_url="script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginPasswordPage.html"},
}

ZhiHuiYunLoginPage.ModList = {
    account = 0,            --登录
    forget_password = 1,    --忘记密码
    service = 2,            --客服
    password = 3,           --修改密码
}

ZhiHuiYunLoginPage.CurSelectMod = ZhiHuiYunLoginPage.ModList.account

local page
local ModPageCtrl
function ZhiHuiYunLoginPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = ZhiHuiYunLoginPage.OnCreate
	page.OnClose = ZhiHuiYunLoginPage.OnClose
end

function ZhiHuiYunLoginPage.OnInitModPage(mod_page)
    ModPageCtrl = mod_page
end

function ZhiHuiYunLoginPage.OnCreate()
    -- 登录界面处理
    for index = 1, #ZhiHuiYunLoginPage.ModButtonList do
        local data = ZhiHuiYunLoginPage.ModButtonList[index]
        local button_obj = ParaUI.GetUIObject(data.node_name)
        if index == ZhiHuiYunLoginPage.CurSelectMod then
            button_obj.text = "返回登录"
            _guihelper.SetFontColor(button_obj, "#509ad9")
            
        else
            button_obj.text = data.text
            _guihelper.SetFontColor(button_obj, "#000000")
        end
    end

    -- 找回密码界面处理
    if ModPageCtrl then
        local forget_password_input_container = ModPageCtrl:FindUIControl("forget_password_input_container")
        local forget_password_desc_container = ModPageCtrl:FindUIControl("forget_password_desc_container")
    -- print("bbbbbbbbbbbxxxx", forget_password_input_container)
        if forget_password_input_container and forget_password_desc_container then
            forget_password_desc_container.visible = ZhiHuiYunLoginPage.SendForgetPasswordFlag == true
            forget_password_input_container.visible = not forget_password_desc_container.visible
        end
    end

    -- 修改密码界面处理
    if ModPageCtrl then
        local password_login_container = ModPageCtrl:FindUIControl("password_login_container")
        local password_modified_container = ModPageCtrl:FindUIControl("password_modified_container")
        if password_login_container and password_modified_container then
            password_modified_container.visible = ZhiHuiYun:IsLogin()
            password_login_container.visible = not password_modified_container.visible
        end
    end
end

function ZhiHuiYunLoginPage.OnClose()
    -- body
end

function ZhiHuiYunLoginPage.Close()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function ZhiHuiYunLoginPage.Show()
	local params = {
		url = "script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginPage.html", 
		name = "ZhiHuiYunLoginPage.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		zorder = -2,
		bShow = bShow,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		cancelShowAnimation = true,
		enable_esc_key = false
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ZhiHuiYunLoginPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

-------------------------------------------------------------------通用部分-----------------------------------------------------------------

function ZhiHuiYunLoginPage.OnClickSelectModButton(name,mcmlNode)
    local mod_index = tonumber(mcmlNode:GetAttribute("param1"))
    if mod_index == ZhiHuiYunLoginPage.CurSelectMod then
        ZhiHuiYunLoginPage.CurSelectMod = ZhiHuiYunLoginPage.ModList.account
    else
        ZhiHuiYunLoginPage.CurSelectMod = mod_index
    end

    ZhiHuiYunLoginPage.RefreshPage()
end

function ZhiHuiYunLoginPage.GetModButtonList()
    return ZhiHuiYunLoginPage.ModButtonList
end

function ZhiHuiYunLoginPage.GetModIframe()
    local select_data = ZhiHuiYunLoginPage.ModButtonList[ZhiHuiYunLoginPage.CurSelectMod]
    if select_data then
        return select_data.iframe_url
    end

    return "script/apps/Aries/Creator/Game/ZhiHuiYun/Login/ZhiHuiYunLoginAccountPage.html"
end

-------------------------------------------------------------------通用部分/end-----------------------------------------------------------------

-------------------------------------------------------------------账号登录部分-----------------------------------------------------------------
function ZhiHuiYunLoginPage.OnZhiHuiYunLogin()
    local page = ModPageCtrl
    local account = page:GetUIValue("account_input")
    local password = page:GetUIValue("password_input")
    local login_data = {username = account, password = password}
    local use_tip = false
    if ZhiHuiYun:IsLogin() then
        ZhiHuiYunHttpApi.LoginOut(ZhiHuiYunLoginPage.OnZhiHuiYunLogin)
    end

    ZhiHuiYun:Login(function(err, msg, data)
        if err ~= 200 then
            if data.message then
                page:SetUIValue('error_code', data.message)
            end
           
            return
        end

        -- if not System.User.zhy_userdata then
        --     ZhiHuiYun:ForceExit()
        --     return
        -- end

        if not System.options.isZhihuiyunDebug and System.User.zhy_userdata.channel ~= ZhiHuiYun.ServerChannelType.CLIENT then
            _guihelper.MessageBox("身份不正确", function()
                ZhiHuiYun:ForceExit()
            end, _guihelper.MessageBoxButtons.OK)
            return
        end
        
        ZhiHuiYunLoginPage.Close()
        GameLogic.RunCommand(format('/loadworld -s -force %s', System.options.AutoEnterPid))
    end, login_data, use_tip)
end

-- 帕拉卡登录遇到的错误提示
function ZhiHuiYunLoginPage.OnParaLoginError(response, err)
    local page = ModPageCtrl
    if response and type(response) ~= "table" then
        _guihelper.MessageBox(string.format(L'服务器数据错误(%d/%s)', err or 0, tostring(response)))
        return
    end
    if response and response.code and response.message then
        if response.code == 77 then
            _guihelper.MessageBox(string.format(L'*%s(%d)', response.message, response.code))
        end

        page:SetUIValue('error_code', string.format(L'*%s(%d)', response.message, response.code))
    else
        if err == 0 then
            page:SetUIValue('error_code', string.format(L'*网络异常或超时，请检查网络(%d)', err))
        else
            page:SetUIValue('error_code', string.format(L'*系统维护中(%d)', err))
        end
    end
end

function ZhiHuiYunLoginPage.Login()
    local page = ModPageCtrl
    

    local account = page:GetUIValue("account_input")
    local password = page:GetUIValue("password_input")
    if account == "" then
        page:SetUIValue('error_code', "用户名不能为空")
        return
    end

    if password == "" then
        page:SetUIValue('error_code', "密码不能为空")
        return
    end

    -- 课程相关
    if System.options.ZhyChannel == "zhy_competition_course" then
        ZhiHuiYunLoginPage.OnZhiHuiYunLogin()
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', 24000, L'链接超时', 320, 120, nil, nil, nil, true)
    local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

    -- print("axxxxxxdd", account, password)
    KeepworkServiceSession:Login(
        account,
        password,
        function(response, err)
            -- print("ccccccccccccxxx", err, account, account =="")
            -- echo(response, true)
            if err ~= 200 or not response or type(response) ~= "table" then
                Mod.WorldShare.MsgBox:Close()
                ZhiHuiYunLoginPage.OnParaLoginError(response, err)
                return false
            end

            -- response.autoLogin = autoLogin
            response.rememberMe = false
            response.password = password

            local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
            if System.options.ZhyChannel ~= "" then
                -- 不加这个不会缓存密码。。。
                response.rememberMe = true
            end
            KeepworkServiceSession:SaveSigninInfo(
                {
                    account = account,
                    loginServer = KeepworkService:GetEnv(),
                    remember_pwd = ''
                }
            )

            KeepworkServiceSession:LoginResponse(response, err, function(bSucceed, message)
                Mod.WorldShare.MsgBox:Close()
                if not bSucceed then
                    page:SetUIValue('error_code', format(L'*%s', message))
                    return
                end
        
                ZhiHuiYunLoginPage.Next()
                local AfterLogined = Mod.WorldShare.Store:Get('user/AfterLogined')
                if type(AfterLogined) == 'function' then
                    AfterLogined(true)
                    Mod.WorldShare.Store:Remove('user/AfterLogined')
                end
            end)
        end
    )
end

function ZhiHuiYunLoginPage.ExecuteCmdLineCmd()
    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

    if System.options.cmdline_cmd then
        local cmd = System.options.cmdline_cmd or '';
        CommandManager:RunCommand(cmd);
        System.options.cmdline_cmd = nil;

        return true;
    end

    return false;
end

function ZhiHuiYunLoginPage.ExecuteCmdLineCmd()
    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

    if System.options.cmdline_cmd then
        local cmd = System.options.cmdline_cmd or '';
        CommandManager:RunCommand(cmd);
        System.options.cmdline_cmd = nil;

        return true;
    end

    return false;
end

function ZhiHuiYunLoginPage.Next(isLocal)
    if isLocal == true then
        System.options.loginmode = 'local'
    else
        System.options.loginmode = nil
    end

    if System.options.cmdline_world and System.options.cmdline_world ~= '' then
        ZhiHuiYunLoginPage.Close()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua")
        local GameMainLogin = commonlib.gettable('MyCompany.Aries.Game.MainLogin')
        GameMainLogin:CheckLoadWorldFromCmdLine()
        
        return
    end

    if (ZhiHuiYunLoginPage.ExecuteCmdLineCmd()) then 
        return 
    end 

    if System.options.loginmode == 'local' then
        -- OfflineAccountManager:ShowActivationPage()
    else
        ZhiHuiYunLoginPage.Close()
        RedSummerCampMainPage.Show()
    end
    ZhiHuiYunLoginPage.JudgeTokenEnough()
end

function ZhiHuiYunLoginPage.JudgeTokenEnough()
    local platform = System.os.GetPlatform();
    local isTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil);

    if not (platform == 'android' or platform == 'ios' or (isTouchDevice and isTouchDevice =='true'))then
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
        KeepworkServiceSession:JudgeTokenEnough()
    end
end

function ZhiHuiYunLoginPage.ChangePasswordShow()
    local zhihuiyun_password_input = ParaUI.GetUIObject("zhihuiyun_password_input")
    zhihuiyun_password_input.PasswordChar = zhihuiyun_password_input.PasswordChar == "*" and "" or "*"

    local zhihuiyun_password_eye = ParaUI.GetUIObject("zhihuiyun_password_eye")
    local texture_eye_on = "Texture/ZhiHuiYun/Login/on_29x17_32bits.png;0 0 29 17"
    local texture_eye_off = "Texture/ZhiHuiYun/Login/off_29x11_32bits.png;0 0 29 17"
    zhihuiyun_password_eye.background = zhihuiyun_password_input.PasswordChar == "*" and texture_eye_off or texture_eye_on
end
-------------------------------------------------------------------账号登录部分/end-----------------------------------------------------------------

-------------------------------------------------------------------找回密码-----------------------------------------------------------------
function ZhiHuiYunLoginPage.SendForgetPassword()
    local page = ModPageCtrl
    local account = page:GetUIValue("account_input")
    local phone_number = page:GetUIValue("phone_input")

    if account == "" then
        page:SetUIValue('error_code', "用户名不能为空")
        return
    end

    if phone_number == "" then
        page:SetUIValue('error_code', "手机号码不能为空")
        return
    end

    local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')
    if not Validated:Phone(phone_number) then
        page:SetUIValue('error_code', "手机号码格式错误")
        return
    end
    
    ZhiHuiYunHttpApi.FindPassword(account, phone_number, function(err, msg, data)
        if err ~= 200 then
            if data and data.message then
                page:SetUIValue('error_code', data.message)
            else
                page:SetUIValue('error_code', "账号不存在，请确认账号输入无误")
            end

            return
        end

        ZhiHuiYunLoginPage.SendForgetPasswordFlag = true
        ZhiHuiYunLoginPage.RefreshPage()
    end)

end


-------------------------------------------------------------------找回密码/end-----------------------------------------------------------------

-------------------------------------------------------------------修改密码-----------------------------------------------------------------
function ZhiHuiYunLoginPage.OnClickPasswordPageSureButton()
    -- 先登录 然后切修改密码
    local page = ModPageCtrl
    
    local account = page:GetUIValue("account_input")
    local password = page:GetUIValue("password_input_changepassword1")
    if account == "" then
        page:SetUIValue('error_code', "用户名不能为空")
        return
    end

    if password == "" then
        page:SetUIValue('error_code', "密码不能为空")
        return
    end

    local login_data = {username = account, password = password}
    local use_tip = false
    ZhiHuiYun:Login(function(err, msg, data)
        if err ~= 200 then
            if data and data.message then
                page:SetUIValue('error_code', data.message)
            end
           
            return
        end

        ZhiHuiYunLoginPage.temp_password = password
        ZhiHuiYunLoginPage.RefreshPage()
    end, login_data, use_tip)
end

-- 输入新密码界面下的确定按钮
function ZhiHuiYunLoginPage.OnClickPasswordModifiedSureButton()
    local page = ModPageCtrl

    local password = page:GetUIValue("password_modified_input")
    local password_again = page:GetUIValue("password_modified_input_again")
    if password == "" then
        page:SetUIValue('error_code2', "密码不能为空")
        return
    end

    if #password < 6 then
        page:SetUIValue('error_code2', "密码长度不少于6位")
        return
    end


    if password_again ~= password then
        page:SetUIValue('error_code2', "两次密码不一致")
        return
    end

    if not ZhiHuiYunLoginPage.temp_password then
        page:SetUIValue('error_code2', "请先登录")
        return
    end

    if ZhiHuiYunLoginPage.temp_password == password then
        page:SetUIValue('error_code2', "与旧密码一致，不需要修改")
        return
    end


    ZhiHuiYunHttpApi.ResetPassword(ZhiHuiYunLoginPage.temp_password, password, function(err, msg, data)
        if err ~= 200 then
            page:SetUIValue('error_code2', "修改密码失败")
            return
        end

        ZhiHuiYunHttpApi.LoginOut(function()
            ZhiHuiYunLoginPage.temp_password = nil
            GameLogic.AddBBS(nil, "修改密码成功,请重新登录", 3000, '0 255 0')
            ZhiHuiYunLoginPage.CurSelectMod = ZhiHuiYunLoginPage.ModList.account
            ZhiHuiYunLoginPage.RefreshPage()
        end)

        -- page:SetUIValue('error_code', "修改密码成功")
    end)
end
-------------------------------------------------------------------修改密码/end-----------------------------------------------------------------