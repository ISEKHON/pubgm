LobbyChatLogic = LobbyChatLogic or 
{
	chatBackGroundProfile = false;	
	chatProfileBufferReq = {};
	chatProfileWorldBufferReq = {};
	chatRoomBufferList = {};
	chatRoomFightNewMsg = 0;
}

BP_ChatMainValid = false;
BP_ChatMainFirstShow = false;
BP_ChatMainShown = false;
BP_ReceiverName = "光速小子";
BP_ReceiverGID = "";
BP_ChatContent = "hello world";
BP_ChatInputContent = "";
BP_ChatInputFilteredContent = "";
BP_ChannelTitleName = "";
BP_ChannelType = 2;
BP_SelectedFriendGID = "";
BP_ChatSelectedGID = "";

BP_WorldNewMessageCount = 0;
BP_FriendNewMessageCount = 0;
BP_TeamNewMessageCount = 0;
BP_ChatRoomNewMessageCount = 0;

BP_ChatOnlineFriendCout = 0;
BP_ChatTotalFriendCount = 0;

BP_ChatMyGID = "";
BP_ChatIsTeamUp = false;
BP_ChatTickBufferList = false;
BP_ChatTodayDate = "";
BP_ChatHoverGID = "";
BP_ChatHoverContent = "";
BP_ChatHoverName = "";
BP_ChatMainClearGID = "";

-- 离线语音相关
BP_ChatVoiceBan = 0;
BP_ChatVoiceTotalLimit = 10;
BP_ChatVoiceUploadMsgId = "";
BP_ChatVoiceToTextContent = "";
BP_ChatVoiceUploadTime = 0;
BP_ChatVoicePlayFileId = "";
BP_ChatVoiceMode = -1;

BP_ChatVoiceDownloadFileId = "";
BP_ChatVoiceDownloadChannel = 0;
BP_ChatVoiceDownloadMsgId = 0;
BP_ChatVoiceDownloadOwnerGid = "";
BP_ChatVoiceDownloadMsgLength = 0;

BP_ChatVoiceTeamRoom = "";

BP_ChatVoiceOpenMic = false;
BP_ChatVoiceOpenSpeaker = false;

BP_ChatHoverIsPullBlack = false;
BP_ChatHoverIsFriend = false;

BP_ChatProfileRspGid = "";
BP_ChatProfileRspUrl = "";
BP_ChatProfileRspNickName = "";
BP_ChatProfileRspGender = 0;
BP_ChatProfileRspLevel = 0;
BP_ChatProfileRspMaxSegment = 0;
BP_ChatProfileRspAvatarBox = 0;

BP_ChatProfileReqGid = "";
BP_ChatRecruitJoinGid = "";
BP_ChatRecruitTeamID = "";
BP_ChatShowHelpContent = "";
BP_ChatMainMyRoomId = "0";
BP_ChatEmojiClickItem = 0;

BP_ChatTranslateChannel = 0;
BP_ChatTranslateID = 0;
BP_ChatTranslateText = "";
BP_ChatLanguageFrom = "";

BP_STRUCT_ChatMessageSingleData = 
{
	uid = "",
	icon = "",
	name = "",
	gender = 0,
	msg = "",
	msgChannel = 0,	--聊天频道
	msgType = 0,	--消息类型
	msgSendTime = "",
	msgSendDate = "",
	level = 1,		--先用level做增量id
	voiceMsgId = "",
	voiceMsgTime = 0,
	roomId = "",
	roomType = "",
	selfMsg = false,
}

BP_STRUCT_ChatBriefFriendData = 
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
    lastOnlineTime = 0,
	teamState = 0, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
	currentTeamAmount = 1, -- 当前队伍人数
	maxTeamAmount = 4, -- 队伍最大可容纳人数
	teamId = 0, -- 队伍id
	timeSinceGameBegin = 0, -- 已开局时间
    op=0, --邀请列表里面的操作
    applyMsg="", --邀请列表里面的留言
	militaryRank = "",
	segment_info_solo = 0,
	segment_info_duo = 0,
	segment_info_squad = 0,
	cur_avatar_box_id = 0,
}

BP_STRUCT_ChatUnreadMsgCount = 
{
	gid = "",
	nickName = "",
	unreadCount = 0,
}

BP_STRUCT_ChatVoiceDownloadData = 
{
	msgGid = 0,
	msgChannel = 0,
	msgId = 0,
	fileId = "",
}

-- 世界聊天记录
BP_ARRAY_WorldChatList = 
{
	BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
};

-- 好友聊天记录
BP_ARRAY_FriendChatList =
{
	BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
};

-- 队友聊天记录
BP_ARRAY_TeamChatList =
{
	BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
};

BP_ARRAY_ChatroomChatList = 
{
	BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
};

-- 访问最新的消息记录数据
BP_ARRAY_NewChatList =
{
	BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
};

-- 消息未读记录
BP_ARRAY_ChatFriendUnreadList =
{
	BP_STRUCT_ChatUnreadMsgCount = _G.BP_STRUCT_ChatUnreadMsgCount,
};

-- 好友列表
BP_ARRAY_ChatFriendList = 
{
	BP_STRUCT_ChatBriefFriendData = _G.BP_STRUCT_ChatBriefFriendData,
};

-- 离线语音下载列表
BP_ARRAY_ChatVoiceDownloadList = 
{
	BP_STRUCT_ChatVoiceDownloadData = _G.BP_STRUCT_ChatVoiceDownloadData,
};

--注册Widget
function bp_chat_main_RegisterUI()

  LuaClassObj.SubUIWidgetList(bp_chat_main,
    {
		{Path="/Game/UMG/UI_Logic/LobbyChat/ChatMain_BP.ChatMain_BP_C", Container="Default", ZOrder=BP_ENUM_UI_CHAT_ZORDER}		
	},
    {"Lobby"},
	false,
	bp_chat_main_OnModeSwitched ~= nil,
	true
  );
