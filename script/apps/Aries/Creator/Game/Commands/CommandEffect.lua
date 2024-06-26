--[[
Title: CommandEffect
Author(s): LiXizhi
Date: 2014/7/4
Desc: command effect
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEffect.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

-- set shader mode. 
Commands["shader"] = {
	name="shader", 
	quick_ref="/shader [0,1,2,3,4]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[graphic shader. default to 1
/shader 0   fixed function
/shader 1   default
/shader 2   shadow+reflection
/shader 3   shadow+reflection+HDR+Bloom+Vignette
/shader 4   shadow+reflection+HDR+Bloom+Vignette+DepthOfField
	]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			if(GameLogic.options:IsDisableShaderCommand()) then
				return "disabled";
			end

			if System.os.GetPlatform()=="android" then
				return false
			end

			local shader_method = tonumber(cmd_text:match("([%d%.]+)") or 1);

			if(GameLogic.GetShaderManager():SetShaders(math.min(2, shader_method))) then
				ParaTerrain.GetBlockAttributeObject():SetField("UseLinearTorchBrightness", shader_method >=3);
				if(shader_method >=2) then
					local effect = GameLogic.GetShaderManager():GetEffect("Fancy");
					if(effect) then
						effect:EnableBloomEffect(shader_method >=3);
						effect:EnableDepthOfViewEffect(shader_method >=4);
					end
				end
			else
				return false;
			end
		end
	end,
};

Commands["dof"] = {
	name="dof", 
	quick_ref="/dof [0-1]", 
	desc=[[set depth of field (DOF) factor used in shader 4. Default value is 0.01. Bigger value has shallower depth of view. 0 is disable depth of view. 
	/dof 0   disable depth of view
	/dof 0.05
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local factor;
		factor, cmd_text = CmdParser.ParseInt(cmd_text);	
		if(factor and factor >= 0 and factor<=2) then
			local effect = GameLogic.GetShaderManager():GetEffect("Fancy");
			if(effect) then
				if(factor==0) then
					effect:EnableDepthOfViewEffect(false);
				else
					effect:EnableDepthOfViewEffect(true);
				end
				effect:SetDepthOfViewFactor(factor);
			end
		end
	end,
};

Commands["brightness"] = {
	name="brightness", 
	quick_ref="/brightness [0-1]", 
	desc=[[set brightness(exposure) factor (0-1) used in HDR shader 3, 4. default value is 0.2.
/brightness 0.1    more detail with dark colors
/brightness 0.5    more detail with bright colors
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local factor;
		factor, cmd_text = CmdParser.ParseNumber(cmd_text);	
		GameLogic.options:SetEyeBrightness(factor);
	end,
};

Commands["contrast"] = {
	name="contrast", 
	quick_ref="/contrast [0-1]", 
	desc=[[set contrast factor (0-1) used in HDR shader 3, 4. default value is 0.5.
/contrast 0.3    low contrast
/contrast 0.8    high contrast
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local factor;
		factor, cmd_text = CmdParser.ParseNumber(cmd_text);	
		GameLogic.options:SetEyeContrast(factor);
	end,
};


--[[

Commands["bloom"] = {
	name="bloom", 
	quick_ref="/bloom [on|off]", 
	desc="enable bloom(DOF) shader effect. This only works when shader level is above 2", 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bIsOn;
		bIsOn, cmd_text = CmdParser.ParseBool(cmd_text);	
		local effect = GameLogic.GetShaderManager():GetEffect("final");
		if(effect) then
			effect:EnableBloomEffect(bIsOn);
			effect:SetEnabled(bIsOn);
		end
	end,
};
]]

Commands["shadow"] = {
	name="shadow", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/shadow [0,1]", 
	desc="whether to cast sun shadows on block. 0 disable; 1 enable" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local shader_method = tonumber(cmd_text:match("([%d%.]+)") or 1);
			ParaTerrain.GetBlockAttributeObject():SetField("UseSunlightShadowMap", if_else(shader_method == 1, true, false));
		end
	end,
};


-- whether to render water reflection blocks. 
Commands["reflection"] = {
	name="reflection", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/reflection [0,1]", 
	desc="0 disable; 1 enable" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local shader_method = tonumber(cmd_text:match("([%d%.]+)") or 1);
			ParaTerrain.GetBlockAttributeObject():SetField("UseWaterReflection", if_else(shader_method == 1, true, false));
		end
	end,
};

Commands["greyblur"] = {
	name="greyblur", 
	quick_ref="/greyblur [on|off]", 
	desc=[[Obsoleted: use /grey instead. 
turn greyblur effect on and off
/blur on
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bIsOn;
		bIsOn, cmd_text = CmdParser.ParseBool(cmd_text);	
		local effect = GameLogic.GetShaderManager():GetEffect("GreyBlur");
		if(effect) then
			effect:SetEnabled(bIsOn);
		end
	end,
};

-- need to opt
Commands["cartoon"] = {
	name="cartoon", 
	quick_ref="/cartoon [on|off]", 
	desc=[[
		turn cartoon effect on and off
		/cartoon on
		/cartoon off
	]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bIsOn;
		bIsOn, cmd_text = CmdParser.ParseBool(cmd_text);	
		local effect = GameLogic.GetShaderManager():GetEffect("Cartoon");
		if(effect) then
			effect:SetEnabled(bIsOn);
		end
	end,
};

Commands["grey"] = {
	name="grey", 
	quick_ref="/grey [r g b] [glow_r glow_g glow_b]", 
	desc=[[turn grey effect on and off
/grey 1.2 1.2 0.9
/grey 0.85 0.79 0.74 0.27 0.14 0.03
/grey     turn it off
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bIsOn;
		local effect = GameLogic.GetShaderManager():GetEffect("Grey");
		if(effect) then
			local r,g,b;
			r, cmd_text = CmdParser.ParseInt(cmd_text);
			g, cmd_text = CmdParser.ParseInt(cmd_text);
			b, cmd_text = CmdParser.ParseInt(cmd_text);
			if(r and g and b) then
				local glow_r, glow_g, glow_b;
				glow_r, cmd_text = CmdParser.ParseInt(cmd_text);
				glow_g, cmd_text = CmdParser.ParseInt(cmd_text);
				glow_b, cmd_text = CmdParser.ParseInt(cmd_text);
				effect:SetColorMultiply(r,g,b, glow_r, glow_g, glow_b);
				effect:SetEnabled(true);
			else
				effect:SetEnabled(false);
			end
		end
	end,
};

Commands["hsv"] = {
	name="hsv", 
	quick_ref="/hsv [h s v] [multiply_r multiply_g multiply_b]", 
	desc=[[hsv effect on and off
/hsv 0 -1 0    offset hsv of the image
/hsv 0 0 0 1 1 2    multiply and then offset hsv of the image
/hsv    turn it off
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local effect = GameLogic.GetShaderManager():GetEffect("ColorEffect");
		if(effect) then
			local h,s,v;
			h, cmd_text = CmdParser.ParseInt(cmd_text);
			s, cmd_text = CmdParser.ParseInt(cmd_text);
			v, cmd_text = CmdParser.ParseInt(cmd_text);
			if(h and s and v) then
				effect:SetHSVAdd(h,s,v);
				local multiply_r, multiply_g, multiply_b;
				multiply_r, cmd_text = CmdParser.ParseInt(cmd_text);
				multiply_g, cmd_text = CmdParser.ParseInt(cmd_text);
				multiply_b, cmd_text = CmdParser.ParseInt(cmd_text);
				if(multiply_r and multiply_g and multiply_b) then
					effect:SetColorMultiply(multiply_r, multiply_g, multiply_b);
				else
					effect:SetColorMultiply(1, 1, 1);
				end
				effect:SetEnabled(true);
			else
				effect:SetEnabled(false);
			end
		end
	end,
};

Commands["vignetting"] = {
	name="vignetting", 
	quick_ref="/vignetting [amount midpoint roundness feather]", 
	desc=[[vignetting effect on and off
/vignetting 0 0.5 0 0   transparent
/vignetting 1 0.5 0 0   pure white
/vignetting -1 0.5 0 0  pure dark
/vignetting 1 0.8 0 0   scale up
/vignetting 1 0.2 0 0   scale down
/vignetting 1 0.5 0.5 0     eclipse
/vignetting 1 0.5 -0.5 0    round corner
/vignetting 1 0.5 0 0.5     feather effect
/vignetting    turn it off
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local effect = GameLogic.GetShaderManager():GetEffect("Vignetting");
		if(effect) then
			local amount, midpoint, roundness, feather;
			amount, cmd_text = CmdParser.ParseNumber(cmd_text);
			midpoint, cmd_text = CmdParser.ParseNumber(cmd_text);
			roundness, cmd_text = CmdParser.ParseNumber(cmd_text);
			feather, cmd_text = CmdParser.ParseNumber(cmd_text);
			if(amount and midpoint and roundness and feather) then
				effect:SetParam(amount, midpoint, roundness, feather);
				effect:SetEnabled(true);
			else
				effect:SetEnabled(false);
			end
		end
	end,
};

Commands["viewport"] = {
	name="viewport", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/viewport [@id_or_name] [alignment:_lt|_fi|_rt] [left] [top] [width] [height]", 
	desc=[[ change main viewport 
e.g.
/viewport							fill all viewport
/viewport 0 0 100 0
/viewport _lt 0 0 600 400
/viewport @0 _lt 0 0 600 400
/viewport @GUI _lt 0 0 600 400
/viewport @scene _fi 10 10 10 10
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local id, alignment, left, top, width, height;
		id, cmd_text = CmdParser.ParseFormated(cmd_text, "@%S+");
		if(id) then
			id = id:gsub("@", "");
			if(id:match("^%d+")) then
				id = tonumber(id) or id;
			end
		else
			id = 1;
		end
		alignment, cmd_text = CmdParser.ParseFormated(cmd_text, "_%w+");
		alignment = alignment or "_fi";

		left, cmd_text = CmdParser.ParseInt(cmd_text);
		top, cmd_text = CmdParser.ParseInt(cmd_text);
		width, cmd_text = CmdParser.ParseInt(cmd_text);
		height, cmd_text = CmdParser.ParseInt(cmd_text);

		NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
		local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
		local viewport = Viewport:new():init(id)
		if(viewport) then
			viewport:SetPosition(alignment, left or 0, top or 0, width or 0, height or 0);
		end
	end,
};

Commands["stereo"] = {
	name="stereo", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/stereo [on|off|red|interlaced|left|ods|odsdebug] [eye_dist] [lookat_offset]", 
	desc=[[turn on/off stereo mode. 
e.g.
/stereo on 0.1          with 0.1 eye seperation distance
/stereo 0.03  3         with 0.03 eye seperation distance and 3 convergence plane offset
/stereo off             turn 3d off
/stereo red             red/blue mode 
/stereo interlaced      mode 
/stereo left            left/right mode
/stereo ods             ods 360 single eye
/stereo odsdebug        ods 360 single eye debug mode
/stereo                 toggle
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local mode,eyeDist, lookat_offset;
		mode, cmd_text = CmdParser.ParseFormated(cmd_text, "[^%d]%w+");
		eyeDist, cmd_text = CmdParser.ParseInt(cmd_text);
		if(not mode and not eyeDist) then
			-- toggle mode
			mode = if_else(GameLogic.options:IsStereoMode(), "off", "on");
		end
		lookat_offset, cmd_text = CmdParser.ParseInt(cmd_text);

		if(mode) then
			if(mode:match("^on") or mode:match("^left")) then
				mode = 2;
			elseif(mode:match("^interlaced")) then
				mode = 4;
			elseif(mode:match("^red")) then
				mode = 5;
			elseif(mode:match("^ods")) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/ODSStereoEffect.lua");
				local ODSStereoEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.ODSStereoEffect");
				ODSStereoEffect.SetDebugMode(false)
				if(mode:match("debug")) then
					ODSStereoEffect.SetDebugMode(true)
				end
				mode = 8
				ODSStereoEffect.AutoAdjustODS_SingleResolution(function()
					GameLogic.options:EnableStereoMode(mode);
				end)
				return
			else
				mode = 0;
			end
			GameLogic.options:EnableStereoMode(mode);
		end
		if(eyeDist) then
			GameLogic.options:SetStereoEyeSeparationDist(eyeDist);
		end
		if(lookat_offset) then
			GameLogic.options:SetStereoConvergenceOffset(lookat_offset);
		end
	end,
};

Commands["stereocontroller"] = {
	name="stereocontroller", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/stereocontroller [on|off]", 
	desc="turn on/off stereo controller" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local mode,eyeDist;
		mode, cmd_text = CmdParser.ParseFormated(cmd_text, "o%w+");
		if(not mode) then
			-- toggle mode
			mode = if_else(GameLogic.options:IsStereoControllerEnabled(), "off", "on");
		end
		GameLogic.options:SetStereoControllerEnabled(mode == "on");
	end,
};

Commands["superrender"] = {
	name="superrender", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/superrender [on|off] [distance]", 
	desc=[[turn on/off long distance multi-frame block world rendering.
@param distance: distance to render usually between [0-2000] meters. if 0, it will disable this feature.
e.g.
/superrender on      turn on super rendering, default distance if 512 meters. 
/superrender 1024    enable and render as far as 1024
/superrender 0       same as turning off
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local enabled;
		enabled, cmd_text = CmdParser.ParseBool(cmd_text);

		local dist;
		dist, cmd_text = CmdParser.ParseNumber(cmd_text);
		if(dist) then
			GameLogic.options:SetSuperRenderDist(dist);
		else
			local attr = ParaTerrain.GetBlockAttributeObject():GetChild("CMultiFrameBlockWorldRenderer");
			attr:SetField("Enabled", enabled == true);	
		end
	end,
};

Commands["pointtexture"] = {
	name="pointtexture", 
	quick_ref="/pointtexture [on|off]", 
	desc=[[turn point texture filter on or off for meshes in block world. By default, it is on. 
/pointtexture on
/pointtexture off
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local bIsOn;
		bIsOn, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bIsOn == nil) then
			bIsOn = true;
		end
		LOG.std(nil, "info", "pointtexture", bIsOn);
		ParaTerrain.GetBlockAttributeObject():SetField("UsePointTextureFiltering", bIsOn);
	end,
};