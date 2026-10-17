--[[
	车队招募与申请列表
--]]

 AllianceRecruitUI = AllianceRecruitUI or {

 	--离线tips的当前显示UID
 	CurrentOffmsg = {},

 	--前台存储已发送列表
 	HasInviteList = {},

}
-- 招募成员、申请列表相关数据结构
BP_STRUCT_AllianceRecruit =
{
    gid="",
	nickName = "",
	level = 0,
	militaryRank = "";
    picUrl = "",
    vipLevel = 0,
    ladder = 0,-- 天梯
    platName = "",
    sex = 0,
    lastOnlineTime = 0,
	lastOnlineTimeStr = "";
	lastLoginTime = 0;
	exp = 0;
	segment_info_solo = 0;-- 段位数据
	segment_info_duo = 0;
	segment_info_squad = 0;
	
	friendType = 0;-- 好友类型（平台1、游戏内0） 
	
    applyMsg="", --好友申请里的留言
	createTime = 0,--好友申请的发送时间
	createTimeStr = "";
	
	online = 1, -- 0为离线，1为在线
		
	teamState = 0, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
	currentTeamAmount = 1, -- 当前队伍人数
	maxTeamAmount = 4, -- 队伍最大可容纳人数
	teamId = 0, -- 队伍id
	timeSinceGameBegin = 0, -- 已开局时间
	timeSinceGameBeginStr = "",
	cur_avatar_box_id = 0, --头像框

	---招募独有字段
	hasSendInvite = false,

};

-- 招募成员列表
BP_ARRAY_Alliance_RecruitList =
{
	BP_STRUCT_AllianceRecruit = _G.BP_STRUCT_AllianceRecruit;
}

-- 申请列表
BP_ARRAY_Alliance_ApplyList =
{
	BP_STRUCT_AllianceRecruit =  _G.BP_STRUCT_AllianceRecruit;
}

--面板是否打开
BP_AllianceRecruit_IsShow = false;

--0：招募面板， 1：申请面板
BP_AllianceRecruit_CurType = 0;

--好友数量23/45
BP_AllianceFriendNumStr = "";

--招募邀请的ID
BP_AllianceRecruit_InviterGid = "";

--申请列表拒绝同意gid
BP_AllianceApply_Gid = "";

--红点
BP_AllianceRecruitReadPoint = false;

--是否队长
BP_AllianceRecruitLeader = false;

function bp_alliance_recruit_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_alliance_recruit,
		{	
			{Path="/Game/UMG/UI_Logic/Lobby_Team/LobbyTeam_LogicRecruitBP.LobbyTeam_LogicRecruitBP_C", Container="Default", ZOrder=BP_ENUM_UI_Alliance_Recruit},

		},
		{"Lobby"},
		false,		
		bp_alliance_recruit_OnModeSwitched ~= nil,
		true
	);
end	

