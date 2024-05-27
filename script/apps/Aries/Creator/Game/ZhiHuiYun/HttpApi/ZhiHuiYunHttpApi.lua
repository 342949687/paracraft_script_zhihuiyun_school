--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/HttpApi/ZhiHuiYunHttpApi.lua");
local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")
ZhiHuiYunHttpApi.Init()
]]

local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")
ZhiHuiYunHttpApi.CommonHeaders = {
    ['User-Agent'] = 'Apifox/1.0.0 (https://www.apifox.cn)',
    ['Content-Type'] = 'application/json',
    ['Accept'] = '*/*',
    ['Host'] = 'api.jisiyun.net',
    ['Connection'] = 'keep-alive',
}

-- 后续有dev模式之类的可在这里加判断
function ZhiHuiYunHttpApi.Init()
    NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/HttpApi/login.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/ZhiHuiYun/HttpApi/competition.lua");
end
