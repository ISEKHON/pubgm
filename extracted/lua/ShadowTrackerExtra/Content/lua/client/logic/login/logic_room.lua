--[[
  房间的相关逻辑
]]--

RoomSystem =  RoomSystem or {
	RoomInfoList = {},
	
	CurrentRoomInfo = {},
	QRCodeRoomInfo = {},
	SelectRoomId = 0,
}

IsRoomToBattle = false;
RoomDisbandReason = "";

function RoomSystem.isRoomOwner()
	if  RoomSystem.CurrentRoomInfo == nil then
		return false;
	end

	if RoomSystem.CurrentRoomInfo.owner_id == DataMgr.roleData.uid then
		return true;
	else
		return false;
	end
end


function RoomSystem.Enter()
	log("RoomSystem Enter");
	
	RoomSystem.RoomInfoList = {};
	RoomSystem.CurrentRoomInfo = {};
	RoomSystem.SelectRoomId = 0;

	RoomSystem.req_room_list();
	RoomSystem.isEnterRoomGettingRoomList = true;
end


function RoomSystem.Release()
	log("RoomSystem Release");
	RoomSystem.RoomInfoList = {};
	RoomSystem.CurrentRoomInfo = {};
	RoomSystem.SelectRoomId = 0;
end

function RoomSystem.BeKicked()
	log("RoomSystem BeKicked");

	--清空房间
	RoomSystem.CurrentRoomInfo = {};

	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	--提示被移出房间
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	if curStatus == "lobby" then
		if BP_Room_InitiativeLeave == false then
			local title_data = Client.GetTableData("LocalizeRes", 101001);
			local title = tostring(title_data.TextValue);
			local msg_data = Client.GetTableData("LocalizeRes", 110085);
			local msg = tostring(msg_data.TextValue);
			CommonMessageBoxUI:ShowPanel(1, title, msg);
		else
			BP_Room_InitiativeLeave = false;
		end
	end
	
	--退出房间
	BP_Room_InitiativeLeave = false;
	BP_Room_IsInRoom = false;
	LuaClassObj.HandleUIMessage(bp_room_waiting, "LeaveRoom");
	
	if curStatus == "lobby" then
		--刷新下当前的房间列表
		RoomSystem.req_room_list();
	end
end

--生成QQ房间邀请二维码
function RoomSystem.InviteJoinRoomQQ(roomid, roompw)
	log("RoomSystem InviteJoinRoomQQ")
	local strUrl = RoomSystem.ConstructQRImageURL(roomid, roompw);	
	local strlogoPath = "Arts/UI/TableIcons/ShareBg/Share_Icon.jpg";
	log(strUrl);
	Client.GenerateQRImage(NetInterface, 1, 250, strUrl, strlogoPath);
end

--QQ房间二维码生产成功
function RoomSystem.OnGenQRImgNotify(tag, ret, imgPath)
	log("RoomSystem OnGenQRImgNotify");
	log("imgPath = "..imgPath);
	if ret == 0 then
		RoomWaitingUI.SetQRImagePath(tostring(imgPath));
		LuaClassObj.HandleUIMessage(bp_room_waiting, "ShowQRUI");
	else
		log("Create QRImage Error!");
	end
end

function RoomSystem.ConstructQRImageURL(roomid, roompw)
	log("RoomSystem ConstructQRImageURL");
	return "http://app.gcloud.qq.com/apolloapp/api/v1/get_app_path?appid=418021106&data=rmid:" .. roomid .. ",rmpw:".. roompw .. ",t:" .. math.floor(os.time() / 60);
end

function RoomSystem.OnLoadStartGameFailed()
	log("RoomSystem OnLoadStartGameFailed");
	-- LoadingUI:Hide();
	LoadingUI.RefreshLoadPercent(1);
	Client.ReturnToLobby(GameFrontendHUD);
end

