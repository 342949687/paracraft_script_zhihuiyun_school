--[[
Title: BlueTooth
Author(s): dummy, big
CreateDate: 2023.10.30
ModifyDate: 2023.11.6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/BlueTooth.lua");
local BlueTooth = commonlib.gettable("System.os.BlueTooth");
------------------------------------------------------------
BlueTooth:init();
BlueTooth:setupBluetoothDelegate();
BlueTooth:setDeviceName("hello_ble");
BlueTooth:reconnectBlu();
]]

local BlueTooth = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.BlueTooth"));

BlueTooth:Signal("setBlueStatus");
BlueTooth:Signal("checkDevice");
BlueTooth:Signal("onReadBlueGattUUid");
BlueTooth:Signal("onReadCharacteristicFinished");
BlueTooth:Signal("onCharacteristic");
BlueTooth:Signal("onDescriptor");
BlueTooth:Signal("onService");

local platform = System.os.GetPlatform();

-- 对应oc/java互调
local BLUETOOTH_SYSTEM_CALL = {
    CHECK_DEVICE = 1101;
    SET_BLUE_STATUS = 1102;
    ON_READ_CHARACTERISTIC_FINSHED = 1103;
    ON_CHARACTERISTIC = 1104;
    ON_DESCRIPTOR = 1105;
    ON_READ_ALL_GATT = 1106;
    ON_SERVICE = 1107;
}

function BlueTooth:init()
    LOG.std(nil, "info", "BlueTooth", "init BlueTooth");
    if (not self.Single) then
        self.Single = self;
        self.regNplEngineBridge();
        self:initProtocolFunc();
    end
end

function BlueTooth.GetSingle()
    return BlueTooth.Single;
end

local LocalService = {callBacks = {}};
function BlueTooth:initProtocolFunc()
    LocalService.RegisterProtocolCallBacks = function(pid, pfunc)
        LocalService.callBacks[pid] = pfunc;
    end

    -- 设置蓝牙状态
    local function setBlueStatus(pId, pData)
        self.isConnected = ("1" == pData);
        -- blue connect finished.
        self:setBlueStatus();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS, setBlueStatus);

    local function checkDevice(pId, pData)
        local device_params = commonlib.Json.Decode(pData);
        self:linkDevice(device_params.addr);
        self:checkDevice();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.CHECK_DEVICE, checkDevice);

    local function onReadBlueGattUUid(pId, pData)
        self.blueGattUUidMap = commonlib.Json.Decode(pData);
        self:onReadBlueGattUUid();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_ALL_GATT, onReadBlueGattUUid);

    local function onReadCharacteristicFinished(pId, pData)
        self:onReadCharacteristicFinished();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_CHARACTERISTIC_FINSHED, onReadCharacteristicFinished);

    local function onCharacteristic(pId, pData)
        local chaParams = commonlib.Json.Decode(pData);
        LOG.std(nil, "debug", "BlueTooth", "chaParams: %s", chaParams);
        if (chaParams and type(chaParams) == "table") then
            self.chaUUID = chaParams.uuid;
        end
        
        self:onCharacteristic();
    end	
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_CHARACTERISTIC, onCharacteristic);

    local function onDescriptor(pId, pData)
        local desc_params = commonlib.Json.Decode(pData);
        self:onDescriptor();
    end	
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_DESCRIPTOR, onDescriptor);

    local function onService(pId, pData)
        local serParams = commonlib.Json.Decode(pData);

        if (serParams and type(serParams) == "table") then
            self.serUUID = serParams.uuid;
        end

        self:onService();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_SERVICE, onService);
end

---- npl call engine
local g_engine_call_Lua;
function BlueTooth.regNplEngineBridge()
    if (platform == "android") then
        if (LuaJavaBridge) then
            return;
        end	

        if (LuaJavaBridge == nil) then
            NPL.call("LuaJavaBridge.cpp", {});
        end

        if (LuaJavaBridge) then
            local LuaJavaBridge = LuaJavaBridge;
            local callJavaStaticMethod = LuaJavaBridge.callJavaStaticMethod;

            local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"};
            local sigs = "(Ljava/lang/String;)V"; -- 传入string参数，无返回值
            local ret = callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "registerLuaCall", sigs, args);
        end
    elseif (platform == "ios") then
        NPL.call("LuaObjcBridge.cpp", {});
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "registerLuaCall", args);
    end

    if (not g_engine_call_Lua) then
        g_engine_call_Lua = function(pData)
            local splt_pos = string.find(pData, "_");
            if (splt_pos) then
                local extData = string.sub(pData, splt_pos + 1);
                local extId = tonumber(string.sub(pData, 1, splt_pos - 1));

                -- LOG.std(nil, "debug", "BlueTooth", string.format("lua id:%s, data:%s", extId, extData));

                if (LocalService and LocalService.callBacks) then
                    if (LocalService.callBacks[extId]) then
                        LocalService.callBacks[extId](extId, extData);
                    end
                end
            end
        end
    end	
