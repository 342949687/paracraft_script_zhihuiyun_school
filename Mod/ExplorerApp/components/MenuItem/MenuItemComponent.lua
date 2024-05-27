--[[
Title: Menu Item Component
Author(s): big
CreateDate: 2021.12.2
ModifyDate: 2021.12.6
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local MenuItemComponent = NPL.load('(gl)Mod/ExplorerApp/components/MenuItem/MenuItemComponent.lua')
------------------------------------------------------------
]]

local MenuItemComponent = NPL.export()

local self = MenuItemComponent

local selectedItem = commonlib.Array:new()
local selectedSubItem = 0

function MenuItemComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    self.width = width
    self.height = height
    self.parentLayout = parentLayout
    self.level = mcmlNode:GetAttributeWithCode('level')
    self.index = mcmlNode:GetAttributeWithCode('index')
    self.fullButton = mcmlNode:GetBool('full_button')
    self.isShowScrollBar = mcmlNode:GetAttributeWithCode('is_show_scroll_bar')
    self.children = mcmlNode:GetAttributeWithCode('children')

    return mcmlNode:DrawDisplayBlock(
            rootName,
            bindingContext,
            _parent,
            left,
            top,
            width,
            height,
            parentLayout,
            style,
            self.RenderCallback
           )
end

function MenuItemComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    if self.level and self.level > 1 then
        local curIndex = self.index

        local function Handle()
            if self:IsSelectedItem(curIndex) then
                for key, item in ipairs(selectedItem) do
                    if item == curIndex then
                        selectedItem:remove(key)
                        break
                    end
                end
            else
                selectedItem:push_back(curIndex)
            end

            mcmlNode:GetPageCtrl():Refresh(0.01)
        end

        if self.fullButton then
            local fullButton =
                ParaUI.CreateUIObject(
                    'button',
                    nil,
                    '_lt',
                    0,
                    0,
                    self.width - 10,
                    40
                )
    
            fullButton.background = ''
            fullButton.zorder = 1

            fullButton:SetScript('onclick', function()
                local onClickScript = mcmlNode:GetString('full_button_click')
                Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onClickScript, curIndex, mcmlNode)
                self:SetSelectedSubItem(0)
                Handle()
            end)

            _parent:AddChild(fullButton)
        end

        local button

        if self.isShowScrollBar then
            button =
                ParaUI.CreateUIObject(
                    'button',
                    nil,
                    '_rt',
                    -35,
                    16,
                    14,
                    8
                )
        else
            button =
                ParaUI.CreateUIObject(
                    'button',
                    nil,
                    '_rt',
                    -50,
                    16,
                    14,
                    8
                )
        end

    
        button.background = 'Texture/Aries/Creator/keepwork/rank/btn_qiehuan2_14X8_32bits.png#0 0 14 8'
        button.zorder = 2

        if self:IsSelectedItem(self.index) then
            button.rotation = 3.14
        end

        button:SetScript('onclick', function()
            local onClickScript = mcmlNode:GetString('full_button_click')
            Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onClickScript, curIndex, mcmlNode)
            self:SetSelectedSubItem(0)
            Handle()
        end)

        _parent:AddChild(button)
    end

    local xmlRoot

    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('Mod/ExplorerApp/components/MenuItem/MenuItemComponent.html')
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end

    if self.level and self.level > 1 then
        if self:IsSelectedItem(self.index) then
            local children = self.children or {}
            local childrenItems = {}

            for key, item in ipairs(children) do
                childrenItems[key] = {
                    {
                        attr = {
                            type = 'button',
                            onclick = 'select_category_by_id()',
                            name = item.id,
                            value = Mod.WorldShare.Utils.WordsLimit(item.tagname),
                            align = 'center',
                            width = '100%',
                            style = 'height: 35px;\
                                     color: #FFFFFF;\
                                     background: ""',
                        },
                        name = 'input'
                    },
                    attr = {
                        style = 'margin-top: 9px;\
                                 margin-bottom: -3px;'
                    },
                    name = 'div'
                }

                if selectedSubItem == item.id then
                    childrenItems[key][1].attr.style = 'height: 35px;\
                                                        color: #FCCE39;\
                                                        background: url(Texture/Aries/Creator/paracraft/ExplorerApp/anniudiban_24x24_32bits.png#0 0 24 24:7 7 7 7);'
                end
            end

            local containerHeight = #children * 41 + 10

            xmlRoot[1][1][#xmlRoot[1][1] + 1] = {
                [1] = childrenItems,
                attr = {
                    style='height: ' .. containerHeight .. 'px;\
                           width: 140px;\
                           margin-left: 4px;\
                           margin-top: -1px;\
                           margin-bottom: 8px;\
                           padding-left: 6px;\
                           padding-right: 6px;\
                           color: #FFFFFF;\
                           background: url(Texture/Aries/Creator/paracraft/ExplorerApp/diban_24x24_32bits.png#0 0 24 24:11 11 11 11);'
                },
                name='div'
            }
        end
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)    
    local MenuItemComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')
    MenuItemComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    local ParacraftWorld = Map3DSystem.mcml_controls.create(
        'menu_item',
        MenuItemComponentMcmlNode,
        nil,
        _parent,
        0,
        0,
        self.width,
        self.height,
        nil,
        self.parentLayout
    )
end

function MenuItemComponent:IsSelectedItem(index)
    for key, item in ipairs(selectedItem) do
        if item == index then
            return true
        end
    end

    return false
end

function MenuItemComponent:SetSelectedSubItem(id)
    selectedSubItem = id
end

function MenuItemComponent:ClearAllSelectedItems()
    selectedItem:clear()
    self.xmlRoot = nil
    selectedSubItem = 0
end

