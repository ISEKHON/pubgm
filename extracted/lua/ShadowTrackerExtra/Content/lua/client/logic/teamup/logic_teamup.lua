
--https://docs.google.com/spreadsheets/d/1wAtt7xOlIcX3dpuM7UbbS0Wr9dwEVKxwRsfUHbcNws8/edit#gid=993147048
--[[
 组队相关逻辑
]]--

local AUTO_REFUSE_TIME_OUT = 300;
local APPLY_INVITE_SHOW_TIME = 5;

TeamUpSystem = TeamUpSystem or
{
	--暂时没有地方取自己的uid
	--这个地方处理一下
	MyUserID = 0,
	TeamInfo = {},	
	--[[
	 TeamInfo
		├─ members
		│  └─ 382236358
		│     ├─ name: "吃鹅ebrcx"
		│     └─ svr: 17039369		
				team.member[uid].carteam_name，为nil时无战队
		│  └─ 38223623123
		│     ├─ name: "吃鹅2ebrcx"
		│     └─ svr: 17039369
		├─ team_type: 4
		├─ id: 6488841903671345157
		├─ create_time: 1510841388
		├─ player_count: 0
		└─ leader: 382236358
	]]--
	--邀请者ID
	Inviter = 0,
	InviterTeamID = 0,
	--申请入队者ID
	ApplyerID = 0,
	ApplyerTeamID = 0,
	
	--是否增加成员
	IsAddMember = true,
	ChangeMemberInfo = {},	
		
	--队员换装广播数据存储
	ChangeWearInfo = {},		
	AutoRefuseInviterMap  = {},
	AutoRefuseApplyerMap = {},
	
	--存储聊天相关人的状态,在线，离线，组队状态，游戏状态
	PlayerStatu = {},
	--组队限时开放
	ModeShields = {},
	InviteApplyQueue = {},
	InviteApplyShowing = false,
	InviteApplyShowType = 0,
	InviteApplyShowTime = 0,

	--队友捏脸换性别
	ChangeAvatarInfo = {},

	WXPlatformInviteType = 0, -- 0结构化，1小程序

  ChooseZoneList = {},

  ChooseZoneId = 0,

}

---自己是否是队长
function TeamUpSystem.IsTeamLeader()		
	local result  = true;
	if TeamUpSystem.TeamInfo ~= nil and  TeamUpSystem.MyUserID ~= nil and TeamUpSystem.TeamInfo.leader ~= nil then		
		if TeamUpSystem.MyUserID ~= TeamUpSystem.TeamInfo.leader then
			result = false;
		end
	end
	
	return result;
	--return TeamUpSystem.TeamInfo ~= nil and TeamUpSystem.MyUserID == TeamUpSystem.TeamInfo.leader;	
end

--获取非队长状态下是否已准备--
function TeamUpSystem.GetMyStatus()
	if TeamUpSystem.TeamInfo ~= nil then
		local myInfo = TeamUpSystem.GetMemberInfo(TeamUpSystem.MyUserID);
		if myInfo ~= nil then
			return myInfo.status;
		end
	end
	
	return 1;	--如果没有队伍信息，默认是准备--
end

--获取是否所有玩家已准备
function TeamUpSystem.IsEverybodyReady()
	--队伍只有一个人的时候无需判断准备的条件
	if TeamUpSystem.TeamInfo.player_count ~= nil then
		if TeamUpSystem.TeamInfo.player_count == 1 then
			return true;
		end
	end

	for key, value in pairs (TeamUpSystem.TeamInfo.members) do
		if (TeamUpSystem.TeamInfo.members[key].status ~= 1) and (key ~= TeamUpSystem.TeamInfo.leader) then
			return false;
		end
	end
	return true;
end

--获取默认模式ID
function TeamUpSystem.GetDefaultRoomMode()
	for key, value in pairs(BP_ARRAY_MatchModeTable) do  
		if BP_ARRAY_MatchModeTable[key].DefaultChosen == 1 then
			return BP_ARRAY_MatchModeTable[key].ID;
		end
	end 
end

--[[
	   ret
	   ├─ svr: 17039369
	   ├─ name: "吃鹅hbyyi"
	   └─ status: 1
]]

--获取成员信息
function TeamUpSystem.GetMemberInfo(userid)
	return TeamUpSystem.TeamInfo.members[tonumber(userid)];
end

function TeamUpSystem.GetMemberName(userid)
	--优先取队伍中的成员名字，然后再从好友中取名字
	local userinfo = TeamUpSystem.GetMemberInfo(userid);
	if (userinfo == nil) then

		local friendData = FriendSystem.GetFriendDataByGID(userid);
		if(friendData == nil) then
			return "";
		end			

		return friendData.nickName;			

	else
		return userinfo.name;
	end
end

function TeamUpSystem.Enter()
	log("TeamUpSystem enter"); 
	TeamUpSystem.query_myid_request();
	--TeamUpSystem.team_info_request();
end

--更新聊天菜单信息
function TeamUpSystem.UpdateMenuForChat()
	log("TeamUpSystem.UpdateMenuForChat");
	if nil ~= TeamUpSystem.PlayerStatu.teamState then	
		LobbyChatLogic.UpdateTeamupMenu(TeamUpSystem.PlayerStatu.teamState, TeamUpSystem.PlayerStatu.online);
	end
end

--取状态
function TeamUpSystem.GetStatuByUID(uid)
	--[[
	teamState=teamState,						// 0 空闲 1 组队中 2 游戏中
	teamId=teamId, 								// 队伍ID
	currentTeamAmount=currentTeamAmount,		// 队伍当前人数
	maxTeamAmount=maxTeamAmount, 				// 队伍最大人数
	timeSinceGameBegin=timeSinceGameBegin, 		// 游戏开局了多久(单位秒)
	online=online  								// 0 不在线  1 在线
	--]]
	local result = nil;
	for key,v in pairs(TeamUpSystem.PlayerStatu) do
		
		if key == uid then
			result = v;
			break;
		end
	
	end	
	return result;
end

--队员语音房间信息
function TeamUpSystem.UpdateVoiceInfo(uid, voiceinfo)
	local memberinfo = TeamUpSystem.GetMemberInfo(uid);
	if memberinfo == nil then
		log("TeamUpSystem.UpdateVoiceInfo memberinfo is none");
		return;
	end
	--member.voice={voice_uid=voice_uid, voice_open=voice_open}
	TeamUpSystem.TeamInfo.members[uid].voice = voiceinfo;
	--voice_info = {uid=uid, voice={voice_uid=voice_uid, voice_open=voice_open}};
end

--队员战队名字
function TeamUpSystem.UpdateCarteamName(uid, carteam_name)
	local memberinfo = TeamUpSystem.GetMemberInfo(uid);
	if memberinfo == nil then
		log("TeamUpSystem.UpdateCarteamName memberinfo is none");
		return;
	end
	TeamUpSystem.TeamInfo.members[uid].carteam_name = carteam_name;
	log("TeamUpSystem.UpdateCarteamName carteam_name:"..tostring(TeamUpSystem.TeamInfo.members[uid].carteam_name));
end

--队员战队名字
function TeamUpSystem.GetMemberCarteamName(uid)
	local result = "";
	local memberinfo = TeamUpSystem.GetMemberInfo(uid);
	if memberinfo ~= nil and memberinfo.carteam_name ~= nil  then
		result = memberinfo.carteam_name;
	end
	return result;
end