function RoomSystem.GetProfileAfterJoinRoom(listinfo)
	log("RoomSystem GetProfileAfterJoinRoom");
	
	for k,v in pairs(listinfo) do
		for kk,vv in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
			if tonumber(v.uid) == tonumber(vv.openid) then
				if tonumber(v.uid) == tonumber(DataMgr.roleData.uid) then
					vv["head_url"] = DataMgr.roleData.headIconUrl;
					vv["gender"] = DataMgr.roleData.gender;
					vv["frame_level"] = DataMgr.roleData.cur_avatar_box_id;
				else
					vv["head_url"] = v.picUrl;
					vv["gender"] = v.sex;
					vv["frame_level"] = v.cur_avatar_box_id;
				end
				break;
			end
		end
	end
	
	RoomWaitingUI:Init();
	
	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	LuaClassObj.HandleUIMessage(bp_room, "ClosePSWUIAfterEnterRoom");
	LuaClassObj.HandleUIMessage(bp_room_waiting, "EnterRoom");
end

function RoomSystem.GetProfileAfterSync(listinfo)
	log("RoomSystem GetProfileAfterSync");
	
	for k,v in pairs(listinfo) do
		for kk,vv in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
			if tonumber(v.uid) == tonumber(vv.openid) then
				if tonumber(v.uid) == tonumber(DataMgr.roleData.uid) then
					vv["head_url"] = DataMgr.roleData.headIconUrl;
					vv["gender"] = DataMgr.roleData.gender;
					vv["frame_level"] = DataMgr.roleData.cur_avatar_box_id;
				else
					vv["head_url"] = v.picUrl;
					vv["gender"] = v.sex;
					vv["frame_level"] = v.cur_avatar_box_id;
				end
				break;
			end
		end
	end
	
	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	log_tree("sync_room_member, updated:", BP_ARRAY_RoomMemberList);

	--更新UI
	LuaClassObj.HandleUIMessage(bp_room_waiting, "RefreshMemberList");
end

function RoomSystem.GetProfileAfterOffline(listinfo)
	log("RoomSystem GetProfileAfterOffline");
	
	for k,v in pairs(listinfo) do
		for kk,vv in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
			if tonumber(v.uid) == tonumber(vv.openid) then
				if tonumber(v.uid) == tonumber(DataMgr.roleData.uid) then
					vv["head_url"] = DataMgr.roleData.headIconUrl;
					vv["gender"] = DataMgr.roleData.gender;
					vv["frame_level"] = DataMgr.roleData.cur_avatar_box_id;
				else
					vv["head_url"] = v.picUrl;
					vv["gender"] = v.sex;
					vv["frame_level"] = v.cur_avatar_box_id;
				end
				break;
			end
		end
	end
	
	RoomSystem.isEnterRoomGettingRoomList = false;
	RoomWaitingUI:Init();
	
	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	LuaClassObj.HandleUIMessage(bp_room, "RoomShow");
	LuaClassObj.HandleUIMessage(bp_room_waiting, "EnterRoom");
end







--请求创建房间
function RoomSystem.req_create_room(_roomName, _mapID, _roomMode, _passWd)
	log("create_room_request " .. _roomName .. " mapid:" .. _mapID .. "mode".._roomMode.." passwd:" .. _passWd);
	if _passWd == "" then
		NetUtil.SendPkg("create_room_request", _roomName, _mapID, "", _roomMode);
	else
		NetUtil.SendPkg("create_room_request", _roomName, _mapID, _passWd, _roomMode);
	end
end


--请求房间列表
function RoomSystem.req_room_list()
	log("query_room_list");
	--NetUtil.SendPkg("query_room_list", 1, 100);	
    NetUtil.SendPriorityPkg(true, "sync_room_list", "query_room_list",1, 100);
end


--请求进入房间
function RoomSystem.req_join_room(_roomID, _passWd)
	if _roomID == nil then
		return;
	end
	log("_roomID = ".._roomID);
	NetUtil.SendPkg("join_room_request", _roomID, _passWd);
end


--请求退出房间
function RoomSystem.req_exit_room()
	log("exit_room:" .. DataMgr.roleData.uid);
	NetUtil.SendPkg("exit_room", tonumber(DataMgr.roleData.uid));
end

--请求开始游戏
function RoomSystem.req_start_game()
	log("start_game_request");
	NetUtil.SendPkg("start_game_request");
end

--请求更换位置
function RoomSystem.req_change_room_pos_request(room_id, new_pos)
	log("req_change_room_pos_request: room_id = "..room_id.."new_pos == "..new_pos);
	
	if RoomSystem.CurrentRoomInfo == nil then
		return;
	end
	NetUtil.SendPkg("change_room_pos_request", RoomSystem.CurrentRoomInfo.id, new_pos);
