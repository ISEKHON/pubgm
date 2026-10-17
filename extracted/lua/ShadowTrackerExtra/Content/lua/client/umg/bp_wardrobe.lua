--仓库UI
WardrobeUI = WardrobeUI or
{
	-- 仓库页签与道具类型关系
	structTabAndItemTypeRelationship = 
	{
		[0] = {tabType = 0, itemType = 0},
		[401] = {tabType = 1, itemType = 401}, -- 头
		[402] = {tabType = 2, itemType = 402}, -- 面具
		[403] = {tabType = 3, itemType = 403}, -- 上衣
		[404] = {tabType = 4, itemType = 404}, -- 裤子
		[405] = {tabType = 5, itemType = 405}, -- 鞋
	},

	mainTabToSubTabArray =
	{
		[1] = {401, 402, 403, 404, 405},
		[2] = {701},
		[3] = {1502},
	};

	-- 仓库大页签与类型关系
	structPageToMainTabType =
	{
		[0] = 1,
		[1] = 3,
		[2] = 2,
	};
	
	isShowing = false,
	needShowRedPoint = false,
	
	redPointTabType = {},

	currentWearPreviewMap = {},
	wearPreviewInfo = {insID = "", resID = 0},

	defaultParachuteResID = 0,

	secToHour = 1 / 3600,
	hourToDay = 1 / 24,

	pageTypeMask = {1, 2, 4},
	saveIsShowing = false,
}

--仓库物品信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
--仓库格子数据
BP_STRUCT_WardrobeItemInfo =
{
    ins_id = "",
	res_id = 0,
    count = 0,
	is_using = false,
	is_new = false,
	is_selected = false,
	is_sourcebook = false, -- 是否为图鉴
	validHours = 0,
	expireTS = 0,
	itemSubType = 0,
	itemQuality = 0,
};

--仓库物品信息列表(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
-- 当前页签的item列表
BP_ARRAY_WardrobeItemList = 
{
	BP_STRUCT_WardrobeItemInfo = _G.BP_STRUCT_WardrobeItemInfo, --定义结构体数组，这种写法要作为规范规定下来
};

BP_ARRAY_Wardrobe_SourceBookItemList =
{
	BP_STRUCT_WardrobeItemInfo = _G.BP_STRUCT_WardrobeItemInfo, --定义结构体数组，这种写法要作为规范规定下来
};

-- 当前页签类型
BP_CurTabType = 0;
-- 大页签类型
BP_CurPageTabType = 0;

-- 仓库金币数值
BP_WardrobeGold = 0;
-- 卖出的item的insID
BP_Sell_id = "";

-- 变化的item数据
BP_STRUCT_WardrobeChangedItemData = _G.BP_STRUCT_WardrobeItemInfo;
-- 点击的item数据
BP_STRUCT_WardrobeClickedItemData = _G.BP_STRUCT_WardrobeItemInfo;

-- 点击的item数据
-- BP_ClickItemInsID = "";
-- BP_ClickItemUsingState = false;

-- tabIcon变化信息
BP_ChangeTabType = 0;
BP_ChangeTabIcon = 0;

-- 用于数值通讯的大页签tab类型
BP_ChangePageTabType = 0;

BP_LastPageType = 0;
-- 需要显示小红点的tab类型
BP_LastTabType = 0;

-- 需要跳转的物品ID
BP_WARDROBE_Jump_Item_resID = 0;

-- 显示的背景ID
BP_Wardrobe_BG_resID = 0;
-- 是否显示装备中
BP_Wardrobe_BG_showPutOn = true;

-- 显示的剩余时间
BP_String_Wardrobe_RemainTime = "";
BP_IsShowUseButton = true;

BP_PageRedPointMask = 0;
BP_TabRedPointMask = 0;

function bp_wardrobe_RegisterUI()		
	LuaClassObj.SubUIWidgetList(bp_wardrobe,
		{{Path="/Game/UMG/UI_Logic/Wardrobe/Wardrobe_BP.Wardrobe_BP_C", Container="Default", ZOrder=BP_ENUM_UI_WARDROBE_ZORDER}},
		{"Lobby"},
		false,
		bp_wardrobe_OnModeSwitched ~= nil,
		true
	);
	
	BP_STRUCT_WardrobeChangedItemData = {};
	BP_STRUCT_WardrobeClickedItemData = {};
end

function bp_wardrobe_OnModeSwitched(gamestatus)
	log("bp_wardrobe_OnModeSwitched" .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
		WardrobeUI:Init();
	end
end

function WardrobeEventHandler(eventType, eventID, vars)
    log("WardrobeEventHandler:" .. eventID);	
	
    if eventID == EVENTID_DATAMGR_GOLD_CHANGE then
		if LuaClassObj and WardrobeUI.isShowing then			
			BP_WardrobeGold = DataMgr.gold;	
			LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateGold");	
		end
	elseif eventID == EVENTID_DATAMGR_HALL_DEPOT_ADD_NEW then
		--WardrobeUI.needShowRedPoint = true;		
		--log_tree("vars", vars);
		local itemCfg = {};
		for k,v in pairs(vars) do		
			itemCfg = Client.GetTableData("Item", v.res_id);
			if itemCfg then
				-- 更新仓库页签红点			
				if itemCfg.WardrobeMainTab == 1 and WardrobeUI.structTabAndItemTypeRelationship[itemCfg.ItemSubType] then
					-- 时装
					WardrobeUI:UpdatePanelRedPoint(true, 0, WardrobeUI.structTabAndItemTypeRelationship[itemCfg.ItemSubType].tabType);
				elseif itemCfg.WardrobeMainTab == 2 then
					-- 降落伞
					WardrobeUI:UpdatePanelRedPoint(true, 2, 0);
				elseif itemCfg.WardrobeMainTab == 3 then
					-- 道具
					WardrobeUI:UpdatePanelRedPoint(true, 1, 0);
					-- 当前物品是道具时，刷新面板
					if WardrobeUI.isShowing and BP_CurPageTabType == 1 then
						WardrobeUI.UpdateItemList();
					end
				end
			end
		end		
	elseif eventID == EVENTID_BACKLOGIN then
		-- 清理数据
		WardrobeUI.redPointTabType = {};
		WardrobeUI.isShowing = false;
    end
end


function WardrobeUI:Init()
	log("WardrobeUI Init");				
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, WardrobeEventHandler);	
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_ADD_NEW, WardrobeEventHandler);	
    EventSystem:registEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, WardrobeEventHandler);	
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, WardrobeUI.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, WardrobeUI.WardRobeAvatarResetClose);
end
function WardrobeUI:Release()
    log("WardrobeUI Release");
	EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, WardrobeEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_ADD_NEW, WardrobeEventHandler);	
    EventSystem:unregistEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, WardrobeEventHandler);	
	EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, WardrobeUI.WardRobeAvatarResetOpen);
	EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, WardrobeUI.WardRobeAvatarResetClose);
	isShowing = false;
