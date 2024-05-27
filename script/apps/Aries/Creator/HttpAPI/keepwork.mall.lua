--[[
Title: keepwork.mall
Author(s): leio
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.mall.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");

--http://yapi.kp-para.cn/project/32/interface/api/2447
local api_name = "keepwork.mall.menus.get";
HttpWrapper.Create(api_name, "%MAIN%/core/v0/mall/classifies", "GET", false)

--http://yapi.kp-para.cn/project/32/interface/api/2452
HttpWrapper.Create("keepwork.mall.goods.get", "%MAIN%/core/v0/mall/products", "GET", false)

--http://yapi.kp-para.cn/project/32/interface/api/2457
HttpWrapper.Create("keepwork.mall.buy", "%MAIN%/core/v0/mall/products/buy", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/2727
HttpWrapper.Create("keepwork.mall.orderResule", "%MAIN%/core/v0/mall/mOrders/", "GET", false)

--搜索商城商品
-- params 
--[[
q	        否	    关键词,纯数字则根据id搜索
classifyId	否	    分类id可以不传
per_page    是	20  一页的个数
page        是	1   第几页，从1开始
modelType	否	
sort	    否	    排序字段， name、userCount、updatedAt
order	    否	    顺序：asc、desc
]]

--http://yapi.kp-para.cn/project/46/interface/api/5125
HttpWrapper.Create("keepwork.mall.searchGoods", "%MAIN%/es/v0/products", "GET", true)

--使用商城物品
--http://yapi.kp-para.cn/project/32/interface/api/5235
HttpWrapper.Create("keepwork.mall.useGood", "%MAIN%/core/v0/mProducts/:id/use", "POST", true)

--商城 V3

--添加收藏
--[[
    mProductId	是	商品id
]]
--http://yapi.kp-para.cn/project/32/interface/api/7685
HttpWrapper.Create("keepwork.mall.star", "%MAIN%/core/v0/mall/stars", "POST", true)

--取消收藏
--[[
  routerParams  mProductId	是	商品id
]]
--http://yapi.kp-para.cn/project/32/interface/api/7691
HttpWrapper.Create("keepwork.mall.unstar", "%MAIN%/core/v0/mall/stars/:mProductId", "DELETE", true)

--收藏列表
--[[
  x-per-page		是	
  x-page		是
]]
--http://yapi.kp-para.cn/project/32/interface/api/7697
HttpWrapper.Create("keepwork.mall.starlist", "%MAIN%/core/v0/mall/stars", "GET", true)

--判断是否收藏
--http://yapi.kp-para.cn/project/32/interface/api/7709
HttpWrapper.Create("keepwork.mall.getstarIds", "%MAIN%/core/v0/mall/starIds", "GET", true)

--新增个人模型
--[[
    name	string	必须
    modelUrl	string	必须
    size	integer	必须 字节数	
    modelType	string	必须
]]
--http://yapi.kp-para.cn/project/32/interface/api/7703
HttpWrapper.Create("keepwork.mall.addModel", "%MAIN%/core/v0/mall/personalModels", "POST", true)

--删除个人模型
--http://yapi.kp-para.cn/project/32/interface/api/7715
HttpWrapper.Create("keepwork.mall.deleteModel", "%MAIN%/core/v0/mall/personalModels/:id", "DELETE", true)

--修改个人模型
--http://yapi.kp-para.cn/project/32/interface/api/7721
HttpWrapper.Create("keepwork.mall.updateModel", "%MAIN%/core/v0/mall/personalModels/:id", "PUT", true)

--查询个人模型列表
--[[
  x-per-page		是	
  x-page		是
]]
--http://yapi.kp-para.cn/project/32/interface/api/7727
HttpWrapper.Create("keepwork.mall.modelList", "%MAIN%/core/v0/mall/personalModels", "GET", true)


