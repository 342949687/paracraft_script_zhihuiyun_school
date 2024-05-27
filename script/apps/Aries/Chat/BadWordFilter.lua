--[[
Title: BadWordFilter
Author(s): WangTian
Date: 2009/12/5
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
BadWordFilter.FilterString(str)
------------------------------------------------------------
]]

-- create class
local libName = "AriesChatBadWordFilter";
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local string_match = string.match;
local string_gsub = string.gsub;

local badwordfiles = {
	"config/BadWords.xml",
};

local badwords = {};
local badwordsMap = {}

local badwordfromnamefiles = {
	"config/BadWords.xml",
};

local badwordsfromname = {};

local lua_symbols = {
		["^"] = true,
		["$"] = true,
		["("] = true,
		[")"] = true,
		["%"] = true,
		["."] = true,
		["["] = true,
		["]"] = true,
		["*"] = true,
		["+"] = true,
		["-"] = true,
		["?"] = true,
	};
BadWordFilter.MaxDirtyKeyLength = 1
function BadWordFilter.Init()
	if(BadWordFilter.is_inited) then
		return;
	end
	BadWordFilter.is_inited = true;

	if(System.options.mc) then
		badwordfiles = {
			"config/BadWords.Paracraft.xml",
		};
		badwordfromnamefiles = {
			"config/BadWords.Paracraft.xml",
		};
	end

	local key,line,file
	local _, path;
	for _, path in ipairs(badwordfiles) do
		file = ParaIO.open(path, "r");
		if(file:IsValid() == true) then
			LOG.std(nil, "debug", "BadWordFilter is inited from %s", path)
			-- read a line 
			line = file:readline();
			while(line) do
--				-- replace regexp keyword to " "
--				for k, __ in pairs(lua_symbols) do
--					line = string_gsub(line, "%" .. k, " ");
--				end
				table.insert(badwords, line);
				key = line:gsub("[%s\t\n\r]","")
				if key~="" then
					badwordsMap[key] = 1
					key = key:gsub("[%w]+","H")
					BadWordFilter.MaxDirtyKeyLength = math.max(BadWordFilter.MaxDirtyKeyLength,ParaMisc.GetUnicodeCharNum(key))
				end
				line = file:readline();
			end
			file:close();
		else
			LOG.std(nil, "warn", "BadWordFilter failed to open file from %s", path)	
		end
	end

	
	if(System.options.locale == "zhTW") then
		badwordfromnamefiles = {
			"config/BadWords.xml",
			"config/BadWords.zhTW.xml",
			"config/BadWordsFromName.zhTW.xml",
		};
	end
	local _, path;
	for _, path in ipairs(badwordfromnamefiles) do
		local file = ParaIO.open(path, "r");
		if(file:IsValid() == true) then
			LOG.std(nil, "debug", "BadWordFilter BadWordFromName is inited from %s", path)
			-- read a line 
			local line = file:readline();
			while(line) do
				--badwords[line] = true;
				if(lua_symbols[line]) then
					line = "%"..line;
				end
				badwordsfromname[line] = true;
				line = file:readline();
			end
			file:close();
		else
			LOG.std(nil, "warn", "BadWordFilter BadWordFromName failed to open file from %s", path)	
		end
	end

	local url = "https://qiniu-public.keepwork.com/sensitiveWords.zip"
	if string.upper(ParaEngine.GetAppCommandLineByParam("http_env", "ONLINE"))~="ONLINE" then
		url = "https://qiniu-public-dev.keepwork.com/sensitiveWords.zip"
	end
	local localPath = ParaIO.GetWritablePath().."temp/filecache/sensitiveWords.zip"
	commonlib.Files.GetRemoteFileText(url,localPath,function(data,path)
		if not data then
			return
		end
		NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
		local ZipFile = commonlib.gettable("System.Util.ZipFile");
		local zipFile = ZipFile:new();
		if(zipFile:open(path)) then
			zipFile:unzip();
			zipFile:close();
			local txtPath = string.gsub(path,".zip","/sensitiveWords.txt")
			local file = ParaIO.open(txtPath, "r");
			if(file:IsValid() == true) then
				LOG.std(nil, "debug", "BadWordFilter RemoteFile is inited from %s", txtPath)
				-- read a line 
				local line = file:readline();
				while(line) do
					local word = System.Encoding.unbase64(line)
					if word~="" and not badwordsMap[word] then
						table.insert(badwords, word);
						badwordsMap[word] = 1
						BadWordFilter.MaxDirtyKeyLength = math.max(BadWordFilter.MaxDirtyKeyLength,ParaMisc.GetUnicodeCharNum(word))
					end
					line = file:readline();
				end
				file:close();
			else
				LOG.std(nil, "warn", "BadWordFilter RemoteFile failed to open file from %s", txtPath)	
			end

			local floderPath = path:gsub(".zip","/")
			ParaIO.DeleteFile(floderPath)
		end
	end)
end

local ReplacementStr = {
	"*",
	"**",
	"***",
	"****",
	"*****",
	"******",
	"*******",
	"********",
	"*********",
	"**********",
	"***********",
	"************",
	"*************",
	"**************",
	"***************",
	"****************",
	"*****************",
	"******************",
	"*******************",
	"********************",
	"*********************",
	"**********************",
	"***********************",
	"************************",
	"*************************",
	"**************************",
	"***************************",
	"****************************",
	"*****************************",
	"******************************",
	"*******************************",
	"********************************",
	"*********************************",
	"**********************************",
	"***********************************",
};

ReplacementStr[0] = "";

