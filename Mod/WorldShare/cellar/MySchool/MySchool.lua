--[[
Title: my school page
Author(s):  big
CreateDate: 2019.09.11
ModifyDate: 2021.11.15
Place: Foshan
Desc: set user school.
use the lib:
------------------------------------------------------------
local MySchool = NPL.load('(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua')
MySchool:Show()
MySchool:ShowJoinSchool()
------------------------------------------------------------
]]

-- libs
local StringUtil = commonlib.gettable('mathlib.StringUtil')
local Screen = commonlib.gettable('System.Windows.Screen')

-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSchoolAndOrg = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

-- database
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local MySchool = NPL.export()
function MySchool:Show(callback)
    self.hasJoined = false
    self.hasSchoolJoined = false
    self.schoolData = {}
    self.orgData = {}
    self.allData = {}
    self.callback = callback
    self.searchText = ''

    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 6)

    local params = Mod.WorldShare.Utils.ShowWindow(
                    600,
                    380,
                    '(ws)MySchool/Theme/MySchool.html',
                    'Mod.WorldShare.MySchool',
                    nil,
                    nil,
                    nil,
                    false,
                    1,
                    true
                   )

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        Mod.WorldShare.MsgBox:Close()

        self.hasJoined = false
        if type(orgData) == 'table' and #orgData > 0 then
            self.hasJoined = true
        
            for key, item in ipairs(orgData) do
                if item and not item.fullname then
                    item.fullname = ''
                end
            end

            for key, item in ipairs(orgData) do
                if item and item.type == 4 then
                    self.hasSchoolJoined = true
                    break
                end
            end
        end

        for key, item in ipairs(orgData) do
            if item.type ~= 4 then
                -- org data
                self.orgData[#self.orgData + 1] = item
            end

            if item.type == 4 then
                -- school data
                item.originName = item.name
                item.name = (item.schoolId or '') .. ' ' .. item.name
                self.schoolData[#self.schoolData + 1] = item
            end
        end

        if self.schoolData and #self.schoolData > 0 then
            self.allData[#self.allData + 1] = {
                element_type = 1,
                title = 'Texture/Aries/Creator/keepwork/my_school_32bits.png#6 31 85 18'
            }
    
            for key, item in ipairs(self.schoolData) do
                item.element_type = 2
                self.allData[#self.allData + 1] = item
            end
        end

        if self.orgData and #self.orgData > 0 then
            self.allData[#self.allData + 1] = {
                element_type = 1,
                title = 'Texture/Aries/Creator/keepwork/my_school_32bits.png#6 7 85 18'
            }
    
            for key, item in ipairs(self.orgData) do
                item.element_type = 2
                self.allData[#self.allData + 1] = item
            end
        end

        params._page:Refresh(0.01)
    end)
end

function MySchool:ShowJoinSchool(callback, mode)
    self.provinces = {
        {
            text = L'省',
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L'市',
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L'区（县、镇、街道）',
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L'学校类型',
            value = 0,
            selected = true,
        },
        {
            text = L'小学',
            value = L'小学'
        },
        {
            text = L'中学',
            value = L'中学'
        },
        {
            text = L'大学',
            value = L'大学',
        },
        {
            text = L'综合',
            value = L'综合',
        }
    }

    self:SetResult({})

    self.curId = 0
    self.kind = nil
    self.joinSchoolCallback = callback

    self.SetDefault = true
    local params = Mod.WorldShare.Utils.ShowWindow(
        {
            url = 'Mod/WorldShare/cellar/MySchool/Theme/JoinSchool.html?mode=' .. (mode or ''),
            name = 'Mod.WorldShare.JoinSchool',
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 1,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = '_fi',
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            cancelShowAnimation = true,
            bToggleShowHide = true,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
        }
    )

    local resultPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchool.Result')

    params._page:CallMethod('province_list_datasource', 'SetDataSource', self.provinces)
    params._page:CallMethod('province_list_datasource', 'DataBind')

    self:GetProvinces(function(data)
        if type(data) ~= 'table' then
            return false
        end

        self.provinces = data

        params._page:CallMethod('province_list_datasource', 'SetDataSource', self.provinces)
        params._page:CallMethod('province_list_datasource', 'DataBind')

        local region = Mod.WorldShare.Store:Get('user/region')

        if region and type(region) == 'table' and region.info then
            -- set privince field
            if self.provinces and type(self.provinces) == 'table' then
                for key, item in ipairs(self.provinces) do
                    item.selected = nil

                    if item.id == region.info.state.id then
                        item.selected = true
                        params._page:SetUIValue('province', item.text)
                        local province_node =  params._page:FindControl('province_bg')
                        local bg = 'Texture/Aries/Creator/paracraft/my_school_32bits.png#53 241 48 70:16 16 16 16'
                        local function set_default(node)
                            if node then
                                node.background = bg
                            end
                        end
                        set_default(province_node)
                    end
                end
            end

            -- set city field
            self:GetCities(region.info.state.id, function(data)
                self.cities = data

                params._page:CallMethod('city_list_datasource', 'SetDataSource', self.cities)
                params._page:CallMethod('city_list_datasource', 'DataBind')

                if self.cities and
                    type(self.cities) == 'table' and
                    region.info.city and
                    region.info.city.id then
                    for key, item in ipairs(self.cities) do
                        item.selected = nil
                        
                        if item.id == region.info.city.id then
                            item.selected = true
                            params._page:SetUIValue('city', item.text)
                            local city_node =  params._page:FindControl('city_bg')
                            local bg = 'Texture/Aries/Creator/paracraft/my_school_32bits.png#53 241 48 70:16 16 16 16'
                            local function set_default(node)
                                if node then
                                    node.background = bg
                                end
                            end
                            set_default(city_node)
                        end
                    end
                end

                self:GetAreas(region.info.city.id, function(data)
                    self.areas = data

                    params._page:CallMethod('area_list_datasource', 'SetDataSource', self.areas)
                    params._page:CallMethod('area_list_datasource', 'DataBind')

                    self.curId = region.info.city.id
                    self.lastCityId = region.info.city.id

                    local lastSchoolId = SessionsData:GetAnonymousInfo().lastSchoolId or 0

                    if false then --lastSchoolId and type(lastSchoolId) == 'number' and lastSchoolId ~= 0
                        params._page:SetValue('search_text', lastSchoolId)

                        self.searchText = tostring(lastSchoolId)

                        self:GetSearchSchoolResultByName(self.searchText, function()
                            resultPage:GetNode('school_list'):SetUIAttribute('DataSource', self.result)
                        end)
                    else
                        self:GetSearchSchoolResult(region.info.city.id, nil, function()
                            resultPage:GetNode('school_list'):SetUIAttribute('DataSource', self.result)
                        end)
                    end
                    if not self.Inited then
                        self.Inited = true
                    end
                    GameLogic.GetFilters():apply_filters("showSchoolResult");
                end)
            end)
        end
    end)

    if resultPage then
        resultPage:GetNode('school_list'):SetUIAttribute('DataSource', {})
    end

    Screen:Connect('sizeChanged', MySchool, MySchool.OnScreenSizeChange, 'UniqueConnection')

    params._page.OnClose = function()
        Screen:Disconnect('sizeChanged', MySchool, MySchool.OnScreenSizeChange)
    end
end

function MySchool.OnScreenSizeChange()
    local joinSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchool')

    if joinSchoolPage then
        joinSchoolPage:CloseWindow()
    end

    MySchool:ShowJoinSchool()
end

function MySchool:ShowJoinSchoolAfterRegister(callback)
    self.provinces = {
        {
            text = L'省',
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L'市',
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L'区（县、镇、街道）',
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L'学校类型',
            value = 0,
            selected = true,
        },
        {
            text = L'小学',
            value = L'小学'
        },
        {
            text = L'中学',
            value = L'中学'
        },
        {
            text = L'大学',
            value = L'大学',
        },
        {
            text = L'综合',
            value = L'综合',
        }
    }

    self:SetResult({})

    self.curId = 0
    self.kind = nil
    self.joinSchoolCallback = callback

    local params1 = Mod.WorldShare.Utils.ShowWindow(
                        600,
                        420,
                        '(ws)MySchool/Theme/JoinSchoolAfterRegister.html',
                        'Mod.WorldShare.JoinSchoolAfterRegister',
                        nil,
                        nil,
                        nil,
                        false,
                        1
                    )
    local params2 = Mod.WorldShare.Utils.ShowWindow(
                        442,
                        100,
                        '(ws)MySchool/Theme/JoinSchoolResult.html',
                        'Mod.WorldShare.JoinSchoolResult',
                        nil,
                        20,
                        nil,
                        false,
                        2
                    )

    self:GetProvinces(function(data)
        if type(data) ~= 'table' then
            return false
        end

        self.provinces = data

        self:RefreshJoinSchool()
    end)

    params1._page.OnClose = function()
        if params2._page then
            params2._page:CloseWindow()
        end
    end
end

function MySchool:RefreshJoinSchool()
    local JoinSchoolPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchool')
    local JoinSchoolAfterRegisterPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchoolAfterRegister')

    if JoinSchoolPage then
        JoinSchoolPage:Refresh(0.01)

        local JoinSchoolResultPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchoolResult')

        if JoinSchoolResultPage then
            JoinSchoolResultPage:Refresh(0.01)
        end
    end

    if JoinSchoolAfterRegisterPage then
        JoinSchoolAfterRegisterPage:Refresh(0.01)

        local JoinSchoolResultPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.JoinSchoolResult')

        if JoinSchoolResultPage then
            JoinSchoolResultPage:Refresh(0.01)
        end
    end
end

function MySchool:ShowJoinInstitute()
    local params = Mod.WorldShare.Utils.ShowWindow(
                    600,
                    243,
                    '(ws)MySchool/Theme/JoinInstitute.html',
                    'Mod.WorldShare.JoinInstitute',
                    nil,
                    nil,
                    nil,
                    false,
                    1,
                    true
                   )
end

function MySchool:ShowRecordSchool()
    self.provinces = {
        {
            text = L'省',
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L'市',
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L'区（县、镇、街道）',
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L'学校类型',
            value = 0,
            selected = true,
        },
        {
            text = L'小学',
            value = L'小学'
        },
        {
            text = L'中学',
            value = L'中学'
        },
        {
            text = L'大学',
            value = L'大学',
        },
        {
            text = L'综合',
            value = L'综合',
        }
    }

    self.curId = 0
    self.kind = nil

    local params = Mod.WorldShare.Utils.ShowWindow(
                    600,
                    300,
                    '(ws)MySchool/Theme/RecordSchool.html',
                    'Mod.WorldShare.RecordSchool'
                   )

    self:GetProvinces(function(data)
        if type(data) ~= 'table' then
            return false
        end

        self.provinces = data

        params._page:Refresh(0.01)
    end)
end

function MySchool:GetProvinces(callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion('province', nil, function(data)
        if type(data) ~= 'table' then
            return false
        end

        if type(callback) == 'function' then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L'省',
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetCities(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion('city', id, function(data)
        if type(data) ~= 'table' then
            return false
        end

        if type(callback) == 'function' then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L'市',
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetAreas(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion('area', id, function(data)
        if type(data) ~= 'table' then
            return false
        end

        if type(callback) == 'function' then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L'区（县、镇、街道）',
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetSearchSchoolResult(id, kind, callback)
    KeepworkServiceSchoolAndOrg:SearchSchool(id, kind, function(data)
        self:SetResult(data)

        for key, item in ipairs(self.result) do
            item.text = item.name
            item.value = item.id
        end

        if callback and type(callback) == 'function' then
            callback(self.result)
        end
    end)
end

function MySchool:GetSearchSchoolResultByName(name, callback)
    if not name or type(name) ~= 'string' or #name == 0 then
        if callback and type(callback) == 'function' then
            self:SetResult({})

            callback()
        end

        return false
    end

    -- trim white space
    name = StringUtil.trim(name)

    if type(tonumber(name)) == 'number' then
        KeepworkServiceSchoolAndOrg:SearchSchoolBySchoolId(tonumber(name), function(data)
            self:SetResult(data)

            for key, item in ipairs(self.result) do
                item.text = item.name or ''
                item.value = item.id
            end
    
            if callback and type(callback) == 'function' then
                callback(self.result)
            end
        end)

        return
    end
    
    KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, self.curId, self.kind, function(data)
        self:SetResult(data)

        for key, item in ipairs(self.result) do
            item.text = item.name or ''
            item.value = item.id
        end

        if callback and type(callback) == 'function' then
            if #self.result==0 and self.curId~=0 then
                KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, 0, self.kind, function(data) --找不到的情况下，不区分地域再找一次
                    self:SetResult(data)
            
                    for key, item in ipairs(self.result) do
                        item.text = item.name or ''
                        item.value = item.id
                    end
            
                    if callback and type(callback) == 'function' then
                        callback(self.result)
                    end
                end)
            else
                callback(self.result)
            end
        end
    end)
end

function MySchool:ChangeSchool(schoolId, callback)
    KeepworkServiceSchoolAndOrg:ChangeSchool(schoolId, callback)
end

function MySchool:JoinInstitute(code, callback)
    KeepworkServiceSchoolAndOrg:JoinInstitute(code, callback)
end

function MySchool:RecordSchool(schoolType, regionId, schoolName, callback)
    KeepworkServiceSchoolAndOrg:SchoolRegister(schoolType, regionId, schoolName, callback)
end

function MySchool:SetResult(data)
    self.result = data
    if self.result and type(self.result) == 'table' then
        -- find out same school name
        for aKey, aItem in ipairs(self.result) do
            local sameName = false

            for bKey, bItem in ipairs(self.result) do
                if aItem.id ~= bItem.id and aItem.name == bItem.name then
                    sameName = true
                    break
                end
            end

            if sameName then
                aItem.sameName = true
            end
        end

        for key, item in ipairs(self.result) do
            item.regionString = ''
            item.hasRegion = true
            if item and item.name then
                item.originName = item.name
                if item and item.status and item.status == 0 then
                    item.name = item.name .. L'（审核中）'
                end
            end

            if item and item.region and item.sameName then
                local regionString = ''

                -- if item.region.country and item.region.country.name then
                --     regionString = regionString .. item.region.country.name
                -- end

                if item.region.state and item.region.state.name then
                    regionString = regionString .. item.region.state.name
                end

                if item.region.city and item.region.city.name then
                    regionString = regionString .. item.region.city.name
                end

                if item.region.county and item.region.county.name then
                    regionString = regionString .. item.region.county.name
                end

                regionString = '(' .. regionString .. ')'
                item.regionString  = regionString

                -- item.name = item.name .. regionString
            end

            -- add id
            if item and item.id and item.name then
                item.name = item.id .. ' ' .. item.name
            end
        end
    end
end

function MySchool:OpenTeachingPlanCenter(orgUrl)
    if not orgUrl or type(orgUrl) ~= 'string' then
        return false
    end

    KeepworkServiceSession:SetUserLevels(nil, function()
        local userType = Mod.WorldShare.Store:Get('user/userType')

        if not userType or type(userType) ~= 'table' then
            return false
        end

        if userType.orgAdmin then
            local url = '/org/' .. orgUrl .. '/admin/packages'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end

        if userType.teacher then
            local url = '/org/' .. orgUrl .. '/teacher/teach'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end

        if userType.student or userType.freeStudent then
            local url = '/org/' .. orgUrl .. '/student'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end
    end)
end