end

--请求踢人
function  RoomSystem.req_room_kick_request(room_id,  kick_id)
	log("req_room_kick_request: room_id = "..room_id.."kick_id == "..kick_id);
	if not RoomSystem.isRoomOwner() then
		return;
	end
	if BP_STRUCT_RoomWaitingInfo == nil then
		return;		
	end
	NetUtil.SendPkg("room_kick_request", RoomSystem.CurrentRoomInfo.id, kick_id);
end

--房间内修改房间名
function RoomSystem.req_change_room_name(room_id, name)
	log("req_change_room_name: room_id = "..room_id.." name = "..name);
	NetUtil.SendPkg("change_room_name_request", room_id, name);
end

--房间内请求修改房间模式
function RoomSystem.req_change_room_group_type(room_id, group_type)
	log("req_change_room_group_type: room_id = "..room_id.." group_type = "..group_type);
	NetUtil.SendPkg("change_room_group_type_request", room_id, group_type);
end

--房间内请求修改地图
function RoomSystem.req_change_room_map(room_id, map_id)
	log("req_change_room_map: room_id = "..room_id.." map_id = "..map_id);
	NetUtil.SendPkg("change_room_map_request", room_id, map_id);
end

--ID查询某个房间
function RoomSystem.req_query_one_room(room_id)
	log("req_query_one_room: room_id = "..room_id);
	NetUtil.SendPkg("query_room_request", room_id);
end

--加入房间请求概要信息
function RoomSystem.req_profile_join_room()
	log("RoomSystem req_profile_join_room");
	
	local listUid = {};
	for k,v in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
		table.insert(listUid, tonumber(v.openid));
	end
	
	ProfileMgr.GetProfileList(listUid, RoomSystem.GetProfileAfterJoinRoom);
end

--同步信息请求概要信息
function RoomSystem.req_profile_sync_room()
	log("RoomSystem req_profile_sync_room");
	
	local listUid = {};
	for k,v in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
		table.insert(listUid, tonumber(v.openid));
	end
	
	ProfileMgr.GetProfileList(listUid, RoomSystem.GetProfileAfterSync);
end

--短线重连请求概要信息
function RoomSystem.req_profile_info_offline_room()
	log("RoomSystem req_profile_info_offline_room");
	
	local listUid = {};
	for k,v in pairs(RoomSystem.CurrentRoomInfo.MemberInfoList) do
		table.insert(listUid, tonumber(v.openid));
	end
	
	ProfileMgr.GetProfileList(listUid, RoomSystem.GetProfileAfterOffline);
end









--创建房间响应
function RoomSystem.on_create_room_respond(res, room_info)
	log("create_room_respond " .. res);
	log_tree("roominfo", room_info);
	
	if res ~= 0 then
		sandbox.LogNormal("create_room_respond failed ");
		DataMgr.ShowNoticeByID(res);
		return;
	end
	
	BattleResult.IgnoreDSError = false;

	--调刷新房间
	RoomSystem.CurrentRoomInfo = room_info;

	RoomSystem.CurrentRoomInfo.IsRoomOwner = true;
	RoomSystem.CurrentRoomInfo.owner_id = tostring(RoomSystem.CurrentRoomInfo.owner_id);

	RoomSystem.CurrentRoomInfo.MemberInfoList = {};
	--把自己加入成员列表
	table.insert(RoomSystem.CurrentRoomInfo.MemberInfoList, 
	{
	  openid = DataMgr.roleData.uid,
	  name = DataMgr.roleData.nickName,
	  level = DataMgr.roleData.level,
	  svr = 0,
	  isRoomMaster = true,
	  pos = 1,
	  state = "idle",
	  head_url = DataMgr.roleData.headIconUrl,
	  gender = DataMgr.roleData.gender,
	  frame_level = DataMgr.roleData.cur_avatar_box_id,
	}
	);
	
	RoomWaitingUI:Init();
	BP_Room_Passwd = BP_CreateRoom_Passwd;

	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);

	--刷新UI
	LuaClassObj.HandleUIMessage(bp_room, "CreateRoomUIHide");
	LuaClassObj.HandleUIMessage(bp_room_waiting, "EnterRoom");
end


