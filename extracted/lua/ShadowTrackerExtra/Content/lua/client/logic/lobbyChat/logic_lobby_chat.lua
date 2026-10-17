--[[
聊天消息数据管理
]]--

LobbyChatSystem = LobbyChatSystem or
{
	chatInited = false;
		
	chatBufferList = {};			--消息缓存列表
	
	chatProfileInfoList = {};		-- 聊天对象概要信息列表
	
	MAX_MESSAGE_BUFFER_CACHE_NUM = 100;	--消息队列缓存列表
	MAX_MESSAGE_CACHE_NUM = 50;    		--历史消息的最大支持条数
	MAX_MESSAGE_CHATROOM_HISTORY_CACHE = 20;
	MAX_FRIEND_MESSAGE_CACHE_NUM = 50;	
	MAX_PROFILE_CACHE_NUM = 30;
	MAX_CHATROOM_MEMBER = 200;		--TODO 讨论人数上限
	STATIC_MESSAGE_COUNTER = 1;
	STATIC_SELF_MESSAGE_COUNTER = 1;
	
	--聊天频道（系统消息，世界频道，战队以及私聊）
	channelSystem = 1;
	channelWorld = 2;
	channelTeam = 3;
	channelPrivate = 4;
	channelChatRoom = 5;
	channelInvalid = -1;
		
	chatMsgType = 0;
	chatInviteType = 1;
	chatSelfMark = 0;
	
	chatEnterFight = false;
	chatWndOpen = false;
	chatTodayDate = "";
	
	canOpenChatWnd = true;
	chatRoomQueryPassword = false;
	
	chatNewestFriendChat = "";
	chatSelectedFriendInFight = "";
	
	friendReservingList = {};
	friendReservedInFight = {};	
	friendReservationFromLobby = {};
	
	FriendChatData =
	{
		gid = 0,
		newMessageCount = 0,
		lastMsgSendTime = 0,
		messageList = 
		{
			BP_STRUCT_ChatMessageSingleData = _G.BP_STRUCT_ChatMessageSingleData,
		};
	};

	friendChatList = 
	{
		
	};
	
	fightFriendChatList = 
	{
	};
	
	tempNewMessageList = 
	{
	};
	
	channelList = 
	{
	};	
	
	chatRoomLastMsgTime = 0;
	chatRoomMsgCounter = 0;
	chatRoomMsgMaxLimit = 8;
	chatRoomStatusDict = {};
	chatRoomPasswordContainer = {};
	chatRoomMyCreateCount = 0;
	chatRoomMaxCreate = 1;
}

--[[
-----------聊天消息发送接口--------------
receiver         私聊的接收者，如果不是私聊这个字段不用
channelType      要发送的聊天频道
msgId            私聊的消息计数,可以是客户端维护
content          聊天内容
]]

function LobbyChatSystem.Entry()
	if not LobbyChatSystem.canOpenChatWnd then
		return;
	end
	
	LobbyChatSystem.Init();
	LobbyChatEntranceUI.Init();
	LobbyChatSystem.ClearFight();
	LobbyChatSystem.EnterLobby();
end

function LobbyChatSystem.Init()
	if not LobbyChatSystem.chatInited then
		LobbyChatSystem.chatInited = true;
		LobbyChatSystem.Construct();		
	end	
	
	LobbyChatLogic:PreInit();
end

function LobbyChatSystem.Release()
	if LobbyChatSystem.chatInited then
		LobbyChatSystem.Destruct();
	end	
	
	LobbyChatSystem.friendReservingList = {};
	LobbyChatSystem.friendReservedInFight = {};
	LobbyChatSystem.friendReservationFromLobby = {};
	LobbyChatSystem.ClearFight();
	LobbyChatSystem.chatInited = false;
end

function LobbyChatSystem.EnterLobby()
	local reservationLength = #LobbyChatSystem.friendReservationFromLobby;
	if reservationLength > 0 then
		local reservation = LobbyChatSystem.friendReservationFromLobby[reservationLength];
		CommonRightNotifyUI.ShowNotify(reservation, nil);
		LobbyChatSystem.friendReservationFromLobby = {};
	end
end

function LobbyChatSystem.EnterFight()	
	LobbyChatSystem.chatEnterFight = true;
	LobbyChatSystem.friendReservingList = {};
	LobbyChatSystem.friendReservedInFight = {};
end

function LobbyChatSystem.ClearFight()
	LobbyChatSystem.chatEnterFight = false;
	LobbyChatSystem.chatSelectedFriendInFight = "";
	LobbyChatSystem.fightFriendChatList = {};		
end

function LobbyChatSystem.Construct()
	EventSystem:registEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN, LobbyChatSystem.on_backto_login);
	EventSystem:registEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC, LobbyChatSystem.on_teamup_info_changed);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, LobbyChatSystem.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, LobbyChatSystem.WardRobeAvatarResetClose);
end

function LobbyChatSystem.Destruct()
	EventSystem:unregistEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC, LobbyChatSystem.on_teamup_info_changed);
	EventSystem:unregistEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, LobbyChatSystem.on_backto_login);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, LobbyChatSystem.WardRobeAvatarResetOpen);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, LobbyChatSystem.WardRobeAvatarResetClose);
	
	GlobalChatVoice.ClearRoleInfo();
end

function LobbyChatSystem.WardRobeAvatarResetOpen()
    log("LobbyChatSystem.WardRobeAvatarResetOpen")
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIHide");
end

function LobbyChatSystem.WardRobeAvatarResetClose()
    log("LobbyChatSystem.WardRobeAvatarResetClose")
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIShow");
end

function LobbyChatSystem:OpenUI()
	TeamUPFriendUI.HidePanel();
	LobbyChatLogic.OpenUI();
end

function LobbyChatSystem.UpdateFriend()
	LobbyChatLogic.RefreshFriendState();
end

function LobbyChatSystem.DeleteFriend(uid)
	LobbyChatSystem.friendChatList[tostring(uid)] = nil;
	
	if LobbyChatSystem.chatNewestFriendChat == tostring(uid) then
		LobbyChatSystem.chatNewestFriendChat = ""
	end
	
	LobbyChatLogic.DeleteFriend(tostring(uid));
	LobbyChatSystem.RefreshTotalUnread();
end

function LobbyChatSystem.RefreshTotalUnread()
	local unreadCount = 0;
	for k, v in pairs(LobbyChatSystem.friendChatList) do
		unreadCount = unreadCount + v.newMessageCount;
	end
	
	LobbyChatLogic.RefreshFriendTotalUnread();
	LobbyChatEntranceUI.RefreshUnreadList(unreadCount);	
end

--[[
	gid: string
]]
function LobbyChatSystem.ChatWithFriend(gid)	
	--LobbyChatEntranceUI.OpenChatUI();	
	LobbyChatLogic.ChatWithFriend(gid);
end

function LobbyChatSystem.NewestFriendChatSort(lhs, rhs)
	return lhs.newMsgTime > rhs.newMsgTime;
end

function LobbyChatSystem.OpenNewestFriendChat()
	LobbyChatSystem.tempNewMessageList = {};
	
	for k, v in pairs(LobbyChatSystem.friendChatList) do
		if 0 ~= v.newMessageCount then
			local newMsgTrunk = {};
			newMsgTrunk.gid = k;
			newMsgTrunk.newMsgTime = v.lastMsgSendTime;
			table.insert(LobbyChatSystem.tempNewMessageList, newMsgTrunk);			
		end
	end
	
	if 0 == #LobbyChatSystem.tempNewMessageList then
		return;
	end

	table.sort(LobbyChatSystem.tempNewMessageList, LobbyChatSystem.NewestFriendChatSort);
	
	LobbyChatSystem.ChatWithFriend(LobbyChatSystem.tempNewMessageList[1].gid);
end

function LobbyChatSystem.ChangeTeamType(teamType)

end