end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function EventSyncBp2Lua_Push()
end

function bp_chat_main_OnModeSwitched(gamestatus)
	local curStatus = string.lower(gamestatus);
	if "lobby" == curStatus then
		log("lobbyChat Init");
		--LobbyChatLogic:Init()
	else
		log("lobbyChat Release");
		
		if "fighting" == curStatus then
			LobbyChatLogic.chatRoomFightNewMsg = BP_ChatRoomNewMessageCount;
		end
		
		LobbyChatLogic:Release()
	end
end

function LobbyChatLogic:PreInit()
	BP_ChannelType = LobbyChatSystem.channelWorld;
	BP_ChatMyGID = DataMgr.roleData.uid;
	BP_ChatVoiceMode = LobbyChatSystem.voiceChatMode;
	BP_ChatVoiceOpenMic = LobbyChatSystem.voiceOpenMic;
	BP_ChatVoiceOpenSpeaker = LobbyChatSystem.voiceOpenSpeaker;		
	BP_ChatRoomNewMessageCount = LobbyChatLogic.chatRoomFightNewMsg;
	LobbyChatLogic.chatRoomFightNewMsg = 0;
end

function LobbyChatLogic:Init()
	if false == BP_ChatMainValid then
		LuaClassObj.HandleDynamicCreation(bp_chat_main);
	
		BP_ChatMainValid = true;
		BP_ChannelType = LobbyChatSystem.channelWorld;
		BP_ChatMyGID = DataMgr.roleData.uid;
		BP_ChatVoiceMode = LobbyChatSystem.voiceChatMode;
		BP_ChatVoiceOpenMic = LobbyChatSystem.voiceOpenMic;
		BP_ChatVoiceOpenSpeaker = LobbyChatSystem.voiceOpenSpeaker;		
		LobbyChatSystem.get_channel_list_req();
		
		LobbyChatLogic.InitFriendUnreadList();
		
		LuaClassObj.HandleUIMessage(bp_chat_main, "UIInit");
	end	
end

function LobbyChatLogic:Release()
	BP_ChannelType = LobbyChatSystem.channelInvalid;
	BP_SelectedFriendGID = "";
	BP_ChatVoiceMode = -1;
	BP_ChatTickBufferList = false;
	BP_ChatVoiceOpenMic = false;
	BP_ChatVoiceOpenSpeaker = false;
	LobbyChatSystem.voiceChatMode = -1;	
	
	BP_WorldNewMessageCount = 0;
	BP_FriendNewMessageCount = 0;
	BP_TeamNewMessageCount = 0;
	BP_ChatRoomNewMessageCount = 0;		
		
	BP_ARRAY_WorldChatList = {};
	BP_ARRAY_FriendChatList = {};
	BP_ARRAY_TeamChatList = {};
	BP_ARRAY_ChatroomChatList = {};
	BP_ARRAY_NewChatList = {};
	BP_ARRAY_ChatFriendUnreadList = {};
	BP_ARRAY_ChatFriendList = {};
	BP_ARRAY_ChatVoiceDownloadList = {};
		
	LobbyChatroomLogic.ClearChatRoomData();
	LobbyChatroomLogic.Release();
	LobbyChatEmojiLogic.Release();
	
	LobbyChatLogic.chatBackGroundProfile = false;	
	LobbyChatLogic.chatProfileBufferReq = {};
	LobbyChatLogic.chatProfileWorldBufferReq = {};
	
	if BP_ChatMainValid then		
		BP_ChatMainValid = false;		
				
		LuaClassObj.HandleUIMessage(bp_chat_main, "OnRefreshMsgBufferState");
		LuaClassObj.HandleUIMessage(bp_chat_main, "UIRelease");
	end	
end

--[[
	Events
]]

function LobbyChatLogic.OnTeamupInfoChanged(eventType, eventID, vars)
	if eventID == EVENTID_TEAMUP_TEAMINFO_SYNC then
		if nil ~= TeamUpSystem.TeamInfo then
			local isTeamup = TeamUpSystem.TeamInfo.player_count > 1;
			LobbyChatLogic.SetIsTeamUp(isTeamup);
			LobbyChatEntranceUI.SetIsTeamUp(isTeamup);
		end
	end
end

--[[
	msg (struct)
	sender_uid (string)
	sender_name (string)
	msg_content (string)
]]
function LobbyChatLogic.NotifyFriendNewChat(msg, sender_uid, sender_name, msg_content)
	
	if BP_ChatMainValid then			
		if BP_SelectedFriendGID == sender_uid then
			BP_ARRAY_NewChatList = nil;		
			BP_ARRAY_NewChatList = {};
			table.insert(BP_ARRAY_NewChatList, msg);
			
			LuaClassObj.HandleUIMessage(bp_chat_main, "OnReceiveFriendChatMsg");
		end			
	end
end

--[[
	sender_uid (string)
	message_count (number)
]]

function LobbyChatLogic.RefreshUnreadList(sender_uid, message_count)
	if not BP_ChatMainValid then
		return;
	end
	
	local existItem = false;
	for i = 1, #BP_ARRAY_ChatFriendUnreadList do 
		local unread = BP_ARRAY_ChatFriendUnreadList[i];
		if FuncUtil:StrTrim(unread.gid) == sender_uid then
			unread.unreadCount = message_count;
			existItem = true;
			break;			
		end
	end
	
	if not existItem then
		local unreadData = {};			
		unreadData.gid = sender_uid;
		unreadData.unreadCount = message_count;
		table.insert(BP_ARRAY_ChatFriendUnreadList, unreadData);
	end	
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnNotifyChatUnread");
end

