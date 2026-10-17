--活动UI
ActivtyUI = ActivtyUI or
{

}

BP_STRUCT_SubActivtyItemInfo =
{
	itemId = 0, 
	count = 0,
	have_count = 0,
}

BP_ARRAY_SubActivtyDropList = 
{
	BP_STRUCT_SubActivtyItemInfo = _G.BP_STRUCT_SubActivtyItemInfo,
}

BP_ARRAY_SubActivtyCostList = 
{
	BP_STRUCT_SubActivtyItemInfo = _G.BP_STRUCT_SubActivtyItemInfo,
}

BP_STRUCT_SubActivtyInfo = 
{
	Key = "",
	ID = 0,
	Index = 0,
	Type = 0,
	Title = "",
	Status = 0,
	Total = 0,
	Progress = 0,
	IsCheckNotice = 0,
	BP_ARRAY_SubActivtyDropList = _G.BP_ARRAY_SubActivtyDropList,
	BP_ARRAY_SubActivtyCostList = _G.BP_ARRAY_SubActivtyCostList,
}

BP_ARRAY_SubActivtyList = 
{
	BP_STRUCT_SubActivtyInfo = _G.BP_STRUCT_SubActivtyInfo,
}

BP_STRUCT_ActivtyInfo = 
{
	ID = 0,
	Title = "",
	Desc = "",
	Detail = "",
	ImgUrl = "",
	ImgLink = "",
	StartTimeStr = "",
	EndTimeStr = "",
	LabelType = 0,
	LabelDesc = "",
	BP_ARRAY_SubActivtyList = _G.BP_ARRAY_SubActivtyList,
}

BP_STRUCT_ActivtyInfo = _G.BP_STRUCT_ActivtyInfo
------------------------------------公告系统-----------------------------------
BP_STRUCT_NoticeInfo = 
{
	ID = 0,
	button_desc="",
	mark_type=0,
	mark_desc="",
	jump_button1 = "",
	jump_button2 = "",
	jump_mode1="",
	jump_mode2="",
	pic_url="",
	title="",
	content ="",
}

BP_STRUCT_NoticeInfo = _G.BP_STRUCT_NoticeInfo

BP_CurrentNoticeJumpMode = ""
BP_CurrentActJumpID = 0
BP_Duihuan_RedPoint_Num = 0
BP_First_Act_ID = 0
BP_First_Notice_ID = 0

------------------------------------------------------------------------------
--点击活动或者公告按钮函数
BP_STRUCT_ActivtyNoticeBtn_Select ={
	NowSelectNoticeID = 0,
	NowSelectActID = 0,
	NowIsSelectNotice = false,
};

BP_STRUCT_ActivtyNoticeBtn_Select = _G.BP_STRUCT_ActivtyNoticeBtn_Select
------------------------------------------------------------------------------

--点击子函数按钮函数
BP_STRUCT_ActivtyInfo_Click ={
	SubActID = 0,
	SubActIndex = 0,
	SubActType = 0,
	Arg = 0,
};

BP_STRUCT_ActivtyInfo_Click = _G.BP_STRUCT_ActivtyInfo_Click
---------------------活动按钮结构--------------------------------------
BP_STRUCT_ActButtonInfo = 
{
	ActID = 0,
	IsRedPoint = false,
	Btn_Name = "",
	Btn_Type = 0,
	Btn_TypeName = "",
}
BP_ARRAY_ActButtonInfo =
{
	BP_STRUCT_ActButtonInfo = _G.BP_STRUCT_ActButtonInfo
}

---------------------公告按钮结构--------------------------------------
BP_STRUCT_NoticeButtonInfo = 
{
	NoticeID = 0,
	IsRedPoint = false,
	Btn_Name = "",
	Btn_Type = 0,
	Btn_TypeName = "",
}
BP_ARRAY_NoticeButtonInfo =
{
	BP_STRUCT_NoticeButtonInfo = _G.BP_STRUCT_NoticeButtonInfo
}
-----------------------------------------------------基础函数部分--------------------------------------------------------------------------------
--注册Widget
function bp_activty_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_activty,
		{{Path="/Game/UMG/UI_Logic/Activty/Activty_BP.Activty_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ACTIVITY_ZORDER}},
		{"Login","Lobby"},
		false,
		bp_activty_OnModeSwitched ~= nil,
		true
	);

	 ----log("lua --- bp_activty_RegisterUI")
	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, ActivtyUI.RefreshUI) 
	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_BULLETIN_CHANGE, ActivtyUI.RefreshUI) 
	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_ACTIVITY, ActivtyUI.JumpIn);
