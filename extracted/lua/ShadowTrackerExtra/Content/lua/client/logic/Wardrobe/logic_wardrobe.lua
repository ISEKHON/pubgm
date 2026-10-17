-- 仓库相关逻辑
WardrobeSystem = WardrobeSystem or
{
	sellCount = 0,
}

function WardrobeSystem.Enter()
    if WardrobeSystem.isWardrobeSysInit ~= true then
        --log("WardrobeSystem enter"); 
        WardrobeSystem.isWardrobeSysInit = true;
    end
	
	WardrobeUI:Show();
end

function WardrobeSystem.IsWearValid(insID, serverTime)
	local itemData = DataMgr.GetHallDepotItemDataByInsID(insID);

	if itemData == nil or (itemData.expireTS ~= 0 and itemData.expireTS < serverTime) then
		-- log_tree("WardrobeSystem.IsWearValid", itemData);
		return false;
	end

	return true;
end

function WardrobeSystem.UpdateInvalidWearInfo(invalidIDList)
	-- 处理时装
	local serverTime = FuncUtil.GetServerTimeInSec();
	if DataMgr.rolewear ~= nil then
		local curWear = "";
		for i = #DataMgr.rolewear, 1, -1 do
			curWear = DataMgr.rolewear[i];
			if not WardrobeSystem.IsWearValid(curWear, serverTime) then
				if invalidIDList then
					table.insert(invalidIDList, curWear);
				end
				table.remove(DataMgr.rolewear, i);
				log("WardrobeSystem.UpdateInvalidWearInfo timeout avatar "..tostring(curWear));
			end
		end
	end

	-- 处理降落伞
	if DataMgr.parachute ~= "" and not WardrobeSystem.IsWearValid(DataMgr.parachute, serverTime) then
		DataMgr.parachute = DataMgr.defaultParachuteInsID;
		log("WardrobeSystem.UpdateInvalidWearInfo revert parachute");
	end
end

--请求穿戴
function WardrobeSystem.wardrobe_puton_req(insID)
    log("WardrobeSystem.wardrobe_puton_req ..... " .. insID);
    --NetUtil.SendPkg("depot_put_on_req", tonumber(insID));	
    NetUtil.SendPriorityPkg(true, "depot_put_on_rsp", "depot_put_on_req", tonumber(insID));
end
--请求穿戴返回
function WardrobeSystem.on_puton_rsp(res, item, olditem)	
	log("on_puton_rsp:"..res);
	log_tree("puton_item:", item);
	log_tree("putdown_item:", olditem);
		
	if res == "ok" then		
		local playerData = {};		
		
		
		local itemCfg = Client.GetTableData("Item", item.res_id);
		if itemCfg ~= nil then

			if itemCfg.WardrobeMainTab == 1 then
				-- 更新时装
				if olditem then
					DataMgr.UpdateRoleWearData(tostring(item.instid), tostring(olditem.instid));
				else
					DataMgr.UpdateRoleWearData(tostring(item.instid), "");
				end
				LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, item.res_id), true);
			elseif itemCfg.WardrobeMainTab == 2 then
				-- 更新降落伞
				DataMgr.UpdateParachute(tostring(item.instid));
			end
			WardrobeUI:UpdatePutOnData(item, olditem);
		end
	else
		DataMgr.ShowMessageBoxByID(res);
	end
end

--请求脱下
function WardrobeSystem.wardrobe_put_down_req(insID)
    log("WardrobeSystem.wardrobe_put_down_req ..... " .. insID);
    NetUtil.SendPriorityPkg(true, "depot_put_down_rsp", "depot_put_down_req", tonumber(insID));
end
--请求脱下返回
function WardrobeSystem.on_putdown_rsp(res, item)
	log("on_putdown_rsp:"..res);
	log_tree("putdown_item:", item);

	if res == "ok" then
		DataMgr.UpdateRoleWearData("", tostring(item.instid));

		LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, item.res_id), false);

		WardrobeUI:UpdatePutDownData(item);
	else	
		DataMgr.ShowMessageBoxByID(res);
	end
end


--请求出售
function WardrobeSystem.wardrobe_sell_req(instID, count)
    log("WardrobeSystem.wardrobe_sell_req instID:" .. instID..", count:"..count);
	WardrobeSystem.sellCount = count;
    --NetUtil.SendPkg("depot_sell_item_req", tonumber(instID), count);	
    NetUtil.SendPriorityPkg(true, "depot_sell_item_rsp", "depot_sell_item_req", tonumber(instID), count);
end
--请求出售返回
function WardrobeSystem.on_sell_rsp(res, sellItem)
    log("on_sell_rsp res:" .. res);
	log_tree("selllItem", sellItem);
	
	if res == "ok" then
		-- 弹出金币获得提示
		local itemDataCfg = Client.GetTableData("Item", sellItem.res_id);		
		if itemDataCfg then
			local gold = itemDataCfg.SellPrice * WardrobeSystem.sellCount;
			--local tip = string.format("出售成功，获得<img src=\"GoldImage\"/><MessageGoldColor>%s</>", gold);
			local tip = string.format(Client.GetTableData("LocalizeRes",301164).TextValue, gold);
			tip = (string.gsub(tip, "\'", "\"")); 
			PopUpNoticeUI.ShowNewNotice(tip);
		end
		
		-- 刷新avatar
		if sellItem.count == 0 then
			LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, sellItem.res_id), false);	
		end
		-- 刷新仓库ui
		WardrobeUI:UpdateItemData(sellItem);
	else	
		DataMgr.ShowMessageBoxByID(res);
	end
end

-- 请求使用道具
function WardrobeSystem.wardrobe_use_item_req(instID, count)
	NetUtil.SendPriorityPkg(true, "use_item_rsp", "use_item", tonumber(instID));
end
-- 请求使用道具返回，开宝箱的表现通过open_chest_rsp返回  实现在logic_shop中
function WardrobeSystem.on_use_item_rsp(res, itemData)
	log_tree("WardrobeSystem.on_use_item_rsp", itemData);
	
	if res == "ok" then
		-- 刷新仓库ui
		WardrobeUI:UpdateItemData(itemData);
	else
		DataMgr.ShowMessageBoxByID(res);
		if res == 9910101 then
			WardrobeUI.UpdateTime();
		end
	end
end

-- 取消物品new标签
function WardrobeSystem.wardrobe_change_item_new_status(instID)
	-- log("WardrobeSystem.wardrobe_change_item_new_status instID "..tostring(instID));
	NetUtil.SendPkg("select_item", tonumber(instID));
end


--[[网络回调]]--
--s2c["list_depot_rsp"] = WardrobeSystem.on_itemlist_rsp;
s2c["depot_put_on_rsp"] = WardrobeSystem.on_puton_rsp;
s2c["depot_put_down_rsp"] = WardrobeSystem.on_putdown_rsp;
s2c["depot_sell_item_rsp"] = WardrobeSystem.on_sell_rsp;
s2c["use_item_rsp"] = WardrobeSystem.on_use_item_rsp;