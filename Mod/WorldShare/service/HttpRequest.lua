--[[
Title: HttpRequest
Author(s): big
CreateDate: 2017.04.17
ModifyDate: 2023.11.30
Desc: 
use the lib:
------------------------------------------------------------
local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')
------------------------------------------------------------
]]
local HttpRequest = commonlib.inherit(nil, NPL.export())

HttpRequest.tryTimes = 1
HttpRequest.maxTryTimes = 3
HttpRequest.defaultTimeout = 120
HttpRequest.maxTimeout = 0
HttpRequest.defaultSuccessCode = {200, 201, 202, 204}
HttpRequest.defaultFailCode = {400, 401, 404, 409, 422, 500}
HttpRequest.cacheData = {}
HttpRequest.cacheTime = 6

function HttpRequest:ctor()
end

function HttpRequest:GetUrl(params, callback, noTryStatus, timeout, noShowLog)
    if not params or
       (type(params) ~= 'table' and type(params) ~= 'string') then
        return
    end

    if timeout and type(timeout) == 'number' then
        self.maxTimeout = timeout
    else
        self.maxTimeout = self.defaultTimeout
    end

    local formatParams = {}

    if params and type(params) == 'string' then
        formatParams = {
            method = 'GET',
            url = params,
            json = true,
            headers = {}
        }
    end

    if params and type(params) == 'table' then
        formatParams = {
            method = params.method or 'GET',
            url = params.url,
            json = params.json,
            headers = params.headers
        }
    end

    if formatParams and
       type(formatParams) == 'table' and
       formatParams.method == 'GET' and
       params and
       type(params) == 'table' then
        local url = params.url
        local paramsString = ''

        for key, value in pairs(params.form or {}) do
            if value ~= nil and
               (type(value) == 'string' or type(value) == 'number') then
                paramsString = paramsString .. key .. '=' .. value .. '&'
            end

            if value ~= nil and type(value) == 'boolean' then
                if value then
                    paramsString = paramsString .. key .. '=true&'
                else
                    paramsString = paramsString .. key .. '=false&'
                end
            end
        end

        paramsString = string.sub(paramsString, 1, -2)

        if paramsString and paramsString ~= '' then
            formatParams.url = format('%s?%s', url, paramsString)
        end
    end

    if formatParams and
       type(formatParams) == 'table' and
       formatParams.method ~= 'GET' then
        formatParams.form = params.form or {}
    end

    local requestTime = os.time()

    if self:CheckCache(formatParams) then
        local cache = self.cacheData[formatParams.url]

        if cache.cacheStatus and cache.cacheStatus == 'fetching' then
            commonlib.TimerManager.SetTimeout(function()
                if callback and type(callback) == 'function' then
                    if cache and cache.cacheResponse and cache.cacheErr then
                        callback(cache.cacheResponse, cache.cacheErr)
                    end
                end
            end, self.cacheTime * 500)
        elseif cache.cacheStatus and cache.cacheStatus == 'finish' then
            if callback and type(callback) == 'function' then
                callback(cache.cacheResponse, cache.cacheErr)
            end
        end
        return
    end

    formatParams.cacheTime = os.time()
    formatParams.cacheStatus = 'fetching'
    self.cacheData[formatParams.url] = formatParams

    System.os.GetUrl(
        formatParams,
        function(err, msg, data)
            if err == 0 or (os.time() - requestTime) >= self.maxTimeout then
                ---- debug code ----
                local debugUrl = type(params) == 'string' and params or formatParams.url
                local method = type(params) == 'table' and params.method and params.method or 'GET'

                if not noShowLog then
                    LOG.std('HttpRequest', 'debug', 'Request', 'Connection timeout, Status Code: %s, Method: %s, URL: %s, Params: %s', err, method, debugUrl, NPL.ToJson(formatParams, true))
                end
                ---- debug code ----

                self:Retry(err, msg, data, params, callback, noTryStatus, timeout)
                return
            end

            ---- debug code ----
            local debugUrl = type(params) == 'string' and params or formatParams.url
            local method = type(params) == 'table' and params.method and params.method or 'GET'

            if not noShowLog then
                LOG.std('HttpRequest', 'debug', 'Request', 'Status Code: %s, Method: %s, URL: %s, Params: %s', err, method, debugUrl, NPL.ToJson(formatParams, true))
            end

            if err ~= 200 then
                local errorMessage = string.format('Status Code: %s, Method: %s, URL: %s, Params: %s', err, method, debugUrl, NPL.ToJson(formatParams, true))
                GameLogic.SendErrorLog("HttpRequest","WorldShare Request",errorMessage)
            end
            ---- debug code ----
            
            -- no try status code, return directly
            if noTryStatus ~= nil and type(noTryStatus) == 'table' then
                for _, code in pairs(noTryStatus) do
                    if err == code then
                        if callback and type(callback) == 'function' then
                            self.cacheData[formatParams.url] = nil
                            callback(data, err)
                        end

                        self.tryTimes = 1
                        return false
                    end
                end
            elseif noTryStatus ~= nil and type(noTryStatus) == 'number' then
                if err == noTryStatus then
                    if callback and type(callback) == 'function' then
                        self.cacheData[formatParams.url] = nil
                        callback(data, err)
                    end

                    self.tryTimes = 1
                    return false
                end
            end

            -- fail return
            for _, code in pairs(HttpRequest.defaultFailCode) do
                if err == code then
                    if callback and type(callback) == 'function' then
                        self.cacheData[formatParams.url] = nil
                        callback(data, err)
                    end

                    self.tryTimes = 1
                    return false
                end
            end

            -- success return
            for _, code in pairs(HttpRequest.defaultSuccessCode) do
                if err == code then
                    if callback and type(callback) == 'function' then
                        formatParams.cacheTime = os.time()
                        formatParams.cacheStatus = 'finish'
                        formatParams.cacheResponse = data
                        formatParams.cacheErr = err
                        self.cacheData[formatParams.url] = formatParams
                        callback(data, err)
                    end

                    self.tryTimes = 1
                    return true
                end
            end

            -- fail try
            self:Retry(err, msg, data, params, callback, noTryStatus, timeout)
        end
    )
