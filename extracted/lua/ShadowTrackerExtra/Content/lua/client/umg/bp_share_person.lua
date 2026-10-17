--[[
	分享 个人 2017-12-12
--]]

SharePersonUI = SharePersonUI or {
	typeShare = 0; 
}

BP_SharePersonPath = "";

--个人战绩总数据（单人1，双人2，组队3, 总体4）
BP_STRUCT_SharePersonInfo =
{
	roleUid = "",
	headIconUrl = "",
	gender = 0,
	nickName = "",
	mordelStr = "",
	
	role_allmatchnum = "",		--总场数
	role_winnum = "",
	role_toptennum = "",
	role_killnum = "",
	role_kd = "",
	role_critrate = "",
};


function bp_share_person_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_person,
		{		
			{Path="/Game/UMG/UI_Logic/Share/Share_PersonLogicBP.Share_PersonLogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_Share_PersonInfo},
		},
		{"Lobby"},
		false, 
		false,
		true
	);
end	 

--组织数据
function SharePersonUI.ContructData()
	BP_STRUCT_SharePersonInfo = {};	
	local perInfo =  RoleInfoUI.GetShareData();
	log_tree("SharePersonUIContructData", perInfo);
	if perInfo ~= nil then
		BP_STRUCT_SharePersonInfo.role_allmatchnum = perInfo.role_allmatchnum;
		BP_STRUCT_SharePersonInfo.role_winnum = perInfo.role_winnum;
		BP_STRUCT_SharePersonInfo.role_toptennum = perInfo.role_toptennum;
		BP_STRUCT_SharePersonInfo.role_killnum = perInfo.role_killnum;
		BP_STRUCT_SharePersonInfo.role_kd = perInfo.role_kd;
		BP_STRUCT_SharePersonInfo.role_critrate = perInfo.role_critrate;
	end
	
	BP_STRUCT_SharePersonInfo.roleUid = DataMgr.roleData.uid;
	BP_STRUCT_SharePersonInfo.headIconUrl = DataMgr.roleData.headIconUrl;
	BP_STRUCT_SharePersonInfo.gender = DataMgr.roleData.gender;
	BP_STRUCT_SharePersonInfo.nickName = DataMgr.roleData.nickName;	
	BP_STRUCT_SharePersonInfo.mordelStr = ""
	if SharePersonUI.typeShare == 1 then
		--BP_STRUCT_SharePersonInfo.mordelStr = "单人模式"
		BP_STRUCT_SharePersonInfo.mordelStr = Client.GetTableData("LocalizeRes", "110049").TextValue
	elseif SharePersonUI.typeShare == 2 then
		--BP_STRUCT_SharePersonInfo.mordelStr = "双人模式"
		BP_STRUCT_SharePersonInfo.mordelStr = Client.GetTableData("LocalizeRes", "110050").TextValue
	elseif SharePersonUI.typeShare == 3 then
		--BP_STRUCT_SharePersonInfo.mordelStr = "四人模式"
		BP_STRUCT_SharePersonInfo.mordelStr = Client.GetTableData("LocalizeRes", "110051").TextValue
	end	
	
	log_tree("SharePersonUIContructData struct", BP_STRUCT_SharePersonInfo);
end

local  function ShareReqPerson()
	ShareMgr.ShareSuccReq(3);
end 

local function OnShareSucessEventHandler(eventType, eventID, vars)

	if eventType ~= EVENTTYPE_SHARE then
		return;
	end	

	local hasApp = DataMgr.HasInstallPlatApp();
	if hasApp ==  true then
		LuaClassObj.HandleUIMessage(bp_share_person, "UIHide");	
	end
	
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);
end



--显示UI 
function SharePersonUI.ShowUI(typeShare)
	LuaClassObj.HandleDynamicCreation(bp_share_person);
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, OnShareSucessEventHandler);

	SharePersonUI.typeShare = typeShare;	
	
	SharePersonUI.ContructData();
	LuaClassObj.HandleUIMessage(bp_share_person, "UIShow");	
	ClientSendBAReport(BP_BA_SHARE_MAINPANEL, 0);
end


--关闭UI
function EventHideUI()
	LuaClassObj.HandleUIMessage(bp_share_person, "UIHide");	
end


function EventSharePerson_Push()
	--蓝图变量同步给lua
end

function EventSharePersonFetchInfo()
	--lua变量同步蓝图
end


		
		
--qq好友
function EventPersonQQFrientBtn()
	--[[
	log("EventPersonQQFrientBtn");

	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end

	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, "", BP_SharePersonPath, ShareType.Friend);
	ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
	ShareReqPerson();
	--]]
	
	log("[HHF]EventPersonQQFrientBtn");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end
	
	--[[
	--个人战绩3
	if ShareMgr.CanShareByType(3) == false then
		return;
	end
	ShareMgr.SetShareLimit(3);
	--]]

	ConnectionWaitingUI:Show();
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_SharePersonPath, "", "", ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReqPerson();
end

--qq朋友圈
function EventPersonQQZoneBtn()
	log("[HHF]EventPersonQQZoneBtn");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end	

	--[[
	--个人战绩3
	if ShareMgr.CanShareByType(3) == false then
		return;
	end
	ShareMgr.SetShareLimit(3);
	--]]

	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_CHIJI, "", BP_SharePersonPath, ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ShareReqPerson();

	--test
	--ShareMgr.SendShareLimit(2);
end

--wx好友
function EventPersonWXFrientBtn()
	log("EventPersonWXFrientBtn");

	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_FRIEND_CHIJI, BP_SharePersonPath, "", "", ShareType.Friend);
	ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
	ShareReqPerson();
end

--wx朋友圈
function EventPersonWXZoneBtn()
	log("EventPersonWXZoneBtn");

	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	--个人战绩3
	if ShareMgr.CanShareByType(3) == false then
		return;
	end
	ShareMgr.SetShareLimit(3);

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_CHIJI, BP_SharePersonPath, "", "", ShareType.Moment);
	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ShareReqPerson();
end