end


function WardrobeUI:WardRobeAvatarResetOpen()
    log("WardrobeUI.WardRobeAvatarResetOpen")
    WardrobeUI.saveIsShowing = WardrobeUI.isShowing;
    WardrobeUI.isShowing = false;
    LuaClassObj.HandleUIMessage(bp_wardrobe, "UIHideNative");
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_CLOSE);
end

function WardrobeUI:WardRobeAvatarResetClose()
    log("WardrobeUI.WardRobeAvatarResetClose")
    if WardrobeUI.saveIsShowing then
    	WardrobeUI:Show();
    end
end


-- 打开仓库面板
function WardrobeUI:Show()    
	LuaClassObj.HandleDynamicCreation(bp_wardrobe);
	
	if WardrobeUI.isShowing then
		return;
	end
	--log("WardrobeUI Show");
	WardrobeUI.isShowing = true;
	
	-- 脱下avata过时时装
	WardrobeUI.PutOffTimeOutWear();
	-- 默认时装页签
	BP_CurTabType = 0;
	BP_CurPageTabType = 0;
	
	BP_WardrobeGold = DataMgr.gold;	
	-- 打开面板
	-- 更新金币
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateGold");	
	-- 更新tabIcon
	WardrobeUI.currentWearPreviewMap = {}
	for k,v in pairs(DataMgr.rolewear) do
		--log("DataMgr.rolewear ".. v);
		local itemData = DataMgr.GetHallDepotItemDataByInsID(v);
		--log_tree("wearItem", itemData);
		if itemData and WardrobeUI.structTabAndItemTypeRelationship[itemData.itemSubType] then
			BP_ChangeTabType = WardrobeUI.structTabAndItemTypeRelationship[itemData.itemSubType].tabType;
			BP_ChangeTabIcon = itemData.resID;

			WardrobeUI.AddToWearInfo(itemData.itemSubType, itemData.insID, itemData.resID);	-- 添加到穿戴信息
			LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTabIcon");	
		end
	end

	local parachuteData = DataMgr.GetHallDepotItemDataByInsID(DataMgr.parachute);
	if parachuteData ~= nil then
		WardrobeUI.AddToWearInfo(701, DataMgr.parachute, parachuteData.resID);
	end

    LuaClassObj.HandleUIMessage(bp_wardrobe, "UIShow");

	--log_tree("WardrobeUI:Show WardrobeUI.currentWearPreviewMap", WardrobeUI.currentWearPreviewMap);
		
    --LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_OpenMenu");
    LobbyUI:SwitchToTeamorMenuCamera(true)
	TeamUpUI.OnCameraSwitch();
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_OPEN);
end

function WardrobeUI.PutOffTimeOutWear()
	local putOff = {}
	WardrobeSystem.UpdateInvalidWearInfo(putOff);

	local itemData;
	for i,v in ipairs(putOff) do
		itemData = DataMgr.GetHallDepotItemDataByInsID(v);
		if itemData ~= nil then
			WardrobeUI.UpdateOneTableIcon(itemData.itemSubType);
			LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, itemData.resID), false);
		end
	end
end

function WardrobeUI.AddToWearInfo(itemSubType, itemInsID, itemResID)
	WardrobeUI.currentWearPreviewMap[itemSubType] = {insID = tostring(itemInsID), resID = itemResID}; -- 记录预览数据
end

-- 关闭仓库面板
function WardrobeUI:Hide()

	if WardrobeUI.isShowing then
	    --log("WardrobeUI Hide");
	    LuaClassObj.HandleUIMessage(bp_wardrobe, "UIHide");
	    --LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_CloseMenu");
	    LobbyUI:SwitchToMainCamera(true)
		TeamUpUI.OnCameraSwitch();
	end
end

-- 更新仓库上的金币显示
function WardrobeUI:UpdateGoldNumber()
	BP_WardrobeGold = DataMgr.gold;
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateGold");	
end