function LobbyChatLogic.RefreshFriendTotalUnread()
	if not BP_ChatMainValid then
		return;
	end
		
	local unreadCount = 0;	
	for k,v in pairs(LobbyChatSystem.friendChatList) do
		unreadCount = unreadCount + v.newMessageCount;
	end
	
	BP_FriendNewMessageCount = unreadCount;		
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnNotifyFriendTotalUnread");
end

function LobbyChatLogic.InitFriendUnreadList()
	if not BP_ChatMainValid then
		return;
	end
	
	BP_ARRAY_ChatFriendUnreadList = {};
	
	for k,v in pairs(LobbyChatSystem.friendChatList) do
		local unreadData = {};
		unreadData.gid = k;
		unreadData.unreadCount = v.newMessageCount;
		table.insert(BP_ARRAY_ChatFriendUnreadList, unreadData);
	end	
end

function LobbyChatLogic.InitChatRoomChatList()
	if not BP_ChatMainValid then
		return;
	end
	
	if ("0" ~= BP_ChatMainMyRoomId) and (""~= BP_ChatMainMyRoomId) then
		log("InitChatRoomChatList " .. BP_ChatMainMyRoomId);
		
		BP_ARRAY_ChatroomChatList = {};
		
		for i = 1, #LobbyChatLogic.chatRoomBufferList do
			local buff = LobbyChatLogic.chatRoomBufferList[i];
			table.insert(BP_ARRAY_ChatroomChatList, buff);
		end		
		
		LuaClassObj.HandleUIMessage(bp_chat_main, "InitChatRoomBuffer");		
	end	
end

function LobbyChatLogic.OpenUI()
	if not LobbyChatSystem.canOpenChatWnd then
		return;
	end
	
	if false == BP_ChatMainValid then
		LobbyChatLogic:Init();
	end
	
	if BP_ChatMainValid then		
		if not BP_ChatMainFirstShow then
			BP_ChatMainFirstShow = true;
			if BP_ChatIsTeamUp then
				--BP_ChannelType = LobbyChatSystem.channelTeam;
			end
		end			
		
		LuaClassObj.HandleUIMessage(bp_chat_main, "UIShow");
		LobbyChatLogic.RefreshFriendTotalUnread();
		FriendSystem.batchGetTeamInfoList();
	end
end

function LobbyChatLogic.CloseUI()
	if not BP_ChatMainValid then
		return;
	end
		
	EventHideChatMainWnd();
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "UIHide");
end

--[[
	gid: string
]]
function LobbyChatLogic.ChatWithFriend(gid)
	BP_SelectedFriendGID = gid;
	LobbyChatEntranceUI.OpenChatUI();
	LuaClassObj.HandleUIMessage(bp_chat_main, "ScrollToFriend");
end

function LobbyChatLogic.SetIsTeamUp(teamUp)
	BP_ChatIsTeamUp = teamUp;
	
	if false == teamUp then
		BP_ARRAY_TeamChatList = {};
		BP_TeamNewMessageCount = 0;
	end
	
	if BP_ChatMainValid then
		LuaClassObj.HandleUIMessage(bp_chat_main, "TeamStateChanged");
	end	
end

function LobbyChatLogic.OnSendMsgSuccess(msg_id)
	if not BP_ChatMainValid then
		return;
	end
	
	if "" == msg_id then
		LuaClassObj.HandleUIMessage(bp_chat_main, "OnSendMsgComplete");
	else
		LuaClassObj.HandleUIMessage(bp_chat_main, "OnSendVoiceComplete");
	end	
end

function LobbyChatLogic.DeleteFriend(uid)
	if not BP_ChatMainValid then
		return;
	end
	
	log("ChatMain Delete Friend 1");
	
	if BP_SelectedFriendGID == uid then
		log("ChatMain Delete Friend ");
		
		LuaClassObj.HandleUIMessage(bp_chat_main, "OnDeleteSelectedFriend");
		BP_SelectedFriendGID = "";
	end
end

function LobbyChatLogic.ClearSomeonesMsg(uid)		
	BP_ChatMainClearGID = tostring(uid);
	
	for i = #BP_ARRAY_WorldChatList, 1, -1 do
		local buf = BP_ARRAY_WorldChatList[i];
		if buf.sender_uid == uid then
			table.remove(BP_ARRAY_WorldChatList, i);
		end
	end
	
	for i = #BP_ARRAY_TeamChatList, 1, -1 do
		local buf = BP_ARRAY_TeamChatList[i];
		if buf.sender_uid == uid then
			table.remove(BP_ARRAY_TeamChatList, i);
		end
	end
	
	for i = #BP_ARRAY_ChatroomChatList, 1, -1 do
		local buf = BP_ARRAY_ChatroomChatList[i];
		if buf.sender_uid == uid then
			table.remove(BP_ARRAY_ChatroomChatList, i);
		end
	end
	
	BP_WorldNewMessageCount = 0;
	BP_TeamNewMessageCount = 0;
	BP_ChatRoomNewMessageCount = 0;
	BP_FriendNewMessageCount = 0;
	
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "ClearSomeonesMsg");
end

