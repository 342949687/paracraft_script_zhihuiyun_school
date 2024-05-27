--[[
Title: Arduino main functions
Author(s): LiXizhi
Date: 2023/8/2
Desc: Display and more
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

NPL.export({

{
	type = "arduino.setup", 
	message0 = L"arduino启动时",
	message1 = L"%1",
	arg0 = {
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "common", 
	helpUrl = "", 
	canRun = false,
	funcName = "arduino.setup",
	previousStatement = true,
	nextStatement = true,
	func_description = 'void setup(){\\n%s\\n}',
	ToNPL = function(self)
		local input = self:getFieldAsString('input')
		return string.format('void setup(){\n%s}\n', input);
	end,
	ToArduino = function(self)
		local input = self:getFieldAsString('input')
		local block_indent = self:GetIndent()..self:GetBlockly().Const.Indent;
		return string.format('void setup(){\n%s\n%s\n}\n', block_indent, input);
	end,
	PostProcess = function(self, lines)
		-- insert headers that begins with //setup into void setup() function. 
		-- e.g. self:GetBlockly():AddUnqiueHeader("//setup Serial.begin(115200);\n");
		local nIndex = 1;
		local setupLines = {}
		local setupFunctionIndex = -1;
		local indent = self:GetBlockly().Const.Indent
		while(nIndex <= #lines) do
			local line = lines[nIndex];
			if(line and line:match("^//setup ")) then
				line = line:gsub("^//setup ", "")
				line = indent..line;
				setupLines[#setupLines + 1] = line;
				table.remove(lines, nIndex);
			else
				if(line and line:match("^void setup()")) then
					setupFunctionIndex = nIndex;
				end
				nIndex = nIndex + 1;
			end
		end
		if(#setupLines > 0) then
			if(setupFunctionIndex < 0) then
				lines[#lines + 1] = "void setup(){\n}\n"
				setupFunctionIndex = #lines;
			end
			-- insert setupLines at setupFunctionIndex to lines
			local setupFunc = lines[setupFunctionIndex] 
			local nFromPos = #("void setup(){\n")
			setupFunc = setupFunc:sub(1, nFromPos)..table.concat(setupLines)..setupFunc:sub(nFromPos, -1);
			lines[setupFunctionIndex] = setupFunc;
		end

		-- insert headers that begins with //replace fromName toName to replace delay function with the newName function. 
		-- e.g. self:GetBlockly():AddUnqiueHeader("//replace delay sleep");
		local nIndex = 1;
		while(nIndex <= #lines) do
			local line = lines[nIndex];
			if(line and line:match("^//replace ")) then
				local fromName, toName = line:match("^//replace ([%S]+)%s+([%S]+)")
				table.remove(lines, nIndex);
				local nextIndex = nIndex;
				while(nextIndex <= #lines) do
					local line = lines[nextIndex];
					if(line and line:match("%s*"..fromName.."%(")) then
						line = line:gsub("(%s*)("..fromName..")%(", "%1"..toName.."%(")
						lines[nextIndex] = line;
					end
					nextIndex = nextIndex + 1;
				end
			else
				nIndex = nIndex + 1;
			end
		end
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.loop", 
	message0 = L"主循环(永远重复)",
	message1 = L"%1",
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "common", 
	helpUrl = "", 
	canRun = false,
	funcName = "arduino.loop",
	previousStatement = true,
	nextStatement = true,
	func_description = 'void loop(){\\n%s\\n}',
	ToNPL = function(self)
		local input = self:getFieldAsString('input')
		return string.format('void loop(){\n%s}\n', input);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
	},

	
{
	type = "print", 
	message0 = L"打印%1",
	arg0 = {
		{
			name = "obj",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
	},
	category = "common", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "print",
	func_description = 'Serial.println(%s);',
	ToNPL = function(self)
		return string.format('Serial.println("%s");\n', self:getFieldAsString('obj'));
	end,
	ToArduino = function(self)
		local text = self:GetValueAsString('obj')
		self:GetBlockly():AddUnqiueHeader("//setup Serial.begin(115200);");
		return string.format('Serial.println(%s);\n', text);
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},
});