-- 更新仓库
function WardrobeUI:UpdatePutOnData(putOnItem, putDownItem)

	-- log_tree("WardrobeUI:UpdatePutOnData putOnItem", putOnItem);
	if putOnItem ~= nil then
		local itemCfg = Client.GetTableData("Item", putOnItem.res_id);
		if itemCfg ~= nil then
			local wearInfo = WardrobeUI.currentWearPreviewMap[itemCfg.ItemSubType];
			-- log_tree("WardrobeUI:UpdatePutOnData "..itemCfg.ItemSubType, wearInfo);
			if wearInfo ~= nil then
				putDownItem = WardrobeUI.CreatePutOnInfo(tostring(wearInfo.insID), wearInfo.resID);
			end
		end
	end
	-- log_tree("WardrobeUI:UpdatePutOnData putDownItem", putDownItem);

	if putDownItem then	
		local insID = tostring(putDownItem.instid);
		BP_STRUCT_WardrobeChangedItemData.ins_id = insID;
		BP_STRUCT_WardrobeChangedItemData.res_id = putDownItem.res_id;
		BP_STRUCT_WardrobeChangedItemData.count = putDownItem.count;
		BP_STRUCT_WardrobeChangedItemData.is_using = false;
		BP_STRUCT_WardrobeChangedItemData.is_selected = false;
		BP_STRUCT_WardrobeChangedItemData.is_new = false;

		local itemCfg = Client.GetTableData("Item", putDownItem.res_id);
		if itemCfg ~= nil then
			WardrobeUI.currentWearPreviewMap[itemCfg.ItemSubType] = nil;
		end
		
		-- log_tree("WardrobeUI:UpdatePutOnData BP_STRUCT_WardrobeChangedItemData1", BP_STRUCT_WardrobeChangedItemData);
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateOneItem");
	end
	
	if putOnItem then		
		local insID = tostring(putOnItem.instid);
		BP_STRUCT_WardrobeChangedItemData.ins_id = insID;
		BP_STRUCT_WardrobeChangedItemData.res_id = putOnItem.res_id;
		BP_STRUCT_WardrobeChangedItemData.count = putOnItem.count;
		BP_STRUCT_WardrobeChangedItemData.is_using = true;
		BP_STRUCT_WardrobeChangedItemData.is_selected = true;
		BP_STRUCT_WardrobeChangedItemData.is_new = false;
				
		-- log_tree("WardrobeUI:UpdatePutOnData putOnItem", BP_STRUCT_WardrobeChangedItemData);
		local itemCfg = Client.GetTableData("Item", putOnItem.res_id);

		if itemCfg then
			if itemCfg.WardrobeMainTab == 1 and putOnItem.instid ~= "" then
				BP_ChangeTabType = WardrobeUI.structTabAndItemTypeRelationship[itemCfg.ItemSubType].tabType;
				BP_ChangeTabIcon = putOnItem.res_id;
				LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTabIcon");
			end

			WardrobeUI.UpdateBG(itemCfg, insID ~= "");
		end

		if itemCfg ~= nil then
			WardrobeUI.AddToWearInfo(itemCfg.ItemSubType, putOnItem.instid, putOnItem.res_id);
		end
		
		-- log_tree("WardrobeUI:UpdatePutOnData BP_STRUCT_WardrobeChangedItemData2", BP_STRUCT_WardrobeChangedItemData);
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateOneItem");
	end
end

function WardrobeUI.DoUpdateOneItem(itemData, count, isUsing, isSelected, isNew)
	itemData.count = count;
	itemData.is_using = isUsing;
	itemData.is_selected = isSelected;
	itemData.is_new = isNew;

	local insData = DataMgr.GetHallDepotItemDataByInsID(itemData.ins_id);
	if insData ~= nil then
		insData.isNew = isNew;

		BP_STRUCT_WardrobeChangedItemData.ins_id = itemData.ins_id;
		BP_STRUCT_WardrobeChangedItemData.res_id = itemData.res_id;
		BP_STRUCT_WardrobeChangedItemData.count = count;
		BP_STRUCT_WardrobeChangedItemData.is_using = isUsing;
		BP_STRUCT_WardrobeChangedItemData.is_selected = isSelected;
		BP_STRUCT_WardrobeChangedItemData.is_new = isNew;

		-- log_tree("WardrobeUI.DoUpdateOneItem BP_STRUCT_WardrobeChangedItemData", BP_STRUCT_WardrobeChangedItemData);
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateOneItem");
	end
end

-- 更新仓库页穿脱表现
function WardrobeUI:UpdatePutDownData(putDownItem)
	if putDownItem then
		BP_STRUCT_WardrobeChangedItemData.ins_id = putDownItem.instid;
		BP_STRUCT_WardrobeChangedItemData.res_id = putDownItem.res_id;
		BP_STRUCT_WardrobeChangedItemData.count = putDownItem.count;
		BP_STRUCT_WardrobeChangedItemData.is_using = false;
		BP_STRUCT_WardrobeChangedItemData.is_selected = true;
		BP_STRUCT_WardrobeChangedItemData.is_new = false;
				
		local itemDataCfg = Client.GetTableData("Item", putDownItem.res_id);

		if itemDataCfg then
			WardrobeUI.currentWearPreviewMap[itemDataCfg.ItemSubType] = nil;
			WardrobeUI.UpdateOneTableIcon(itemDataCfg.ItemSubType);
			-- BP_ChangeTabType = WardrobeUI.structTabAndItemTypeRelationship[itemDataCfg.ItemSubType].tabType;
			-- BP_ChangeTabIcon = 0;
			-- LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTabIcon");
		end
		
		-- log_tree("WardrobeUI:UpdatePutDownData BP_STRUCT_WardrobeChangedItemData", BP_STRUCT_WardrobeChangedItemData);
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateOneItem");
	end		
end

function WardrobeUI.UpdateOneTableIcon(itemSubType)
	BP_ChangeTabType = WardrobeUI.structTabAndItemTypeRelationship[itemSubType].tabType;
	BP_ChangeTabIcon = 0;
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTabIcon");
end

-- 移除大页签下的小红点
function WardrobeUI.RemovePageRedPoint(lastPage, curPage)
	if lastPage == curPage then
		return;
	end

	local v = nil;
	for i=1,#WardrobeUI.redPointTabType do
		v = WardrobeUI.redPointTabType[i];
		if v and v.pageType == lastPage then
			table.remove(WardrobeUI.redPointTabType, i);
		end
	end
end

