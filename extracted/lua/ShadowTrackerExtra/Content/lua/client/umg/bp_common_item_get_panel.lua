CommonItemGetUI = CommonItemGetUI or 
{
	onClickCallback,
	disableGoodItem,
}

BP_STRUCT_ItemGetPanel_ItemData =
{
	res_id = 0,
	count = 0,
	valid_hours = 0,
	expire_ts = 0,
};
BP_ARRAY_ItemGetPanel_ItemData =
{
    BP_STRUCT_ItemGetPanel_ItemData = _G.BP_STRUCT_ItemGetPanel_ItemData, --定义结构体数组，这种写法要作为规范规定下来
};

-- 注册面板
function bp_common_item_get_panel_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_common_item_get_panel,
		{{Path="/Game/UMG/UI_Logic/Common/Common_Item_Get_Panel_BP.Common_Item_Get_Panel_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_ITEM_GET_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
end

-- 显示物品获得面板
--[[
	array
		BP_STRUCT_ItemGetPanel_ItemData
			res_id
			count			
			...
]]
function CommonItemGetUI:ShowPanel(arrayItemData)
	LuaClassObj.HandleDynamicCreation(bp_common_item_get_panel);
	--log_tree("CommonItemGetUI:ShowPanel", arrayItemData);
	CommonItemGetUI.onClickCallback = nil
	CommonItemGetUI.disableGoodItem = false

	BP_ARRAY_ItemGetPanel_ItemData = {};	

	--拷贝一份免得部分模块缺少字段
	for k,v in pairs(arrayItemData) do
		if v and v.res_id then
			local item = {}
			item.res_id = v.res_id
			item.count = v.count or 0
			item.valid_hours = v.valid_hours or 0
			item.expire_ts = v.expire_ts or 0
			BP_ARRAY_ItemGetPanel_ItemData[#BP_ARRAY_ItemGetPanel_ItemData + 1] = item
		end
	end
	
	LuaClassObj.HandleUIMessage(bp_common_item_get_panel, "UIShow");
end

function CommonItemGetUI:ShowPanelWithCallback(arrayItemData,callback ,disableGoodItem)	
	CommonItemGetUI:ShowPanel(arrayItemData)
	CommonItemGetUI.onClickCallback = callback
	CommonItemGetUI.disableGoodItem = disableGoodItem
end

function EventTryToShowGetPanel()
	if CommonItemGetUI.disableGoodItem == false then
		GoodItemGetUI:ShowGetPanel(BP_ARRAY_ItemGetPanel_ItemData);
	end
	
	if CommonItemGetUI.onClickCallback ~= nil then
		CommonItemGetUI.onClickCallback()
		CommonItemGetUI.onClickCallback = nil
	end 
end

function EventCommonItemGetShowPanel_Push()	
    log("EventCommonItemGetShowPanel_Push");
end

function CommonItemGetUI:Hide()
	BP_ARRAY_ItemGetPanel_ItemData = {};
	if CommonItemGetUI.onClickCallback ~= nil then
		CommonItemGetUI.onClickCallback()
		CommonItemGetUI.onClickCallback = nil
	end
    LuaClassObj.HandleUIMessage(bp_common_item_get_panel, "UIHide");
end