end

-- Is exist cache
function HttpRequest:CheckCache(formatParams)
    if not formatParams or not formatParams.url or formatParams.url == '' then
        return false
    end

    if not self.cacheData[formatParams.url] or not self.cacheData[formatParams.url].cacheTime then
        return false
    end

    local cacheUrlParams = self.cacheData[formatParams.url]

    if formatParams.json then
        formatParams.headers['content-type'] = 'application/json'
    end

    local isOverTime = false

    if (os.time() - cacheUrlParams.cacheTime) > self.cacheTime then
        isOverTime = true
    else
        isOverTime = false
    end

    local isSameForm = true

    if cacheUrlParams.form and formatParams.form then
        if NPL.ToJson(cacheUrlParams.form) ~= NPL.ToJson(formatParams.form) then
            isSameForm = false
        end
    else
        if cacheUrlParams.form == nil and formatParams.form == nil then
            isSameForm = true
        else
            isSameForm = false
        end
    end

    local isSameHeader = true

    for key, item in ipairs(cacheUrlParams.headers) do
        if not formatParams.headers[key] or formatParams.headers[key] ~= item then
            isSameHeader = false
            break
        end
    end

    for key, item in ipairs(formatParams.headers) do
        if not cacheUrlParams.headers[key] or cacheUrlParams.headers[key] ~= item then
            isSameHeader = false
            break
        end
    end

    -- clean overtime data
    local cacheData = commonlib.copy(self.cacheData)
    for key, item in ipairs(cacheData) do
        if item and item.cacheTime and (os.time() - item.cacheTime) > self.cacheTime then
            self.cacheData[key] = nil
        end
    end

    if not isOverTime and isSameForm and isSameHeader and formatParams.method == cacheUrlParams.method then
        return true
    else
        return false
    end
end

function HttpRequest:RefreshCache(url)
    self.cacheData[url] = nil
end