--是否打开语音
function TeamUpSystem.IsOpenVoice(uid)
	log("IsOpenVoice"..tostring(uid));
	local result = false;
	local memberinfo = TeamUpSystem.GetMemberInfo(tonumber(uid));
	--log_tree("IsOpenVoice",memberinfo)
	if memberinfo ~= nil then
		if memberinfo.voice ~= nil and memberinfo.voice.voice_open == true then
			result = true;
		end
	end
	log("IsOpenVoice"..tostring(result));
	return result;
end
------- C2S -------
--获取自己的uid
--临时用，因为暂时没有其它地方可以取得
function TeamUpSystem.query_myid_request()
	log("query_myid_request" );
	NetUtil.SendPkg("query_myid_request");
end

--请求队伍信息
function TeamUpSystem.team_info_request()
	log("team_info_request" );
	NetUtil.SendPkg("team_info_request");
end

--改变房间类型
function TeamUpSystem.team_change_type_request(teamtype)
	log("team_change_type_request, teamtype: " .. teamtype);
	NetUtil.SendPkg("team_change_type_request", teamtype);
end

--邀请好友
function TeamUpSystem.team_invite_request(userid)
	log("team_invite_request, invite: " .. userid);	
	NetUtil.SendPkg("team_invite_request", userid);	
	--NetUtil.SendPriorityPkg(true, "team_invite_respond", "team_invite_request", userid);	
	--DataMgr.ShowNoticeByID(110004);	--邀请消息已发送
end

--聊天招募接口team_join_respond
function TeamUpSystem.JoinTeamByChat(uid, teamid, src)
	log("JoinTeamByChat"..uid.."--src:"..tostring(src));
	if DataMgr.roleData ~= nil then
		if DataMgr.roleData.uid == uid  then
			--你已经在队伍中
			DataMgr.ShowNoticeByID(110045);
			return;			
		end
	end	
	log("TeamUpSystem.JoinTeamByChat"..tostring(uid));	
	log("TeamUpSystem.JoinTeamByChat teamid"..tostring(teamid));	
	--local timeTick = os.time - timeString;
	--if timeTick > 600 then --如果大于10分钟，则表示消息失效
		--TODO,提示
	--	log("JoinTeamByChat time is vaild");
		--return;
	--end
	--res 用 enlist ，我就不发给队长,队长就收不到申请	
	TeamUpSystem.team_invite_reply("enlist", tonumber(uid), tonumber(teamid), src);
end


--回应收到的邀请
function TeamUpSystem.team_invite_reply(ispermit, userid, teamid, src)
	log("team_invite_reply: userid = "..userid..", ispermit = "..ispermit);
	NetUtil.SendPkg("team_invite_reply", ispermit, userid,teamid, src);
end

--申请离队
function TeamUpSystem.team_quit_request(teamid)
	log("team_quit_request teamid = "..teamid);	
	--NetUtil.SendPriorityPkg(true, "team_quit_respond", "team_quit_request", teamid);	
	NetUtil.SendPkg("team_quit_request", teamid);
end

--申请加入好友队伍
function TeamUpSystem.team_apply_request(userid)
	log("team_apply_request userid = "..userid);
	NetUtil.SendPkg("team_apply_request", userid);
	--后台返回才提示
	--DataMgr.ShowNoticeByID(110012);	--入队申请已发送
end

--对于申请组队提示的回应
function TeamUpSystem.team_apply_reply(ispermit, userid, teamid)
	log("team_apply_reply ispermit = "..ispermit..", userid = " .. userid);
	NetUtil.SendPkg("team_apply_reply", ispermit, userid, teamid);
end

--踢人
function TeamUpSystem.team_kick_request(userid)
	log("team_kick_request userid = "..userid);
	NetUtil.SendPkg("team_kick_request", userid);
end

--是否需要实时拉取好友变化
function TeamUpSystem.recv_stau_request(isNeed)
	log("recv_stau_request "..tostring(isNeed));
	--iphonexiao(肖建)  01-13 22:34:05备忘 是否接受好友通知标志的请求给干掉
	--NetUtil.SendPkg("chang_recv_group_statu_flag",true);
end


function TeamUpSystem.team_change_fill_request(fill)
	log("team_change_fill_request fill = "..tostring(fill));
	NetUtil.SendPkg("team_change_fill_request",fill);
end


------- S2C -------
function TeamUpSystem.team_change_leader_request(new_leader)
	log("team_change_leader_request new_leader = "..new_leader);
	NetUtil.SendPkg("team_change_leader_request", new_leader);
end

--请求陌生人所有状态
function TeamUpSystem.stange_all_status_request(uid)
	local oneUid = tonumber(uid);
	local list = {};
	table.insert(list,oneUid);
	local cb = "strengthStatu";
	NetUtil.SendPkg("batch_get_group_and_online_req",cb,list);
end

--请求预留teamid，用于平台邀请
function TeamUpSystem.get_teamid_for_plat_request()
	--c2s.team_recruit_for_plat_req( )
	log("get_teamid_for_plat ");
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX and Client.IsInstallWX(NetInterface) == false then
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ and Client.IsInstallQQ(NetInterface) == false then
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end
	NetUtil.SendPkg("team_recruit_for_plat_req");
end

--上报自己的语音房间信息
function TeamUpSystem.ReportVoiceInfo(voiceuid,voiceOpen)
	log("ReportVoiceInfo:"..voiceuid.."isOpen:"..tostring(voiceOpen));
	NetUtil.SendPkg("team_report_voice_info",tonumber(voiceuid),voiceOpen);
end


--招募请求
function TeamUpSystem.team_recruit(msgContent,sendWord,sendFriend,sendChannel)
	-- chat_content 招募内容  chat_content.text 文本消息
	-- send_world  世界招募  true or false
	-- send_friend  好友招募 true or false
	-- send_channel  频道招募  true or false	
	local list = {};
	list.text = msgContent;
	log("TeamUpSystem.team_recruit"..list.text..tostring(sendWord)..tostring(sendFriend)..tostring(sendChannel));
	NetUtil.SendPkg("team_recruit",list,sendWord,sendFriend,sendChannel);
end

--招募请求返回,ok不处理
function TeamUpSystem.team_recruit_rsp(ret, time_left)
	log("TeamUpSystem.team_recruit_rsp"..tostring(ret));
	if ret == "ok" then
			
	elseif ret == "request_frequent" then
		--todo
		local msgContent = string.format(Client.GetTableData("LocalizeRes", "100007").TextValue, time_left);
		DataMgr.ShowNoticeByString(msgContent);
		--time_left    请求频繁时返回还剩余多少秒可以请求
	end
end

local function CreateTeamInfoSingle(_teaminfo)
	--local nickname  = DataMgr.roleData == nil and "" or DataMgr.roleData.nickName;	
	--重构单人数据结构
	local teaminfo = {};
	teaminfo.fill = _teaminfo.fill;
	teaminfo.player_count = 1;
	teaminfo.id = 0;
	teaminfo.leader = TeamUpSystem.MyUserID;
	teaminfo.members = _teaminfo.members;	
	teaminfo.team_type = _teaminfo.team_type;
	return teaminfo;
end


--聊天内点击进入队伍

--获取自己uid回应
function TeamUpSystem.on_query_myid_respond(myuserid)
	log("on_query_myid_respond "..myuserid);
	TeamUpSystem.MyUserID = myuserid;
	TeamUpSystem.team_info_request();
	
	--同步下组队限时开放
	TeamUpSystem.on_mode_shield_req();
