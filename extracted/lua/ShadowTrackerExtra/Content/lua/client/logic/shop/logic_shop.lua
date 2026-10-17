
--[[
 商城相关逻辑
]]--

ShopSystem = ShopSystem or
{
	--可售商品总表
	ItemInfoList = {},
	--上次购买的商品id
	LastBuyInfo = {},
}

function ShopSystem.Enter()
	log("ShopSystem enter"); 
	ShopSystem.shop_itemlist_req();
end

--请求物品列表
function ShopSystem.shop_itemlist_req()
	log("shop_itemlist_req");
	--NetUtil.SendPkg("shop_itemlist_req");
	NetUtil.SendPriorityPkg(true, "shop_itemlist_rsp", "shop_itemlist_req");
end

--请求单个物品信息
function ShopSystem.get_single_shopitem(shop_item_id)
	log("get_single_shopitem");
	NetUtil.SendPriorityPkg(true, "get_single_shopitem_rsp", "get_single_shopitem", shop_item_id);
end

--请求购买
function ShopSystem.shop_buy_req(itemsInfo)
	log("shop_buy_req");
	if itemsInfo == nil or next(itemsInfo) == nil then
		return;
	end
	ShopSystem.LastBuyInfo = itemsInfo;
	NetUtil.SendPriorityPkg(true, "shop_buy_rsp", "shop_buy_req", itemsInfo);
end

--获取列表响应
function ShopSystem.on_itemlist_rsp(res, itemlist)
	log("on_itemlist_rsp: " .. res);
	    
      --刷新列表信息
    if res == "ok" then
		ShopSystem.ItemInfoList = {};
		
		for k,v in pairs(itemlist) do
			local shopId = tonumber(k);
			local shopdata = Client.GetTableData("ShopItem", shopId);
			if shopdata ~= nil then
				local icon;
				for _,chestDropInfo in pairs(BP_ARRAY_ChestDrop) do
					if chestDropInfo.ChestID == shopdata.ItemID then
						icon = chestDropInfo.ChestIcon;
						break;
					end
				end
				ShopSystem.ItemInfoList[shopId] = 
				{
					product_id = shopdata.ProductID,
					item_id = shopdata.ItemID,
					pruduct_name = translate(shopdata.ProductName),
					product_desc = shopdata.ProductDesc,
					product_type = shopdata.ProductType,
					product_sub_type = shopdata.ProductSubType,
					product_gold_price = v.gold_price,
					product_sort = shopdata.ProductSort,
					item_icon = icon,
				};
			end
		end

		log_tree("ItemInfoList", ShopSystem.ItemInfoList);
		--更新商店蓝图数据
		EventSystem:postEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST);     
	
    else
       sandbox.LogNormal("on_itemlist_rep failed ");
    end
end

function ShopSystem.get_single_shopitem_rsp(res, shop_item)
	log("get_single_shopitem_rsp: " .. res);
	    
    if res == "ok" then
		local shopId = tonumber(shop_item.itemid);
		local iteminfo = ShopSystem.ItemInfoList[shopId];
		if iteminfo ~= nil then
			local update = iteminfo.product_gold_price ~= shop_item.gold_price;
			--价格发生变化才更新界面
			if update then
				iteminfo.product_gold_price = shop_item.gold_price;
				--更新商店蓝图数据
				EventSystem:postEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST);
			end
			if ShopUI.isBuying == true then
				--弹出购买提示框
				ShopUI:BuyItem(shopId);
			end
		end
    end
end

--购买物品响应
function ShopSystem.on_buy_rsp(res, itemlist)
    if res == "ok" then
		sandbox.LogNormal("on_buy_rsp success ");
		--拉取购买商品的id
		ShopUI.isBuying = false;
		for k,v in pairs(itemlist) do
			local shopId = tonumber(k);
			ShopSystem.get_single_shopitem(shopId);
		end
		--某些物品需要弹出获得提示
		local arrayItemData = {};
		for k,v in pairs(itemlist) do
			local shopId = tonumber(k);
			local iteminfo = ShopSystem.ItemInfoList[shopId];
			if iteminfo ~= nil then
				local itemdata = Client.GetTableData("Item", iteminfo.item_id);
				if itemdata ~= nil and itemdata.ItemSubType ~= 1501 then
					--不是商城直接购买打开的道具加入数组
					table.insert(arrayItemData, {res_id = iteminfo.item_id, count = v});
				end

			end
		end
		if #arrayItemData > 0 then
			CommonItemGetUI:ShowPanel(arrayItemData);
		end
    else
		sandbox.LogNormal("on_buy_rsp failed ");
		DataMgr.ShowNoticeByID(res);
    end
end

--宝箱开启响应
function ShopSystem.on_open_chest_rsp(res, chestid, itemlist, reason)
	log("on_open_chest_rsp: " .. res);
    --刷新列表信息
    if res == "ok" then
		sandbox.LogNormal("on_open_chest_rsp success ");
		local arrayItemData = {};
		for k,v in pairs(itemlist) do
			local h = v.valid_hours or 0;
			table.insert(arrayItemData, {res_id = v.resid, count = v.count, valid_hours = h});
		end
		if reason ~= 1 then
			CommonItemGetUI:ShowPanel(arrayItemData);
		else
			OpenBoxtUI:ShowPanel(arrayItemData);
		end
    else
		sandbox.LogNormal("on_open_chest_rsp failed ");
		DataMgr.ShowNoticeByID(res);
    end
end

--[[网络回调]]--
s2c["shop_itemlist_rsp"] = ShopSystem.on_itemlist_rsp;
s2c["get_single_shopitem_rsp"] = ShopSystem.get_single_shopitem_rsp;
s2c["shop_buy_rsp"] = ShopSystem.on_buy_rsp;
s2c["open_chest_rsp"] = ShopSystem.on_open_chest_rsp;