function HttpRequest:Retry(err, msg, data, params, callback, noTryStatus, timeout)
    -- beyond the max try times, must be return
    if self.tryTimes >= HttpRequest.maxTryTimes then
        if callback and type(callback) == 'function' then
            callback(data, err)
        end

        self.tryTimes = 1
        return
    end

    -- continue try
    self.tryTimes = self.tryTimes + 1

    commonlib.TimerManager.SetTimeout(
        function()
            self:GetUrl(params, callback, noTryStatus, timeout)
        end,
        2100
    )
end

function HttpRequest:Get(url, params, headers, success, error, noTryStatus, timeout, noShowLog)
    if not url then
        return false
    end

    local getParams = {
        method = 'GET',
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:new():GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus,
        timeout,
        noShowLog
    )
end

function HttpRequest:Post(url, params, headers, success, error, noTryStatus, timeout, noShowLog)
    if not url then
        return false
    end

    local getParams = {
        method = 'POST',
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:new():GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus,
        timeout,
        noShowLog
    )

end

function HttpRequest:Put(url, params, headers, success, error, noTryStatus, timeout, noShowLog)
    if not url then
        return false
    end

    local getParams = {
        method = 'PUT',
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:new():GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus,
        timeout,
        noShowLog
    )
end

function HttpRequest:Delete(url, params, headers, success, error, noTryStatus, timeout, noShowLog)
    if not url then
        return false
    end

    local getParams = {
        method = 'DELETE',
        url = url,
        json = true,
        headers = headers or {},
        form = params or {}
    }

    self:new():GetUrl(
        getParams,
        function(data, err)
            if err == 200 then
                if type(success) == 'function' then success(data, err) end
            else
                if type(error) == 'function' then error(data, err) end
            end
        end,
        noTryStatus,
        timeout,
        noShowLog
    )
end

function HttpRequest:PostFields(url, params, headers, success, error, timeout)
    if not params or type(params) ~= 'table' then
        return false
    end

    if not self.boundary then
        self.boundary = ParaMisc.md5('')
    end

    local boundaryLine = '--WebKitFormBoundary' .. self.boundary .. '\n'
    
    local out = {}
    out[#out + 1] = '' .. boundaryLine
    for key, item in ipairs(params) do
        if not item or not item.name or not item.type or not item.value then
            return false
        end

        if item.type == 'string' then
            out[#out + 1] = 'Content-Disposition: form-data; name="' .. item.name .. '"\n\n'
            out[#out + 1] = item.value
            out[#out + 1] = '\n'
        elseif item.type == 'file' then
            if item.filename then
                out[#out + 1] = 'Content-Disposition: form-data; name="file"; filename="' .. item.filename .. '"\n';
            else
                out[#out + 1] = 'Content-Disposition: form-data; name="file";\n';
            end
            if(item["Content-Type"]) then
                out[#out + 1] = string.format('Content-Type: %s\n\n', item["Content-Type"]);
            else
                out[#out + 1] = 'Content-Type: application/octet-stream\nContent-Transfer-Encoding: binary\n\n';
            end
            out[#out + 1] = item.value or "";
            out[#out + 1] = '\n';
        end
        out[#out + 1] = boundaryLine;
    end
    local postfields = table.concat(out);
    local contentLength = #postfields
    headers = headers or {}

    headers['User-Agent'] = 'paracraft'
    headers['Accept'] = '*/*'
    headers['Cache-Control'] = 'no-cache'
    headers['Content-Type'] = 'multipart/form-data; boundary=WebKitFormBoundary' .. self.boundary
    headers['Content-Length'] = contentLength
    headers['Connection'] = 'keep-alive'
    
    System.os.GetUrl({url = url, headers = headers, postfields = postfields}, function(err, msg, data)
        LOG.std('HttpRequest', 'debug', 'Request', 'Status Code: %s, Method: %s, URL: %s', err, 'POST', url)

        if err == 200 then
            if type(success) == 'function' then
                success(data, err, msg)
            end
        else
            -- echo(url); echo(headers); echo(postfields);
            if type(error) == 'function' then
                error(data, err, msg)
            end
        end
    end)
    -- TODO: implement timeout?

    if(contentLength > 1024*1024*10) then
        postfields = nil;
        headers = nil;
        out = nil;
        collectgarbage("collect");
    end
end