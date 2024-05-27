--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/ProgramChecker/ProgramCheckerData.lua");
local ProgramCheckerData = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerData")
ProgramCheckerData.Init()
]]

local ProgramCheckerData = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ProgramChecker.ProgramCheckerData")

ProgramCheckerData.ReportData = {}
function ProgramCheckerData.Init()
	ProgramCheckerData.ReportData = {}
end

function ProgramCheckerData.SetData(key, value)
	ProgramCheckerData.ReportData[key] = value
end

function ProgramCheckerData.GetData(key)
	return ProgramCheckerData.ReportData[key]
end

function ProgramCheckerData.GetTask2ItemData(key)
	local task_key = "task2_record"
	local task2_data = ProgramCheckerData.GetData(task_key) or {}

	return task2_data[key]
end

function ProgramCheckerData.SetTask2ItemData(key, value)
	local task_key = "task2_record"
	local task2_data = ProgramCheckerData.GetData(task_key) or {}
	task2_data[key] = value
	ProgramCheckerData.SetData(task_key, task2_data)
end