function LobbyChatSystem.ChangeTickBuffer()
	if #LobbyChatSystem.chatBufferList > LobbyChatSystem.MAX_MESSAGE_BUFFER_CACHE_NUM then
		for i = LobbyChatSystem.MAX_MESSAGE_BUFFER_CACHE_NUM + 1, #LobbyChatSystem.chatBufferList do
			table.remove(LobbyChatSystem.chatBufferList, 1);
		end
	end
	
	LobbyChatEntranceUI.RefreshTickBufferState();	
end

function LobbyChatSystem.PopBufferList()	
	if nil == LobbyChatSystem.chatBufferList or 0 == #LobbyChatSystem.chatBufferList then
		LobbyChatSystem.ChangeTickBuffer();
		return;
	end
	
	local bufferData = LobbyChatSystem.chatBufferList[1];
	--log("LobbyChatSystem.PopBufferList:",bufferData.chat_content.text);
	LobbyChatSystem.chat_true_notify(bufferData.chat_type, bufferData.sender_name, bufferData.msg_id, bufferData.chat_content, bufferData.sender_uid);	
	table.remove(LobbyChatSystem.chatBufferList, 1);
end

function LobbyChatSystem.ReplaceEmoji(chat_ctt)
	local ctt = chat_ctt;
	for emoji in string.gmatch(chat_ctt, "%%%d+") do
		local num = string.match(emoji, "%d+");
		if string.len(num) >= 3 then
			num = string.sub(num, 1, 2);
		end
		
		local no = tonumber(num);
		if no < 1 then
			;
		elseif no > 64 then
			num = tostring(math.floor(no / 10));			
			ctt = string.gsub(ctt, "%%" .. num, "<img src=\"Emoji1_22_".. num .."\"/>", 1);
		else
			ctt = string.gsub(ctt, "%%" .. no, "<img src=\"Emoji1_22_".. num .."\"/>", 1);
		end			
	end
	
	return ctt;
end

function LobbyChatSystem.on_report_req(uid, name, content)		
	local strTitle = DataMgr.GetMsgByID(102012);
	local fmtMsg = Client.GetTableData("LocalizeRes", 106069);
	local str = string.format(fmtMsg.TextValue, name);

	CommonMessageBoxUI:ShowPanel(2, strTitle, str, 
		function()
			local securityLog = {};
			securityLog.ReportRoleID = tonumber(uid);
			securityLog.UserName = name;
			securityLog.ComplaintType2 = 2;
			PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106068).TextValue);
			
			NetUtil.SendPkg("report_info", securityLog);
		end
	);	
end

function LobbyChatSystem.on_report_rsp(res)
	log("on_report_rsp");
end

function LobbyChatSystem.ProfileCallBack(profile_list)
	if nil == profile_list or 0 == #profile_list then
		return;
	end
	
	for i = 1, #profile_list do 
		local dat = profile_list[i];
		local profileData = {};
		profileData.gid = tostring(math.floor(dat.uid));
		profileData.url = dat.picUrl;
		profileData.nickName = dat.nickName;
		profileData.gender = dat.sex;		
		profileData.level = dat.level;
        
        ----------------------------------------intl modify--------------------------------------
        --[[
		profileData.segmentSolo = dat.segment_info[1];
		profileData.segmentDuo = dat.segment_info[2];
		profileData.segmentSquad = dat.segment_info[3];
		profileData.segmentMax = math.max(profileData.segmentSolo, profileData.segmentDuo, profileData.segmentSquad);
        ]]
        --waynedong todo  check
        -- 取全区最高的段位设置当前段位（最终是用到蓝图中设置称号用的，因此只需要取所有区中最高段位的一个保存即可）
        all_segment_info = dat.segment_info;
        --[[
        maxSegment = -1;
        for k,v in pairs(all_segment_info) do
            local segemnt_solo = all_segment_info[k][1];
            local segemnt_duo =  all_segment_info[k][2];
            local segemnt_squad =  all_segment_info[k][3];
            --log("chatwaynedong: segemnt_solo = "..segemnt_solo..", segemnt_duo = "..segemnt_duo..", segemnt_squad = "..segemnt_squad)
            local tmpmax = math.max(segemnt_solo, segemnt_duo, segemnt_squad);
            if maxSegment < tmpmax then
                maxSegment = tmpmax;
                profileData.segment_info_solo = segemnt_solo;
                profileData.segment_info_duo = segemnt_duo;
                profileData.segment_info_squad = segemnt_squad;
            end
             log("chatwaynedong:profileData.segment_info_solo = "..profileData.segment_info_solo..", profileData.segment_info_duo = "..profileData.segment_info_duo..", profileData.segment_info_squad = "..profileData.segment_info_squad)
        end
        ]]
        profileData.segment_info_solo,  profileData.segment_info_duo,  profileData.segment_info_squad =  FuncUtil.GetMaxSegement( all_segment_info );
        
        ----------------------------------------intl modify--------------------------------------
		profileData.avatarBox = dat.cur_avatar_box_id;		
		LobbyChatLogic.RefreshProfileData(profileData);
	end
end

function LobbyChatSystem.on_profile_req(uid)
	--log("get profile in chat " .. uid);
	ProfileMgr.GetProfile(tonumber(uid), LobbyChatSystem.ProfileCallBack, false);
	--NetUtil.SendPkg("batch_get_profile_req", "", {tonumber(uid)}, "chat");
end

function LobbyChatSystem.on_profile_rsp(listType, res, role_basic_info_list, systemType)
	if "chat" ~= systemType then		
		return;
	end
end

--[[
	receiver_uid (number)
]]

function LobbyChatSystem.on_chat_quick_msg(content)
	log("on_chat_quick_msg,content:"..content);
	if nil == content or "" == content then
		return;
	end
		
	--log("LobbyChatSystem.on_chat_quick_msg:"..content);
	local tabContent = {};
	tabContent.voice = "";
	--快捷聊天不过滤 _, _, tabContent.text = FuncUtil:CheckName(content);
	tabContent.text = content;
	tabContent.voiceLength = 0;	
	tabContent.quickMsg = true;
	tabContent.msgType = 0;	
	tabContent.msgID = content;
	--log("LobbyChatSystem.on_chat_quick_msg:"..tabContent.text);
	NetUtil.SendPkg("chat_req", 0, LobbyChatSystem.channelTeam, 0, tabContent);
end

function LobbyChatSystem.on_chat_req(receiver_uid, channelType, content)

	if nil == content or "" == content then
		return;
	end		
	
	local tabContent = {};
	tabContent.voice = "";
	--_, _, tabContent.text = FuncUtil:CheckName(content);
	tabContent.text = content;
	tabContent.voiceLength = 0;	
	tabContent.quickMsg = false;
	tabContent.msgType = 0;	
	
	sandbox.LogNormal(tostring(channelType) .. "send chat req" .. tabContent.text);
	
	if  channelType == LobbyChatSystem.channelPrivate then
		if 0 ~= receiver_uid then
			local isFriend = FriendSystem.IsMyFriend(receiver_uid);
			if isFriend then
				NetUtil.SendPkg("chat_req", receiver_uid, channelType, 0, tabContent);
			else
				PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106020).TextValue);
			end			
		end
	else
		sandbox.LogNormal(tostring(channelType) .. "send chat req" .. content);
		if channelType == LobbyChatSystem.channelChatRoom then
			NetUtil.SendPkg("chat_req", receiver_uid, channelType, 0, tabContent);
		else
			NetUtil.SendPkg("chat_req", 0, channelType, 0, tabContent);
		end
	end
end

function LobbyChatSystem.on_voice_chat_req(receiver_uid, channel_type, voice_id, msg_time, content)
	if nil == voice_id or "" == voice_id then
		return;
	end
	
	local tabContent = {};
	tabContent.voice = voice_id;
	--_, _, tabContent.text = FuncUtil:CheckName(content);
	tabContent.text = content;
	tabContent.voiceLength = msg_time;
	tabContent.quickMsg = false;
	tabContent.msgType = 0;
	
	if channel_type == LobbyChatSystem.channelPrivate then
		sandbox.LogNormal("send voice chat req with msgId " .. voice_id .. " to " .. tostring(receiver_uid) .. content);
				
		NetUtil.SendPkg("chat_req", receiver_uid, channel_type, 0, tabContent);
	else
		sandbox.LogNormal("send voice chat req with msgId " .. voice_id .. content);
		
		if channel_type == LobbyChatSystem.channelChatRoom then
			sandbox.LogNormal("send voice chat req with msgId to chatroom " .. tostring(receiver_uid) .. voice_id .. content);
			NetUtil.SendPkg("chat_req", receiver_uid, channel_type, 0, tabContent);
		else
			NetUtil.SendPkg("chat_req", 0, channel_type, 0, tabContent);
		end
	end
