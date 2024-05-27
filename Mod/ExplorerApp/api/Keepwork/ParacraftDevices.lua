--[[
Title: Keepwork Paracraft Devices API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkParacraftDevicesApi = NPL.load("(gl)Mod/Explorer/api/Keepwork/ParacraftDevices.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local KeepworkParacraftDevicesApi = NPL.export()

-- url: /paracraftDevices/pwdVerify
-- method: GET
-- params: [[]]
-- return: object
function KeepworkParacraftDevicesApi:PwdVerify(params, success, error)
    KeepworkBaseApi:Get('/paracraftDevices/pwdVerify', params, nil, success, error)
end