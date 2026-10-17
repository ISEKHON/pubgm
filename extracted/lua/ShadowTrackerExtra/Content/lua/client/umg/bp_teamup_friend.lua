--[[
	组队好友UI相关逻辑 by eddygu 2017-11-19	
--]]

TeamUPFriendUI = TeamUPFriendUI or {
	isInit = false;

}

BP_STRUCT_InviteFriendProfile =
{
    gid="",
	nickName = "",
	level = 0,
    picUrl = "",
    vipLevel = 0,
    ladder = 0,
    platName = "",
    sex = 0,
	online = 1, -- 0为离线，1为在线
	showInviteIcon = 0,
    lastOnlineTime = 0,
	teamState = 0, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据
	reserveState = 0,	-- 0 亲密度不足不能预约，1 可预约，2 预约CD中, 3 已预约
	currentTeamAmount = 1, -- 当前队伍人数
	maxTeamAmount = 4, -- 队伍最大可容纳人数
	teamId = 0, -- 队伍id
	timeSinceGameBegin = 0, -- 已开局时间
    op=0, --邀请列表里面的操作
    applyMsg="", --邀请列表里面的留言
	timeSinceGameBeginStr = "", --已开局时间
	intimacy = 0,
	
	segment_info_solo = 0;-- 段位数据
	segment_info_duo = 0;
	segment_info_squad = 0;
	cur_avatar_box_id = 0; --头像框
};


--组队好友列表
BP_ARRAY_Teamuup_Friend_Profile =
{
    BP_STRUCT_InviteFriendProfile = _G.BP_STRUCT_InviteFriendProfile, --定义结构体数组，这种写法要作为规范规定下来
}

--车队列表
BP_ARRAY_CarTeam_Friend = 
{
	BP_STRUCT_InviteFriendProfile = _G.BP_STRUCT_InviteFriendProfile,
}

--最近列表
BP_ARRAY_Recent_Friend = 
{
	BP_STRUCT_InviteFriendProfile = _G.BP_STRUCT_InviteFriendProfile,
}

--UI是否展开
BP_TeamUPFriendIsShow = false;


--是否关闭相关UI,true表示关闭UI
local IsCheckClose = false;

function bp_teamup_friend_RegisterUI()                                                                                                                                     
	LuaClassObj.SubUIWidgetList(bp_teamup_friend,
		{
			{Path="/Game/UMG/UI_Logic/Lobby/Lobby_InviteFriendLogic_BP.Lobby_InviteFriendLogic_BP_C", Container="Default", ZOrder=11},
		},
		{"Lobby"},
		false,
		bp_teamup_friend_OnModeSwitched ~= nil
	);
    
    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_teamup_friend,
            "Lobby_InviteFriendLogic_BP_C",
            {
                "WidgetSwitcher_WXorQQ",
                "Overlay_OfflineShareFather",
            }
        );
    end
end	


function TeamUPFriendUI.Init()
	EventSystem:registEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_STATUS_UI_MATCH, OnHandleUIChange);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, TeamUPFriendUI.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, TeamUPFriendUI.WardRobeAvatarResetClose);
    EventSystem:registEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_UPDATE_MEMBER, TeamUPFriendUI.UpdateCarTeamMember);
	EventSystem:registEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_RECENT_STATE_UPDATE, TeamUPFriendUI.UpdateAllFriendStatus);
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_INVITE_FRIEND, TeamUPFriendUI.ShowUI)
    
	BP_ARRAY_Teamuup_Friend_Profile = FriendSystem.SortFriendList();
	--log_tree("TeamUPFriendUI.Init", BP_ARRAY_Teamuup_Friend_Profile)
	--TeamUPFriendUI.TestData();		
end


function TeamUPFriendUI.Release()
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, TeamUPFriendUI.WardRobeAvatarResetOpen);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, TeamUPFriendUI.WardRobeAvatarResetClose);
    EventSystem:unregistEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_UPDATE_MEMBER, TeamUPFriendUI.UpdateCarTeamMember);
	EventSystem:unregistEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_RECENT_STATE_UPDATE, TeamUPFriendUI.UpdateAllFriendStatus);
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_INVITE_FRIEND, TeamUPFriendUI.ShowUI)
end