-- 移除当前不需要显示小红点的页签
function WardrobeUI:UpdatePanelRedPoint(isShow, pageType, tabType)	
	if pageType ~= -1 and tabType ~= -1 then
		log("WardrobeUI:UpdatePanelRedPoint "..tostring(isShow)..", "..pageType..", "..tabType);
		-- log_tree("WardrobeUI:UpdatePanelRedPoint WardrobeUI.redPointTabType", WardrobeUI.redPointTabType);

		-- 查找小红点所在下标
		local curIndex = -1;
		for i,v in ipairs(WardrobeUI.redPointTabType) do
			if v.pageType == pageType and v.tabType == tabType then
				curIndex = i;
				break;
			end
		end

		-- 根据添加或移除逻辑处理
		if isShow then
			if curIndex == -1 then
				WardrobeUI.ShowRedPoint(pageType, tabType);
			end

			local allTabIndex = -1;
			for i,v in ipairs(WardrobeUI.redPointTabType) do
				if v.pageType == pageType and v.tabType == 0 then
					allTabIndex = i;
					break;
				end
			end

			if allTabIndex == -1 then
				WardrobeUI.ShowRedPoint(pageType, 0);
			end
		else
			if curIndex ~= -1 then
				table.remove(WardrobeUI.redPointTabType, curIndex);
			end
		end
	end

	-- 标记各级页签掩码
	WardrobeUI.UpdatePageTabRedPointMask(BP_CurPageTabType);
	-- log_tree("WardrobeUI:UpdatePanelRedPoint redPoint", WardrobeUI.redPointTabType);
	log("WardrobeUI:UpdatePanelRedPoint BP_PageRedPointMask "..BP_PageRedPointMask);
	log("WardrobeUI:UpdatePanelRedPoint BP_TabRedPointMask "..BP_TabRedPointMask);

	-- 更新大厅红点
	LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_WARDROBE, (#WardrobeUI.redPointTabType > 0));
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateAllRedPoint");
end

function WardrobeUI.UpdatePageTabRedPointMask(curPage)
	log("WardrobeUI.UpdatePageTabRedPointMask curPage = "..curPage);
	local pageMask = {}
	local tabMask = {}
	for i,v in ipairs(WardrobeUI.redPointTabType) do
		FuncUtil.MarkBit(pageMask, v.pageType + 1);
		if v.pageType == curPage then
			FuncUtil.MarkBit(tabMask, v.tabType + 1);
		end
	end

	BP_PageRedPointMask = FuncUtil.GetBitMaskValue(pageMask);
	BP_TabRedPointMask = FuncUtil.GetBitMaskValue(tabMask);
end

function WardrobeUI.ShowRedPoint(pageType, tabType)
	log("WardrobeUI.ShowRedPoint pageType = "..pageType.." 		tabType = "..tabType);
	table.insert(WardrobeUI.redPointTabType, {pageType = pageType, tabType = tabType});
end

-- 更新物品售卖返回的物品刷新
function WardrobeUI:UpdateItemData(itemData)
	if itemData then
		local insID = tostring(itemData.instid);
		local isCurrentSelected = insID == BP_STRUCT_WardrobeClickedItemData.ins_id and itemData.res_id == BP_STRUCT_WardrobeClickedItemData.res_id;
		BP_STRUCT_WardrobeChangedItemData.ins_id = insID;
		BP_STRUCT_WardrobeChangedItemData.res_id = itemData.res_id;
		BP_STRUCT_WardrobeChangedItemData.is_new = (itemData.isnew == 1);
		BP_STRUCT_WardrobeChangedItemData.count = itemData.count;
		BP_STRUCT_WardrobeChangedItemData.is_selected = isCurrentSelected;
		BP_STRUCT_WardrobeChangedItemData.is_using = isCurrentSelected;
			
		if BP_CurPageTabType == 0 then
			if itemData.count == 0 then
				local itemDataCfg = Client.GetTableData("Item", itemData.res_id);
				if itemDataCfg then
					if itemDataCfg.WardrobeMainTab == 1 then
						BP_ChangeTabType = WardrobeUI.structTabAndItemTypeRelationship[itemDataCfg.ItemSubType].tabType;
						BP_ChangeTabIcon = 0;
						LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTabIcon");
					end
				end
			end
		end

		for i,v in ipairs(BP_ARRAY_WardrobeItemList) do
			if v.ins_id == tostring(itemData.instid) then
				v.count = itemData.count;
				break;
			end
		end
		
		-- log_tree("WardrobeUI:UpdateItemData BP_STRUCT_WardrobeClickedItemData", BP_STRUCT_WardrobeClickedItemData);
		-- log_tree("WardrobeUI:UpdateItemData BP_STRUCT_WardrobeChangedItemData", BP_STRUCT_WardrobeChangedItemData);
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateOneItem");
	end
end

-- 关闭仓库回调
function EventHideWardrodbe()
	if not WardrobeUI.isShowing then
		return;
	end
	
	-- EventWardrobeHideTabRedPoint();

	--LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_CloseMenu");
    LobbyUI:SwitchToMainCamera(true)
    LuaClassObj.HandleUIMessage(bp_lobby, "ResetBtnSprites");
	TeamUpUI.OnCameraSwitch();
	
	WardrobeUI.isShowing = false;
			
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_CLOSE);
    WardrobeUI.RevertAvatar();

	-- 关闭大厅仓库红点
	--LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_WARDROBE, false);
end

-- 卖物品
function EventWardrobeSell()
	log("EventWardrobeSell: "..BP_Sell_id);
    --WardrobeSystem.wardrobe_sell_req(BP_Sell_id, 1);
	
	local itemData;
	local itemCfg;
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		--log_tree("v", v);
		--log(type(v.insID)..", "..type(BP_Sell_id));
		if v.insID == BP_Sell_id then
			itemData = v;			
			itemCfg = Client.GetTableData("Item", v.resID);
			break;
		end		
	end
	--log_tree("itemData", itemData);
	
	if itemData then
		--local tip = string.format("是否以<img src=\"GoldImage\"/><MessageGoldColor>%s</>出售<MessageProductColor>%s</>?", itemCfg.SellPrice, itemCfg.ItemName);
		local tip = string.format(Client.GetTableData("LocalizeRes", "301306").TextValue, itemCfg.SellPrice, itemCfg.ItemName);
		tip = (string.gsub(tip, "\'", "\"")); 
		CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "301307").TextValue, tip, 
		function()
			WardrobeSystem.wardrobe_sell_req(BP_Sell_id, 1);
			return true;
		end
		);
	end
end