end

function LobbyChatSystem.on_clear_msg(gid)
	local strGid = tostring(gid);
	for i = #LobbyChatSystem.chatBufferList, 1, -1 do
		local chatBuffer = chatBufferList[i];
		if chatBuffer.sender_uid == strGid then
			table.remove(LobbyChatSystem.chatBufferList, i);
		end
	end
	
	if DataMgr.roleData.uid == strGid then
		LobbyChatSystem.friendChatList = {};
		LobbyChatSystem.RefreshTotalUnread();
	else	
		LobbyChatSystem.DeleteFriend(gid);
	end
	
	LobbyChatLogic.ClearSomeonesMsg(strGid);
	LobbyChatEntranceUI.ClearSomeonesMsg(strGid);
end

--[[
聊天消息发送回包
surplus 聊天频率限制，表示还剩下多少秒的限制
]]
function LobbyChatSystem.on_chat_rsp(res, msg_id, chat_type, surplus, receiver_gid, chat_content)	
	
	if res == "chat-banned" then
        --receiver_gid = reason chat_content = surplus_time
        local time = chat_content;
        --local date = os.date("%Y年%m月%d日%H时%M分%S秒", time);
		local date = os.date(Client.GetTableData("LocalizeRes",115005).TextValue, time);
        --CommonMessageBoxUI:ShowPanel(1, "提示", reason.."\n解封时间为: "..date);
		local str = string.format(Client.GetTableData("LocalizeRes",301129).TextValue, tostring(date));
    	local promptTip = FuncUtil.GetLocalizeResStr("101001");
        --CommonMessageBoxUI:ShowPanel(1, promptTip, receiver_gid.."\n解封时间为: "..date);
        CommonMessageBoxUI:ShowPanel(1, promptTip, receiver_gid..str);
        return;
    end

	local strGid = "";
	if nil ~= receiver_gid and "" ~= receiver_gid then
		if type(receiver_gid) == "string" then
			strGid = receiver_gid;
		else
			local gid = math.floor(receiver_gid);
			strGid = tostring(gid);
		end
	end			
	
	if res == "ok" then		
		local voice_file = "";
		local voice_time = 0;
		local chat_ctt = chat_content.text;
		if true == chat_content.quickMsg then
			log("LobbyChatSystem.on_chat_rsp,chat_content.quickMsg:" .. tostring(chat_content.quickMsg));
			chat_ctt = Client.GetTableData("LocalizeRes", chat_content.text).TextValue;
		end
		if nil ~= chat_content.voice and "" ~= chat_content.voice then
			voice_time = chat_content.voiceLength;
			voice_file = chat_content.voice;		

			--log("send voice message length" .. tostring(voice_time));
		end
		--log("LobbyChatSystem.on_chat_rsp"..chat_ctt);
		chat_ctt = LobbyChatSystem.ReplaceEmoji(chat_ctt);
		--log("LobbyChatSystem.on_chat_rsp"..chat_ctt);
		sandbox.LogNormal("send chat message success" .. chat_ctt);
		
		local sender_name = DataMgr.roleData.nickName;
		local sender_uid = DataMgr.roleData.uid;			
		local msg_type = chat_content.msgType;
		
		--log("send chat message success " .. tostring(msg_type));
		
		if 0 == msg_type then
			LobbyChatLogic.OnSendMsgSuccess(voice_file);
			
			if chat_type == LobbyChatSystem.channelTeam and "" == voice_file then
				TeamUpUI.OnQuickMsg(sender_uid, chat_ctt);
			end
			
			if chat_type == LobbyChatSystem.channelPrivate then
				LobbyChatSystem.on_friend_msg(strGid, DataMgr.roleData.uid, sender_name, voice_file, voice_time, chat_ctt, true);
			else
				LobbyChatLogic.AddNewChat(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt, sender_uid, true, "");
				LobbyChatEntranceUI.ReceiveNewMsg(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt);
			end
		elseif 1 == msg_type then
			if chat_type ~= LobbyChatSystem.channelPrivate and chat_type ~= LobbyChatSystem.channelTeam then

				--log_tree("ddddddddddddddddddd me",chat_content)
				if chat_content.client_ver ~= nil then
					local isMatch = FuncUtil:IsMatchVersion(chat_content.client_ver);
					if isMatch == false then
						--如果版本不匹配，则不要在世界聊天显示，前台过滤
						log("versionIsNotMatch");
						return;
					end
				end				
				-- 小古在这加队伍Id
				local team_id = chat_content.team_id;
				LobbyChatLogic.AddNewChat(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt, sender_uid, true, team_id);
				LobbyChatEntranceUI.ReceiveNewMsg(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt);
			end
		end
	elseif res == "chat_busy" then		
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106012).TextValue);
	elseif res == "chat_frequent" then
		sandbox.LogNormal("chat response error = " ..res);
		msgContent = string.format(Client.GetTableData("LocalizeRes", 100007).TextValue, surplus);
		sandbox.LogNormal(msgContent);
		PopUpNoticeUI.ShowNewNotice(msgContent);
	end
	
end

--[[
收到聊天消息的通知回包
]]

function LobbyChatSystem.chat_merge_notify(merge_world_chat)
	log("LobbyChatSystem.chat_merge_notify");
	if nil == merge_world_chat or #merge_world_chat == 0 then
		log("empty merge list");
		return;
	end

	for i = 1, #merge_world_chat do
		local chatData = merge_world_chat[i];
		local msg = {};
		msg.chat_type = chatData.chat_type;
		msg.sender_name = chatData.sender_name;
		msg.msg_id = chatData.msg_id;
		msg.chat_content = chatData.chat_content;
		msg.sender_uid = chatData.send_uid;
		table.insert(LobbyChatSystem.chatBufferList, msg);
	end
	
	LobbyChatSystem.ChangeTickBuffer();
end

function LobbyChatSystem.chat_true_notify(chat_type, sender_name, msg_id, chat_content, sender_uid)
	log("LobbyChatSystem.chat_true_notify");
	if nil == sender_uid or "" == sender_uid then
		return;
	end
	
	local strGid = "";
	if type("sender_uid") == "string" then
		strGid = sender_uid;
	else
		local gid = math.floor(sender_uid);
		strGid = tostring(gid);
	end	
	
	if tonumber(strGid) == tonumber(DataMgr.roleData.uid) then
		--log("receive chat from me");
		return;
	end;
		
	if FriendSystem.IsPulBlack(strGid) then
		return;
	end
	
	local voice_file = "";
	local voice_time = 0;
	local chat_ctt = chat_content.text;

	if true == chat_content.quickMsg then
		log("LobbyChatSystem.on_chat_rsp,chat_content.quickMsg:" .. tostring(chat_content.quickMsg));
		chat_ctt = Client.GetTableData("LocalizeRes", chat_content.text).TextValue;
	end

	if nil ~= chat_content.voice and "" ~= chat_content.voice then
		voice_time = chat_content.voiceLength;
		voice_file = chat_content.voice;
	end
	
	chat_ctt = LobbyChatSystem.ReplaceEmoji(chat_ctt);
	
	if chat_type == LobbyChatSystem.channelTeam and "" == voice_file then
		--log("LobbyChatSystem.chat_true_notify!!!"..chat_ctt);
		TeamUpUI.OnQuickMsg(strGid, chat_ctt);
	end
		
	--sandbox.LogNormal("receive msg from :"..sender_name .. "  chat type " .. tostring(chat_type) .. " says: "..chat_ctt);		
	
	local msg_type = chat_content.msgType;
	--local msg_type = 1;
	if 0 == msg_type then
		if chat_type == LobbyChatSystem.channelPrivate then
			LobbyChatSystem.on_friend_msg(strGid, strGid, sender_name, voice_file, voice_time, chat_ctt, false);
		else
			LobbyChatLogic.AddNewChat(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt, strGid, false, "");
		end
				
		LobbyChatEntranceUI.ReceiveNewMsg(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt);
	elseif 1 == msg_type then	-- 招募消息 只有世界和聊天室
		if chat_type ~= LobbyChatSystem.channelPrivate and chat_type ~= LobbyChatSystem.channelTeam then
			
			--不是好友才进行过滤，好友不过滤
			local isFriend = FriendSystem.IsMyFriend(strGid);
			if isFriend == false then 
				--log_tree("ddddddddddddddddddd other",chat_content);
				if chat_content.client_ver ~= nil then
					local isMatch = FuncUtil:IsMatchVersion(chat_content.client_ver);
					if isMatch == false then
						--如果版本不匹配，则不要在世界聊天显示，前台过滤
						log("vertion is not same");
						return;
					end
				end	
			end

			-- 小古在这加队伍Id
			local team_id = chat_content.team_id;
			--log("chatTeamID"..team_id);
			LobbyChatLogic.AddNewChat(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt, strGid, false, team_id);
			LobbyChatEntranceUI.ReceiveNewMsg(chat_type, msg_type, sender_name, voice_file, voice_time, chat_ctt);
		end		
	end	
