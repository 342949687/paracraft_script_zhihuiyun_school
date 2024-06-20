--[[
Title: MicroPython
Author(s): LiXizhi
Date: 2023/7/31
Desc: language configuration file for MicroPython. see also: https://online.mpython.cn/
use the lib:
-------------------------------------------------------
local MicroPython = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/MicroPython/MicroPython.lua");
MicroPython.InstallEsp32Firmware("temp/esp32_firmware.bin");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local MicroPython = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.MicroPython", MicroPython);

-- disable auto create movie entity
MicroPython.isAutoCreateMovieEntity = false
-- TODO: a better way would be using js or npl like in https://github.com/espressif/esptool-js
MicroPython.source_url = "https://cdn.keepwork.com/paracraft/esp32/esptool.exe";
MicroPython.web_esp32_install_url = "https://webparacraft.keepwork.com/esptool/";
MicroPython.defaultEspToolPath = "plugins/esptool_v1.exe";
MicroPython.firmware_url = "https://cdn.keepwork.com/paracraft/esp32/mpython.bin"
MicroPython.defaultFirmwarePath = "temp/esp32firmware/mpython.bin";
MicroPython.cache_policy = "access plus 1 year";

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

function MicroPython:GetFileExtension()
	return "py"
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

function MicroPython.GetCustomToolbarMCML()
	MicroPython.toolBarMcmlText = MicroPython.toolBarMcmlText or string.format([[
<div style="float:left;margin-left:5px;margin-top:7px;">
	<input type="button" value='%s' name='ConfigWithMicroPython' onclick="MyCompany.Aries.Game.Code.MicroPython.ConfigWithMicroPython" style="margin-top:0px;margin-left:5px;background:url(Texture/whitedot.png);background-color:#808080;color:#ffffff;height:25px;min-width:20px;" />
</div>
]], L"硬件");
	return MicroPython.toolBarMcmlText;
end

function MicroPython.ConfigWithMicroPython()
	-- show context menu 
	if(not MicroPython.menuCtrl) then
		MicroPython.menuCtrl = CommonCtrl.ContextMenu:new{
			name = "MicroPython.ConfigWithMicroPython",
			width = 200,
			height = 200,
			DefaultNodeHeight = 26,
			-- style = CommonCtrl.ContextMenu.DefaultStyle,
		}
		local groupNode = CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 };
		MicroPython.menuCtrl.RootNode:AddChild(groupNode);
		groupNode:AddChild(CommonCtrl.TreeNode:new({Text = L"清除程序", Type = "Menuitem", uiname="ConfigWithMicroPython.clearCode", Name = "clearCode", onclick = function()
			SerialPortConnector.SetRunMicroPythonMainCode('')
		end}));
		groupNode:AddChild(CommonCtrl.TreeNode:new({Text = L"固件烧录...", Type = "Menuitem", uiname="ConfigWithMicroPython.micropythonWriteFireware", Name = "micropythonWriteFireware", onclick = function()
			MicroPython.OpenWriteFirmwareDialog(true)
		end}));
		groupNode:AddChild(CommonCtrl.TreeNode:new({Text = L"安装串口驱动...", Type = "Menuitem", uiname="ConfigWithMicroPython.InstallDriver", Name = "InstallDriver", onclick = function()
			SerialPortConnector.InstallDriver()
		end}));
	end
	local x, y, width, height = _guihelper.GetLastUIObjectPos();
	if(x and y)then
		MicroPython.menuCtrl:Show(x, y + height)
	end
end

function MicroPython.OpenWriteFirmwareDialog(bDownloadDefault)
	if (System.os.GetPlatform() == "mac") then
		GameLogic.RunCommand('/open -e '..MicroPython.web_esp32_install_url);
		return;
	elseif (System.os.GetPlatform() ~= "win32") then
		ParaGlobal.ShellExecute("open", MicroPython.web_esp32_install_url, "", "", 1);
		return;
	end

	local destFileName = ParaIO.GetWritablePath()..MicroPython.defaultFirmwarePath;
	if(not bDownloadDefault or ParaIO.DoesFileExist(destFileName) or MicroPython.is_loading) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");

		local searchPath = MicroPython.defaultFirmwarePath:gsub("[^/\\]+$", "");
		local relativePath = searchPath;
		searchPath = ParaIO.GetWritablePath()..searchPath;
		ParaIO.CreateDirectory(searchPath);

		OpenFileDialog.ShowPage(L"刷入：选择一个固件文件(*.bin)"..format("<a style='color:#6666ff' href='%s'>%s</a>", MicroPython.web_esp32_install_url, L"用网页安装"), function(result)
			local filename = result;
			if(filename) then
				if(not filename:match("[/\\]")) then
					filename = relativePath..filename;
				end
				MicroPython.InstallEsp32Firmware(filename)
			end
		end, nil, L"固件烧录", {{L"固件文件(*.bin)",  "*.bin", searchPath = searchPath,},})	
	elseif(bDownloadDefault) then
		MicroPython.is_loading = true;
		MicroPython.loader = MicroPython.loader or FileDownloader:new();
		MicroPython.loader:SetSilent();
		GameLogic.AddBBS(nil, L"正在下载默认固件，请稍等", 3000, "255 0 0");
		ParaIO.CreateDirectory(destFileName);
		MicroPython.loader:Init(nil, MicroPython.firmware_url, destFileName, function(b, msg)
			MicroPython.is_loading = false;
			MicroPython.loader:Flush();
			GameLogic.AddBBS(nil, L"下载完成", 3000, "0 255 0");
			MicroPython.OpenWriteFirmwareDialog()
		end, MicroPython.cache_policy);
	end
end

function MicroPython.GetEspToolPath()
	MicroPython.esp_tool_path = MicroPython.esp_tool_path or string.format("%s%s", ParaIO.GetWritablePath(), MicroPython.defaultEspToolPath)
	return MicroPython.esp_tool_path;
end

-- @param isAutoInstall: false to disable, otherwise it will auto install if not found.
function MicroPython.FetchValidEspToolPath(callbackFunc, isAutoInstall)
	MicroPython.callbackFunc = callbackFunc;
	if(MicroPython.is_loading)then
		return
	end
	if(MicroPython.exe_full_path)then
        if(not ParaIO.DoesFileExist(MicroPython.exe_full_path))then
            MicroPython.exe_full_path = nil
        else
			if(MicroPython.callbackFunc) then
				MicroPython.callbackFunc(MicroPython.exe_full_path)
			end
            return 
		end
    end
	local filepath = MicroPython.GetEspToolPath();
    LOG.std(nil, "info", "MicroPython", "run: %s", filepath);
    if(not ParaIO.DoesFileExist(filepath))then
		LOG.std(nil, "info", "MicroPython", "file not installed: %s", filepath);
		if(isAutoInstall~=false) then
			MicroPython.OnStartDownload(callbackFunc);
		end
        return 
	end
    MicroPython.exe_full_path = filepath;
    if(MicroPython.callbackFunc) then
		MicroPython.callbackFunc(MicroPython.exe_full_path)
	end
end

function MicroPython.OnStartDownload(callbackFunc)
	if(MicroPython.is_loading)then
		return 
	end
	MicroPython.is_loading = true;
	GameLogic.AddBBS(nil, L"正在下载Esptool，请稍等", 3000, "255 0 0");
	MicroPython.loader = MicroPython.loader or FileDownloader:new();
	MicroPython.loader:SetSilent();

	local destFileName = MicroPython.GetEspToolPath();
	ParaIO.CreateDirectory(destFileName);
	MicroPython.loader:Init(nil, MicroPython.source_url, destFileName, function(b, msg)
		MicroPython.is_loading = false;
		MicroPython.loader:Flush();
		GameLogic.AddBBS(nil, L"下载完成", 3000, "0 255 0");
		if(b)then
			if(callbackFunc) then
				callbackFunc(destFileName);
			end
		else
			GameLogic.AddBBS(nil, L"下载失败"..": esptool.exe", 3000, "255 0 0");
		end
	end, MicroPython.cache_policy);
end

function MicroPython.InstallEsp32Firmware(filename)
	if (System.os.GetPlatform() == "win32") then
		SerialPortConnector.Show();
		if (SerialPortConnector.IsConnected()) then
			local port = SerialPortConnector.GetCurrentPort();
			if (port) then
				local portName = port:GetFilename();
				MicroPython.FetchValidEspToolPath(function(esptoolPath)
					if(esptoolPath) then
						if(filename:match("^https?://$")) then
							-- TODO download from url
						else
							SerialPortConnector.Disconnect();
							commonlib.TimerManager.SetTimeout(function()  
								local cmd = string.format([[
echo "building with esptool ..." >con
pushd "%s"
"%s" --chip esp32 --port %s --baud 1200000 write_flash -z 0x0000 %s >con 2>&1
popd
timeout /t 5 >nul
]], ParaIO.GetWritablePath(), esptoolPath, portName, filename);
								LOG.std(nil, "info", "MicroPython", "run: %s", cmd);
								System.os.run(cmd);	
							end, 500)
							
						end
					end
				end)
			end
		else
			GameLogic.AddBBS(nil, L"请先连接设备", 3000, "255 0 0");
			return
		end
	else
		GameLogic.AddBBS(nil, L"暂时不支持当前平台", 3000, "255 0 0");
	end
end

function MicroPython.PostProcessBlocklyCode(blockly, code)
	-- 获取所有变量
	local variables = blockly:GetAllVariables();
	if (not variables or #variables == 0) then return code end
	
	-- 转换成有效变量集
	local valid_vars = {}
	for _, var in ipairs(variables) do
		local valid_var = commonlib.Encoding.toValidParamName(var);
		if(valid_var and valid_var:match("^[_a-zA-Z]")) then
			valid_vars[#valid_vars + 1] = valid_var
		end
	end

	-- 拆分代码成行集
	local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        table.insert(lines, line);
    end

	-- 遍历行集解析函数, 为函数内首行添加全局变量定义
	local code_lines = {};
	for index, line in ipairs(lines) do
		code_lines[#code_lines + 1] = line;
		
		-- 函数定义行
		local func_name, param_names = line:match("def%s+([%_%w]+)%s*%(([^)]*)%)");
		if (func_name) then
			local next_line = lines[index + 1];
			-- 下一行没有定义global
			if (not next_line or not next_line:match("%s*global")) then
				-- 函数缩进
				local indent = string.match(line, "^(%s*)") .. blockly.Const.Indent;
				
				-- 解析函数参数
				local params_map = {};
				for param_name in param_names:gmatch("([%_%w]+)%s*,?") do
					local valid_param_name = commonlib.Encoding.toValidParamName(param_name);
					if (valid_param_name and valid_param_name:match("^[_a-zA-Z]")) then
						params_map[valid_param_name] = true;
					end
				end

				-- 变量集中排除函数参数
				local vars = {}
				for _, var in ipairs(valid_vars) do
					if(not params_map[var]) then
						vars[#vars + 1] = var;
					end
				end

				-- 添加全局变量定义行
				if(#vars > 0) then
					code_lines[#code_lines + 1] = indent .. "global " .. table.concat(vars, ",");
				end
			end			
		end
	end
	return table.concat(code_lines, "\n");
end

--[[
def func_a():
	return a

def func_b(a):
    if (b):
		return a + b

def func_c():
	def func_d():
		return d

	return c + func_d()
]]