--[[
	msg_channel (number)
	sender_name (string)
	voice_file (string)
	voice_length (number)
	chat_content (string)
	sender_uid (string)
	self_msg (bool)
]]
function LobbyChatLogic.AddNewChat(msg_channel, msg_type, sender_name, voice_file, voice_length, chat_content, sender_uid, self_msg, team_id)		
	--构造聊天数据结构--	
	local msg = {};
    msg.name = sender_name;
	msg.msgChannel = msg_channel;
	msg.msgType = msg_type;
	msg.msg = chat_content;	
	msg.uid = sender_uid;
	msg.selfMsg = self_msg;
	msg.voiceMsgId = voice_file;
	msg.voiceMsgTime = voice_length;
	msg.roomId = team_id; --保存招募用的teamID,目前使用roomId是因为这个字段以前没人用，就复用了
	
	LobbyChatSystem.STATIC_MESSAGE_COUNTER = LobbyChatSystem.STATIC_MESSAGE_COUNTER + 1;
	msg.level = LobbyChatSystem.STATIC_MESSAGE_COUNTER;
	
	BP_ARRAY_NewChatList = nil;
	BP_ARRAY_NewChatList =
	{		
	};
	
	table.insert(BP_ARRAY_NewChatList, msg);
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_chat_main));
	if "lobby" ~= curStatus then
		if msg_channel == LobbyChatSystem.channelChatRoom then
			if #LobbyChatLogic.chatRoomBufferList >= LobbyChatSystem.MAX_MESSAGE_CHATROOM_HISTORY_CACHE then
				table.remove(LobbyChatLogic.chatRoomBufferList, 1);
			end
			
			table.insert(LobbyChatLogic.chatRoomBufferList, msg);
			LobbyChatLogic.chatRoomFightNewMsg = LobbyChatLogic.chatRoomFightNewMsg + 1;	
		end
		
		return;
	end
	
	if msg_channel == LobbyChatSystem.channelWorld then	
		if #BP_ARRAY_WorldChatList >=  LobbyChatSystem.MAX_MESSAGE_CACHE_NUM  then
			table.remove(BP_ARRAY_WorldChatList, 1);
		end
	
		table.insert(BP_ARRAY_WorldChatList, msg);
		
		if msg_channel ~= BP_ChannelType then
			BP_WorldNewMessageCount = BP_WorldNewMessageCount + 1;
		end
	elseif msg_channel == LobbyChatSystem.channelTeam then
		if #BP_ARRAY_TeamChatList >= LobbyChatSystem.MAX_MESSAGE_CACHE_NUM then
			table.remove(BP_ARRAY_TeamChatList, 1);
		end
	
		table.insert(BP_ARRAY_TeamChatList, msg);
		
		if msg_channel ~= BP_ChannelType then
			BP_TeamNewMessageCount = BP_TeamNewMessageCount + 1;
		end
	elseif msg_channel == LobbyChatSystem.channelChatRoom then
		if #BP_ARRAY_ChatroomChatList >= LobbyChatSystem.MAX_MESSAGE_CACHE_NUM then
			table.remove(BP_ARRAY_ChatroomChatList, 1);
		end		
		
		if #LobbyChatLogic.chatRoomBufferList >= LobbyChatSystem.MAX_MESSAGE_CHATROOM_HISTORY_CACHE then
			table.remove(LobbyChatLogic.chatRoomBufferList, 1);
		end
		
		table.insert(BP_ARRAY_ChatroomChatList, msg);
		table.insert(LobbyChatLogic.chatRoomBufferList, msg);
		--log("chat main " .. tostring(msg_channel) .. " " .. BP_ChatMainMyRoomId);
		
		if ((msg_channel ~= BP_ChannelType) or (false == BP_ChatMainShown)) and ("0" ~= BP_ChatMainMyRoomId) then
			BP_ChatRoomNewMessageCount = BP_ChatRoomNewMessageCount + 1;
		end
	end
	
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnReceiveChatMsg");
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnRefreshUnread");
		
	LobbyChatEntranceUI.RefreshChatroomUnread(BP_ChatRoomNewMessageCount);
end

function LobbyChatLogic.RefreshFriendState()
	if not BP_ChatMainValid then
		return;
	end
	
	-- EventFetchFriendData();
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnFriendStateChanged");
end

function LobbyChatLogic.RefreshVoiceMode()
	if not BP_ChatMainValid then
		return;
	end
	
	BP_ChatVoiceMode = LobbyChatSystem.voiceChatMode;	
end

function LobbyChatLogic.RefreshMicOpen()
	BP_ChatVoiceOpenMic = LobbyChatSystem.voiceOpenMic;
	BP_ChatVoiceTeamRoom = LobbyChatSystem.voiceEnterRoomId;
	
	if not BP_ChatMainValid then
		return;
	end	
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnVoiceMicOpenChanged");
end

function LobbyChatLogic.RefreshSpeakerOpen()
	if not BP_ChatMainValid then
		return;
	end
	
	BP_ChatVoiceOpenSpeaker = LobbyChatSystem.voiceOpenSpeaker;
	BP_ChatVoiceTeamRoom = LobbyChatSystem.voiceEnterRoomId;
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnVoiceSpeakerOpenChanged");
end

function LobbyChatLogic.RefreshProfileData(profile)	
	if not BP_ChatMainValid then
		return;
	end	
	
	--local friendData = FriendSystem.GetFriendDataByGID(tonumber(profile.gid));
	--if nil ~= friendData then
	--	return;
	--end
	
	BP_ChatProfileRspGid = profile.gid;
	BP_ChatProfileRspUrl = profile.url;
	BP_ChatProfileRspGender = profile.gender;
	BP_ChatProfileRspNickName = profile.nickName;	
	BP_ChatProfileRspLevel = profile.level;
	BP_ChatProfileRspMaxSegment = profile.segmentMax;
	BP_ChatProfileRspAvatarBox = profile.avatarBox;
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnGetProfileInfo");
end

function LobbyChatLogic.HandleVoiceRoomChange(room_name)	
	if not BP_ChatMainValid then
		return;
	end
		
	BP_ChatVoiceTeamRoom = room_name;
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnTeamVoiceRoomChanged");
end

function LobbyChatLogic.OnAfterVoiceInited()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnVoiceInited");
end

function LobbyChatLogic.OnJoinRoomSuccess()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnJoinRoomSuccess");
end

function LobbyChatLogic.OnQuitRoomSuccess()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnQuitRoomSuccess");
end

function LobbyChatLogic.OnClearVoiceProcedure()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnClearVoiceProcedure");
end

function LobbyChatLogic.OnStopPlayRecordFile()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnStopPlayRecordFile");
end