end

--队伍信息同步
function TeamUpSystem.on_team_info_sync(teamid, teaminfo)
	log("teamid"..teamid);
	--log_tree("teaminfo",teaminfo);
	--为0表示单人
	if teamid == 0 then
		teaminfo =  CreateTeamInfoSingle(teaminfo);
	end

	--TODO jack 
	--TeamUpUI.TestAddOnPlayer(teaminfo, 1);
	--TeamUpUI.TestAddOnPlayer(teaminfo, 2);	
	--TeamUpUI.TestAddOnPlayer(teaminfo, 3);	
	--teaminfo.team_type = 0;
	TeamUpSystem.CheckInviteApplyOnTeamChange(teaminfo);
	
	TeamUpSystem.CompareMemBer(teaminfo);
	--EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_COMPARE_DATA);
	TeamUpSystem.TeamInfo = teaminfo;	
	log_tree("TeamUpSystem.TeamInfo", TeamUpSystem.TeamInfo);	
	EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);	
	
	TeamUpSystem.ProcessChat();
end

function TeamUpSystem.CheckInviteApplyOnTeamChange(teaminfo)
	log("TeamUpSystem.CheckInviteApplyOnTeamChange");
	if (TeamUpSystem.TeamInfo ~= nil and TeamUpSystem.TeamInfo.id ~= nil and TeamUpSystem.TeamInfo.id ~= teaminfo.id) then
		local queueLength = #TeamUpSystem.InviteApplyQueue;
		log("queueLength = " .. queueLength);
		if (queueLength > 0) then
			for i = 1, queueLength, 1 do
				local inviteApplyData = TeamUpSystem.InviteApplyQueue[i];
				--log_tree("inviteApplyData", inviteApplyData);
				if (inviteApplyData ~= nil and inviteApplyData.type == 0) then
					log("autoRefuseOnTeamChange invite playerId = " .. inviteApplyData.playerId);
					TeamUpSystem.team_invite_reply("autoRefuseOnTeamChange", tonumber(inviteApplyData.playerId),tonumber(inviteApplyData.InviterTeamID));
				elseif (inviteApplyData ~= nil and inviteApplyData.type == 1) then
					--log("autoRefuseOnTeamChange apply playerId = " .. inviteApplyData.playerId);
					TeamUpSystem.team_apply_reply("autoRefuseOnTeamChange", tonumber(inviteApplyData.playerId),tonumber(inviteApplyData.ApplyerTeamID));
				end
			end
		end
		
		TeamUpSystem.InviteApplyQueue = {};
		TeamUpUI.CloseInviteApplyPanel();		
	end
end


--邀请好友响应
function TeamUpSystem.on_team_invite_respond(state, invitee)
	log("on_query_myid_respond state = "..state..", invitee = "..invitee);
	if(state == "ok") then
		DataMgr.ShowNoticeByID(110004);	--邀请消息已发送
		--好友进入队伍
		TeamUpSystem.team_info_request();
	elseif (state == "target-not-online") then
		DataMgr.ShowNoticeByID(110016);
		--PopUpNoticeUI.ShowMessageBox("提示", "邀请失败，对方不在线。");
	elseif (state == "team-is-full") then
		DataMgr.ShowNoticeByID(110007);
		--PopUpNoticeUI.ShowMessageBox("提示", "邀请失败，队伍人数已满。");
	elseif (state == "refuse") then
		DataMgr.ShowNoticeByID(110011);
		--用户主动拒绝
	elseif (state == "autoRefuseOnTeamChange") then
		DataMgr.ShowNoticeByID(110056);	--对方已加入其它队伍
	elseif (state == "already_in_match") then 
		DataMgr.ShowNoticeByID(110058);----匹配中不能邀请队友
	elseif (state == "invitee_in_match") then 
		DataMgr.ShowNoticeByID(110059);----%s在匹配中		
	elseif (state == "inviter_in_match") then 
		DataMgr.ShowNoticeByID(110059);----%s在匹配中			
	elseif (state == "inviter_in_game") then 
		DataMgr.ShowNoticeByID(9911106);----游戏中		
	elseif (state == "team in match") then 
		DataMgr.ShowNoticeByID(110060);----	队伍已经在匹配中
	elseif (state == "already_in_match") then 
		DataMgr.ShowNoticeByID(110061);----	已经在匹配中
	elseif state == "not_same_version" then
		TeamUpUI.NotSameVertionTips();--版本不一致，无法一起游戏
	else
	--team_invite_respond("already_in_room", invitee)   ---您在房间中，不能组队。
	--team_invite_respond("invitee_in_room", invitee)   ---对方房间中，不能组队。
		TeamUpUI.ProtocolErrorCode(state);
	end
end

--收到邀请提示
function TeamUpSystem.on_team_invite_notify(inviter,  teamId)
	
	log("on_team_invite_notify inviter = "..inviter);
	log("on_team_invite_notify teamId = "..teamId);

	local autoRefuse = TeamUpSystem.CheckInviteAutoRefuse(inviter);
	
	if (autoRefuse == true) then
		log("on_team_invite_notify autoRefuse = true");
		return;
	end
	--不在黑名单的才弹出邀请消息
	local isPullBack = FriendSystem.IsPulBlack(inviter);
	log("on_team_invite_notify ispulblack:"..tostring(isPullBack));
	if isPullBack == false then			
		local inviteApplyData = {};
		inviteApplyData.type = 0;
		inviteApplyData.playerId = inviter;
		inviteApplyData.InviterTeamID = teamId;
		inviteApplyData.playerName = TeamUpSystem.GetMemberName(inviter);
		table.insert(TeamUpSystem.InviteApplyQueue, inviteApplyData);
		TeamUpSystem.CheckNextInviteApply();
		--TeamUpSystem.Inviter = inviter;	
		--EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_GET_INVITE);
	end
end

function TeamUpSystem.CheckNextInviteApply()
	
	if (TeamUpSystem.InviteApplyShowing)  then
		local timeDiff = os.time() - TeamUpSystem.InviteApplyShowTime;
		if (timeDiff < (APPLY_INVITE_SHOW_TIME + 1)) then
			return;
		end
	end
	
	if #TeamUpSystem.InviteApplyQueue > 0 then
		
		local inviteApplyData = TeamUpSystem.InviteApplyQueue[1];
		table.remove(TeamUpSystem.InviteApplyQueue, 1);
		
		TeamUpSystem.InviteApplyShowing = true;
		TeamUpSystem.InviteApplyShowTime = os.time();
		
		--log("show invite apply");
		--log_tree("inviteApplyData", inviteApplyData);
		
		if (inviteApplyData.type == 0) then
			if (TeamUpSystem.TeamInfo.player_count > 1) then
				TeamUpSystem.InviteApplyShowing = false;
				TeamUpSystem.team_invite_reply("autoRefuseOnTeamChange", tonumber(inviteApplyData.playerId),tonumber(inviteApplyData.InviterTeamID));
				TeamUpSystem.CheckNextInviteApply();
				return;
			end
			TeamUpSystem.InviteApplyShowType = 0;
			TeamUpSystem.Inviter = inviteApplyData.playerId;	
			TeamUpSystem.InviterTeamID = inviteApplyData.InviterTeamID;
			TeamUp_Inviter_Name = inviteApplyData.playerName;
			EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_GET_INVITE);
		elseif (inviteApplyData.type == 1) then
			if (TeamUpSystem.IsTeamLeader() == false) then
				TeamUpSystem.InviteApplyShowing = false;
				TeamUpSystem.team_apply_reply("autoRefuseOnTeamChange", tonumber(inviteApplyData.playerId),tonumber(inviteApplyData.ApplyerTeamID));
				TeamUpSystem.CheckNextInviteApply();
				return;
			end
			
			TeamUpSystem.InviteApplyShowType = 1;
			TeamUpSystem.ApplyerID = inviteApplyData.playerId;
			TeamUpSystem.ApplyerTeamID = inviteApplyData.ApplyerTeamID;
			TeamUp_Applyer_Name = inviteApplyData.playerName;
			EventSystem:postEvent(EVENTTYPE_TEAMUP, EVNETID_TEAMUP_APPLY_JOIN);
		end
	end
