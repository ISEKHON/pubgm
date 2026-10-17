--[[
	每日分享 2017-12-16
--]]

ShareDayFinalyShareUI = ShareDayFinalyShareUI or {
	 
}

BP_ShareDayFinalyNick = ""; --人物昵称
BP_ShareDayFinalySologan = "绝地求生：刺激战场等你来战！";
BP_ShareDayFinalyPath = ""; --截图图片路径
BP_ShareDayFinalyUrl = ""; --人物头像


function bp_share_dayfinaly_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_dayfinaly,
		{
			{Path="/Game/UMG/UI_Logic/Share/Share_DayFinalyLogicBP.Share_DayFinalyLogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_Share_Day_Fianly_ZORDER},
		},
		{"Lobby"},
		false,
		false,
		true
	);
	
	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHARE, ShareDayFinalyShareUI.ShowUI);
end	

function EventShareDayFinaly_Push()
	--蓝图变量同步给lua
end

function EventShareDayFinalyFetchInfo()
	--lua变量同步蓝图
end

local function OnShareSucessEventHandler(eventType, eventID, vars)

	if eventType ~= EVENTTYPE_SHARE then
		return;
	end	

	local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_share_dayfinaly, "UIHide");	
	end
	
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
end


--显示UI 
function ShareDayFinalyShareUI.ShowUI()		
	LuaClassObj.HandleDynamicCreation(bp_share_dayfinaly);
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
	if DataMgr.roleData ~= nil then
		BP_ShareDayFinalyNick = DataMgr.roleData.nickName;
		BP_ShareDayFinalyUrl = DataMgr.roleData.headIconUrl;
	end

	LuaClassObj.HandleUIMessage(bp_share_dayfinaly, "UIShow");	
	ClientSendBAReport(BP_BA_SHARE_MAINPANEL, 0);
end

local  function ShareReqDay()
	ShareMgr.ShareSuccReq(2);
end 

--保存本地
function EventClickBtnSave()
	Log("bp_share_dayfinaly clickSaveLoc");
	
end

--qq好友
function EventDayQQFrientBtn()
	--[[
	--EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL);	
	--ShareMgr:onShareResult(1, "");

	log("EventDayQQFrientBtn");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end

	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, "", BP_ShareDayFinalyPath, ShareType.Friend);

	ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
	ShareReqDay();
	--]]

	log("[HHF]EventDayQQFrientBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end

	--[[
	--每日分享2
	if ShareMgr.CanShareByType(2) == false then
		return;
	end
	ShareMgr.SetShareLimit(2);
	--]]
	
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareDayFinalyPath, "", "", ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReqDay();
end

--qq朋友圈
function EventDayQQZoneBtn()
	log("[HHF]EventDayQQZoneBtn");	

	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end

	--[[
	--每日分享2
	if ShareMgr.CanShareByType(2) == false then
		return;
	end
	ShareMgr.SetShareLimit(2);
	--]]

	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ShareDayFinalyPath, ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareReqDay();
end

--wx好友
function EventDayWXFrientBtn()
	log("EventDayWXFrientBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, BP_ShareDayFinalyPath, "", "", ShareType.Friend);

	ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
	ShareReqDay();
end

--wx朋友圈
function EventDayWXZoneBtn()
	log("EventDayWXZoneBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	--每日分享2
	if ShareMgr.CanShareByType(2) == false then
		return;
	end
	ShareMgr.SetShareLimit(2);
	
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareDayFinalyPath, "", "", ShareType.Moment);

	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReqDay();
end




