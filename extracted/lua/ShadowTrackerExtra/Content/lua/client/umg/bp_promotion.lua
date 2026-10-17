UIPromotion = UIPromotion or {}

local PlatFormStr = {"微信", "QQ" } 
--蓝图调用

--服务器信息
BP_STRUCT_Promotion_Friend_Info =
{
	openID = "",
	nickName = "",
	headUrl = "",
	inviteStatus = 0,
}

--服务器列表
BP_ARRAY_Promotion_Friend_Infos =
{
	BP_STRUCT_Promotion_Friend_Info  = _G.BP_STRUCT_Promotion_Friend_Info,
}

-- 注册游戏的好友列表
BP_ARRAY_Promotion_Register_Friend_Infos =
{
	BP_STRUCT_Promotion_Friend_Info = _G.BP_STRUCT_Promotion_Friend_Info,
} 

-- 邀请的好友
BP_Promotion_Invite_Friend_OpenID = ""

-- 奖励信息
BP_STRUCT_Promotion_Award_Info =
{
	itemIdx = 0,
	needInviteCount = 0,
	mainActID = 0,
	actID = 0,
	currentInviteCount = 0,
	awardID = 0,
	status = 0,
	expireTime = 0, 
} 

BP_ARRAY_Promotion_Award_Infos = 
{
	BP_STRUCT_Promotion_Award_Info = _G.BP_STRUCT_Promotion_Award_Info  
} 

-- 领取的奖励
BP_Promotion_Award_Index_Get = -1 
-- 活动时间
BP_Promotion_Open_Time = ""

local HELP_TEXT = [[活动规则：
1.活动期间，邀请%s好友注册游戏，可获得活动专属时装-猎鹰套装
2.被邀请的玩家注册游戏后，通过邀请链接成功领取注册礼包，即可算作邀请成功
3.成功邀请的玩家满3/5/8人后，点击分享至%s，并点击【返回绝地求生：刺激战场】返回游戏，即可点击领取时装
4.活动结束后，活动面板将消失，未领取的时装将无法领取，请留意公告栏的活动时间
5.多个玩家邀请同一个好友时，被邀请的玩家只能选择接受其中一位玩家的邀请，成功领取注册礼包后不能再接受其他玩家的邀请]]

--显示帮助
BP_Promotion_Help_Content = ""

--注册Widget
function bp_promotion_RegisterUI()
	
	LuaClassObj.SubUIWidgetList(bp_promotion,
	{ 
		{Path = "/Game/UMG/UI_Logic/Promotion/Promotion_BP.Promotion_BP_C", Container = "Default", ZOrder = BP_ENUM_UI_PROMOTION_ZORDER },
		{Path = "/Game/UMG/UI_Logic/Promotion/PromotionRegisterFriend_BP.PromotionRegisterFriend_BP_C", Container = "Default", ZOrder = BP_ENUM_UI_PROMOTION_ZORDER + 1} 
	},
	{"Lobby"},
	false,
	bp_promotion_OnModeSwitched ~= nil 
	
	)

	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, UIPromotion.RefreshPromotionInfo) 
	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_PROMOTION, UIPromotion.GetPromotionInfoAndOpenUI) 
	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHARE, ShareDayFinalyShareUI.ShowUI)
end

local function OnShareSucessEventHandler(eventType, eventID, vars)
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler)

	if BP_Promotion_Award_Index_Get <= 0 then
		log("BP_Promotion_Award_Index_Get" .. BP_Promotion_Award_Index_Get  )
		return
	end
	-- UIExcitingParty.SendGetAward() 

	if eventType == EVENTTYPE_SHARE and eventID == EVENTID_SHARE_SUCESSFUL then
		-- if vars and vars[1] == 1 and vars[2] == MEDIA_TAG_SHARE_EXCITING_PARTY then
		if vars and vars[1] == 1 then 
			log("UIPromotion OnShareSucessEventHandler  success")
			LuaClassObj.HandleUIMessage(bp_promotion, "OnShareSuccess") 
		end
	end
