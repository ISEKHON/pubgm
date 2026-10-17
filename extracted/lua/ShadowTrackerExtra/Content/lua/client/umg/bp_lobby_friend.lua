--好友UI
LobbyFriendUI = LobbyFriendUI or
{
	lastClickPresentCoinTime = 0,  	----上一次金币赠送时间
	PresentCoinDeltaTime = 1,   	----赠送金币中间点击间隔时间
}

--好友结构的定义
BP_STRUCT_FriendProfile =
{
    gid="",
	nickName = "",
	level = 0,
	militaryRank = "";
    picUrl = "",
    vipLevel = 0,
    ladder = 0,-- 天梯
    platName = "",
    sex = 0,-- 1为男，2为女
    lastOnlineTime = 0,
	lastOnlineTimeStr = "",
	lastLoginTime = 0,
	exp = 0,
	segment_info_solo = 0,-- 段位数据
	segment_info_duo = 0,
	segment_info_squad = 0,
	
	startup_type = 0,-- 启动类型
	qq_vip = 0,-- QQ会员
	
	friendType = 0,-- 好友类型（平台1、游戏内0） 
	
    applyMsg="", --好友申请里的留言
	createTime = 0,--好友申请的发送时间
	createTimeStr = "",
	
	online = 1, -- 0为离线，1为在线
	showInviteIcon = 0,
		
	teamState = 0, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
	currentTeamAmount = 1, -- 当前队伍人数
	maxTeamAmount = 4, -- 队伍最大可容纳人数
	teamId = 0, -- 队伍id
	timeSinceGameBegin = 0, -- 已开局时间
	timeSinceGameBeginStr = "",
	
	endtime=0,-- 战斗结算时间
	endtimeStr="",
	rank=0, --排名
	total=0, -- 总人数
	score="", --评分
	kill=0, --淘汰人数
	mode=0, --模式
	modeStr="",
	
	intimacy=0,--亲密度
	lastInviteTime=0,--上次邀请时间
	remarks_name="",--备注名称，有备注名称表示备注名称，无备注表示平台名称
	cur_avatar_box_id=0,
	remarks_name="",--平台备注名（无则表示平台名称）
	
	lastPresentCoinTime=0,--上次赠送时间
	bPresentedCoin=0,--是否赠送过金币(0未赠送，1赠送过)
	bXiaoYue=0,--是否是小悦
	bNewMessage=0,--小悦是否有小红点
    
    AllSegment_Info = {},
    
};

--平台好友列表
BP_ARRAY_Plat_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile, --定义结构体数组，这种写法要作为规范规定下来
}

--游戏内好友列表
BP_ARRAY_Inner_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

--搜索好友列表
BP_ARRAY_Search_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

--邀请好友列表(被别人申请加为好友的)
BP_ARRAY_Apply_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

--已发送的邀请列表(申请别人为好友的)
BP_ARRAY_Invite_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

