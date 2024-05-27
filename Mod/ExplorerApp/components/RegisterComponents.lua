--[[
Title: Register Components
Author(s): big
CreateDate: 2021.12.2
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local RegisterComponents = NPL.load('(gl)Mod/ExplorerApp/components/RegisterComponents.lua')
------------------------------------------------------------
]]

-- include components
local ParacraftWorldComponent = NPL.load('(gl)Mod/ExplorerApp/components/ParacraftWorld/ParacraftWorldComponent.lua')
local MenuItemComponent = NPL.load('(gl)Mod/ExplorerApp/components/MenuItem/MenuItemComponent.lua')

local RegisterComponents = NPL.export()

function RegisterComponents:Install()
    Map3DSystem.mcml_controls.RegisterUserControl('pe:paracraft_world', ParacraftWorldComponent)
    Map3DSystem.mcml_controls.RegisterUserControl('pe:menu_item', MenuItemComponent)
end

function RegisterComponents:Uninstall()
    Map3DSystem.mcml_controls.UnRegisterUserControl('pe:paracraft_world')
    Map3DSystem.mcml_controls.UnRegisterUserControl('pe:menu_item')

    ParacraftWorldComponent.xmlRoot = nil
    MenuItemComponent:ClearAllSelectedItems()
end