end

function ActivtyUI.JumpIn(eventType, eventID, vars)
	LuaClassObj.HandleDynamicCreation(bp_activty);
	--log("活动界面收到跳转信息")
	LuaClassObj.HandleUIMessage(bp_activty, "TryToShowActivty");
	if vars and vars.id then
		BP_CurrentActJumpID = vars.id
		--log("BP_CurrentActJumpID ="..BP_CurrentActJumpID)
		LuaClassObj.HandleUIMessage(bp_activty, "JumpToActID");
	else
		----log("没有跳转的活动号码")
	end
end

function bp_activty_OnModeSwitched(gamestatus)
	if string.lower(gamestatus) == "lobby" then
		if ActivtyUI.timer == nil then
			ActivtyUI.timer = Timer.InsertTimer(60, ActivtyUI.HandlerTimer, true)
		end
	else
		if ActivtyUI.timer ~= nil then
			Timer.RemoveTimer(ActivtyUI.timer)
		end
	end
end

function ActivtyUI.RefreshUI()
	ActivtyUI.LoadData()
end

function ActivtyUI.HandlerTimer()
	----log("=ActivtyUI.HandlerTimer==================")
	ActivitySystem.Req_ActivityCheckList()
	ActivitySystem.Req_BulletinHashList()
end

-------------------------------------------------------------------------------------------------------------------------------------

function ActivtyUI.GetItemNum(itemID)
	if itemID == 1000 then
		return DataMgr.gold
	elseif itemID == 1003 then
		return DataMgr.roleData.roleExp
	else
		local itemData = DataMgr.GetHallDepotItemDataByResID(itemID)
		if itemData == nil then
			return 0
		else
			return itemData.count
		end
	end

	return 0
end