end

function LobbyChatSystem.chat_notify(chat_type, sender_name, msg_id, chat_content, sender_uid)
	log("LobbyChatSystem.chat_notify1:"..msg_id);
	if nil == sender_uid or "" == sender_uid then
		return;
	end
	
	local strGid = "";
	if type("sender_uid") == "string" then
		strGid = sender_uid;
	else
		local gid = math.floor(sender_uid);
		strGid = tostring(gid);
	end	
	
	if tonumber(strGid) == tonumber(DataMgr.roleData.uid) then
		--log("receive chat from me");
		return;
	end;
	
	
	-- 聊天室性能优化
	if chat_type == LobbyChatSystem.channelChatRoom then
		local thisClock = os.time();
		if thisClock - LobbyChatSystem.chatRoomLastMsgTime < 1.1 then
			LobbyChatSystem.chatRoomMsgCounter = LobbyChatSystem.chatRoomMsgCounter + 1;
			if LobbyChatSystem.chatRoomMsgMaxLimit <= LobbyChatSystem.chatRoomMsgCounter then
				log("msg abandon" .. chat_content.text);
				return;
			end
			-- 进战斗就让消息过去，返回大厅在加载缓存的聊天室消息
			if false == LobbyChatSystem.chatEnterFight then				
				-- 加到队列里
				local msg = {};
				msg.chat_type = chat_type;
				msg.sender_name = sender_name;
				msg.msg_id = msg_id;
				msg.chat_content = chat_content;
				msg.sender_uid = sender_uid;
				table.insert(LobbyChatSystem.chatBufferList, msg);
				LobbyChatSystem.ChangeTickBuffer();
				return;
			end				
		else
			LobbyChatSystem.chatRoomLastMsgTime = thisClock;
			LobbyChatSystem.chatRoomMsgCounter = 0;
		end		
	end
	--log("LobbyChatSystem.chat_notify2:"..chat_content.text);
	LobbyChatSystem.chat_true_notify(chat_type, sender_name, msg_id, chat_content, sender_uid);
end

--[[
	gid (string),
	sender_name (string),
	chat_content (string),
	self_msg (bool)
]]

function LobbyChatSystem.on_friend_msg(str_gid, str_sender_gid, sender_name, voice_file, voice_length, chat_content, self_msg)	
	chatTodayDate = os.date("%Y-%m-%d");
	
	str_gid = FuncUtil:StrTrim(str_gid);
	
	local thisMsg = {};
	thisMsg.msgChannel = LobbyChatSystem.channelPrivate;
	thisMsg.msgType = LobbyChatSystem.chatMsgType;
	thisMsg.uid = str_gid;
	thisMsg.name = sender_name;
	thisMsg.msg = chat_content;	
	thisMsg.selfMsg = self_msg;	
	thisMsg.voiceMsgId = voice_file;
	thisMsg.voiceMsgTime = voice_length;
	thisMsg.roomId = "";
	
	LobbyChatSystem.chatNewestFriendChat = str_gid;
	
	LobbyChatSystem.STATIC_MESSAGE_COUNTER = LobbyChatSystem.STATIC_MESSAGE_COUNTER + 1;
	thisMsg.level = LobbyChatSystem.STATIC_MESSAGE_COUNTER;
	
	LobbyChatSystem.on_friend_lobby_msg(str_gid, str_sender_gid, thisMsg);
	if "" == voice_file then
		LobbyChatSystem.on_friend_fight_msg(str_gid, str_sender_gid, thisMsg);
	end;
end

function LobbyChatSystem.on_friend_lobby_msg(str_gid, str_sender_gid, thisMsg)	
	--local refMsg = LobbyChatSystem.GetFriendChatItem(str_gid);
	local refMsg = LobbyChatSystem.friendChatList[str_gid];
	if nil == refMsg then
		refMsg = {};
		refMsg.gid = str_gid;
		refMsg.newMessageCount = 0;
		refMsg.lastMsgSendTime = 0;
		refMsg.messageList = { };
		--table.insert(LobbyChatSystem.friendChatList, refMsg);				
		LobbyChatSystem.friendChatList[str_gid] = refMsg;
	end	
		
	local thisTime = os.time();	
	local diffTime = thisTime - refMsg.lastMsgSendTime;
	if diffTime > 300 then
		thisMsg.msgSendTime = os.date("%H:%M");
	else
		thisMsg.msgSendTime = "";
	end
	
	thisMsg.msgSendDate = os.date("%Y-%m-%d");
	
	refMsg.lastMsgSendTime = os.time();
	
	if ((BP_ChannelType == LobbyChatSystem.channelPrivate) and (FuncUtil:StrTrim(BP_SelectedFriendGID) == str_gid) and (true == LobbyChatSystem.chatWndOpen)) 
		or (DataMgr.roleData.uid == str_sender_gid) then
		refMsg.newMessageCount = 0;
	elseif (LobbyChatSystem.chatSelectedFriendInFight == str_gid) and (true == LobbyChatSystem.chatEnterFight) then
		refMsg.newMessageCount = 0;
	else
		refMsg.newMessageCount = refMsg.newMessageCount + 1;
	end	
	
	if #refMsg.messageList >= LobbyChatSystem.MAX_FRIEND_MESSAGE_CACHE_NUM then
		table.remove(refMsg.messageList, 1);		
		log("friend count over size");
	end
	
	table.insert(refMsg.messageList, thisMsg);

	LobbyChatSystem.on_notify_friend_unread(str_gid, refMsg.newMessageCount);
	LobbyChatSystem.on_notify_friend_new_chat(thisMsg, str_gid, thisMsg.name, thisMsg.msg);
end

function LobbyChatSystem.on_friend_fight_msg(str_gid, str_sender_gid, thisMsg)
	if false == LobbyChatSystem.chatEnterFight then
		return;
	end
	
	local refMsg = LobbyChatSystem.fightFriendChatList[str_gid];
	if nil == refMsg then
		refMsg = {};
		refMsg.gid = str_gid;
		refMsg.newMessageCount = 0;
		refMsg.lastMsgSendTime = 0;
		refMsg.messageList = { };
		LobbyChatSystem.fightFriendChatList[str_gid] = refMsg;
	end
	
	if LobbyChatSystem.chatSelectedFriendInFight == str_gid then
		refMsg.newMessageCount = 0;
	else
		refMsg.newMessageCount = refMsg.newMessageCount + 1;
	end
	
	if #refMsg.messageList >= LobbyChatSystem.MAX_FRIEND_MESSAGE_CACHE_NUM then
		table.remove(refMsg.messageList, 1);		
		log("friend count over size");
	end
	
	table.insert(refMsg.messageList, thisMsg);
	
	LobbyChatSystem.on_notify_fight_friend_unread(str_gid);
	LobbyChatSystem.on_notify_fight_friend_chat(str_gid, thisMsg);