-- 使用物品
function EventWardrobeUseItem()
	log("EventWardrobeUseItem："..BP_Sell_id);
	-- log_tree("EventWardrobeUseItem", BP_STRUCT_WardrobeClickedItemData);
	
	local itemCfg;
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.insID == BP_Sell_id then		
			itemCfg = Client.GetTableData("Item", v.resID);
			break;
		end		
	end
	
	if itemCfg then
		--local tip = string.format("是否确定开启一个<MessageProductColor>%s</>?", itemCfg.ItemName);
		local tip = string.format(Client.GetTableData("LocalizeRes", "301308").TextValue, itemCfg.ItemName);
		local  title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		CommonMessageBoxUI:ShowPanel(2, title, tip, 
		function()
			WardrobeSystem.wardrobe_use_item_req(BP_Sell_id, 1);
			return true;
		end
		);
	end
	
end

-- 点击item
function EventWardrobeClickItem()
	BP_String_Wardrobe_RemainTime = "";
	-- log_tree("EventWardrobeClickItem BP_STRUCT_WardrobeClickedItemData", BP_STRUCT_WardrobeClickedItemData);
	if BP_STRUCT_WardrobeClickedItemData.is_sourcebook then
		WardrobeUI.ClickSourceBookItem();
	else
		local itemInstID = BP_STRUCT_WardrobeClickedItemData.ins_id;
		local itemInst = DataMgr.GetHallDepotItemDataByInsID(BP_STRUCT_WardrobeClickedItemData.ins_id);
		if BP_STRUCT_WardrobeClickedItemData.is_new then
			-- 取消物品new标签
			WardrobeSystem.wardrobe_change_item_new_status(itemInstID);
			DataMgr.ChangeHallDepotItemNewStatus(itemInstID);
		end

		if itemInst ~= nil then
			if itemInst.mainTabType == 1 or itemInst.mainTabType == 2 then
				WardrobeUI.ClickAvatarItem();
				WardrobeUI.UpdateRemainTimeString();
			elseif itemInst.mainTabType == 3 then
				WardrobeUI.ClickToolItem();
			end
		end
	end
end

-- 跳转
function EventWardrobeClickJump()
	log("EventWardrobeClickJump");
	if BP_WARDROBE_Jump_Item_resID == 0 then
		return;
	end

	local itemInfo = Client.GetTableData("Item", BP_WARDROBE_Jump_Item_resID);
	if itemInfo ~= nil then
	    BP_Global_Url = itemInfo.JumpUrl;
	    EventJumpUrl();
	end
end

function WardrobeUI.GetWearPreviewInfoByResID(resID)
	local itemCfg = Client.GetTableData("Item", BP_STRUCT_WardrobeClickedItemData.res_id);
	if itemCfg ~= nil then
		return WardrobeUI.currentWearPreviewMap[itemCfg.ItemSubType];
	end

	return nil;
end

function WardrobeUI.ClickAvatarItem()
	-- log_tree("WardrobeUI.ClickAvatarItem：", BP_STRUCT_WardrobeClickedItemData);
	local itemInstID = BP_STRUCT_WardrobeClickedItemData.ins_id;
	
	if BP_CurPageTabType == 0 or BP_CurPageTabType == 2 then
		-- 如果点击的和实际穿戴的是同一件，则比较UI预览的物件
		local isWear = false;
		for k,v in pairs(DataMgr.rolewear) do
			if BP_STRUCT_WardrobeClickedItemData.ins_id == v then
				isWear = true;
				break;
			end
		end

		-- 如果装备的是降落伞
		local isParachute = false;
		if BP_STRUCT_WardrobeClickedItemData.ins_id == DataMgr.parachute then
			isWear = true;
			isParachute = true;
		end

		local putonByClient = false;
		if isWear then
			local wearInfo = WardrobeUI.GetWearPreviewInfoByResID(BP_STRUCT_WardrobeClickedItemData.res_id);
			if wearInfo ~= nil then
				-- 如果已经存在预览信息，判断一下预览的信息和当前点击的是否同一件，是则做后面的处理，不是则直接换上
				if wearInfo.insID ~= BP_STRUCT_WardrobeClickedItemData.ins_id and wearInfo.resID ~= BP_STRUCT_WardrobeClickedItemData.res_id then
					putonByClient = true;
				end
			end
		end

		if putonByClient then
			local putonInfo = WardrobeUI.CreatePutOnInfo(BP_STRUCT_WardrobeClickedItemData.ins_id, BP_STRUCT_WardrobeClickedItemData.res_id);
			WardrobeUI.PutOnPreview(BP_STRUCT_WardrobeClickedItemData.ins_id, BP_STRUCT_WardrobeClickedItemData.res_id);
		elseif not putonByClient and isWear and isParachute then
			WardrobeUI.UpdateSelectItem();
		else

			if BP_STRUCT_WardrobeClickedItemData.is_using then
				local itemCfg = Client.GetTableData("Item", BP_STRUCT_WardrobeClickedItemData.res_id);
				if itemCfg.WardrobeMainTab == 1 then
					-- 请求脱时装
					log("EventWardrobeClickItem PutDown insID:"..itemInstID);
					WardrobeSystem.wardrobe_put_down_req(itemInstID);
				end
			else
				-- 请求穿时装
				log("EventWardrobeClickItem PutOn insID:"..itemInstID);
				WardrobeSystem.wardrobe_puton_req(itemInstID);
			end
		end
	end
end