function TeamUPFriendUI.ShowUI()
	if not BP_TeamUPFriendIsShow then
	LuaClassObj.HandleUIMessage(bp_teamup_friend, "OnClickBtnFriendList")
	end
end

function TeamUPFriendUI.WardRobeAvatarResetOpen()
    log("TeamUPFriendUI.WardRobeAvatarResetOpen")
		LuaClassObj.HandleUIMessage(bp_teamup_friend, "UIHide");	
end

function TeamUPFriendUI.WardRobeAvatarResetClose()
    log("TeamUPFriendUI.WardRobeAvatarResetClose")
	TeamUPFriendUI.ShowPanel()
end

function TeamUPFriendUI.UpdateCarTeamMember(eventType, eventID, msgType)
	if eventType ~= EVENTTYPE_ALLIANCE then
		return;
	end

	if eventID == EVENTID_ALLIANCE_UPDATE_MEMBER then --车队成员更新
		--log_tree("UpdateCarTeamMember", msgType);	
		--重新取下车队数据
		BP_ARRAY_CarTeam_Friend = AllianceSystem.GetAllianceProfileListWithoutSelf();	

		if BP_TeamUPFriendIsShow == true then
			LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateCarTeamStatus");
		end

	end

end

local function OnHandleUIChange(eventType, eventID, vars)
	log("OnHandleUIChange");
	if eventType ~= EVENTTYPE_TEAMUP then
		return;
	end
	
	if eventID == EVENTID_TEAMUP_STATUS_UI_MATCH then
		log("EVENTID_TEAMUP_STATUS_UI_MATCH");
		if BP_TeamUPFriendIsShow then
			log("EVENTID_TEAMUP_STATUS_UI_MATCH Hide");
			LuaClassObj.HandleUIMessage(bp_teamup_friend, "HideFriendMenu");
		end
	end
end


