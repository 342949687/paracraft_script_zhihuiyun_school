--[[
Title: Macro Tip
Author(s): LiXizhi
Date: 2021/1/7
Desc: tip macro

Use Lib:
-------------------------------------------------------
GameLogic.Macros.Tip("some mcml text here")
GameLogic.Macros.Broadcast("globalGameEvent")
GameLogic.Macros.Text("bottom line big text", 5000)
GameLogic.Macros.Text("bottom line big text", 5000, "center")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");

-- @param text: mcml text, if nil, it will remove the tip. 
function Macros.Tip(text)
	MacroPlayer.ShowTip(text)
end
Macros.tip = Macros.Tip;

-- @param msg: global message name, same as /sendevent msg
function Macros.Broadcast(msg)
	GameLogic.RunCommand("sendevent", msg);
end
Macros.broadcast = Macros.Broadcast


-- @param text: show big one line text at the bottom, if nil, it will remove the tip. 
-- @param duration: milli seconds. if nil, it is forever
-- @param position: nil default to "bottom", can also be "center", "top"
-- @param voiceType: voice type, default to play a kid's voice (4).  -1 to disable
function Macros.Text(text, duration, position, voiceType)
	MacroPlayer.ShowText(text, duration, position)
	Macros.lastPlayTextTime = commonlib.TimerManager.GetCurrentTime();
	if(voiceType ~= -1) then
		SoundManager:PlayText(text, voiceType, nil, nil, function()
			-- start play callback
			Macros.isPlayingText = true
		end, function()
			-- end play callback
			Macros.isPlayingText = false;
		end)
	end
end
Macros.text = Macros.Text;