--请求房间响应
function RoomSystem.on_sync_room_list(view, pos, total)	
	if view == nil then
		return;
	end
	log("sync_room_list " .. #view);

	RoomSystem.RoomInfoList = {};

	for _roomIndex = pos, pos+total do
		table.insert(RoomSystem.RoomInfoList, view[_roomIndex]);
	end
	log_tree("view =",view);
	
	local IdleRoomList = {};
	local GamingRoomList = {};
	local SortRoomList = {};
	for i,v in ipairs(RoomSystem.RoomInfoList) do
		v.owner_id = tostring(v.owner_id);
		if v.state == "idle" then
			table.insert(IdleRoomList, v);
		elseif v.state == "gaming" then
			local cur_time = os.time();
			local start_time = v.game_start;
			v.game_start = math.ceil( (cur_time-start_time)/60 );
			table.insert(GamingRoomList, v);
		end
	end
    
	table.sort( IdleRoomList, function(a,b) return a.create_time > b.create_time; end );
	table.sort( GamingRoomList, function(a,b) return a.create_time > b.create_time; end );
	
	for i,v in ipairs(IdleRoomList) do
		table.insert(SortRoomList, v);
	end
	for i,v in ipairs(GamingRoomList) do
		table.insert(SortRoomList, v);
	end
	
	RoomSystem.RoomInfoList = SortRoomList;
	log_tree("RoomSystem.RoomInfoList =",RoomSystem.RoomInfoList);

	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);

	if RoomSystem.IsQuickJoin then
		--快速加入房间
		if #RoomSystem.RoomInfoList > 0 then
			log("quick join room, lucky for aready room list, request join!");
			RoomSystem.req_join_room(RoomSystem.RoomInfoList[1].id);
		else
			log("quick join room, bad lucky for no room list, show create room!");
			LuaClassObj.HandleUIMessage(bp_room, "ShowCreateRoom");
		end
		RoomSystem.IsQuickJoin = false;
	elseif RoomSystem.isEnterRoomGettingRoomList then
		--大厅进入房间
		LuaClassObj.HandleUIMessage(bp_room, "RoomShow");
		LuaClassObj.HandleUIMessage(bp_room, "RefreshRoomList");  
		RoomSystem.isEnterRoomGettingRoomList = false;
	else
		--其他拉取列表
		LuaClassObj.HandleUIMessage(bp_room, "RefreshRoomList");
	end
  
end

--加入房间响应
function RoomSystem.on_join_room_respond(res, base_info, members)
	log("join_room_respond " .. res);
	log_tree("baseinfo", base_info);
	log_tree("room_members", members);
	
	if res ~= 0 then
		sandbox.LogNormal("join_room_respond failed = " .. res);
		if res == 110091 then
			DataMgr.ShowMessageBoxByID(res);
			RoomSystem.req_room_list();
			return;
		end
		
		DataMgr.ShowNoticeByID(res);
        RoomSystem.req_room_list();
		return;
	end
	
	BattleResult.IgnoreDSError = false;

	RoomSystem.CurrentRoomInfo = base_info;
	RoomSystem.CurrentRoomInfo.owner_id = tostring(RoomSystem.CurrentRoomInfo.owner_id);
	
	RoomSystem.CurrentRoomInfo.MemberInfoList = {};
	for k, v in pairs(members) do
		local tmp = v;
		tmp.openid = tostring(k);
		tmp.isRoomMaster = (RoomSystem.CurrentRoomInfo.owner_id == tmp.openid);
		table.insert(RoomSystem.CurrentRoomInfo.MemberInfoList, tmp);
	end
	
	RoomSystem.req_profile_join_room();

	-- --更新房间蓝图数据
	-- EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	-- LuaClassObj.HandleUIMessage(bp_room, "ClosePSWUIAfterEnterRoom");
	-- LuaClassObj.HandleUIMessage(bp_room_waiting, "EnterRoom");
end

--房间状态
function RoomSystem.on_sync_room_state(state)
	log_tree("sync_room_state", state);

	RoomSystem.CurrentRoomInfo.state = state;

	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
end


