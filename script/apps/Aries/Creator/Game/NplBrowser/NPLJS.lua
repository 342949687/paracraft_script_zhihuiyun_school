--[[
Title: NPLJS
Author(s): wxa
Date: 2023.5.31
Desc: NPLJS NPL JS 通用双向通信
------------------------------------------------------------
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
NPLJS:Open("http://127.0.0.1:8088/npl/webparacraft/python/py2lua/index.local.html", function()
NPLJS:SendMsg("Py2Lua", [==[
var1 = 100
if var1:
    print ("1 - if 表达式条件为 true")
    print (var1)
    
var2 = 0
if var2:
    print ("2 - if 表达式条件为 true")
    print (var2)
print ("Good bye!")
    ]==], nil, function(msgdata)
        echo(msgdata, true);
    end)
end)

NPLJS:GetCameraVideoImages(function(bSucceed, filename) 
    NPLJS:CloseCamera();
end, 400, 300, "temp/camera.jpg")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Encoding = commonlib.gettable("System.Encoding");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NPLJS = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local about_blank_url = "about:blank";

function NPLJS:ctor()
    self:Reset();
end

function NPLJS:Reset()
    self.m_url = about_blank_url;
    self.m_msg_callback = {};
    self.m_msgid_callback = {};
    self.m_msgid = 0;
    self.m_loaded = false;
    self.m_loading = false;
    self.m_onload_callbacks = {};
    self.m_retry_callbacks = {};

    if (self.m_onload_timer) then
        self.m_onload_timer:Change();
        self.m_onload_timer = nil;
    end

    if (self.m_retry_timer) then
        self.m_retry_timer:Change();
        self.m_retry_timer = nil;
    end
    print("=================NPLJS:Reset================");
end

function NPLJS:Open(url, callback, x, y, width, height)
    if (url == about_blank_url) then return end

    local callback_wrap = function()
        if (type(callback) == "function") then 
            callback(self) 
        end
    end

    if (self.m_url == url) then 
        if (self.m_loaded) then
            return callback_wrap();
        end
        if (self.m_loading) then
            return table.insert(self.m_onload_callbacks, callback_wrap);
        end
    else
        self:Reset();
        table.insert(self.m_onload_callbacks, callback_wrap);
    end

    self.m_url = url;
    self.m_loading = true;
    NplBrowserPlugin.Start({id = self:GetID(), url = self:GetUrl(), x = x or 0, y = y or 0, width = width or 0, height = height or 0});
    NplBrowserPlugin.Open({id = self:GetID(), url = self:GetUrl(), visible = true, x = x or 0, y = y or 0, width = width or 0, height = height or 0});
    self.m_onload_timer = commonlib.Timer:new({callbackFunc = function()
        self:SendMsg("load");
    end});

    self.m_onload_timer:Change(200, 200);
end

function NPLJS:Close()
    self:Reset();
    NplBrowserPlugin.Open({id = self:GetID(), url = self:GetUrl(), visible = false, x = 0, y = 0, width = 0, height = 0});
end

function NPLJS:IsLoaded()
    return self.m_loaded;
end

function NPLJS:OnLoad()
    if (self.m_loaded) then return end
    print("============NPLJS:OnLoad==========");
    self.m_loaded = true;
    if (self.m_onload_timer) then
        self.m_onload_timer:Change();
        self.m_onload_timer = nil;
    end
    for _, callback in ipairs(self.m_onload_callbacks) do
        callback();
    end
    self.m_onload_callbacks = {};
    self:SendMsg("load");
end

function NPLJS:GetUrl()
    return self.m_url;
end

function NPLJS:GetID()
    return "NPLJS";
end

function NPLJS:GetFilename()
    return "NPLJS";
end

function NPLJS:GetNextMsgId()
    self.m_msgid = self.m_msgid + 1;
    return "npl_" .. tostring(self.m_msgid);
end

function NPLJS:StartRetryTimer()
    if (self.m_retry_timer) then return end
    self.m_retry_timer = commonlib.Timer:new({callbackFunc = function()
        local is_empty = true;
        local timestamp = ParaGlobal.timeGetTime();
        for _, item in pairs(self.m_retry_callbacks) do
            if (timestamp > item.expired) then item.callback() end
            is_empty = false;
        end
        if (is_empty) then
            self.m_retry_timer:Change(nil, nil);
            self.m_retry_timer = nil;
        end
    end});
    self.m_retry_timer:Change(1000, 1000);
end

function NPLJS:GetMsgCallbacks(msgname)
    return self.m_msg_callback[msgname] or {};
end

function NPLJS:OnMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    self.m_msg_callback[msgname][callback] = callback;
end

function NPLJS:OffMsg(msgname, callback)
    self.m_msg_callback[msgname] = self.m_msg_callback[msgname] or {};
    self.m_msg_callback[msgname][callback] = nil;
end

function NPLJS:EmitMsg(msgname, msgdata, msgid)
    local callbacks = self:GetMsgCallbacks(msgname);
    for callback in pairs(callbacks) do
        callback(msgdata, msgid);
    end
end

function NPLJS:SendMsg(msgname, msgdata, msgid, callback, retry, timeout)
    if (msgid == nil) then msgid = self:GetNextMsgId() end
    if (type(callback) == "function") then self.m_msgid_callback[msgid] = callback end

    if (retry) then
        self.m_retry_callbacks[msgid] = {
            callback = function() 
                print("Retry SendMsg msgname!!!", "msgname:" .. msgname, "msgid:", msgid);
                self:SendMsg(msgname, msgdata, msgid, callback, retry, timeout) 
            end, 
            expired = ParaGlobal.timeGetTime() + (timeout or 5000),
        };
        self:StartRetryTimer();
    end

    NplBrowserPlugin.NPL_Activate(self:GetID(), self:GetFilename(), {
        msgid = msgid,
        msgname = msgname,
        msgdata = Encoding.base64(commonlib.Json.Encode(msgdata)),
        -- msgdata = msgdata,
        request_reply = retry,
    });
end

function NPLJS:RecvMsg(msg)
    if (type(msg) ~= "table" or type(msg.msgname) ~= "string") then return end
    local msgid = msg.msgid or 0;
    local msgname = msg.msgname;
    local msgdata = msg.msgdata;
    self.m_retry_callbacks[msgid] = nil;
    if (msg.response_reply) then return end

    local msgid_callback = self.m_msgid_callback[msgid];
    if (msgid_callback) then 
        msgid_callback(msgdata);
        self.m_msgid_callback[msgid] = nil;
    end

    if (msgname == "load") then
        -- 回调事件
        self:OnLoad();
    else
        self:EmitMsg(msgname, msgdata, msgid);
    end
end

function NPLJS:CloseCamera()
    self.m_camera_opened = false;
    NPLJS:Close();
end

-- @param callback: function(succeed, filepath) end
-- @param width, height: camera image width and height
-- @param filepath: camera image filepath default to temp/camera_snap.png
-- @param {x, y, width, height, filepath, callback}
function NPLJS:GetCameraVideoImages(options)
    options = options or {};
    local x, y, width, height = self:ScaleCameraPosition(options);

    local __self__ = self;
    local url = "https://webparacraft.keepwork.com/camera/index.html";
    if (options.debug) then url = "http://127.0.0.1:8088/npl/webparacraft/camera/index.local.html" end

    local callback = options.callback or function(msgdata)  end
    local filepath = options.filepath or "temp/camera_snap.png";

    local msg_callback = function(base64_image_data)
        local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
        if (base64_image_data and base64_image_data ~= "") then
            base64_image_data = string.gsub(base64_image_data, "data:image/png;base64,", "");
            local image_data = Encoding.unbase64(base64_image_data);
            CommonLib.WriteFile(filepath, image_data);
            callback(true, filepath);
        else
            callback(false, filepath);
        end
    end

    __self__:Open(url, function() 
        options.callback = nil;
        __self__.m_camera_opened = true;
        __self__:SendMsg("CameraSnap", options, nil, nil, true, 500);
        __self__:OnMsg("CameraSnapReply", msg_callback);
    end, x, y, width, height);
end

-- @param callback: function({{width:0, height:0, data: base64_string | [r,g,b,a, r,g,b,a]}}) end
-- @param format: raw | png | jpeg
-- NPLJS:GetCameraVideoImages 需已经被调用即 /capture video|image 被执行且未关闭
function NPLJS:GetCameraImageData(options)
    options = options or {};
    options.format = options.format or "raw";
    -- local callback = options.callback or function(msgdata)  end
    local callback = function(msgdata)
        if (options.format ~= "raw" and options.filename and msgdata and msgdata.data ~= "") then
            local base64_image_data = string.gsub(msgdata.data, "data:image/" .. options.format .. ";base64,", "");
            local image_data = Encoding.unbase64(base64_image_data);
            local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
            CommonLib.WriteFile(options.filename, image_data);
            msgdata.filename = options.filename;
        end
        if (type(options.callback) == "function") then
            options.callback(msgdata);
        end
    end
    if (not self.m_camera_opened) then return callback(nil) end
    self:SendMsg("CameraSnapData", options, nil, callback, true, 500);
end

-- @param callback: function({{name:"", label:"", score: 0.f}}) end
-- @param {x, y, width, height, video_url, callback}
function NPLJS:GetCameraObjectDetection(options)
    options = options or {};

    local __self__ = self;
    local url = "https://webparacraft.keepwork.com/object-detection/index.html";
    if (options.debug) then url = "http://127.0.0.1:8088/npl/webparacraft/object-detection/index.html" end

    local x, y, width, height = self:ScaleCameraPosition(options);

    local callback = options.callback or function(msgdata)  end
    __self__:Open(url, function() 
        options.callback = nil;  
        __self__.m_camera_opened = true;
        __self__:SendMsg("CameraObjectDetection", options, nil, nil, true, 500);
        __self__:OnMsg("CameraObjectDetectionReply", callback);
    end, x, y, width, height);
	
    -- System.PushState({name = "GetCameraObjectDetection", OnEscKey = function() __self__:Close() end});
end

function NPLJS:ScaleCameraPosition(options)
    local uiScales = System.Windows.Screen:GetUIScaling();
    local scale_x = uiScales[1];
    local scale_y = uiScales[2];
    local x = options.x or 0;
    local y = options.y or 0;
    local width = options.width or 400;
    local height = options.height or 300;
    options.x = 0;
    options.y = 0 ;
    options.width = width * scale_x;
    options.height = height* scale_y;
    return x* scale_x, y* scale_y, width * scale_x, height * scale_y;
end

-- @param {x, y, width, height, model="PoseNet|MoveNet|BlazePose", runtime="mediapipe|tfjs", maxPoses=1, interval=30, callback}
--[[ @param callback(
[
  {
    score: 0.8,
    keypoints: [
      {x: 230, y: 220, score: 0.9, score: 0.99, name: "nose"},
      {x: 212, y: 190, score: 0.8, score: 0.91, name: "left_eye"},
      ...
    ],
    -- model = BlazePose runtime=mediapipe 特有以下数据
    keypoints3D: [
      {x: 0.65, y: 0.11, z: 0.05, score: 0.99, name: "nose"},
      ...
    ],
    segmentation: {
      maskValueToLabel: (maskValue: number) => { return 'person' },
      mask: {
        toCanvasImageSource(): ...
        toImageData(): ...
        toTensor(): ...
        getUnderlyingType(): ...
      }
    }
  }
]
)
]] 
function NPLJS:GetCameraPoseDetection(options)
    -- /capture -debug -interval=2000 pose start 
    options = options or {};

    LOG.std(nil, "info", "NPLJS:GetCameraPoseDetection", options);
    local __self__ = self;
    local url = "https://webparacraft.keepwork.com/tfjs/index.html";
    if (options.debug) then url = "http://127.0.0.1:8088/npl/webparacraft/tfjs/index.html" end

    local callback = options.callback or function(msgdata) end
    options.maxPoses = options.maxPoses ~= nil and tonumber(options.maxPoses);
    options.interval = options.interval ~= nil and tonumber(options.interval);

    local x, y, width, height = self:ScaleCameraPosition(options);

    __self__:Open(url, function()
        options.callback = nil;
        __self__.m_camera_opened = true;
        __self__:SendMsg("TFJS_POSE", options, nil, nil, true, 500);
        __self__:OnMsg("TFJS_POSE_REPLY", callback);
    end, x, y, width, height);

	-- System.PushState({name = "GetCameraPoseDetection", OnEscKey = function() __self__:Close() end});
end


function NPLJS:GetCameraHandPoseDetection(options)
    -- /capture -debug -interval=2000 pose start 
    options = options or {};
    local x, y, width, height = self:ScaleCameraPosition(options);

    LOG.std(nil, "info", "NPLJS:GetCameraHandPoseDetection", options);
    local __self__ = self;
    local url = "https://webparacraft.keepwork.com/tfjs/index.html";
    if (options.debug) then url = "http://127.0.0.1:8088/npl/webparacraft/tfjs/index.html" end

    local callback = options.callback or function(msgdata) end

    __self__:Open(url, function()
        options.callback = nil;
        LOG.std(nil, "info", "SendMsg TFJS_HANDPOSE");
        __self__.m_camera_opened = true;
        __self__:SendMsg("TFJS_HANDPOSE", options, nil, nil, true, 500);
        __self__:OnMsg("TFJS_HANDPOSE_REPLY", callback);
    end, x, y, width, height);

    -- System.PushState({name = "GetCameraPoseDetection", OnEscKey = function() __self__:Close() end});
end

NPLJS:InitSingleton();

NPL.this(function()
	local msg = NplBrowserPlugin.TranslateJsMessage(msg)
    NPLJS:RecvMsg(msg);
end, {filename="NPLJS"});
