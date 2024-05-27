--[[
Title: lesson store
Author(s):  big
Date:  2018.11.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ExplorerStore/store/ExplorerStore.lua")
local ExplorerStore = commonlib.gettable('Mod.ExplorerApp.store.Explorer')
------------------------------------------------------------
]]

local ExplorerStore = NPL.export()

function ExplorerStore:Action(data)
    self = data

    return {}
end

function ExplorerStore:Getter(data)
    self = data

    return {}
end