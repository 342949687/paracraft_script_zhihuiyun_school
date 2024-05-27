--[[
Title: Sound recorder
Author(s): LiXizhi
Date: 2021/10/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeacherPPT/TeacherPPTUrlPage.lua");
local TeacherPPTUrlPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTUrlPage");
TeacherPPTUrlPage.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeacherPPT/TeacherPPTSelectPage.lua");

local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local TeacherPPTUrlPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTUrlPage");

-- [0.1, 1]: 0.1 is lowest recording quality with smallest file size
TeacherPPTUrlPage.recordSoundQuality = 0.1
TeacherPPTUrlPage.startRecordTime = 0;
TeacherPPTUrlPage.recordedDuration = 0;

local page;
function TeacherPPTUrlPage.OnInit()
	page = document:GetPageCtrl();
end

function TeacherPPTUrlPage.ShowPage()

	TeacherPPTUrlPage.InitData()
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeacherPPT/TeacherPPTUrlPage.html", 
		name = "TeacherPPTUrlPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -170,
			width = 400,
			height = 320,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
	end

	local course_url = TeacherPPTUrlPage.SettingData.course_url
	if course_url and course_url ~= "" then
		params._page:SetValue("url_input", course_url)
	end

	params._page:SetValue("PaintCheckBox", TeacherPPTUrlPage.SettingData.is_use_paint)
	params._page:SetValue("MindCheckBox", TeacherPPTUrlPage.SettingData.is_use_mind)
end

function TeacherPPTUrlPage.IsRecordAudio()
	return settings.isRecordAudio == true;
end

function TeacherPPTUrlPage.InitData()
	local parentDir = GameLogic.GetWorldDirectory();
	TeacherPPTUrlPage.SettingFilePath = parentDir .. "ppt_setting.json"
	TeacherPPTUrlPage.SettingData = {}
    if ParaIO.DoesFileExist(TeacherPPTUrlPage.SettingFilePath, true) then
        local file = ParaIO.open(TeacherPPTUrlPage.SettingFilePath, "r");
        local json_code = ""
        if(file:IsValid()) then
            json_code = file:GetText();
            file:close();
        end

        TeacherPPTUrlPage.SettingData = commonlib.Json.Decode(json_code)
    end
end

function TeacherPPTUrlPage.OnClose()
	if(page) then
		page:CloseWindow();
	end

	
end

function TeacherPPTUrlPage.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function TeacherPPTUrlPage.OnclickImport()
	local url = page:GetValue("url_input")
	if not url or url == "" then
		GameLogic.AddBBS(nil,"请输入教案引用地址")
		return
	end

	
	local TeacherPPTSelectPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTSelectPage");
	TeacherPPTSelectPage.ShowPage(url);
end

function TeacherPPTUrlPage.OnOk()
	-- 保存数据
	TeacherPPTUrlPage.OnSaveSetting()

	TeacherPPTUrlPage.OnClose()
	GameLogic.GetCodeGlobal():BroadcastTextEvent("ReOpenMainPage");
end

function TeacherPPTUrlPage.OnSaveSetting()
	if not page then
		return
	end

	-- 保存数据
	TeacherPPTUrlPage.SettingData = TeacherPPTUrlPage.SettingData or {}
	TeacherPPTUrlPage.SettingData.course_url = page:GetValue("url_input")
	TeacherPPTUrlPage.SettingData.is_use_paint = page:GetValue("PaintCheckBox")
	TeacherPPTUrlPage.SettingData.is_use_mind = page:GetValue("MindCheckBox")
	local data = {}
	local json_code = commonlib.Json.Encode(TeacherPPTUrlPage.SettingData)
	local file_path = TeacherPPTUrlPage.SettingFilePath
	ParaIO.CreateDirectory(file_path)
	local file = ParaIO.open(file_path, "w");
	if(file) then
		file:write(json_code, #json_code);
		file:close();
	end
end