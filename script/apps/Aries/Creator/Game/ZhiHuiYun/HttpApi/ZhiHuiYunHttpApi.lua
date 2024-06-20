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

--[[
curl --location --request GET 'https://api-dev.jisiyun.net/getSocketHost' \
--header 'User-Agent: Apifox/1.0.0 (https://www.apifox.cn)' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcklkIjoxLCJ1c2VybmFtZSI6ImR1a2VzIiwiY2hhbm5lbCI6MCwiaWF0IjoxNjg1MzQ3NDYyfQ.BPF8Mym63m93lgYDKI-_bIuBzWupm-zDGr9LKegbBwA' \
--header 'Accept: */*' \
--header 'Host: api-dev.jisiyun.net' \
--header 'Connection: keep-alive'
]]

function ZhiHuiYunHttpApi.GetSocketUrl(callback)
    local headers = ZhiHuiYunHttpApi.CommonHeaders
    System.os.GetUrl({url = "https://api.jisiyun.net/getSocketHost",json=true, method="GET", headers = headers}, function(err, msg, data)
        print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYunHttpApi.GetSocketUrl", err)
        echo(data, true)
        
        if callback then
            callback(err, msg, data)
        end
    end)
end