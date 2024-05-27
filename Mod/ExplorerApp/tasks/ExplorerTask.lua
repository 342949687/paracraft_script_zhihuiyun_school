--[[
Title: Explorer Task
Author(s):  big
Date:  201
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ExplorerApp/tasks/ExplorerTask.lua")
local ExplorerTask = commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/PlayContext.lua")

local PlayContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.PlayContext")

local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext")

local ExplorerTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask"))
local ProactiveEnd = NPL.load("(gl)Mod/ExplorerApp/pages/GameProcess/ProactiveEnd/ProactiveEnd.lua")

function ExplorerTask:keyPressEvent(event)
end

function ExplorerTask:EnableAutoCamera(bEnable)
	if not self.sceneContext or not self.sceneContext.EnableAutoCamera then
		return false
	end

	self.sceneContext:EnableAutoCamera(bEnable)
end

function ExplorerTask:Run()
	self:LoadSceneContext()
	ExplorerTask._super.Run(self)
end