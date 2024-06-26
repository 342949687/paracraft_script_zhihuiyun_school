# 新手引导相关API

## 代码方块同步

代码方块同步是新手引导开始, 当代码方块同步完成也就是相关数据与逻辑已准备就绪, 可以开始新手引导.

```lua
-- CodeBlock1 主入口代码块 
local LoadItems = gettable("LoadItems");

LoadItems["CodeBlock1"] = LoadItems["CodeBlock1"] or false;
LoadItems["CodeBlock2"] = LoadItems["CodeBlock2"] or false;
LoadItems["CodeBlock3"] = LoadItems["CodeBlock3"] or false;
LoadItems["CodeBlock4"] = LoadItems["CodeBlock4"] or false;
LoadItems["CodeBlock5"] = LoadItems["CodeBlock5"] or false;

local function IsFinishLoadItems()
    for item, loaded in pairs(LoadItems) do
        if (not loaded) then return false end
    end
    return true;
end
LoadItems["CodeBlock1"] = true;

-- TODO
-- 实现所有代码块共享的相关代码, 全局变量, 函数的定义

repeat wait(0.1) until(IsFinishLoadItems());
broadcast("AllItemLoadFinish");   -- 开始新手引导逻辑

-- CodeBlock2
-- ... 代码块相关实现
registerBroadcastEvent("AllItemLoadFinish", function(msg)
    -- 所有代码初始化完毕
end)
gettable("LoadItems")["CodeBlock2"] = true;

-- CodeBlock3
-- ... 代码块相关实现
registerBroadcastEvent("AllItemLoadFinish", function(msg)
    -- 所有代码初始化完毕
end)
gettable("LoadItems")["CodeBlock3"] = true;

-- CodeBlock4
-- ... 代码块相关实现
registerBroadcastEvent("AllItemLoadFinish", function(msg)
    -- 所有代码初始化完毕
end)
gettable("LoadItems")["CodeBlock4"] = true;

-- CodeBlock5
-- ... 代码块相关实现
registerBroadcastEvent("AllItemLoadFinish", function(msg)
    -- 所有代码初始化完毕
end)
gettable("LoadItems")["CodeBlock5"] = true;
```

## 按键事件处理

代码方块内置按键事件处理, 但其只支持单个键的响应, 若需监听组合键(ctrl, shift, alt)则可以使用沙盒API中监听键盘事件接口.

```lua
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

-- 常规普通单个按键事件
registerKeyPressedEvent("space", function(msg)
    say("space");
end)

--  通用按键事件
TutorialSandbox:RegisterKeyPressedEvent(function(event)
    local keyname = event.keyname;
    local shift_pressed = event.shift_pressed;
    local ctrl_pressed = event.ctrl_pressed;
    local alt_pressed = event.alt_pressed;
    if (keyname == "DIK_W" or keyname == "DIK_S" or keyname == "DIK_A" or keyname == "DIK_D") then
        if (shift_pressed) then
            say("shift " .. keyname)
        elseif (ctrl_pressed) then
            say("ctrl " .. keyname)
        elseif (alt_pressed) then
            say("alt " .. keyname)
        else
            say(keyname)
        end
        return true;
    end
    -- 不监听的键返回false
    return false;
end);
```

## 3D 场景的鼠标事件的开启与禁用

当需要引导用户点击弹出的2D UI 相关操作时, 可已禁用3D 场景中鼠标事件处理, 避免其破坏3D场景等...

```lua
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

TutorialSandbox:SetCanClickScene(false);  -- 禁用
TutorialSandbox:SetCanClickScene(true);   -- 开启
```

## 玩家手中方块的设置与获取

```lua
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

TutorialSandbox:SetBlockInRightHand(62);
local blockId = TutorialSandbox:GetBlockInRightHand()
say("手中方块ID=" .. tostring(blockId), 2);
TutorialSandbox:SetBlockInRightHand(100);
blockId = TutorialSandbox:GetBlockInRightHand();
say("手中方块ID=" .. tostring(blockId), 2);
```

## 玩家行为控制

定义玩家飞行, 跳跃, 方块创建与销毁等常用行为

