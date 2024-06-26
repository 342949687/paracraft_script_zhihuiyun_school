
local GoodsConfig = require("../GoodsConfig.lua");
local EntitySunBin = require("./EntitySunBin.lua");
local EntityHunter = require("./EntityHunter.lua");
local EntityWolf = require("./EntityWolf.lua");
local EntityTiger = require("./EntityTiger.lua");
local EntityArrowTower = require("./EntityArrowTower.lua");

function CreateSunBinEntity(bx, by, bz)
    return EntitySunBin:new():Init(bx, by, bz);
end

function CreateHunterEntity(bx, by, bz)
    return EntityHunter:new():Init(bx, by, bz);
end

function CreateWolfEntity(bx, by, bz)
    return EntityWolf:new():Init(bx, by, bz);
end

function CreateTigerEntity(bx, by, bz)
    return EntityTiger:new():Init(bx, by, bz);
end

function CreateCrossFenceEntity(bx, by, bz)
    return CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "cross_fence",
        assetfile = "model/blockworld/Fence/Fence_Cross.x", 
        obstruction = true, 
    });
end

function CreateLiangShiEntity(bx, by, bz)
    return CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "liangshi",
        assetfile = "character/CC/artwar/game/liangshi.x", 
        destroyBeCollided = true, 
        goods = {
            [1] = {gsid = GoodsConfig.LIANG_SHI.ID, transfer = true},
        }
    });
end

function CreateArrowTowerEntity(bx, by, bz)
    return EntityArrowTower:new():Init(bx, by, bz);
end

-- character/CC/02human/blockman/shanzei.   shanzhui
-- character/CC/02human/blockman/cunzhang.x
-- character/CC/codewar/laohu.x

-- character/CC/artwar/game/caoyao_daoju.x
-- character/CC/artwar/game/assassin.x
-- blocktemplates/youxia_youxi.x

-- <asset filename="character/CC/artwar/game/firetrap_off.x" displayname="火焰陷阱" name="firetrap_off"/>
-- <asset filename="character/CC/artwar/game/firetrap_on.x" displayname="火焰陷阱（触发）" name="firetrap_on"/>

-- <asset filename="character/CC/artwar/game/mumen.x" displayname="木门" name="mumen"/>
-- <asset filename="character/CC/artwar/game/mumen_poor.x" displayname="破木门" name="mumen_poor"/>
-- <asset filename="character/CC/artwar/game/liangshi.x" displayname="粮食" name="liangshi"/>
-- 