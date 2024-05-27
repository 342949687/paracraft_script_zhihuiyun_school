--[[
Title: Keepwork Service Paracraft Services
Author(s):  big
Date:  2019.01.28
Place: Foshan
use the lib:
------------------------------------------------------------
local ParacraftDevices = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkService/ParacraftDevices.lua")
------------------------------------------------------------
]]
local ParacraftDevicesApi = NPL.load('(gl)Mod/ExplorerApp/api/ParacraftDevices.lua')
local ParacraftGameCoinKeysApi = NPL.load('(gl)Mod/ExplorerApp/api/ParacraftGameCoinKeys.lua')

local ParacraftDevices = NPL.export()

function ParacraftDevices:PwdVerify(password, callback)
    if not password then
        return false
    end

    local params = {
        deviceId = ParaEngine.GetAttributeObject():GetField("MaxMacAddress",""),
        password = password
    }

    ParacraftGameCoinKeysApi:PwdVerify(
        params,
        function(data, err)
            if type(callback) == 'function' then
                callback(data, err)
            end
        end,
        function(data, err)
            if type(callback) == 'function' then
                callback()
            end
        end
    )
end

function ParacraftDevices:Recharge(code, callback)
    if not code then
        return false
    end

    local params = {
        key = code
    }

    ParacraftGameCoinKeysApi:Active(params, callback, nil , 400)
end