--军衔分享UI
ShareLevelUpUI = ShareLevelUpUI or
{

}

BP_STRUCT_ShareLevelUp_ShareInfo = 
{
	levelUpName = "",
	levelUpBgPath = "",
	levelUpFgPath = "",
};

--图片分享保存的路径
BP_ShareLevelUp_ImagePath = "";

function bp_share_levelup_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_levelup,
		{		
			{Path="/Game/UMG/UI_Logic/Share/Share_LevelUp_BP.Share_LevelUp_BP_C", Container="Top", ZOrder=BP_ENUM_UI_SHARE_RANK_ZORDER},
		},
		{"Lobby","Fighting"},
		false,
		false,
		true
	);
end

local function ShareReq()
	ShareMgr.ShareSuccReq(7);
end 

local function OnShareSucessEventHandler(eventType, eventID, vars)

	local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_share_levelup, "UIHide");	
	end	
end

function ShareLevelUpUI:ShowSharePanel()
	LuaClassObj.HandleDynamicCreation(bp_share_levelup);
	BP_STRUCT_ShareLevelUp_ShareInfo = {};
	BP_STRUCT_ShareLevelUp_ShareInfo.levelUpName = BP_RankName;
	BP_STRUCT_ShareLevelUp_ShareInfo.levelUpBgPath = BP_RankBgPath;
	BP_STRUCT_ShareLevelUp_ShareInfo.levelUpFgPath = BP_RankFgPath;
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
	LuaClassObj.HandleUIMessage(bp_share_levelup, "UIShow");
end

--分享好友
function EventShareLevelUpClickShareFriendBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then

		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end

		ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, BP_ShareLevelUp_ImagePath, "", "", ShareType.Friend);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		
		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end		
		ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, "", BP_ShareLevelUp_ImagePath, ShareType.Friend);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventShareLevelUpClickShareFriendBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end
		
	--[[
	--6 军衔数据分享
	if ShareMgr.CanShareByType(6) == false then
		return;
	end
	ShareMgr.SetShareLimit(6);
	--]]
	
	ConnectionWaitingUI:Show();
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareLevelUp_ImagePath, "", "", ShareType.Moment);
	ShareReq();
end

--分享朋友圈
function EventShareLevelUpClickShareZoneBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end

		--6 军衔数据分享
		if ShareMgr.CanShareByType(6) == false then
			return;
		end
		ShareMgr.SetShareLimit(6);

		ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareLevelUp_ImagePath, "", "", ShareType.Moment);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then

		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end

		--6 军衔数据分享
		if ShareMgr.CanShareByType(6) == false then
			return;
		end
		ShareMgr.SetShareLimit(6);		

		ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ShareLevelUp_ImagePath, ShareType.Moment);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventShareLevelUpClickShareZoneBtn");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end
	
	--[[
	--6 军衔数据分享
	if ShareMgr.CanShareByType(6) == false then
		return;
	end
	ShareMgr.SetShareLimit(6);
	--]]
	
	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ShareLevelUp_ImagePath, ShareType.Moment);
	ShareReq();
end

function EventShareLevelUpHide()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end