--房间解散
function RoomSystem.on_room_disband(room_id, reason)
	log("on_room_disband ");
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	if curStatus == "lobby" then
		log("lobby on_room_disband ");
		if reason == "owner-exit" then
			if not RoomSystem.isRoomOwner() then
				local title_data = Client.GetTableData("LocalizeRes", 101001);
				local title = tostring(title_data.TextValue);
				local msg_data = Client.GetTableData("LocalizeRes", 110069);
				local msg = tostring(msg_data.TextValue);
				CommonMessageBoxUI:ShowPanel(1, title, msg);
				RoomDisbandReason = "owner-exit";
			end
		elseif reason == "owner-offline" then
			local title_data = Client.GetTableData("LocalizeRes", 101001);
			local title = tostring(title_data.TextValue);
			local msg_data = Client.GetTableData("LocalizeRes", 110073);
			local msg = tostring(msg_data.TextValue);
			CommonMessageBoxUI:ShowPanel(1, title, msg);
			RoomDisbandReason = "owner-offline";
		elseif reason == "version-not-same" then
		elseif reason == "game-over" then
			local title_data = Client.GetTableData("LocalizeRes", 101001);
			local title = tostring(title_data.TextValue);
			local msg_data = Client.GetTableData("LocalizeRes", 110127);
			local msg = tostring(msg_data.TextValue);
			CommonMessageBoxUI:ShowPanel(1, title, msg);
			RoomDisbandReason = "game-over";
			
			RoomSystem.CurrentRoomInfo = {};
			EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
			
			BP_Room_InitiativeLeave = false;
			BP_Room_IsInRoom = false;
			LuaClassObj.HandleUIMessage(bp_room_waiting, "LeaveRoom");
			
			RoomSystem.Enter();
			RoomUI:Init();
			
			return
		end
	else
		log("fighting on_room_disband ");
		if reason == "owner-exit" then
			if not RoomSystem.isRoomOwner() then
				RoomDisbandReason = "owner-exit";
			end
		elseif reason == "owner-offline" then
			RoomDisbandReason = "owner-offline";
		elseif reason == "version-not-same" then
		elseif reason == "game-over" then
			RoomDisbandReason = "game-over";
		end
	end

	--清空房间
	RoomSystem.CurrentRoomInfo = {};

	--更新房间蓝图数据
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	--退出房间
	BP_Room_InitiativeLeave = false;
	BP_Room_IsInRoom = false;
	LuaClassObj.HandleUIMessage(bp_room_waiting, "LeaveRoom");
	
	if curStatus == "lobby" then
		--刷新下当前的房间列表
		RoomSystem.req_room_list();
	end
end


--同步房间的玩家信息
function RoomSystem.on_sync_room_member(id, info)
	log_tree("sync_room_member, openid=" .. id, info);
	if RoomSystem.CurrentRoomInfo == nil then
		return;
	end

	if RoomSystem.CurrentRoomInfo.MemberInfoList == nil then
		RoomSystem.CurrentRoomInfo.MemberInfoList = {};
	end
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	if curStatus ~= "lobby" then
		log("Not lobby on_sync_room_member ");
		return;
	end
	
	id = tostring(id);
	local isLeaveRoomSync = false;
	
	--离开房间同步
	if info == nil then
		log("sync_room_member, delete member id = "..id);
		isLeaveRoomSync = true;
		--删除当前房间中的玩家
		for _memberIndex = 1, #RoomSystem.CurrentRoomInfo.MemberInfoList do
			if RoomSystem.CurrentRoomInfo.MemberInfoList[_memberIndex].openid == id then
				table.remove(RoomSystem.CurrentRoomInfo.MemberInfoList, _memberIndex);
				break;
			end
		end
		
		if id == DataMgr.roleData.uid then --踢人
			RoomSystem.BeKicked();
			return;
		end
	--增加或者更新玩家信息
	else
		local tmp = info;
		tmp.openid = id;
		tmp.isRoomMaster = (RoomSystem.CurrentRoomInfo.owner_id == id);
		
		local isInRoomMemberInfoList = false;	--玩家是否在房间中
		for _memberIndex = 1, #RoomSystem.CurrentRoomInfo.MemberInfoList do		
			if RoomSystem.CurrentRoomInfo.MemberInfoList[_memberIndex].openid == id then
				RoomSystem.CurrentRoomInfo.MemberInfoList[_memberIndex] = tmp;
				isInRoomMemberInfoList = true;
				break;
			end
		end
		if not isInRoomMemberInfoList then
			log("not found in roomm member list");
			table.insert(RoomSystem.CurrentRoomInfo.MemberInfoList, tmp);
		end
	end
	
	if not isLeaveRoomSync then
		RoomSystem.req_profile_sync_room();
	else
		--更新房间蓝图数据
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		log_tree("sync_room_member, updated:", BP_ARRAY_RoomMemberList);

		--更新UI
		LuaClassObj.HandleUIMessage(bp_room_waiting, "RefreshMemberList");
	end