--黑名单id列表
BP_ARRAY_Friend_ID_Blacklist =
{
}
--黑名单列表（从好友列表和平台列表取数据）
BP_ARRAY_Blacklist_Friend_Profile =
{
    BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

--最近组队队友
BP_ARRAY_Recent_Teammate_Profile =
{
	BP_STRUCT_FriendProfile = _G.BP_STRUCT_FriendProfile,
}

function bp_lobby_friend_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_lobby_friend,
		{{Path="/Game/UMG/UI_BP/Friend/LobbyFriendList_UIBP.LobbyFriendList_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_FRIEND_ZORDER}},
		{"Lobby"},
		false,
        bp_lobby_friend_OnModeSwitched ~= nil,
		true
	);
    
end

function bp_lobby_friend_OnModeSwitched(gamestatus)
	log("OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
        FriendSystem.Enter();
	end
end

function bp_lobby_friend_OnModeAboutToSwitched()
end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

BP_Friend_Platform = 0;
function LobbyFriendUI:Init()
	log("LobbyFriendUI Init");
	local msg = Client.GetTableData("LocalizeRes",200006);
	if msg then
		BP_Verify_DefaultWord = msg.TextValue;
	end
	-- 获取当前平台
	BP_Friend_Platform = BP_Platform;
	
	
	
end

function LobbyFriendUI:Release()
	log("LobbyFriendUI Release");
end

BP_Is_Show = false;
function LobbyFriendUI:Show()
	LuaClassObj.HandleDynamicCreation(bp_lobby_friend);
    log("LobbyFriendUI Show");

	if BP_Platform == BP_ENUM_PLAYFORM_WX or BP_Platform == BP_ENUM_PLAYFORM_QQ then
		LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIShow");
	elseif BP_Platform == BP_ENUM_PLAYFORM_TOURIST then
		LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIShow2");
	end
end

function LobbyFriendUI:Hide()
    log("LobbyFriendUI Hide");
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIHide");
end

function LobbyFriendUI:Jump()
	log("LobbyFriendUI Jump");
	if BP_Platform == BP_ENUM_PLAYFORM_WX or BP_Platform == BP_ENUM_PLAYFORM_QQ then
		LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIJump");
	elseif BP_Platform == BP_ENUM_PLAYFORM_TOURIST then
		LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIJump2");
	end
end

--拉取id列表 begin，需要一个openid
BP_SelfOpenid = ""; 
function EventLobbyFriendOpenId_Push()
	log("EventLobbyFriendOpenId_Push");
    --FriendSystem.getFriendIDList();
    FriendSystem.FetchFriendList();
end

function EventLobbyFriendOpenIdPlat_Push()
    FriendSystem.getFriendIDListPlat();
end

function EventLobbyFriendInner_Push()
    FriendSystem.getFriendIDListInnder();
end

-- 判断是游戏好友不是平台好友
BP_FriendSystem_CheckFriendTypeUid = ""
BP_FriendSystem_IsInnerFriendNotPlatFriend = false

function EventLobbyFriendCheckFriendInnerandPlat_Push()
    log("EventLobbyFriendCheckFriendInnerandPlat_Push" .. tostring(BP_FriendSystem_CheckFriendTypeUid))
    
    BP_FriendSystem_IsInnerFriendNotPlatFriend = FriendSystem.IsInnerFriendNotPlatFriend(BP_FriendSystem_CheckFriendTypeUid)
end
-----

function LobbyFriendUI:UpdateInnerList()
	log("updateinnerpanel");
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateInnerPanel");
end

function EventFetchInfo()

end

function LobbyFriendUI:UpdatePlatList()
	log("updateplatpanel");
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdatePlatPanel");
end
--拉取id列表 end

--查找好友相关 begin
BP_SearchName = "";
function EventLobbyFriendSearch_Push()
	--[[local result = tonumber(BP_SearchName);
	if result then
		local list = {result};
	    NetUtil.SendPkg("batch_get_profile_req", "search", list,BP_PROFILE_MSG_TYPE_FRIEND);
	else
	end]]--
	
	FriendSystem.find_uid_by_name_req(BP_SearchName);
end

-- 搜索为空时的提示
function EventLobbyFriendSearchEmpty_Push()
	DataMgr.ShowNoticeByID(200015);
end

--赠送金币的好友的金币
BP_FriendSystem_Present_Coin_Friend_ID="";
function EventLobbyPresentCoin_Push()
	local curTime = FuncUtil.GetServerTimeInSec()
	local deltaTime = curTime - LobbyFriendUI.lastClickPresentCoinTime
	if deltaTime > LobbyFriendUI.PresentCoinDeltaTime then
		lastClickPresentCoinTime = curTime;
		FriendSystem.present_friend_gold_req(tonumber(BP_FriendSystem_Present_Coin_Friend_ID),0);
	end

end

function LobbyFriendUI:UpdateSearchList()
    --数据在BP_ARRAY_Plat_Friend_Profile
    LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateSearchPanel");
end

-- 未查找到该好友
function LobbyFriendUI:ShowSearchFailResult()
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "SearchFail");
end
--查找好友相关 end

--添加好友相关 start
--A添加B
BP_Add_Friend_ID = "";
BP_Add_Friend_Verify = "";
BP_Verify_MaxWordCount = 15;
BP_Verify_DefaultWord = "";
function EventLobbyFriendApply_Push()
	local addId = tonumber(BP_Add_Friend_ID);
	if string.len(BP_Add_Friend_Verify) > 0 then
		if tonumber(DataMgr.roleData.uid) ~= addId then
			FriendSystem.add_inner_friend_req(addId, BP_Add_Friend_Verify,BP_ENUM_ADD_FRIEND_FROM_FRIEND_SEARCH);
		else
			DataMgr.ShowNoticeByID(200004);
		end
	else
		if tonumber(DataMgr.roleData.uid) ~= addId then
			FriendSystem.add_inner_friend_req(addId, BP_Verify_DefaultWord,BP_ENUM_ADD_FRIEND_FROM_FRIEND_SEARCH);
		else
			DataMgr.ShowNoticeByID(200004);
		end
	end
end


function LobbyFriendUI:SendPresentCoinSuccess()
	LuaClassObj.HandleUIMessage(bp_lobby_friend,"SendPresentCoinSuccess");
end

function LobbyFriendUI:SendInviteSuccess()
	LuaClassObj.HandleUIMessage(bp_lobby_friend,"SendInviteSuccess");
end



--B回复A是否愿意 op=1，同意；op=0,拒绝；-1 未操作
BP_RSPAdd_Friend_ID = "";
BP_RSPAdd_OP = "";
function EventLobbyFriendRespondApply_Push()
    FriendSystem.add_inner_friend_op_req(tonumber(BP_RSPAdd_Friend_ID), tonumber(BP_RSPAdd_OP));
end
--添加好友相关 end

--申请列表相关 start
function EventLobbyFriendUpdateInvite_Push()
    FriendSystem.get_addfriend_reqlist_req();
end

--后台返回列表，数据在BP_ARRAY_Apply_Friend_Profile
function LobbyFriendUI:UpdateApplyList()
    LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateApplyList");
end

-- 更新申请列表小红点
function LobbyFriendUI:UpdateApplyNewTips()
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateApplyNewTips");
end
--申请列表相关 end

--删除好友相关 start
BP_Delete_Friend_ID = "";
BP_Delete_Friend_Name = "";
function EventLobbyFriendDelete_Push()
	local msg = Client.GetTableData("LocalizeRes",200003);
	if msg then
		local str = string.format(msg.TextValue,BP_Delete_Friend_Name);
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		--CommonMessageBoxUI:ShowPanel(2,"提示",str,DeleteFriend,nil);
		CommonMessageBoxUI:ShowPanel(2,title,str,DeleteFriend,nil);
	end
end

function DeleteFriend()
	FriendSystem.del_inner_friend_req(tonumber(BP_Delete_Friend_ID));
end
--删除好友相关 end

--申请入队
BP_APPLY_TEAM_FRIEND_ID = "";
function EventLobbyFriendApplyEnterTeam_Push()
	TeamUpSystem.team_apply_request(tonumber(BP_APPLY_TEAM_FRIEND_ID));
end

-- 刷新黑名单列表
function LobbyFriendUI:UpdateBlackist()
    LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateBlackList");
end

-- 请求黑名单列表
function EventLobbyFriendBlackList_Push()
	FriendSystem.get_black_list_req();
end

-- 拉黑好友
BP_ADD_FRIEND_BLACK_ID = "";
function EventLobbyFriendAddBlack_Push()
	FriendSystem.add_black_list_req(tonumber(BP_ADD_FRIEND_BLACK_ID));
end
-- 解除屏蔽
BP_DELETE_FRIEND_BLACK_ID = "";
BP_DELETE_FRIEND_BLACK_NAME = "";
function EventLobbyFriendDeleteBlack_Push()
	local msg = Client.GetTableData("LocalizeRes",200011);
	if msg then
		local str = string.format(msg.TextValue,BP_DELETE_FRIEND_BLACK_NAME);
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		--CommonMessageBoxUI:ShowPanel(2,"提示",str,DeleteBlack,nil);
		CommonMessageBoxUI:ShowPanel(2,title,str,DeleteBlack,nil);
	end
end

function DeleteBlack()
	FriendSystem.del_black_list_req(tonumber(BP_DELETE_FRIEND_BLACK_ID));
end

-- 打开好友资料
BP_FRIEND_PROFILE_ID = "";
function EventLobbyFriendProfile_Push()	
	RoleInfoSystem.Enter(BP_FRIEND_PROFILE_ID);
	log("enter profile panel:"..tostring(BP_FRIEND_PROFILE_ID));
	RoleInfoUI.Init();

	ProfileMgr.GetProfile(tostring(BP_FRIEND_PROFILE_ID), LobbyFriendUI.OnFriendStatusListChange, true);
end

function LobbyFriendUI.OnFriendStatusListChange(list)
	log("OnFriendStatusListChange");
	local count = #list;
	if (count > 0) then
		for i = 1,count,1 do
			LobbyFriendUI.OnFriendStatusChange(list[i]);
		end
	end
end

BP_Friend_UpdateInnerIndex = 0;
BP_Friend_UpdatePlatIndex = 0;

function LobbyFriendUI.OnFriendStatusChange(profile)
	if (profile ~= nil and profile.uid ~= nil) then

		local listCount = #BP_ARRAY_Inner_Friend_Profile;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_Inner_Friend_Profile[i];
				if (tostring(profile.uid) == tostring(v.gid)) then
					v = LobbyFriendUI.CopyBaseInfo(v, profile);		
					BP_Friend_UpdateInnerIndex = i - 1;
					log("LobbyFriendUI.OnFriendStatusChange BP_Friend_UpdateInnerIndex = " .. BP_Friend_UpdateInnerIndex);
					LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateInnerOneSync");
				end
			end	
		end
		
		listCount = #BP_ARRAY_Plat_Friend_Profile;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_Plat_Friend_Profile[i];
				if (tostring(profile.uid) == tostring(v.gid)) then
					v = LobbyFriendUI.CopyBaseInfo(v, profile);		
					BP_Friend_UpdatePlatIndex = i - 1;
					log("LobbyFriendUI.OnFriendStatusChange BP_Friend_UpdatePlatIndex = " .. BP_Friend_UpdatePlatIndex);
					LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdatePlatOneSync");
				end
			end	
		end


		listCount = #BP_ARRAY_All_Friend_Profile;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_All_Friend_Profile[i];
				if (tostring(profile.uid) == tostring(v.gid)) then
					v = LobbyFriendUI.CopyBaseInfo(v, profile);		
					BP_ARRAY_All_Friend_Profile[i] = v;
					log("BP_ARRAY_All_Friend_Profile date update ");
				end
			end	
		end

		listCount = #BP_ARRAY_Inner_Friend_Profile;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_Inner_Friend_Profile[i];
				if (tostring(profile.uid) == tostring(v.gid)) then
					v = LobbyFriendUI.CopyBaseInfo(v, profile);		
					BP_ARRAY_Inner_Friend_Profile[i] = v;
					log("BP_ARRAY_Inner_Friend_Profile date update ");
				end
			end	
		end

		listCount = #BP_ARRAY_Plat_Friend_Profile;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_Plat_Friend_Profile[i];
				if (tostring(profile.uid) == tostring(v.gid)) then
					v = LobbyFriendUI.CopyBaseInfo(v, profile);		
					BP_ARRAY_Plat_Friend_Profile[i] = v;
					log("BP_ARRAY_Plat_Friend_Profile date update ");
				end
			end	
		end
	end
end

function LobbyFriendUI.CopyBaseInfo(v, profile)
	v.nickName = profile.nickName
	v.level = profile.level
	v.vipLevel = profile.vipLevel
	v.picUrl = profile.picUrl
	v.platName = profile.platName
	v.sex = profile.sex
	v.lastOnlineTime = profile.lastOnlineTime
	v.lastOnlineTimeStr = FriendSystem.FormatTime(profile.lastOnlineTime,"online")
	v.lastLoginTime = profile.lastLoginTime
	v.exp = profile.exp
    --waynedong todo
    ----------------------------------------intl modify--------------------------------------
    --[[
	v.segment_info_solo = profile.segment_info[1]
	v.segment_info_duo = profile.segment_info[2]
	v.segment_info_squad = profile.segment_info[3]
    ]]
    v.AllSegment_Info = v.segment_info;
    for k, v in pairs(v.AllSegment_Info) do
        v.segment_info_solo   = v.AllSegment_Info[k][1];
        v.segment_info_duo    = v.AllSegment_Info[k][2];
        v.segment_info_squad = v.AllSegment_Info[k][3];
    break;
    end
    v.segment_info_solo,  v.segment_info_duo,  v.segment_info_squad =  FuncUtil.GetMaxSegement( v.AllSegment_Info );
    ----------------------------------------intl modify--------------------------------------
	v.cur_avatar_box_id = profile.cur_avatar_box_id
	return v;
end

-- 打开聊天界面
BP_FRIEND_CHAT_ID = "";
function EventLobbyFriendChat_Push()
	LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIHide");
	LobbyChatSystem.ChatWithFriend(BP_FRIEND_CHAT_ID);
end


-- 邀请QQ或者微信好友
function EventLobbyFriendInvitePlatformFriend_Push()
	--local tips = "结构化分享测试"
	local tips = Client.GetTableData("LocalizeRes", "301293").TextValue;
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		ShareMgr:shareWechat(MEDIA_TAG_SHARE_INVITE, tips, "structshare")
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		ShareMgr:shareQQ(MEDIA_TAG_SHARE_INVITE, tips, ShareType.Friend)
	end
end

-- 获取最近组队队友信息
function EventLobbyFriendGetRecentTeammate_Push()
	FriendSystem.getRecentTeammate()
end

-- 刷新最近组队界面
function LobbyFriendUI:UpdateRecentTeammateList()
    LuaClassObj.HandleUIMessage(bp_lobby_friend, "UpdateRecentTeammateList")
end

--游戏小悦URL和红点
BP_XY_API_URL = "";
BP_XY_API_RedPoint = 0;
function EventXYAPISetUrl()
    local url = "https://xyapi.game.qq.com/xiaoyue/service/redirect?game_id=1279&source=xy_games&login_type=msdk&partition_id=1";
    local plat_id = 0;
    if BP_Platform == BP_ENUM_PLAYFORM_WX then
        plat_id = 2;
    elseif BP_Platform == BP_ENUM_PLAYFORM_QQ then
        plat_id = 1;
    end
    local xyapi = "";--Client.GetXY_API_Url(NetInterface);
    BP_XY_API_URL = string.format("%s%s&plat_id=%d&role_id=%d",url, xyapi, plat_id, BP_PlayerUid);
    log("BP_XY_API_URL:"..BP_XY_API_URL)
end

function EventSetXYAPIShowRedPoint()
    BP_XY_API_RedPoint = 1;
	
		--刷新小悦小红点
	if BP_Is_Show then
		LobbyFriendUI:UpdateInnerList()
		LobbyFriendUI:UpdatePlatList()
	end
end
function EventSetXYAPIHideRedPoint()
    BP_XY_API_RedPoint = 0;
	
		--刷新小悦小红点
	if BP_Is_Show then
		FriendSystem.SortInnerFriendList()
		FriendSystem.SortPlatFriendList()
	
		LobbyFriendUI:UpdateInnerList()
		LobbyFriendUI:UpdatePlatList()
	end
end