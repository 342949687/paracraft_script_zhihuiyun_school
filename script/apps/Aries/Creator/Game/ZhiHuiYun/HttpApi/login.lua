local ZhiHuiYunHttpApi = commonlib.gettable("MyCompany.Aries.Game.ZhiHuiYun.ZhiHuiYunHttpApi")

function ZhiHuiYunHttpApi.Login()
    -- body
end

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
function ZhiHuiYunHttpApi.FindPassword(username, phone_number, callback)
    local headers = ZhiHuiYunHttpApi.CommonHeaders
    local data_raw = {
        username = username,
        findCellphone = phone_number,
    }

    System.os.GetUrl({url = "https://api.jisiyun.net/users/findOldpassword",json=true, method="POST", headers = headers, form=data_raw}, function(err, msg, data)
        -- print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYunHttpApi.ResetPassword", err)
        -- echo(data, true)
        -- echo(data_raw, true)
        
        if callback then
            callback(err, msg, data)
        end
    end)
end

--[[
    curl --location --request PUT 'https://api-dev.jisiyun.net/users/password' \
    --header 'User-Agent: Apifox/1.0.0 (https://www.apifox.cn)' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwidXNlcklkIjoyLCJ1c2VybmFtZSI6ImJveXMiLCJjaGFubmVsIjowLCJpYXQiOjE3MTQ0Mzc5NDV9.-4p46009y3t0CI7fVNjiMZfZB748N6EaplHYWgLmx0k' \
    --header 'Accept: */*' \
    --header 'Host: api-dev.jisiyun.net' \
    --header 'Connection: keep-alive' \
    --data-raw '{
        "oldPassword": "ae123456",
        "password": "Keep2023"
    }'
]]

-- 修改密码
function ZhiHuiYunHttpApi.ResetPassword(old_password, new_password, callback)
    if not System.User or not System.User.zhy_userdata then
        return
    end

    local headers = ZhiHuiYunHttpApi.CommonHeaders
    headers['Authorization'] = 'Bearer ' .. System.User.zhy_userdata.token
    local data_raw = {
        oldPassword = old_password,
        password = new_password,
    }

    System.os.GetUrl({url = "https://api.jisiyun.net/users/password",json=true, method="PUT", headers = headers, form=data_raw}, function(err, msg, data)
        -- print(">>>>>>>>>>>>>>>>>>>>>ZhiHuiYunHttpApi.ResetPassword", err)
        -- echo(data, true)
        -- echo(data_raw, true)
        
        if callback then
            callback(err, msg, data)
        end
    end)
end

function ZhiHuiYunHttpApi.LoginOut(callback)
    -- 暂时没有登出接口 先占坑
    if not System.User then
        System.User = {}
    end

    System.User.zhy_userdata = nil
    if callback then
        callback()
    end
end