end

--[[
	过滤接口
]]

function LobbyChatSystem.filter_text_req(text)
	if nil == text or "" == text then
		return;
	end
	
	NetUtil.SendPkg("filter_text_req", text);
end

function LobbyChatSystem.filter_text_rsp(filter_text)
	IngameChat:on_filter_finish(filter_text);
end

--[[
	战斗内私聊接口
]]
function LobbyChatSystem.fight_send_msg(str_receiver_gid, content)
	LobbyChatSystem.on_chat_req(str_receiver_gid, LobbyChatSystem.channelPrivate, content);
end

function LobbyChatSystem.on_enter_fight_chat(str_gid)
	LobbyChatSystem.chatSelectedFriendInFight = str_gid;
	
	local refMsg = LobbyChatSystem.friendChatList[str_gid];
	if nil ~= refMsg then
		refMsg.newMessageCount = 0;
	end
	
	refMsg = LobbyChatSystem.fightFriendChatList[str_gid];
	if nil ~= refMsg then
		refMsg.newMessageCount = 0;
	end
	
	LobbyChatSystem.on_notify_fight_total_unread();
end

function LobbyChatSystem.on_quit_fight_chat()
	LobbyChatSystem.chatSelectedFriendInFight = "";
end

function LobbyChatSystem.on_notify_fight_friend_unread(str_gid, unread_count)
	LobbyChatSystem.on_notify_fight_total_unread();
	--[[ blablabla 刷新某个好友未读数量]]
end

function LobbyChatSystem.on_notify_fight_friend_chat(str_gid, this_msg)
	--[[
	消息格式
	thisMsg.msgChannel = LobbyChatSystem.channelPrivate;
	thisMsg.msgType = LobbyChatSystem.chatMsgType;
	thisMsg.uid = str_gid;
	thisMsg.name = sender_name;
	thisMsg.msg = chat_content;	
	thisMsg.selfMsg = self_msg;	
	thisMsg.voiceMsgId = voice_file;
	thisMsg.voiceMsgTime = voice_length;
	thisMsg.roomId = "";
	]]
	--[[ blablabla 通知战斗内新消息 ]]
	IngameChat:on_notify_fight_friend_chat(str_gid, this_msg);
end

function LobbyChatSystem.on_notify_fight_total_unread()
	local unreadCount = 0;
	for k, v in pairs(LobbyChatSystem.fightFriendChatList) do
		unreadCount = unreadCount + v.newMessageCount;
	end
	--[[ blablabla 刷新所有好友未读数量]]
end

--[[
	end of 战斗内私聊接口
]]

--[[
	预约相关
]]
function LobbyChatSystem.on_reserve_friend_req(str_gid)
	if nil == str_gid or "" == str_gid then
		return;
	end	
	
	local reservingData = LobbyChatSystem.friendReservingList[str_gid];
	if nil == reservingData then
		log("friend is reserved add reserving");
		local dat = {};
		dat.gid = str_gid;
		dat.time = os.time();
		LobbyChatSystem.friendReservingList[str_gid] = dat;
	else
		reservingData.time = os.time();
	end
	
	NetUtil.SendPkg("appointment_game_friend_req", tonumber(str_gid));
end

function LobbyChatSystem.on_clear_reserving(str_gid)
	LobbyChatSystem.friendReservingList[str_gid] = nil;
end

function LobbyChatSystem.on_reserve_require_notify(num_uid)	
	local str_gid = tostring(num_uid);
	log("on_reserve_require_notify " .. str_gid);
	--[[
		blablabla 处理战斗内预约相关
	]]

	local friendData = FriendSystem.GetFriendDataByGID(num_uid)
	if nil == friendData then
		return;
	end
	IngameChat:on_reserve_require_notify(str_gid, friendData.nickName);

	-- 测试：
	-- LobbyChatSystem.on_reserve_reply_req(str_gid, true);
	
	--LobbyChatSystem.on_reservation_from_lobby_notify(FriendSystem.GetFriendUidList());
end

--[[
	b_reply: true, false
]]
function LobbyChatSystem.on_reserve_reply_req(str_uid, b_reply)
	if nil == str_uid or "" == str_uid then
		log("on_reserve_reply_req return" .. str_uid);
		return;
	end
	
	local reply = 0;
	if b_reply then
		reply = 1;	
	end
	
	log("on_reserve_reply_req " .. str_uid);
	
	NetUtil.SendPkg("appointment_game_friend_answer", tonumber(str_uid), reply);
end

function LobbyChatSystem.IsReserved(str_gid)
	local contains = false;
	for i = 1, #LobbyChatSystem.friendReservedInFight do
		if LobbyChatSystem.friendReservedInFight[i] == str_gid then
			contains = true;
			break;
		end
	end
	
	return contains;
end

function LobbyChatSystem.on_reserve_reply_notify(num_uid, result)
	local str_gid = tostring(num_uid);
	log("on_reserve_reply_notify " .. str_gid);
	
	local friendData = FriendSystem.GetFriendDataByGID(num_uid);
	-- 拼一下
	if nil == friendData then
		log("empty friend data when reserve _reply");
		return;
	end
	
	if 1 == result then
		--log("friend is reserved");
		local contains = LobbyChatSystem.IsReserved(str_gid);		
		if false == contains then			
			table.insert(LobbyChatSystem.friendReservedInFight, str_gid);
		end
		
		TeamUPFriendUI.OnFriendReserved(str_gid);
	end	
	
	local msg = "";
	if 1 == result then
		msg = string.format(DataMgr.GetMsgByID(110110), friendData.nickName);
	else
		msg = string.format(DataMgr.GetMsgByID(110109), friendData.nickName);
	end
	
	CommonRightNotifyUI.ShowNotify(msg, nil);
end

function LobbyChatSystem.on_reserve_friend_game_end_notify(num_uid)
	local friendData = FriendSystem.GetFriendDataByGID(num_uid);
	if nil == friendData then
		log("empty friend data when reserve friend_game_end");
		return;
	end
	
	local index = 0;
	for i = 1, #LobbyChatSystem.friendReservedInFight do
		if tostring(num_uid) == LobbyChatSystem.friendReservedInFight[i] then
			index = i;			
			break;			
		end
	end
	
	if 0 ~= index then
		table.remove(LobbyChatSystem.friendReservedInFight, index);
	end
	
	local msg = string.format(DataMgr.GetMsgByID(110111), friendData.nickName);
	CommonRightNotifyUI.ShowNotify(msg, nil);
end

function LobbyChatSystem.on_reservation_from_lobby_notify(appointment_friend_list)	
	log("on_reservation_from_lobby_notify");
	local listLength = #appointment_friend_list;
	if 0 == listLength then
		log("on_reservation_from_lobby_notify empty list");
		return;
	end
	
	local friendsName = "";
	for i = 1, listLength do
		local friendData = FriendSystem.GetFriendDataByGID(appointment_friend_list[i]);
		if nil ~= friendData then
			friendsName = friendsName .. string.format(DataMgr.GetMsgByID(110113), friendData.nickName);
			
			if i ~= listLength then
				friendsName = friendsName .. ",";
			end
		end
	end
	
	local msg = DataMgr.GetMsgByID(110112);
	msg = msg .. friendsName;
	msg = msg ..DataMgr.GetMsgByID(110114);
	CommonRightNotifyUI.ShowNotify(msg, nil);
end

--[[
	end of 预约相关
]]

--[[
	msg (msg struct)
	sender_uid (string)
	sender_name (string)
	msg_content (string)
]]
function LobbyChatSystem.on_notify_friend_new_chat(msg, sender_uid, sender_name, msg_content)
	LobbyChatLogic.NotifyFriendNewChat(msg, sender_uid, sender_name, msg_content)
end