end


function TeamUpSystem.CheckInviteAutoRefuse(inviter)
	return TeamUpSystem.CheckAutoRefuse(TeamUpSystem.AutoRefuseInviterMap, inviter, AUTO_REFUSE_TIME_OUT);
end

function TeamUpSystem.CheckApplyAutoRefuse(applyerID)
	return TeamUpSystem.CheckAutoRefuse(TeamUpSystem.AutoRefuseApplyerMap, applyerID, AUTO_REFUSE_TIME_OUT);
end

function TeamUpSystem.CheckAutoRefuse(map, id, timeout)

	if (map == nil or id == nil or timeout == nil) then
		return false;
	end
	
	local autoRefuseTime = map[id];
	
	if (autoRefuseTime == nil) then
		return false;
	end
	
	local timeDiff = os.time() - autoRefuseTime;
	log("TeamUpSystem.CheckAutoRefuse id = " .. id .. ", timeDiff = " .. timeDiff);
	
	return timeDiff < timeout;
end



--退出队伍响应
function TeamUpSystem.on_team_quit_respond(state)
	log("on_team_quit_respond state = "..state)
	-- 请求一下新队伍的信息
	-- 还需要做其它什么吗？？
	if(state == "ok") then
		TeamUpSystem.team_info_request();
	else
		--PopUpNoticeUI.ShowMessageBox("提示", "退出队伍失败");
	end	
	
end

--申请加入好友队伍 收到的响应
function TeamUpSystem.on_team_apply_respond(state)
	log("on_team_apply_respond state = "..state);
	-- 请求一下新队伍的信息
	-- 还需要做其它什么吗？？
	if(state == "ok") then
		TeamUpSystem.team_info_request();
	elseif (state == "refuse") then
		DataMgr.ShowNoticeByID(110013); --对方拒绝了入队申请
	elseif (state == "autoRefuseOnTeamChange") then
		DataMgr.ShowNoticeByID(110057);	--对方队长退出队伍了，请重新申请
	elseif (state == "team in match") then 
		DataMgr.ShowNoticeByID(110060);----	队伍已经在匹配中
	elseif state == "send_apply_success" then
		--后台返回才提示
		DataMgr.ShowNoticeByID(110012);	--入队申请已发送
	elseif state == "not_same_version" then
		TeamUpUI.NotSameVertionTips();--版本不一致，无法一起游戏
	else
		--team_apply_respond("already_in_room")             ---您在房间中，不能组队。
		--team_apply_respond("applicant_in_room")           ---被申请者在房间中，不能组队。
		TeamUpUI.ProtocolErrorCode(state);

	end
end

--踢人
function TeamUpSystem.on_team_kick_respond(res, targetUID)
	
	log("on_team_kick_respond res = "..res..", targetUID = "..targetUID);

	if(res == "ok") then
		TeamUpSystem.team_info_request();
	else
		--PopUpNoticeUI.ShowNewNotice("踢出失败");
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes",301165).TextValue);
	end	
end

--收到申请进入队伍提示
function TeamUpSystem.on_team_apply_notify(applyerID, applyerName, teamid)
	
	log("on_team_apply_notify applyerID = "..applyerID..", applyerName = "..applyerName);
	
	local autoRefuse = TeamUpSystem.CheckApplyAutoRefuse(applyerID);

	if (autoRefuse == true) then
		log("on_team_apply_notify autoRefuse = true");
		return;
	end	
	
	local inviteApplyData = {};
	inviteApplyData.type = 1;
	inviteApplyData.playerId = applyerID;
	inviteApplyData.playerName = applyerName;
	inviteApplyData.ApplyerTeamID = teamid;	
	table.insert(TeamUpSystem.InviteApplyQueue, inviteApplyData);	
	TeamUpSystem.CheckNextInviteApply();
	--TeamUpSystem.ApplyerID = applyerID;
	--TeamUp_Applyer_Name = applyerName;
	
	--EventSystem:postEvent(EVENTTYPE_TEAMUP, EVNETID_TEAMUP_APPLY_JOIN);
end

--队伍信息改变通知
--[[
operate_type:
1  team other join in my team
2  team other quit
3  team change leader,param1代表成员数量
4  team join a team
5  team change type to param 1 2 4
6  team member status changed
7  team member online or offline    param  svr( not nil = online,  nil = offline)
8  change fill 
9  client version not match team 
10 voice notify
11 通知某队员的站队名变更, 其中param ={uid=uid, carteam_name=carteam_name}
]]
function TeamUpSystem.on_team_info_change_notify(teamid, operate_type, param, param1)
	
	log("on_team_info_change_notify: " .. operate_type );
	
	--log_tree("param :", param);
	if(operate_type == 1) then
		TeamUpSystem.team_info_request();
	elseif(operate_type == 2) then
		if param ~= nil and TeamUpSystem.MyUserID == tonumber(param) then
			--您已被请出队伍
			TeamUpUI.ProtocolErrorCode("kickOut");
		end
		TeamUpSystem.team_info_request();
	elseif(operate_type == 3) then
		
		local myId = DataMgr.roleData.uid;
		--log("team change leader myID = " .. myId .. " , param = " .. param);
		log("on_team_info_change_notify param1",param1);
		local curPlayerCount = TeamUpSystem.TeamInfo.player_count;
		if param1 ~= nil then
			curPlayerCount = param1;
		end

		if ((tostring(myId)  == tostring(param)) and curPlayerCount > 1) then

			--如果在战斗过程中不提示
			local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			if curStatus ~= "fighting" then
				DataMgr.ShowNoticeByID(110046); --被任命为队长
			end
		
		end
		if (tostring(myId)  ~= tostring(param)) then
			--log("TeamUpSystem.InviteApplyShowing = " .. tostring(TeamUpSystem.InviteApplyShowing));
			--log("TeamUpSystem.InviteApplyShowType = " .. tostring(TeamUpSystem.InviteApplyShowType));
			if (TeamUpSystem.InviteApplyShowing and TeamUpSystem.InviteApplyShowType == 1) then		
				TeamUpUI.CloseInviteApplyPanel();
				TeamUpSystem.CheckNextInviteApply();
			end
		end
		TeamUpSystem.TeamInfo.leader = param;
		--换队长，重新执行下聊天相关的逻辑
		TeamUpSystem.ProcessChat();
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);	
		
	elseif(operate_type == 4) then
		TeamUpSystem.team_info_request();
	elseif(operate_type == 5) then
		TeamUpSystem.TeamInfo.team_type = tonumber(param);
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TYPE_CHAGNE);
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);
	elseif (operate_type == 6) then
		local mermberInfo = TeamUpSystem.GetMemberInfo(param.uid);
		mermberInfo.status = param.status;
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);	
	elseif (operate_type == 7) then
		TeamUpSystem.ReLinkLine(param);
	elseif (operate_type == 8) then
		TeamUpSystem.TeamInfo.fill = param;
		LobbySystem.SetFillValue(param);
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);
	elseif operate_type == 9 then
		--版本不一致，无法一起游戏
		TeamUpUI.NotSameVertionTips();
	elseif operate_type == 10 then --通知队员语音房间信息
		--voice_info = {uid=uid, voice={voice_uid=voice_uid, voice_open=voice_open}};				
		if param ~= nil then
			--log_tree("team_info_notify  voice_info", param);
			TeamUpSystem.UpdateVoiceInfo(param.uid, param.voice);			
		end
		--同步队友的语音信息
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);
				
	elseif operate_type == 11 then --通知某队员的站队名变更, 其中param ={uid=uid, carteam_name=carteam_name}
		if param ~= nil then
			--log_tree("team_info_notify  carteam_name", param);
			TeamUpSystem.UpdateCarteamName(param.uid, param.carteam_name);
			--同步战队名字
			EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);
		end

	end
