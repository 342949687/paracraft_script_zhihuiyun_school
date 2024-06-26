--[[
Title: world share command
Author(s): big
Date: 2020/9/25
Desc: 
use the lib:
------------------------------------------------------------
local WorldShareCommand = NPL.load("(gl)Mod/WorldShare/command/Command.lua")
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")

-- command
local MenuCommand = NPL.load("(gl)Mod/WorldShare/command/Menu.lua")
local PipeCommand = NPL.load("(gl)Mod/WorldShare/command/Pipe.lua")
local LoadWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadWorld.lua")
local LoadPersonalWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadPersonalWorld.lua")
local LoadReadOnlyWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadReadOnlyWorld.lua")
local ReloadWorldCommand = NPL.load("(gl)Mod/WorldShare/command/ReloadWorld.lua")
local CreateWorldCommand = NPL.load('(gl)Mod/WorldShare/command/CreateWorldCommand.lua')

local WorldShareCommand = NPL.export()

WorldShareCommand.afterLoadWorldCommands = {}

function WorldShareCommand:Init()
    if self.inited then
        return
    end

    self.inited = true

    MenuCommand:Init()
    LoadWorldCommand:Init()
    local pipe = PipeCommand:Init()
    local loadpersonalworld = LoadPersonalWorldCommand:Init()
    local loadreadonlyworld = LoadReadOnlyWorldCommand:Init()
    local reload = ReloadWorldCommand:Init()
    local createworld = CreateWorldCommand:Init()

    GameLogic.GetFilters():add_filter("register_command", function(_, SlashCommand)
        SlashCommand:RegisterSlashCommand(pipe)
        SlashCommand:RegisterSlashCommand(loadpersonalworld)
        SlashCommand:RegisterSlashCommand(loadreadonlyworld)
        SlashCommand:RegisterSlashCommand(reload)
        SlashCommand:RegisterSlashCommand(createworld)
        SlashCommand:RegisterSlashCommand(self:MacroRecordCommand())
    end)
end

function WorldShareCommand:PushAfterLoadWorldCommand(command)
    self.afterLoadWorldCommands[#self.afterLoadWorldCommands + 1] = command
end

function WorldShareCommand:PopAfterLoadWorldCommand()
    self.afterLoadWorldCommands[#self.afterLoadWorldCommands] = nil
end

function WorldShareCommand:ExecAfterLoadWorldCommands()
    local beExist = true

    while beExist do
        if #self.afterLoadWorldCommands > 0 then
            GameLogic.RunCommand(self.afterLoadWorldCommands[#self.afterLoadWorldCommands])
            self:PopAfterLoadWorldCommand()
        else
            beExist = false
        end
    end
end

function WorldShareCommand:OnWorldLoad()
    -- Mod.WorldShare.Utils.SetTimeOut(function()
    --     self:ExecAfterLoadWorldCommands()
    -- end, 1000)
end

function WorldShareCommand:MacroRecordCommand()
    local macro_record = {
        name='macrorecord', 
        quick_ref='/macrorecord', 
        desc=[[]],
        mode_deny = "",
        handler = function(cmd_name, cmd_text, cmd_params)
            GameLogic.Macros.SetRecordMode(true)
            GameLogic.Macros.SetHelpLevel()
        end,
    }

    Commands['macrorecord'] = macro_record

    return macro_record
end
