--[[
Title: MallOtherPage
Author(s):  pbb
CreateDate: 2023.12.6
Desc:
Use Lib:
-------------------------------------------------------
local MallOtherPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallOtherPage.lua");
MallOtherPage.Show("collete");
--]]

--Lib
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");
--Page
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local MallOtherPage = NPL.export()

local pageNum = 40;
MallOtherPage.data_hits = {}
MallOtherPage.data_count = 0


--updatedAt-desc、updatedAt-asc、mProduct.name-asc、mProduct.useCount-asc
local defaultSort = {
    {name=L"名称", value="mProduct.namePinyin" ,sort_type=-1},
    {name=L"使用量", value="mProduct.useCount" ,sort_type=-1},
    {name=L"更新时间", value="updatedAt" ,sort_type=-1}
}
MallOtherPage.sort_data = defaultSort
MallOtherPage.sort_select_index = -1
MallOtherPage.sort_select_type = -1 --0,asc-》顺序；1，desc-》降序
MallOtherPage.do_modify = false
MallOtherPage.ShowEditData = nil
local page
MallOtherPage.type = ""
-- MallOtherPage.IsInited = false
function MallOtherPage.OnInit(page_type)
    page = document:GetPageCtrl();
    -- if (MallOtherPage.IsInited) then
    --     return;
    -- end
    if MallOtherPage.type ~= page_type then
        MallOtherPage.type = page_type
        MallOtherPage.dataLoaded = false
        MallOtherPage.curPage = 1
        MallOtherPage.sort_select_index = -1
        MallOtherPage.sort_select_type = -1
        MallOtherPage.data_hits = {}
        MallOtherPage.data_count = 0
        MallOtherPage.FilterSort()
        MallOtherPage.LoadMallList()
    end
end

function MallOtherPage.FilterSort()
    if MallOtherPage.type == "histroy" or MallOtherPage.type == "personnal" then
        MallOtherPage.sort_data = commonlib.filter(defaultSort,function(item)
            return item.value ~= "mProduct.useCount"
        end)
    else
        MallOtherPage.sort_data = defaultSort
    end
end

