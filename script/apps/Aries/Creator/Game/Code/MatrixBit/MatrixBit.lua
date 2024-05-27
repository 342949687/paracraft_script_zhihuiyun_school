--[[
Title: MatrixBit
Author(s): ygy
Date: 2023/6/26
Desc: blockly program for microbit, based on pxt-microbit api
use the lib:
-------------------------------------------------------
local MatrixBit = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/MatrixBit/MatrixBit.lua");
MatrixBit.Init()
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local MatrixBit = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.MatrixBit.MatrixBit", MatrixBit);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};

local esptool_path = ParaIO.GetWritablePath().."temp/esptool"
MatrixBit.type =  "matrixBit";
MatrixBit.categories = {
    {name = "Basic", text = L"基础", colour = "#1e90ff", },
    {name = "Input", text = L"输入", colour = "#d400d4", },
    {name = "Music", text = L"音乐", colour = "#e63022", },
    {name = "Led", text = L"发光管", colour = "#5c2d91", },
    {name = "Radio", text = L"无线", colour = "#e3008c", },
    {name = "Loops", text = L"循环", colour = "#00aa00", },
    {name = "Logic", text = L"逻辑", colour = "#00aa00", },
    {name = "Variables", text = L"变量", colour = "#dc143c", custom="VARIABLE", },
    {name = "Math", text = L"数学", colour = "#9400d3", },
    
};

MatrixBit.Com4PortInstance = nil
function MatrixBit.Init()
	if not MatrixBit.Com4PortInstance then
		MatrixBit.ConnectPort()
	end
end

local has_esptool =  ParaIO.DoesFileExist(esptool_path, true)
function MatrixBit.ConnectPort()
	if MatrixBit.Com4PortInstance then
		return
	end

	NPL.load("(gl)script/ide/System/os/SerialPort.lua");
	local SerialPort = commonlib.gettable("System.os.SerialPort");
	MatrixBit.Com4PortInstance = SerialPort:new():init("COM4")
	print(">>>>>>>>>>>>>>>>>>SerialPort:Connect")
	if(MatrixBit.Com4PortInstance:open()) then
		MatrixBit.Com4PortInstance:Connect("dataReceived", function(data)
			-- print(">>>>>>>>>>>>>>>>dataReceived")
			-- echo(data)
		end)
		MatrixBit.Com4PortInstance:Connect("lineReceived", function(line)
			print(">>>>>>>>>>>>>>>>lineReceived")
			echo("line:" .. line)
			if line == "invalid header: 0xffffffff" then
				if has_esptool then
					_guihelper.MessageBox("烧录固件中，请稍后")
					MatrixBit.DisConnectPort()
					commonlib.TimerManager.SetTimeout(function()  
						print(">>>>>>>>>>>>>>>>connect")
						-- local cmd = string.format("start %s", path)
						local esptool_path = ParaIO.GetWritablePath().."temp/esptool"
						local cmd = string.format("%s/esptool.py.exe --port COM4 --baud 1500000 write_flash --flash_size detect 0x0000 %s/mpython_firmware_v2.3.6.bin", esptool_path, esptool_path)
						os.execute(cmd)
						
						GameLogic.AddBBS(nil,">>>>>>>>>>>>>烧录固件完成")
						_guihelper.CloseMessageBox(false)
						commonlib.TimerManager.SetTimeout(function()
							MatrixBit.ConnectPort()
						end, 500)
					end, 1000)
				end
			end
		end)
	end
end

function MatrixBit.DisConnectPort()
	if MatrixBit.Com4PortInstance and MatrixBit.Com4PortInstance:isOpen() then
		MatrixBit.Com4PortInstance:close()
		MatrixBit.Com4PortInstance = nil
	end
end

function MatrixBit.EraseFlash()
	_guihelper.MessageBox("擦除固件中，请稍后")
	commonlib.TimerManager.SetTimeout(function()
		local cmd = string.format("%s/esptool.py.exe --chip esp32 --port com4 erase_flash", esptool_path)
		os.execute(cmd)
		_guihelper.CloseMessageBox(false)
	end, 500)
end

function MatrixBit.SendCmd(cmd)
	if not MatrixBit.Com4PortInstance or not MatrixBit.Com4PortInstance:isOpen() then
		return
	end
	local cmd = commonlib.serialize_compact(cmd)
	print(ParaMisc.UTF16ToUTF8(ParaMisc.UTF8ToUTF16(cmd)))
	print("qqqqqqqqqqqqqq:", cmd)
	local result = string.format("f = open(\"main.py\",\"w\")\r\nf.write(%s)\r\nf.close()\r\n\r\n", cmd)
	MatrixBit.Com4PortInstance:send(result)
end

-- make files for blockly 
function MatrixBit.MakeBlocklyFiles()
    local categories = MatrixBit.GetCategoryButtons();
    local all_cmds = MatrixBit.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_microbit",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_microbit", "", "", 1); 
end
function MatrixBit.GetCategoryButtons()
    return MatrixBit.categories;
end
function MatrixBit.AppendAll()
	-- if(is_installed)then
	-- 	return
	-- end
	-- is_installed = true;

	-- local all_source_cmds = {
	-- NPL.load("(gl)./MicrobitDef/MicrobitDef_Basic.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Input.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Music.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Led.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Radio.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Loops.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Logic.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Variables.lua");
    -- NPL.load("(gl)./MicrobitDef/MicrobitDef_Math.lua");
	-- }
	-- for k,v in ipairs(all_source_cmds) do
	-- 	MatrixBit.AppendDefinitions(v);
	-- end
end

function MatrixBit.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function MatrixBit.GetAllCmds()
	MatrixBit.AppendAll();
	return all_cmds;
end

function MatrixBit.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end