end

--主要用于聊天招募,加入失败的处理，并不是一一对应的协议
function TeamUpSystem.on_team_join_rsp(res, teamid, teamInfo)
	-- "team-is-full" 队伍满了
	--"target-not-online"队伍已解散
	log("on_team_join_rsp"..res);
	if res == "ok" then				
		DataMgr.ShowNoticeByID(110042);
	elseif res == "team-is-full" then	
		DataMgr.ShowNoticeByID(110007);
		
	elseif res == "target-not-online" then		
		DataMgr.ShowNoticeByID(110009);
	elseif res == "already_in_team"  then
		--你已经在队伍中		
		DataMgr.ShowNoticeByID(110045);		
	elseif res == "already_has_team"  then		
		--您已在组队中，不可加入其他队伍。	
		DataMgr.ShowNoticeByID(110044);
	elseif res == "team-in-match" then
		DataMgr.ShowNoticeByID(110059);	--对方在匹配中
	elseif res == "team_not_exist" then
		DataMgr.ShowNoticeByID(110009);	--队伍已解散
	elseif res == "not_same_version" then
		TeamUpUI.NotSameVertionTips();--版本不一致，无法一起游戏
	elseif (res == "inviter_in_match") then 
		DataMgr.ShowNoticeByID(110059);----%s在匹配中			
	elseif (res == "inviter_in_game") then 
		DataMgr.ShowNoticeByID(9911106);----游戏中	
	else
		--team_join_respond("inviter_in_room", nil, nil)    ---邀请者在房间中，不能组队。
		--team_join_respond("already_in_room", nil, nil)    ---您在房间中，不能组队。
		TeamUpUI.ProtocolErrorCode(res);
	end
end

local  function UpdateTeamInfoWear(memberUid, isPushOn, mResId, mAvatarPos)
	local memberInfo  =  TeamUpSystem.GetMemberInfo(tonumber(memberUid));
	if memberInfo == nil then
		return;
	end

	if memberInfo.ware == nil then
		return;
	end

	local hasWear = memberInfo.ware[mAvatarPos];
	if hasWear == nil then
		if isPushOn == 1 then
			TeamUpSystem.TeamInfo.members[tonumber(memberUid)].ware[mAvatarPos] = mResId;
			--memberInfo.ware[mAvatarPos] = mResId;
		end		
	elseif hasWear ~= nil then
		if isPushOn == 1 then --表示穿
			TeamUpSystem.TeamInfo.members[tonumber(memberUid)].ware[mAvatarPos] = mResId;
			--memberInfo.ware[mAvatarPos] = mResId;
		else --0表示脱		
			
			for k,v in pairs(memberInfo.ware) do
				if v == mAvatarPos then
					table.remove(TeamUpSystem.TeamInfo.members[tonumber(memberUid)].ware,k);			
					 --table.remove(memberInfo.ware,k)
				end
			end		
			
		end
	end

end


function TeamUpSystem.on_team_change_wear(memberUid, isPushOn, mResId, mAvatarPos)
	TeamUpSystem.ChangeWearInfo = {
		uid = memberUid,
		pos = isPushOn, --0 是脱，1是穿
		resId = mResId, 
		--新增人的avatar位置
		avatarPos = mAvatarPos,
	};
	--同步下数据，用于断线重连
	UpdateTeamInfoWear(memberUid, isPushOn, mResId, mAvatarPos);
	--log_tree("TeamUpSystem.on_team_change_wear", TeamUpSystem.TeamInfo);
	
	EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_CHANGE_WEAR);	
end




--返回陌生人状态信息,用于聊天菜单弹出
function TeamUpSystem.on_stranger_staus_rsp(cb, res, infos)
	--[[
	// res 字符串返回码. "ok": 正常; "timeout": 超时,此时仅有部分数据拉取成功
	//此时仅有部分数据拉取成功; "invalid_param": 表示参数非法; "busy": 表示当前系统繁忙
	// infos = 	  {[uid1] = 
	{
		teamState=teamState,						// 0 空闲 1 组队中 2 游戏中
		teamId=teamId, 								// 队伍ID
		currentTeamAmount=currentTeamAmount,		// 队伍当前人数
		maxTeamAmount=maxTeamAmount, 				// 队伍最大人数
		timeSinceGameBegin=timeSinceGameBegin, 		// 游戏开局了多久(单位秒)
		online=online  								// 0 不在线  1 在线
	} --]]
	if cb ~= "strengthStatu" then
		log("no strengthStatu");
		return;
	end
	
	
		
	local curUID;
	TeamUpSystem.PlayerStatu = {};	
	if res =="ok" then
		if infos ~= nil then
			for k,v in pairs(infos) do
				--始终取第一个
				curUID = k;
				TeamUpSystem.PlayerStatu.teamState = v.teamState;
				TeamUpSystem.PlayerStatu.teamId = v.teamId;
				TeamUpSystem.PlayerStatu.currentTeamAmount = v.currentTeamAmount;
				TeamUpSystem.PlayerStatu.maxTeamAmount = v.maxTeamAmount;
				TeamUpSystem.PlayerStatu.timeSinceGameBegin = v.timeSinceGameBegin;
				TeamUpSystem.PlayerStatu.online = v.online;
				break; 
			end			
		end		
		--log_tree("TeamUpSystem.PlayerStatu ",TeamUpSystem.PlayerStatu);
		--TeamUpSystem.PlayerStatu = infos;	
		if curUID > 0 then
			local myInfo = TeamUpSystem.GetMemberInfo(curUID);
			if myInfo == nil then
				TeamUpSystem.UpdateMenuForChat();
			end		
		end
		
	elseif res == "timeout" then
		--超时
	elseif res == "invalid_param" then
		--参数非法
	elseif res == "busy" then
		--系统繁忙
	end

end

--如果只是换头发则不需要重新删除角色
local function NeedReCreatPalyer(op_uid,newAvatar)
	local result = false;
	local _info = TeamUpSystem.GetMemberInfo(op_uid);
	if _info ~= nil then
		--判断性别
		if _info.avatar.gamegender ~= newAvatar.gamegender then
			return true;
		end		
		--判断头ID
		if _info.avatar.headid ~= newAvatar.headid then
			return true;
		end
	end
	
	return result;
end


