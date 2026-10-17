ShareAwardUI = ShareAwardUI or {
	isShowing = false,
	isSelPanelShowing = false,
}

BP_IsTodayShareDone = false
BP_CurShareNum = 0
BP_GetAwardIndex = 0

BP_GetAwardID = 0
BP_AwardItem1 = 0
BP_AwardNum1 = 0
BP_AwardName1 = ""
BP_AwardItem2 = 0
BP_AwardNum2 = 0
BP_AwardName2 = ""

BP_SelAwardIndex = 0

BP_STRUCT_ShareAwardInfo = {
	need_share_num = 0,
	award_state = 0,
	award_type = 1,
	award_item1 = 0,
	award_num1 = 0,
	award_name1 = "",
	award_item2 = 0,
	award_num2 = 0,
	award_name2 = "",
}

BP_ARRAY_ShareAwardInfoList = {
	BP_STRUCT_ShareAwardInfo = _G.BP_STRUCT_ShareAwardInfo,
}

--注册Widget
function bp_share_award_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_award,
		{{Path="/Game/UMG/UI_Logic/ShareAward/ShareAward_BP.ShareAward_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SHAREAWARD_ZORDER},
		 {Path="/Game/UMG/UI_Logic/ShareAward/ShareAward_SelAward_BP.ShareAward_SelAward_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SHAREAWARD_ZORDER + 70}},
		{"Lobby"},
		false,
		bp_share_award_OnModeSwitched ~= nil,
		true
	);
end

function bp_share_award_OnModeSwitched(gamestatus)
	log("bp_share_award_OnModeSwitched" .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
		ShareAwardMgr.Init();
		ShareAwardMgr.CheckDelayAward();
		--ShareAwardMgr.CheckGetAward();
	elseif string.lower(gamestatus) == "Fighting" then
		ShareAwardUI.Hide();
	elseif string.lower(gamestatus) == "login" then
		ShareAwardUI.Release();
		ShareAwardMgr.Release();
		ShareAwardUI.isSelPanelShowing = false;
	end
end

local function ShareAwardEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_SHARE_AWARD then
		return;
	end
	
	--领奖后更新界面信息
	if eventID == EVENTID_SHARE_AWARD_SYNCINFO then
		log("EVENTID_SHARE_AWARD_SYNCINFO");
		ShareAwardUI.UpdateUI();
	end
end

function ShareAwardUI.Show()
	LuaClassObj.HandleDynamicCreation(bp_share_award);
	log("ShareAwardUI Show");
	if ShareAwardUI.isShowing then
		return;
	end
	
	ShareAwardUI.isShowing = true;
	
	ShareMgr.GetShareInfoReq();
	
	BP_IsTodayShareDone = ShareAwardMgr.IsTodayShareDone();
	BP_CurShareNum = ShareAwardMgr.GetShareTimes();
	
	BP_ARRAY_ShareAwardInfoList = {}
			
	local awardConfigTab = Client.GetTable("ShareAwardConfig");
	local awardConfigList = {}
	for k, v in pairs(awardConfigTab) do
		local info = {}
		info.need_share_num = v.Day;
		info.award_state = ShareAwardMgr.GetShareAwardState(v.Day);
		info.award_type = v.AwardType;
		info.award_item1, info.award_num1, info.award_name1 = ShareAwardMgr.GetAwardItemByDropId(v.MaleAwardID);
		info.award_item2, info.award_num2, info.award_name2 = ShareAwardMgr.GetAwardItemByDropId(v.FemaleAwardID);
		table.insert(BP_ARRAY_ShareAwardInfoList, info);
	end
	table.sort(BP_ARRAY_ShareAwardInfoList, function(a, b)
		return a.need_share_num < b.need_share_num;
	end)
	log_tree("ShareAwardUI.Show BP_ARRAY_ShareAwardInfoList=", BP_ARRAY_ShareAwardInfoList);
	
	EventSystem:registEvent(EVENTTYPE_SHARE_AWARD, EVENTID_SHARE_AWARD_SYNCINFO, ShareAwardEventHandler);
		
	LuaClassObj.HandleUIMessage(bp_share_award, "UIShow");
end

function ShareAwardUI.Release()
	ShareAwardUI.isShowing= false
	
	EventSystem:unregistEvent(EVENTTYPE_SHARE_AWARD, EVENTID_SHARE_AWARD_SYNCINFO, ShareAwardEventHandler);
end

function ShareAwardUI.Hide()
	log("ShareAwardUI Hide");
	LuaClassObj.HandleUIMessage(bp_share_award, "UIHide");
end

function ShareAwardUI.OpenSelAwardPanel(id, item1, num1, name1, item2, num2, name2)
	LuaClassObj.HandleDynamicCreation(bp_share_award);
	if ShareAwardUI.isSelPanelShowing then
		return;
	end
	
	ShareAwardUI.isSelPanelShowing = true;
	
	BP_GetAwardID = id;
	BP_AwardItem1 = item1;
	BP_AwardNum1 = num1;
	BP_AwardName1 = name1;
	BP_AwardItem2 = item2;
	BP_AwardNum2 = num2;
	BP_AwardName2 = name2;
		
	LuaClassObj.HandleUIMessage(bp_share_award, "OpenSelAwardPanel");
end

function ShareAwardUI.UpdateUI()
	if not ShareAwardUI.isShowing then
		return;
	end
	
	BP_IsTodayShareDone = ShareAwardMgr.IsTodayShareDone();
	BP_CurShareNum = ShareAwardMgr.GetShareTimes();
		
	for i=1, #BP_ARRAY_ShareAwardInfoList do
		local need_num = BP_ARRAY_ShareAwardInfoList[i].need_share_num;
		BP_ARRAY_ShareAwardInfoList[i].award_state = ShareAwardMgr.GetShareAwardState(need_num);
	end
	
	LuaClassObj.HandleUIMessage(bp_share_award, "UpdateUI");
end

function EventShareAwardSelAward_Push()
	log("EventShareAwardSelReward_Push")
	if BP_SelAwardIndex <= 0 then
		CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "660001").TextValue);
		return
	end
	
	ShareAwardMgr.ReqShareGetAward(BP_GetAwardID, BP_SelAwardIndex);
	
	LuaClassObj.HandleUIMessage(bp_share_award, "CloseSelAwardPanel");
end

function EventShareAwardShare_Push()
	log("EventShareAwardShare")
	--ShareAwardUI.Hide();
	ShareDayFinalyShareUI.ShowUI(); 
end

function EventShareAwardUIHide_Push()
	 ShareAwardUI.Release()
end

function EventShareAwardSelPanelHide_Push()
	BP_GetAwardID = 0;
	BP_AwardItem1 = 0;
	BP_AwardItem2 = 0;
	ShareAwardUI.isSelPanelShowing = false;
end

function EventShareAwardGetOnAward_Push()
	local info = BP_ARRAY_ShareAwardInfoList[BP_GetAwardIndex];
	if nil == info then
		return;
	end
	
	if info.award_type == 1 then
		ShareAwardMgr.ReqShareGetAward(info.need_share_num, 0);
	else
		ShareAwardUI.OpenSelAwardPanel(info.need_share_num, info.award_item1, info.award_num1, info.award_name1, info.award_item2, info.award_num2, info.award_name2);
	end
end