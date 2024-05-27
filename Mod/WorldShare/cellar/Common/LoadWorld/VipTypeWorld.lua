--[[
Title: Vip Type World
Author(s): big
Date: 2021.3.8
City: Foshan
use the lib:
------------------------------------------------------------
local VipTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/VipTypeWorld.lua')
------------------------------------------------------------
]]

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

local VipTypeWorld = NPL.export()

function VipTypeWorld:IsVipWorld(world)
    if world and (world.isVipWorld == true or world.isVipWorld == "true") then
        return true
    else
        return false
    end
end

function VipTypeWorld:HasProjectId(world)
    if(world and world.kpProjectId) then
		return true;
	end
end

-- return true if free and white listed world
function VipTypeWorld:IsFreeWorld(world)
    if(world and (world.isFreeWorld or 0) ~= 0) then
		return true;
	end
end

function VipTypeWorld:IsWorldInCurrentUserFolder(world)
	if(world and world.worldpath) then
		local username = Mod.WorldShare.Store:Get('user/username') or System.User.username;
		if(username) then
			if(string.find(world.worldpath, "worlds/DesignHouse/_user/"..username, nil, true)) then
				return true;
			end
		end
	end
end

function VipTypeWorld:CheckVipWorld(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if self:IsVipWorld(world) then
        if not KeepworkServiceSession:IsSignedIn() then
            return false
        end

        local canEnter = false
        local username = Mod.WorldShare.Store:Get('user/username')

        if world.user and world.user.username == username then
            canEnter = true
        end

        local isVip = Mod.WorldShare.Store:Get('user/isVip')

        if isVip then
            canEnter = true
        end

        if not canEnter then
            return false
        end

        return canEnter
    else
        return true
    end
end

function VipTypeWorld:IsInstituteVipWorld(world)
    if world and (world.instituteVipEnabled == true or world.instituteVipEnabled == "true") then
        return true
    else
        return false
    end
end

function VipTypeWorld:CheckInstituteVipWorld(world, callback)
    if not world or type(world) ~= 'table' then
        return false
    end

    if self:IsInstituteVipWorld(world) then
        if not KeepworkServiceSession:IsSignedIn() then
            if callback and type(callback) == 'function' then
                callback(false)
            end
            return
        end

        GameLogic.IsVip('IsOrgan', true, function(result)
            if result then
                if callback and type(callback) == 'function' then
                    callback(true)
                end
            else
                if callback and type(callback) == 'function' then
                    callback(false)
                end
            end
        end, 'Institute')
    else
        if callback and type(callback) == 'function' then
            callback(false)
        end
    end
end