end

--更换位置回调
function RoomSystem.on_change_room_pos_respond(res,  new_pos)
	log("on change room pos respond");
	
	if res ~= 0 then
		log("change room pos failed");
		log("res: "..res);
		DataMgr.ShowNoticeByID(res);
		return;
	end
	
	if RoomSystem.CurrentRoomInfo == nil then
		return;
	end
	
	--找到自己
	local isFoundOpenId = false;
	for _memberIndex = 1, #RoomSystem.CurrentRoomInfo.MemberInfoList do
		if RoomSystem.CurrentRoomInfo.MemberInfoList[_memberIndex].openid == DataMgr.roleData.uid then
			RoomSystem.CurrentRoomInfo.MemberInfoList[_memberIndex].pos = new_pos;
			isFoundOpenId = true;
			break;
		end
	end
	if isFoundOpenId then
		log("not found openID = "..DataMgr.roleData.uid);
	end
	LuaClassObj.HandleUIMessage(bp_room_waiting, "SetMyOldTeamBGEmpty");
	EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
end

--踢人回调
function RoomSystem.on_room_kick_respond(res,  kick_id)
	log("on room kick respond res = "..res);
	if res ~= 0 then
		log("room kick failed");
		DataMgr.ShowNoticeByID(res);
		return;
	end
	log("memberID = "..kick_id.." was kicked by room owner");
end

--通知进入游戏
function RoomSystem.on_notify_enter_game(ip, port, key)
	sandbox.LogNormal("notify_enter_game " .. ip .. ":" .. port .. ",key=" .. key);
end

--开始游戏结果
function RoomSystem.on_start_game_respond(res)
	log("start_game_respond " .. res);
	if res ~= 0 then
		log("start game failed");
		DataMgr.ShowNoticeByID(res);
		return;
	end
end

g_game_id = 0;

--正式进入游戏
function RoomSystem.on_enter_game(ip, port, key, packet_key,game_id)
	log("enter_game: " .. ip .. ":" .. port .. " key=" .. key);
    log("game_id " .. game_id);
    BattleResult.IgnoreDSError = false;
    g_game_id = game_id;

	--切换到战斗场景
	NetUtil.EnterBattle(ip, port, key, DataMgr.roleData.nickName, packet_key, game_id);
	LobbySystem.ResetMatchInfo();
	ProfileMgr.ClearStrangerProfileList();
	Client.JoinLbsVoiceRoom(GameFrontendHUD, game_id, DataMgr.roleData.openID);
end

--房间内修改房间名响应
function RoomSystem.on_change_room_name_request(res, room_id, name)
	log("change_room_name_request");
	log("room_id = "..room_id);
	log("name = "..name);
	
	if res ~= 0 then
		DataMgr.ShowNoticeByID(res);
		return;
	end
	
	DataMgr.ShowNoticeByID(110100);
end

--房间内修改房间模式
function RoomSystem.on_change_room_group_type_respond(res, room_id, group_type)
	log("change_room_group_type_respond res = "..res);
	log("room_id = "..room_id);
	log("group_type = "..group_type);
	
	if res ~= 0 then
		DataMgr.ShowNoticeByID(res);
		return;
	end
end

--房间内修改地图
function RoomSystem.on_change_room_map_respond(res, room_id, map_id)
	log("change_room_map_respond res = "..res);
	log("room_id = "..room_id);
	log("map_id = "..map_id);
	
	if res ~= 0 then
		DataMgr.ShowNoticeByID(res);
		return;
	end
	
	DataMgr.ShowNoticeByID(110097);
end

