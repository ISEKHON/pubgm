--[[
	分享 个人 2017-12-12
--]]

ShareUI = ShareUI or {
	 
}

BP_STRUCT_ShareRoleData =
{
	roleUid = "",
	headIconUrl = "",
	gender = 0,
	nickName = "",
	cur_avatar_box_id = 0,
}


function bp_share_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share,
		{	
			{Path="/Game/UMG/UI_BP/Lobby/Shareinterface_UIBP.Shareinterface_UIBP_C", Container="Default", ZOrder=10},
		},
		{"Lobby"},
		false,
		false
	);
end	 


--组织数据
function ShareUI.ContructData()
	log("ShareUIContructData");
	BP_STRUCT_ShareRoleData = {};	
	BP_STRUCT_ShareRoleData.roleUid = DataMgr.roleData.uid;
	BP_STRUCT_ShareRoleData.headIconUrl = DataMgr.roleData.headIconUrl;
	BP_STRUCT_ShareRoleData.gender = DataMgr.roleData.gender;
	BP_STRUCT_ShareRoleData.nickName = DataMgr.roleData.nickName;	
	BP_STRUCT_ShareRoleData.cur_avatar_box_id = DataMgr.roleData.cur_avatar_box_id;	
	log_tree("ShareUIContructData struct", BP_STRUCT_ShareRoleData);
end

function EventGetRoleData()
	log("EventGetRoleData");	
	ShareUI.ContructData();
end

function EventShare_Push()
	--蓝图变量同步给lua
end

function EventShareFetchInfo()
	--lua变量同步蓝图
end



--保存本地失败
function EventSaveLocalFail()
	DataMgr.ShowNoticeByString("没有访问相册的权限");
end

--保存本地成功
function EventSaveLocalSuccess()
	DataMgr.ShowNoticeByID(110124);
end

--qq好友
function EventClickQQFrientBtn()
	--[[if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
	end]]

	log("EventClickQQFrientBtn");
	--TODO
end

--qq朋友圈
function EventClickQQZoneBtn()
	--[[if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
	end]]
	log("EventClickQQZoneBtn");
end
	
--wx好友
function EventClickWXFrientBtn()
	--[[if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
	end]]
	log("EventClickWXFrientBtn");
	--TODO
end

--wx朋友圈
function EventClickWXZoneBtn()
	--[[if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		--DataMgr.ShowNoticeByID(110126);
	end
	]]
	log("EventClickWXFrientBtn");
end

--结构化分享
function EventStructShare()
	--log("EventStructShare");
	--if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
	--	ShareMgr:shareWechat(MEDIA_TAG_SHARE_INVITE, "结构化分享测试", "structshare");
	--elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
	--	ShareMgr:shareQQ(MEDIA_TAG_SHARE_INVITE, "结构化分享测试", ShareType.Friend);
	--end
	log("test livebroadcast");
	LuaClassObj.HandleUIMessage(bp_live_broadcast, "UIShow");
end

--分享给好友
function EventShareToFriend()
	--log("EventShareToFriend");
	--local params = {};
	--params.openid = DataMgr.roleData.openID;
	--ShareMgr:shareToFriend(params);
	----
	log("EventShowItemShare");
	local arrayItemData = {};
	table.insert(arrayItemData, {res_id = 404003, count = 1});
	CommonItemGetUI:ShowPanel(arrayItemData);
end