function MallOtherPage.Show(type)

    -- local ItemComponent = NPL.load('script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallComponent/ItemComponent.lua');
    -- Map3DSystem.mcml_controls.RegisterUserControl('pe:keepwork_mall_item', ItemComponent)
    MallOtherPage.dataLoaded = false
    MallOtherPage.curPage = 1
    MallOtherPage.data_count = 0
    MallOtherPage.data_hits = {}
    local params = {
        url = "script/apps/Aries/Creator/Game/KeepWorkMall/MallOtherPage.html",
        name = "MallOtherPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        isTopLevel = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };

    System.App.Commands.Call("File.MCMLWindowFrame", params);

    MallOtherPage.LoadMallList()
end

function MallOtherPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function MallOtherPage.OnChangeSort(name)
    local index = tonumber(name)
    if index and index > 0 then
        if MallOtherPage.sort_select_index ~= index then
            MallOtherPage.sort_select_index = index
            MallOtherPage.sort_select_type = 0
        else
            if MallOtherPage.sort_select_type == 0 then
                MallOtherPage.sort_select_type = 1
            else
                MallOtherPage.sort_select_type = 0
            end
        end
        MallOtherPage.lastLoadIndex = 0
        MallOtherPage.dataLoaded = false
        MallOtherPage.curPage = 1
        MallOtherPage.data_hits = {}
        MallOtherPage.data_count = 0
        MallOtherPage.LoadMallList()
        MallOtherPage.RefreshPage()
    end
end

function MallOtherPage.GetSortData()
    local isSort = MallOtherPage.sort_select_index > 0 and MallOtherPage.sort_select_type >= 0    
    local sortType
    if isSort then
        sortType = MallOtherPage.sort_select_type == 0 and "asc" or "desc"
    end

    local sortName
    if isSort then
        sortName = MallOtherPage.sort_data[MallOtherPage.sort_select_index].value or ""
    end
    return sortName, sortType
end

function MallOtherPage.LoadMallList()
    MallOtherPage.do_modify = false
    MallOtherPage.ShowEditData = nil
    local sortName, sortType = MallOtherPage.GetSortData()
    print("LoadMallList=========",sortName, sortType)
    if MallOtherPage.type == "collect" then
        if MallOtherPage.SearchText and MallOtherPage.SearchText ~= "" then
            MallOtherPage.OnSearchGood(MallOtherPage.SearchText)
            return 
        end
        MallOtherPage.LoadCollectList(sortName,sortType)
    elseif MallOtherPage.type == "histroy" then
        MallOtherPage.LoadHistroyList(sortName,sortType)
    elseif MallOtherPage.type == "personnal" then
        MallOtherPage.LoadPersonalList(sortName,sortType)
    
    end
end

function MallOtherPage.LoadCollectList(sortName,sortType,keyword)
    local dataNum = #MallOtherPage.data_hits
    if MallOtherPage.data_count == 0 or dataNum < MallOtherPage.data_count then
        print("LoadCollectList=============",sortName,sortType,MallOtherPage.data_count)
        MallManager.getInstance():LoadCollectList(MallOtherPage.curPage,sortName,sortType,keyword,function(data,key)
            if not data then
                return
            end
            MallOtherPage.dataLoaded = true
            if MallOtherPage.data_count == 0 then
                MallOtherPage.data_count = data.count
            end
            if data and next(data.rows) ~= nil then
                for i,v in ipairs(data.rows) do
                    if v.mProduct then
                        table.insert(MallOtherPage.data_hits,v.mProduct)
                    end
                end
                MallOtherPage.HandleDataSources()
                -- print("==================================")
                -- echo(MallOtherPage.data_hits,true)
            else
            --    GameLogic.AddBBS(nil,"数据加载完毕")  
               MallOtherPage.FlushView(true)           
            end
            print("load collect===============")
            -- echo(MallOtherPage.data_hits,true)
        end)
        return
    end
    -- print("数据一加载完毕")
end

function MallOtherPage.LoadHistroyList(sortName,sortType,keyword)
    local data = MallManager.getInstance():GetMallHistory()
    -- echo(data,true)
    -- print("load histroy============",MallOtherPage.SearchText)
    if data and next(data) ~= nil then
        MallOtherPage.data_hits = data
        if sortName == "mProduct.namePinyin" then
            if sortType == "desc" then
                table.sort(MallOtherPage.data_hits, function(a,b)
                    local _,sp1 = MallUtils.GetPinyin(a["name"],true)
                    local _,sp2 = MallUtils.GetPinyin(b["name"],true)
                    if not sp1 or not sp2  then
                        return a["name"] > b["name"]
                    end
                    return sp1 > sp2
                end)
            else
                table.sort(MallOtherPage.data_hits, function(a,b)
                    local _,sp1 = MallUtils.GetPinyin(a["name"],true)
                    local _,sp2 = MallUtils.GetPinyin(b["name"],true)
                    if not sp1 or not sp2  then
                        return a["name"] < b["name"]
                    end
                    return sp1 < sp2
                end)
            end
        end
        if sortName == "updatedAt" then
            if sortType == "desc" then
                table.sort(MallOtherPage.data_hits, function(a,b)
                    return commonlib.timehelp.GetTimeStampByDateTime(a["updatedAt"]) > commonlib.timehelp.GetTimeStampByDateTime(b["updatedAt"])
                end)
            else
                table.sort(MallOtherPage.data_hits, function(a,b)
                    return commonlib.timehelp.GetTimeStampByDateTime(a["updatedAt"]) < commonlib.timehelp.GetTimeStampByDateTime(b["updatedAt"])
                end)
            end
        end
        if MallOtherPage.SearchText and MallOtherPage.SearchText ~= "" then
            MallOtherPage.data_hits = commonlib.filter(MallOtherPage.data_hits, function(item)
                return (item["name"] and item["name"]:lower():find(MallOtherPage.SearchText:lower()))
                    or (item["id"] and item["id"] == tonumber(MallOtherPage.SearchText))
            end)
        end
        -- echo(MallOtherPage.data_hits,true)
        MallOtherPage.data_count = #MallOtherPage.data_hits
        MallOtherPage.dataLoaded = true
        MallOtherPage.HandleDataSources()
        if MallOtherPage.data_count == 0 then
            MallOtherPage.FlushView(true)
        end
    end
end

function MallOtherPage.LoadPersonalList(sortName,sortType)
    local dataNum = #MallOtherPage.data_hits
    if MallOtherPage.data_count == 0 or dataNum < MallOtherPage.data_count then
        local keyword = (MallOtherPage.SearchText and MallOtherPage.SearchText ~= "") and MallOtherPage.SearchText or nil
        print("LoadPersonalList==============",MallOtherPage.curPage,sortName,sortType,keyword)
        MallManager.getInstance():LoadPersonalList(MallOtherPage.curPage,sortName,sortType,keyword,function(data)
            -- print("LoadPersonalList=============")
            -- echo(data,true)
            if not data then
                return
            end
            MallOtherPage.dataLoaded = true
            if MallOtherPage.data_count == 0 then
                MallOtherPage.data_count = data.count
            end
            if data.rows and #data.rows > 0 then
                for i,v in ipairs(data.rows) do
                    table.insert(MallOtherPage.data_hits,v)
                end
                MallOtherPage.HandleDataSources()

                -- echo(MallOtherPage.data_hits,true)
            else
                -- GameLogic.AddBBS(nil,"数据加载完毕")  
                MallOtherPage.FlushView(true)   
            end
        end)
    end
end

local icons = {
    stl = "Texture/Aries/Creator/keepwork/Mall1/stlicon_128x128_32bits.png",
    blocks = "Texture/Aries/Creator/keepwork/Mall1/template_icon_128x128_32bits.png",
}

function MallOtherPage.HandleDataSources()
    if not MallOtherPage.data_hits or next(MallOtherPage.data_hits) == nil then
        return
    end
    -- echo(MallOtherPage.data_hits,true)
    local count = 0
    for i,v in ipairs(MallOtherPage.data_hits) do
        v.name = commonlib.GetLimitLabel(v.name,20)
        v.useCount = tonumber(v.useCount) or 0

        v.isLink = v.method == 1  or (v.purchaseUrl ~= nil and v.purchaseUrl ~= "") --购买方式，0：内部购买；1：外部购买

        if MallOtherPage.type == "personnal" then
            if v.modelType == "stl" or v.modelType == "blocks" then
                v.icon = icons[v.modelType]
                v.bigIcon = true
            end
            v.isPublic = 1
        end

        v.hasIcon = v.icon ~= "" and v.icon ~= nil

        v.isLiveModel = v.modelType == "liveModel"
        v.hasPermission = MallUtils.CheckHasPermission(v)
        v.enabled = v.hasPermission
        v.vip_enabled = not v.hasPermission

       

        local modelUrl = v.modelUrl or ""
        local downloadUrl = v.modelUrl or ""
        v.isModelProduct = modelUrl ~= "" and modelUrl ~= nil

        if v.isModelProduct then
            v.modelType = (v.modelType and v.modelType~= "") and v.modelType or ""
        end

        v.needDownload = (downloadUrl~= nil and downloadUrl ~= "") and not downloadUrl:match("character/") and v.modelType ~= "blocks"
        if v.needDownload then
            count = count + 1
        end
    end

    if System.options.isHideVip then
        local preNum = #MallOtherPage.data_hits
        MallOtherPage.data_hits = commonlib.filter(MallOtherPage.data_hits, function (item)
            return item.isPublic == 1;
        end)

        local filterNum = #MallOtherPage.data_hits
        local curTotal = (MallOtherPage.data_count ~= 0) and MallOtherPage.data_count or filterNum
        local maxDataNum = math.min(pageNum,curTotal)
        if filterNum < maxDataNum then
            if MallOtherPage.SearchText and MallOtherPage.SearchText ~= "" then
                MallOtherPage.OnClickSearch(MallOtherPage.SearchText)
                return 
            end
            MallOtherPage.curPage = MallOtherPage.curPage + 1
            MallOtherPage.LoadMallList()
        end
    end

    local index = 1;
    local loadCount = 0;
    local loadFunc = nil;
    loadFunc = function (item_data)
        if index > #MallOtherPage.data_hits then
            MallOtherPage.FlushView(false);
            return;
        end

        index = index + 1;
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadCount = loadCount + 1
                if loadCount <= pageNum then
                    loadFunc(MallOtherPage.data_hits[index])
                else
                    MallOtherPage.FlushView(false)
                    commonlib.TimerManager.SetTimeout(function ()
                        MallOtherPage.LoadElseModel(index + 1)
                    end, 1000)
                end
                
            end)
        else
            loadFunc(MallOtherPage.data_hits[index])
        end
    end

    loadFunc(MallOtherPage.data_hits[index]);
