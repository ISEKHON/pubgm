OpenBoxtUI = OpenBoxtUI or 
{
	
}

BP_STRUCT_OpenBoxPanel_ItemData =
{
	res_id = 0,
	count = 0,
	valid_hours_str = "",
	product_price = 0,
};

-- 注册面板
function bp_open_box_panel_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_open_box_panel,
		{{Path="/Game/UMG/UI_Logic/Shop/OpenBox_BP.OpenBox_BP_C", Container="Top", ZOrder=BP_ENUM_UI_OPEN_BOX_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
end

local function ShopEventHandler(eventType, eventID, vars)
	if eventID == EVENTID_SHOP_UPDATE_LIST then
		if ShopSystem.LastBuyInfo ~= nil and next(ShopSystem.LastBuyInfo) ~= nil then
			for shopId,_ in pairs(ShopSystem.LastBuyInfo) do
				BP_STRUCT_OpenBoxPanel_ItemData.product_price = ShopSystem.ItemInfoList[shopId].product_gold_price;
				break;
			end
		end
		LuaClassObj.HandleUIMessage(bp_open_box_panel, "UpdatePrice");
	end
end

function OpenBoxtUI:ShowPanel(arrayItemData)
	LuaClassObj.HandleDynamicCreation(bp_open_box_panel);
	EventSystem:registEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST, ShopEventHandler);
	BP_STRUCT_OpenBoxPanel_ItemData = {};

	for k,v in pairs(arrayItemData) do
		if v and v.res_id then
			local item = {}
			item.res_id = v.res_id
			item.count = v.count or 0
			local str = "";
			if v.valid_hours ~= nil and v.valid_hours > 0 then
				if v.valid_hours >= 24 then
					str = string.format(Client.GetTableData("LocalizeRes", "301173").TextValue, tostring(math.ceil(v.valid_hours / 24)));
				else
					str = string.format(Client.GetTableData("LocalizeRes", "301174").TextValue, tostring(v.valid_hours));
				end
			end
			item.valid_hours_str = str;
			if ShopSystem.LastBuyInfo ~= nil and next(ShopSystem.LastBuyInfo) ~= nil then
				for shopId,_ in pairs(ShopSystem.LastBuyInfo) do
					item.product_price = ShopSystem.ItemInfoList[shopId].product_gold_price;
					break;
				end
			else
				item.product_price = 0;
			end
			BP_STRUCT_OpenBoxPanel_ItemData = item;
			break;
		end
	end
	
	LuaClassObj.HandleUIMessage(bp_open_box_panel, "UIShow");
end

--检查打开宝箱
function EventCheckOpenBox()
	--如果打开宝箱获得了高品质物品，则弹高品质物品弹框
	local iteminfo = BP_ARRAY_Item[BP_STRUCT_OpenBoxPanel_ItemData.res_id];
	if iteminfo ~= nil then
		local items = {};
		table.insert(items, BP_STRUCT_OpenBoxPanel_ItemData);
		GoodItemGetUI:ShowGetPanel(items);
	end
	LuaClassObj.HandleUIMessage(bp_open_box_panel, "immediateBtnIn");
end

--再买一次
function EventOpenBoxBuyAgain()
	ShopSystem.shop_buy_req(ShopSystem.LastBuyInfo);
end

function EventAfterHideOpenBox()
	log_tree("33333333333333333333333333333333333333333", ShopSystem.LastBuyInfo);
	EventSystem:unregistEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST, ShopEventHandler);
end

function EventSetInfo_Push()	
end

function EventFetchInfo()
end
