ShopLimitUI = ShopLimitUI or {}

BP_STRUCT_ShopLimitInfo = {
	["id"] = 1,
	["type"] = 1,	--页签
	["typename"] = "",	--页签名称
	["typepic"] = "",
	["gift"] = "",	--礼包名称
	["price"] = 0,	--礼包售价
	["icon"] = "",	--卖场图
	["limit"] = 0,	--限购次数
	["lootid"] = 0,	--掉落方案ID
	["open_time"] = 0,	--开始时间
	["end_time"] = 0,	--结束时间
	["desc"] = "",	--礼包描述
	["current_sold_num"] = 0,	--当前已购买次数
}
BP_ARRAY_ShopLimitList = {
	BP_STRUCT_ShopLimitInfo = BP_STRUCT_ShopLimitInfo
}
BP_ShopLimitBuyId = 0

-- function bp_shoplimit_RegisterUI()
-- 	LuaClassObj.SubUIWidgetList(bp_shoplimit,
-- 		{{Path="/Game/UMG/UI_Logic/ShopLimit/ShopLimit_BP.ShopLimit_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SHOPLIMIT_ZORDER}},
-- 		{"Lobby", "Login"},
-- 		false,
-- 		false
-- 	);

-- 	EventSystem:registEvent(EVENTTYPE_SHOPLIMIT, EVENTID_SHOPLIMIT_TEMPLATECHANGE, ShopLimitUI.RefreshData)
-- 	EventSystem:registEvent(EVENTTYPE_SHOPLIMIT, EVENTID_SHOPLIMIT_BUYINFOCHANGE, ShopLimitUI.RefreshData)
-- end

function bp_shoplimit_OnModeSwitched(gamestatus)
	if string.lower(gamestatus) == "lobby" then
		if ShopLimitUI.timer == nil then
			ShopLimitUI.timer = Timer.InsertTimer(60, ShopLimitUI.HandlerTimer, true)
		end
	else
		if ShopLimitUI.timer ~= nil then
			Timer.RemoveTimer(ShopLimitUI.timer)
		end
	end
end

function ShopLimitUI.HandlerTimer()
	ShopLimitSystem.Req_CheckHash()
end

function ShopLimitUI.RefreshData()
	BP_ARRAY_ShopLimitList = ShopLimitSystem.GetShopLimit()
	LuaClassObj.HandleUIMessage(bp_shoplimit, "UpdateUI")
end

function EventShopLimitShowUI()
    log("================EventShopLimitShowUI")
    LuaClassObj.HandleUIMessage(bp_shoplimit, "ShowUI")
end

function EventShopLimitInitData()
	BP_ARRAY_ShopLimitList = ShopLimitSystem.GetShopLimit()
end

function EventShopLimitBuy_Push()
	log("BP_ShopLimitBuyId : " .. BP_ShopLimitBuyId)
end