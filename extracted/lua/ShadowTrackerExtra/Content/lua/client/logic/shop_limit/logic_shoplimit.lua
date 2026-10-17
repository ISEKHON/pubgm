ShopLimitSystem = ShopLimitSystem or {}

function ShopLimitSystem.GetShopLimit()
	local resultList = {}
	local serTime = NetUtil.GetCurServerTime()
	for id, shopLimitInfo in pairs(DataMgr.shopLimit.template) do
		shopLimitInfo.id = id
		shopLimitInfo.current_sold_num = DataMgr.shopLimit.buyInfo[id] or 0
		if shopLimitInfo.open_time < serTime
		and shopLimitInfo.end_time > serTime then
			table.insert(resultList, shopLimitInfo)
		end 
	end

	return resultList
end

function ShopLimitSystem.Req_CheckHash()
	NetUtil.SendPkg("get_direct_buy_list_req", DataMgr.shopLimit.hash)
end