function ActivtyUI.LoadData()

	local is_lobby_show_red = false

	local need_push_to_bp = false
	BP_STRUCT_ActivtyInfo = {}
	BP_STRUCT_NoticeInfo = {}
	BP_ARRAY_ActButtonInfo = {}
	BP_ARRAY_NoticeButtonInfo = {}

	BP_Duihuan_RedPoint_Num = 0
	BP_First_Act_ID = -1
	BP_First_Notice_ID = -1

	for _, activity in ipairs(DataMgr.activity.data) do
		-- 排除吃鸡盛典和新兵八天活动 只显示通用活动
		if activity and activity.Type ~= nil and 
			(activity.Type == 2 or activity.Type == 3 or activity.Type == 4 or activity.Type == 5
				 or activity.Type == 6 or activity.Type == 7 or activity.Type == 8 or activity.Type == 10 or activity.Type == 13)
			
			then
			activity.BP_ARRAY_SubActivtyList = {}



			local btn_info = {}
			btn_info.IsRedPoint = ActivitySystem.HasActivityRedDotByID(activity.ID)

			--可以领取的排在最上面
			for k,v in ipairs(activity.List) do
				if v and v.Status == 1 and v.BP_ARRAY_SubActivtyDropList and v.BP_ARRAY_SubActivtyDropList[1] and v.BP_ARRAY_SubActivtyDropList[1].itemId ~= 0 then
					activity.BP_ARRAY_SubActivtyList[#activity.BP_ARRAY_SubActivtyList + 1] = v
					if btn_info.IsRedPoint and v.BP_ARRAY_SubActivtyCostList and #v.BP_ARRAY_SubActivtyCostList > 0 and v.IsCheckNotice == 1 then
						BP_Duihuan_RedPoint_Num = BP_Duihuan_RedPoint_Num + 1
					end
				end
			end
			for k,v in ipairs(activity.List) do
				if v and v.Status == 0 and v.BP_ARRAY_SubActivtyDropList and v.BP_ARRAY_SubActivtyDropList[1] and v.BP_ARRAY_SubActivtyDropList[1].itemId ~= 0 then
					activity.BP_ARRAY_SubActivtyList[#activity.BP_ARRAY_SubActivtyList + 1] = v
				end
			end
			for k,v in ipairs(activity.List) do
				if v and v.Status == 2 and v.BP_ARRAY_SubActivtyDropList and v.BP_ARRAY_SubActivtyDropList[1] and v.BP_ARRAY_SubActivtyDropList[1].itemId ~= 0 then
					activity.BP_ARRAY_SubActivtyList[#activity.BP_ARRAY_SubActivtyList + 1] = v
				end
			end
			for _, subActivity in pairs(activity.List) do
				subActivity.BP_ARRAY_SubActivtyCostList = subActivity.CostList
				subActivity.BP_ARRAY_SubActivtyDropList = subActivity.Drop
				--cost list 赋值
				for k,v in pairs(subActivity.BP_ARRAY_SubActivtyCostList) do
					if v then
						v.have_count = ActivtyUI.GetItemNum(v.itemId)
					end
				end
			end

			
			btn_info.ActID = activity.ID
			
			btn_info.Btn_Name = activity.Title
			btn_info.Btn_Type = activity.LabelType
			btn_info.Btn_TypeName = activity.LabelDesc

			if btn_info.IsRedPoint then
				is_lobby_show_red = true
			end

			BP_ARRAY_ActButtonInfo[#BP_ARRAY_ActButtonInfo + 1] = btn_info
			--log("添加活动按钮 id= "..btn_info.ActID)

			if BP_First_Act_ID > 0 then
				if not BP_STRUCT_ActivtyNoticeBtn_Select.NowIsSelectNotice and activity.ID == BP_STRUCT_ActivtyNoticeBtn_Select.NowSelectActID then
					need_push_to_bp = true
					BP_STRUCT_ActivtyInfo = activity
				end
			end

			if BP_First_Act_ID < 0 then
				BP_First_Act_ID = activity.ID
				need_push_to_bp = true
				BP_STRUCT_ActivtyInfo = activity
			end
		end
	end

	log("BP_Duihuan_RedPoint_Num =================="..BP_Duihuan_RedPoint_Num)

	--log_tree("BP_ARRAY_ActButtonInfo", BP_ARRAY_ActButtonInfo)

	--公告数据
	local notice_id = 1
	for k,v in pairs(DataMgr.bulletin.data) do
		if v then
			v.ID = notice_id

			local btn_info = {}
			btn_info.NoticeID = v.ID
			btn_info.IsRedPoint = false
			btn_info.Btn_Name = v.button_desc
			btn_info.Btn_Type = v.mark_type
			btn_info.Btn_TypeName = v.mark_desc

			if btn_info.IsRedPoint then
				is_lobby_show_red = true
			end

			BP_ARRAY_NoticeButtonInfo[#BP_ARRAY_NoticeButtonInfo + 1] = btn_info
			--log("添加公告按钮 id= "..btn_info.NoticeID)

			if BP_First_Notice_ID > 0 then
				if BP_STRUCT_ActivtyNoticeBtn_Select.NowIsSelectNotice and v.ID == BP_STRUCT_ActivtyNoticeBtn_Select.NowSelectNoticeID then
					need_push_to_bp = true
					BP_STRUCT_NoticeInfo = v
				end
			end

			if BP_First_Notice_ID < 0 then
				BP_First_Notice_ID = v.ID
				need_push_to_bp = true
				BP_STRUCT_NoticeInfo = v
			end

			notice_id = notice_id + 1
		end
	end

	--log("BP_First_Act_ID ="..BP_First_Act_ID)
	--log("BP_First_Notice_ID ="..BP_First_Notice_ID)

	--更新大厅界面小红点
	UpdateLobbyActivityRedPoint(is_lobby_show_red)

	if need_push_to_bp then
		--log("LuaClassObj.HandleUIMessage(bp_activty, LoadLuaData);")
		LuaClassObj.HandleUIMessage(bp_activty, "LoadLuaData");
	end

end

--------------------------------------------------------按钮响应部分------------------------------------------------------------------------------
--点击领取按钮
function EventActivtyUIOnClickGetBtn()
	--log("点击领取按钮")
	--log("BP_CLICK_SubActID ="..BP_STRUCT_ActivtyInfo_Click.SubActID)
	--log("BP_CLICK_SubActIndex ="..BP_STRUCT_ActivtyInfo_Click.SubActIndex)
	--log("BP_CLICK_SubActType ="..BP_STRUCT_ActivtyInfo_Click.SubActType)
	ActivitySystem.Req_TakeActivityAward(BP_STRUCT_ActivtyInfo_Click.SubActID, BP_STRUCT_ActivtyInfo_Click.SubActIndex)
end

--点击跳转按钮

function EventActivtyUIOnClickJumpBtn()
	--log("点击跳转按钮")
	--log("BP_CLICK_SubActID ="..BP_STRUCT_ActivtyInfo_Click.SubActID)
	--log("BP_CLICK_SubActIndex ="..BP_STRUCT_ActivtyInfo_Click.SubActIndex)
	--log("BP_CLICK_SubActType ="..BP_STRUCT_ActivtyInfo_Click.SubActType)

	if BP_STRUCT_ActivtyInfo_Click.SubActType == 4 then
		local function clickOkCallback()
	        LobbyUI.CloseOtherMenu()
			GlobalData:JumpUrl("https://www.apple.com/cn/itunes/charts/free-apps/")
			return
	    end
	    CommonMessageBoxUI:ShowPanel(2, "提示", "即将离开绝地求生：刺激战场\n是否打开'App Store'", clickOkCallback, nil)
		return
	end

	LuaClassObj.HandleUIMessage(bp_activty, "OnCloseBtn");

	--直接根据配置跳转
	EventActivtyUIOnNoticeJump()
	
end

function EventActivtyClickOneBtn()
	--log("点击活动或者公告按钮")
	ActivtyUI.LoadData()
end

function EventActivtyUIOnClickCheckExchange()
	--log("点击提醒按钮")
	--log("BP_CLICK_SubActID ="..BP_STRUCT_ActivtyInfo_Click.SubActID)
	--log("BP_CLICK_SubActIndex ="..BP_STRUCT_ActivtyInfo_Click.SubActIndex)
	--log("BP_CLICK_SubActType ="..BP_STRUCT_ActivtyInfo_Click.SubActType)
	--log("Arg ="..BP_STRUCT_ActivtyInfo_Click.Arg)

	ActivitySystem.Req_DealActivity(BP_STRUCT_ActivtyInfo_Click.SubActID, BP_STRUCT_ActivtyInfo_Click.SubActIndex, BP_STRUCT_ActivtyInfo_Click.Arg)

end

function EventActivtyUIOnNoticeJump()
	--log("公告点击跳转按钮")
	--log("BP_CurrentNoticeJumpMode ="..BP_CurrentNoticeJumpMode)

	---test 
	--BP_CurrentNoticeJumpMode = "game://?module=1001300&id=2017010801"

	if string.starts(BP_CurrentNoticeJumpMode, "game://") or string.starts(BP_CurrentNoticeJumpMode, "http") or string.starts(BP_CurrentNoticeJumpMode, "www") then
		GlobalData:JumpUrl(BP_CurrentNoticeJumpMode)
	else
		--log("不是game，http开头，调用函数")
		if BP_CurrentNoticeJumpMode ~= "" and _G[BP_CurrentNoticeJumpMode] then
			local func = _G[BP_CurrentNoticeJumpMode]
			func()
		end
	end
	
end

function ActivtyShowQQDingYueBox()

	if DataMgr.qqsubscribe and DataMgr.qqsubscribe == 1 then
		--log("已经qq订阅")
		CommonMessageBoxUI:ShowPanel(1, "提示", "已经订阅", nil, nil)
		return
	end

	--log("调用qq订阅信息")
	local function clickOkCallback()
        --这里发送订阅协议
        --log("发送订阅协议")
        DataMgr.SendQQSubscribeRet()
    end
    CommonMessageBoxUI:ShowPanel(2, "提示", "是否QQ订阅？", clickOkCallback, nil)
end

function ActivtyShowDingYueBox()
	if DataMgr.wxsubscribe and DataMgr.wxsubscribe == 1 then
		--log("已经wx订阅")
		CommonMessageBoxUI:ShowPanel(1, "提示", "已经微信订阅", nil, nil)
		return
	end
	--log("调用订阅信息")
	local function clickOkCallback()
        --这里发送订阅协议
        --log("发送订阅协议")
        DataMgr.SendSubscribeRet()
    end
    CommonMessageBoxUI:ShowPanel(2, "提示", "是否订阅？", clickOkCallback, nil)
end

--大厅按钮添加小红点（蓝图回调，如果有未读的新活动）
function EventActivtyUpdateLobbyRedPoint()
	--log("大厅按钮添加小红点")
	UpdateLobbyActivityRedPoint(true)
	
end