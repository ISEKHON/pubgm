LobbyChatroomLogic = LobbyChatroomLogic or 
{
	chatRoomInited = false;
}

function bp_chat_room_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_chat_room,
	{
		{Path="/Game/UMG/UI_Logic/LobbyChat/ChatRoom_LogicBp.ChatRoom_LogicBp_C", Container="Default", ZOrder=BP_ENUM_UI_CHAT_ZORDER + 1},
		{Path="/Game/UMG/UI_Logic/LobbyChat/Chatroomcreat_LogicBP.Chatroomcreat_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_CHAT_ZORDER + 10},
		{Path="/Game/UMG/UI_Logic/LobbyChat/ChatroomPassword_LogicBP.ChatroomPassword_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_CHAT_ZORDER + 10},
	},
	{"Lobby"},
	false,
	false,
	true
	);
end
-------------聊天室开始---------------
--[[
频道数据结构
channel:
    channel_info:
	channel_id:			频道ID
	channel_name:		频道名称
	channel_owner:  	群主
	channel_need_key: 	是否需要key
	member_num:			频道人数
	last_update_time: 	最新更新时间
    member_info:		成员信息, id为uid
	svr:	
]]

BP_ChatRoom_CreateName = "";
BP_ChatRoom_CreatePassword = "";

BP_ChatRoom_WillMarkRoomID = "0";
BP_ChatRoom_WillMarkRoomState  = false;

BP_ChatRoom_SearchRoomID = "0";
BP_ChatRoom_SearchRoomPassword = "";

BP_ChatRoom_ClickMenuPlayerID = "0";
BP_ChatRoom_ClickMenuPlayerIsFriend = false;
BP_ChatRoom_ClickMenuPlayerIsPullBlack = false;
BP_ChatRoom_ClickMenuPlayerInMyTeam = false;
BP_ChatRoom_DefaultCreateName = "";

BP_ChatRoom_CreateWindowTitle = "";
BP_ChatRoom_SetWindowTitle = "";

BP_ChatRoom_MyChatRoomPassword = "";

BP_ChatRoom_MyRoomID = "0";
BP_ChatRoom_MyRoomName = "";
BP_ChatRoom_MyRoomPlayerCount = 0;
BP_ChatRoom_MyRoomIsSelfCreate = false;
BP_ChatRoom_MyRoomIsMarked = false;
BP_ChatRoom_MyRoomNeedKey = false;

BP_ChatRoom_UpdateOnePlayerIndex = 0;

BP_ChatRoom_UpdateMemberIndex = 0;

BP_ChatShowHelpContent = "";

local testRoomId = 10000;
local testFlag = false;
local testPlayerId = 0;

local baseInfoReady = false;
local statusInfoRead = false;

local onlyRefreshLastOne = false;

BP_STRUCT_ChatRoomInfo =
{
	id = "0",
	name = "",
	playerCount = 30,
	isSelfCreate = false,
	isMarked = false,
	needKey = false,
	updateTime = 0,
};

BP_ARRAY_ChatRoomInfoList = 
{
	BP_STRUCT_ChatRoomInfo = _G.BP_STRUCT_ChatRoomInfo,
};

BP_STRUCT_ChatRoomPlayer =
{
	id = "0",
	name = "",
	headUrl = "",
	isHost = false,
	isSelf = false,
	isFriend = false,
	isPullBlack = false,
	gender = 0,
	
	teamState = 0,-- 0 空闲 1 组队中 2 游戏中
	teamId = 0,		--队伍ID
	currentTeamAmount = 0, --队伍当前人数
	maxTeamAmount = 0,-- 队伍最大人数
	timeSinceGameBegin = 0, --游戏开局了多久(单位秒)
	online = 0,
	
	segmentInfoSolo = 1,
	segmentInfoDuo = 1,
	segmentInfoSquad = 1,
	cur_avatar_box_id = 0;
	level = 0;
};

BP_ARRAY_ChatRoomPlayerList = 
{
	BP_STRUCT_ChatRoomPlayer = _G.BP_STRUCT_ChatRoomPlayer,
};

function LobbyChatroomLogic.Init()
	BP_ChatShowHelpContent = string.format("%s\n\n%s\n\n%s\n\n%s\n\n%s", DataMgr.GetMsgByID(106060), DataMgr.GetMsgByID(106061), DataMgr.GetMsgByID(106062), DataMgr.GetMsgByID(106063), DataMgr.GetMsgByID(106064));
	
	if false == LobbyChatroomLogic.chatRoomInited then
		LuaClassObj.HandleDynamicCreation(bp_chat_room);
		LuaClassObj.HandleUIMessage(bp_chat_room, "UIInit");
		
		LobbyChatLogic.InitChatRoomChatList();
		
		LobbyChatroomLogic.chatRoomInited = true;
	end
end

function LobbyChatroomLogic.Release()
	LobbyChatroomLogic.chatRoomInited = false;
end

function LobbyChatroomLogic.Show()
	LobbyChatroomLogic.Init();
	
	LuaClassObj.HandleUIMessage(bp_chat_room, "UIShow");
end

function LobbyChatroomLogic.Hide()
	LuaClassObj.HandleUIMessage(bp_chat_room, "UIHide");
end

function LobbyChatroomLogic.OnChatMainShowHover()
	LuaClassObj.HandleUIMessage(bp_chat_room, "OnChatMainShowHover");
end

function EventFetchInfo()
	
end

--[[
LogNula: LuaLog: get_channel_list_rsp
LogNula: LuaLog: ├─ 10088
LogNula: LuaLog: │  ├─ is_collect: true
LogNula: LuaLog: │  └─ channel_info
LogNula: LuaLog: │     ├─ member_num: 2
LogNula: LuaLog: │     ├─ last_update_time: 1513329115
LogNula: LuaLog: │     ├─ id: 10088
LogNula: LuaLog: │     ├─ channel_name: "test"
LogNula: LuaLog: │     ├─ channel_need_key: true
LogNula: LuaLog: │     └─ channel_owner: 410000001
LogNula: LuaLog: └─ current_channel: 10088
]]
function LobbyChatroomLogic.UpdateChannelList()

	local myId = DataMgr.roleData.uid;
	BP_ARRAY_ChatRoomInfoList = {};

	local currentChannelID = LobbyChatSystem.channelList.current_channel;
	local currentCHannelInfo = {};
	LobbyChatSystem.chatRoomMyCreateCount = 0;

	if (LobbyChatSystem.channelList ~= nil) then
		for k,v in pairs(LobbyChatSystem.channelList) do
			
			if (type(k) == "number" and v ~= nil and v.channel_info ~= nil) then
				local roomData = {};
				roomData.id = tostring(k);
				roomData.name = v.channel_info.channel_name;
				roomData.isSelfCreate = (myId == tostring(v.channel_info.channel_owner));
				roomData.playerCount = v.channel_info.member_num;
				roomData.isMarked = v.is_collect;
				roomData.needKey = v.channel_info.channel_need_key;
				roomData.updateTime = v.channel_info.last_update_time;
				
				table.insert(BP_ARRAY_ChatRoomInfoList, roomData);
				
				if (currentChannelID ~= nil and currentChannelID == k) then
					currentCHannelInfo = v;
				end

				if (roomData.isSelfCreate) then
					LobbyChatSystem.chatRoomMyCreateCount = LobbyChatSystem.chatRoomMyCreateCount + 1;
				end
			end
		end
	end

	LobbyChatroomLogic.SortChannelList();

	if (currentChannelID == nil) then
		log("currentChannelID == nil");
		BP_ChatRoom_MyRoomID = "0";
		BP_ChatMainMyRoomId = "0";
		--log_tree("BP_ARRAY_ChatRoomInfoList", BP_ARRAY_ChatRoomInfoList);
		LobbyChatroomLogic.RefreshChatRoom();
	else 
		log("currentChannelID ~= nil");
		BP_ChatRoom_MyRoomID = tostring(currentChannelID);
		BP_ChatMainMyRoomId = BP_ChatRoom_MyRoomID;
		LobbyChatSystem.myChannel = currentCHannelInfo;
		LobbyChatroomLogic.UpdateMyChannel(true);
	end
end

function LobbyChatroomLogic.SortChannelList()
	table.sort(BP_ARRAY_ChatRoomInfoList, SortChannelFunc);
end

function SortChannelFunc(a,b)	
	if (a.isMarked == b.isMarked) then
		return a.updateTime > b.updateTime;
	elseif (a.isMarked and not b.isMarked) then
		return true;
	elseif (not a.isMarked and b.isMarked) then
		return false;
	else
		return a.name < b.name;
	end
	return false;
end


function LobbyChatroomLogic.SortPlayerList()
	--table.sort(BP_ARRAY_ChatRoomPlayerList, SortPlayerFunc);
end
--[[
	创始者始终在第一位，自己始终在第二位，其余的人的排序规则为按名字的字母排序
]]
function SortPlayerFunc(a,b)
	if (a.isHost and not b.isHost) then
		return true;
	elseif (not a.isHost and b.isHost) then
		return false;
	else 
		if (a.isSelf and not b.isSelf) then
			return true;
		elseif (not a.isSelf and b.isSelf) then
			return false;
		else 
			return a.name < b.name;
		end
	end
	
	return false;
end

function LobbyChatroomLogic.GetChannelById(id)
	if (#BP_ARRAY_ChatRoomInfoList > 0) then
		for i = 1,#BP_ARRAY_ChatRoomInfoList,1 do
			local roomInfo = BP_ARRAY_ChatRoomInfoList[i];
			--log_tree("roomInfo", roomInfo);
			if (roomInfo ~= nil and tostring(roomInfo.id) == tostring(id)) then
				return roomInfo;
			end
		end
	end
	return nil;
end

function LobbyChatroomLogic.UpdateChannelMarkState(channelID, isMarked)
	local channelIDStr = tostring(channelID);
	for i = 1,#BP_ARRAY_ChatRoomInfoList,1 do
		local roomInfo = BP_ARRAY_ChatRoomInfoList[i];
		--log_tree("roomInfo", roomInfo);
		if (roomInfo ~= nil and roomInfo.id == channelIDStr) then
			roomInfo.isMarked = isMarked;
			break;
		end
	end
	LobbyChatroomLogic.SortChannelList();
	--log_tree("BP_ARRAY_ChatRoomInfoList", BP_ARRAY_ChatRoomInfoList);
	if (BP_ChatRoom_MyRoomID == "0") then
		LuaClassObj.HandleUIMessage(bp_chat_room, "RefreshChatRoom");
	end
end

--[[
		teamState=teamState,						// 0 空闲 1 组队中 2 游戏中
		teamId=teamId, 								// 队伍ID
		currentTeamAmount=currentTeamAmount,		// 队伍当前人数
		maxTeamAmount=maxTeamAmount, 				// 队伍最大人数
		timeSinceGameBegin=timeSinceGameBegin, 		// 游戏开局了多久(单位秒)
		online=online  								/
]]
function LobbyChatroomLogic.UpdateChannelStatus()

	--log_tree("before UpdateChannelStatus BP_ARRAY_ChatRoomPlayerList", BP_ARRAY_ChatRoomPlayerList);
	for k,v in pairs(BP_ARRAY_ChatRoomPlayerList) do
		local profileData = LobbyChatSystem.chatRoomStatusDict[v.id];
		if (profileData ~= nil) then
		
			v.teamState = profileData.teamState;
			v.teamId = profileData.teamId;
			v.currentTeamAmount = profileData.currentTeamAmount;
			v.maxTeamAmount = profileData.maxTeamAmount;
			v.timeSinceGameBegin = profileData.timeSinceGameBegin;
			v.online = profileData.online;
		else
			log("UpdateChannelStatus not exist id = " .. v.id);
		end
	end	
	--log_tree("after UpdateChannelStatus BP_ARRAY_ChatRoomPlayerList", BP_ARRAY_ChatRoomPlayerList);
	
	statusInfoRead = true;
	if (baseInfoReady and statusInfoRead) then
		log("LobbyChatLogic.UpdateChannelStatus UpdatePlayerStatus, onlyRefreshLastOne = " .. tostring(onlyRefreshLastOne));
		LobbyChatroomLogic.RefreshAfterFetch();
	end
end

function LobbyChatroomLogic.RefreshAfterFetch()
	baseInfoReady = false;
	statusInfoRead = false;
	
	if (onlyRefreshLastOne == true) then
		BP_ChatRoom_UpdateOnePlayerIndex = #BP_ARRAY_ChatRoomPlayerList - 1;
		LuaClassObj.HandleUIMessage(bp_chat_room, "OnAddOnePlayer");
	else
		LuaClassObj.HandleUIMessage(bp_chat_room, "UpdatePlayerStatus");
	end

	onlyLastOne = fasle;

	--LuaClassObj.HandleUIMessage(bp_chat_main, "UpdatePlayerStatus");
end

function LobbyChatroomLogic.AddOnePlayer(uid)
	LobbyChatroomLogic.UpdateMyChannel(false, true);
end

function LobbyChatroomLogic.RemoveOnePlayer(memberIndex)
	log("LobbyChatLogic.RemoveOnePlayer memberIndex = " .. memberIndex);
	local playerCount = #BP_ARRAY_ChatRoomPlayerList;
	if memberIndex < playerCount + 1 then
		table.remove(BP_ARRAY_ChatRoomPlayerList, memberIndex);
		BP_ChatRoom_UpdateOnePlayerIndex = memberIndex - 1;
		LuaClassObj.HandleUIMessage(bp_chat_room, "OnRemoveOnePlayer");
	else
		log("memberIndex < playerCount memberIndex = " .. memberIndex .. ", playerCount = " .. playerCount);
	end
end

--[[
LogNula: LuaLog: ├─ 410000002
LogNula: LuaLog: │  ├─ gender: 1
LogNula: LuaLog: │  ├─ nickName: "test"
LogNula: LuaLog: │  ├─ gid: "410000002"
LogNula: LuaLog: │  └─ url: "http://q.qlogo.cn/qqapp/1106467070/2B6DDC941C9C798E385981BCF2B4CB2B/40"
LogNula: LuaLog: └─ 410000001
LogNula: LuaLog:    ├─ gender: 1
LogNula: LuaLog:    ├─ nickName: "jack"
LogNula: LuaLog:    ├─ gid: "410000001"
LogNula: LuaLog:    └─ url: "http://q.qlogo.cn/qqapp/1106467070/C1E162B0B7786CCF551EA5935D8AE1EB/40"
]]
function LobbyChatroomLogic.UpdateChannelMember(chatroomInfoDict)
	for k,v in pairs(BP_ARRAY_ChatRoomPlayerList) do
		local profileData = chatroomInfoDict[v.id];
		if (profileData ~= nil) then
			v.name = profileData.nickName;
			v.headUrl = profileData.url;
			v.gender = profileData.gender;
			v.segmentInfoSolo = profileData.segment_info_solo;
			v.segmentInfoDuo = profileData.segment_info_duo;
			v.segmentInfoSquad = profileData.segment_info_squad;
			v.cur_avatar_box_id = profileData.cur_avatar_box_id;
			v.level = profileData.level;
		else
			log("UpdateChannelMember not exist id = " .. v.id);
		end
	end	
	LobbyChatroomLogic.SortPlayerList(); 
	--log_tree("after UpdateChannelMember BP_ARRAY_ChatRoomPlayerList", BP_ARRAY_ChatRoomPlayerList);
	baseInfoReady = true;
	if (baseInfoReady and statusInfoRead) then
		baseInfoReady = false;
		statusInfoRead = false;
		log("LobbyChatLogic.UpdateChannelMember UpdatePlayerStatus");
		LuaClassObj.HandleUIMessage(bp_chat_room, "UpdatePlayerStatus");
	end
end


--[[
LogNula: LuaLog: channel
LogNula: LuaLog: ├─ is_collect: true
LogNula: LuaLog: ├─ members
LogNula: LuaLog: │  └─ 1: 410000001
LogNula: LuaLog: └─ channel_info
LogNula: LuaLog:    ├─ channel_need_key: true
LogNula: LuaLog:    ├─ id: 10088
LogNula: LuaLog:    ├─ channel_owner: 410000001
LogNula: LuaLog:    ├─ channel_name: "test"
LogNula: LuaLog:    ├─ last_update_time: 1513327431
LogNula: LuaLog:    └─ member_num: 2
]]
function LobbyChatroomLogic.UpdateMyChannel(fetchAll, onlyLastOne)

	log("LobbyChatLogic.UpdateMyChannel fetchAll = " .. tostring(fetchAll));
	
	if (onlyLastOne == nil) then
		onlyRefreshLastOne = false;
	else
		onlyRefreshLastOne = true;
	end
	
	baseInfoReady = false;
	statusInfoRead = false;
	
	BP_ARRAY_ChatRoomPlayerList = {};

	local myId = DataMgr.roleData.uid;
	
	if (LobbyChatSystem.myChannel ~= nil) then
		if (LobbyChatSystem.myChannel.members ~= nil) then
			LobbyChatSystem.myChannel.channel_info.member_num = #LobbyChatSystem.myChannel.members;
		else
			log("LobbyChatSystem.myChannel.members == nil");
			return;
		end
		--log_tree("UpdateMyChannel LobbyChatSystem.myChannel", LobbyChatSystem.myChannel);
		BP_ChatRoom_MyRoomID = tostring(LobbyChatSystem.myChannel.channel_info.id);
		BP_ChatRoom_MyRoomName = LobbyChatSystem.myChannel.channel_info.channel_name;
		BP_ChatRoom_MyRoomPlayerCount = LobbyChatSystem.myChannel.channel_info.member_num;
		BP_ChatRoom_MyRoomIsSelfCreate = (tostring(LobbyChatSystem.myChannel.channel_info.channel_owner) == tostring(myId));
		BP_ChatRoom_MyRoomIsMarked = LobbyChatSystem.myChannel.is_collect;
		BP_ChatRoom_MyRoomNeedKey = LobbyChatSystem.myChannel.channel_info.channel_need_key;
		
		BP_ChatMainMyRoomId = BP_ChatRoom_MyRoomID;
		
		local memberIdList = {};
		local allMemberIdList = {};
		
		for k,v in pairs(LobbyChatSystem.myChannel.members) do
			local playerData = {};

			playerData.id = tostring(v);
			playerData.name = "";
			playerData.headUrl = "";
			playerData.isHost = LobbyChatSystem.myChannel.channel_info.channel_owner == v;
			playerData.isSelf = (tostring(v) == tostring(myId));
			playerData.isFriend = FriendSystem.IsMyFriend(v);
			playerData.isPullBlack = FriendSystem.IsPulBlack(v);
			playerData.gender = 0;

			local profileData = nil;

			if (LobbyChatSystem.chatRoomStatusDict ~= nil) then
			
				profileData = LobbyChatSystem.chatRoomStatusDict[playerData.id];
			end
		
			table.insert(allMemberIdList, v);
			if (fetchAll == true or profileData == nil) then
				log("fetchAll = " .. tostring(fetchAll) .. ", playerData.id = " .. playerData.id);
				table.insert(memberIdList, v);
			end

			table.insert(BP_ARRAY_ChatRoomPlayerList, playerData);
		end

		ProfileMgr.GetProfileList(allMemberIdList, LobbyChatroomLogic.ReceiveProfileData, fetchAll);
		
		if (#memberIdList > 0) then
			--LobbyChatSystem.send_chatroom_profile_req(memberIdList);
			LobbyChatSystem.send_chatroom_status_req(memberIdList);
		else
			if (onlyRefreshLastOne == true) then
				--onlyRefreshLastOne = false;
				--BP_ChatRoom_UpdateOnePlayerIndex = #BP_ARRAY_ChatRoomPlayerList - 1;
				--LuaClassObj.HandleUIMessage(bp_chat_room, "OnAddOnePlayer");
				LobbyChatroomLogic.UpdateChannelStatus();
			else
				LobbyChatroomLogic.RefreshChatRoom();
				LobbyChatroomLogic.UpdateChannelStatus();
			end
			return;
		end
	end
	
	--log_tree("after UpdateMyChannel BP_ARRAY_ChatRoomPlayerList", BP_ARRAY_ChatRoomPlayerList);
	LobbyChatroomLogic.RefreshChatRoom();
end

function LobbyChatroomLogic.ReceiveProfileData(list)
	--log_tree("TestProfileData.list", list);
	local chatroomInfoDict = {};
	for k,v in pairs(list) do				
		
		local profileData = {};
		profileData.gid = tostring(v.uid);
		profileData.url = v.picUrl;
		profileData.nickName = v.nickName;
		profileData.gender = v.sex;		
        
        --waynedong todo
        ----------------------------------------intl modify--------------------------------------
        --[[
		profileData.segment_info_solo = v.segment_info[1];
		profileData.segment_info_duo = v.segment_info[2];
		profileData.segment_info_squad = v.segment_info[3];
        ]]
        profileData.AllSegment_Info = v.segment_info;
        for k, v in pairs(profileData.AllSegment_Info) do
           profileData.segment_info_solo   = profileData.AllSegment_Info[k][1];
           profileData.segment_info_duo    = profileData.AllSegment_Info[k][2];
           profileData.segment_info_squad = profileData.AllSegment_Info[k][3];
           break;
        end
        profileData.segment_info_solo,  profileData.segment_info_duo,  profileData.segment_info_squad =  FuncUtil.GetMaxSegement( profileData.AllSegment_Info );
        ----------------------------------------intl modify--------------------------------------
        
		profileData.cur_avatar_box_id = v.cur_avatar_box_id;
		profileData.level = v.level;
		chatroomInfoDict[profileData.gid] = profileData;
	end	
	--log_tree("chatroomInfoDict", chatroomInfoDict);
	LobbyChatroomLogic.UpdateChannelMember(chatroomInfoDict);
end

function LobbyChatroomLogic.OnPlayerStatusChange(profile)
	if (profile ~= nil and profile.uid ~= nil) then

		local listCount = #BP_ARRAY_ChatRoomPlayerList;
		if (listCount > 0) then
			for i = 1, listCount, 1 do
				local v = BP_ARRAY_ChatRoomPlayerList[i];
				--for k,v in pairs(BP_ARRAY_ChatRoomPlayerList) do
				if (tostring(profile.uid) == tostring(v.id)) then
					
					local profileData = {};
					profileData.gid = tostring(v.uid);
					profileData.url = profile.picUrl;
					profileData.nickName = profile.nickName;
					profileData.gender = profile.sex;		
                    --waynedong todo 
                    ----------------------------------------intl modify--------------------------------------
                    --[[
					profileData.segment_info_solo = profile.segment_info[1];
					profileData.segment_info_duo = profile.segment_info[2];
					profileData.segment_info_squad = profile.segment_info[3];
                    ]]
                    profileData.AllSegment_Info = v.segment_info;
                    for k, v in pairs(profileData.AllSegment_Info) do
                       profileData.segment_info_solo   = profileData.AllSegment_Info[k][1];
                       profileData.segment_info_duo    = profileData.AllSegment_Info[k][2];
                       profileData.segment_info_squad = profileData.AllSegment_Info[k][3];
                       break;
                    end
                    profileData.segment_info_solo,  profileData.segment_info_duo,  profileData.segment_info_squad =  FuncUtil.GetMaxSegement( profileData.AllSegment_Info );
                    ----------------------------------------intl modify--------------------------------------
					v.name = profileData.nickName;
					v.headUrl = profileData.url;
					v.gender = profileData.gender;
					v.segmentInfoSolo = profileData.segment_info_solo;
					v.segmentInfoDuo = profileData.segment_info_duo;
					v.segmentInfoSquad = profileData.segment_info_squad;

					BP_ChatRoom_UpdateOnePlayerIndex = i - 1;
					log("UpdateOnePlayerSync BP_ChatRoom_UpdateOnePlayerIndex = " .. BP_ChatRoom_UpdateOnePlayerIndex);
					LuaClassObj.HandleUIMessage(bp_chat_room, "UpdateOnePlayerSync");
				end
			end	
		end
	end
end

function LobbyChatroomLogic.OnPlayerStatusListChange(list)
	log("OnPlayerStatusListChange");
	local count = #list;
	if (count > 0) then
		for i = 1,count,1 do
			LobbyChatroomLogic.OnPlayerStatusChange(list[i]);
		end
	end
end

function LobbyChatroomLogic.HandleReconnectSuccess()
	log("HandleReconnectSuccess BP_ChannelType = " .. BP_ChannelType);

	if (LobbyChatSystem.myChannel ~= nil and BP_ChannelType == LobbyChatSystem.channelChatRoom) then
		--log("HandleReconnectSuccess ClearChatRoomData");
		--DataMgr.ShowNoticeByID(106058);
		--LobbyChatLogic.ClearChatRoomData();
		--LobbyChatLogic.RefreshChatRoom();
		LobbyChatSystem.get_channel_list_req();
	end
end

function LobbyChatroomLogic.ClearChatRoomData()
	LobbyChatSystem.myChannel = nil;
	BP_ChatRoom_MyRoomID = "0";	
	BP_ChatRoomNewMessageCount = 0;
	BP_ChatRoom_MyRoomID = "0";
	LobbyChatSystem.chatRoomStatusDict = {};
end

function LobbyChatroomLogic.RefreshChatRoom()
	LobbyChatLogic.RefreshChatRoom()
	LuaClassObj.HandleUIMessage(bp_chat_room, "RefreshChatRoom");
end

function LobbyChatroomLogic.OnTeamStateChange(uid, channel_id, team_state)
	local playerCount = #BP_ARRAY_ChatRoomPlayerList;
	local uidStr = tostring(uid);
	if (playerCount > 0) then
		for i = 1, playerCount, 1 do 
			local playerData = BP_ARRAY_ChatRoomPlayerList[i];
			if (playerData ~= nil and playerData.id == uidStr) then
				playerData.teamState = team_state;
				BP_ChatRoom_UpdateOnePlayerIndex = i - 1;
				LuaClassObj.HandleUIMessage(bp_chat_room, "UpdateOnePlayerSync");
				break;
			end
		end
	end
end

function EventOpenCreateChatRoomPanel()

	log("EventOpenCreateChatRoomPanel");

	if (LobbyChatLogic.CheckHasRightToCreateOrJoinRoom() == false) then
		return;
	end
	
	if (LobbyChatSystem.chatRoomMyCreateCount >= LobbyChatSystem.chatRoomMaxCreate) then
		LobbyChatSystem.ShowErrorMsg("create-channel-exceed-limit");
		return;
	end
	
	BP_ChatRoom_CreateWindowTitle = DataMgr.GetMsgByID(106053);
	BP_ChatRoom_DefaultCreateName = DataMgr.GetMsgByID(4024); 
	LuaClassObj.HandleUIMessage(bp_chat_room, "OpenCreateRoomPanel");
end

function EventOpenSetChatRoomPanel()
	log("EventOpenSetChatRoomPanel");
	BP_ChatRoom_SetWindowTitle = DataMgr.GetMsgByID(106054);
	BP_ChatRoom_MyChatRoomPassword = (BP_ChatRoom_MyRoomNeedKey and LobbyChatSystem.myChannel ~= nil and LobbyChatSystem.myChannel.passwd ~= nil) and LobbyChatSystem.myChannel.passwd or "";
	--log_tree("EventOpenSetChatRoomPanel myChannel", LobbyChatSystem.myChannel);
	log("BP_ChatRoom_MyChatRoomPassword = " .. BP_ChatRoom_MyChatRoomPassword);
	LuaClassObj.HandleUIMessage(bp_chat_room, "EventOpenSetChatRoomPanel");
end

function EventCreateChatRoom()
	
	log("EventCreateChatRoom name = " .. BP_ChatRoom_CreateName .. " password = " .. BP_ChatRoom_CreatePassword);
	
	BP_ChatRoom_CreateName = FuncUtil:StrTrim(BP_ChatRoom_CreateName);
	local ret, len, retStr = FuncUtil:CheckName(BP_ChatRoom_CreateName, true, nil, true);
    if ret then
		DataMgr.ShowNoticeByID(990004);
        return;
	end	

    if len > 20 then
		DataMgr.ShowNoticeByID(106028);
        return;
    end	
	
	local needPassword = string.len(BP_ChatRoom_CreatePassword) > 0;
	LobbyChatSystem.create_channel_req(BP_ChatRoom_CreateName, needPassword, BP_ChatRoom_CreatePassword);
end

function EventSaveChatRoom()
	
	log("EventCreateChatRoom name = " .. BP_ChatRoom_CreateName .. " password = " .. BP_ChatRoom_CreatePassword);
	local needPassword = string.len(BP_ChatRoom_CreatePassword) > 0;
	LobbyChatSystem.change_channel_req(LobbyChatSystem.myChannel.channel_info.id, BP_ChatRoom_CreateName, needPassword, BP_ChatRoom_CreatePassword);
end

function EventJoinChatRoom()
	log("EventJoinMyCreateChatRoom BP_ChatRoom_SearchRoomID = " .. BP_ChatRoom_SearchRoomID);
	LobbyChatSystem.chatRoomQueryPassword = false;
	LobbyChatSystem.join_channel_req(tonumber(BP_ChatRoom_SearchRoomID), BP_ChatRoom_SearchRoomPassword);
end
	
function EventQuitChatRoom()
	log("EventQuitChatRoom");
	LobbyChatSystem.exit_channel_req(tonumber(BP_ChatRoom_MyRoomID));
end

function EventClickChatRoomPlayerInfo()
	log("EventClickChatRoomPlayerInfo");
	LuaClassObj.HandleUIMessage(bp_chat_room, "RefreshChatRoom");
end

function EventClickMarkState()
	log("EventClickMarkState id = " .. BP_ChatRoom_WillMarkRoomID .. ", state = " .. tostring(BP_ChatRoom_WillMarkRoomState));
	if (BP_ChatRoom_WillMarkRoomState) then
		LobbyChatSystem.collect_channel_req(tonumber(BP_ChatRoom_WillMarkRoomID));
	else 
		LobbyChatSystem.cancel_collect_channel_req(tonumber(BP_ChatRoom_WillMarkRoomID));
	end
end

function EventClickRemoveRoom()	
	log("EventClickRemoveRoom BP_ChatRoom_MyRoomID = " .. BP_ChatRoom_MyRoomID);
	
	local clickOkCallback = function()
		LobbyChatSystem.delete_channel_req(tonumber(BP_ChatRoom_MyRoomID));
	end
	
	local clickCancelCallback = function()
		
	end	
	
	local strTile = DataMgr.GetMsgByID(106040);--"提示";
	local strMsg = DataMgr.GetMsgByID(106041);
	--"确定要删除该频道吗？删除后将不在频道历史中出现，但仍可通过搜索ID进入频道。";
	
	if (BP_ChatRoom_MyRoomIsSelfCreate) then
		--strMsg = strMsg .. "您是该聊天室的创建者，删除聊天室后该聊天室会解散。";
		strMsg = DataMgr.GetMsgByID(106025);
	end
	
	CommonMessageBoxUI:ShowPanel(2, strTile, strMsg, clickOkCallback, clickCancelCallback);
end

function EventClickSearchAndJoinRoom()	
	
	log("EventClickSearchAndJoinRoom");
	LobbyChatSystem.chatRoomQueryPassword = true;
	LobbyChatSystem.join_channel_req(tonumber(BP_ChatRoom_SearchRoomID), "")
end

function EventOpenChatRoomPassword()
	LuaClassObj.HandleUIMessage(bp_chat_room, "OpenChatRoomPassword");
end

function EventAlertNeedPassword()
	DataMgr.ShowNoticeByString(DataMgr.GetMsgByID(106042));
	--DataMgr.ShowNoticeByString("请输入密码");
end

function EventAlertNeedRoomID()
	--DataMgr.ShowNoticeByString("请输入聊天室ID");
	DataMgr.ShowNoticeByString(DataMgr.GetMsgByID(106043));
end

function EventAlertNeedRoomName()
	--DataMgr.ShowNoticeByString("请输入聊天室名字");
	DataMgr.ShowNoticeByString(DataMgr.GetMsgByID(106047));
end
function EventChatRoomPlayerInfo()
	log("EventChatRoomPlayerInfo BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID);
	RoleInfoSystem.Enter(BP_ChatRoom_ClickMenuPlayerID);	
	RoleInfoUI.Init();
	ProfileMgr.GetProfile(tostring(BP_ChatRoom_ClickMenuPlayerID), LobbyChatLogic.OnPlayerStatusListChange, true);
end

function EventChatRoomUpdateClickMenuPlayer()
	BP_ChatRoom_ClickMenuPlayerIsFriend = FriendSystem.IsMyFriend(tonumber(BP_ChatRoom_ClickMenuPlayerID));
	BP_ChatRoom_ClickMenuPlayerIsPullBlack = FriendSystem.IsPulBlack(tonumber(BP_ChatRoom_ClickMenuPlayerID));
	BP_ChatRoom_ClickMenuPlayerInMyTeam = tonumber(BP_ChatRoom_ClickMenuPlayerID) ~= 0 and TeamUpSystem.GetMemberInfo(tonumber(BP_ChatRoom_ClickMenuPlayerID)) ~= nil;

	log("EventChatRoomUpdateClickMenuPlayer BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID 
		.. ", BP_ChatRoom_ClickMenuPlayerIsFriend = " .. tostring(BP_ChatRoom_ClickMenuPlayerIsFriend)
		.. ", BP_ChatRoom_ClickMenuPlayerIsPullBlack = " .. tostring(BP_ChatRoom_ClickMenuPlayerIsPullBlack)
		.. ", BP_ChatRoom_ClickMenuPlayerInMyTeam = " .. tostring(BP_ChatRoom_ClickMenuPlayerInMyTeam));
end

function EventChatRoomAddFriend()
	log("EventChatRoomAddFriend BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID);
	FriendSystem.add_inner_friend_req(tonumber(BP_ChatRoom_ClickMenuPlayerID), "",BP_ENUM_ADD_FRIEND_FROM_CHAT);
end

function EventChatRoomJoinTeam()
	log("EventChatRoomJoinTeam BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID);
	TeamUpSystem.team_apply_request(tonumber(BP_ChatRoom_ClickMenuPlayerID));
end

function EventChatRoomPullBlack()
	log("EventChatRoomPullBlack BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID);
	
	if (BP_ChatRoom_ClickMenuPlayerIsPullBlack) then
		DataMgr.ShowNoticeByID(106065);	--已经屏蔽该玩家~
		--FriendSystem.del_black_list_req(tonumber(BP_ChatRoom_ClickMenuPlayerID));
	else
		FriendSystem.AddBlack(BP_ChatRoom_ClickMenuPlayerID);
	end
end

function EventChatRoomInviteTeam()
	log("EventChatRoomInviteTeam BP_ChatRoom_ClickMenuPlayerID = " .. BP_ChatRoom_ClickMenuPlayerID);
	local isMatch = TeamUpUI.IsMatching();
	if isMatch then
		log("EventChatRoomInviteTeam isMatch:");
		--PopUpNoticeUI.ShowMessageBox("队伍", "匹配中，无法邀请或者加入队伍");
		return;
	end	
	--log_tree("OnClickMeta", BP_ARRAY_Teamuup_Friend_Profile);	
	log("EventClickInviteFriendBtn GID:"..tonumber(BP_ChatRoom_ClickMenuPlayerID));
	TeamUpSystem.team_invite_request(tonumber(BP_ChatRoom_ClickMenuPlayerID));
end

function EventChatRoomOnShowList()
	LobbyChatLogic.OnShowChatroomList();
end

function EventChatRoomOnMyRoom()
	LobbyChatLogic.OnShowMyChatroom();
end

function EventChatRoomMenuOpen()
	LobbyChatLogic.HideHover();
end

function LobbyChatroomLogic.CloseCreateOrSetRoomPanel()
	LuaClassObj.HandleUIMessage(bp_chat_room, "CloseCreateOrSetRoomPanel");
end

function LobbyChatroomLogic.CloseChatRoomPassword()
	LuaClassObj.HandleUIMessage(bp_chat_room, "CloseChatRoomPassword");
end

function LobbyChatroomLogic.OnCollectStateChange()
	log("LobbyChatLogic.OnCollectStateChange()");
	LuaClassObj.HandleUIMessage(bp_chat_room, "PlayCollectSound");
end