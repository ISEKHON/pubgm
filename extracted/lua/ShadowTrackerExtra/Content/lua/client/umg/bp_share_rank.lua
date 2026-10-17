--段位分享UI
ShareRankUI = ShareRankUI or
{

}

BP_STRUCT_ShareRank_ShareInfo = 
{
	rankName = "",
	rankPointStr = "",
	rankLevel = 0,
	rankTypeName = "",
};

--图片分享保存的路径
BP_ShareRank_ImagePath = "";

function bp_share_rank_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_rank,
		{		
			{Path="/Game/UMG/UI_Logic/Share/Share_Rank_BP.Share_Rank_BP_C", Container="Top", ZOrder=BP_ENUM_UI_SHARE_RANK_ZORDER},
		},
		{"Lobby","Fighting"},
		false,
		false,
		true
	);
end

local function ShareReq()
	ShareMgr.ShareSuccReq(6);
end 

local function OnShareSucessEventHandler(eventType, eventID, vars)

    local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_share_rank, "UIHide");	
	end
	
end

function ShareRankUI:ShowSharePanel()
	LuaClassObj.HandleDynamicCreation(bp_share_rank);
	BP_STRUCT_ShareRank_ShareInfo = {};
	BP_STRUCT_ShareRank_ShareInfo.rankName = BP_LevelUp_NewRankName;
	BP_STRUCT_ShareRank_ShareInfo.rankPointStr = string.format("%d分", math.floor(BP_LevelUp_NewRankPoint));
	BP_STRUCT_ShareRank_ShareInfo.rankLevel = BP_LevelUp_NewRankLevel;
	if BP_LevelUp_RankType == 1 then
        BP_STRUCT_ShareRank_ShareInfo.rankTypeName = Client.GetTableData("LocalizeRes", "110049").TextValue;
    elseif BP_LevelUp_RankType == 2 then
        BP_STRUCT_ShareRank_ShareInfo.rankTypeName = Client.GetTableData("LocalizeRes", "110050").TextValue;
    else
        BP_STRUCT_ShareRank_ShareInfo.rankTypeName = Client.GetTableData("LocalizeRes", "110051").TextValue;
    end
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
	LuaClassObj.HandleUIMessage(bp_share_rank, "UIShow");
end

--保存本地/相册
function EventItemShareClickSaveLocalBtn()
	
end

--分享好友
function EventShareRankClickShareFriendBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then

		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end

		ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, BP_ShareRank_ImagePath, "", "", ShareType.Friend);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then

		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end

		ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, "", BP_ShareRank_ImagePath, ShareType.Friend);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventShareRankClickShareFriendBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end	
	
	--[[
	--7 段位数据分享
	if ShareMgr.CanShareByType(7) == false then
		return;
	end
	ShareMgr.SetShareLimit(7);		
	--]]
	
	ConnectionWaitingUI:Show();
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareRank_ImagePath, "", "", ShareType.Moment);
	ShareReq();
end

--分享朋友圈
function EventShareRankClickShareZoneBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then

		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end	

		--7 段位数据分享
		if ShareMgr.CanShareByType(7) == false then
			return;
		end
		ShareMgr.SetShareLimit(7);		

		
		ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ShareRank_ImagePath, "", "", ShareType.Moment);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end

		--7 段位数据分享
		if ShareMgr.CanShareByType(7) == false then
			return;
		end
		ShareMgr.SetShareLimit(7);			

		ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ShareRank_ImagePath, ShareType.Moment);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventShareRankClickShareZoneBtn");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end
	
	--[[
	--7 段位数据分享
	if ShareMgr.CanShareByType(7) == false then
		return;
	end
	ShareMgr.SetShareLimit(7);
	--]]	
	
	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ShareRank_ImagePath, ShareType.Moment);
	ShareReq();
end

function EventShareRankHide()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end