function WardrobeUI.ClickSourceBookItem()
	-- log_tree("WardrobeUI.ClickSourceBookItem：", BP_STRUCT_WardrobeClickedItemData);
	if BP_STRUCT_WardrobeClickedItemData.is_using then
		log("WardrobeUI.ClickSourceBookItem puton default");
		local itemCfg = Client.GetTableData("Item", BP_STRUCT_WardrobeClickedItemData.res_id);
		if itemCfg == nil then
			return;
		end

		local itemData = WardrobeUI.GetRealWearInstance(itemCfg.WardrobeMainTab, itemCfg.ItemSubType);
		if itemData == nil then
			-- 这里没有拿到真实的穿戴，把原来的穿戴脱下
			log("WardrobeUI.ClickSourceBookItem putoff");
			local wearInfo = WardrobeUI.currentWearPreviewMap[itemCfg.ItemSubType];
			if wearInfo ~= nil then
				LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, wearInfo.resID), false);
				local oldInfo = WardrobeUI.CreatePutOnInfo(wearInfo.insID, wearInfo.resID);
				WardrobeUI:UpdatePutDownData(oldInfo);
			end
		else
			WardrobeUI.PutOnPreview(itemData.insID, itemData.resID);
		end
	else
		-- log_tree("WardrobeUI.ClickSourceBookItem puton", BP_STRUCT_WardrobeClickedItemData);
		if BP_STRUCT_WardrobeClickedItemData ~= nil then
			WardrobeUI.PutOnPreview(BP_STRUCT_WardrobeClickedItemData.ins_id, BP_STRUCT_WardrobeClickedItemData.res_id);
		end
	end
end

function WardrobeUI.UpdateSelectItem()
	-- log_tree("WardrobeUI.UpdateSelectItem BP_STRUCT_WardrobeClickedItemData", BP_STRUCT_WardrobeClickedItemData);
	local isChange;
	for i,v in ipairs(BP_ARRAY_WardrobeItemList) do
		isChange = false;
		if v.is_using or v.is_selected then
			v.is_using = false;
			v.is_selected = false;
			isChange = true;
		end

		if v.ins_id == BP_STRUCT_WardrobeClickedItemData.ins_id and v.res_id == BP_STRUCT_WardrobeClickedItemData.res_id then
			v.is_using = true;
			v.is_selected = true;
			isChange = true;
		end

		if isChange then
			-- log_tree("WardrobeUI.UpdateSelectItem updateItem", v);
			WardrobeUI.DoUpdateOneItem(v, v.count, v.is_using, v.is_selected, false);
		end
	end
end

function WardrobeUI.ClickToolItem()
	log("WardrobeUI.ClickToolItem");
	WardrobeUI.UpdateSelectItem();
	WardrobeUI.UpdateRemainTimeString();
end

function WardrobeUI.GetRealWearInstance(pageType, itemSubType)
	if pageType == 1 then
		local itemData = nil;
		for k,v in pairs(DataMgr.rolewear) do
			itemData = DataMgr.GetHallDepotItemDataByInsID(v);
			if itemData and itemData.mainTabType == pageType and itemData.itemSubType == itemSubType then
				return itemData;
			end
		end
		return nil;
	elseif pageType == 2 then
		return DataMgr.GetHallDepotItemDataByInsID(DataMgr.parachute);
	end
end

function WardrobeUI.PutOnPreview(insID, resID)
	log("itemCfgitemCfgitemCfg "..insID.." "..resID);
	local itemCfg = Client.GetTableData("Item", resID);
	if itemCfg ~= nil then
		-- 记录新的穿戴
		local newWearInfo = WardrobeUI.CreatePutOnInfo(insID, resID);
		WardrobeUI:UpdatePutOnData(newWearInfo, nil);

		-- 更换穿戴
		if itemCfg.WardrobeMainTab == 1 then
			LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, resID), true);
		end

		WardrobeUI.UpdateBG(itemCfg, insID ~= "");
	end
end

function WardrobeUI.UpdateBG(itemCfg, showPutOn)
	if itemCfg and itemCfg.Preview ~= "" then
		BP_Wardrobe_BG_resID = itemCfg.ItemID;
	else
		BP_Wardrobe_BG_resID = 0;
	end
	BP_Wardrobe_BG_showPutOn = showPutOn;
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateBG");
end

function WardrobeUI.CreatePutOnInfo(insID, resID)
	local result = nil;
	-- log("WardrobeUI.CreatePutOnInfo :"..insID.." "..resID);
	if insID ~= "" then
		local itemIns = DataMgr.GetHallDepotItemDataByInsID(insID);
		-- log_tree("WardrobeUI.CreatePutOnInfo "..insID, DataMgr.arrayHallDepotItemInfo);
		if itemIns ~= nil then
			result = {instid = insID, res_id = itemIns.resID, count = itemIns.count};
		end
	else
		result = {instid = "", res_id = resID, count = 0};
	end
	return result;
end

-- 切换小页签
function EventChangeWardrodbeTab()
	BP_Wardrobe_BG_resID = 0;
    log("EventChangeWardrodbeTab page:"..BP_CurPageTabType..", tab:"..BP_CurTabType);
	BP_ARRAY_Wardrobe_SourceBookItemList = {}
	if BP_CurPageTabType == 0 then
		-- 切换到时装
		WardrobeUI:UpdateAvatarList();
	elseif BP_CurPageTabType == 1 then
		-- 切换到道具
		WardrobeUI:UpdateItemList();
	elseif BP_CurPageTabType == 2 then
				-- 切换到降落伞
		WardrobeUI.UpdateParachuteList();
	end
	
    log("EventChangeWardrodbeTab lastPage:"..BP_LastPageType..", lastTab:"..BP_LastTabType);
    -- WardrobeUI.RemovePageRedPoint(BP_LastPageType, BP_CurPageTabType);
	WardrobeUI:UpdatePanelRedPoint(false, BP_LastPageType, BP_LastTabType);
end

-- 切换大页签
-- function EventChangePageWardrodbeTab()
--     log("EventChangePageWardrodbeTab BP_ChangePageTabType = "..BP_ChangePageTabType);
-- 	BP_ChangeTabType = 0;
-- 	BP_ChangeTabIcon = 0;

-- 	BP_CurTabType = 0;
-- 	BP_CurPageTabType = BP_ChangePageTabType;
-- 	BP_ARRAY_Wardrobe_SourceBookItemList = {}
-- 	BP_Wardrobe_BG_resID = 0;