--更新队友模型，
local function UpdateMemberModle(newTeamInfo)
	--单人不需要替换模型
	if newTeamInfo.player_count == 1 then
		return;
	end

	local  needUpdate = false;
	for k,v in pairs(newTeamInfo.members) do
		local _newGid = k;
		if k ~= TeamUpSystem.MyUserID then
			local info =TeamUpSystem.GetMemberInfo(tonumber(k));
			--判断性别不一样或者判断头ID不一样都要重新删除模型，然后再加载模型
			local notSameSex = false;
			local notSameHeadid = false;
			if info ~= nil then
				notSameSex = NeedReCreatPalyer(_newGid,info.avatar)
				notSameHeadid = NeedReCreatPalyer(_newGid,info.avatar)
			end

			if info == nil or notSameSex == true or notSameHeadid == true  then
				needUpdate = true;
				break;
			end
		end
	end

	if needUpdate == true then
		--删除旧的模型
		local oldTeamInfo = TeamUpSystem.TeamInfo;	
		for k1,v1 in pairs(oldTeamInfo.members) do
			local _oldGid = k1;
			if k1 ~= TeamUpSystem.MyUserID then

				local _sex = 1;
				if v1.gender  ~= nil then
					_sex = v1.gender;
				end	

				local wearArray = {};
				if v1.wear ~= nil then
					for wk,wv in pairs(v1.wear) do
						table.insert(wearArray, wv);
					end
				end

				local playerData ={
					gid = _oldGid,
					sex = _sex,		
					BP_ARRAY_AvatarList = wearArray,
	                avatar = v1.avatar
				};
				--log_tree("UpdateMemberModle del", playerData);	
				LobbyUI:SpawnPlayer(playerData, false);
			end
		end

		--重新加载新的模型
		for k2,v2 in pairs(newTeamInfo.members) do
			local _newGid1 = k2;
			if k2 ~= TeamUpSystem.MyUserID then

				local _sex = 1;
				if v2.gender  ~= nil then
					_sex = v2.gender;
				end	

				local wearArray = {};
				if v2.wear ~= nil then
					for wk1,wv1 in pairs(v2.wear) do
						table.insert(wearArray, wv1);
					end
				end

				local playerData ={
					gid = _newGid1,
					sex = _sex,		
					BP_ARRAY_AvatarList = wearArray,
	                avatar = v2.avatar
				};
				--log_tree("UpdateMemberModle", playerData);	
				LobbyUI:SpawnPlayer(playerData, true);
			end
		end


	end
	
end

	
function TeamUpSystem.CompareMemBer(newTeamInfo)
	if newTeamInfo == nil then
		log("TeamUpSystem.CompareMemBer newTeamInfo none");
		return;
	end
	--log_tree("TeamUpSystem.CompareMemBer parmNewTeamInfo" , newTeamInfo);
	local oldTeamInfo = TeamUpSystem.TeamInfo;	
	--log_tree("TeamUpSystem.CompareMemBer oldTeamInfo" , oldTeamInfo);
	if oldTeamInfo.player_count == nil then		
		--登录只设一次
		log("TeamUpSystem.CompareMemBer MyUserID" ..tostring(TeamUpSystem.MyUserID));
		TeamUpSystem.IsAddMember = true;				
		for k,v in pairs(newTeamInfo.members) do
			local _newGid = k;
			if k ~= TeamUpSystem.MyUserID then
				local _newStructData ={
				gid = _newGid,
				name = v.name,
				status = v.status,
				svr = v.svr, 
				wear = v.ware,
				gender = v.gender,
                avatar = v.avatar
				};
				table.insert(TeamUpSystem.ChangeMemberInfo, _newStructData);
			end
		end
		--log_tree(" TeamUpUI.CompareMemBer initData", TeamUpSystem.ChangeMemberInfo);		
		return;
	end	

	TeamUpSystem.ChangeMemberInfo = {};		

	--计算增量
	if newTeamInfo.player_count == oldTeamInfo.player_count then		
		TeamUpSystem.IsAddMember = false;	
		--更新模型
		UpdateMemberModle(newTeamInfo);
		--处理断线重连后换装的逻辑
		TeamUpSystem.UpdateTeamMemberAvatar(newTeamInfo);
		return;
	end 	

	
	--[[
	    │  └─ 382236358
		│    ├─ name: "吃鹅ebrcx"
		│    └─ svr: 17039369	
	--]]	
	--log_tree("TeamUpSystem.CompareMemBer newTeamInfo" , newTeamInfo);	
	
	if newTeamInfo.player_count > oldTeamInfo.player_count then
		
		--增加角色
		TeamUpSystem.IsAddMember = true;
		for k,v in pairs(newTeamInfo.members) do
			local _newGid = k;
			local _isFind = false;
			for i,iv in pairs(oldTeamInfo.members) do
				local _oldGid = i;			
				if _newGid == _oldGid then
					_isFind =true;
					break;
				end		
			end		
			if _isFind == false then
				local _newStructData ={
					gid = _newGid,
					name = v.name,
					status = v.status,
					svr = v.svr,
					wear = v.ware,
					gender = v.gender,
                    avatar = v.avatar
				};
				table.insert(TeamUpSystem.ChangeMemberInfo, _newStructData);
			end	
		end		
		
	elseif newTeamInfo.player_count < oldTeamInfo.player_count then		
		--删除角色
		TeamUpSystem.IsAddMember = false;	
		for k,v in pairs(oldTeamInfo.members) do
			local _newGid = k;
			local _isFind = false;
			for i,iv in pairs(newTeamInfo.members) do
				local _oldGid = i;			
				if _newGid == _oldGid then
					_isFind =true;
					break;
				end				
			end			
			
			if _isFind == false then
				local _newStructData ={
					gid = _newGid,
					name = v.name,
					status = v.status,
					svr = v.svr,
					wear = v.ware,
					gender = v.gender,
                    avatar = v.avatar
				};
				table.insert(TeamUpSystem.ChangeMemberInfo, _newStructData);
			end	
		
		end
			
	end	
	
	--log_tree(" TeamUpUI.CompareMemBer memberInfo", TeamUpSystem.ChangeMemberInfo);	
		--处理断线重连后换装的逻辑
	TeamUpSystem.UpdateTeamMemberAvatar(newTeamInfo);
	
end 

--同步avatar信息
local function HasPosInNewWare(ware, position)
	log("HasPosInNewWare"..position);
	--log_tree("HasPosInNewWare",ware);
	if ware ~= nil then
		for k,v in pairs(ware) do
			if k == position then
				return v;
			end		
		end
	end

	return nil;
	
end 

function TeamUpSystem.UpdateTeamMemberAvatar(newTeamInfo)
	local oldTeamInfo = TeamUpSystem.TeamInfo;	
	--log_tree("oldTeamInfo",oldTeamInfo);
	--log_tree("newTeamInfo",newTeamInfo);
	for k,v in pairs(newTeamInfo.members) do
		local _newGid = k;
		local _newWare = v.ware;
		local oldMemberInfo = TeamUpSystem.GetMemberInfo(_newGid);
		--log("oldMemberInfo",oldMemberInfo);
		--先脱后穿
		if oldMemberInfo ~= nil then
			local _oldWare = oldMemberInfo.ware;
			--log_tree("_oldWare",_oldWare);
			for k1,v1 in pairs(_oldWare) do
				local resId = HasPosInNewWare(_newWare,k1);
				--老的avatar在新的模型上取不到，说明被脱了
				if resId == nil then
					local avatar_data = {};
					avatar_data.gid = _newGid;
					avatar_data.resId = v1;
					--脱掉
					--log("tttttttttd:"..v1);
					LobbyUI:AvatarChange(avatar_data, false);
				end
			end
		end	

		--穿上新的avatar;
		--log_tree("_newWare",_newWare);
		for k2,v2 in pairs(_newWare) do
			local newAvatar_data = {};
			newAvatar_data.gid = _newGid;
			newAvatar_data.resId = v2;
			--log("cccccccccccd::"..v2);
			LobbyUI:AvatarChange(newAvatar_data, true);
		end	
	end

