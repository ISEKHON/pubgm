CommonTreasureBoxPopup = CommonTreasureBoxPopup or {}

-- 同步物品掉落列表
BP_STRUCT_DropItem = {
	DropItemID = 0, 
	DropItemNum = 0, 
	DropItemSort = 0
}

BP_STRUCT_ActiveAwardItem = {
	BP_ARRAY_FixItemList = {
		BP_STRUCT_DropItem = BP_STRUCT_DropItem
	},
	BP_ARRAY_RandomItemList = {
		BP_STRUCT_DropItem = BP_STRUCT_DropItem
	}
}

BP_TitleName_String = ""

-- 注册面板
function bp_common_treasurebox_popup_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_common_treasurebox_popup,
		{{Path="/Game/UMG/UI_Logic/Common/Common_TreasureBox_Popup_BP.Common_TreasureBox_Popup_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_TREASUREBOXPOPUP_ZORDER}},
		{"Lobby","Login","Fighting","CreateRole"},
		false,
		false
	);	
end

local function GenDataByID(dropID)
	local tableTaskActiveInfo = Client.GetTableData("TaskActive", dropID)
	if tableTaskActiveInfo == nil then
		log("task active table data not found" .. dropID)
		return
	end

	BP_STRUCT_ActiveAwardItem = {
		BP_ARRAY_FixItemList = {},
		BP_ARRAY_RandomItemList = {}
	}

	local dropTable = GetDropsList({tableTaskActiveInfo.DropID});
    for _,dropInfo in pairs(dropTable) do
    	log("dropInfo.DropItemID")
    	if dropInfo.DropItemWeight >= 1000000 then
    		table.insert(BP_STRUCT_ActiveAwardItem.BP_ARRAY_FixItemList, dropInfo)
    	else
    		table.insert(BP_STRUCT_ActiveAwardItem.BP_ARRAY_RandomItemList, dropInfo)
    	end
    end

    -- local dropTable = Client.GetTable("Drop")
    -- for _,dropInfo in pairs(dropTable) do
    --     if dropInfo.DropID == tableTaskActiveInfo.DropID then
    -- 		local itemInfo = {DropItemID = dropInfo.DropItemID, DropItemNum = dropInfo.DropItemNum, DropItemSort = dropInfo.DropItemSort}
    --     	if dropInfo.Weight >= 1000000 then
    --     		table.insert(BP_STRUCT_ActiveAwardItem.BP_ARRAY_FixItemList, itemInfo)
    --     	else
    --     		table.insert(BP_STRUCT_ActiveAwardItem.BP_ARRAY_RandomItemList, itemInfo)
    --     	end
    --     end
    -- end
    -- table.sort(BP_STRUCT_ActiveAwardItem.BP_ARRAY_FixItemList, function(a, b)
    --     return a.DropItemSort > b.DropItemSort
    -- end)
    -- table.sort(BP_STRUCT_ActiveAwardItem.BP_ARRAY_RandomItemList, function(a, b)
    --     return a.DropItemSort > b.DropItemSort
    -- end)
end 

function CommonTreasureBoxPopup:ShowPanel(dropID)
	GenDataByID(dropID)
	LuaClassObj.HandleUIMessage(bp_common_treasurebox_popup, "UIShow");
end

function CommonTreasureBoxPopup:ClosePanel()
	LuaClassObj.HandleUIMessage(bp_common_treasurebox_popup, "UIClose")
end

function CommonTreasureBoxPopup:SetTitleString(str)
	BP_TitleName_String = str
	LuaClassObj.HandleUIMessage(bp_common_treasurebox_popup, "SetTitle");
end