--资源加载完成
function bp_teamup_friend_OnModeSwitched(gamestatus)
	
	log("OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then		
		
		--拿去好友系统数据
		TeamUPFriendUI.Init();
		
		--默认不显示UI
		log("bp_teamup_friend ShowUI");
		--屏蔽2017年12月10版本
		if IsCheckClose == false then
			LuaClassObj.HandleUIMessage(bp_teamup_friend, "UIShow");	
		end		
	end	

	
	
end

function bp_teamup_friend_OnModeAboutToSwitched (gamestatus)
end


local function RefreshList()
	--打开列表才需要取自己队友数量
	BP_MyPlyerCount = TeamUpSystem.TeamInfo.player_count;
	
	BP_ARRAY_Teamuup_Friend_Profile = FriendSystem.SortFriendList();	
	
	--列表增加或者删除
	LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateFriendList");		
end

function TeamUPFriendUI.ShowPanel()
	--log("TeamUPFriendUI.ShowPanel")
	--屏蔽2017年12月10版本
	if IsCheckClose == false then
		LuaClassObj.HandleUIMessage(bp_teamup_friend, "UIShow");	
	end
	
end

function TeamUPFriendUI.HidePanel()
	--log("TeamUPFriendUI.HidePanel")
	LuaClassObj.HandleUIMessage(bp_teamup_friend, "HideFriendMenu");	
end

--*更新逻辑*--
--拉取、增加、删除好友、逻辑
function TeamUPFriendUI.UpdateFriend()	
	if TeamUPFriendUI.isInit == true then
		RefreshList();
		TeamUpUI.UpdateFriendStatus();		
	end
	--更新好友数量
	TeamUPFriendUI.UpdateOnlineNum();
	
end

--更新好友状态
function TeamUPFriendUI.UpdateAllFriendStatus()		
	--如果这里面板打开才需要更新数据，否则
	if(BP_TeamUPFriendIsShow) then
		--取最新好友所有状态
		BP_ARRAY_Teamuup_Friend_Profile = FriendSystem.SortFriendList();
		BP_ARRAY_Recent_Friend = FriendSystem.SortRecentList();
		
		for k,v in pairs(BP_ARRAY_Teamuup_Friend_Profile) do	
			local str_gid = v.gid;
			
			if v.intimacy == nil then
				log("updateallfriendstatus intimacy is nil")
				v.intimacy = 0
			end
			
			if (v.intimacy >= 100) then	
				local isReserved = LobbyChatSystem.IsReserved(str_gid);				
				if true == isReserved then					
					v.reserveState = 3;
				else					
					local reservingData = LobbyChatSystem.friendReservingList[str_gid];
					if nil ~= reservingData then					
						local thisTime = os.time();								
						if thisTime - reservingData.time >= 60 then
							v.reserveState = 1;							
							LobbyChatSystem.on_clear_reserving(str_gid);
						else
							v.reserveState = 2;
						end
					else					
						v.reserveState = 1;
					end
				end				
			else				
				v.reserveState = 0;
			end
		end	
		--log("UpdateAllFriendStatus");
		--log_tree("UpdateAllFriendStatus new data", BP_ARRAY_Teamuup_Friend_Profile);
		--只刷状态信息
		--LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateAllFriendStausNew");
		--更新页签相关的数据
		LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateByCurrentType");		
		
	end

end

function TeamUPFriendUI.ChangePlayerCount()
	--队伍人员变更，外部调用，重新刷新好友列表,表示可以邀请，或申请入队按钮出现
	BP_MyPlyerCount = TeamUpSystem.TeamInfo.player_count;
	--log("TeamUPFriendUI.ChangePlayerCount BP_MyPlyerCount"..BP_MyPlyerCount);
	TeamUPFriendUI.UpdateAllFriendStatus();	
	
end

--更新在线人数显示
function TeamUPFriendUI.UpdateOnlineNum()
	--取最新好友所有状态
	log("TeamUPFriendUI.UpdateOnlineNum");
	BP_ARRAY_Teamuup_Friend_Profile = FriendSystem.SortFriendList();
	--log_tree("TeamUPFriendUI.UpdateOnlineNum", BP_ARRAY_Teamuup_Friend_Profile);
	LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateOnLineNum");	
	if(BP_TeamUPFriendIsShow) then
		--log("TeamUPFriendUI.UpdateOnlineNum BP_TeamUPFriendIsShow true");	
		TeamUPFriendUI.UpdateAllFriendStatus();
	end
end


function TeamUPFriendUI.CheckSwitch()
	log("==================checkSWitch")
	if IsCheckClose == true then
		IsCheckClose = false;
		LuaClassObj.HandleUIMessage(bp_teamup_friend, "UIShow");
	end
end

--从战斗回到大厅，或者切换账号清空相关数据
function TeamUPFriendUI.OnLogOut()
	IsCheckClose = false;
	TeamUPFriendUI.isInit = false;
	BP_MyPlyerCount = 0;

end

function TeamUPFriendUI.OnFriendReserved(str_gid)
	TeamUPFriendUI.UpdateAllFriendStatus();
end


--************************************************蓝图交互逻辑**********************************--
--蓝图取最新lua数据
function EventFetchTeamupFriendInfo()
end

--lua取最新蓝图的修改过得变量
function EventSetInfo_Push()

end

--打开列表，关闭时候回调
function EventShowListCallBack()

	if(BP_TeamUPFriendIsShow) then
		
		--FriendSystem.getFriendIDList()
		--打开 发请求告诉后台实时拉取状态
		TeamUpSystem.recv_stau_request(true);
		--同步下最新状态
		FriendSystem.batchGetTeamInfoList();
		TeamUpUI.HidePanel();		
		--打开好友重新拉取最新数据
		--FriendSystem.getFriendIDList();	
			
		log("EventShowListCallBack true");		

		LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateOnLineNum");	
		--设置最近队友数据
		BP_ARRAY_Recent_Friend = FriendSystem.SortRecentList();
		local idlist = {};
		for i = 1,#BP_ARRAY_Recent_Friend,1 do
			table.insert(idlist, BP_ARRAY_Recent_Friend[i].gid);
		end
		if #idlist > 0 then
			NetUtil.SendPkg("batch_get_group_and_online_req", "recentteammate", idlist);
		end
	
        --设置车队数据
		BP_ARRAY_CarTeam_Friend = AllianceSystem.GetAllianceProfileListWithoutSelf();
		--log_tree("EventShowListCallBack BP_ARRAY_CarTeam_Friend",BP_ARRAY_CarTeam_Friend);
		
		FriendSystem.CheckFetchFriendList();
	else		
		TeamUpUI.ShowPanel();
		TeamUpSystem.recv_stau_request(false);
		log("EventShowListCallBack false");		
	end


	--第一次打开
	if TeamUPFriendUI.isInit == false then
		--第一次打开重新拉取列表
		TeamUPFriendUI.isInit = true;
		TeamUPFriendUI.UpdateFriend();
		return;
	end
		
	if(BP_TeamUPFriendIsShow) then		
		--打开好友重新拉取下最新状态
		TeamUPFriendUI.UpdateAllFriendStatus();
	end

	
end

--邀请好友的ID
BP_InviteFriendID = "";
BP_InviteFriendName = "";

--自己队伍人数，用于（双方都是≥2人队伍，不能邀请或者加入，不显示邀请或加入按钮。）
BP_MyPlyerCount = 0;
-- 0 亲密度不足不能预约，1 可预约，2 预约CD中, 3 已预约
BP_ReservationState = 0;

--点击邀请好友按钮
function EventClickInviteFriendBtn()
	local isMatch = TeamUpUI.IsMatching();
	if isMatch then
		log("EventClickInviteFriendBtn isMatch:");
		--DataMgr.ShowNoticeByString("匹配中，无法邀请或者加入队伍");
		DataMgr.ShowNoticeByID(110122);		
		return;
	end	
	--log_tree("OnClickMeta", BP_ARRAY_Teamuup_Friend_Profile);	
	log("EventClickInviteFriendBtn GID:"..tonumber(BP_InviteFriendID));
	TeamUpSystem.team_invite_request(tonumber(BP_InviteFriendID));
end	

--点击申请组队
function EventClickJoinBtn()
	local isMatch = TeamUpUI.IsMatching();
	if isMatch then
		log("EventClickInviteFriendBtn isMatch:");
		--DataMgr.ShowNoticeByString("匹配中，无法邀请或者加入队伍");
		DataMgr.ShowNoticeByID(110122);	
		return;
	end
	--log_tree("OnClickMeta", BP_ARRAY_Teamuup_Friend_Profile);
	log("EventClickJoinBtn GID:"..tonumber(BP_InviteFriendID));	
	TeamUpSystem.team_apply_request(tonumber(BP_InviteFriendID));
end

--点击跳转好友列表按钮
function EventClickAddFriendBtn()
	--TeamUPFriendUI.TestOneData("10000002");
	--LobbyFriendUI:Jump(); 
	
	log("friend list open");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_FRIEND) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    LobbyFriendUI:Init();
    LobbyFriendUI:Show();