function LobbyChatLogic.OnStartPlayRecordFile()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnStartPlayRecordFile");
end

function LobbyChatLogic.OnStartRecordVoice()
    
    log("LobbyChatLogic.OnStartRecordVoice()");
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnStartRecordVoice");
end

function LobbyChatLogic.OnStopRecordVoice()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnStopRecordVoice");
end

function LobbyChatLogic.OnCancelRecordVoice()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnCancelVoiceRecord");
end

function LobbyChatLogic.OnUploadRecordVoice()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnUploadRecordVoice");
end

function LobbyChatLogic.OnUploadToTextComplete(content, length, msg_id)
	if not BP_ChatMainValid then
		return;
	end
	
	BP_ChatContent = content;
	BP_ChatVoiceUploadTime = length;
	BP_ChatVoiceUploadMsgId = msg_id;
	
	log("upload to text complete .. " .. tostring(length));
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnSpeechToTextComplete");
end

function LobbyChatLogic.OnApplicationDeactivated()
	if not BP_ChatMainValid then
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnApplicationDeactivated");
end

function LobbyChatLogic.OnRefreshTeamupState()

end

function LobbyChatLogic.CheckHasRightToCreateOrJoinRoom()
	local roomOpenLvStr = DataMgr.GetSystemConfig("ChatRoomOpenLv");
	local roomOpenLv = roomOpenLvStr == nil and 0 or tonumber(roomOpenLvStr);
	
	local satisfyLevel = DataMgr.roleData.level >= roomOpenLv;
	if (not satisfyLevel) then
		DataMgr.ShowNoticeByID(106059);
		return false;
	end
	return true;
end

function LobbyChatLogic.CheckHasRightToChat()
	local worldOpenLvStr = DataMgr.GetSystemConfig("ChatWordOpenLv");
	local worldOpenLv = worldOpenLvStr == nil and 0 or tonumber(worldOpenLvStr);
	if (BP_ChannelType == LobbyChatSystem.channelWorld) then
		local satisfyLevel = DataMgr.roleData.level >= worldOpenLv;
		if (not satisfyLevel) then
			DataMgr.ShowNoticeByID(106017);
			return false;
		end
	elseif (BP_ChannelType == LobbyChatSystem.channelChatRoom) then
		if (BP_ChatMainMyRoomId == "0") then
			DataMgr.ShowNoticeByID(106057);
			return false;
		end
	end
	return true;
end	

function LobbyChatLogic.UpdateTeamupMenu(team_state, online)
	if not BP_ChatMainValid then
		return;
	end;
	
	if 1 == online then
		if 0 == team_state then
			LuaClassObj.HandleUIMessage(bp_chat_main, "OnTeamupStateCanInvice");
		elseif 1 == team_state then
			LuaClassObj.HandleUIMessage(bp_chat_main, "OnTeamupStateCanJoin");
		elseif 2 == team_state then
			LuaClassObj.HandleUIMessage(bp_chat_main, "OnTeamupStateCanInvice");
		end
	end	
end

function LobbyChatLogic.OnShowChatroomList()
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnShowChatroomList");
end

function LobbyChatLogic.OnShowMyChatroom()
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnShowMyChatroom");
end

function LobbyChatLogic.ShowHover()
	LuaClassObj.HandleUIMessage(bp_chat_main, "ShowHover");
end

function LobbyChatLogic.HideHover()
	LuaClassObj.HandleUIMessage(bp_chat_main, "HideHover");
end

function LobbyChatLogic.OnEmojiItemClicked(index)
	BP_ChatEmojiClickItem = index;
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnEmojiItemClicked");
end

function LobbyChatLogic.RefreshChatRoom()
	LuaClassObj.HandleUIMessage(bp_chat_main, "RefreshChatRoom");
end

function LobbyChatLogic.ReprofileBaseInfo()
	if false == BP_ChatMainShown then
		return;
	end

	LobbyChatLogic.chatBackGroundProfile = true;
end

function LobbyChatLogic.Tick()
	LobbyChatLogic.ReprofileTimerTick();
end

function LobbyChatLogic.ReprofileTimerTick()
	if false == LobbyChatLogic.chatBackGroundProfile then
		return;
	end
	
	if BP_ChannelType == LobbyChatLogic.channelInvalid or false == BP_ChatMainShown then	
		LobbyChatLogic.chatBackGroundProfile = false;
		return;
	end	
	
	if BP_ChannelType == LobbyChatSystem.channelWorld then
		if 0 == #LobbyChatLogic.chatProfileWorldBufferReq then			
			LobbyChatLogic.chatBackGroundProfile = false;			
			return;
		end		
	else			
		if 0 == #LobbyChatLogic.chatProfileBufferReq then
			LobbyChatLogic.chatBackGroundProfile = false;			
			return;
		end		
	end
	
	if BP_ChannelType == LobbyChatSystem.channelWorld then
		local gid = LobbyChatLogic.chatProfileWorldBufferReq[1];
		LobbyChatSystem.on_profile_req(gid);
		table.remove(LobbyChatLogic.chatProfileWorldBufferReq, 1);		
	else
		local gid = LobbyChatLogic.chatProfileBufferReq[1];
		LobbyChatSystem.on_profile_req(gid);
		table.remove(LobbyChatLogic.chatProfileBufferReq, 1);			
	end
end

function EventPopMessageBuffer()
	LobbyChatSystem.PopBufferList();
end