function bp_alliance_recruit_OnModeSwitched(gamestatus)
	log("OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
       	AllianceRecruitUI.AddRegistUIEvent();
       	--发送离线消息,1表示车队
        AllianceSystem.SendAllOffMsgReq(1);
	end
end

function bp_alliance_recruit_OnModeAboutToSwitched()

end

--事件监听注册
local function OnAlianceRecruitEventHandler(eventType, eventID, dataVar)
	if eventType ~= EVENTTYPE_ALLIANCE then
		return;
	end

	if eventID == EVENTID_ALLIANCE_RECRUIT_APPLIST then --邀请列表取到概要信息返回
		--log_tree("OnAlianceRecruitEventHandler", dataVar);

		BP_ARRAY_Alliance_ApplyList = {};
		for k,v in pairs(dataVar) do  

	        local profileData = {};
	        profileData.gid = tostring(math.floor(v.uid));
	        profileData.picUrl = v.picUrl;
	        profileData.nickName = v.nickName;
	        profileData.sex = v.sex;     
	        profileData.level = v.level;
            --waynedong todo 
            ----------------------------------------intl modify--------------------------------------
            --[[
	        profileData.segment_info_solo = v.segment_info[1];
	        profileData.segment_info_duo = v.segment_info[2];
	        profileData.segment_info_squad = v.segment_info[3];
            ]]
            profileData.AllSegment_Info = v.segment_info;
            for kseg, vseg in pairs(profileData.AllSegment_Info) do
               profileData.segment_info_solo   = profileData.AllSegment_Info[kseg][1];
               profileData.segment_info_duo    = profileData.AllSegment_Info[kseg][2];
               profileData.segment_info_squad = profileData.AllSegment_Info[kseg][3];
               break;
            end
            profileData.segment_info_solo,  profileData.segment_info_duo,  profileData.segment_info_squad =  FuncUtil.GetMaxSegement( profileData.AllSegment_Info );
            ----------------------------------------intl modify--------------------------------------
	        profileData.cur_avatar_box_id = v.cur_avatar_box_id;
	        --profileData.segmentMax = math.max(profileData.segmentSolo, profileData.segmentDuo, profileData.segmentSquad);
	        table.insert(BP_ARRAY_Alliance_ApplyList, profileData);  
    	end 
	end

	--TODO更新UI
	if BP_AllianceRecruit_CurType == 1 then
		AllianceRecruitUI.UpdateApplyList();		
	end
end

--注册事件
function AllianceRecruitUI.AddRegistUIEvent()
	--注册事件 TODO
	EventSystem:registEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_RECRUIT_APPLIST, OnAlianceRecruitEventHandler);
end

--删除事件
function AllianceRecruitUI.RemoveUIEvent()
	EventSystem:unregistEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_RECRUIT_APPLIST, OnAlianceRecruitEventHandler);
end


local function hasSend(uid)
	local result = false;
	local localUID = tonumber(uid);
	for k,v in pairs(AllianceRecruitUI.HasInviteList) do
		if localUID == v then
			result = true;
			--log("dddddddddddd"..localUID);
			break;
		end
	end
	return result;
end