end

--点击邀请上线
function EventClickOfflineShare()
	local function confirmClick()
		FriendSystem.get_openid_by_nickname_req(BP_InviteFriendName, "offlineInvite");
	end
	CommonMessageBoxUI:ShowPanel(2, "提示", string.format("是否邀请好友%s上线？", BP_InviteFriendName), confirmClick, nil);
end

--点击预约
function EventClickReserveFriend()
	LobbyChatSystem.on_reserve_friend_req(BP_InviteFriendID);
	
	local friendData = FriendSystem.GetFriendDataByGID(BP_InviteFriendID);
	if nil ~= friendData then
		PopUpNoticeUI.ShowNewNotice(string.format(DataMgr.GetMsgByID(110123), friendData.nickName));
	end	
end
--查询预约状态
function EventCheckReservationState()
	if BP_TeamUPFriendIsShow == true then
		TeamUPFriendUI.UpdateAllFriendStatus();	
	end	
end

--点击头像设置的GID
BP_FriendHeadClickGid = "";
function EventClickHeadBtn()
	RoleInfoSystem.Enter(BP_FriendHeadClickGid);
	log("bp_teamup_friend enter profile panel:"..tostring(BP_FriendHeadClickGid));
	RoleInfoUI.Init();
end

function EventClickPlatformInvite()
	TeamUpSystem.WXPlatformInviteType = 0;
	TeamUpSystem.get_teamid_for_plat_request();
end

