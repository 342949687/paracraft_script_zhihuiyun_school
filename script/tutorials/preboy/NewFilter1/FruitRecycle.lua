--[[
Title: 
Author(s): yq/Leio
Date: 2009/12/24
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/tutorials/preboy/NewFilter1/FruitRecycle.lua");
MyCompany.Aries.Inventory.FruitRecycle.ShowPage();
MyCompany.Aries.Inventory.FruitRecycle.ClosePage();
-------------------------------------------------------
]]
local FruitRecycle = {
	page = nil,
	align = "_ct",
	left = -320,
	top = -280-20,
	width = 640,
	height = 560, 
	
	
	fruits_map = {
		[17001] = true,
		[17002] = true,
		[17003] = true,
		[17004] = true,
		[17044] = true,
	},

	
	selectedItem = nil,
	destroyNum = 0,
	maxNum = 0,
	price = 0,
}
commonlib.setfield("MyCompany.Aries.Inventory.FruitRecycle",FruitRecycle);

function FruitRecycle.OnInit()
	local self = FruitRecycle;
	self.pageCtrl = document:GetPageCtrl();
end

--页面  
function FruitRecycle.ShowPage()
	local self = FruitRecycle;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/tutorials/preboy/NewFilter1/FruitRecycle.html", 
			name = "FruitRecycle.ShowPage", 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			isTopLevel = true,
			allowDrag = false,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 0,
				width = 1000,
				height = 560,
		});
end

--关闭
function FruitRecycle.ClosePage()
	local self = FruitRecycle;
	Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="FruitRecycle.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		bShow = false,bDestroy = true,});
		
	self.destroyNum = nil;
	self.maxNum = nil;
	self.price = nil;
	self.selectedItem = nil;
end

--出售
function FruitRecycle.DoSell()
	local self = FruitRecycle;
	if(self.selectedItem)then
		local gsid = self.selectedItem.gsid;
		
		local destroyNum = self.pageCtrl:GetValue("count");
		local price = self.price;
		--local s = string.format("你打算出售：%d，数量为%d个，单价：%d",gsid,destroyNum or 0,price);
		--_guihelper.MessageBox(s);
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/tutorials/preboy/NewFilter1/ConfirmTrade.html", 
			name = "ConfirmTrade.ShowPage", 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			isTopLevel = true,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = 0,
				y = 0,
				width = 300,
				height = 250,
				
		});
		return MyCompany.Aries.Inventory.ConfirmTrade.SetGUID(guid);
		
		  
	end
	
end

--选择果实
function FruitRecycle.DoClick(guid)
	local self = FruitRecycle;
	local ItemManager = Map3DSystem.Item.ItemManager;
	local item = ItemManager.GetItemByGUID(guid);
	if(item)then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid)
		if(gsItem) then
			--commonlib.echo(gsItem);
			self.maxNum = item.copies;
			self.price = gsItem.psellprice;
			self.selectedItem = gsItem;
			if(self.pageCtrl)then
				self.pageCtrl:SetValue("count",1);
				self.pageCtrl:SetValue("icon",gsItem.icon);
				self.pageCtrl:Refresh();
			end
		end
	end
end

-- The data source for items
function FruitRecycle.DS_Func_Items(dsTable, index, pageCtrl)      
	-- get the class of the 
	local class = "character";
	local subclass = "collect";
	
    if(not dsTable.status) then
        -- use a default cache
        FruitRecycle.GetItems(class, subclass, pageCtrl, "access plus 0", dsTable)
    elseif(dsTable.status == 2) then    
        if(index == nil) then
			return dsTable.Count;
        else
			return dsTable[index];
        end
    end 
end

--物品包裹数量
function FruitRecycle.GetItems(class, subclass, pageCtrl, cachepolicy, output)
	local self = FruitRecycle;
	-- find the right bag for inventory items
	local bag;
	if(class == "character" and subclass == "makeup") then
		bag = 1;
	elseif(class == "character" and subclass == "consumable") then
		bag = 81;
	elseif(class == "character" and subclass == "collect") then
		bag = 12;
	elseif(class == "character" and subclass == "reading") then
		bag = 10001;
	elseif(class == "mount" and subclass == "makeup") then
		bag = 21;
	elseif(class == "mount" and subclass == "feed") then
		bag = 22;
	end
	if(bag == nil) then
		-- return empty datasource table, if no bag id is specified
		output.Count = 0;
		commonlib.resize(output, output.Count)
		return;
	end
	-- fetching inventory items
	output.status = 1;
	local ItemManager = System.Item.ItemManager;
	ItemManager.GetItemsInBag(bag, "ariesitems", function(msg)
		if(msg and msg.items) then
			local count = ItemManager.GetItemCountInBag(bag);
			commonlib.echo(count);
			if(count == 0) then
				count = 1;
			end
			-- fill the 12 tiles per page
			count = math.ceil(count/12) * 12;
			local i;
			for i = 1, count do
				local item = ItemManager.GetItemByBagAndOrder(bag, i);
				--如果是果实
				if(item ~= nil and item.gsid and self.fruits_map[item.gsid]) then
					output[i] = {guid = item.guid};
				else
					output[i] = {guid = 0};
				end
			end
			output.Count = count;
			commonlib.resize(output, output.Count);
			-- fetched inventory items
			output.status = 2;
			pageCtrl:Refresh();
		else
			output.Count = 0;
			commonlib.resize(output, output.Count);
			-- fetched inventory items
			output.status = 2;
			pageCtrl:Refresh();
		end
	end, cachepolicy);
end
--page:Refresh(0);