end

function MallOtherPage.LoadElseModel(index)
    local loadFunc = nil
    loadFunc = function (item_data)
        if index > #MallOtherPage.data_hits then
            MallOtherPage.FlushView(false)
            return
        end
        index = index + 1
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadFunc(MallOtherPage.data_hits[index])
            end)
        else
            loadFunc(MallOtherPage.data_hits[index])
        end
    end
    loadFunc(MallOtherPage.data_hits[index])
end

function MallOtherPage.LoadMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not MallOtherPage.data_hits) then
        return;
    end

    index = tonumber(index);
    local dataLength = #MallOtherPage.data_hits;

    if (index >= dataLength and index < MallOtherPage.data_count) then
        if MallOtherPage.lastLoadIndex ~= index then
            MallOtherPage.lastLoadIndex = index;
            MallOtherPage.curPage = MallOtherPage.curPage + 1
            if MallOtherPage.SearchText and MallOtherPage.SearchText ~= "" then
                MallOtherPage.OnClickSearch(MallOtherPage.SearchText)
                return 
            end
            MallOtherPage.LoadMallList()
        end
    end
end

function MallOtherPage.FlushView(only_refresh_grid)
    if only_refresh_grid then
        local gvw_name = "item_gridview";
        local node = page:GetNode(gvw_name);
        pe_gridview.DataBind(node, gvw_name, false);
    else
        MallOtherPage.RefreshPage()
    end
