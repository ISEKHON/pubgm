--获得物品分享UI
ItemShareUI = ItemShareUI or
{

}

BP_STRUCT_ItemGetShare_ShowInfo = 
{
	res_id = 0,--物品id
	valid_hours_str = "",
	tip = "",--文字提示
	play_name = "",--玩家昵称
	uid = "",
	icon_url = "";
	gender = 1;
}

--图片分享保存的路径
BP_ItemGetShare_ImagePath = "";

function bp_item_get_share_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_item_get_share,
		{		
			{Path="/Game/UMG/UI_Logic/Share/Share_Item_Get_BP.Share_Item_Get_BP_C", Container="Top", ZOrder=BP_ENUM_UI_SHARE_ITEM_ZORDER},
		},
		{"Lobby"},
		false,
		false,
		true
	);
end

function EventShowSharePanel()
	ItemShareUI:ShowSharePanel();
end

local function ShareReq()
	ShareMgr.ShareSuccReq(1);
end 

local function OnShareSucessEventHandler(eventType, eventID, vars)

    local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_item_get_share, "UIHide");	
	end
		
end

function ItemShareUI:ShowSharePanel()
	LuaClassObj.HandleDynamicCreation(bp_item_get_share);
	
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
	local itemGetInfo = _G.BP_Array_GoodItemGet_ToShow[1];
	BP_STRUCT_ItemGetShare_ShowInfo = {};
	BP_STRUCT_ItemGetShare_ShowInfo.res_id = itemGetInfo.res_id;
	local iteminfo = Client.GetTableData("Item", itemGetInfo.res_id);
	BP_STRUCT_ItemGetShare_ShowInfo.valid_hours_str = itemGetInfo.valid_hours_str;
	BP_STRUCT_ItemGetShare_ShowInfo.tip = ShareMgr.GetTraitidNum(iteminfo.ItemQuality);
	BP_STRUCT_ItemGetShare_ShowInfo.play_name = DataMgr.roleData.nickName;
	BP_STRUCT_ItemGetShare_ShowInfo.uid = DataMgr.roleData.uid;
	BP_STRUCT_ItemGetShare_ShowInfo.icon_url = DataMgr.roleData.headIconUrl;
	BP_STRUCT_ItemGetShare_ShowInfo.gender = DataMgr.roleData.gender;
	LuaClassObj.HandleUIMessage(bp_item_get_share, "UIShow");
	
	ClientSendBAReport(BP_BA_SHARE_ITEMPANEL, 0);
	ClientSendBAReport(BP_BA_SHARE_MAINPANEL, 0);
end

--保存本地/相册
function EventItemShareClickSaveLocalBtn()
	
end

--分享好友
function EventItemShareClickShareFriendBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then

		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end	

		ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, BP_ItemGetShare_ImagePath, "", "", ShareType.Friend);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then

		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end

		ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, "", BP_ItemGetShare_ImagePath, ShareType.Friend);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventItemShareClickShareFriendBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end
	
	--[[
	if ShareMgr.CanShareByType(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id) == false then
	   return;
	end
	ShareMgr.SetShareLimit(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id);
	--]]
	
	ConnectionWaitingUI:Show();
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ItemGetShare_ImagePath, "", "", ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReq();
end

--分享朋友圈
function EventItemShareClickShareZoneBtn()
	--[[
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		if Client.IsInstallWX(NetInterface) == false then 
			--你还没有安装微信，无法使用此功能
			DataMgr.ShowNoticeByID(110126);
			return;
		end
		if ShareMgr.CanShareByType(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id) == false then
		   return;
		end
		ShareMgr.SetShareLimit(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id);

		ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
		ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_ItemGetShare_ImagePath, "", "", ShareType.Moment);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		if Client.IsInstallQQ(NetInterface) == false then 
			--你还没有安装QQ，无法使用此功能
			DataMgr.ShowNoticeByID(110125);
			return;
		end
		if ShareMgr.CanShareByType(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id) == false then
		   return;
		end
		ShareMgr.SetShareLimit(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id);
			
		ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
		ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ItemGetShare_ImagePath, ShareType.Moment);
	end
	ShareReq();
	--]]
	
	log("[HHF]EventItemShareClickShareZoneBtn");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end	
	
	--[[
	if ShareMgr.CanShareByType(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id) == false then
	   return;
	end
	ShareMgr.SetShareLimit(1, BP_STRUCT_ItemGetShare_ShowInfo.res_id);
	--]]
	
	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_ItemGetShare_ImagePath, ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareReq();
end

function EventItemShareHide()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end
