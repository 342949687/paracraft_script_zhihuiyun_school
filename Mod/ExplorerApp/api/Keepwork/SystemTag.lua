--[[
Title: Keepwork System Tag API
Author(s):  big
Date:  2019.11.8
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkSystemTagApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/SystemTag.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local KeepworkSystemTagApi = NPL.export()

-- url: /systemTags/search?classify=1&x-order=extra.sn-asc
-- method:
-- params: [[]]
-- return: object
function KeepworkSystemTagApi:Search(success, error)
    KeepworkBaseApi:Post('/systemTags/search?classify=1&x-order=extra.sn-asc', nil, nil, success, error)
end