end

function MallOtherPage.OnMouseWheel()
    if (not page) then
        return;
    end
    MallOtherPage.HideAllOperateCtrl()
    local itemGrideViewNode = page:GetNode("item_gridview");
    local curLine = 0;

    if (itemGrideViewNode) then
        if (itemGrideViewNode:GetChild('pe:treeview') and
            itemGrideViewNode:GetChild('pe:treeview').control) then
            local control = itemGrideViewNode:GetChild('pe:treeview').control;

            if control then
                curLine = math.ceil(control.ClientY / 180);
            end
        end
    end

    local lineCount = 6;
    local startLine = curLine * lineCount - (lineCount - 1);
    local startIndex;
    local endIndex;

    if (startLine - lineCount) > 0 then
        startIndex = startLine - lineCount;
        endIndex = startIndex + (lineCount * 6 - 1);
    else
        startIndex = startLine
        endIndex = startIndex + (lineCount * 5 - 1);
    end
    
    for key, item in ipairs(MallOtherPage.data_hits) do
        if (key < startIndex or key > endIndex) then
            if (item and item.icon and item.icon ~= "") then
                ParaAsset.LoadTexture('', item.icon, 1):UnloadAsset()
            end

            if (item and item.modelUrl and item.modelUrl ~= "") then
                ParaAsset.LoadTexture('', item.modelUrl, 1):UnloadAsset()
            end
            -- if (item and item.tooltip and item.tooltip ~= "") then
            --     ParaAsset.LoadParaX("", Files.GetTempPath()..item.tooltip):UnloadAsset();
            -- end
        end
    end
end

function MallOtherPage:CheckIsCollected(item)
    if not item or type(item) ~= "table" then
        return false
    end
    local id = item.id
    if id and id > 0 then
        return MallManager.getInstance():CheckIsCollected(id)
    end

    return false
end

function MallOtherPage.OnClickCollect(data)
    if MallOtherPage.type == "personnal" then
        return
    end
    -- print("OnClickCollect-===============")
    -- echo(data,true)
    MallManager.getInstance():CollectMallGood(data and data.id,function(result)
        if not result then
            MallOtherPage.RefreshPage()
        end
    end)
    MallOtherPage.RefreshPage()
end

function MallOtherPage.OnClickItem(item_data)
    if not item_data then
        return
    end
    MallUtils.OnClickUseGood(item_data)
end