```lua
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

TutorialSandbox:SetCanFly(true);  -- 允许飞行
TutorialSandbox:SetCanFly(false); -- 禁止飞行

TutorialSandbox:SetCanJump(true);    -- 允许跳跃
TutorialSandbox:SetCanJump(false);   -- 禁止跳跃

-- 添加鼠标点击策略
local strategy = TutorialSandbox:AddClickStrategy({
    eventType = nil,      -- 鼠标事件类型匹配 nil 匹配任意事件  mousePressEvent 鼠标按下, mouseMoveEvent 鼠标移动 mouseReleaseEvent 鼠标抬起 匹配相应事件
    mouseKeyState = 3,    -- 1 鼠标左键按下 2 鼠标右键按下 3 鼠标左键或右键按下
    shiftKeyState = 0,    -- 0 shift 键必须没有按下   1 shift 键必须按下   2 shift 键可以按下也可以不按下
    ctrlKeyState = 0,     -- 0 ctrl 键必须没有按下   1 ctrl 键必须按下   2 ctrl 键可以按下也可以不按下
    altKeyState = true,   -- 0 alt 键必须没有按下   1 alt 键必须按下   2 alt 键可以按下也可以不按下
    handBlockId = nil,    -- 玩家手中方块匹配, 为 nil 则忽略, 可取值 60,  {60, 61},  function({blockId, blockX, ...}) return true or false end
    -- 允许移除指定类型方块
    type = "BlockId",     -- All 全部可点击
    blockId = 60,
    blockIdList = {61, 62, ...},
    -- 允许移除指定位置方块
    type = "BlockPos",
    blockX=0, blockY=0, blockZ=0,
    blockPosList = {{blockX=1, blockY=1, blockZ=1}, {blockX=2, blockY=2, blockZ=2},  ...},
    -- 允许移除指定类型位置方块
    type = "BlockPosId",    -- 是 BlockId 与 BlockPos 组合   
    blockId = 60, blockX=0, blockY=0, blockZ=0,   -- blockIdList  blockPosList
    -- 允许移除指定类型范围方块
    type = "BlockIdRange",
    minBlockId = 1, maxBlockId=10,
    -- 允许移除指定位置范围方块
    type = "BlockPosRange",
    minBlockX=0,maxBlockX=0,minBlockY=0,maxBlockY=0,minBlockZ=0,maxBlockZ=0,
    -- 允许移除指定位置类型范围方块
    type = "BlockPosIdRange",
    blockX=0, blockY=0, blockZ=0,minBlockId = 1, maxBlockId=10,
    -- 允许移除指定位置范围类型方块
    type = "BlockPosRangeId",
    minBlockX=0,maxBlockX=0,minBlockY=0,maxBlockY=0,minBlockZ=0,maxBlockZ=0,blockId = 60,
    -- 允许移除指定位置范围类型范围方块
    type = "BlockPosRangeIdRange",
    minBlockX=0,maxBlockX=0,minBlockY=0,maxBlockY=0,minBlockZ=0,maxBlockZ=0,minBlockId = 1, maxBlockId=10,
});
-- 移除鼠标点击策略
TutorialSandbox:RemoveClickStrategy(strategy);

-- 添加左击清除方块策略
local strategy = TutorialSandbox:AddLeftClickToDestroyBlockStrategy({
    -- 规则点击策略   mouseKeyState 被强制设置为 1
});
-- 移除左击清除方块策略
TutorialSandbox:RemoveLeftClickToDestroyBlockStrategy(strategy);

-- 右击添加方块策略
local strategy = TutorialSandbox:AddRightClickToCreateBlockStrategy({
    -- 规则点击策略  mouseKeyState 被强制设置为 2
});
-- 移除左击清除方块策略
TutorialSandbox:RemoveRightClickToCreateBlockStrategy(strategy);
```

## 步骤拆分与定义

步骤拆分与定义主要是将新手引导整个流程阶段化, 每个阶段需要做什么和已做了什么定义与检测. 沙盒通过拆分步骤来实现主支线的完成进度.

如总步数为10,  主线: 1, 4, 9 10  支线1: 2, 3  支线2: 5, 6, 7, 8

```lua
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

-- 设置完成第几步时的回调处理函数
TutorialSandbox:SetStepTask(1, function()
    -- log(TutorialSandbox:GetStep() == 1);
end);

-- 进入下一步操作  参数true表是执行下一步回调
TutorialSandbox:NextStep(true);

-- 跳转至第几步  参数true表是执行跳转后步回调
TutorialSandbox:GoStep(3, true);
```

