--[[
Title: Sound recorder
Author(s): yangguiyi
Date: 2023/9/
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeacherPPT/TeacherPPTSelectPage.lua");
local TeacherPPTSelectPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTSelectPage");
TeacherPPTSelectPage.ShowPage();
-------------------------------------------------------
]]
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local TeacherPPTSelectPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTSelectPage");

local page;
function TeacherPPTSelectPage.OnInit()
	page = document:GetPageCtrl();
end

function TeacherPPTSelectPage.ShowPage(url)
    System.os.GetUrl(url, function(err, msg, data)  
        -- print("axxxxxxxxxxxdddd", err)
        -- echo(data, true)
        if(err == 200)then
			TeacherPPTSelectPage.InitData(data)
	
			local params = {
				url = "script/apps/Aries/Creator/Game/Tasks/TeacherPPT/TeacherPPTSelectPage.html", 
				name = "TeacherPPTSelectPage.ShowPage", 
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
					x = -185,
					y = -170,
					width = 370,
					height = 320,
			};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
		
			params._page.OnClose = function()
			end
		else
			GameLogic.AddBBS(nil,"请求失败，请确认链接是否正确")
		end
    end);
end

function TeacherPPTSelectPage.IsRecordAudio()
	return settings.isRecordAudio == true;
end

function TeacherPPTSelectPage.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function TeacherPPTSelectPage.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end
function TeacherPPTSelectPage.InitData(data)
	TeacherPPTSelectPage.CourseData = data
	TeacherPPTSelectPage.CourseList = {
		-- {text="六年级上册", value=1}
	}
	for index, v in ipairs(data) do
		TeacherPPTSelectPage.CourseList[index] = {text=v.name, value=index, children = v.children}
	end

	TeacherPPTSelectPage.ClassList = {}
	TeacherPPTSelectPage.LessonList = {}

end

function TeacherPPTSelectPage.GetCourseList()
	return TeacherPPTSelectPage.CourseList
end

function TeacherPPTSelectPage.GetLessonList()
	return TeacherPPTSelectPage.LessonList
end

function TeacherPPTSelectPage.GetClassList()
	return TeacherPPTSelectPage.ClassList
end

function TeacherPPTSelectPage.OnSelectCourse(name, value)
	-- local data = TeacherPPTSelectPage.CourseData
	value = tonumber(value)
	local select_course_data = TeacherPPTSelectPage.CourseList[value]
	if not select_course_data then
		return
	end
	select_course_data.selected = true
	local data = select_course_data.children or {}
	TeacherPPTSelectPage.LessonList = {}
	TeacherPPTSelectPage.ClassList = {}
	for unit_index, unit_data in ipairs(data) do
		if unit_data.children then
			for lesson_index, lesson_data in ipairs(unit_data.children) do
				local text = string.format("%d.%d %s", unit_index, lesson_index, lesson_data.name)
				local data_index = #TeacherPPTSelectPage.LessonList + 1
				local item = {text = text, value = data_index, target_index = unit_index * 100 + lesson_index}
				TeacherPPTSelectPage.LessonList[data_index] = item
			end
		end
	end

	TeacherPPTSelectPage.RefreshPage()
end