-- 	if BP_CurPageTabType == 0 then
-- 		-- 切换到时装
-- 		WardrobeUI:UpdateAvatarList();
-- 	elseif BP_CurPageTabType == 1 then
-- 		-- 切换到道具
-- 		WardrobeUI:UpdateItemList();
-- 	elseif BP_CurPageTabType == 2 then
-- 		-- 切换到降落伞
-- 		WardrobeUI.UpdateParachuteList();
-- 	end

-- 	-- 更新小页签红点
-- 	--log_tree("EventChangePageWardrodbeTab redPointTabType", WardrobeUI.redPointTabType);
-- 	local isFind = false;
-- 	for k,v in pairs(WardrobeUI.structTabAndItemTypeRelationship) do
-- 		BP_LastTabType = v.tabType;
-- 		LuaClassObj.HandleUIMessage(bp_wardrobe, "HideTabRedPoint");
-- 		-- log("HideTabRedPoint "..v.tabType);
-- 		isFind = false;
-- 		for kk,vv in pairs(WardrobeUI.redPointTabType) do
-- 			if BP_CurPageTabType == vv.pageType and v.tabType == vv.tabType then
-- 				BP_LastTabType = v.tabType;
-- 				LuaClassObj.HandleUIMessage(bp_wardrobe, "ShowTabRedPoint");
-- 				-- log("ShowTabRedPoint "..v.tabType);
-- 				break;
-- 			end
-- 		end
-- 	end
-- end

-- 更新道具页签
function WardrobeUI:UpdateItemList()
	-- log("WardrobeUI:UpdateItemList");

	-- local itemSubType = 1502;
	
	local serverTime = FuncUtil.GetServerTimeInSec();
	BP_ARRAY_WardrobeItemList = {};
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.mainTabType == 3 and (v.expireTS == 0 or v.expireTS > serverTime) then
			--log_tree("v:", v);				
						
			table.insert(BP_ARRAY_WardrobeItemList,
			{
				ins_id = v.insID,
				res_id = v.resID,
				count = v.count,
				is_using = false,
				is_new = v.isNew,
				is_selected = false,
				is_sourcebook = false,
				validHours = v.validHours,
				expireTS = v.expireTS,
				index = #BP_ARRAY_WardrobeItemList,
			});
		end
	end

	table.sort(BP_ARRAY_WardrobeItemList,
	function(a, b)
		local aHasTime = a.expireTS ~= 0;
		local bHasTime = b.expireTS ~= 0;

		if a.is_new ~= b.is_new then
			return a.is_new;
		elseif aHasTime ~= bHasTime then
			return bHasTime;
		else
			return false;
		end
	end);

	--log_tree("UpdateItemList", BP_ARRAY_WardrobeItemList);
	LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateView");
end

-- 刷新当前时装页签
function WardrobeUI:UpdateAvatarList()
    log("WardrobeUI:UpdateAvatarList BP_CurTabType"..BP_CurTabType);
	local itemSubType = 0;
	for k,v in pairs(WardrobeUI.structTabAndItemTypeRelationship) do
		if v.tabType == BP_CurTabType then
			itemSubType = v.itemType;
			break;
		end
	end
    --log("BP_CurTabType:"..BP_CurTabType..", itemSubType:"..itemSubType);
    --log_tree("DataMgr.arrayHallDepotItemInfo:"DataMgr.arrayHallDepotItemInfo);

    WardrobeUI.UpdateElementList(itemSubType);
end

-- 刷新当前降落伞页签
function WardrobeUI.UpdateParachuteList()
    log("WardrobeUI:UpdateParachuteList");

    WardrobeUI.UpdateElementList(0);
end

function WardrobeUI.UpdateElementList(itemSubType)
	local wardrobeMainTab = WardrobeUI.structPageToMainTabType[BP_CurPageTabType];
	local isWear = false;
	local itemInfo = nil;
	local wearInfo = nil;
	BP_ARRAY_WardrobeItemList = {};
	local itemResIDMap = {}	-- 当前页签map
	-- log_tree("WardrobeUI:UpdateAvatarList currentWearPreviewMap", WardrobeUI.currentWearPreviewMap)
	local serverTime = FuncUtil.GetServerTimeInSec();
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.mainTabType == wardrobeMainTab and (itemSubType == 0 or v.itemSubType == itemSubType) and (v.expireTS == 0 or v.expireTS > serverTime) then
			--log_tree("v:", v);

			isWear = false;
			wearInfo = WardrobeUI.currentWearPreviewMap[v.itemSubType];
			if wearInfo ~= nil then
				isWear = wearInfo.insID == v.insID and wearInfo.resID == v.resID;
			end

			if isWear and v.mainTabType == 2 then
				-- BP_Wardrobe_BG_resID = v.resID;
				local itemCfg = Client.GetTableData("Item", v.resID);
				WardrobeUI.UpdateBG(itemCfg, v.insID ~= "")
			end

			-- log(string.format("WardrobeUI:UpdateAvatarList insID=%s resId=%s isWear=%s", tostring(v.insID), tostring(v.resID), tostring(isWear)))

			itemInfo =
			{
				ins_id = v.insID,
				res_id = v.resID,
				count = v.count,
				is_using = isWear,
				is_new = v.isNew,
				is_selected = false,
				is_sourcebook = false,
				validHours = v.validHours,
				expireTS = v.expireTS,
				index = #BP_ARRAY_WardrobeItemList,
				itemSubType = v.itemSubType,
				itemQuality = v.itemQuality,
			};
			table.insert(BP_ARRAY_WardrobeItemList, itemInfo);

			itemResIDMap[v.resID] = itemInfo;
		end
	end

	--log_tree("BP_ARRAY_WardrobeItemList", BP_ARRAY_WardrobeItemList);
	table.sort(BP_ARRAY_WardrobeItemList,
		function(a, b)
			local aHasTime = a.expireTS ~= 0;
			local bHasTime = b.expireTS ~= 0;

			if a.res_id == DataMgr.defaultParachuteResID or b.res_id == DataMgr.defaultParachuteResID then
				return a.res_id == DataMgr.defaultParachuteResID;
			elseif a.is_new ~= b.is_new then
				return a.is_new;
			elseif aHasTime ~= bHasTime then
				return bHasTime;
			elseif a.itemSubType ~= b.itemSubType then
				return a.itemSubType < b.itemSubType;
			elseif a.itemQuality ~= b.itemQuality then
				return a.itemQuality > b.itemQuality;
			elseif a.res_id ~= b.res_id then
				return a.res_id < b.res_id;
			elseif a.expireTS ~= b.expireTS then
				return a.expireTS < b.expireTS;
			else
				return false;
			end
		end);
	
	WardrobeUI.UpdateSourceBook(wardrobeMainTab, itemSubType, itemResIDMap);
    LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateView");
