
-- _G.__debugger__ = function()
-- 	package.path = 'C:/Users/xiaoyao/.vscode/extensions/stuartwang.luapanda-3.2.0/Debugger/?.lua;'.. package.path;
-- 	_G.lua_extension = _G.lua_extension or {};
-- 	_G.lua_extension.luasocket = _G["socket.core"];
-- 	_G.LuaPanda = _G.require("LuaPanda");
-- 	_G.LuaPanda.start('127.0.0.1', 8818);
-- end

_G.__debugger__ = function(ip, port)
    local LuaPanda = NPL.load("Mod/GeneralGameServerMod/LuaPanda.lua")
	_G.lua_extension = _G.lua_extension or {};
	_G.lua_extension.luasocket = _G["socket.core"];
	_G.LuaPanda = LuaPanda;
	_G.LuaPanda.start(ip or '127.0.0.1', port or 8818);
end

-- _G.__debugger__();

-- print("this is a test", 1221)

-- local obj = {a = 1}
-- setmetatable(obj, {__index = {key = 1}})

-- for key, value in pairs(obj) do
--     print(key, value);
-- end