function TeacherPPTSelectPage.OnSelectLesson(name, value)
	TeacherPPTSelectPage.ClassList = {}
	local select_course_index = page:GetValue("course_select")
	local select_course_data = TeacherPPTSelectPage.CourseList[select_course_index].children
	if not select_course_data then
		return
	end

	local data = select_course_data.children or {}
	value = tonumber(value)
	local list_item_data = TeacherPPTSelectPage.LessonList[value]
	list_item_data.selected = true
	local target_index = list_item_data.target_index

	local unit_index = math.floor(target_index/100)
	local lesson_index = target_index - unit_index*100
	local unit_data = data[unit_index]
	-- print("aaaaaaaaaxxdd", lesson_index)
	-- echo(unit_data, true)
	if not unit_data then
		return
	end

	local lesson_data = unit_data.children[lesson_index]

	if not lesson_data or not lesson_data.children then
		TeacherPPTSelectPage.RefreshPage()
		return
	end

	for i, v in ipairs(lesson_data.children) do
		local item = {text = v.name, value = i, target_data = v}
		TeacherPPTSelectPage.ClassList[#TeacherPPTSelectPage.ClassList + 1] = item
	end

	TeacherPPTSelectPage.RefreshPage()
end

function TeacherPPTSelectPage.OnSelectClass(name, value)
end

function TeacherPPTSelectPage.OnImport()
	local parentDir = GameLogic.GetWorldDirectory();
	local course_config_file_path = parentDir .. "course_config/"

	local value = page:GetValue("course_radio")
	if not value or value == "" then
		GameLogic.AddBBS(nil,"请在左侧选择导入类型")
		return
	end

	if value == "course" then
		local name = page:GetValue("course_select")
		if not name or name == "" then
			GameLogic.AddBBS(nil,"请先选择课包")
			return
		end

		TeacherPPTSelectPage.ImportCourse()
	elseif value == "lesson" then
		local select_index = page:GetValue("lesson_select")
		if not select_index or select_index == "" then
			GameLogic.AddBBS(nil,"请先选择课程")
			return
		end
		
		TeacherPPTSelectPage.ImportLesson()
	else
		local select_index = page:GetValue("class_select")
		if not select_index or select_index == "" then
			GameLogic.AddBBS(nil,"请先选择小节")
			return
		end
		TeacherPPTSelectPage.ImportClass(select_index)
	end
end

function TeacherPPTSelectPage.OnImportFinished(fail_nums)
	if fail_nums and fail_nums > 0 then
		GameLogic.AddBBS(nil,string.format("导入完成，有%s个文件导入失败，请尝试重新导入", fail_nums))
	else
		GameLogic.AddBBS(nil,"导入完成")
	end
	
	local TeacherPPTUrlPage = commonlib.gettable("MyCompany.Aries.Game.TeacherPPT.TeacherPPTUrlPage");
	if TeacherPPTUrlPage then
		TeacherPPTUrlPage.OnSaveSetting()
	end
	
	TeacherPPTSelectPage.OnClose()
	
end

function TeacherPPTSelectPage.ImportCourse()
	local parentDir = GameLogic.GetWorldDirectory();
	local course_config_file_path = parentDir .. "course_config/"
	if not TeacherPPTSelectPage.CourseList or #TeacherPPTSelectPage.CourseList == 0 then
		return
	end
	local select_course_index = page:GetValue("course_select")
	local select_course_data = TeacherPPTSelectPage.CourseList[select_course_index].children

	ParaIO.DeleteFile(course_config_file_path)

	-- 先生成总配置
	local json_data = {}
	local all_class_nums = 0
	local import_nums = 0
	local fail_nums = 0

	for unit_index, unit_data in ipairs(select_course_data) do
		json_data[unit_index] = {name = unit_data.name, desc = unit_data.description, coverUrl = unit_data.coverUrl}
		if unit_data.children then
			local unit_json_data = {}
			for lesson_index, lesson_data in ipairs(unit_data.children) do
				unit_json_data[lesson_index] = {name = lesson_data.name, desc = lesson_data.description, coverUrl = lesson_data.coverUrl}

				-- 
				if lesson_data.children then
					local class_json_data = {}
					all_class_nums = all_class_nums + #lesson_data.children
					-- echo(lesson_data.children, true)
					for class_index, class_data in ipairs(lesson_data.children) do
						class_json_data[class_index] = {name = class_data.name, desc = class_data.description, coverUrl = class_data.coverUrl}
						
						local data = class_data.content
						if(data and data ~= "")then
							-- 转json后存储
							local json_code = commonlib.Json.Encode(data)
							local file_path = string.format("%s/%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index, string.format("class_%s.json", class_index))
							ParaIO.CreateDirectory(file_path)
							local file = ParaIO.open(file_path, "w");
							if(file) then
								file:write(json_code, #json_code);
								file:close();
							end
						else
							fail_nums = fail_nums + 1
							LOG.std(nil, "error","TeacherPlanImport", "import fail, the fail url is: " .. lesson_index .. "_" .. class_index);
						end
						import_nums = import_nums + 1
						if import_nums >= all_class_nums then
							TeacherPPTSelectPage.OnImportFinished(fail_nums)
						end
					end

					-- 转json后存储
					local json_code = commonlib.Json.Encode(class_json_data)

					local file_path = string.format("%s/%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index, "lesson_config.json")
					ParaIO.CreateDirectory(file_path)
					local file = ParaIO.open(file_path, "w");
					if(file) then
						file:write(json_code, #json_code);
						file:close();
					end
				end
			end

			-- 转json后存储
			local json_code = commonlib.Json.Encode(unit_json_data)
			local file_path = string.format("%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "unit_config.json")
			ParaIO.CreateDirectory(file_path)
			local file = ParaIO.open(file_path, "w");
			if(file) then
				file:write(json_code, #json_code);
				file:close();
			end
		end
	end

	-- 转json后存储
	local json_code = commonlib.Json.Encode(json_data)
	local file_path = string.format("%s/%s", course_config_file_path, "course_config.json")
	ParaIO.CreateDirectory(file_path)
	local file = ParaIO.open(file_path, "w");
	if(file) then
		file:write(json_code, #json_code);
		file:close();
	end
end

function TeacherPPTSelectPage.ImportLesson()
	local parentDir = GameLogic.GetWorldDirectory();
	local course_config_file_path = parentDir .. "course_config"
	local lesson_data, unit_index, lesson_index = TeacherPPTSelectPage.GetSelectLessonItemData()
	if not lesson_data then
		return
	end
	local folder_path = string.format("%s/%s/%s/", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index)
	ParaIO.DeleteFile(folder_path)
	commonlib.TimerManager.SetTimeout(function()
		local class_json_data = {}
		local all_class_nums = #lesson_data.children
		local import_nums = 0
		local fail_nums = 0
		for class_index, class_data in ipairs(lesson_data.children) do
			class_json_data[class_index] = {name = class_data.name, desc = class_data.description, coverUrl = class_data.coverUrl}
			local data = class_data.content
			if(data)then
				-- 转json后存储
				local json_code = commonlib.Json.Encode(data)
				local file_path = string.format("%s/%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index, string.format("class_%s.json", class_index))
				ParaIO.CreateDirectory(file_path)
				local file = ParaIO.open(file_path, "w");
				if(file) then
					file:write(json_code, #json_code);
					file:close();
				end

				import_nums = import_nums + 1
			else
				fail_nums = fail_nums + 1
				LOG.std(nil, "error","TeacherPlanImport", "import fail, the fail index is: " .. class_index);
			end

			if import_nums >= all_class_nums then
				TeacherPPTSelectPage.OnImportFinished(fail_nums)
			end
		end
	
		-- 转json后存储
		local json_code = commonlib.Json.Encode(class_json_data)
		local file_path = string.format("%s%s", folder_path, "lesson_config.json")
		
		ParaIO.CreateDirectory(file_path)
		local file = ParaIO.open(file_path, "w");
		if(file) then
			file:write(json_code, #json_code);
			file:close();
		end
	end, 100);
end

function TeacherPPTSelectPage.GetSelectLessonItemData()
	local select_index = page:GetValue("lesson_select")
	if not select_index or select_index == "" then
		return
	end

	if not TeacherPPTSelectPage.CourseList or #TeacherPPTSelectPage.CourseList == 0 then
		return
	end
	local select_course_index = page:GetValue("course_select")
	if not select_course_index or select_course_index == "" then
		return
	end


	local select_course_data = TeacherPPTSelectPage.CourseList[select_course_index].children

	local select_item = TeacherPPTSelectPage.LessonList[select_index]
	local target_index = select_item.target_index

	local unit_index = math.floor(target_index/100)
	local lesson_index = target_index - unit_index*100

	local unit_data = select_course_data[unit_index]
	if not unit_data then
		return
	end

	local lesson_data = unit_data.children[lesson_index]

	if not lesson_data or not lesson_data.children then
		return
	end

	return lesson_data, unit_index, lesson_index
end

function TeacherPPTSelectPage.ImportClass(class_index)
	local parentDir = GameLogic.GetWorldDirectory();
	local course_config_file_path = parentDir .. "course_config"
	local lesson_data, unit_index, lesson_index = TeacherPPTSelectPage.GetSelectLessonItemData()
	if not lesson_data then
		return
	end
	local folder_path = string.format("%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index)
	local file_path = string.format("%s/%s",folder_path, string.format("class_%s.json", class_index))
	ParaIO.DeleteFile(file_path)

	local class_data = lesson_data.children[class_index]
	local data = class_data.content
	if(data)then
		-- 转json后存储
		local json_code = commonlib.Json.Encode(data)
		local file_path = string.format("%s/%s/%s/%s", course_config_file_path, "unit_" .. unit_index, "lesson_" .. lesson_index, string.format("class_%s.json", class_index))
		ParaIO.CreateDirectory(file_path)
		local file = ParaIO.open(file_path, "w");
		if(file) then
			file:write(json_code, #json_code);
			file:close();
		end

		TeacherPPTSelectPage.OnImportFinished()
	end
end