-- 微信小程序
function EventClickPlatformInviteWXMiniApp()
	log("EventClickPlatformInviteWXMiniApp");
	TeamUpSystem.WXPlatformInviteType = 1;
	TeamUpSystem.get_teamid_for_plat_request();
end

function EventSwitchFriend( )
	log("TeamUpFriendUIEventSwitchFriend")
end

function EventSwitchRecent( )
	log("TeamUpFriendUIEventSwitchRecent")
	--设置最近队友数据
	BP_ARRAY_Recent_Friend = FriendSystem.SortRecentList();
	local idlist = {};
	for i = 1,#BP_ARRAY_Recent_Friend,1 do
		table.insert(idlist, BP_ARRAY_Recent_Friend[i].gid);
	end
	if #idlist > 0 then
		NetUtil.SendPkg("batch_get_group_and_online_req", "recentteammate", idlist);
	end
end

function EventSwitchCarTeam( )
	log("TeamUpFriendUIEventSwitchCarTeam")
end

function TeamUPFriendUI.TestOneData(uid)
	for k,v in pairs(BP_ARRAY_Teamuup_Friend_Profile) do
		log("uid:aaaaaaaa"..uid);
		log("v.gid:aaaaaaaa"..v.gid);
		--log("aaaaaaa"..tostring(uid == v.gid));
		if tostring(uid) == tostring(v.gid) then	
			v.currentTeamAmount = 4;
			v.maxTeamAmount = 4;
			v.nickName = "adfadf";		
			v.teamState = 1;
			v.level = 100;
			break;
		end		
	
	end
	--log_tree("TeamUPFriendUI.TestOneData", BP_ARRAY_Teamuup_Friend_Profile);
	LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateAllFriendStausNew");
end

function TeamUPFriendUI.TestData()
	if #BP_ARRAY_Teamuup_Friend_Profile > 1 then
		--return;
	end
	BP_ARRAY_Recent_Friend = {};
	local testData = 
	{
		gid="10000002",
		nickName = "jack老师假",		
		level = 10,
		online = 1,
		teamState = 2, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
		currentTeamAmount = 1, -- 当前队伍人数
		maxTeamAmount = 2, -- 队伍最大可容纳人数
		timeSinceGameBegin = 400,
	}
	
	local testData1 = 
	{
		gid="10000006",
		nickName = "小古假",
		level = 100,
		online = 1,
		teamState = 2, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
		currentTeamAmount = 1, -- 当前队伍人数
		maxTeamAmount = 4, -- 队伍最大可容纳人数
		timeSinceGameBegin = 59,
	}
	
	local testData2 = 
	{
		gid="10000007",
		nickName = "jack老师组队中假",
		level = 200,
		online = 1,
		teamState = 2, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
		currentTeamAmount = 1, -- 当前队伍人数
		maxTeamAmount = 4, -- 队伍最大可容纳人数
		timeSinceGameBegin = 0,
	}
	
	local testData3 = 
	{
		gid="10000003",
		nickName = "fourth假",
		level = 300,
		online = 1,
		teamState = 2, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
		currentTeamAmount = 3, -- 当前队伍人数
		maxTeamAmount = 4, -- 队伍最大可容纳人数
		timeSinceGameBegin = 12000,
	}
	
	local testData4 = 
	{
		gid="10000004",
		nickName = "amy假",
		level = 400,
		online = 0,
		teamState = 2, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
		currentTeamAmount = 3, -- 当前队伍人数
		maxTeamAmount = 4, -- 队伍最大可容纳人数
		timeSinceGameBegin = 120000,
	}
	table.insert(BP_ARRAY_CarTeam_Friend, testData);
	--table.insert(BP_ARRAY_CarTeam_Friend, testData1);
	--table.insert(BP_ARRAY_CarTeam_Friend, testData2);
	--table.insert(BP_ARRAY_CarTeam_Friend, testData3);
	--table.insert(BP_ARRAY_CarTeam_Friend, testData4);

	table.insert(BP_ARRAY_Recent_Friend, testData);
	table.insert(BP_ARRAY_Recent_Friend, testData1);
	

	--LuaClassObj.HandleUIMessage(bp_teamup_friend, "UpdateRecentList");	
end