## 常用功能

```lua
-- 设置相机位置
TutorialSandbox:SetCamera(12, 40, 90);
-- 获取相机位置
local dist, pitch, facing = TutorialSandbox:GetCamera();
-- 禁止人物随鼠标转向
TutorialSandbox:SetCameraMode(2);
-- 允许人物随鼠标转向
TutorialSandbox:SetCameraMode(0);
-- 禁止右键拖拽调整视角
TutorialSandbox:SetParaCameraEnableMouseRightButton(false);
-- 允许右键拖拽调整视角
TutorialSandbox:SetParaCameraEnableMouseRightButton(true);
-- 设置玩家移速, 设置为0, 玩家将无法移动
TutorialSandbox:SetPlayerSpeedScale(speed);
-- 获取玩家移速
local speed = TutorialSandbox:GetPlayerSpeedScale();
-- 进入主世界
TutorialSandbox:EnterMainWorld();
-- 获取用户信息
TutorialSandbox:GetUserInfo();
-- 获取当前时间的毫秒数
TutorialSandbox:GetTimeStamp();

-- 方块选择
-- 选择块
TutorialSandbox:SelectBlock(19189,5,19224);
-- 取消选择块
TutorialSandbox:DeselectBlock(19189,5,19224);
-- 取消选择所有块
TutorialSandbox:DeselectAllBlock();

-- 注册世界加载事件回调
TutorialSandbox:RegisterWorldLoadedCallBack(callback);
-- 注册世界退出事件回调
TutorialSandbox:RegisterWorldUnloadedCallBack(callback);

-- 获取共享数据
TutorialSandbox:GetShareData();  -- 该函数返回一个表对象, 该对象不会被Reset函数修改,  可用于存储世界间的共享数据.

-- 显示窗口
TutorialSandbox:ShowWindow(G, params);  -- 使用同Page.Show, 区别 Page.Show 创建的窗口不会随世界退出自动关闭,    TutorialSandbox:ShowWindow 创建的窗口会随世界退出而自动关闭

-- 获取 keepwork api 实例对象
TutorialSandbox:GetKeepworkAPI();

-- 发送联机数据
TutorialSandbox:SendNetData(data);
-- 注册联机数据接收回调
TutorialSandbox:RegisterNetDataCallBack(function(data) echo(data) end);
-- 获取在线用户列表
TutorialSandbox:GetPlayers();

-- 沙盒 API 类, 同窗口脚本中的全局 API 类, 参考文档 UI/Window/Api/Api.md
TutorialSandbox.Http      -- http 请求类
TutorialSandbox.Promise   -- 异步辅助类
```

## 快速开始

```lua
-- 获取沙盒API对象
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");

-- 重置新手沙盒环境
TutorialSandbox:Reset();

-- main logic

-- 退出沙盒环境
TutorialSandbox:Restore();
```

## 测试环境搭建

1. 安装正式Paracraft的应用程序, 安装Git以便执行sh脚本.
2. 在D盘新建测试环境paracraft安装目录 ParacraftTest. 注: 该路径可自定义, D://ParacraftTest 为本教程示例目录
3. 拷贝正式环境安装目录中的 ParaCraft.exe 应用程序到 D://ParacraftTest 目录内, 得到D://ParacraftTest/ParaCraft.exe
4. 在 D://ParacraftTest 目录内, 点击新拷贝的 ParaCraft.exe 程序, 并在弹出的界面中点击更新, 更新完成后可以关闭该程序
5. 进入D://ParacraftTest/npl_packages目录, 下载 https://raw.githubusercontent.com/tatfook/GeneralGameServerMod/dev/upgrade.sh 至本目录内, 若无法下载可以拷贝 https://github.com/tatfook/GeneralGameServerMod/blob/dev/upgrade.sh 内容, 自己本地新建.
6. 在D://ParacraftTest/npl_packages目录内, 执行下载 upgrade.sh 脚本. (下载git后, 该类型文件会默认用git打开, 所以直接双击运行即可, 也可以手动执行, 目录内右击选择git bash, 在弹出的命令行中执行 bash upgrade.sh 即可)
7. 后续增量更新, 执行4, 6步骤即可
