CommonItemTipsUI = CommonItemTipsUI or {}

BP_CommonItemTips_ItemID =0;

--手动输入状态下，输入点击位置或者按钮位置，panel再计算摆放
BP_STRUCT_CommonItemTips_Pos = { x = 0,y = 0}

BP_CommonItemTips_OwningText = ""

local item_time_info = {}
-- 注册面板
function bp_common_itemtips_panel_RegisterUI()
	log("CommonItemTipsUI:bp_common_itemtips_panel_RegisterUI");
	LuaClassObj.SubUIWidgetList(bp_common_itemtips_panel,
		{{Path="/Game/UMG/UI_Logic/Common/Common_ItemTips_Panel_BP.Common_ItemTips_Panel_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_ITEMTIPS_ZORDER}},
		{"Lobby","Login","Fighting","CreateRole"},
		false,
		false
	);	
end

function CommonItemTipsUI:ShowPanel(itemID,pos)
	BP_CommonItemTips_ItemID = itemID
    BP_STRUCT_CommonItemTips_Pos = pos
	LuaClassObj.HandleUIMessage(bp_common_itemtips_panel, "UIShow");
end

function CommonItemTipsUI:SetPanelTimeInfo(time_info)
	item_time_info = time_info
end

function CommonItemTipsUI:ClosePanel()
	LuaClassObj.HandleUIMessage(bp_common_itemtips_panel, "UIClose")
end

local function GetItemNum(itemID)
	log("查询id：" .. itemID)
	local itemData = DataMgr.GetHallDepotItemDataByResID(itemID)
	if itemData == nil then
		return 0
	else
		return itemData.count
	end
end

function EventCommonItemTipsGetOwningText_Push()
	log("------------itemid:" .. BP_CommonItemTips_ItemID );

	--头像框数据需要查表
	local itemData = Client.GetTableData("Item", BP_CommonItemTips_ItemID)
	local owningText = " "
	if BP_CommonItemTips_ItemID == 1000 then
		--金币不显示
		
		--owningText = "拥有金币 " .. DataMgr.gold
		--owningText = string.format(Client.GetTableData("LocalizeRes", "301220").TextValue, DataMgr.gold);
	-- elseif BP_CommonItemTips_ItemID == 1001 then
	-- 	owningText = "拥有钻石 " .. DataMgr.roleData.attr_type_diamond
	elseif BP_CommonItemTips_ItemID == 1003 then
		local  curlevel = tonumber(DataMgr.roleData.level)
		local  nextLevelExp = ""
		if curlevel > 0 and curlevel < 100 then
			local curmilitarylevel = Client.GetTableData("MilitaryRankLevel", curlevel);
			nextLevelExp = tostring(curmilitarylevel.Exp);
		end
		--owningText = "当前经验 " .. RoleInfoSystem.PersonalBasicInfo["role_curexpnum"].. "/" .. RoleInfoSystem.PersonalBasicInfo["role_needexpnum"] 
		owningText = Client.GetTableData("LocalizeRes", "301221").TextValue .. DataMgr.roleData.roleExp .. "/" .. nextLevelExp
	elseif BP_CommonItemTips_ItemID == 1004 then
		owningText = string.format(Client.GetTableData("LocalizeRes", "301222").TextValue, DataMgr.activeness.value);
	elseif itemData.ItemType == 20 then 
		--头像框不显示

	else
		--owningText = "拥有 " .. GetItemNum(BP_CommonItemTips_ItemID)  .. "个" 
		owningText = string.format(Client.GetTableData("LocalizeRes", "301222").TextValue, GetItemNum(BP_CommonItemTips_ItemID));
	end
	

	--限时物品显示过期时间
	if item_time_info and item_time_info.is_limit and item_time_info.time_s ~= "" then
		BP_CommonItemTips_OwningText = item_time_info.time_s
	else
		BP_CommonItemTips_OwningText = owningText
	end

	log("BP_CommonItemTips_OwningText ="..BP_CommonItemTips_OwningText)
end