local split_chars = function (code)
	if not code or code == "" then
		return {}
	end
	code = tostring(code)
	local len = ParaMisc.GetUnicodeCharNum(code);
	local chars = {}; 
	for i = 1, len do
		local c = ParaMisc.UniSubString(code, i, i);
		chars[#chars+1] = c;
	end
	return chars
end

-- only filter if str length is smaller than this value
BadWordFilter.MaxStrLength = 512;

-- public: return the validated string 
function BadWordFilter.FilterString(str, maxStrLength)
	BadWordFilter.Init();
	if(type(str) ~= "string") or str=="" then
		return str
	end
	maxStrLength = maxStrLength or BadWordFilter.MaxStrLength
	if(#str > maxStrLength) then
		return BadWordFilter.FilterString(string.sub(str,1,256))..string.sub(str,256+1);
	end
	
	local charArr = split_chars(str)
	
	--去掉尾部的换行空格
	while charArr[#charArr] and string.match(charArr[#charArr],"[%s\t\r\n]") do
		table.remove(charArr,#charArr)
	end
	--去掉头部的换行空格
	while charArr[1] and string.match(charArr[1],"[%s\t\r\n]") do
		table.remove(charArr,1)
	end

	for i=#charArr,2,-1 do
		if not string.match(charArr[i],"[^%a']+") and not string.match(charArr[i-1],"[^%a']+") then --合并连续的英文单词
			charArr[i-1] = charArr[i-1]..charArr[i]
			table.remove(charArr,i)
		end
	end

	local tempTab,tempStr,num,j = {},nil,nil,nil
	for i=1,#charArr do
		num = math.min(#charArr,BadWordFilter.MaxDirtyKeyLength)
		tempStr = ""
		j = i
		while j<=num do
			tempStr = tempStr..charArr[j]
			if not charArr[j]:match("[%s\t\r\n]") then --新加的如果是换行空格不用重复处理
				-- print(tempStr,badwordsMap[tempStr],"j",j,"num",num)
				if badwordsMap[tempStr] then
					local len = #(tempStr);
					if(not string_match(tempStr, "^(%l+)$")) then
						len = math.floor(len/3);
					end
					local replace = ReplacementStr[len] or "";

					local s,e = string.find(str,tempStr)
					if s and e and e<#str then
						return string.sub(str,1,s-1)..replace..BadWordFilter.FilterString(string.sub(str,e+1))
					else
						return string.gsub(str,tempStr,replace)
					end
				end
			end
			j = j + 1
		end
	end
	return str
end

-- public: return the validated string 
function BadWordFilter.FilterString2(str)
	if(type(str) == "string") then
		local _, badword;
		for _, badword in ipairs(badwords) do
			if(str:match(badword)) then
				local len = #(badword);
				if(not string_match(badword, "^(%l+)$")) then
					len = math.floor(len/3);
				end
				local replace = ReplacementStr[len] or "";
				str = string.gsub(str, badword, replace);
			end
		end
	end
	return str;
end

function BadWordFilter.FilterString3(str,replaceChar)
	if(type(str) == "string") then
		local _, badword;
		for _, badword in ipairs(badwords) do
			if(str:match(badword)) then
				local len = #(badword);
				if(not string_match(badword, "^(%l+)$")) then
					len = math.floor(len/3);
				end
				
				local replace =  "";
				for i=1,len do
					replace = replace .. (replaceChar or "")
				end
				str = string.gsub(str, badword, replace);
			end
		end
	end
	return str;
end

function BadWordFilter.HasBadWorld(str)
	if(type(str) == "string") then
		-- local _, badword;
		-- for _, badword in ipairs(badwords) do
		-- 	if(str:match(badword)) then
		-- 		return true, badword
		-- 	end
		-- end
		return BadWordFilter.FilterString(str)~=str
	end
	return false, ""
end

-- public: return the validated string 
function BadWordFilter.FilterStringForUserName(str)
	if(type(str) == "string") then
		local badword, _;
		for badword, _ in pairs(badwordsfromname) do
			if(str:match(badword)) then
				local len = #(badword);
				if(not string_match(badword, "^(%l+)$")) then
					len = math.floor(len/3);
				end
				local replace = ReplacementStr[len] or "";
				str = string.gsub(str, badword, replace);
			end
		end
	end
	return str;
end

local cheat_strs = {
	"魔豆", "充值", "米币", "账号", "密码", "米米号", "交易密码", "交易"
}
function BadWordFilter.HasCheatingWord(str)
	if(type(str) == "string") then
		local bFound; 
		local _, badword;
		for _, badword in ipairs(cheat_strs) do
			if(str:match(badword)) then
				bFound = true;
				break;
			end
		end
		return bFound;
	end
end


function BadWordFilter.GenerateBadWordFile()
	local badwords = {};
	local input_files = {
		"BadWordFilter/c.t",
		"BadWordFilter/cdk.dat",
		"BadWordFilter/e.t",
		"BadWordFilter/edk.dat",
	};
	local _, path;
	for _, path in ipairs(input_files) do
		local file = ParaIO.open(path, "r");
		if(file:IsValid() == true) then
			-- read a line 
			local line = file:readline();
			while(line) do
				if(string.find(line, "%s")) then
					local word = string.match(line, "^(.-)%s");
					if(word and not string.find(word, "#")) then
						table.insert(badwords, word);
					end
				else
					table.insert(badwords, line);
				end
				line = file:readline();
			end
			file:close();
		end
	end
	
    ParaIO.DeleteFile("config/BadWords.xml");
    
	local file = ParaIO.open("config/BadWords.xml", "w");
	if(file:IsValid() == true) then
		local _, writeline;
		for _, writeline in ipairs(badwords) do
			file:WriteString(writeline.."\n");
		end
		file:close();
	end
end