--[[
Title: Bone attribute variable
Author(s): LiXizhi
Date: 2015/9/15
Desc: a single attribute like rotation, trans or scaling on a bone. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BoneAttributeVariable.lua");
local BoneAttributeVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BoneAttributeVariable");
-------------------------------------------------------
]]
local ATTRIBUTE_FIELDTYPE = commonlib.gettable("System.Core.ATTRIBUTE_FIELDTYPE");

local BoneAttributeVariable = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Movie.BoneAttributeVariable"));
BoneAttributeVariable.name = "";

function BoneAttributeVariable:ctor()
end

-- @param attrName: 
-- @param attrType: "rot", "scale", "trans": this will affect default value and type
-- @param attr: parax bone attribute model
-- @param animInstance: the animation instance 
-- @param parent: get the parent BonesVariable.
function BoneAttributeVariable:init(attrName, attrType, attr, animInstance, parent)
	self.parent = parent;
	self.name = attrName or attr:GetField("RotName", "");
	self.type = attrType or "rot";
	self.attr = attr;
	self.animInstance = animInstance;
	return self;
end

-- save from C++'s current anim instance to actor's timeseries
function BoneAttributeVariable:SaveToTimeVar()
	local name = self:GetAttributeName();
	local keyCount = self:GetKeyNum();
	if(keyCount == 0) then
		local var = self.parent:GetTimeVariable(name);
		if(var) then
			if(var:GetKeyNum() > 0) then
				var:Reset();
			end
		end
	else
		local var = self.parent:GetTimeVariable(name) or self.parent:CreateTimeVariable(name);
		if(var) then
			var:SetKeyNum(keyCount);
			for i=1, keyCount do
				local time = self.animInstance:GetFieldKeyTime(name, i-1);
				local value
				if(self.type == "rot") then
					value = self.animInstance:GetFieldKeyValue(name, i-1, {0,0,0,1});
				elseif(self.type == "scale") then
					value = self.animInstance:GetFieldKeyValue(name, i-1, {1,1,1});
				elseif(self.type == "trans") then
					value = self.animInstance:GetFieldKeyValue(name, i-1, {0,0,0});
				end
				if(value) then
					var:SetKeyValueAt(i, time, value);
				end
			end
		end
	end
end

function BoneAttributeVariable:CreateGetTimeVar()
	local name = self:GetAttributeName();
	return self.parent:GetTimeVariable(name) or self.parent:CreateTimeVariable(name);
end

-- Load from actor's timeseries to C++'s current anim instance. 
function BoneAttributeVariable:LoadFromTimeVar()
	local name = self:GetAttributeName();
	local var = self.parent:GetTimeVariable(name)
	if(var) then
		local animInstance = self.animInstance;
		if(self.type == "rot") then
			animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedQuaternion);
		else
			animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedVector3);
		end
		local i=0;
		animInstance:SetFieldKeyNums(name, var:GetKeyNum());
		for time, v in var:GetKeys_Iter(1, -1, 999999) do
			animInstance:SetFieldKeyTime(name, i, time);
			animInstance:SetFieldKeyValue(name, i, v);
			i = i + 1;
		end
		if(i == 0) then
			self.parent:RemoveEmptyVariables();
		end
	else
		self.animInstance:SetFieldKeyNums(name, 0);
	end
end

function BoneAttributeVariable:GetAttributeName()
	return self.name;
end

-- variable is returned as an array of individual variable value at the given time. 
function BoneAttributeVariable:getValue(anim, time)
	if(self:GetKeyNum()>0) then
		return self:CreateGetTimeVar():getValue(anim, time)
	end
	-- return self.name;
end

-- only support modifying existing key at time
-- TODO: support add key
function BoneAttributeVariable:AddKey(time, data)
	
end

-- modify the C++ data directly as a constant value.
-- use this function to control the animation externally. 
-- @note: this function does not modify the time variable.
function BoneAttributeVariable:SetData(data)
	local name = self:GetAttributeName();
	local animInstance = self.animInstance;
	if(self.type == "rot") then
		animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedQuaternion);
		self.lastData = self.lastData or mathlib.Quaternion:new();
	else
		animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedVector3);
		self.lastData = self.lastData or mathlib.vector3d:new();
	end
	animInstance:SetFieldKeyNums(name, 1);
	animInstance:SetFieldKeyTime(name, 1, 0);
	animInstance:SetFieldKeyValue(name, 1, data);
	self.lastData:set(data);