end



function TeamUpSystem.ReLinkLine(tParam)
	
	if tParam == nil then 
		log("TeamUpSystem.ReLinkLine tParam none");
		TeamUpSystem.team_info_request();
		return;
	end	
	
	--log_tree("TeamUpSystem.ReLinkLine :", tParam);
	local pUid = tParam.uid;
	local _info = TeamUpSystem.GetMemberInfo(pUid);
	local isOnlineLastTime = false;
	if _info == nil then
		log("TeamUpSystem.ReLinkLine _info none uid:"..tostring(pUid));		
		return;	
	end

	if _info ~= nil then
		isOnlineLastTime = (_info.svr ~= nil);
	end	
	
	local isOnlineNow = (tParam.svr ~= nil);
	if isOnlineLastTime == false and isOnlineNow == true then
		log("TeamUpSystemReLinkLine perOnline"..pUid);
		local stringName = TeamUpSystem.GetMemberName(pUid);
		local tipString =DataMgr.GetMsgByID(110020);
		local finalString = string.format(tostring(tipString),tostring(stringName));	

		--如果在战斗过程中不提示
		local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
		if curStatus ~= "fighting" then
			DataMgr.ShowNoticeByString(finalString);
		end

		
		--CommonMessageBoxUI:ShowPanel(1, "提示", finalString, nil, nil);		
		---xxx已上线啦
	elseif isOnlineLastTime == true and isOnlineNow == false then
		log("TeamUpSystemReLinkLine perOffline"..pUid);
		local stringName = TeamUpSystem.GetMemberName(pUid);
		local tipString =DataMgr.GetMsgByID(110021);
		local finalString = string.format(tostring(tipString),tostring(stringName));	
		--DataMgr.ShowNoticeByString(finalString);		
		--CommonMessageBoxUI:ShowPanel(1, "提示", finalString, nil, nil);
		-----xxx下线啦
	end
	--game_start不为空则游戏中，nil为非游戏中
	_info.svr = tParam.svr;
	_info.game_start = 0;
	if tParam.game_start ~= nil then
		_info.game_start = tParam.game_start;
	end
	EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC);		

end

function TeamUpSystem.ProcessChat()	
	if TeamUpSystem.TeamInfo.player_count ~= nil then
		if TeamUpSystem.TeamInfo.player_count > 1 then
			if TeamUpSystem.TeamInfo.leader ~= nil then
				local leaderUid = TeamUpSystem.TeamInfo.leader;
				log("chatddddd:"..leaderUid);
				leaderUid = math.floor(leaderUid);
				log("chatmath.floorddddd:"..leaderUid);
				GlobalChatVoice.JoinLobbyVoiceRoom(tostring(leaderUid));				
			end
		else
			 GlobalChatVoice.QuitLobbyVoiceRoom();
		end
	end

end

--断线重连
function TeamUpSystem.ReconnectFetchTeamUpInfo()
	--清空模型相关
	TeamUpSystem.ChangeMemberInfo = {};
	--请求自己队伍信息 和同步下组队限时开放	
	TeamUpSystem.team_info_request();		
	TeamUpSystem.on_mode_shield_req();

	--同步下好友状态
	FriendSystem.batchGetTeamInfoList();
end

---------------------------------组队限时开放逻辑------------------
function TeamUpSystem.GetShieldByType(modelType)
	--log_tree("GetShieldByType",TeamUpSystem.ModeShields);
	if TeamUpSystem.ModeShields ~= nil then
		return TeamUpSystem.ModeShields[modelType];
	end
	
	return nil;
end

function TeamUpSystem.on_mode_shield_req()
	--登录断线重连的时候会请求一次，点击切换模式会请求一次,选择模式失败也请求一次
	log("on_mode_shield_req ");	
	--NetUtil.SendPriorityPkg(true, "team_quit_respond", "team_quit_request", teamid);	
	NetUtil.SendPkg("get_mode_shield_req");
end

function TeamUpSystem.on_mode_shield_rsp(mode_shields)
	--[[
	mode_shields:	
	   ├─ 101
	   │  ├─ open_end: 0
	   │  ├─ is_shield: true
	   │  └─ open_begin: 0
	   ├─ 102
	   │  ├─ open_end: 1514304000
	   │  ├─ is_shield: true
	   │  └─ open_begin: 1513526400
	   └─ 103
		  ├─ open_end: 0
		  ├─ is_shield: true
		  └─ open_begin: 1513612800
	--]]
	log_tree("on_mode_shield_rsp",mode_shields);
	if mode_shields ~= nil then
		TeamUpSystem.ModeShields = mode_shields;
		--test
		--TeamUpSystem.testShieldData( );
		--更新组队模式菜单
		TeamUpUI.SetShieldLock();
	end
end

function TeamUpSystem.testShieldData( )
	local  mode_shields = 
	{
		[101] = {open_end = 0, is_shield = false, open_begin = 0};
		[102] = {open_end = 1514304000, is_shield = true, open_begin = 1513526400};
		[103] = {open_end = 0, is_shield = true, open_begin = 1513612800};

	}
	TeamUpSystem.ModeShields = mode_shields;
end

function TeamUpSystem.on_change_type_rsp(res)
	log("on_change_type_rsp faild"..res);
	if res ~= "ok" then
		TeamUpSystem.on_mode_shield_req();
	end 
end

function TeamUpSystem.on_change_leader_rsp( new_leader, res)
	if res == "member-offline" then
		--提示“对方已离线，不能任命队长”。后台返回 TODO
		DataMgr.ShowNoticeByID(110065);

	end
end

--返回预留teamid,用于平台邀请
function TeamUpSystem.on_plat_get_teamid_rsp(res,team_id,battle_id)
	log("on_plat_get_teamid_rsp "..team_id.. "  " .. battle_id);
	--[[
		team_is_full
		already_in_match
		already_in_game
	]]
	if res == "ok" then
		if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
			ShareMgr:InviteJoinTeamWX(team_id, battle_id);
		elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
			ShareMgr:InviteJoinTeamQQ(team_id);
		end
	elseif res == "team_is_full" then		
		DataMgr.ShowNoticeByID(110007);
		--PopUpNoticeUI.ShowMessageBox("提示", "邀请失败，队伍人数已满。");
	elseif res == "already_in_match" then
		DataMgr.ShowNoticeByID(110059);----%s在匹配中
	elseif res == "already_in_game" then
		DataMgr.ShowNoticeByID(9911106);----游戏中
	else
		--team_recruit_for_plat_res("already_in_room")      ---您在房间中，不能邀请组队。
		TeamUpUI.ProtocolErrorCode(res);
	end

end	

