LobbyChatEntranceUI = LobbyChatEntranceUI or
{
}


function bp_chat_entrance_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_chat_entrance,
    {{Path="/Game/UMG/UI_BP/LobbyChat/LobbyChatEntrance_BP.LobbyChatEntrance_BP_C", Container="Default", ZOrder=BP_ENUM_UI_CHAT_ENTRANCE_ZORDER}},
    {"Lobby"},
	false,
	bp_chat_entrance_OnModeSwitched ~= nil
  );
end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function EventSetInfo_Push()
end

BP_ChatEntranceValid = false;
BP_ChatEntranceNewSender = "";
BP_ChatEntranceNewMsg = "";
BP_ChatEntranceNewChannel = 2;
BP_ChatFriendNewMsgCount = 0;
BP_ChatEntranceChatroomNewMsgCount = 0;
BP_ChatEntranceTeamed = false;
BP_ChatEntranceTickBufferList = false;
BP_ChatEntranceEnterRoom = false;

BP_ChatEntranceVoiceRoomId = "";
BP_ChatEntranceClearGID = "";

BP_ChatEntranceQuickMsgId = 0;
BP_ChatEntranceQuickMsgStr = "";

function bp_chat_entrance_OnModeSwitched(gamestatus)
	local status = string.lower(gamestatus);
	if "lobby" == status then
		log("init chat entrance" .. tostring(BP_ChannelType));
		
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIInit");
		
		LobbyChatSystem.Entry();
	elseif "login" == status then
		LobbyChatEntranceUI.Release()
		LobbyChatSystem.Release();	
	elseif "fighting" == status then
		LobbyChatSystem.EnterFight();
	else	
		LobbyChatEntranceUI.Release();		
		
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIRelease");
	end
end

function LobbyChatEntranceUI.Init()		
	BP_ChatEntranceValid = true;	
	LobbyChatEntranceUI.RefreshTickBufferState();
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIShow");
	LobbyChatEntranceUI.RefreshUnreadList(BP_ChatFriendNewMsgCount);
	LobbyChatEntranceUI.RefreshChatroomUnread(BP_ChatRoomNewMessageCount);
end

function LobbyChatEntranceUI.Release()
	BP_ChatFriendNewMsgCount = 0;
	BP_ChatEntranceOpenMic = false;
	BP_ChatEntranceOpenMic = false;
	BP_ChatEntranceTickBufferList = false;
	BP_ChatEntranceEnterRoom = false;
	BP_ChatEntranceValid = false;
end

function LobbyChatEntranceUI.SetIsTeamUp(isTeamup)
	BP_ChatEntranceTeamed = isTeamup;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "TeamStateChanged");
end

function LobbyChatEntranceUI.SetIsRoomMode(is_room)
	BP_ChatEntranceEnterRoom = is_room;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "RoomStateChanged");
end

function LobbyChatEntranceUI.SetVisibility(visible)	
	if true == BP_ChatEntranceEnterRoom and false == visible then
		LobbyChatLogic.CloseUI();
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIHide");		
	else
		LobbyChatEntranceUI.Init();
	end
end

function LobbyChatEntranceUI.ClearSomeonesMsg(gid)
	if not BP_ChatEntranceValid then
		return;
	end

	BP_ChatEntranceClearGID = gid;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "ClearSomeonesMsg");
end

function LobbyChatEntranceUI.ReceiveNewMsg(channel_type, msg_type, sender_name, voice_file, voice_length, chat_content)	
	if not BP_ChatEntranceValid then
		return;
	end	
	
	--[[	
	if BP_ChatEntranceTeamed then
		if channel_type ~= LobbyChatSystem.channelTeam and channel_type ~= LobbyChatSystem.channelPrivate then
			return;
		end	
	end
	]]
	
	BP_ChatEntranceNewSender = sender_name;
	
	if "" ~= voice_file then
		BP_ChatEntranceNewMsg = Client.GetTableData("LocalizeRes", 106016).TextValue .. chat_content;
	elseif 1 == msg_type then
		BP_ChatEntranceNewMsg = Client.GetTableData("LocalizeRes", 110027).TextValue .. chat_content;
		--BP_ChatEntranceNewMsg = "[招募消息]" .. chat_content;
	else
		BP_ChatEntranceNewMsg = chat_content;
	end	
	
	BP_ChatEntranceNewChannel = channel_type;
	if "" == voice_file then
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "YouHaveANewMsg");
	end;
