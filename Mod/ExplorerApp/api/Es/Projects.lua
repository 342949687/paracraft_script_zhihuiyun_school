--[[
Title: Keepwork Paracraft Devices API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkParacraftDevicesApi = NPL.load("(gl)Mod/ExplorerApp/api/Keepwork/ParacraftDevices.lua")
------------------------------------------------------------
]]

local EsBaseApi = NPL.load('(gl)Mod/WorldShare/api/Es/BaseApi.lua')

local EsProjectsApi = NPL.export()

-- url: /projects
-- method: GET
-- [[]]
-- return object
function EsProjectsApi:Projects(params, success, error)
    EsBaseApi:Get('/projects', params, nil, success)
end

