--[[
Title: Config
Author(s):  big
Date: 2018.10.18
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')
------------------------------------------------------------
]]

local Config = NPL.export()

function Config:GetValue(key)
  return self[key][self.defaultEnv]
end

Config.env = {
  ONLINE = 'ONLINE',
  STAGE = 'STAGE',
  RELEASE = 'RELEASE',
  LOCAL = 'LOCAL'
}

Config.defaultEnv = (ParaEngine.GetAppCommandLineByParam('http_env', nil) or Config.env.ONLINE)
Config.defaultGit = 'KEEPWORK'

Config.homeWorldId = {
  ONLINE = 19759,
  RELEASE = 1296,
  STAGE = 0,
  LOCAL = 0,
}

Config.schoolWorldId = {
  ONLINE = 52217,
  RELEASE = 20617,
  STAGE = 0,
  LOCAL = 0
}

Config.campWorldId = {
  ONLINE = 70351,
  RELEASE = 20669,
  STAGE = 0,
  LOCAL = 0
}

Config.keepworkList = {
  ONLINE = 'https://keepwork.com',
  STAGE = 'http://dev.kp-para.cn',
  RELEASE = 'http://rls.kp-para.cn',
}

Config.storageList = {
  ONLINE = 'https://api.keepwork.com/ts-storage',
  STAGE = 'http://api-dev.kp-para.cn/ts-storage',
  RELEASE = 'http://api-rls.kp-para.cn/ts-storage',
}

Config.qiniuList = {
  ONLINE = 'https://upload-z2.qiniup.com',
  STAGE = 'https://upload-z2.qiniup.com',
  RELEASE = 'https://upload-z2.qiniup.com',
}

Config.qiniuGitZip = {
  ONLINE = 'https://qiniu-gitzip.keepwork.com',
  STAGE = 'http://qiniu-gitzip-dev.keepwork.com',
  RELEASE = 'http://qiniu-gitzip-dev.keepwork.com',
}

Config.xpGitZip = {
  ONLINE = 'http://api.keepwork.com/core/v0',
  STAGE = 'http://api-dev.keepwork.com/core/v0',
  RELEASE = 'http:/api-dev.keepwork.com/core/v0',
}

Config.keepworkServerList = {
  ONLINE = 'https://api.keepwork.com/core/v0',
  STAGE = 'http://api-dev.kp-para.cn/core/v0',
  RELEASE = 'http://api-rls.kp-para.cn/core/v0',
}

Config.keepworkApiCdnList = {
  ONLINE = 'https://apicdn.keepwork.com/core/v0',
  STAGE = 'http://api-dev.kp-para.cn/core/v0',
  RELEASE = 'http://apicdn-rls.kp-para.cn/core/v0',
}

Config.keepworkServerList_Edu = {
  ONLINE = 'https://api.keepwork.com/edu/v0',
  STAGE = 'http://api-dev.kp-para.cn/edu/v0',
  RELEASE = 'http://api-rls.kp-para.cn/edu/v0',
}

Config.keepworkApiCdnList_Edu = {
  ONLINE = 'https://apicdn.keepwork.com/edu/v0',
  STAGE = 'http://api-dev.kp-para.cn/edu/v0',
  RELEASE = 'http://apicdn-rls.kp-para.cn/edu/v0',
}

Config.gitGatewayList = {
  ONLINE = 'https://api.keepwork.com/git/v0',
  STAGE = 'http://api-dev.kp-para.cn/git/v0',
  RELEASE = 'http://api-rls.kp-para.cn/git/v0',
}

Config.esGatewayList = {
  ONLINE = 'https://api.keepwork.com/es/v0',
  STAGE = 'http://api-dev.kp-para.cn/es/v0',
  RELEASE = 'http://api-rls.kp-para.cn/es/v0',
}

Config.eventGatewayList = {
  ONLINE = 'https://api.keepwork.com/event-gateway',
  STAGE = 'http://api-dev.kp-para.cn/event-gateway',
  RELEASE = 'http://api-rls.kp-para.cn/event-gateway',
}

Config.lessonList = {
  ONLINE = 'https://api.keepwork.com/lessonapi/v0',
  STAGE = 'http://api-dev.kp-para.cn/lessonapi/v0',
  RELEASE = 'http://api-rls.kp-para.cn/lessonapi/v0',
}

Config.accountingList = {
  ONLINE = 'https://api.keepwork.com/accounting',
  STAGE = 'http://api-dev.kp-para.cn/accounting',
  RELEASE = 'http://api-rls.kp-para.cn/accounting',
}

Config.dataSourceApiList = {
  gitlab = {
    ONLINE = 'https://git.keepwork.com/api/v4',
    STAGE = 'http://git-dev.kp-para.cn/api/v4',
    RELEASE = 'http://git-rls.kp-para.cn/api/v4',
  }
}

Config.dataSourceRawList = {
  gitlab = {
    ONLINE = 'https://git.keepwork.com',
    STAGE = 'http://git-dev.kp-para.cn',
    RELEASE = 'http://git-rls.kp-para.cn',
  }
}

Config.socket = {
  ONLINE = 'https://socket.keepwork.com',
  STAGE = 'http://socket-dev.kp-para.cn',
  RELEASE = 'http://socket-rls.kp-para.cn',
}

Config.marketing = {
  ONLINE = 'https://api.keepwork.com/client-marketing',
  STAGE = 'http://api-dev.kp-para.cn/client-marketing',
  RELEASE = 'http://api-rls.kp-para.cn/client-marketing',
}
Config.RecommendedWorldList = 'https://git.keepwork.com/gitlab_rls_official/keepworkdatasource/raw/master/official/paracraft/RecommendedWorldList.md'

Config.QQ = {
  ONLINE = {
    clientId = '101403344'
  },
  STAGE = {
    clientId = '101403344'
  },
  RELEASE = {
    clientId = '101403344'
  },
  LOCAL = {
    clientId = '101403344'
  },
}

Config.WECHAT = {
  ONLINE = {
    clientId = 'wxc97e44ce7c18725e'
  },
  STAGE = {
    clientId = 'wxc97e44ce7c18725e'
  },
  RELEASE = {
    clientId = 'wxc97e44ce7c18725e'
  },
  LOCAL = {
    clientId = 'wxc97e44ce7c18725e'
  }
}
