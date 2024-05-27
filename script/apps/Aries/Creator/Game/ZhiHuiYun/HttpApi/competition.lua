local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")

--[[
    curl --location --request POST 'http://127.0.0.1:7001/users/findOldpassword' \
    --header 'User-Agent: Apifox/1.0.0 (https://www.apifox.cn)' \
    --header 'Content-Type: application/json' \
    --header 'Accept: */*' \
    --header 'Host: 127.0.0.1:7001' \
    --header 'Connection: keep-alive' \
    --data-raw '{
        "username": "boys",
        "findCellphone": "15219451923"
    }'
]]
-- 找回密码
function ZhiHuiYunHttpApi.ReportCompetitionPerformanceTest(data_raw, callback)
    local headers = ZhiHuiYunHttpApi.CommonHeaders
    headers['Authorization'] = 'Bearer ' .. System.User.zhy_userdata.token

    System.os.GetUrl({url = "https://api.jisiyun.net/users/cptPerformanceTests",json=true, method="POST", headers = headers, form=data_raw}, function(err, msg, data)
        -- print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYunHttpApi.ReportCompetitionPerformanceTest", err)
        -- echo(data, true)
        -- echo(data_raw, true)
        
        if callback then
            callback(err, msg, data)
        end
    end)
end