function MallOtherPage.OnClickSearch(search_text)
    if not MallOtherPage.SearchFunc then
        MallOtherPage.SearchFunc = commonlib.debounce(function(search_text)
            MallOtherPage.OnSearchGood(search_text)
        end,500)
    end
    MallOtherPage.SearchFunc(search_text)
end

function MallOtherPage.OnSearchGood(search_text)
    if MallOtherPage.type == "collect" then
        MallOtherPage.OnSearchCollect(search_text)
    elseif MallOtherPage.type == "histroy" then
        MallOtherPage.OnSearchHistory(search_text)
    elseif MallOtherPage.type == "personnal" then
        MallOtherPage.OnSearchPerssonal(search_text)
    end
end

function MallOtherPage.OnSearchCollect(search_text)
    if (not MallOtherPage.SearchText or MallOtherPage.SearchText == "") and (not search_text or search_text == "") then
        return
    end
    if MallOtherPage.SearchText ~= search_text then
        MallOtherPage.sort_select_index = -1
        MallOtherPage.sort_select_type = -1
        MallOtherPage.curPage = 1
        MallOtherPage.data_count = 0
        MallOtherPage.data_hits = {}
        MallOtherPage.SearchText = search_text
    else
        if MallOtherPage.data_count > 0 and MallOtherPage.data_count == #MallOtherPage.data_hits then
            return
        end
    end 
    local sortName, sortType = MallOtherPage.GetSortData()
    
    MallOtherPage.LoadCollectList(sortName,sortType,MallOtherPage.SearchText)
end

function MallOtherPage.OnSearchPerssonal(search_text)
    if MallOtherPage.SearchText ~= search_text then
        MallOtherPage.sort_select_index = -1
        MallOtherPage.sort_select_type = -1
        MallOtherPage.curPage = 1
        MallOtherPage.data_count = 0
        MallOtherPage.data_hits = {}
        MallOtherPage.SearchText = search_text
        MallOtherPage.LoadMallList()
    end
end

function MallOtherPage.OnSearchHistory(search_text)
    print("search===============",search_text)
    if MallOtherPage.SearchText ~= search_text then
        MallOtherPage.sort_select_index = -1
        MallOtherPage.sort_select_type = -1
        MallOtherPage.curPage = 1
        MallOtherPage.data_count = 0
        MallOtherPage.data_hits = {}
        MallOtherPage.SearchText = search_text
        MallOtherPage.LoadMallList()
    end
end

function MallOtherPage.HideAllOperateCtrl()
    if not MallOtherPage.ShowEditData then
        return 
    end
    if not MallOtherPage.data_hits or next(MallOtherPage.data_hits) == nil then
        return
    end
    MallOtherPage.HideOperateCtrl(MallOtherPage.ShowEditData)
    MallOtherPage.ShowEditData = nil
    -- for k, v in pairs(MallOtherPage.data_hits) do
    --     MallOtherPage.HideOperateCtrl(v)
    -- end
end

function MallOtherPage.ShowOperateCtrl(data)
    if MallOtherPage.type ~= "personnal" or not data or next(data) == nil then
        return
    end
    local id = data.id or ""
    local name = data.name or ""
    local uiname = "MallOtherPage.operate."..id..name
    local operateCtrl = ParaUI.GetUIObject(uiname)
    if operateCtrl and operateCtrl:IsValid() then
        operateCtrl.visible = not operateCtrl.visible
    end
end

function MallOtherPage.HideOperateCtrl(data)
    if MallOtherPage.type ~= "personnal" or not data or next(data) == nil then
        return
    end
    local id = data.id or ""
    local name = data.name or ""
    local uiname = "MallOtherPage.operate."..id..name
    local operateCtrl = ParaUI.GetUIObject(uiname)
    if operateCtrl and operateCtrl:IsValid() then
        operateCtrl.visible = false
    end
end


function MallOtherPage.IsSameDt(data1,data2)
    return data1 and data2 and data1.id and data2.id and data1.id == data2.id
end

function MallOtherPage.OnClickEdit(data)
    if MallOtherPage.IsSameDt(MallOtherPage.ShowEditData,data) then
        MallOtherPage.ShowOperateCtrl(data)
        MallOtherPage.ShowEditData = nil
        return
    end
    MallOtherPage.HideOperateCtrl(MallOtherPage.ShowEditData)
    MallOtherPage.ShowEditData = data
    MallOtherPage.ShowOperateCtrl(MallOtherPage.ShowEditData)
