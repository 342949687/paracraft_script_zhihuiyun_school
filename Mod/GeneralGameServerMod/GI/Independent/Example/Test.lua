

local str = "hello 你好";

print(string.char(string.byte(str, 8, 8)))
local newstr = "";
for i = 1, #str do
    local byte = string.byte(str, i, i);
    if (byte > 0 and byte < 128) then
        newstr = newstr .. string.char(byte);
    else 
        newstr = newstr .. string.format("_%X", byte)
    end
end
print(newstr)

-- function test()
--     local i = 1;
--     while (i < 10) do
--         print(i);
--         i = i + 1;
--     end
-- end

-- __debug_sethook__(function(...)
--     print(...);
-- end, "l");

-- test();

-- CreateEntity({
--     bx = 19196, by = 5, bz = 19203,
--     assetfile = "@/blocktemplates/goalpoint.bmax"
-- })

-- print(GetFullPath("./API.lua"));

-- ShowGIBlocklyEditorPage();
-- SetCameraLookAtBlockPos(19195,4,19203);

-- local function SelectWorldServer()
--     GetNetAPI():Get("__server_manager__/__select_world_server__", {
--         worldId = GetWorldId(),
--     }):Then(__safe_callback__(function(msg)
--         echo(msg)
--     end));
-- end

-- SelectWorldServer();

-- local GGS = require("GGS");

-- GGS:Connect(function()
-- 	print("===========================s")
-- 	GGS:SetUserData({nickname = "xiaoyao", score = 10});
-- end)

-- GGS:OnUserData(function(userdata)
-- 	log(userdata)
-- end)

-- RegisterEventCallBack(EventType.KEY_DOWN, function(event)
-- 	local keyname = event.keyname;
-- 	print(keyname);
-- 	if (keyname == "DIK_A" or keyname == "DIK_LEFT") then
-- 	end
-- end)

-- function test(arg)
-- 	log(arg);
-- end

-- RegisterEventCallBack("ABC", function(ev)
-- 	log(ev)
-- end);
-- TriggerEventCallBack("ABC", 32, 3232)

-- print(GetPlayer():GetBlockPos())
-- local Log = require("Log");
-- print("---------1")
-- Log:Info("hello world")

-- SetInterval(1000, function()
--     print("timer");
-- end)

-- print("============sleep begin=============")

-- sleep(1000);

-- run(function()
--     print("============run1 sleep begin=============")
--     sleep(2000);
--     print("============run1 sleep end=============")
-- end)

-- run(function()
--     print("============run2 sleep begin=============")
--     sleep(4000);
--     print("============run2 sleep end=============")
-- end)

-- sleep(3000);

-- print("============sleep end=============")


-- local EntityCodeList = GI.API.GetAllEntityCode();

-- for _, entity in ipairs(EntityCodeList) do
--     local text = entity:GetNPLCode();
--     if (text) then
--         text = string.gsub(text, [[TutorialSandbox:Reset%([^%)]*%);?]], "");
--         text = string.gsub(text, [[local TutorialSandbox = NPL.load%([^%)]*%);]], [[local TutorialSandbox = GI.API;]])
--         text = string.gsub(text, "TutorialSandbox:", "TutorialSandbox%.");
--         entity:SetNPLCode(text);
--     end
-- end

