UIExcitingParty = UIExcitingParty or {}

-- 刺激盛宴说明
local ExcitingPartyRule_Content = [[1、 活动第一天，第三天，第五天，第七天，第九天晚上20点会分别揭晓一项全服成就，成功分享成就即可领取对应奖励。
2、打开刺激盛宴宝箱有机会获得永久/30天运动裤（黄色），无袖机车夹克（7天），百褶超短裙 (蓝色)(7天)，百褶超短裙 (黑色)(7天)，迷彩超短裤（7天）等PUBG经典时装奖励。
3、活动期间，成功分享全部成就即可领取终极大奖：永久运动外套（黄色）。
4、温馨提示：分享成就到QQ/微信后请立即返回游戏领取奖励，如果停留在QQ/微信再返回游戏，可能会出现无法领取的情况，重新分享后返回游戏即可领取。
]]
local ExcitingPartyRule_Title = "活动规则"


--蓝图调用

BP_STRUCT_Exciting_Party_Award_Info  =
{
	itemId = 0,
	count = 0,
	expireTime = 0, 
} 

BP_ARRAY_Exciting_Party_Award_Infos =
{
	BP_STRUCT_Exciting_Party_Award_Info = _G.BP_STRUCT_Exciting_Party_Award_Info, 
} 

--服务器信息
BP_STRUCT_Exciting_Party_Info =
{
	itemIdx = 0,
	mainActID = 0,
	actID = 0,
    targetNum = "",
	status = 0, 
	openTime = 0,
	openTimeStr = "", 
	title = "",
	titleHide = "", 
	bigProgress = "",
	showName = "",
	shareNum = "", -- 分享显示的数字 

	BP_ARRAY_Exciting_Party_Award_Infos = _G.BP_ARRAY_Exciting_Party_Award_Infos   
}

--服务器列表
BP_ARRAY_Exciting_Party_Infos =
{
	BP_STRUCT_Exciting_Party_Info = _G.BP_STRUCT_Exciting_Party_Info,
}

-- BP_STRUCT_Exciting_Party_BigAward_Info = _G.BP_STRUCT_Exciting_Party_Info 

-- 需要操作的item idx，领取，查看之类
BP_ExcitingPart_Op_Item_Idx = -1

-- 活动时间段字符串
BP_Exciting_Party_ACT_TIME = ""

local function InitTestData()
	-- for i = 1, 6 do
	-- 	local need =(i * i * 5 - 4) * 50000
	-- 	local award = 405009 + i
		
	-- 	local info = {needInvietCount = need, awardID = award}
		
	-- 	table.insert(BP_ARRAY_Promotion_Award_Infos, info)
	-- end
	-- log("award len = " .. #BP_ARRAY_Promotion_Award_Infos)
end

--注册Widget
function bp_exciting_party_RegisterUI() 
	
	LuaClassObj.SubUIWidgetList(bp_exciting_party,
		{
			{Path = "/Game/UMG/UI_Logic/Promotion/ExcitingParty_BP.ExcitingParty_BP_C", Container = "Default", ZOrder = BP_ENUM_UI_PROMOTION_ZORDER},
			{Path = "/Game/UMG/UI_Logic/Promotion/ExcitingPary_ViewBox_BP.ExcitingPary_ViewBox_BP_C", Container = "Default", ZOrder = BP_ENUM_UI_PROMOTION_ZORDER + 5}
		},
		{"Lobby"},
		false,
		bp_exciting_party_OnModeSwitched ~= nil 
	)

	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, UIExcitingParty.RefreshExcitingPartyInfo) 
end

--跳转到Lobby
function bp_exciting_party_OnModeSwitched(gamestatus)
	log("bp_exciting_party_OnModeSwitched  gamestatus = " .. gamestatus);
	if string.lower(gamestatus) ~= "lobby" then
		--设置定时器
		LuaClassObj.HandleUIMessage(bp_lobby, "RefreshTimer")
		EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler) 
	end
end 