function EventGetProfile()
	if "" == BP_ChatProfileReqGid then
		return;
	end
	
	if BP_ChatMainShown then
		if BP_ChatProfileReqGid == BP_ChatMyGID then		
			
			local profileData = {};
			profileData.gid = BP_ChatMyGID;
			profileData.url = DataMgr.roleData.headIconUrl;
			profileData.nickName = DataMgr.roleData.nickName;
			profileData.gender = DataMgr.roleData.gender;
			profileData.level = DataMgr.roleData.level;
			profileData.segmentSolo = DataMgr.roleData.segment.solo;
			profileData.segmentDuo = DataMgr.roleData.segment.double;
			profileData.segmentSquad = DataMgr.roleData.segment.team;
			profileData.segmentMax = DataMgr.GetMaxRankLevel();--math.max(profileData.segmentSolo, profileData.segmentDuo, profileData.segmentSquad);
			profileData.avatarBox = DataMgr.roleData.cur_avatar_box_id;
			
			table.insert(LobbyChatSystem.chatProfileInfoList, profileData);
			
			LobbyChatLogic.RefreshProfileData(profileData);
			return;
		else
			local friendData = FriendSystem.GetFriendDataByGID(tonumber(BP_ChatProfileReqGid));
			if nil ~= friendData then
				local profileData = {};
				profileData.gid = BP_ChatProfileReqGid;
				profileData.url = friendData.picUrl;
				profileData.nickName = friendData.nickName;
				profileData.gender = friendData.sex;
				profileData.level = friendData.level;
				profileData.segmentSolo = friendData.segment_info_solo;
				profileData.segmentDuo = friendData.segment_info_duo;
				profileData.segmentSquad = friendData.segment_info_squad;
				profileData.segmentMax = math.max(profileData.segmentSolo, profileData.segmentDuo, profileData.segmentSquad);
				profileData.avatarBox = friendData.cur_avatar_box_id;
				
				table.insert(LobbyChatSystem.chatProfileInfoList, profileData);
				
				LobbyChatLogic.RefreshProfileData(profileData);
				return;
			end
		end
		
		LobbyChatSystem.on_profile_req(BP_ChatProfileReqGid);
	else
		if BP_ChannelType == LobbyChatSystem.channelWorld then
			if BP_ChatProfileReqGid ~= BP_ChatMyGID then
				local contains = false;
				for i = 1, #LobbyChatLogic.chatProfileWorldBufferReq do
					if BP_ChatProfileReqGid == LobbyChatLogic.chatProfileWorldBufferReq[i] then					
						return;
					end
				end
				
				if #LobbyChatLogic.chatProfileWorldBufferReq > 5 then
					table.remove(LobbyChatLogic.chatProfileWorldBufferReq, 1);
				end
				
				table.insert(LobbyChatLogic.chatProfileWorldBufferReq, BP_ChatProfileReqGid);				
			end
		else
			if BP_ChatProfileReqGid ~= BP_ChatMyGID then
				for i = 1, #LobbyChatLogic.chatProfileBufferReq do 
					if BP_ChatProfileReqGid == LobbyChatLogic.chatProfileBufferReq[i] then
						return;
					end
				end
			
				if #LobbyChatLogic.chatProfileBufferReq > 10 then
					table.remove(LobbyChatLogic.chatProfileBufferReq, 1);
				end
				
				table.insert(LobbyChatLogic.chatProfileBufferReq, BP_ChatProfileReqGid);
			end
		end			
	end	
end

function EventSwitchToFriendChat()
	local msgData = LobbyChatSystem.friendChatList[BP_SelectedFriendGID];
	--local msgData = LobbyChatSystem.GetFriendChatItem(BP_SelectedFriendGID);
	if nil == msgData then
		return;
	end
	
	msgData.newMessageCount = 0;
	LobbyChatSystem.on_notify_friend_unread(BP_SelectedFriendGID, 0);
	-- TODO entrance notify unread
end

function EventTryStartRecordVoice()
	if not BP_ChatMainValid then 
		return;
	end
	
	GlobalChatVoice.TryStartRecordVoice();
end

function EventTryStopRecordVoice()
	if not BP_ChatMainValid then 
		return;
	end
	
	GlobalChatVoice.TryStopRecordVoice();
end

function EventTryCancelRecordVoice()
	if not BP_ChatMainValid then 
		return;
	end
	
	GlobalChatVoice.TryCancelRecordVoice();
end

function EventTryStopPlayRecordVoice()
	if not BP_ChatMainValid then 
		return;
	end
	
	GlobalChatVoice.TryStopPlayRecordVoice();
end

function EventInputChatMsg()
	if not BP_ChatMainValid then
		return;
	end

	local content = BP_ChatInputContent;
	_, _, content = FuncUtil:CheckName(BP_ChatInputContent);
	
	BP_ChatInputFilteredContent = content;
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnInputTextFiltered");
end

function EventSendChatMsg()
	if not BP_ChatMainValid then 
		log("send msg chat main not valid");
		return;
	end

	local satisfy = LobbyChatLogic.CheckHasRightToChat();
	if (not satisfy) then
		log("send msg has no right to chat");
		return;
	end
	
	sandbox.LogNormal(string.format("send msg [%d][%s][%s]", BP_ChannelType, BP_SelectedFriendGID, BP_ChatContent));	
	
	local content = BP_ChatContent;
	_, _, content = FuncUtil:CheckName(BP_ChatContent);
	
	if "" == content then 
		EventNotifyNoText();
		return;
	end
	
	if (BP_ChannelType == LobbyChatSystem.channelChatRoom) and ("0" ~= BP_ChatMainMyRoomId) and (""~= BP_ChatMainMyRoomId) then
		LobbyChatSystem.on_chat_req(tonumber(BP_ChatMainMyRoomId), BP_ChannelType, BP_ChatContent);
	else
		LobbyChatSystem.on_chat_req(tonumber(BP_ReceiverGID), BP_ChannelType, BP_ChatContent);
	end
end

