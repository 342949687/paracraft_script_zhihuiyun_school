--[[
Title: MicroPython
Author(s): LiXizhi
Date: 2023/7/31
Desc: language configuration file for MicroPython. see also: https://online.mpython.cn/
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/MicroPython/MicroPython.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local MicroPython = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.MicroPython", MicroPython);

-- disable auto create movie entity
MicroPython.isAutoCreateMovieEntity = false

local all_cmds = {}
local cmdsMap = {};
local default_categories = {
	{name = "display", text = L"显示", colour="#cccc00", },
	{name = "input", text = L"输入", colour="#6666ff", },
	{name = "output", text = L"输出", colour="#cc8000", },
	-- {name = "wifi", text = L"通讯", colour="#11dd11", },
	{name = "wifi", text = L"通讯", colour="#13b013", },
	{name = "message", text = L"广播", colour="#ff3333", },

	{name = "Control", text = L"控制", colour="#d83b01", },
	{name = "Operators", text = L"运算", colour="#569138", },
	{name = "Data", text = L"数据", colour="#459197", },
};

local is_installed = false;
function MicroPython.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./MicroPython_Main.lua"),
		NPL.load("./MicroPython_Input.lua"),
		NPL.load("./MicroPython_Output.lua"),
		NPL.load("./MicroPython_Wifi.lua"),
		NPL.load("./MicroPython_Control.lua"),
		NPL.load("./MicroPython_Data.lua"),
		NPL.load("./MicroPython_Operators.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		MicroPython.AppendDefinitions(v);
	end
end

function MicroPython.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			cmdsMap[v.type] = v;
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function MicroPython.GetCategoryButtons()
	return default_categories;
end

function MicroPython.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/micropython", "", "", 1);
end

-- public:
function MicroPython.GetAllCmds()
	MicroPython.AppendAll();
	return all_cmds;
end

function MicroPython.EditorChangeCodeEntity(entity)
	SerialPortConnector.Show();
	if(entity) then
		SerialPortConnector.SetCurrentPortByName(entity:GetDisplayName())
	end
end

function MicroPython.OnOpenCodeEditor(entity)
	SerialPortConnector.Show();
	if(entity) then
		SerialPortConnector.SetCurrentPortByName(entity:GetDisplayName())
	end
end

-- custom compiler here: 
-- @param codeblock: code block object here
-- @return code_func, errormsg
function MicroPython.CompileCode(code, filename, codeblock)
	local name = codeblock:GetEntity():GetDisplayName();
	if(SerialPortConnector.IsConnected()) then
		local block_name = codeblock:GetBlockName();

		if(not CodeBlockWindow.IsVisible()) then
			SerialPortConnector.SetCurrentPortByName(codeblock:GetEntity():GetDisplayName())
		end

		-- 上报
		local pos_x,pos_y,pos_z = codeblock:GetBlockPos()
		GameLogic.GetFilters():apply_filters("zhihuiyun.school.record_log", {key="micropython_code_run_info", value={code_pos=string.format("%d,%d,%d", pos_x, pos_y, pos_z), time = os.date("%H:%M:%S", os.time())}})

		code = MicroPython.GetCode(code, block_name, SerialPortConnector.GetCurrentPortName());
		local compiler = CodeCompiler:new():SetFilename(filename)
		compiler:SetAllowFastMode(true);
		return compiler:Compile(code);
	else
		SerialPortConnector.Show();

		-- tricky: if the code block's display name is not empty, we will try and wait for available virtual port
		
		if(SerialPortConnector.SetCurrentPortByName(name)) then
			if(SerialPortConnector.IsConnected()) then
				return MicroPython.CompileCode(code, filename, codeblock)
			end
		end

		if(name and name ~= "" and codeblock:GetEntity():IsPowered()) then
			if(not SerialPortConnector.HasVirtualPort(name)) then
				commonlib.TimerManager.SetTimeout(function()  
					if(SerialPortConnector.HasVirtualPort(name)) then
						local entity = codeblock:GetEntity()
						if(entity and entity:IsPowered()) then
							entity:Restart();
						end
					end
				end, 300)
			end
		else
			return nil, L"连接硬件后，请点击上方的'连接设备'"
		end
	end
end

function MicroPython:OnReceiveLog(text)
	-- log(text);
	GameLogic.GetCodeGlobal():logAdded(text);
	GameLogic.AppendChat(text);
end

--@param excludeNameMap: map of names to exclude. this can be nil.
function MicroPython:GetGlobalVarsDefString(block, excludeNameMap)
	local global_vars = ""
	local variables = block:GetBlockly():GetAllVariables()
	if(variables and #variables > 0) then
		local vars = {}
		for i, var in ipairs(variables) do
			if(not excludeNameMap or not excludeNameMap[var]) then
				var = commonlib.Encoding.toValidParamName(var)
				if(var and var:match("^[_a-zA-Z]")) then
					vars[#vars + 1] = var
				end
			end
		end
		if(#vars > 0) then
			local block_indent = (block:GetIndent() or "").. block:GetBlockly().Const.Indent;
			global_vars = block_indent.."global "..table.concat(vars, ",").."\n";
		end
	end
	return global_vars
end

-- @param code: text of code string
function MicroPython.GetCode(code, filename, preferredPortName)
	local text = string.format('NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");SerialPortConnector.SetRunMicroPythonMainCode([[%s]], %q, %q)', code, filename, preferredPortName or "")
	return text;
end