--房间信息变更通知	opt: 1-变更房间名 2-变更地图id 3-变更房间模式
function RoomSystem.on_room_info_notify(room_id, opt, param)
	log("room_info_notify");
	log("room_id = "..room_id);
	log("opt = "..opt);
	log("param = "..param);
	
	if opt == 1 then
		RoomSystem.CurrentRoomInfo.name = param;
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		LuaClassObj.HandleUIMessage(bp_room_waiting, "UpdateRoomName");
	elseif opt == 2 then
		RoomSystem.CurrentRoomInfo.map_id = param;
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		LuaClassObj.HandleUIMessage(bp_room_waiting, "UpdateRoomMapType");
	elseif opt == 3 then
		RoomSystem.CurrentRoomInfo.group_type = param;
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		LuaClassObj.HandleUIMessage(bp_room_waiting, "UpdateRoomGroupType");
		LuaClassObj.HandleUIMessage(bp_room_waiting, "SetAllTeamBGEmpty");
		LuaClassObj.HandleUIMessage(bp_room_waiting, "RefreshMemberList");
	else
		log("room_info_notify Error!");
	end
end

--ID查询某个房间响应
function RoomSystem.on_query_room_respond(res, room_id, room)
	log("query_room_respond");
	log("room_id = "..room_id);
	log_tree("room =", room);
	
	if res ~= 0 then
		DataMgr.ShowNoticeByID(res);
		RoomSystem.req_room_list();
		return;
	end
	
	local isMatch = FuncUtil:IsMatchVersion(room.version);
	if isMatch == false then
		DataMgr.ShowMessageBoxByID(110091);
		RoomSystem.req_room_list();
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_room, "ShowEnterRoomPSWUI");
end

--断线重连时同步房间信息
function RoomSystem.on_sync_room_info(room, members)
	log("sync_room_info");
	log_tree("room =", room);
	log_tree("members =", members);
	
	if room == nil then
		log("no_room_info");
		local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
		if curStatus == "lobby" then
			log("Lobby State");
			--客户端房间状态还存在（实际不存在  1.未开始战斗被解散了 2.这场战斗结束而自动解散）
			if BP_Room_IsInRoom == true then
				log("Lobby BP_Room_IsInRoom LeaveRoom");
				--清空房间
				RoomSystem.CurrentRoomInfo = {};
				--更新房间蓝图数据
				EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
				--离开房间
				BP_Room_InitiativeLeave = false;
				BP_Room_IsInRoom = false;
				LuaClassObj.HandleUIMessage(bp_room_waiting, "LeaveRoom");
				--从战斗退回
				if IsRoomToBattle == true then
					log("IsRoomToBattle");
					IsRoomToBattle = false;
					RoomSystem.Enter();
					RoomUI:Init();
					
					local title_data = Client.GetTableData("LocalizeRes", 101001);
					local title = tostring(title_data.TextValue);
					local msg_data = "";
					if RoomDisbandReason == "owner-exit" then
						msg_data = Client.GetTableData("LocalizeRes", 110069);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					elseif RoomDisbandReason == "owner-offline" then
						msg_data = Client.GetTableData("LocalizeRes", 110073);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					elseif RoomDisbandReason == "game-over" then
						msg_data = Client.GetTableData("LocalizeRes", 110127);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					end
					RoomDisbandReason = "";
					
					return;
				end
				--刷新下当前的房间列表
				RoomSystem.req_room_list();
			--客户端房间状态不存在（1.战斗中房间已被解散  2.不是房间进的战斗）
			else
				log("Lobby Not BP_Room_IsInRoom LeaveRoom");
				if IsRoomToBattle == true then
					log("IsRoomToBattle");
					IsRoomToBattle = false;
					BP_Room_InitiativeLeave = false;
					BP_Room_IsInRoom = false;
					RoomSystem.Enter();
					RoomUI:Init();
					
					local title_data = Client.GetTableData("LocalizeRes", 101001);
					local title = tostring(title_data.TextValue);
					local msg_data = "";
					if RoomDisbandReason == "owner-exit" then
						msg_data = Client.GetTableData("LocalizeRes", 110069);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					elseif RoomDisbandReason == "owner-offline" then
						msg_data = Client.GetTableData("LocalizeRes", 110073);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					elseif RoomDisbandReason == "game-over" then
						msg_data = Client.GetTableData("LocalizeRes", 110127);
						local msg = tostring(msg_data.TextValue);
						CommonMessageBoxUI:ShowPanel(1, title, msg);
					end
					RoomDisbandReason = "";
				end
			end
		end
		return;
	end
	
	RoomSystem.Enter();
	RoomUI:Init();
	
	BattleResult.IgnoreDSError = false;
	
	RoomSystem.CurrentRoomInfo = room;
	RoomSystem.CurrentRoomInfo.owner_id = tostring(RoomSystem.CurrentRoomInfo.owner_id);
	if RoomSystem.CurrentRoomInfo.password ~= nil then
		BP_CreateRoom_Passwd = RoomSystem.CurrentRoomInfo.password;
		BP_Room_Passwd = RoomSystem.CurrentRoomInfo.password;
		RoomSystem.CurrentRoomInfo.password = nil;
	end
	
	RoomSystem.CurrentRoomInfo.MemberInfoList = {};
	for k, v in pairs(members) do
		local tmp = v;
		tmp.openid = tostring(k);
		tmp.isRoomMaster = (RoomSystem.CurrentRoomInfo.owner_id == tmp.openid);
		table.insert(RoomSystem.CurrentRoomInfo.MemberInfoList, tmp);
	end
	
	for i=1, #RoomSystem.CurrentRoomInfo.MemberInfoList do
		RoomSystem.CurrentRoomInfo.MemberInfoList[i].offline_time = nil;
	end
	
	RoomSystem.req_profile_info_offline_room();

	-- --更新房间蓝图数据
	-- EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
	
	-- RoomSystem.isEnterRoomGettingRoomList = false;
	-- LuaClassObj.HandleUIMessage(bp_room, "RoomShow");
	-- LuaClassObj.HandleUIMessage(bp_room, "EnterRoom");