function EventSendChatVoiceMsg()
	if not BP_ChatMainValid then 
		return;
	end	
	
	local satisfy = LobbyChatLogic.CheckHasRightToChat();
	if (not satisfy) then
		return;
	end		
	
	sandbox.LogNormal(string.format("send voice msg [%d][%s][%s]", BP_ChannelType, BP_SelectedFriendGID, BP_ChatContent));	
	
	if (BP_ChannelType == LobbyChatSystem.channelChatRoom) and ("0" ~= BP_ChatMainMyRoomId) and (""~= BP_ChatMainMyRoomId) then
		LobbyChatSystem.on_voice_chat_req(tonumber(BP_ChatMainMyRoomId), BP_ChannelType, BP_ChatVoiceUploadMsgId, BP_ChatVoiceUploadTime, BP_ChatContent);
	else
		LobbyChatSystem.on_voice_chat_req(tonumber(BP_ReceiverGID), BP_ChannelType, BP_ChatVoiceUploadMsgId, BP_ChatVoiceUploadTime, BP_ChatContent);
	end
end

function EventHideChatMainWnd()
	if not LobbyChatSystem.canOpenChatWnd then
		return;
	end
	
	if not BP_ChatMainValid then
		return;
	end
	
	BP_ChatMainShown = false;		
	LobbyChatEntranceUI:Init()
end

function EventFetchFriendData()
	if not BP_ChatMainValid then
		return;
	end
		
	BP_ARRAY_ChatFriendList = nil;
	BP_ARRAY_ChatFriendList = {};
	BP_ARRAY_ChatFriendList = FriendSystem.SortFriendList();
	
	if nil == BP_ARRAY_ChatFriendList then
		sandbox.LogNormal("!!!!!!!!!!!!!!!!!!!empty friend list !!!!!!!!!!!!!!!!");
		return;
	end
	
	BP_ChatOnlineFriendCout = 0;
	BP_ChatTotalFriendCount = #BP_ARRAY_ChatFriendList;
	for i = 1, BP_ChatTotalFriendCount do
		local friendInfo = BP_ARRAY_ChatFriendList[i];
		if friendInfo.online == 1 then
			BP_ChatOnlineFriendCout = BP_ChatOnlineFriendCout + 1;
		end
	end	
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "RefreshFriendList");
end

function EventNotifyFriendChatRequireSelect()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106019).TextValue);
end

function EventNotifyOutofTextRange()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 100006).TextValue);
end

function EventNotifyVoiceChatFailToRecord()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106012).TextValue);
end

function EventNotifyVoiceRecordTooShort()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106015).TextValue);
end

function EventNotifyNoText()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106018).TextValue);
end

function EventChangeVoiceChatMode()	
end

function EventChangeChannelType()
	--log("chat main " .. tostring(BP_ChatMainShown))
	if BP_ChannelType == LobbyChatSystem.channelWorld then
		BP_WorldNewMessageCount = 0;
	elseif BP_ChannelType == LobbyChatSystem.channelTeam then
		BP_TeamNewMessageCount = 0;
	elseif BP_ChannelType == LobbyChatSystem.channelPrivate then
		FriendSystem.CheckFetchFriendList();
	elseif BP_ChannelType == LobbyChatSystem.channelChatRoom then
		LobbyChatroomLogic.Show();
		
		if true == BP_ChatMainShown then
			BP_ChatRoomNewMessageCount = 0;
		end
		LobbyChatSystem.get_channel_list_req();	--切页签则重新读取
	end
	
	if BP_ChannelType ~= LobbyChatSystem.channelChatRoom then
		LobbyChatroomLogic.Hide();
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnChangeChannelType");
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnRefreshUnread");
	LobbyChatEntranceUI.RefreshChatroomUnread(BP_ChatRoomNewMessageCount);
	
	LobbyChatLogic.ReprofileBaseInfo();
	--log("chat main unread " .. tostring(BP_ChatRoomNewMessageCount))
end

function EventCheckTodayDate()
	BP_ChatTodayDate = os.date("%Y-%m-%d");
end

function EventCheckBlackList()
	BP_ChatHoverIsPullBlack = false;
	
	if "" == BP_ChatSelectedGID then
		return;
	end
	
	BP_ChatHoverIsPullBlack = FriendSystem.IsPulBlack(BP_ChatSelectedGID);
end

function EventCheckFriendList()
	BP_ChatHoverIsFriend = false;
	
	if "" == BP_ChatSelectedGID then
		return;
	end
	
	BP_ChatHoverIsFriend = FriendSystem.IsMyFriend(BP_ChatSelectedGID);
	--[[
	if nil == BP_ARRAY_ChatFriendList or 0 == #BP_ARRAY_ChatFriendList then
		return;
	end
	
	for i = 1, #BP_ARRAY_ChatFriendList do
		local friendData = BP_ARRAY_ChatFriendList[i];
		if friendData.gid == BP_ChatSelectedGID then
			BP_ChatHoverIsFriend = true;
			return;
		end
	end]]
end

function EventShowEmoji()
	LobbyChatEmojiLogic.Show()
end

function EventHideEmoji()
	LobbyChatEmojiLogic.Hide()
end

function EventShowHover()
	LobbyChatroomLogic.OnChatMainShowHover();
end

function EventHideHover()

end

function EventHoverShowFriendInfo()
	if "" == BP_ChatSelectedGID then
		return;
	end
	
	ProfileMgr.GetProfile(tonumber(BP_ChatSelectedGID), LobbyChatSystem.ProfileCallBack, true);
	RoleInfoSystem.Enter(BP_ChatSelectedGID);
	RoleInfoUI.Init();
end

function EventHoverAddFriend()
	if "" == BP_ChatSelectedGID then
		return;
	end
	
	FriendSystem.AddFriend(BP_ChatSelectedGID,BP_ENUM_ADD_FRIEND_FROM_CHAT);
end

function EventHoverBlockTarget()
	if "" == BP_ChatSelectedGID then
		return;
	end
	
	if true == BP_ChatHoverIsPullBlack then
		DataMgr.ShowNoticeByID(106065);
	else
		FriendSystem.AddBlack(BP_ChatSelectedGID);
	end	