end

function MallOtherPage.RemoveModelData(data)
    if not data then
        return
    end
    local removeIndex
    for i,v in ipairs(MallOtherPage.data_hits) do
        if v.id == data.id then
            removeIndex = i
            break
        end
    end
    if removeIndex then
        table.remove(MallOtherPage.data_hits,removeIndex)
    end
end

function MallOtherPage.RenameModelData(data)
    if not data then
        return
    end
    local removeIndex
    for i,v in ipairs(MallOtherPage.data_hits) do
        if v.id == data.id then
            v.name = data.name
            break
        end
    end
end

function MallOtherPage.OnClickDeleteModel(data)
    if not data or next(data) == nil then
        return
    end
    MallOtherPage.HideOperateCtrl(data)
    local model_id = data.id
    MallManager.getInstance():DeleteModel(model_id,function(result)
        if result then
            MallOtherPage.data_count = MallOtherPage.data_count - 1
            MallOtherPage.data_count = math.max(0,MallOtherPage.data_count)
            MallOtherPage.RemoveModelData(data)
            MallOtherPage.ShowEditData = nil
            MallOtherPage.do_modify = false
            MallOtherPage.FlushView(true)
        end
    end)
end

function MallOtherPage.GetCurEditCtrl()
    if not MallOtherPage.ShowEditData or not page then
        return 
    end
    local model_id = MallOtherPage.ShowEditData.id
    local name = MallOtherPage.ShowEditData.name
    local ctrl_name = "rename_"..model_id.."_"..name
    local uiname = "MallOtherPage."..ctrl_name
    local ctrlEdit = page:FindControl(ctrl_name)
    local objEdit = ParaUI.GetUIObject(uiname)
    return objEdit
end

function MallOtherPage.OnClickUpdateModel(data)
    if not data or next(data) == nil then
        return
    end
    MallOtherPage.HideOperateCtrl(data)
    MallOtherPage.do_modify = true
    MallOtherPage.FlushView(true)
    local objEdit = MallOtherPage.GetCurEditCtrl()
    if objEdit and objEdit:IsValid() then
        objEdit:Focus()
        objEdit:SetCaretPosition(-1)
    end
end

function MallOtherPage.IsSelected(id)
    return MallOtherPage.ShowEditData and id and MallOtherPage.ShowEditData.id == id
end

function MallOtherPage.OnRenameFocusOut()
    local objEdit = MallOtherPage.GetCurEditCtrl()
    MallOtherPage.do_modify = false
    if objEdit and objEdit:IsValid() then
        local text = objEdit.text
        if not text or text == "" then
            MallOtherPage.ShowEditData = nil
            MallOtherPage.FlushView(true)
            GameLogic.AddBBS(nil,L"请输入正确的模型名字")
            return
        end
        if MallOtherPage.ShowEditData.name == text then
            MallOtherPage.ShowEditData = nil
            MallOtherPage.FlushView(true)
            return
        end

        local textNum = commonlib.GetUnicodeCharNum(text)
        if textNum > 20 then
            text = commonlib.GetLimitLabel(text,20,true)
            GameLogic.AddBBS(nil,L"你输入的模型名字过长，只保留前20位字符")
        end

        -- if BadWordFilter.HasBadWorld(text) then
		-- 	_guihelper.MessageBox(L"包含敏感词，请重新修改");
        --     MallOtherPage.ShowEditData = nil
        --     MallOtherPage.FlushView(true)
		-- 	return 
		-- end
        
        local model_id = MallOtherPage.ShowEditData.id
        local name = text
        MallManager.getInstance():UpdateModel(model_id,name,function(result)
            if result then
                MallOtherPage.ShowEditData.name = name
                MallOtherPage.RenameModelData(MallOtherPage.ShowEditData)
                MallOtherPage.ShowEditData = nil
                MallOtherPage.FlushView(true)
            end
        end)
        
    end
end

function MallOtherPage.OnRenameKeyUp()
    if(virtual_key and virtual_key == Event_Mapping.EM_KEY_RETURN) then
        MallOtherPage.OnRenameFocusOut()
    end 
end