end

-- get the C++ dynamic data directly as a constant value.
-- @param bRefresh: true to refresh, otherwise use the last cached value (usually set via self:SetData).
function BoneAttributeVariable:GetData(bRefresh)
	if(not bRefresh) then
		return self.lastData
	end
	local name = self:GetAttributeName();
	local animInstance = self.animInstance;
	if(animInstance:GetFieldKeyNums(name) > 0) then
		if(self.type == "rot") then
			self.lastData = self.lastData or mathlib.Quaternion:new()
		else
			self.lastData = self.lastData or mathlib.vector3d:new()
		end
		animInstance:GetFieldKeyValue(name, 1, self.lastData);
		return self.lastData;
	end
end

function BoneAttributeVariable:GetKeyNum()
	return self.animInstance:GetFieldKeyNums(self:GetAttributeName());
end

function BoneAttributeVariable:GetLastTime()
	local name = self:GetAttributeName();
	local count = self.animInstance:GetFieldKeyNums(name);
	if(count > 0) then
		return self.animInstance:GetFieldKeyTime(name, count-1);
	else
		return 0;
	end
end

function BoneAttributeVariable:MoveKeyFrame(key_time, from_keytime)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():MoveKeyFrame(key_time, from_keytime);
		self:LoadFromTimeVar();
	end
end

function BoneAttributeVariable:CopyKeyFrame(key_time, from_keytime)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():CopyKeyFrame(key_time, from_keytime);
		self:LoadFromTimeVar();
	end
end

-- Update or insert (Upsert) a key frame at given time.
-- @param data: data is cloned before updating. 
function BoneAttributeVariable:UpsertKeyFrame(key_time, data)
	self:CreateGetTimeVar():UpsertKeyFrame(key_time, data);
	self:LoadFromTimeVar();
end

function BoneAttributeVariable:RemoveKeyFrame(key_time)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():RemoveKeyFrame(key_time);
		self:LoadFromTimeVar();
	end
end

function BoneAttributeVariable:ShiftKeyFrame(shift_begin_time, offset_time)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():ShiftKeyFrame(shift_begin_time, offset_time);
		self:LoadFromTimeVar();
	end
end

function BoneAttributeVariable:RemoveKeysInTimeRange(fromTime, toTime)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():RemoveKeysInTimeRange(fromTime, toTime);
		self:LoadFromTimeVar();
	end
end


function BoneAttributeVariable:TrimEnd(time)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():TrimEnd(time);
		self:LoadFromTimeVar();
	end
end

-- iterator that returns, all (time, value) pairs between (TimeFrom, TimeTo].  
-- the iterator works fine when there are identical time keys in the animation, like times={0,1,1,2,2,2,3,4}.  for time keys in range (0,2], 1,1,2,2,2, are returned. 
function BoneAttributeVariable:GetKeys_Iter(anim, TimeFrom, TimeTo)
	local name = self:GetAttributeName();
	local count = self.animInstance:GetFieldKeyNums(name);
	if(count > 0) then
		local i = 1;
		return function()
			if(i > count) then
				return;
			end
			local time = self.animInstance:GetFieldKeyTime(name, i-1);
			while(time < TimeFrom and i <= count) do
				i = i + 1;
				time = self.animInstance:GetFieldKeyTime(name, i-1);
			end
			if(time>TimeFrom and time<=TimeTo) then
				i = i + 1;
				return time, self.name;
			end
		end
	else
		return function() end;	
	end
end


-- paste all key frames between [fromTime, toTime] to time
function BoneAttributeVariable:PasteKeyFramesInRange(time, fromTime, toTime)
	if(self:GetKeyNum()>0) then
		self:CreateGetTimeVar():PasteKeyFramesInRange(time, fromTime, toTime);
		self:LoadFromTimeVar();
	end
end

-- append a key intelligently without introducing keys, it will automatically update the range if necessary.
-- currently it only works for range 0. 
-- if type is Linear, it will create a new key only if the last key, the last last key and the new key are all the same. 
-- if type is Discrete, it will always create a new key. 
-- @param time: if time is smaller than the last time, previous time, value will be removed. 
-- @param bForceAppend: always append no matter what. 
-- @return true if appended.
function BoneAttributeVariable:AutoAppendKey(time, data, bForceAppend)
	local res = self:CreateGetTimeVar():AutoAppendKey(time, data, bForceAppend);
	self:LoadFromTimeVar();
	return res;
end