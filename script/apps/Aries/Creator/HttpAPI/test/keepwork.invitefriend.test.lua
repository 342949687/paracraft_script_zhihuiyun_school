--[[
Title: keepwork.invitefriend.test
Author(s): pbb
Date: 2021/3/9
Desc:  
Use Lib:
-------------------------------------------------------
local test = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/test/keepwork.invitefriend.test.lua");

--]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local test = NPL.export()

function test.GetInviteCode()
    keepwork.invitefriend.invitationCode({},function(err, msg, data)
        print("test.GetInviteCode")
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data,true);
    end)
end

function test.GetInviteInfo()
    keepwork.invitefriend.invitationInfo({},function(err, msg, data)
        print("test.GetInviteInfo")
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data,true);
    end)
end

function test.UseInviteCode()
    keepwork.invitefriend.useInvitationCode({
        invitationCode = "1111111",
    },function(err, msg, data)
        print("test.UseInviteCode")
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data,true);
    end)
end

function test.GetInviteReward()
    keepwork.invitefriend.inviteReward({
        level = 1,
    },function(err, msg, data)
        print("test.GetInviteReward")
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data,true);
    end)
end