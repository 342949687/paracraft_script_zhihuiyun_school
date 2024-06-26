--[[
Title: Keepwork Users API
Author(s): big
CreateDate: 2019.11.8
ModifyDate: 2022.8.11
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkUsersApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkUsersApi.lua')
------------------------------------------------------------
]]
local Encoding = commonlib.gettable("System.Encoding.basexx")

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkUsersApi = NPL.export()

-- url: /users/login
-- method: POST
-- params:
--[[
    account	string necessary username	
    password string necessary password
    platform string not necessary platform
    machineCode string not necessary machine code
    oauthToken string not necessary third party token
    cellphone string not necessary login with phone number
    cellphoneCaptcha string not necessary A captcha for cellphone
]]
-- return: object
function KeepworkUsersApi:Login(params, success, error, isRefreshCache)
    if not params or type(params) ~= 'table' then
        return
    end

    local versionXml = ParaXML.LuaXML_ParseFile('config/Aries/creator/paracraft_script_version.xml')

    params.version = versionXml[1][1]
    if System.os.IsWindowsXP() then
        params.version = "9.0.0"
    end
    if System.options and System.options.appId then
        params.appId = System.options.appId
    end
    local url = System.options.isEducatePlatform and "/edu/users/login" or "/users/login"
    if System.options.isEducatePlatform then
      params.captcha = params.cellphoneCaptcha
    end
    KeepworkBaseApi:Post(url, params, nil, success, function(data, err)

        echo(data, true)
        error(data, err)
        LOG.std(nil,"info","KeepworkUsersApi","login err is: %s",("appId="..params.appId .. ",version=" .. params.version))
        
    end, { 503, 400 }, 8, nil, nil, isRefreshCache)
end

-- url: /users/logout
-- method: POST
-- params: []
-- return: object
function KeepworkUsersApi:Logout(success, error)
    KeepworkBaseApi:Post("/users/logout", nil, nil, success, error, nil, 8)
end

-- url: other:/users/profile； 431:"/edu/users/profile"
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:Profile(token, success, error, isLogin)
    if not token or type(token) ~= "string" or #token == 0 then
        if error and type(error) == 'function' then
            error()
        end
        return
    end
    if System.options.isEducatePlatform and isLogin then
        self:ProfilePost(token, success, error)
        return
    end
    local headers = { Authorization = format("Bearer %s", token) }
    local url = System.options.isEducatePlatform and "/edu/users/profile" or"/users/profile"
    KeepworkBaseApi:Get(url, nil, headers, success, error, 401, 8)
end
--url : /edu/users/tokenProfile
-- method: POST
-- params:
--[[
    token string 必须 token
    machineCode
    platform
]]
-- return: object
function KeepworkUsersApi:ProfilePost(token,success,error)
    local machineID = GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID', ''))
    local platform = "PC"
    local params = {
        machineCode = machineID,
        platform = platform
    }
    local headers = { Authorization = format("Bearer %s", token) }
    KeepworkBaseApi:Post("/edu/users/tokenProfile",params,headers,success,error)
end

-- url: /users/register
-- method: POST
-- params:
--[[
    username string necessary username,
    password string necessary password,
    key string necessary captchaKey,
    captcha string necessary captcha,
    channel = 3,
    platform string not necessary WEB WEB,PC,MOBILE
    machineCode	string necessary
    oauthToken string not necessary third party account token 
]]
-- return: object
function KeepworkUsersApi:Register(params, success, error, noTryStatus)
    KeepworkBaseApi:Post('/users/register', params, { notTokenRequest = true }, success, error, noTryStatus)
end

-- url: /users/svg_captcha?png=true
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:FetchCaptcha(success, error)
    KeepworkBaseApi:Get('/users/svg_captcha?png=true', nil, { notTokenRequest = true }, success, error)
end


-- url: /users/cellphone_captcha
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:CellphoneCaptcha(phone, success, error)
    if type(phone) ~= 'string' then
        return false
    end

    local url = '/users/cellphone_captcha?cellphone=' .. phone
    KeepworkBaseApi:Get(url, nil, { notTokenRequest = true }, success, error)