end

--跳转到Lobby
function bp_promotion_OnModeSwitched(gamestatus)
	log("bp_promotion_OnModeSwitched  gamestatus = " .. gamestatus);
	if string.lower(gamestatus) ~= "lobby" then
		EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler) 
	end
end 

function UIPromotion.InitAwardData(actData)

	local dateFormat = Client.GetTableData("LocalizeRes", "110070").TextValue

	BP_Promotion_Open_Time = string.format("%s~%s", os.date(dateFormat, actData.StartTime), os.date(dateFormat, actData.EndTime))
	BP_ARRAY_Promotion_Award_Infos = {}

	for i = 1, #actData.List do
		local one = actData.List[i]
		
		local actOne = {}
		actOne.itemIdx = one.Index
		actOne.mainActID = actData.ID
		actOne.actID = one.ID
        actOne.needInviteCount = one.Total
        actOne.currentInviteCount  = one.Progress 
		actOne.awardID = one.Drop[1].itemId
		actOne.status = one.Status
		actOne.expireTime = one.Drop[1].expireTime 
		
		table.insert(BP_ARRAY_Promotion_Award_Infos, actOne)
	end
end

function UIPromotion:GetPromotionInfoAndOpenUI()
	PromotionMgr.SendGetPromotionInfo() 
end

function UIPromotion.RefreshPromotionInfo(eventType, eventID, changeList)

	if changeList.typeList[ActivityType.PROMOTOR] == true then 
		-- log("tttttttt")
		PromotionMgr.DealPromotionFromActivity()
		LuaClassObj.HandleUIMessage(bp_promotion, "UpdateAwardData")
	end
end

function UIPromotion.UpdateFriendInviteStatus(openid)
	-- log_tree("change openid = " .. openid)
	for i = 1, #BP_ARRAY_Promotion_Friend_Infos do
		local svrData = BP_ARRAY_Promotion_Friend_Infos[i]
		-- log("svrData.openID = " .. svrData.openID )
		if svrData.openID == openid then
			svrData.inviteStatus = 1
			LuaClassObj.HandleUIMessage(bp_promotion, "UpdateFriendData") 			
			break
		end
	end
end

function UIPromotion.OnGetPromotionFriendList(frdList, regList)
	-- 处理邀请列表
	BP_ARRAY_Promotion_Friend_Infos = {}
	
	if frdList then
		for i = 1, #frdList do
			local svrData = frdList[i]
			local frd = {}
			frd.openID = svrData.sopenid
			frd.nickName = svrData.nick_name
			frd.headUrl = svrData.head_img_url
			frd.inviteStatus = svrData.status
			
			table.insert(BP_ARRAY_Promotion_Friend_Infos, frd)
		end 
	end

	-- 处理已邀请列表
	BP_ARRAY_Promotion_Register_Friend_Infos = {}
	
	if regList then
		listNeedUin = {}
		for i=1,#regList  do
			-- local svrData = regList[i]
			local frd = {}
			-- 其实存的是gid
			frd.openID  = regList[i]  
			local frdInfo = FriendSystem.GetFriendDataByGID(frd.openID)
			-- frdInfo = nil 
			if frdInfo then
				frd.nickName = frdInfo.nickName	
				frd.headUrl = frdInfo.picUrl
				frd.inviteStatus = 2
			else
				table.insert(listNeedUin, frd.openID)
				frd.nickName = ""
				frd.headUrl = ""
				frd.inviteStatus = 2
			end
			table.insert(BP_ARRAY_Promotion_Register_Friend_Infos, frd) 
		end

		if #listNeedUin > 0 then
			ProfileMgr.GetFriendProfileList(listNeedUin, UIPromotion.OnGetFriendProfile, false) 
		end
	end

	-- for i=1,10 do
	-- 	local frd = {}
	-- 	-- 其实存的是gid
	-- 	frd.openID  = "410000528"  
	-- 	local frdInfo = FriendSystem.GetFriendDataByGID(frd.openID) 
	-- 	if frdInfo then
	-- 		frd.nickName = frdInfo.nickName	
	-- 		frd.headUrl = frdInfo.picUrl
	-- 		frd.inviteStatus = 2
			
	-- 		table.insert(BP_ARRAY_Promotion_Register_Friend_Infos, frd)
	-- 	end 
	-- end
