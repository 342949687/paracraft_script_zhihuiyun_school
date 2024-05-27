--[[
Title: Toast Component
Author(s): big
CreateDate: 2019.01.26
ModifyDate: 2021.09.28
Place: Foshan
use the lib:
------------------------------------------------------------
local Toast = NPL.load('(gl)Mod/ExplorerApp/pages/Toast/Toast.lua')
------------------------------------------------------------
]]

local Toast = NPL.export()

Toast.msg = ''
Toast.allPreviousMsg = {}

function Toast:ShowPage(msg, nTimes)
    local index = #self.allPreviousMsg + 1
    local ToastPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.Toast')

    if ToastPage then
        self:ClosePage()

        if #self.allPreviousMsg > 0 then
            self.allPreviousMsg[#self.allPreviousMsg] = false
        end
    end

    self.allPreviousMsg[index] = true
    self.msg = msg

    local params = Mod.WorldShare.Utils.ShowWindow(
        300,
        32,
        'Mod/ExplorerApp/pages/Toast/Toast.html',
        'Mod.ExplorerApp.Toast',
        nil,
        nil,
        '_ct',
        false,
        3
    )

    Mod.WorldShare.Utils.SetTimeOut(
        function()
            if self.allPreviousMsg[index] then
                self:ClosePage()
                self.allPreviousMsg = {}
            end
        end,
        nTimes or 5000
    )
end

function Toast:ClosePage()
    local ToastPage = Mod.WorldShare.Store:Get('page/Mod.ExplorerApp.Toast')

    if ToastPage then
        ToastPage:CloseWindow()
    end
end