--[[
	sender_uid (string),
	message_count (number)
]]
function LobbyChatSystem.on_notify_friend_unread(sender_uid, message_count)
	LobbyChatSystem.RefreshTotalUnread();
	LobbyChatLogic.RefreshUnreadList(sender_uid, message_count);	
end

function LobbyChatSystem.on_teamup_info_changed(eventType, eventID, vars)
	if eventID == EVENTID_TEAMUP_TEAMINFO_SYNC then
		if nil ~= TeamUpSystem.TeamInfo then
			local isTeamup = false;
			if nil ~= TeamUpSystem.TeamInfo.player_count then
				isTeamup = TeamUpSystem.TeamInfo.player_count > 1;
			end
			
			LobbyChatLogic.SetIsTeamUp(isTeamup);
			LobbyChatEntranceUI.SetIsTeamUp(isTeamup);
			GlobalChatVoice.SetIsTeamup(isTeamup);
		end
	end	
end

function LobbyChatSystem.on_backto_login(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_LOGIN then
      return;
    end
	
	log("back to login");
	
	if eventID == EVENTID_BACKLOGIN then
		LobbyChatSystem.chatBufferList = {};
		LobbyChatSystem.friendChatList = {};
		LobbyChatLogic.chatRoomBufferList = {};
		LobbyChatLogic.chatRoomFightNewMsg = 0;
		GlobalChatVoice.ClearRoleInfo();
		LobbyChatLogic:Release();
    end
end

-------------------------chat room send client to server-----------------

--创建频道
function LobbyChatSystem.create_channel_req(name, need_key, key)
	log("create_channel_req, name = " .. name .. ", need_key = " .. tostring(need_key) .. ", key = " .. key);
	NetUtil.SendPkg("create_channel_req", name, need_key, key);
end

--查找频道
function LobbyChatSystem.query_channel_req(channel_id)
	log("query_channel_req channel_id = " .. channel_id);
	NetUtil.SendPkg("query_channel_req", channel_id);
end

--获取玩家自己的频道列表
function LobbyChatSystem.get_channel_list_req()
	log("get_channel_list_req");
	NetUtil.SendPkg("get_channel_list_req");
end

--加入频道
function LobbyChatSystem.join_channel_req(channel_id, key)
	log("join_channel_req channel_id = " .. channel_id .. ", key = " .. key);
	NetUtil.SendPkg("join_channel_req", channel_id, key);
end

--退出频道
function LobbyChatSystem.exit_channel_req(channel_id)
	log("exit_channel_req channel_id = " .. channel_id);
	NetUtil.SendPkg("exit_channel_req", channel_id);
end

--收藏频道
function LobbyChatSystem.collect_channel_req(channel_id)
	log("collect_channel_req channel_id = " .. channel_id);
	NetUtil.SendPkg("collect_channel_req", channel_id);
end

--设置/修改频道
function LobbyChatSystem.change_channel_req(channel_id, channel_name, need_key, channel_key)
	log("change_channel_req");
	NetUtil.SendPkg("change_channel_req", channel_id, channel_name, need_key, channel_key);
end

--删除频道
function LobbyChatSystem.delete_channel_req(channel_id)
	log("delete_channel_req channel_id = " .. channel_id);
	NetUtil.SendPkg("delete_channel_req", channel_id);
end



--取消收藏频道
function LobbyChatSystem.cancel_collect_channel_req(channel_id)
	log("cancel_collect_channel_req");
	NetUtil.SendPkg("cancel_collect_channel_req", channel_id);
end


function LobbyChatSystem.send_chatroom_profile_req(list)
	log("LobbyChatSystem.send_chatroom_profile_req");
    LobbyChatSystem.GetProfileReq(list, BP_PROFILE_MSG_TYPE_CHATROOM);
end

function LobbyChatSystem.GetProfileReq(listNotGet, type)
	log("[HHF]LobbyChatSystem.GetProfileReq, total list.num = " .. #listNotGet);
	-- 分批拉取，每次上限100个
	local numperrequest = 100;
	if #listNotGet <= numperrequest then
    	NetUtil.SendPkg("batch_get_profile_req", "", listNotGet, type);
	else
		local listPerReq = {};
		for k, v in pairs(listNotGet) do
			if #listPerReq == numperrequest then
    			NetUtil.SendPkg("batch_get_profile_req", "", listPerReq, type);
				listPerReq = {};
			else
				table.insert(listPerReq, v);
			end
		end
		if #listPerReq > 0 then
    		NetUtil.SendPkg("batch_get_profile_req", "", listPerReq, type);
		end
	end
end


function LobbyChatSystem.send_chatroom_status_req(list)
	log("LobbyChatSystem.send_chatroom_status_req");
	local cb = "ChatRoomStatus";
	NetUtil.SendPkg("batch_get_group_and_online_req",cb,list);
end

-------------------------chat room send server to client-----------------

--1. 创建频道
function LobbyChatSystem.create_channel_rsp(ok, reason, channel_id, channel)
	log("create_channel_rsp " 
		.. " ok = " .. tostring(ok) 
		.. " , reason = " .. tostring(reason) 
		.. " , channel_id = " 
		.. tostring(channel_id)
	);
	if (ok) then
		--log_tree("channel", channel);
		LobbyChatSystem.myChannel = channel;
		LobbyChatroomLogic.UpdateMyChannel(true);
		LobbyChatroomLogic.CloseCreateOrSetRoomPanel();
	else
		LobbyChatSystem.ShowErrorMsg(reason);
	end
end


--查找频道
function LobbyChatSystem.query_channel_rsp(channel_id, channel)
	log("LobbyChatSystem.query_channel_rsp");
end

--[[
LogNula: LuaLog: └─ 10088
LogNula: LuaLog:    ├─ channel_info
LogNula: LuaLog:    │  ├─ member_num: 1
LogNula: LuaLog:    │  ├─ channel_name: "test"
LogNula: LuaLog:    │  ├─ last_update_time: 1513324272
LogNula: LuaLog:    │  ├─ channel_need_key: true
LogNula: LuaLog:    │  └─ channel_owner: 410000001
LogNula: LuaLog:    └─ is_collect: true
]]
--获取玩家自己的频道列表
function LobbyChatSystem.get_channel_list_rsp(channel_list)

	log("get_channel_list_rsp");
	--log_tree("get_channel_list_rsp", channel_list);
	
	LobbyChatSystem.channelList = channel_list;
	LobbyChatroomLogic.UpdateChannelList();
end
--[[
LogNula: LuaLog: channel
LogNula: LuaLog: ├─ members
LogNula: LuaLog: │  └─ 1: 410000001
LogNula: LuaLog: └─ channel_info
LogNula: LuaLog:    ├─ channel_need_key: true
LogNula: LuaLog:    ├─ channel_name: "test"
LogNula: LuaLog:    ├─ last_update_time: 1513326300
LogNula: LuaLog:    ├─ channel_owner: 410000001
LogNula: LuaLog:    └─ member_num: 2
]]
--加入频道
function LobbyChatSystem.join_channel_rsp(channel_id, ok, reason, channel)
	log("join_channel_rsp");
	--log_tree("channel", channel);
	if (ok) then
		LobbyChatSystem.myChannel = channel;
		LobbyChatroomLogic.UpdateMyChannel(true);
		LobbyChatroomLogic.CloseChatRoomPassword();
		LobbyChatSystem.chatRoomPasswordContainer[tostring(channel_id)] = BP_ChatRoom_SearchRoomPassword;
	else
		if (channel_id ~= nil) then
			if (tostring(reason) == "passwd-not-correct" and LobbyChatSystem.chatRoomQueryPassword) then
				LobbyChatSystem.chatRoomQueryPassword = false;
				LobbyChatSystem.chatRoomPasswordContainer[tostring(channel_id)] = nil;
				EventOpenChatRoomPassword();
				return;
			end
		end
		log("fail to join room, reason = " .. reason);
		--DataMgr.ShowNoticeByString("fail to join room , reason = " .. reason);
		LobbyChatSystem.ShowErrorMsg(reason);
		if (tostring(reason) == "chatchannel-not-exist") then
			LobbyChatSystem.get_channel_list_req();
		end
	end
end

--退出频道
function LobbyChatSystem.exit_channel_rsp(channel_id, ok, reason)
	log("exit_channel_rsp");
	if (ok) then
		LobbyChatroomLogic.ClearChatRoomData();
		LobbyChatroomLogic.RefreshChatRoom();
		LobbyChatSystem.get_channel_list_req();
	else
		log("fail to exit channel, reason = " .. reason);
		--DataMgr.ShowNoticeByString("fail to exit channel reason = " .. reason);
		LobbyChatSystem.ShowErrorMsg(reason);
	end
end

--收藏频道
function LobbyChatSystem.collect_channel_rsp(channel_id, ok)
	log("collect_channel_rsp channel_id = " .. channel_id .. " ok = " .. tostring(ok));
	
	LobbyChatroomLogic.OnCollectStateChange();

	if (ok) then
		LobbyChatroomLogic.UpdateChannelMarkState(channel_id, true);
		DataMgr.ShowNoticeByID(106066);
	else
		log("fail to collect channel");
		--DataMgr.ShowNoticeByString("fail to collect channel");
		--LobbyChatSystem.ShowErrorMsg(reason);
		DataMgr.ShowNoticeByID(106045);
	end
end

--设置/修改频道
function LobbyChatSystem.change_channel_rsp(channel_id, ok, reason, channel)
	log("change_channel_rsp channel_id = " .. channel_id .. " ok = " .. tostring(ok));
	--log_tree("channel", channel);

	if (ok) then
		if (LobbyChatSystem.myChannel ~= nil) then
			local members = LobbyChatSystem.myChannel.members;
			LobbyChatSystem.myChannel = channel;
			LobbyChatSystem.myChannel.members = members;
			
			LobbyChatroomLogic.UpdateMyChannel(false);
			LobbyChatroomLogic.CloseCreateOrSetRoomPanel();
		end
	else
		log("fail to change channel, reason = " .. reason);
		--DataMgr.ShowNoticeByString("fail to change channel, reason = " .. reason);
		LobbyChatSystem.ShowErrorMsg(reason);
	end
end

--删除频道
function LobbyChatSystem.delete_channel_rsp(channel_id, ok, reason)
log("delete_channel_rsp");	
	if (ok) then
		LobbyChatroomLogic.ClearChatRoomData();
		LobbyChatSystem.get_channel_list_req();
	else 
		log("fail to remove channel, reason = " .. reason);
		--DataMgr.ShowNoticeByString("fail to remove channel, reason = " .. reason);
		LobbyChatSystem.ShowErrorMsg(reason);
	end
end

function LobbyChatSystem.update_channel_info(channel_id, channel)
	log("update_channel_info channel_id = " .. channel_id);
	--log_tree("channel", channel);

	if (LobbyChatSystem.myChannel ~= nil and LobbyChatSystem.myChannel.channel_info ~= nil and channel ~= nil and channel.channel_info ~= nil) then
		LobbyChatSystem.myChannel.channel_info = channel.channel_info;
		LobbyChatroomLogic.UpdateMyChannel(false);
	end
end

--type = 1 JOIN   加入
--type = 2 EXIT	退出
--type = 3 DEL	删除(uid为0)
--更新频道成员
function LobbyChatSystem.update_channel_member(channel_id, uid, type)
	log("update_channel_member channel_id = " .. channel_id .. ", uid = " .. tostring(uid) .. ", type = " .. tostring(type));
	if (LobbyChatSystem.myChannel ~= nil and LobbyChatSystem.myChannel.members ~= nil and LobbyChatSystem.myChannel.channel_info ~= nil) then
		local memberCount = #LobbyChatSystem.myChannel.members;
		local memberIndex = -1;
		if (memberCount > 0) then
			for i = 1, memberCount, 1 do 
				if (tostring(LobbyChatSystem.myChannel.members[i]) == tostring(uid)) then
					memberIndex = i;
				end
			end
		end
		
		if (type == 1) then
			if (memberIndex == -1) then
				table.insert(LobbyChatSystem.myChannel.members, uid);
				LobbyChatSystem.myChannel.channel_info.member_num = #LobbyChatSystem.myChannel.members;
				LobbyChatroomLogic.AddOnePlayer(tostring(uid));
			end
			--[[
			if (LobbyChatSystem.myChannel.members ~= nil) then
				LobbyChatSystem.myChannel.channel_info.member_num = #LobbyChatSystem.myChannel.members;
			end
			LobbyChatroomLogic.UpdateMyChannel(false);
			]]
		elseif (type == 2) then
			if (memberIndex ~= -1) then
				local member_num = #LobbyChatSystem.myChannel.members;
				table.remove(LobbyChatSystem.myChannel.members, memberIndex);
				LobbyChatSystem.myChannel.channel_info.member_num = (member_num - 1);
				LobbyChatroomLogic.RemoveOnePlayer(memberIndex);
			end
			--[[
			if (LobbyChatSystem.myChannel.members ~= nil) then
				LobbyChatSystem.myChannel.channel_info.member_num = #LobbyChatSystem.myChannel.members;
			end
			LobbyChatroomLogic.UpdateMyChannel(false);
			]]
		elseif (type == 3) then
			if (LobbyChatSystem.myChannel ~= nil and LobbyChatSystem.myChannel.channel_info ~= nil) then
				local channelName = LobbyChatSystem.myChannel.channel_info.channel_name;
				DataMgr.ShowNoticeByString(string.format(DataMgr.GetMsgByID(106055), channelName)); --聊天室被解散
			end
			LobbyChatroomLogic.ClearChatRoomData();
			LobbyChatSystem.get_channel_list_req();
		end
	end	
end


--取消收藏频道
function LobbyChatSystem.cancel_collect_channel_rsp(channel_id, ok)
	log("cancel_collect_channel_rsp channel_id = " .. channel_id .. ", ok = " .. tostring(ok));
	
	LobbyChatroomLogic.OnCollectStateChange();

	if (ok) then
		LobbyChatroomLogic.UpdateChannelMarkState(channel_id, false);
		DataMgr.ShowNoticeByID(106067);
	else
		log("fail to cancel collect channel");
		DataMgr.ShowNoticeByID(106046);
		--DataMgr.ShowNoticeByString("fail to cancel collect channel");
		--LobbyChatSystem.ShowErrorMsg(reason);
	end
end

function LobbyChatSystem.ShowErrorMsg(reason)
	if (reason ~= nil) then
		if (tostring(reason) == "name-too-long") then --名字太长
			DataMgr.ShowNoticeByID(106028);
		elseif (tostring(reason) == "key-too-long") then	--密码太长
			DataMgr.ShowNoticeByID(106029);
		elseif (tostring(reason) == "key-too-short") then	--密码太短
			DataMgr.ShowNoticeByID(106030);
		elseif (tostring(reason) == "have-dirty-in-name") then	--名字中含有脏字
			DataMgr.ShowNoticeByID(106031);
		elseif (tostring(reason) == "chatchannel_exist") then	--频道已存在
			DataMgr.ShowNoticeByID(106032);
		elseif (tostring(reason) == "create-channel-exceed-limit") then	--创建的频道超出限制
			DataMgr.ShowNoticeByID(106033);
		elseif (tostring(reason) == "channel-not-exists") then	--当前尚未进入频道
			DataMgr.ShowNoticeByID(106034);
		elseif (tostring(reason) == "chatchannel-not-exist") then	--频道不存在
			DataMgr.ShowNoticeByID(106035);
		elseif (tostring(reason) == "db_error") then		--DB错误
			DataMgr.ShowNoticeByID(106036);
		elseif (tostring(reason) == "chatchannel-is-full") then	--频道人员已满
			DataMgr.ShowNoticeByID(106037);
		elseif (tostring(reason) == "passwd-not-correct") then	--频道密码不对
			DataMgr.ShowNoticeByID(106038);
		elseif (tostring(reason) == "not-channel-owner") then	--频道不是自己所创建的
			DataMgr.ShowNoticeByID(106039);
		else
			log("unknown error " .. tostring(reason));
		end
	end
end


--[[
LogNula: LuaLog: role_basic_info_list
LogNula: LuaLog: └─ 410000358
LogNula: LuaLog:    ├─ vipLevel: ""
LogNula: LuaLog:    ├─ segment_info
LogNula: LuaLog:    │  ├─ 1: 1
LogNula: LuaLog:    │  ├─ 2: 1
LogNula: LuaLog:    │  └─ 3: 1
LogNula: LuaLog:    ├─ platName: "宁"
LogNula: LuaLog:    ├─ level: 1
LogNula: LuaLog:    ├─ lastLoginTime: 1513665918
LogNula: LuaLog:    ├─ picUrl: "http://q.qlogo.cn/qqapp/1106467070/C1E162B0B7786CCF551EA5935D8AE1EB/40"
LogNula: LuaLog:    ├─ lastOnlineTime: 1513665918
LogNula: LuaLog:    ├─ ladder: 0
LogNula: LuaLog:    ├─ nickName: "jack1219"
LogNula: LuaLog:    ├─ sex: 1
LogNula: LuaLog:    ├─ bitmap: 0
LogNula: LuaLog:    ├─ signature: ""
LogNula: LuaLog:    ├─ exp: 0
LogNula: LuaLog:    ├─ rankdata
LogNula: LuaLog:    │  ├─ squad
LogNula: LuaLog:    │  │  ├─ win_rating: 1000
LogNula: LuaLog:    │  │  ├─ kill_rating: 1000
LogNula: LuaLog:    │  │  ├─ rank_rating: 1200
LogNula: LuaLog:    │  │  ├─ win_num: 0
LogNula: LuaLog:    │  │  ├─ playtime: 0
LogNula: LuaLog:    │  │  ├─ kill_num: 0
LogNula: LuaLog:    │  │  ├─ kd: 0
LogNula: LuaLog:    │  │  ├─ win_ratio: 0
LogNula: LuaLog:    │  │  └─ max_kill: 0
LogNula: LuaLog:    │  ├─ total_rank_rating: 3600
LogNula: LuaLog:    │  ├─ solo
LogNula: LuaLog:    │  │  ├─ max_kill: 0
LogNula: LuaLog:    │  │  ├─ kill_rating: 1000
LogNula: LuaLog:    │  │  ├─ rank_rating: 1200
LogNula: LuaLog:    │  │  ├─ win_num: 0
LogNula: LuaLog:    │  │  ├─ playtime: 0
LogNula: LuaLog:    │  │  ├─ kill_num: 0
LogNula: LuaLog:    │  │  ├─ win_ratio: 0
LogNula: LuaLog:    │  │  ├─ kd: 0
LogNula: LuaLog:    │  │  ├─ win_rating: 1000
LogNula: LuaLog:    │  │  └─ top10_count: 0
LogNula: LuaLog:    │  └─ duo
LogNula: LuaLog:    │     ├─ win_rating: 1000
LogNula: LuaLog:    │     ├─ kill_rating: 1000
LogNula: LuaLog:    │     ├─ rank_rating: 1200
LogNula: LuaLog:    │     ├─ win_num: 0
LogNula: LuaLog:    │     ├─ playtime: 0
LogNula: LuaLog:    │     ├─ kill_num: 0
LogNula: LuaLog:    │     ├─ kd: 0
LogNula: LuaLog:    │     ├─ win_ratio: 0
LogNula: LuaLog:    │     └─ max_kill: 0
LogNula: LuaLog:    └─ city: ""
LogGCloud: [2017-12-19 14:45:36 893] | In
]]
function LobbyChatSystem.on_chatroom_profile_rsp(listType, res, role_basic_info_list, systemType)

	if BP_PROFILE_MSG_TYPE_CHATROOM ~= systemType then
		return;
	end

	if "ok" ~= res then
		return;
	end

	log("LobbyChatSystem.on_chatroom_profile_rsp");
end
--[[
LogNula: LuaLog: infos
LogNula: LuaLog: └─ 410000358
LogNula: LuaLog:    ├─ teamState: 0
LogNula: LuaLog:    ├─ online: 1
LogNula: LuaLog:    ├─ timeSinceGameBegin: 0
LogNula: LuaLog:    ├─ currentTeamAmount: 1
LogNula: LuaLog:    └─ maxTeamAmount: 4
]]
function LobbyChatSystem.on_chatroom_status_rsp(cb, res, infos)
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
	if cb ~= "ChatRoomStatus" then
		log("no ChatRoomStatus");
		return;
	end	
	log("LobbyChatSystem.on_chatroom_status_rsp");
	
	if res =="ok" then
		if infos ~= nil then
			for k,v in pairs(infos) do
				
				local PlayerStatu = {};
				PlayerStatu.teamState = v.teamState;
				PlayerStatu.teamId = v.teamId;
				PlayerStatu.currentTeamAmount = v.currentTeamAmount;
				PlayerStatu.maxTeamAmount = v.maxTeamAmount;
				PlayerStatu.timeSinceGameBegin = v.timeSinceGameBegin;
				PlayerStatu.online = v.online;
				
				LobbyChatSystem.chatRoomStatusDict[tostring(k)] = PlayerStatu;
				
			end	
		end		
		LobbyChatroomLogic.UpdateChannelStatus();
	end
end

function LobbyChatSystem.notify_update_channel_member_state(uid, channel_id, team_state, channel)
	log("notify_update_channel_member_state " .. uid .. ", channel_id = " .. channel_id .. ", team_state = " .. team_state);
	if (channel ~= nil) then
		--log_tree("channel", channel);
	end
	LobbyChatroomLogic.OnTeamStateChange(uid, channel_id, team_state)
end

--[[网络回调]]--
s2c["chat_req"] = LobbyChatSystem.on_chat_req;
s2c["chat_rsp"] = LobbyChatSystem.on_chat_rsp;
s2c["chat_notify"] = LobbyChatSystem.chat_notify;
s2c["chat_merge_notify"] = LobbyChatSystem.chat_merge_notify;
s2c["chat_clear_msg"] = LobbyChatSystem.on_clear_msg;
s2c["report_info"] = LobbyChatSystem.on_report_rsp;
s2c["filter_text_rsp"] = LobbyChatSystem.filter_text_rsp;

s2c["appointment_game_friend_notify"] = LobbyChatSystem.on_reserve_require_notify;
s2c["appointment_game_friend_res"] = LobbyChatSystem.on_reserve_reply_notify;
s2c["appointment_friend_game_end"] = LobbyChatSystem.on_reserve_friend_game_end_notify;
s2c["notify_appointment_friend_list"] = LobbyChatSystem.on_reservation_from_lobby_notify;


s2c["create_channel_rsp"] = LobbyChatSystem.create_channel_rsp;			--创建频道
s2c["query_channel_rsp"] = LobbyChatSystem.query_channel_rsp;			--查找频道
s2c["get_channel_list_rsp"] = LobbyChatSystem.get_channel_list_rsp;		--获取玩家自己的频道列表
s2c["join_channel_rsp"] = LobbyChatSystem.join_channel_rsp;				--加入频道
s2c["exit_channel_rsp"] = LobbyChatSystem.exit_channel_rsp;				--退出频道
s2c["collect_channel_rsp"] = LobbyChatSystem.collect_channel_rsp; 		--收藏频道
s2c["change_channel_rsp"] = LobbyChatSystem.change_channel_rsp;			--设置/修改频道
s2c["delete_channel_rsp"] = LobbyChatSystem.delete_channel_rsp;			--删除频道
s2c["update_channel_member"] = LobbyChatSystem.update_channel_member;	--更新频道成员
s2c["cancel_collect_channel_rsp"] = LobbyChatSystem.cancel_collect_channel_rsp;	--取消收藏频道
s2c["notify_update_channel_member_state"] = LobbyChatSystem.notify_update_channel_member_state;	--频道成员组队状态变化
s2c["update_channel_info"] = LobbyChatSystem.update_channel_info;		--修改频道时,通知频道基本信息