end

function UIPromotion.OnGetFriendProfile(profileList)
	-- log_tree("UIPromotion.OnGetFriendProfile",profileList)
	for k, v in pairs(profileList) do
		local has = false
		for i = #BP_ARRAY_Promotion_Register_Friend_Infos, 1, - 1 do
			if tonumber(BP_ARRAY_Promotion_Register_Friend_Infos[i].openID) == tonumber(v.uid) then
				BP_ARRAY_Promotion_Register_Friend_Infos[i].nickName = v.nickName
				BP_ARRAY_Promotion_Register_Friend_Infos[i].headUrl = v.picUrl
			end
		end
	end

	LuaClassObj.HandleUIMessage(bp_promotion, "UpdateRegFriendInfos") 
end 

function UIPromotion.OpenUI()
	LuaClassObj.HandleUIMessage(bp_promotion, "UIShow") 
	LuaClassObj.HandleUIMessage(bp_promotion, "UpdateFriendData") 
	LuaClassObj.HandleUIMessage(bp_promotion, "UpdateAwardData") 

	if BP_Promotion_Help_Content == ""  then
		BP_Promotion_Help_Content = string.format(HELP_TEXT, PlatFormStr[BP_Platform], PlatFormStr[BP_Platform]) 
	end
end

-- 一键邀请
function EventPromotionGetAward()
	log("EventPromotionGetAward ") 

	local awardInfo = BP_ARRAY_Promotion_Award_Infos[BP_Promotion_Award_Index_Get]
	if awardInfo then		
		ActivitySystem.Req_TakeActivityAward(awardInfo.actID, BP_Promotion_Award_Index_Get)
	end
	
	BP_Promotion_Award_Index_Get = - 1
end

function EventPromotionShare()
	
	ShareDayFinalyShareUI.ShowUI() 
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler)

	-- local function fireEvent()
	-- 	log("fire share")
	-- 	local vars = {};
	-- 	table.insert(vars, 1)
	-- 	EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, vars)
	-- 	-- EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL) 
	-- end
	-- Timer.InsertTimer(3, fireEvent, false)
end 


-- 邀请好友
function EventPromotionFriendInvite()
	log("EventPromotionFriendInvite OpenID = " .. BP_Promotion_Invite_Friend_OpenID)

	local strTile = DataMgr.GetMsgByID(102012)
	local strMsg = DataMgr.GetMsgByID(9990002)
	strMsg = string.format(strMsg, PlatFormStr[BP_Platform]) 
	
	local function clickOkCallback()
		PromotionMgr.SendInviteFriend(BP_Promotion_Invite_Friend_OpenID) 
	end
	CommonMessageBoxUI:ShowPanel(2, strTile, strMsg, clickOkCallback)

	-- PromotionMgr.SendInviteFriend(BP_Promotion_Invite_Friend_OpenID) 
end 

-- 
function EventPromotionViewRegisterFriend()
	log("EventPromotionViewRegisterFriend")
	LuaClassObj.HandleUIMessage(bp_promotion, "ShowReigsterFriends")
end

-- 关闭UI
function EventPromotionCloseUI()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler)
	LuaClassObj.HandleUIMessage(bp_promotion, "UIHide")
end 

-- 贼神奇
function EventFetchInfo()

end 

function EventSetInfo_Push()
end 
