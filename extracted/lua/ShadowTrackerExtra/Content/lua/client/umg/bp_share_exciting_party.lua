--[[	
    刺激盛宴分享 nanneli
--]]
ShareExcitingPartyUI = ShareExcitingPartyUI or {
	
}

BP_ShareExcitingPartyPath = ""

--分享的的数据
BP_STRUCT_ShareExcitingPartyInfo =
{
	shareIndex = 0, 
	shareNum = ""
}

-- 这个分享UI,zorder要比跑马灯高
function bp_share_exciting_party_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_exciting_party,
	{		
		{Path = "/Game/UMG/UI_Logic/Share/Share_ExcitingPartyBP.Share_ExcitingPartyBP_C", Container = "Default", ZOrder = BP_ENUM_UI_SCROLLMSG_ZORDER + 5},
	},
	{"Lobby"},
	false,
	false
	);
end	

local function OnShareSucessEventHandler(eventType, eventID, vars)
	
	if eventType ~= EVENTTYPE_SHARE then
		return;
	end	
	
	EventExcitingPartyHideUI()	
    
    -- if eventType == EVENTTYPE_SHARE and eventID == EVENTID_SHARE_SUCESSFUL then
	-- 	if vars and vars[1] == 1 and vars[2] == MEDIA_TAG_SHARE_EXCITING_PARTY then
	-- 		log("ShareExcitingPartyUI.OnShareSucessEventHandler   success")
	-- 		UIExcitingParty.SendGetAward()
	-- 	end
	-- end
end



--显示UI 
function ShareExcitingPartyUI.ShowUI(awardInfo)
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
	
	BP_STRUCT_ShareExcitingPartyInfo.shareIndex = awardInfo.itemIdx  
	BP_STRUCT_ShareExcitingPartyInfo.shareNum = awardInfo.shareNum 

	LuaClassObj.HandleUIMessage(bp_share_exciting_party, "UIShow")
	LuaClassObj.HandleUIMessage(bp_share_exciting_party, "UpdateContent")
	-- ClientSendBAReport(BP_BA_SHARE_MAINPANEL, 0);
end



--关闭UI
function EventExcitingPartyHideUI()
    log("EventExcitingPartyHideUI")
    EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler) 

    local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_share_exciting_party, "UIHide");	
	end
	
end


function EventShareExcitingParty_Push()
	--蓝图变量同步给lua
end

function EventShareExcitingPartyFetchInfo()
	--lua变量同步蓝图
end

local function ShareReqExcitingParty()
	ShareMgr.ShareSuccReq(8)
end 


--qq好友
function EventExcitingPartyQQFriendBtn()
	log("EventExcitingPartyQQFriendBtn");

	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end


	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_EXCITING_PARTY, "", BP_ShareExcitingPartyPath, ShareType.Friend);
	-- ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
	ShareReqExcitingParty() 
end

--qq朋友圈
function EventExcitingPartyQQZoneBtn()
	log("EventExcitingPartyZoneBtn");	
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end

	if ShareMgr.CanShareByType(8) == false then
		return
	end

	ShareMgr.SetShareLimit(8) 
	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_EXCITING_PARTY, "", BP_ShareExcitingPartyPath, ShareType.Moment);
	-- ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareReqExcitingParty() 
end

--wx好友
function EventExcitingPartyWXFriendBtn()
	log("EventExcitingPartyFriendBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_EXCITING_PARTY, BP_ShareExcitingPartyPath, "", "", ShareType.Friend);
	-- ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
	ShareReqExcitingParty() 
end

--wx朋友圈
function EventExcitingPartyWXZoneBtn()
	log("EventExcitingPartyZoneBtn ");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	if ShareMgr.CanShareByType(8) == false then
		return
	end
	
	ShareMgr.SetShareLimit(8)

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_EXCITING_PARTY, BP_ShareExcitingPartyPath, "", "", ShareType.Moment);
	-- ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReqExcitingParty() 
end