end

-- url: /users/cellphone_captcha
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:CellphoneCaptchWithEducate(phone, success, error)
    if type(phone) ~= 'string' then
        return false
    end

    local url = '/users/cellphone_captcha'
    KeepworkBaseApi:Get(url, {isLonger = true,cellphone=phone}, { notTokenRequest = true }, success, error)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[
    token string necessary token
    cellphone number necessary cellphone,
    captcha number necessary captcha,
    realname boolean necessary true
]]
-- return: object
function KeepworkUsersApi:RealName(cellphone, captcha, success, error, noTryStatus, macAddress)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        realname = true,
    }

    if macAddress then
        params.macAddress = macAddress
    end
    
    KeepworkBaseApi:Post('/users/cellphone_captcha', params, nil, success, error, noTryStatus)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:BindPhone(cellphone, captcha, success, error)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        isBind = true
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha', params , { notTokenRequest = false }, success, error)
end

-- url: /users/cellphone_captcha
-- method: POST
-- params:
--[[

]]
-- return: object
function KeepworkUsersApi:ClassificationAndBindPhone(cellphone, captcha, success, error)
    local params = {
        cellphone = cellphone,
        captcha = captcha,
        realname = true,
        isBind = true
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha', params , { notTokenRequest = false }, success, error)
end

-- url: /users/email_captcha
-- method: GET
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:EmailCaptcha(email, success, error)
    local url = '/users/email_captcha?email=' .. email

    KeepworkBaseApi:Get(url, nil, { notTokenRequest = true }, success, error)
end

-- url: /users/email_captcha
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:BindEmail(params, success, error)
    KeepworkBaseApi:Post('/users/email_captcha', params, { notTokenRequest = false }, success, error)
end

-- url: /users/reset_password
-- method: POST
-- params:
--[[
    token string 必须 token
]]
-- return: object
function KeepworkUsersApi:ResetPassword(params, success, error, noTryStatus)
    KeepworkBaseApi:Post('/users/reset_password', params, { notTokenRequest = true }, success, error, noTryStatus)
end

-- url: /users?cellphone=<the phone number>
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByPhonenumber(phonenumber, success, error)
    if not phonenumber then
        return
    end

    KeepworkBaseApi:Get('/users?cellphone=' .. phonenumber, nil, nil, success, error)
end

-- url: /users/PP{username base 64}
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByUsernameBase64(username, success, error)
    if not username or
       type(username) ~= 'string' or
       #username == 0 then
        return
    end

    local usernameBase64 = Encoding.to_base64(NPL.ToJson({username = username}))

    KeepworkBaseApi:Get(
        '/users/PP' .. usernameBase64,
        nil,
        nil,
        success,
        error
    )
end

-- url: /users?email={email}
-- method: GET
-- return: object
function KeepworkUsersApi:GetUserByEmail(email, success, error)
    if type(email) ~= "string" then
        return false
    end

    if #email == 0 then
        return false
    end

    KeepworkBaseApi:Get('/users?email=' .. email, nil, nil, success, error)
end

-- url: users/refreshToken
-- method: GET
-- return: object
function KeepworkUsersApi:RefreshToken(success, error)
    KeepworkBaseApi:Get('/users/refreshToken', nil, nil, success, error)
end

-- url: /users/school
-- desc: get user school list
-- method: GET
-- headers: 
--[[
    Authorization string necessary
]]
-- return:
--[[
    id number not necessary
    name string not necessary
    regionId number not necessary
    region object not necessary
        country string not necessary
        state string not necessary
        city string not necessary
        county string not necessary	
    type string not necessary
    orgId number not necessary
]]
function KeepworkUsersApi:School(success, error)
    KeepworkBaseApi:Get('/users/school', nil, nil, success, error, nil, 8)
end

-- url: /users/school
-- method: PUT
-- header:
--[[
    Authorization string necessary
]]
-- params:
--[[
    schoolId int necessary
]]
-- return: object
function KeepworkUsersApi:ChangeSchool(schoolId, success, error)
    if not schoolId then
        return false
    end

    KeepworkBaseApi:Put('/users/school', { schoolId = schoolId }, nil, success, error)
end

-- url: /paralife/wxmini/buySchemes 生成小程序跳转链接
-- method: Post
-- header:
--[[
    Authorization string necessary
]]
-- params:
--[[
    macAddress int necessary
    productCode int necessary
]]
-- return: object
function KeepworkUsersApi:BuySchemes(macAddress,productCode, success, error)
    KeepworkBaseApi:Post('/paralife/wxmini/buySchemes', {macAddress = macAddress,productCode = productCode }, nil, success, error)
end

-- url: /paralife/licenses 判断是否获得了许可
-- method: PUT
-- header:
--[[
    Authorization string necessary
]]
-- params:
--[[
    macAddress int necessary
    productCode int necessary
]]
-- return: object
function KeepworkUsersApi:ParalifeLicenses(macAddress,productCode, success, error)
    KeepworkBaseApi:Get('/paralife/licenses', {macAddress = macAddress,productCode = productCode }, nil, success, error)
end

-- url: /users/school/register
-- method: POST
-- header:
--[[
    Authorization string necessary
]]
-- params:
--[[
    type string necessary 学校类型	
    regionId integer necessary 地域ID
    name string necessary 学校名称
]]
-- return: object
function KeepworkUsersApi:SchoolRegister(schoolType, regoinId, schoolName, success, error)
    local params = {
        type = schoolType,
        regionId = regoinId,
        name = schoolName
    }

    KeepworkBaseApi:Post('/users/school/register', params, nil, success, error)
end

-- url: /users/search
-- method: POST
-- header:
-- params:
--[[
    {"id":{"$in": [ 用户id数组 ]}}
]]
-- return: object
function KeepworkUsersApi:Search(params, success, error)
    if not params or type(params) ~= 'table' then
        return false
    end

    KeepworkBaseApi:Post('/users/search', params, nil, success, error)
end

-- url: /users/webToken
-- method: GET
-- header:
-- params:
--[[ ]]
-- return: object
function KeepworkUsersApi:WebToken(success, error)
    KeepworkBaseApi:Get('/users/webToken', nil, nil, success, error)
end

-- url:/users/textingToInviteRealname
-- method: POST
-- header:
-- params:
--[[
    cellphone string necessary
    name string necessary user real name
]]
-- return: object
function KeepworkUsersApi:TextingToInviteRealname(cellphone, name, success, error)
    if not cellphone or not name then
        return false
    end

    local params = {
        cellphone = cellphone,
        name = name
    }

    KeepworkBaseApi:Post('/users/textingToInviteRealname', params, nil, success, error)
end

-- url:/users/cellphone_captcha_verify
-- method: POST
-- header:
-- params:
--[[
    cellphone string necessary
    captcha string necessary
]]
-- return: object
function KeepworkUsersApi:CellphoneCaptchaVerify(cellphone, captcha, success, error)
    if not cellphone or not captcha then
        return
    end

    local params = {
        cellphone = cellphone,
        captcha = captcha
    }

    KeepworkBaseApi:Post('/users/cellphone_captcha_verify', params, nil, success, error)
end

-- url:/users/account
-- method: DELETE
-- header:
-- params:
--[[
    password string necessary
]]
-- return: object
function KeepworkUsersApi:DeleteAccount(password, success, error)
    if not password or type(password) ~= 'string' then
        return
    end

    KeepworkBaseApi:Delete('/users/account', { password = password }, nil, success, error)
end

-- url:/users/parentCellphoneCaptcha
-- method: POST
-- header:
-- params:
--[[
    cellphone string necessary
]]
-- return: object
function KeepworkUsersApi:ParentCellphoneCaptcha(cellphone, isBind, macAddress, success, error)
    if not cellphone or
       type(cellphone) ~= 'string' or
       isBind == nil or
       type(isBind) ~= 'boolean' or
       not macAddress or
       type(macAddress) ~= 'string' then
        return
    end

    local params = {
        cellphone = cellphone,
        isBind = isBind,
        macAddress = macAddress
    }

    KeepworkBaseApi:Get('/users/parentCellphoneCaptcha', params, nil, success, error)
end
