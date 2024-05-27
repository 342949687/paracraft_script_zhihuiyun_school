--[[
Title: Keepwork Paracraft Game Coin Keys API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkParacraftGameCoinKeysApi = NPL.load("(gl)Mod/ExplorerApp/api/Keepwork/ParacraftGameCoinKeys.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local KeepworkParacraftGameCoinKeysApi = NPL.export()

-- url: /paracraftGameCoinKeys/active
-- method: POST
-- params: [[]]
-- return object
function KeepworkParacraftGameCoinKeysApi:Active(params, success, error, noTryStatus)
    KeepworkBaseApi:Post('/paracraftGameCoinKeys/active', params, nil, success, error, noTryStatus)
end