end

function LobbyChatEntranceUI.RefreshUnreadList(message_count)
	if not BP_ChatEntranceValid then
		return;
	end
	
	local count = 0;
	for k, v in pairs(LobbyChatSystem.friendChatList) do
		count = v.newMessageCount + count;
	end
	
	BP_ChatFriendNewMsgCount = count;
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "YourFriendCalledYou");
end

function LobbyChatEntranceUI.RefreshChatroomUnread(count)
	if not BP_ChatEntranceValid then
		return;
	end	
	
	BP_ChatEntranceChatroomNewMsgCount = count;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "ChatroomUnreadChanged");
	
	if 0 == count then
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "ChatroomUnreadCleared");
	else
		LuaClassObj.HandleUIMessage(bp_chat_entrance, "ChatroomUnreadAppeared");
	end
end

function LobbyChatEntranceUI.RefreshTickBufferState()
	if not BP_ChatEntranceValid then
		return;
	end
	
	BP_ChatEntranceTickBufferList = nil ~= LobbyChatSystem.chatBufferList and #LobbyChatSystem.chatBufferList > 0;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "OnRefreshMsgBufferState");
end

function LobbyChatEntranceUI.OpenChatUI()
	EventOpenChatWindow();
    
    ClientSendBAReport(BP_BA_LOBBY_CHAT_PANEL, 0);
end

function EventOpenChatUI()	
end

function EventOpenChatWindow()
	BP_ChatEntranceNewSender = "";
	BP_ChatEntranceNewMsg = "";
	BP_ChatEntranceNewChannel = 0;
	
	LuaClassObj.HandleUIMessage(bp_chat_entrance, "UIHide");
	LobbyChatSystem:OpenUI();
end

function EventOpenFriendNewChat()
	LobbyChatSystem.OpenNewestFriendChat();
end

function EventTestQuitRoom()
	--GlobalChatVoice.QuitVoiceRoomOnDeactivate();	
	TeamUpSystem.ProcessChat();
	GlobalChatVoice.QuitRoomTemp();
end

function EventTestJoinGameRoom()
	--GlobalChatVoice.JoinVoiceRoomOnReactivate();
	local temp = {};
	table.insert(temp, 12045234);
	table.insert(temp, 954875721);
	table.insert(temp, 93939393);
	
	GlobalChatVoice.JoinGameVoiceRoom(temp);
	GlobalChatVoice.OnJoinGameVoiceRoom();
end

function EventPopMessageBuffer()
	LobbyChatSystem.PopBufferList();
end

function EventAchieveQuickMsgStr()
	if 0 == BP_ChatEntranceQuickMsgId then
		return;
	end

	BP_ChatEntranceQuickMsgStr = Client.GetTableData("LocalizeRes", BP_ChatEntranceQuickMsgId).TextValue;	
end

function EventSendTeamQuickMsg()
	if not BP_ChatEntranceValid then
		return;
	end		
	
	if not BP_ChatEntranceTeamed then
		return;
	end
	
	if 0 == BP_ChatEntranceQuickMsgId then
		return;
	end
	
	--local msg = Client.GetTableData("LocalizeRes", BP_ChatEntranceQuickMsgId).TextValue;
	LobbyChatSystem.on_chat_quick_msg(BP_ChatEntranceQuickMsgId);
end

function EventClickBtnRecruit()
	RecruitUI.ShowUI();
end