end

--进入游戏响应
function RoomSystem.on_room_start_game_notify(res)
	log("room_start_game_notify");
	
	if res == "start" then
		RoomSystem.CurrentRoomInfo.state = "gaming";
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		IsRoomToBattle = true;
		BP_LoadingTo = 0;
		LoadingUI:Init();
	elseif res == "load-game-fail" then
		RoomSystem.CurrentRoomInfo.state = "idle";
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		IsRoomToBattle = false;
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		local content = Client.GetTableData("LocalizeRes", "9911109").TextValue;
		CommonMessageBoxUI:ShowPanel(1, title, content, RoomSystem.OnLoadStartGameFailed, nil);
	elseif res == "version-not-support" then
		RoomSystem.CurrentRoomInfo.state = "idle";
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		IsRoomToBattle = false;
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		local content = Client.GetTableData("LocalizeRes", "9911112").TextValue;
		CommonMessageBoxUI:ShowPanel(1, title, content, RoomSystem.OnLoadStartGameFailed, nil);
	else
		RoomSystem.CurrentRoomInfo.state = "idle";
		EventSystem:postEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA);
		IsRoomToBattle = false;
	end
end


--[[网络回调]]--
s2c["create_room_respond"] = RoomSystem.on_create_room_respond;
s2c["sync_room_list"] = RoomSystem.on_sync_room_list;
s2c["join_room_respond"] = RoomSystem.on_join_room_respond;
s2c["sync_room_member"] = RoomSystem.on_sync_room_member;
s2c["sync_room_state"] = RoomSystem.on_sync_room_state;
s2c["room_disband"] = RoomSystem.on_room_disband;
s2c["change_room_pos_respond"] = RoomSystem.on_change_room_pos_respond;
s2c["room_kick_respond"] = RoomSystem.on_room_kick_respond;
s2c["notify_enter_game"] = RoomSystem.on_notify_enter_game;
s2c["start_game_respond"] = RoomSystem.on_start_game_respond;
s2c["enter_game"] = RoomSystem.on_enter_game;
s2c["change_room_name_respond"] = RoomSystem.on_change_room_name_request;
s2c["change_room_group_type_respond"] = RoomSystem.on_change_room_group_type_respond;
s2c["change_room_map_respond"] = RoomSystem.on_change_room_map_respond;
s2c["room_info_notify"] = RoomSystem.on_room_info_notify;
s2c["query_room_respond"] = RoomSystem.on_query_room_respond;
s2c["sync_room_info"] = RoomSystem.on_sync_room_info;
s2c["room_start_game_notify"] = RoomSystem.on_room_start_game_notify;