function AllianceRecruitUI.InitData()
	-- body
	--构造招募数据,好友数量	
	--BP_ARRAY_Alliance_RecruitList = {};
	BP_ARRAY_Alliance_RecruitList = FriendSystem.SortFriendList();	

	--过滤队员的列表
	for i = #BP_ARRAY_Alliance_RecruitList,1,-1 do
		local  isMember = AllianceSystem.IsAllianceMember(BP_ARRAY_Alliance_RecruitList[i].gid);
		if isMember == true then
			table.remove(BP_ARRAY_Alliance_RecruitList,i);
		end		
	end


	BP_AllianceRecruitLeader = AllianceSystem.IsLeader();
	local onlineNum  = 0;
	for k,v in pairs(BP_ARRAY_Alliance_RecruitList) do
		if v.online == 1 then
			onlineNum = onlineNum + 1;
		end
		--是否显示已发送
		BP_ARRAY_Alliance_RecruitList[k].hasSendInvite = hasSend(v.gid);	
	end
	--log_tree("AllianceRecruitUI",BP_ARRAY_Alliance_RecruitList);
	BP_AllianceFriendNumStr = "("..tostring(onlineNum).."/"..tostring(#BP_ARRAY_Alliance_RecruitList) ..")";
end

--打开招募UI
function AllianceRecruitUI.ShowUIRecruit()
	--招募拉取好友，走好友2分钟后强制拉取最新的概要
	FriendSystem.CheckFetchFriendList();

	LuaClassObj.HandleDynamicCreation(bp_alliance_recruit);
	--重新打开UI清空列表
	AllianceRecruitUI.HasInviteList = {};
	BP_AllianceRecruit_IsShow = true;
	--取好友数据
	AllianceRecruitUI.InitData();
	LuaClassObj.HandleUIMessage(bp_alliance_recruit, "ShowUIRecruit");
end

function AllianceRecruitUI.CloseUI()
	LuaClassObj.HandleUIMessage(bp_alliance_recruit, "UIHide");
end

function AllianceRecruitUI.HasSendInvite(uid)
	table.insert(AllianceRecruitUI.HasInviteList,uid);

	for k,v in pairs(BP_ARRAY_Alliance_RecruitList) do
		--是否显示已发送		
		BP_ARRAY_Alliance_RecruitList[k].hasSendInvite = hasSend(v.gid);	
		--log_tree("BP_ARRAY_Alliance_RecruitList",BP_ARRAY_Alliance_RecruitList[k]);
	end
	--更新列表
	LuaClassObj.HandleUIMessage(bp_alliance_recruit, "UpdateRecruitListInvite");
end


--打开申请列表UI
function AllianceRecruitUI.ShowUIApplist()
	--- 请求申请列表数据，拉取申请列表ID，返回后直接拉取概要信息，回调更新UI
	AllianceSystem.SendGetApplyListReq();
	--显示申请UI
	LuaClassObj.HandleUIMessage(bp_alliance_recruit, "ShowUIApplist");
end

--请求概要信息回来后显示更新UI
function AllianceRecruitUI.UpdateApplyList(isemty)
	log("AllianceRecruitUIUpdateApplyList"..tostring(isemty));
	if isemty ~= nil and isemty == true then
		log("AllianceRecruitUIUpdateApplyList isemty");
		BP_ARRAY_Alliance_ApplyList = {};
	end

	--UI打开才更新
	if BP_AllianceRecruit_IsShow == true then
		LuaClassObj.HandleUIMessage(bp_alliance_recruit, "UpdateApplyListUI");
	end	
end

--队长接受拒绝
function AllianceRecruitUI.RemoveApplyList(uid)
	for k,v in pairs(BP_ARRAY_Alliance_ApplyList) do
		if tostring(uid) == v.gid then
			table.remove(BP_ARRAY_Alliance_ApplyList,k);
		end
	end
	AllianceRecruitUI.UpdateApplyList();

	--更新小红点
	AllianceRecruitUI.UpdateRepoint(#BP_ARRAY_Alliance_ApplyList);
end


function AllianceRecruitUI.OnClickOkCallBack()
		-- 接受邀请			
	local teamid = AllianceRecruitUI.CurrentOffmsg.msg.team_id;
	local fromuid = AllianceRecruitUI.CurrentOffmsg.msg.from_uid;
	local offmsgid = AllianceRecruitUI.CurrentOffmsg.index;

	--log_tree("clickOkCallback",AllianceRecruitUI.CurrentOffmsg);
	AllianceSystem.SendAcceptJoinReq(teamid, fromuid, offmsgid, true);
	AllianceSystem.RemoveOffMsgInfoByIndex(offmsgid);
	AllianceRecruitUI.CurrentOffmsg = {};
	--AllianceRecruitUI.PopQueueMsgInfoTips();
end

function AllianceRecruitUI.OnClickCancelCallBack()
	-- 拒绝
	local teamid = AllianceRecruitUI.CurrentOffmsg.msg.team_id;
	local fromuid = AllianceRecruitUI.CurrentOffmsg.msg.from_uid;
	local offmsgid = AllianceRecruitUI.CurrentOffmsg.index;
	--log_tree("clickCancelCallback",AllianceRecruitUI.CurrentOffmsg);

	AllianceSystem.SendAcceptJoinReq(teamid, fromuid, offmsgid, false);
	AllianceSystem.RemoveOffMsgInfoByIndex(offmsgid);
	AllianceRecruitUI.CurrentOffmsg = {};
	--AllianceRecruitUI.PopQueueMsgInfoTips();
end

function AllianceRecruitUI.GetPopNickNameBack(profile_list)  
	--log_tree("getNickNameBack",profile_list);      		
 	local friendName = DataMgr.GetMsgByID(117032);--"陌生人";        		
	if #profile_list ~= 0 then
		 friendName = profile_list[1].nickName;
	end

   -- local friendData = FriendSystem.GetFriendDataByGID(AllianceRecruitUI.CurrentOffmsg.msg.from_uid);
    --log_tree("friendDataddddddddd",friendData);
    --if(friendData ~= nil) then
     --   friendName = friendData.nickName;
    --end	

    local tipstr = DataMgr.GetMsgByID(117033);-- "<MessageProductColor>%s</>邀请你加入<MessageProductColor>%s</>小分队，你同意吗？";
    local contentStr = string.format(tipstr, friendName, AllianceRecruitUI.CurrentOffmsg.msg.team_name);
    CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(117034), contentStr, AllianceRecruitUI.OnClickOkCallBack, AllianceRecruitUI.OnClickCancelCallBack, DataMgr.GetMsgByID(117035),DataMgr.GetMsgByID(117036));	

end

--弹出离线消息
function AllianceRecruitUI.PopQueueMsgInfoTips()
	--CurrentOffmsg
	--[[
		offmsg:
		index:  	索引
		uid:		uid
		type:	1 车队消息
		sendtime: 	时间
		msg:		消息
		op	  1 邀请; 2 通知审核完加入
		team_id   车队ID
		team_name 车队名称
		from_uid  邀请人uid
	]]
	local find = false;
	for k,v in pairs(AllianceSystem.OffMsgInfo) do
		AllianceRecruitUI.CurrentOffmsg = v;
		find = true; 
		break;
	end

	if find == true then
		
        if AllianceRecruitUI.CurrentOffmsg.msg.op == 1 then
        	--log_tree("AllianceRecruitUI.CurrentOffmsg",AllianceRecruitUI.CurrentOffmsg);
			ProfileMgr.GetProfile(AllianceRecruitUI.CurrentOffmsg.msg.from_uid, AllianceRecruitUI.GetPopNickNameBack, true);

        elseif AllianceRecruitUI.CurrentOffmsg.msg.op == 2 then
        	--恭喜加入XXX战队
            AllianceUI.ProtocolErroCode("cline_JoinCarTeam",AllianceRecruitUI.CurrentOffmsg.msg.team_name);
			--加入战队(1表示战队离线消息)后同步下离线消息，因为后台会清离线消息，前台有可能还会有。。所以.
        	AllianceSystem.SendAllOffMsgReq(1);
        end
    
	end
	

end

--更新小红点
function AllianceRecruitUI.UpdateRepoint(listNum)
	--大厅车队按钮
	--车队界面
	--招募界面
	BP_AllianceRecruitLeader = AllianceSystem.IsLeader();
	if tonumber(listNum) > 0 then
		BP_AllianceRecruitReadPoint = true;
		--显示小红点 TODO
	else
		--关闭小红点 TOD
		BP_AllianceRecruitReadPoint = false;
	end
	--更新大厅和车队界面
	AllianceUI:RedPointStatusUpdate(BP_AllianceRecruitReadPoint);	
	if BP_AllianceRecruit_IsShow == true then
		LuaClassObj.HandleUIMessage(bp_alliance_recruit,"UpdateBPRepoint");
	end
end


function EventAllianceRecruit_Push()
	--蓝图变量同步给lua
end

function EventAllianceRecruitFetchInfo()
	--lua变量同步蓝图
end

--点击申请按钮回调，发送请求
function EventShowApplyList()	
	 AllianceRecruitUI.ShowUIApplist();
	 --test
	 --BP_ARRAY_Alliance_ApplyList = BP_ARRAY_Alliance_RecruitList;
	 --AllianceRecruitUI.UpdateApplyList()
end

--关闭UI回调
function EventHideUI()
	BP_AllianceRecruit_IsShow = false;
end

--点击招募按钮
function EventClickRecruit()
	-- body
	if BP_AllianceRecruit_InviterGid ~= "" then
		AllianceSystem.SendInviteCarTeamReq(BP_AllianceRecruit_InviterGid);
	end
end

--点击申请列表，同意
function EventClickApplyAgree()
	-- body
	if BP_AllianceApply_Gid ~= "" then
		 AllianceSystem.SendApproveReq(BP_AllianceApply_Gid, true);
	end
end

--点击申请列表，拒绝
function EventClickApplyRefuse()
	-- body
	if BP_AllianceApply_Gid ~= "" then
		 AllianceSystem.SendApproveReq(BP_AllianceApply_Gid, false);
	end
end


BP_Alliance_UpdateInnerIndex = 0;
function AllianceRecruitUI.OnRecruitItemChange(list)
	log("AllianceRecruitUIOnRecruitItemChange");
	local listCount = #list;
	if listCount > 0 then
		local profile = list[1];
		for i=1, #BP_ARRAY_Alliance_RecruitList do
			local v = BP_ARRAY_Alliance_RecruitList[i];
			if tostring(profile.uid) == tostring(v.gid) then
				v = AllianceRecruitUI.CopyBaseInfo(v, profile);
				BP_Alliance_UpdateInnerIndex = i-1;
				log("AllianceRecruitUI.OnRecruitItemChange BP_Alliance_UpdateInnerIndex = " .. BP_Alliance_UpdateInnerIndex);
				LuaClassObj.HandleUIMessage(bp_alliance_recruit, "UpdateRecruitOneSync");
			end
		end
	end
	
end

function AllianceRecruitUI.OnApplyItemChange(list)
	log("AllianceRecruitUIOnApplyItemChange");
	local listCount = #list;
	if listCount > 0 then
		local profile = list[1];
		for i=1, #BP_ARRAY_Alliance_ApplyList do
			local v = BP_ARRAY_Alliance_ApplyList[i];
			if tostring(profile.uid) == tostring(v.gid) then
				v = AllianceRecruitUI.CopyBaseInfo(v, profile);
				BP_Alliance_UpdateInnerIndex = i-1;
				log("AllianceRecruitUI.OnApplyItemChange BP_Alliance_UpdateInnerIndex = " .. BP_Alliance_UpdateInnerIndex);
				LuaClassObj.HandleUIMessage(bp_alliance_recruit, "UpdateApplyOneSync");
			end
		end
	end
end

function AllianceRecruitUI.CopyBaseInfo(v, profile)	    
	v.nickName = profile.nickName;
	v.level = profile.level;
	v.vipLevel = profile.vipLevel;
	v.picUrl = profile.picUrl;
	v.platName = profile.platName;
	v.sex = profile.sex;

	v.segment_info_solo = profile.segment_info[1];
	v.segment_info_duo = profile.segment_info[2];
	v.segment_info_squad = profile.segment_info[3];
	v.cur_avatar_box_id = profile.cur_avatar_box_id;
	return v;
end


--点击招募列表头像
function EventClickHeadRecruit()
	RoleInfoSystem.Enter(BP_AllianceRecruit_InviterGid);
	log("enter profile panel:"..tostring(BP_AllianceRecruit_InviterGid));
	RoleInfoUI.Init();

	ProfileMgr.GetProfile(tostring(BP_AllianceRecruit_InviterGid), AllianceRecruitUI.OnRecruitItemChange, true);
end

--点击申请列表头像
function EventClickHeadApply()
	RoleInfoSystem.Enter(BP_AllianceApply_Gid);
	log("enter profile panel:"..tostring(BP_AllianceApply_Gid));
	RoleInfoUI.Init();

	ProfileMgr.GetProfile(tostring(BP_AllianceApply_Gid), AllianceRecruitUI.OnApplyItemChange, true);
end