end

function WardrobeUI.UpdateSourceBook(wardrobeMainTab, itemSubType, itemResIDMap)

	local curTypeSourceBook = DataMgr.mapSourceBookInfo[wardrobeMainTab];
	if curTypeSourceBook == nil then
		return;
	end

	local subTabArray = WardrobeUI.mainTabToSubTabArray[wardrobeMainTab];
	if subTabArray == nil then
		return;
	end

	-- 填充图鉴列表
	local sourceBookItemArray = nil;
	for i,v in ipairs(subTabArray) do
		-- log_tree("sourceBookItemArray "..itemSubType, sourceBookItemArray);
		if itemSubType == 0 or v == itemSubType then
			sourceBookItemArray = curTypeSourceBook[v];
			if sourceBookItemArray ~= nil then
				for i,v in ipairs(sourceBookItemArray) do
					-- 如果不在仓库中，放到图鉴中
					local itemInfo = itemResIDMap[v.resID];
					if not itemInfo then
						WardrobeUI.AddToSourceBook(v);
					end
				end
			end
		end
	end
	-- log_tree("BP_ARRAY_Wardrobe_SourceBookItemList", BP_ARRAY_Wardrobe_SourceBookItemList);
end

function WardrobeUI.AddToSourceBook(tableInfo)
	local wearInfo = WardrobeUI.currentWearPreviewMap[tableInfo.itemSubType];

	local info =
	{
		ins_id = "",
		res_id = tableInfo.resID,
		count = 0,
		is_new = false,
		is_selected = false,
		is_sourcebook = true,
	};
	info.is_using = wearInfo ~= nil and wearInfo.insID == "" and wearInfo.resID == tableInfo.resID;

	table.insert(BP_ARRAY_Wardrobe_SourceBookItemList, info);
end

function WardrobeUI.HasWearSubType(itemSubType)
	for k,v in pairs(DataMgr.rolewear) do
		local itemInfo = DataMgr.GetHallDepotItemDataByInsID(v);
		if itemInfo ~= nil and itemInfo.itemSubType == itemSubType then
			return true;
		end
	end

	return false;
end

function WardrobeUI.RevertAvatar()
	-- log_tree("WardrobeUI.RevertAvatar rolewear", DataMgr.rolewear);
	WardrobeSystem.UpdateInvalidWearInfo()

	-- 还原真实穿戴
	for k,v in pairs(DataMgr.rolewear) do
		local itemInfo = DataMgr.GetHallDepotItemDataByInsID(v);
		if itemInfo ~= nil then
			local wearInfo = WardrobeUI.currentWearPreviewMap[itemInfo.itemSubType];
			if wearInfo ~= nil and wearInfo.insID ~= itemInfo.insID then
				-- log_tree("WardrobeUI.RevertAvatar wearInfo", wearInfo);
				LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, itemInfo.resID), true);
			end
		end
	end

	-- 脱下实际未穿戴
	for k,v in pairs(WardrobeUI.currentWearPreviewMap) do
		if not WardrobeUI.HasWearSubType(k) then
			-- log("WardrobeUI.RevertAvatar putdown "..v.resID);
			LobbyUI:AvatarChange(LobbyUI:CreateAvatarChangeData(DataMgr.roleData.uid, v.resID), false);
		end
	end

	-- log_tree("WardrobeUI.RevertAvatar currentWearPreviewMap", WardrobeUI.currentWearPreviewMap);
    WardrobeUI.currentWearPreviewMap = {}
end

function WardrobeUI.UpdateRemainTimeString()
	BP_IsShowUseButton = true;
	log("WardrobeUI.UpdateRemainTimeString");
	if BP_STRUCT_WardrobeClickedItemData == nil then
		return;
	end

	local itemData = DataMgr.GetHallDepotItemDataByInsID(BP_STRUCT_WardrobeClickedItemData.ins_id);
	-- log_tree("WardrobeUI.UpdateRemainTimeString itemData", itemData);
	if itemData == nil or itemData.expireTS == 0 then
		return;
	end

	local remainTime = itemData.expireTS - FuncUtil.GetServerTimeInSec();
	-- log("WardrobeUI.UpdateRemainTimeString remainTime="..remainTime);
	if remainTime <= 0 then
		BP_IsShowUseButton = false;
		BP_String_Wardrobe_RemainTime = FuncUtil.GetLocalizeResStr(9910111);
	else
		-- 计算天数和小时数
		local hour = math.ceil(remainTime * WardrobeUI.secToHour);
		local day = math.floor(hour * WardrobeUI.hourToDay);
		local hourMod = hour%24;
		local dayStr = "";
		local hourStr = "";

		if day ~= 0 then
			dayStr = FuncUtil.LocalizeResFormat(9910108, tostring(day));
		end

		if hourMod ~= 0 then
			hourStr = FuncUtil.LocalizeResFormat(9910107, tostring(hourMod));
		end

		if dayStr ~= "" or hourStr ~= "" then
			BP_String_Wardrobe_RemainTime = FuncUtil.LocalizeResFormat(9910106, dayStr..hourStr);
		end
	end
end

function WardrobeUI.UpdateTime()
	if WardrobeUI.isShowing then
		BP_String_Wardrobe_RemainTime = "";
		WardrobeUI.UpdateRemainTimeString()
		LuaClassObj.HandleUIMessage(bp_wardrobe, "UpdateTime");
	end
end
