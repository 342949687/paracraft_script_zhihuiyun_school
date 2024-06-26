--[[
Title: User Mac Binds Service
Author(s): big
CreateDate: 2021.09.08
Desc: 
use the lib:
------------------------------------------------------------
local UserMacBindsService = NPL.load('(gl)Mod/service/UserMacBindsService.lua')
------------------------------------------------------------
]]

-- api
local KeepworkUserMacBindsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkUserMacBindsApi.lua')

-- database
local BindDatabase = NPL.load('(gl)Mod/WorldShare/database/BindDatabase.lua')
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local UserMacBindsService = NPL.export()

function UserMacBindsService:GetMachineID()
    return GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID', ''))
end

function UserMacBindsService:GetUUID()
    return System.Encoding.guid.uuid()
end

function UserMacBindsService:BindDevice(callback)
    if not callback and type(callback) ~= 'function' then
        return
    end

    local function RecordToLocal()
        local username = Mod.WorldShare.Store:Get('user/username')

        BindDatabase:SetValue('username', username)
        BindDatabase:SetValue('UUID', self:GetUUID())
        BindDatabase:SetValue('machineID', self:GetMachineID())
        BindDatabase:SetValue('bindDate', Mod.WorldShare.Utils:TimestampToDatetime(Mod.WorldShare.Utils:GetCurrentTime(true)))
        BindDatabase:SetValue('isBind', true)

        BindDatabase:SaveDatabase()
    end

    self:IsBindDevice(function(bExist)
        if bExist then
            RecordToLocal()
            callback(true)
        else
            KeepworkUserMacBindsApi:BindMacAddress(
                self:GetMachineID(),
                self:GetUUID(),
                function(data, err)
                    if err == 200 then
                        RecordToLocal()
                        callback(true)
                    else
                        callback(false)
                    end
                end,
                function(data, err)
                    callback(false)
                end
            )
        end
    end)
end

function UserMacBindsService:UnbindDevice(callback)
    if not callback and type(callback) ~= 'function' then
        return
    end

    KeepworkUserMacBindsApi:GetBindList(function(data, err)
        if err ~= 200 or
           type(data) ~= 'table' then
            callback(false)
            return
        end

        if data and type(data) == 'table' and #data == 0 then
            -- always unbind when bad network    
            BindDatabase:SetValue('username', nil)
            BindDatabase:SetValue('UUID', nil)
            BindDatabase:SetValue('machineID', nil)
            BindDatabase:SetValue('bindDate', nil)
            BindDatabase:SetValue('isBind', nil)

            BindDatabase:SaveDatabase()

            callback(true)
        elseif data and type(data) == 'table' and #data > 0 then
            for _, item in ipairs(data) do
                local macAddress = self:GetMachineID()

                if item.macAddr == macAddress then
                    KeepworkUserMacBindsApi:RemoveMacAddress(item.id)
    
                    BindDatabase:SetValue('username', nil)
                    BindDatabase:SetValue('UUID', nil)
                    BindDatabase:SetValue('machineID', nil)
                    BindDatabase:SetValue('bindDate', nil)
                    BindDatabase:SetValue('isBind', nil)
    
                    BindDatabase:SaveDatabase()
    
                    callback(true)
                    return
                end
            end
        else
            callback(false)
        end
    end)
end

function UserMacBindsService:IsBindDevice(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    KeepworkUserMacBindsApi:GetBindList(function(data, err)
        if err ~= 200 or
           type(data) ~= 'table' then
            return
        end

        local macAddress = self:GetMachineID()
        local UUID = self:GetUUID()

        for _, item in ipairs(data) do
            if item.macAddress == macAddress and
               item.uuid == UUID then
                callback(true, item)
                return
            end
        end

        callback(false)
    end)
end

function UserMacBindsService:IsBindDeviceFromLocal()
    local isBind = BindDatabase:GetValue('isBind')

    if isBind == true then
        return true
    else
        return false
    end
end

function UserMacBindsService:GetUsername()
    return BindDatabase:GetValue('username')
end

function UserMacBindsService:GetBindDate()
    return BindDatabase:GetValue('bindDate')
end

function UserMacBindsService:SetSyncDate()
    BindDatabase:SetValue('syncDate', Mod.WorldShare.Utils:GetCurrentTime())
    BindDatabase:SaveDatabase()
end

function UserMacBindsService:GetSyncTimestamp()
    return BindDatabase:GetValue('syncDate')
end

function UserMacBindsService:GetSyncDate()
    local syncDate = BindDatabase:GetValue('syncDate')

    if syncDate then
        local syncDateTable = os.date('*t', syncDate)
        return format('%d年%d月%d日', syncDateTable.year, syncDateTable.month, syncDateTable.day)
    else
        return L'未同步'
    end
end

function UserMacBindsService:IsVip()
    local session = SessionsData:GetSessionByUsername(self:GetUsername())

    if session and type(session) == 'table' then
        if session.isVip == true then
            return true
        else
            return false
        end
    else
        return false
    end
end

function UserMacBindsService:GetUserType()
    local session = SessionsData:GetSessionByUsername(self:GetUsername())

    if session and type(session) == 'table' then
        return session.userType
    end
end
