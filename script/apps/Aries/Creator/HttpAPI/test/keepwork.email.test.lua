--[[
Title: keepwork.email.test
Author(s): pbb
Date: 2021/3/24
Desc:  
Use Lib:
-------------------------------------------------------
local test = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/test/keepwork.email.test.lua");
test.GetEmailList()
--]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local test = NPL.export()


function test.SendEmail()
    keepwork.email.sendEmail({
        title = "test",
        content = "听，有鸟归巢的呼唤，有夕阳滑过树梢的呢喃，有流水轻抚小桥的滋润，有天边的一朵云，不想从哪里来，也不想到哪里去，一切都是自由的。听，心跳的声音，慢慢平静，就像人生的繁华，终将结束；就像盛大的舞台，开始谢幕。",
        rewards = {},
        type = 2,
        exId = 90001,
        audiences = {773},
    },function(err, msg, data)
        commonlib.echo("==========SendEmail");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end

function test.GetEmailList()
    keepwork.email.email({},function(err, msg, data)
        commonlib.echo("==========GetEmailList");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end

function test.SetEmailReaded()
    keepwork.email.setEmailReaded({
        ids = {1},
    },function(err, msg, data)
        commonlib.echo("==========SetEmailReaded");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end

function test.DeleteEmail()
    keepwork.email.delEmail({
        ids = {1},
    },function(err, msg, data)
        commonlib.echo("==========DeleteEmail");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end

function test.ReadEmail(id)
    keepwork.email.readEmail({
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        commonlib.echo("==========ReadEmail");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end

function test.GetEmailReward()
    keepwork.email.getEmailReward({
        ids = {1},
    },function(err, msg, data)
        commonlib.echo("==========GetEmailReward");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end