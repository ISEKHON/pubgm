----商店UI
ShopUI = ShopUI or
{
	isShow = false;
	--avatar列表
	avatar_indexes = {};
	--是否要购买
	isBuying = false;
	--自动指定跳转某个商品
	auto_product_id = nil;
}


--选中类型
BP_SelectType = 4;
BP_SelectSubType = 1;

--要买的商品id
BP_SHOP_Buy_Shop_Item_ID = 0;

--要查看的商品id
BP_SHOP_Look_Shop_Item_ID = 0;

--点击换装的物品索引，可能选中的是不能换装的物品
BP_SHOP_Avatar_Item_Index = -1;
--要脱掉的换装物品索引
BP_SHOP_PutOff_Avatar_Index = -1;

--商城金币
BP_SHOP_GOLD = 0;

--物品信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_Shop_ItemInfo =
{
	product_id = 0,
	item_id = 0,
	pruduct_name = "商品名",
	product_desc = "商品描述",
	product_type = 0,
	product_sub_type = 0,
	product_gold_price = 0,
	product_sort = 1,
	item_icon = "",
};

--物品信息列表(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
BP_ARRAY_Shop_ItemList = 
{
	BP_STRUCT_Shop_ItemInfo=_G.BP_STRUCT_Shop_ItemInfo, --定义结构体数组，这种写法要作为规范规定下来
};

BP_STRUCT_Shop_DropInfo =
{
	DropItemID = 0,
	DropItemNum = 0,
	DropItemTime = 0,
	DropItemSort = 1;
};

--要查看的商品可能掉落的物品列表
BP_ARRAY_Look_DropList =
{
	BP_STRUCT_Shop_DropInfo=_G.BP_STRUCT_Shop_DropInfo,
};

--注册Widget
function bp_shop_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_shop,
		{{Path="/Game/UMG/UI_LOGIC/Shop/Shop_BP.Shop_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SHOP_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHOP, UrlModuleHandler);
end

function UrlModuleHandler(eventType, eventID, vars)
	ShopUI.auto_product_id = vars.productId;
	EventEnterShop();
end

local function ShopEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_SHOP then
		return;
	end
	
	if eventID == EVENTID_SHOP_UPDATE_LIST then
		log("EVENTID_SHOP_UPDATE_LIST");
		ShopUI:UnifyData();  
		if LuaClassObj ~= nil then
			LuaClassObj.HandleUIMessage(bp_shop, "UpdateShopItemList");
			if ShopUI.auto_product_id ~= nil then
				--自动选中指定商品
				BP_SHOP_Look_Shop_Item_ID = ShopUI.auto_product_id;
				ShopUI.auto_product_id = nil;
				LuaClassObj.HandleUIMessage(bp_shop, "LookSelectItem");
			end
		end
	end
end

local function GoldChange(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_DATA_MGR then
		return;
	end
	
	if eventID == EVENTID_DATAMGR_GOLD_CHANGE then
		log("EVENTID_DATAMGR_GOLD_CHANGE");
        BP_SHOP_GOLD = DataMgr.gold;
		if LuaClassObj ~= nil then
			LuaClassObj.HandleUIMessage(bp_shop, "UpdateGold");
		end
	end
end

-- 商城是否正在初始化标签
BP_SHOP_ISINITING = false

function ShopUI:Init()
	LuaClassObj.HandleDynamicCreation(bp_shop);
	
	log("ShopUI_Init");
	ShopUI.isBuying = false;
    BP_SHOP_GOLD = DataMgr.gold;
	if ShopUI.isShow == false then
		LuaClassObj.HandleUIMessage(bp_shop, "UIShow");
		LobbyUI:SwitchToTeamorMenuCamera(true);
		TeamUpUI.OnCameraSwitch();
		ShopUI.isShow = true;
	end
	EventSystem:registEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST, ShopEventHandler);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, GoldChange);
    BP_SHOP_ISINITING = true
    LuaClassObj.HandleUIMessage(bp_shop, "UpdateGold");
    BP_SHOP_ISINITING = false
end

function ShopUI:Release()
	log("ShopUI_Release");
	ShopUI.isShow = false;
	ShopUI.isBuying = false;
	EventSystem:unregistEvent(EVENTTYPE_SHOP, EVENTID_SHOP_UPDATE_LIST, ShopEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, GoldChange);
	EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHOP, UrlModuleHandler);
end

--组织数据
function ShopUI:UnifyData()
	log("ShopUI_UnifyData");
	BP_ARRAY_Shop_ItemList = {};
	for k,v in pairs(ShopSystem.ItemInfoList) do
		table.insert(BP_ARRAY_Shop_ItemList, v);
	end
	table.sort(BP_ARRAY_Shop_ItemList, function(a, b)
		return a.product_sort < b.product_sort
	end);
end

--(以Event开头的函数名就能暴露给蓝图调用)

--请求购买物品
function EventRequestBuyItem()
	local shopdata = Client.GetTableData("ShopItem", math.floor(BP_SHOP_Buy_Shop_Item_ID));
	if shopdata == nil then
		return;
	end
	local serverdata = ShopSystem.ItemInfoList[shopdata.ProductID];
	if serverdata == nil then
		return;
	end
	ShopUI.isBuying = true;
	ShopSystem.get_single_shopitem(shopdata.ProductID);
end
function ShopUI:BuyItem(shop_item_id)
	local shopdata = Client.GetTableData("ShopItem", shop_item_id);
	if shopdata == nil then
		return;
	end
	local serverdata = ShopSystem.ItemInfoList[shopdata.ProductID];
	if serverdata == nil then
		return;
	end
	local strBuy = Client.GetTableData("LocalizeRes", "301185").TextValue;
	--local tip = string.format("是否以<img src=\"GoldImage\"/><MessageGoldColor>%s</>购买<MessageProductColor>%s</>?", serverdata.product_gold_price, shopdata.ProductName);	
	local tip = FuncUtil.GetLocalizeResStr("301186");	
	tip = (string.gsub(tip, "\'", "\"")); 
	tip = string.format(tip, serverdata.product_gold_price, shopdata.ProductName);
	log("buyItem: " .. tip);
	CommonMessageBoxUI:ShowPanel(2, strBuy, tip, function()
		local buyItemData = {[BP_SHOP_Buy_Shop_Item_ID] = {count=1, moneytype=1}};
		ShopSystem.shop_buy_req(buyItemData);
		return true;
	end);
end

--请求查看物品
function EventLookItem()
	--脱掉所有穿戴
	local avatar_data = {};
	avatar_data.gid = DataMgr.roleData.uid;
	for k,v in pairs(ShopUI.avatar_indexes) do
		if v ~= nil then
			local dropInfo = BP_ARRAY_Look_DropList[v + 1];
			if dropInfo ~= nil then
				avatar_data.resId = dropInfo.DropItemID;
				LobbyUI:AvatarChange(avatar_data, false);
			end
		end
    end
	BP_SHOP_Avatar_Item_Index = -1;
	BP_SHOP_PutOff_Avatar_Index = -1;
	ShopUI.avatar_indexes = {};
	--穿上原始穿戴
    for k,v in pairs(DataMgr.rolewear) do
        local itemdata = DataMgr.GetHallDepotItemDataByInsID(v);
        if itemdata ~= nil then
			avatar_data.resId = itemdata.resID;
			LobbyUI:AvatarChange(avatar_data, true);
        end
	end
	--设置查看商品的掉落物品信息
	BP_ARRAY_Look_DropList = {};
	local shopdata = Client.GetTableData("ShopItem", math.floor(BP_SHOP_Look_Shop_Item_ID));
	if shopdata == nil then
		return;
	end
	local lookShopItemId = shopdata.ItemID;
	local chestDropTable = Client.GetTable("ChestDrop");
	local dropIds = {};
	for _,chestDrop in pairs(chestDropTable) do
		if chestDrop.ChestID == lookShopItemId then
			table.insert(dropIds, chestDrop.DropID);
		end
	end
	BP_ARRAY_Look_DropList = GetDropsList(dropIds);
	--打开ui
	LuaClassObj.HandleUIMessage(bp_shop, "ShowChestInfoPanel");
end

--换装
function EventShopChangeAvatar()
	local dropInfo = BP_ARRAY_Look_DropList[BP_SHOP_Avatar_Item_Index + 1];
	if dropInfo == nil then
		return;
	end
	local itemdata = Client.GetTableData("Item", dropInfo.DropItemID);
	if itemdata.ItemType ~= 4 then
		--不是形象道具
		return;
	end
	local last_item_index = ShopUI.avatar_indexes[itemdata.ItemSubType];
	local avatar_data = {};
	avatar_data.gid = DataMgr.roleData.uid;
	if last_item_index == nil or last_item_index == -1 then
		--如果之前没有穿戴同类型的道具，进行穿戴
		log("初次穿戴" .. itemdata.ItemID);
		avatar_data.resId = itemdata.ItemID;
		LobbyUI:AvatarChange(avatar_data, true);
		ShopUI.avatar_indexes[itemdata.ItemSubType] = BP_SHOP_Avatar_Item_Index;
		LuaClassObj.HandleUIMessage(bp_shop, "PutOnAvatar");
	elseif last_item_index == BP_SHOP_Avatar_Item_Index then
		--如果点击的是相同的道具，脱掉穿戴
		log("脱掉" .. itemdata.ItemID);
		avatar_data.resId = itemdata.ItemID;
		LobbyUI:AvatarChange(avatar_data, false);
		ShopUI.avatar_indexes[itemdata.ItemSubType] = nil;
		BP_SHOP_PutOff_Avatar_Index = last_item_index;
		LuaClassObj.HandleUIMessage(bp_shop, "PutOffAvatar");
	else
		--如果点击了不同道具，但已经穿戴了相同道具，进行替换
		log("替换穿戴" .. itemdata.ItemID);
		avatar_data.resId = itemdata.ItemID;
		LobbyUI:AvatarChange(avatar_data, true);
		ShopUI.avatar_indexes[itemdata.ItemSubType] = BP_SHOP_Avatar_Item_Index;
		LuaClassObj.HandleUIMessage(bp_shop, "PutOnAvatar");
		BP_SHOP_PutOff_Avatar_Index = last_item_index;
		LuaClassObj.HandleUIMessage(bp_shop, "PutOffAvatar");
	end
end

--隐藏界面
function EventShopHide()
	log("ShopHide");
	ShopUI.isShow = false;
	--脱掉所有穿戴
	local avatar_data = {};
	avatar_data.gid = DataMgr.roleData.uid;
	for k,v in pairs(ShopUI.avatar_indexes) do
		if v ~= nil then
			local dropInfo = BP_ARRAY_Look_DropList[v + 1];
			if dropInfo ~= nil then
				avatar_data.resId = dropInfo.DropItemID;
				LobbyUI:AvatarChange(avatar_data, false);
			end
		end
    end
	--穿上原始穿戴
    for k,v in pairs(DataMgr.rolewear) do
		local itemdata = DataMgr.GetHallDepotItemDataByInsID(v);
        if itemdata ~= nil then
			avatar_data.resId = itemdata.resID;
			LobbyUI:AvatarChange(avatar_data, true);
        end
	end
	BP_SHOP_Avatar_Item_Index = -1;
	BP_SHOP_PutOff_Avatar_Index = -1;
	ShopUI.avatar_indexes = {};
	--LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_CloseMenu");
    LobbyUI:SwitchToMainCamera(true)
    LuaClassObj.HandleUIMessage(bp_lobby, "ResetBtnSprites");
	TeamUpUI.OnCameraSwitch();
end

--显示帮助提示
function EventShowHelpTip()
	local shopdata = Client.GetTableData("ShopItem", math.floor(BP_SHOP_Look_Shop_Item_ID));
	if shopdata == nil then
		return;
	end
	local chestdropdata = Client.GetTableData("ChestDrop", shopdata.ItemID);
	if chestdropdata == nil then
		return;
	end
	local tip = string.gsub(chestdropdata.DropDesc, "#", "\n");
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "301184").TextValue, tip);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end