function UIExcitingParty.InitExcitingPartyUIData()
	local datas = ExcitingPartyMgr.ExcitingPartyInfo

	-- 一共有6组数据，最后一组是大奖
	log("exciting party data len = " .. #datas)
	BP_ARRAY_Exciting_Party_Infos = {} 
	local bigPro = 0
	for i=1,#datas do
		if i < 6 and datas[i].status == 2 then
			bigPro = bigPro + 1 
		elseif i == 6 then
			datas[i].bigProgress = string.format("即可领取(%d/5)", bigPro) 
		end

		table.insert(BP_ARRAY_Exciting_Party_Infos, datas[i]) 
	-- else
	-- 	BP_STRUCT_Exciting_Party_BigAward_Info = datas[i] 
	end

	BP_Exciting_Party_ACT_TIME = ExcitingPartyMgr.actDurationTime 
end

function UIExcitingParty.RefreshExcitingPartyInfo(eventType, eventID, changeList)

	if changeList.typeList[ActivityType.GROUP_EXCITE] == true then
		-- log("tttttttt") 
		ExcitingPartyMgr.DealExcitingPartyFromActivity()

		if ExcitingPartyMgr.isInTime then
			UIExcitingParty.InitExcitingPartyUIData()
			LuaClassObj.HandleUIMessage(bp_exciting_party, "UpdateData")
		end 
	end
	
end

function UIExcitingParty.SendGetAward()
	local awardInfo = BP_ARRAY_Exciting_Party_Infos[BP_ExcitingPart_Op_Item_Idx] 
	if awardInfo then		
		ActivitySystem.Req_TakeActivityAward(awardInfo.actID , BP_ExcitingPart_Op_Item_Idx) 
	end

	BP_ExcitingPart_Op_Item_Idx = -1
end

function EventRefreshOpenExcitingPartyTime()
	local serverTime = FuncUtil.GetServerTimeInSec() 
	for i=1,#BP_ARRAY_Exciting_Party_Infos - 1 do
		local one = BP_ARRAY_Exciting_Party_Infos[i]

        if one.status == 0 and serverTime > one.openTime then
			-- actOne.status = 1 
			ActivitySystem.Req_AcitvityOneData(one.mainActID) 
        end
	end
end

local function OnShareSucessEventHandler(eventType, eventID, vars)
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler)
	log("OnShareSucess1") 
	if BP_ExcitingPart_Op_Item_Idx <= 0 then
		log("OnShareSucess2 " .. BP_ExcitingPart_Op_Item_Idx) 
		return
	end
	-- UIExcitingParty.SendGetAward() 
	log("OnShareSucess3") 
	if eventType == EVENTTYPE_SHARE and eventID == EVENTID_SHARE_SUCESSFUL then
		-- if vars and vars[1] == 1 and vars[2] == MEDIA_TAG_SHARE_EXCITING_PARTY then
		if vars and vars[1] == 1 then 
			DataMgr.ShowNoticeByID(102031) 
			log("UIExcitingParty OnShareSucessEventHandler   success")
			LuaClassObj.HandleUIMessage(bp_exciting_party, "OnShareSuccess") 
		end
	end
end

function EventExcitingPartyShare()

	local awardInfo = BP_ARRAY_Exciting_Party_Infos[BP_ExcitingPart_Op_Item_Idx]
	if awardInfo == nil then	
		return
	end
	
	ShareExcitingPartyUI.ShowUI(awardInfo) 
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler)


	-- local function fireEvent()
	-- 	log("fire share")
	-- 	local vars = {};
	-- 	table.insert(vars,1)
	-- 	EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL,vars)
	-- 	-- EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL) 
	-- end
	-- Timer.InsertTimer(3, fireEvent, false) 
end

-- 邀请好友
function EventExcitingPartyShareGet()
	log("EventExcitingPartyShareGet")
	
	local awardInfo = BP_ARRAY_Exciting_Party_Infos[BP_ExcitingPart_Op_Item_Idx] 
	if awardInfo == nil then	
		return
	end
	
	UIExcitingParty.SendGetAward() 
end

-- 关闭UI
function EventExcitingPartyCloseUI()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler) 
	LuaClassObj.HandleUIMessage(bp_exciting_party, "UIHide") 
end
-- 规则
function EventExcitingPartyRule()
	-- log("EventExcitingPartyRule") 
	PopUpNoticeUI.ShowMessageBox(ExcitingPartyRule_Title, ExcitingPartyRule_Content)
end

-- 查看宝箱内容
function EventExcitingPartyViewBox()
	log("EventExcitingPartyViewBox:" .. BP_ExcitingPart_Op_Item_Idx)

	LuaClassObj.HandleUIMessage(bp_exciting_party, "ShowBox")
end

-- 贼神奇
function EventFetchInfo()
	
end

function EventSetInfo_Push()
end