end

function EventHoverInviteTeam()
	if "" == BP_ChatHoverGID then
		return;
	end
	
	TeamUpSystem.team_invite_request(tonumber(BP_ChatHoverGID));
	
end

function EventHoverJoinTeam()
	if "" == BP_ChatHoverGID then
		return;
	end
	
	TeamUpSystem.team_apply_request(tonumber(BP_ChatHoverGID));
end

function EventHoverReportTarget()
	if "" == BP_ChatHoverGID or "" == BP_ChatHoverContent or "" == BP_ChatHoverName then
		log("report target" .. BP_ChatHoverGID .. BP_ChatHoverContent.. BP_ChatHoverName );
		return;
	end
	
	LobbyChatSystem.on_report_req(BP_ChatHoverGID, BP_ChatHoverName, BP_ChatHoverContent);
end

function EventRecruitMember()
	log("EventRecruitMember:"..BP_ChatRecruitJoinGid.."--temid:"..BP_ChatRecruitTeamID)
	if "" == BP_ChatRecruitJoinGid then
		return;
	end

	if "" == BP_ChatRecruitTeamID then
		return;
	end

	local src = "normal";
	if BP_ChannelType == LobbyChatSystem.channelWorld then		
		src="world-chat";	
	elseif BP_ChannelType == LobbyChatSystem.channelChatRoom then
		src="channel-chat";
	end
	
	TeamUpSystem.JoinTeamByChat(BP_ChatRecruitJoinGid,BP_ChatRecruitTeamID, src);
	--JoinTeamByChat();
end

function EventOpenRecruitPanel()
	RecruitUI.ShowUI();
end

function EventClickFriendItem()	
	if not BP_ChatMainValid then
		return;		
	end	
		
	if false == BP_ChatMainShown then
		return;
	end	
	
	log("friend chat click .. " .. BP_SelectedFriendGID);
	
	local msgData = LobbyChatSystem.friendChatList[FuncUtil:StrTrim(BP_SelectedFriendGID)];
	--local msgData = LobbyChatSystem.GetFriendChatItem(BP_SelectedFriendGID);
	if nil ~= msgData then				
		msgData.newMessageCount = 0;
		BP_ARRAY_FriendChatList = FuncUtil:CopyTable(msgData.messageList);
	else		
		BP_ARRAY_FriendChatList = {};
	end
	
	LobbyChatLogic.RefreshUnreadList(BP_SelectedFriendGID, 0);
	LobbyChatSystem.RefreshTotalUnread();
end

function EventDownloadVoiceFile()
	if not BP_ChatMainValid then
		return;		
	end	
	
	GlobalChatVoice.AddDownloadFile(BP_ChatVoiceDownloadOwnerGid, "", BP_ChatVoiceDownloadChannel, 
		BP_ChatVoiceDownloadMsgId, BP_ChatVoiceDownloadMsgLength, BP_ChatVoiceDownloadFileId);	
end

function EventAchieveVoiceRoom()
	BP_ChatVoiceTeamRoom = LobbyChatSystem.voiceEnterRoomId;
end

function EventInitJoinRoom()	
end

function EventOnAfterShowWnd()
	LobbyChatSystem.chatWndOpen = true;
	BP_ChatMainShown = true;
	TeamUpSystem.recv_stau_request(true);
	
	if BP_ChannelType == LobbyChatSystem.channelChatRoom then
		LobbyChatroomLogic.Show()
	end
	
	LobbyChatLogic.ReprofileBaseInfo();
	-- EventClickFriendItem();
end

function EventOnAfterHideWnd()
	LobbyChatSystem.chatWndOpen = false;
	
	TeamUpSystem.recv_stau_request(false);
	
	LobbyChatroomLogic.Hide();
	LobbyChatEmojiLogic.Hide();
end

function EventRequireHoverTeamup()
	if "" == BP_ChatHoverGID then
		return;
	end
	
	TeamUpSystem.stange_all_status_request(BP_ChatHoverGID);
end

function EventChatVoiceCheckBan()    
    BP_ChatVoiceBan = 0;
    if(DataMgr.ban ~= nil) then
        if(DataMgr.ban[2] ~= nil and type(DataMgr.ban[2]) == "table") then
            BP_ChatVoiceBan = 1;
        end
    end
    log("ChatVoiceBan = "..BP_ChatVoiceBan);
end

function EventChatVoiceBanInfo()
    log("EventChatVoiceCheckBan");
    if(DataMgr.ban ~= nil) then
        if(DataMgr.ban[2] ~= nil and type(DataMgr.ban[2]) == "table") then
            local time = DataMgr.ban[2].end_time;
            local reason = DataMgr.ban[2].reason;
            --local date = os.date("%Y年%m月%d日%H时%M分%S秒", time);
            --CommonMessageBoxUI:ShowPanel(1, "提示", reason.."\n解封时间为: "..date);
			local date = os.date(Client.GetTableData("LocalizeRes",115005).TextValue, time);
			local title = Client.GetTableData("LocalizeRes", "101001").TextValue
			local deblockingStr = string.format(Client.GetTableData("LocalizeRes",301129).TextValue, tostring(date));
			CommonMessageBoxUI:ShowPanel(1, title, reason..deblockingStr);
        end
    end
end

function LobbyChatLogic.OnTranslate(ChatChannel, ChatId, LanguageFrom, Text)
    log("LobbyChatLogic.OnTranslate=" .. Text);
    BP_ChatTranslateChannel = ChatChannel;
    BP_ChatTranslateID = ChatId;
	BP_ChatLanguageFrom = LanguageFrom;
	BP_ChatTranslateText = Text;
	LuaClassObj.HandleUIMessage(bp_chat_main, "OnTranslate");
end