--捏脸换性别
function TeamUpSystem.on_team_change_avatar(op_uid, newAvatar)
	log("on_team_change_avatar"..op_uid);
	--log_tree("on_team_change_avatar",newAvatar);
	--newAvatar = {gamegender=0,headid=0,hairid=0}
	TeamUpSystem.ChangeAvatarInfo = {
		reCreate = NeedReCreatPalyer(op_uid,newAvatar), --是否重新创建
		uid = op_uid,
		avatar = newAvatar,
	};
	--同步下数据，用于断线重连	
	local _info = TeamUpSystem.GetMemberInfo(op_uid);
	if _info ~= nil then
		--更新
		_info.avatar = newAvatar;
		_info.gender = newAvatar.gamegender;
		EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_CHANGE_AVATAR);	
	end
end

--[[网络回调]]--

s2c["team_invite_respond"] = TeamUpSystem.on_team_invite_respond; --邀请他人

s2c["team_invite_notify"] = TeamUpSystem.on_team_invite_notify; --收到组队邀请

s2c["team_quit_respond"] = TeamUpSystem.on_team_quit_respond;  --退出队伍

s2c["team_apply_respond"] = TeamUpSystem.on_team_apply_respond; -- 申请入队

s2c["team_apply_notify"] = TeamUpSystem.on_team_apply_notify; --队长收到入队申请

s2c["team_info_sync"] = TeamUpSystem.on_team_info_sync; --同步当前队伍信息

s2c["team_kick_respond"] = TeamUpSystem.on_team_kick_respond; --踢人

s2c["query_myid_respond"] = TeamUpSystem.on_query_myid_respond; --查询我得GID

s2c["team_info_notify"] = TeamUpSystem.on_team_info_change_notify; --队伍信息变动

s2c["team_change_wear"] = TeamUpSystem.on_team_change_wear; --队伍换装通知

s2c["team_join_respond"] =  TeamUpSystem.on_team_join_rsp -- 用于招募队员加入错误信息返回

s2c["team_recruit_rsp"] =  TeamUpSystem.team_recruit_rsp; --招募消息时间限制

s2c["get_mode_shield_rsp"] =  TeamUpSystem.on_mode_shield_rsp -- 限时组队开放

s2c["team_change_type_respond"] = TeamUpSystem.on_change_type_rsp; -- 主要用于限时组队开放，选择模式失败重新拉下开放数据

s2c["team_change_leader_respond"] = TeamUpSystem.on_change_leader_rsp;  --只处理点离线队员的“转让队长”按钮，提示“对方已离线，不能任命队长”

--平台邀请组队
--[[
c2s.team_recruit_for_plat_req( )
s2c.team_recruit_for_plat_res( res，team_id)
--]]
s2c["team_recruit_for_plat_res"] = TeamUpSystem.on_plat_get_teamid_rsp; --申请teamid返回，用于平台邀请
s2c["team_change_avatar"] = TeamUpSystem.on_team_change_avatar; --队伍捏脸通知






-----------------intl start-------------------

--请求服务器大区列表
function TeamUpSystem.query_match_zone_list_req()
    log("query_match_zone_list_req");
    NetUtil.SendPkg("query_match_zone_list");
    --NetUtil.SendPriorityPkg(true, "sync_match_zone_list", "query_match_zone_list");
end

--服务器下发服务器大区列表
function TeamUpSystem.sync_match_zone_list_rsp(tpingsvr_tab)
    log("sync_match_zone_list_rsp");
    TeamUpSystem.SaveZoneListInfo(tpingsvr_tab);
    DataMgr.SyncZoneList(tpingsvr_tab);
    EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_INTL_ZONELIST_RSP);
end

function TeamUpSystem.SaveZoneListInfo(tpingsvr_tab)
    TeamUpSystem.ChooseZoneList = {};
    table.sort(tpingsvr_tab, function(a, b) return a.zone_id < b.zone_id end)
    
    log("TeamUpSystem.SaveZoneListInfo count: "..#tpingsvr_tab)
	if(tpingsvr_tab ~= null) then
		for k,v in pairs(tpingsvr_tab) do
			local zoneinfo =
			{
				zone_id = v.zone_id,
				tpingsvr_ip = v.tpingsvr_ip,
                tpingsvr_port = v.tpingsvr_port

			};
            --log("TeamUpSystem.SaveZoneListInfo: zoneinfo.zone_id = "..tostring(zoneinfo.zone_id) .."tpingsvr_ip = "..zoneinfo.tpingsvr_ip .."tpingsvr_port = "..zoneinfo.tpingsvr_port);
			table.insert(TeamUpSystem.ChooseZoneList, zoneinfo);
		end
	end
--[[
    local zoneinfoTest1 =
			{
				zone_id = 3,
				tpingsvr_ip = "100.226.129.164",
                tpingsvr_port = "10199"

			};
    table.insert(TeamUpSystem.ChooseZoneList, zoneinfoTest1);

    local zoneinfoTest2 =
			{
				zone_id = 3,
				tpingsvr_ip = "100.112.20.95",
                tpingsvr_port = "9030"

			};

    table.insert(TeamUpSystem.ChooseZoneList, zoneinfoTest2);
--]]
    log_tree("---TeamUpSystem.ChooseZoneList",TeamUpSystem.ChooseZoneList);
end

--选择匹配大区请求
function TeamUpSystem.on_select_zone_req(match_zone)
    log("on_select_zone_req,match_zone = "..match_zone);
    NetUtil.SendPkg("on_select_zone_req", match_zone);
    --NetUtil.SendPriorityPkg(true, "on_select_zone_res", "on_select_zone_req",match_zone);
end

--选择匹配大区回复
--ret:
----"ok" -->成功
----"nil zone" --> 没有传递zone
----"invalid zone" --> 所选zone不存在
----"player_matching" --> 匹配中不能选择zone
----"not-leader" --> 不是队长
-- match_zone:匹配大区id
function TeamUpSystem.on_select_zone_rsp(ret, match_zone)
    log("on_select_zone_res, ret = "..ret..", match_zone = "..match_zone);
    if(string.lower(ret)=="ok") then
        TeamUpSystem.ChooseZoneId = match_zone;
        LobbySystem.matchZone = match_zone;

    elseif (string.lower(ret)=="nil zone" or string.lower(ret)=="invalid zone") then
        textMsg =  Client.GetTableData("LocalizeRes", "1012").TextValue; --所选区不存在
        DataMgr.ShowNoticeByString(textMsg);
    elseif (string.lower(ret)=="player_matching") then
        textMsg =  Client.GetTableData("LocalizeRes", "1013").TextValue; --当前为匹配状态，停止匹配才能进行选区操作
        DataMgr.ShowNoticeByString(textMsg);
    elseif (string.lower(ret)=="not-leader") then
        textMsg =  Client.GetTableData("LocalizeRes", "1014").TextValue; --当前处于队伍中，只有队长才能选区
        DataMgr.ShowNoticeByString(textMsg);
    end
    EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_INTL_SELECT_ZONE_RSP, string.lower(ret));
end

--队伍匹配大区变更通知广播
-- teamid:integer 队伍id
-- match_zone:integer 匹配大区id
function TeamUpSystem.team_match_zone_notify( match_zone)
    log("team_match_zone_notify, match_zone = "..match_zone);
    TeamUpSystem.ChooseZoneId = match_zone;
    LobbySystem.matchZone = match_zone;
    EventSystem:postEvent(EVENTTYPE_TEAMUP, EVENTID_INTL_MATCH_ZONE_NOTIFY);
end



s2c["on_select_zone_res"] = TeamUpSystem.on_select_zone_rsp;
s2c["sync_match_zone_list"] = TeamUpSystem.sync_match_zone_list_rsp;
s2c["team_match_zone_notify"] = TeamUpSystem.team_match_zone_notify;
-----------------intl end-------------------