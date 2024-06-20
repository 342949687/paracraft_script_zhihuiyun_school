--[[
Title: dump command
Author(s): LiXizhi
Date: 2015/1/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDump.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["dump"] = {
	name="dump", 
	quick_ref="/dump [scene|gui|asset|all|view|player|codeblock]", 
	desc=[[dump information to log.txt file
/dump codeblock   dump all codeblocks text to a single file and open it. 
/dump scene
/dump asset
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name, bIsShow;
		name, cmd_text = CmdParser.ParseString(cmd_text);

		local att;
		if(not name or name == "all") then
			att = ParaEngine.GetAttributeObject();
		elseif(name == "scene") then
			att = ParaScene.GetAttributeObject();
		elseif(name == "gui") then
			att = ParaEngine.GetAttributeObject():GetChild("GUI");
		elseif(name == "asset") then	
			att = ParaEngine.GetAttributeObject():GetChild("AssetManager");
		elseif(name == "view") then
			att = ParaEngine.GetAttributeObject():GetChild("ViewportManager");
		elseif(name == "player") then
			att = ParaScene.GetPlayer():GetAttributeObject();
		elseif(name == "codeblock") then
			if(GameLogic.IsReadOnly()) then
				GameLogic.AddBBS(nil, L"只读世界不能导出代码", 3000, "255 0 0");
				return
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockFileSync.lua");
			local CodeBlockFileSync = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockFileSync");
			CodeBlockFileSync:AutoDumpAllCodeBlocks(true)
		end
		if(att) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AttributeModel.lua");
			local AttributeModel = commonlib.gettable("MyCompany.Aries.Game.Common.AttributeModel");
			local attrModel = AttributeModel:new():init(att);
			attrModel:dump();
		end
	end,
};