end

function BlueTooth:setDeviceName(name)
    if (platform == "win32") then
        NPL.call("script/bluetooth.cpp", {
            cmd = "setDeviceName",
            args = {name = name}
        });
    elseif (platform == "android") then
        local args = {name};
        local sigs = "(Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setDeviceName", sigs, args);
    elseif (platform == "ios") then
        local args = {name = name};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setDeviceName", args);
    end
end

function BlueTooth:setCharacteristicsUuid(serUUID, chaUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setCharacteristicsUuid", sigs, args);
    elseif (platform == "ios") then
        local args = {serUuid = serUUID, chaUuid = chaUUID};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicsUuid", args);
    end
end

function BlueTooth:setupBluetoothDelegate()
    if (platform == "android") then
        local args = {}
        local sigs = "()V"
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setupBluetoothDelegate", sigs, args);
    elseif (platform == "ios") then
        local args = {}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setupBluetoothDelegate", args);
    end
end

function BlueTooth:readAllBlueGatt()
    if (platform == "android") then
        local args = {};
        local sigs = "()Ljava/lang/String;";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "readAllBlueGatt", sigs, args);
        if (type(ret.result) == "string") then
            ret.result = commonlib.Json.Decode(ret.result);
        end
        return ret.result;
    elseif (platform == "ios") then
        local args = {};
        local _, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readAllBlueGatt", args);
        if (type(ret) == "string") then
            ret = commonlib.Json.Decode(ret);
        end
        return ret;
    end
end

function BlueTooth:reconnectBlueTooth()
    if (platform == "ios") then
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "reconnectBlueTooth", args);
    end
end

function BlueTooth:disconnectBlueTooth()
    if (platform == "android") then
        local args = {};
        local sigs = "()V";
        local let = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "disconnectBlueTooth", sigs, args);
    elseif (platform == "ios") then
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "disconnectBlueTooth", args);
    end
end

-- NPL.this function
NPL.this(function()
    -- LOG.std(nil, "debug", "BlueTooth", "BlueTooth NPL.this:" .. tostring(msg));
    if (g_engine_call_Lua) then
        local msg = msg;
        g_engine_call_Lua(msg);
    end
end);

function BlueTooth:linkDevice(addr)
    if (platform == "android") then
        local args = {addr};
        local sigs = "(Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "connectDevice", sigs, args);
    elseif (platform == "ios") then
        local args = {addr = addr};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "linkDevice", args);
    end
end

function BlueTooth:writeToCharacteristic(serUUID, chaUUID, writeByte, reset)
    if (platform == "android") then
        local args = {serUUID, chaUUID, writeByte};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "writeToCharacteristic", sigs, args);
    elseif (platform == "ios") then
        local args = {serUUID = serUUID, chaUUID = chaUUID, writeByte = writeByte, reset = reset};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "writeToCharacteristic", args);
    end
end

function BlueTooth:characteristicGetStrValue(serUUID, chaUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "characteristicGetStrValue", sigs, args);	
        if (type(ret.result) == "string") then
            ret.result = commonlib.Json.Decode(ret.result);
        end
        return ret.result;
    elseif (platform == "ios") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID};
        local ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "characteristicGetStrValue", args);
        return ret.result;
    end
end

function BlueTooth:readCharacteristic(serUUID, chaUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "readCharacteristic", sigs, args);
    elseif (platform == "ios") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readCharacteristic", args);
    end	
end	

function BlueTooth:setCharacteristicNotification(serUUID, chaUUID, isNotify)
    if (platform == "android") then
        local args = {serUUID, chaUUID, isNotify}; 
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Z)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setCharacteristicNotification", sigs, args);
    elseif (platform == "ios") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID, isNotify = isNotify};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicNotification", args);
    end
end

function BlueTooth:setDescriptorNotification(serUUID, chaUUID, descUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID, descUUID} ;
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setDescriptorNotification", sigs, args);
    elseif (platform == "ios") then
        -- not need
    end
end
