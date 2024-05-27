--[[
Title: World Item Component
Author(s): big
CreateDate: 2021.11.17
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local ParacraftWorldComponent = NPL.load('(gl)Mod/ExplorerApp/components/ParacraftWorld/ParacraftWorldComponent.lua')
------------------------------------------------------------
]]

local ParacraftWorldComponent = NPL.export()

local self = ParacraftWorldComponent

function ParacraftWorldComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    self.width = width
    self.height = height
    self.parentLayout = parentLayout

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

function ParacraftWorldComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local xmlRoot

    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('Mod/ExplorerApp/components/ParacraftWorld/ParacraftWorldComponent.html')
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)
    local ParacraftWorldComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')

    ParacraftWorldComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    local ParacraftWorld = Map3DSystem.mcml_controls.create(
        'paracraft_world',
        ParacraftWorldComponentMcmlNode,
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

