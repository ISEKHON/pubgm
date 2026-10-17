GlobalChatVoice = GlobalChatVoice or
{
	VOICE_PROCEDURE_INIT = "init";
	VOICE_PROCEDURE_UNINIT = "uninit";
	VOICE_PROCEDURE_JOIN = "join";

	voiceChatMode = -1;
	voiceIsInited = false;
	
	voiceErrHandle = 0;
	voiceErrMaxHandle = 3;	
	
	voiceOpenMic = false;
	voiceOpenSpeaker = false;
	voiceEnterBackground = false;
	
	voiceLobbyMemberId = "";
	voiceEnterRoomId = "";
	voiceBufferRoomId = "";
	voiceLobbyRoomId = "";
	voiceGameRoomId = "";
	voiceOperationLock = false;
	
	voiceTeamOperationList = 
	{
	};
	
	-- OPERATION ERROR CODE
	GVOICE_OPERR_PMSMIC_ERR = 12291;	-- 0x3003 	android
	GVOICE_OPERR_PMSMIC_ERR2 = 20481;	-- 0x5001	ios
	GVOICE_OPERR_UPLOAD_ERR = 12293;	-- 0x3005
	GVOICE_OPERR_HTTP_BUSY = 12294;		-- 0x3006
	GVOICE_OPERR_DOWNLOAD_ERR = 12295;	-- 0x3007
	GVOICE_OPERR_TOTEXTPROCESSING_ERR = 28673;	-- 0x07001
	GVOICE_OPERR_CHANGEMODE_ERR = 4102;	-- 0x1006
	GVOICE_OPERR_ALREADYINROOM_ERR = 8200;	-- 0x2008	
	
	-- COMPLETE ERROR CODE
	GVOICE_JOINROOM_SUCC = 1;
	GVOICE_JOINROOM_TIMEOUT = 2;
	GVOICE_JOINROOM_SVRERROR = 3;
	
	GVOICE_COMPLETE_ERR = 5;
	
	GVOICE_QUITROOM_SUCC = 6;
	
	GVOICE_UPLOAD_ERROR = 12;
	
	GVOICE_DOWNLOAD_ERROR = 14;
}

BP_GlobalChatvoiceMicOpened = false;
BP_GlobalChatvoiceSpeakerOpened = false;

BP_GlobalChatvoiceIsTeamup = false;

BP_GlobalChatvoiceRecordSuccess = false;

BP_GlobalChatvoiceCurrentRole = "";
BP_GlobalChatvoiceCurrentRoom = "";
BP_GlobalChatvoiceCurrentMode = -1;
BP_GlobalChatvoiceCurrentStage = "";

-- 离线相关
BP_GlobalChatvoiceTotalLimit = 10;
BP_GlobalChatvoiceUploadMsgId = "";
BP_GlobalChatvoiceToTextContent = "";
BP_GlobalChatvoiceUploadTime = 0;
BP_GlobalChatvoiceCurrentPlayFile = "";

BP_STRUCT_GlobalChatvoiceDownloadData = 
{
	msgContextGID = "",
	msgSenderGID = "",	
	msgLength = 0,
	msgChannel = 0,
	msgId = 0,
	fileId = "",
}

BP_ARRAY_GlobalChatvoiceDownloadList = 
{
	BP_STRUCT_GlobalChatvoiceDownloadData = _G.BP_STRUCT_GlobalChatvoiceDownloadData,
};

function bp_chat_voice_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_chat_voice,
    {{Path="/Game/UMG/UI_Logic/ChatVoice/Global_Voice.Global_Voice_C", Container="Default", ZOrder=10}},
    {"Lobby", "Fighting", "Training", "Pending"},
	true,
	bp_chat_voice_OnModeSwitched ~= nil
  );
end

function bp_chat_voice_OnModeSwitched(gamestatus)	
	local status = string.lower(gamestatus);
	GlobalChatVoice.StageChanged(status);
	-- 处理各阶段mic和speaker状态相关内容
	if "lobby" == status then		
	else		
	end
end

function bp_chat_voice_OnModeAboutToSwitched()

end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function EventSetInfo_Push()
end

-- BP设置mode后调用
function EventChangeGVoiceMode()
	GlobalChatVoice.OnVoiceModeChange();
end

function EventClearGVoiceProcedure()
	GlobalChatVoice.OnClearVoiceProcedure();
end

function EventStopPlayGVoiceRecord()	
	GlobalChatVoice.OnStopPlayRecordFile();
end

function EventStartPlayGVoiceRecord()
	GlobalChatVoice.OnStartPlayRecordFile();
end

function EventStartGVoiceRecord()
	GlobalChatVoice.OnStartRecordVoice();
end

function EventStopGVoiceRecord()
	GlobalChatVoice.OnStopRecordVoice();
end

function EventCancelGVoiceRecord()
	GlobalChatVoice.OnCancelRecordVoice();
end

function EventUploadGVoiceRecord()
	GlobalChatVoice.OnUploadRecordVoice();
end

function EventChangeMicState()
	GlobalChatVoice.ChangeMicOpen(BP_GlobalChatvoiceMicOpened);
end

function EventChangeSpeakerState()
	GlobalChatVoice.ChangeSpeakerOpen(BP_GlobalChatvoiceSpeakerOpened);
end

function EventNotifyVoiceProcedureFailed()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106014).TextValue);
end

function EventNotifyVoiceChatFailToRecord()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106012).TextValue);
end

function EventNotifyVoiceRecordTooShort()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106015).TextValue);
end

function EventNotifyVoiceOpenSpeaker()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106011).TextValue);
end

function EventNotifySystemVoiceOpen()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 102100).TextValue);
end

function EventNotifySystemMicOpen()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 102101).TextValue);
end

function EventNotifySystemSpeakerOpen()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 102102).TextValue);
end

function EventNotifyDownloadFailed()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106056).TextValue);
end

function EventNotifyRecordTooShort()
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106015).TextValue);
end

function EventTickVoiceRoom()
	if false == GlobalChatVoice.voiceIsInited then
		return;
	end
	
	if true == GlobalChatVoice.voiceOperationLock then				
		return;
	end
	
	if true == GlobalChatVoice.voiceEnterBackground then
		return;
	end
	
	if 0 ~= #GlobalChatVoice.voiceTeamOperationList then
		return;
	end	
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_chat_voice));
	if "lobby" == curStatus then
		if GlobalChatVoice.voiceEnterRoomId ~= GlobalChatVoice.voiceLobbyRoomId then			
			GlobalChatVoice.OnJoinLobbyVoiceRoom();
		end
	elseif "fighting" == curStatus then
		if GlobalChatVoice.voiceEnterRoomId ~= GlobalChatVoice.voiceGameRoomId then
			GlobalChatVoice.OnJoinGameVoiceRoom();
		end
	end
end

--=======================================================================--
function GlobalChatVoice.ResetEventListener()

end

function GlobalChatVoice.ResetRoleInfo(roleId, isRelogin)	
	BP_GlobalChatvoiceCurrentRole = FuncUtil:StrTrim(roleId);
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnResetRoleInfo");
	
	if not isRelogin then
		GlobalChatVoice.InitRoleVoice();
	else
		log("GVoice Relogin");
		
		GlobalChatVoice.QuitRoomTemp();
	end		
end

function GlobalChatVoice.ClearRoleInfo()	
	log("gvoice clear role");
	
	GlobalChatVoice.ChangeMicOpen(false);
	GlobalChatVoice.ChangeSpeakerOpen(false);		
	
	GlobalChatVoice.UninitRoleVoice();
	
	BP_GlobalChatvoiceCurrentRole = "";
	BP_GlobalChatvoiceCurrentRoom = "";
	BP_GlobalChatvoiceCurrentMode = -1;
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnClearRoleInfo");	
end

function GlobalChatVoice.InitRoleVoice()
	--log("gvoice init role voice");
	if true == GlobalChatVoice.voiceIsInited then
		log("gvoice already inited role");
		return;
	end
	
	GlobalChatVoice.voiceIsInited = true;
	GlobalChatVoice.OnVoiceInited();
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, GlobalChatVoice.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, GlobalChatVoice.WardRobeAvatarResetClose);
end

--[[
	退出登录时清理音频相关内容
]]
function GlobalChatVoice.UninitRoleVoice()
	GlobalChatVoice.QuitVoiceRoom();
	GlobalChatVoice.voiceIsInited = false;		
	GlobalChatVoice.voiceOperationLock = false;
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, GlobalChatVoice.WardRobeAvatarResetOpen);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, GlobalChatVoice.WardRobeAvatarResetClose);
end

function GlobalChatVoice.WardRobeAvatarResetOpen()
    log("GlobalChatVoice.WardRobeAvatarResetOpen")
		LuaClassObj.HandleUIMessage(bp_chat_voice, "UIHide");	
end

function GlobalChatVoice.WardRobeAvatarResetClose()
    log("GlobalChatVoice.WardRobeAvatarResetClose")
    LuaClassObj.HandleUIMessage(bp_chat_voice, "UIShow");	
end

function GlobalChatVoice.StageChanged(stage)

	BP_GlobalChatvoiceCurrentStage = stage;
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnGameStageChanged");
	
	log("GVoice Stage Changed " .. stage);
	
	if "lobby" == stage then
		GlobalChatVoice.OnQuitGameVoiceRoom();
		GlobalChatVoice.OnJoinLobbyVoiceRoom();
	elseif "login" ~= stage and "createrole" ~= stage then
		GlobalChatVoice.QuitLobbyVoiceRoom();
		GlobalChatVoice.OnJoinGameVoiceRoom();
	end
end

function GlobalChatVoice.SetIsTeamup(isTeamup)
	BP_GlobalChatvoiceIsTeamup = isTeamup;
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTeamStateChanged");
end

function GlobalChatVoice.JoinLobbyVoiceRoom(room_id)	
	GlobalChatVoice.voiceLobbyRoomId = room_id;
	
	GlobalChatVoice.OnJoinLobbyVoiceRoom();
end

function GlobalChatVoice.QuitLobbyVoiceRoom()
	GlobalChatVoice.voiceLobbyRoomId = "";
	GlobalChatVoice.voiceLobbyMemberId = "";
	GlobalChatVoice.OnQuitLobbyVoiceRoom();
end

function GlobalChatVoice.OnJoinLobbyVoiceRoom()			
	log("GVoice On Join Lobby Voice Room " .. GlobalChatVoice.voiceLobbyRoomId);
	
	if BP_GlobalChatvoiceCurrentStage == "lobby" then
		GlobalChatVoice.JoinVoiceRoom(GlobalChatVoice.voiceLobbyRoomId);
	end
end

function GlobalChatVoice.OnQuitLobbyVoiceRoom()
	log("GVoice On Quit Lobby Voice Room");
	
	if "lobby" == BP_GlobalChatvoiceCurrentStage then
		GlobalChatVoice.QuitVoiceRoom();
	end		
end

function GlobalChatVoice.JoinGameVoiceRoom(team_info)	
	log_tree("GVoice Join Game Voice room team info ", team_info);
	
	local checkSum = 0;
	for i = 1, #team_info do
		checkSum = team_info[i] + checkSum;
	end
	
	local room_id = "";
	
	table.sort(team_info, function(a, b) return a > b end);
	
	if #team_info > 1 then
		room_id = tostring(checkSum);
		
		for i = 1, #team_info do
			room_id = room_id .. string.sub(tostring(team_info[i]), -4);
		end
	end
	
	log("GVoice Join Game Voice Room: " .. room_id);
	
	if "" ~= room_id then
		GlobalChatVoice.voiceGameRoomId = room_id .. "_in_game";	
	else
		GlobalChatVoice.voiceGameRoomId = "";
	end	
	
	GlobalChatVoice.OnJoinGameVoiceRoom();	
end

function GlobalChatVoice.OnJoinGameVoiceRoom()	
	log("GVoice On Join Game Voice Room" .. GlobalChatVoice.voiceGameRoomId);
	
	if "" ~= GlobalChatVoice.voiceGameRoomId then
		GlobalChatVoice.JoinVoiceRoom(GlobalChatVoice.voiceGameRoomId);
	else
		GlobalChatVoice.QuitVoiceRoom();
	end
		
end

function GlobalChatVoice.OnQuitGameVoiceRoom()	
	log("GVoice On Quit Game Voice Room");
	
	GlobalChatVoice.voiceGameRoomId = "";
	GlobalChatVoice.QuitVoiceRoom();	
end


--[[
	room_id (string, leader_gid when team up or specific room_id)
]]
function GlobalChatVoice.JoinVoiceRoom(room_id)	
	GlobalChatVoice.QuitVoiceRoom();
	
	log("GVoice Join Voice Room" .. room_id);
	
	local room = FuncUtil:StrTrim(tostring(room_id));
	
	if GlobalChatVoice.voiceBufferRoomId == room then
		if "" ~= room then
			log("GVoice join same room" .. room);
		end
		return;
	end
	
	if false == GlobalChatVoice.voiceOperationLock and room == GlobalChatVoice.voiceEnterRoomId then
		GlobalChatVoice.ResetVoiceOperation();
		return;
	end
	
	GlobalChatVoice.voiceBufferRoomId = room;
	
	if not GlobalChatVoice.voiceIsInited then
		log("gvoice not inited when join team");
		return;
	end
	
	GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, room, true);
	GlobalChatVoice.HandleVoiceRoomOperation();	
end

function GlobalChatVoice.QuitVoiceRoom()	
	log("GVoice Quit Voice Room");

	if false == GlobalChatVoice.voiceOperationLock and "" == GlobalChatVoice.voiceEnterRoomId then
		GlobalChatVoice.ResetVoiceOperation();
		log("GVoice Quit Voice room returned when done");
		return;
	end
	
	GlobalChatVoice.voiceBufferRoomId = "";
	
	if not GlobalChatVoice.voiceIsInited then
		log("GVoice Quit Voice Room Returned when not initialize");
		return;
	end
		
	GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, "", false);
	GlobalChatVoice.HandleVoiceRoomOperation();	
end

function GlobalChatVoice.QuitRoomTemp()	
	if false == GlobalChatVoice.voiceOperationLock and "" == GlobalChatVoice.voiceEnterRoomId then
		GlobalChatVoice.ResetVoiceOperation();
		GlobalChatVoice.HandleReenterVoiceRoom();
		return;
	end
	
	if not GlobalChatVoice.voiceIsInited then		
		return;		
	end
	
	GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, "", false);
	GlobalChatVoice.HandleVoiceRoomOperation();	
end

function GlobalChatVoice.QuitVoiceRoomOnDeactivate()	
	GlobalChatVoice.voiceEnterBackground = true;
	
	GlobalChatVoice.QuitRoomTemp();	
	LobbyChatLogic.OnApplicationDeactivated();
end

function GlobalChatVoice.JoinVoiceRoomOnReactivate()	
	GlobalChatVoice.voiceEnterBackground = false;
	
	if false == GlobalChatVoice.voiceOperationLock and GlobalChatVoice.voiceBufferRoomId == GlobalChatVoice.voiceEnterRoomId then
		GlobalChatVoice.ResetVoiceOperation();
		return;
	end
	
	if not GlobalChatVoice.voiceIsInited then		
		return;
	end
	
	GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, GlobalChatVoice.voiceBufferRoomId, true);
	GlobalChatVoice.HandleVoiceRoomOperation();	
end

function GlobalChatVoice.ChangeMicOpen(open)	
	GlobalChatVoice.voiceOpenMic = open;
	BP_GlobalChatvoiceMicOpened = open;
	
	if GlobalChatVoice.voiceLobbyRoomId == GlobalChatVoice.voiceEnterRoomId then
		TeamUpSystem.ReportVoiceInfo(GlobalChatVoice.voiceLobbyMemberId, BP_GlobalChatvoiceMicOpened);
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnVoiceMicOpenChanged");	
end

function GlobalChatVoice.ChangeSpeakerOpen(open)	
	GlobalChatVoice.voiceOpenSpeaker = open;
	BP_GlobalChatvoiceSpeakerOpened = open;
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnVoiceSpeakerOpenChanged");	
end

function GlobalChatVoice.ResetVoiceOperation()	
	GlobalChatVoice.voiceTeamOperationList = {};	
end

function GlobalChatVoice.AddDownloadFile(context_gid, sender_gid, channel, msg_id, msg_length, file_id)	
	BP_ARRAY_GlobalChatvoiceDownloadList = {};
		
	local downloadData = {};
	downloadData.msgContextGID = context_gid;
	downloadData.msgSenderGID = sender_gid;
	downloadData.msgChannel = channel;
	downloadData.msgId = msg_id;
	downloadData.msgLength = msg_length;
	downloadData.fileId = file_id;
	
	table.insert(BP_ARRAY_GlobalChatvoiceDownloadList, downloadData);
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryDownloadVoiceRecord");	
end

function GlobalChatVoice.AddVoiceOperation(handle_type, custom_data, operation_type)	
	if #GlobalChatVoice.voiceTeamOperationList > 0 then
		local opData = GlobalChatVoice.voiceTeamOperationList[1];
		if (handle_type == opData.type) and (custom_data == opData.customData) and (operation_type == opData.operationEnter) then
			return;
		end
	end
	
	local operation = {};
	operation.type = handle_type;
	operation.customData = custom_data;
	operation.operationEnter = operation_type;
	
	table.insert(GlobalChatVoice.voiceTeamOperationList, operation);	
end

function GlobalChatVoice.TryStartRecordVoice()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryStartRecordVoice");
end

function GlobalChatVoice.TryStopRecordVoice()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryStopRecordVoice");
end

function GlobalChatVoice.TryCancelRecordVoice()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryCancelRecordVoice");
end

function GlobalChatVoice.TryStopPlayRecordVoice()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryStopPlayRecordVoice");
end

function GlobalChatVoice.TryCloseMic()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTryCloseMic");
end

function GlobalChatVoice.HandleVoiceRoomOperation()	
	log("GVoice handle voice room operation 1");
	
	if true == GlobalChatVoice.voiceOperationLock then		
		log("GVoice handle voice room operation 2");
		return;
	end
	
	if 0 == #GlobalChatVoice.voiceTeamOperationList then		
		log("GVoice handle voice room operation 3");
		return;
	end
	
	GlobalChatVoice.voiceOperationLock = true;	
	
	for i = 1, #GlobalChatVoice.voiceTeamOperationList do 
		local operationData = GlobalChatVoice.voiceTeamOperationList[i];		
		GlobalChatVoice.OnVoiceRoomChange(operationData.customData);
		break;		
	end		
end

function GlobalChatVoice.HandleVoiceRoomAsync()
	GlobalChatVoice.voiceOperationLock = false;
		
	if 0 ~= #GlobalChatVoice.voiceTeamOperationList then
		local operationData = GlobalChatVoice.voiceTeamOperationList[1];
		table.remove(GlobalChatVoice.voiceTeamOperationList, 1);
	end		
	
	GlobalChatVoice.HandleReenterVoiceRoom();
end

function GlobalChatVoice.HandleReenterVoiceRoom()
	if true == GlobalChatVoice.voiceEnterBackground then
		if "" == GlobalChatVoice.voiceEnterRoomId then
			GlobalChatVoice.ResetVoiceOperation();			
		end
		
		return;
	else
		if GlobalChatVoice.voiceBufferRoomId == GlobalChatVoice.voiceEnterRoomId then
			GlobalChatVoice.ResetVoiceOperation();
			return;
		end
	end
	
	if 0 == #GlobalChatVoice.voiceTeamOperationList then
		if GlobalChatVoice.voiceBufferRoomId ~= GlobalChatVoice.voiceEnterRoomId then
			local opEnter = false;
			if "" == GlobalChatVoice.voiceBufferRoomId then
				opEnter = false;
			else
				opEnter = true;
			end
						
			GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, GlobalChatVoice.voiceBufferRoomId, opEnter);
		else
			return;
		end		
	end	
		
	GlobalChatVoice.HandleVoiceRoomOperation();
end

function GlobalChatVoice.OnApplicationDeactivated()		
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnApplicationDeactivated");
	GlobalChatVoice.QuitVoiceRoomOnDeactivate();
end

function GlobalChatVoice.OnApplicationReactivated()		
	GlobalChatVoice.JoinVoiceRoomOnReactivate();
end

function GlobalChatVoice.OnVoiceInited()
	LobbyChatLogic.OnAfterVoiceInited();
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnGVoiceInited");
end

function GlobalChatVoice.OnVoiceUninited()
	
end

function GlobalChatVoice.OnVoiceRoomChange(roomId)	
	BP_GlobalChatvoiceCurrentRoom = roomId;	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnTeamVoiceRoomChanged");
	LobbyChatLogic.HandleVoiceRoomChange(roomId);
end

function GlobalChatVoice.OnVoiceModeChange()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnVoiceModeChanged");
end

function GlobalChatVoice.OnJoinVoiceRoomSuccess(room_name, member_id)
	if GlobalChatVoice.voiceLobbyRoomId == room_name then
		GlobalChatVoice.voiceLobbyMemberId = tostring(member_id);
		TeamUpSystem.ReportVoiceInfo(GlobalChatVoice.voiceLobbyMemberId, BP_GlobalChatvoiceMicOpened);
	end	
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnJoinVoiceRoomSuccess");
end

function GlobalChatVoice.OnQuitVoiceRoomSuccess(room_name)
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnQuitVoiceRoomSuccess");
end

function GlobalChatVoice.OnClearVoiceProcedure()
	LobbyChatLogic.OnClearVoiceProcedure();
end

function GlobalChatVoice.OnStopPlayRecordFile()
	LobbyChatLogic.OnStopPlayRecordFile();
end

function GlobalChatVoice.OnStartPlayRecordFile()
	LobbyChatLogic.OnStartPlayRecordFile();
end

function GlobalChatVoice.OnStartRecordVoice()
	LobbyChatLogic.OnStartRecordVoice();
end

function GlobalChatVoice.OnStopRecordVoice()
	LobbyChatLogic.OnStopRecordVoice();
end

function GlobalChatVoice.OnCancelRecordVoice()
	LobbyChatLogic.OnCancelRecordVoice();
end

function GlobalChatVoice.OnUploadRecordVoice()
	LobbyChatLogic.OnUploadRecordVoice();
end


function GlobalChatVoice.OnApplyMessageKeyComplete()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnApplyMessageKeyComplete");
end

function GlobalChatVoice.OnUploadRecordFileComplete()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnUploadRecordFileComplete");
	GlobalChatVoice.OnSpeechToTextComplete();
end

function GlobalChatVoice.OnSpeechToTextComplete()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnUploadSpeechToTextComplete");
	
	LobbyChatLogic.OnUploadToTextComplete(BP_GlobalChatvoiceToTextContent, BP_GlobalChatvoiceUploadTime, BP_GlobalChatvoiceUploadMsgId);
end

function GlobalChatVoice.OnDownloadFileComplete()
	if nil == BP_ARRAY_GlobalChatvoiceDownloadList or 0 == #BP_ARRAY_GlobalChatvoiceDownloadList then
		log("GVoice_Download Complete Undefined voice");
		return;
	end
	
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnDownloadFileComplete");
end

function GlobalChatVoice.OnRecordSuccess()
	BP_GlobalChatvoiceRecordSuccess = true;
end

function GlobalChatVoice.OnRecordFailed()
	BP_GlobalChatvoiceRecordSuccess = false;
end

function GlobalChatVoice.OnUploadSuccess()

end

function GlobalChatVoice.OnUploadFailed()
	LuaClassObj.HandleUIMessage(bp_chat_voice, "OnUploadRecordFailed");
end

function GlobalChatVoice.OnSpeechToTextSuccess()

end

function GlobalChatVoice.OnSpeechToTextFailed()

end

function GlobalChatVoice.OnDownloadFileSuccess()

end

function GlobalChatVoice.OnDownloadFileFailed()

end

function GlobalChatVoice.OnOpenMicSuccess()
	log("GVoice_OnOpenMicSuccess");
end

function GlobalChatVoice.OnOpenMicFailed()
	log("GVoice_OnOpenMicFailed");
	GlobalChatVoice.TryCancelRecordVoice();
	GlobalChatVoice.TryCloseMic();
end

function GlobalChatVoice.OnMemberSpeaking(room_name, member, status)
	if room_name ~= GlobalChatVoice.voiceLobbyRoomId then
		return;
	end	
	
	if TeamUpSystem.TeamInfo == nil then
		return;
	end

	if TeamUpSystem.TeamInfo.members == nil then
		return;
	end

	for k,v in pairs(TeamUpSystem.TeamInfo.members) do
		local teamMemberInfo = v;
		if member == teamMemberInfo.voice.voice_uid then
			TeamUpUI.SetVoiceSpeaking(k, 0 ~= status);
		end
	end
end

--[[
	GVoice Callbacks
]]

function GVoice_JoinRoomNotify(code, roomName, memberID)
	log("GVoice_JoinRoomNotify " .. tostring(code) .. roomName .. memberID);
	
	if GlobalChatVoice.GVOICE_JOINROOM_SUCC~= code then
		GlobalChatVoice.HandleJoinRoomFailed();
	else
		GlobalChatVoice.voiceErrHandle = 0;
		GlobalChatVoice.voiceEnterRoomId = roomName;
		GlobalChatVoice.OnJoinVoiceRoomSuccess(roomName, memberID);
		GlobalChatVoice.HandleVoiceRoomAsync();
	end	
end

function GVoice_QuitRoomNotify(code, roomName)
	log("GVoice_QuitRoomNotify " .. tostring(code) .. roomName);
	
	if GlobalChatVoice.GVOICE_QUITROOM_SUCC ~= code then
		GlobalChatVoice.HandleQuitRoomFailed();
	else
		GlobalChatVoice.voiceErrHandle = 0;
		GlobalChatVoice.voiceEnterRoomId = "";
		GlobalChatVoice.OnQuitVoiceRoomSuccess();
		GlobalChatVoice.HandleVoiceRoomAsync();
	end		
end

function GVoice_JoinLbsRoomNotify(code, roomName)
	
	log("GVoice_JoinLbsRoomNotify " .. tostring(code) .. " " .. roomName);
end

function GVoice_QuitLbsRoomNotify(code, room_name)
	
	log("GVoice_QuitLbsRoomNotify " .. tostring(code) .. " " .. room_name);
end

-- GVoice
-- gvoice auth success
function GVoice_ApplyMessageKeyNotify(code)
	log("GVoice_ApplyMessageKeyNotify " .. code);
	GlobalChatVoice.OnApplyMessageKeyComplete();
end

-- Upload notify
function GVoice_UploadFileNotify(code, filePath, fileID)
	log("GVoice_UploadFileNotify code=" .. code .. " filePath=" .. filePath .. " fileID=" .. fileID);
	BP_GlobalChatvoiceUploadMsgId = fileID;
	GlobalChatVoice.OnUploadRecordFileComplete();
end

function GVoice_SpeechToTextNotify(code, fileID, result)
	log("GVoice_SpeechToTextNotify code=" .. tostring(code) .. " fileID=" .. tostring(fileID) .. " result=" .. result);
	BP_GlobalChatvoiceToTextContent = result;
	GlobalChatVoice.OnSpeechToTextComplete();
end

function GVoice_DownLoadFileNotify(code, filePath, fileID)
	log("GVoice_DownLoadFileNotify " .. tostring(code) .. filePath .. tostring(fileID));
	
	GlobalChatVoice.OnDownloadFileComplete();
end

-- OPERATION NOTIFY

function GVoice_SetAppInfoFailed(code, user_id)
	log("GVoice_SetAppInfoFailed " .. tostring(code) .. " user_id " .. user_id);
	PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));
end

function GVoice_RecordSuccess()
	log("GVoice_RecordSuccess");
	GlobalChatVoice.OnRecordSuccess();
end

function GVoice_RecordFailed(code)
	log("GVoice_RecordFailed " .. tostring(code));
	
	if (GlobalChatVoice.GVOICE_OPERR_PMSMIC_ERR == code) or (GlobalChatVoice.GVOICE_OPERR_PMSMIC_ERR2 == code) then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106048).TextValue)--(Client.GetTableData("LocalizeRes", 106048).TextValue);
	elseif GlobalChatVoice.GVOICE_OPERR_HTTP_BUSY == code then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106049).TextValue);--(Client.GetTableData("LocalizeRes", 106049).TextValue);
	else
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));--(Client.GetTableData("LocalizeRes", 106050).TextValue);
	end
		
	GlobalChatVoice.OnRecordFailed();	
end

function GVoice_UploadSuccess()
	GlobalChatVoice.OnUploadSuccess();
end

function GVoice_UploadFailed(code)
	log("GVoice_UploadFailed " .. tostring(code));
	
	if GlobalChatVoice.GVOICE_OPERR_UPLOAD_ERR == code then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106048).TextValue)--(Client.GetTableData("LocalizeRes", 106051).TextValue);
	elseif GlobalChatVoice.GVOICE_OPERR_HTTP_BUSY == code then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106049).TextValue);--(Client.GetTableData("LocalizeRes", 106049).TextValue);
	elseif GlobalChatVoice.GVOICE_OPERR_CHANGEMODE_ERR == code then
		;
	else
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));--(Client.GetTableData("LocalizeRes", 106050).TextValue);
	end
	
	GlobalChatVoice.OnUploadFailed();
end	

function GVoice_SpeechToTextSuccess()
	GlobalChatVoice.OnSpeechToTextSuccess();	
end

function GVoice_SpeechToTextFailed(code)
	log("GVoice_SpeechToTextFailed " .. tostring(code));
	
	if GlobalChatVoice.GVOICE_OPERR_HTTP_BUSY == code then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106049).TextValue);--(Client.GetTableData("LocalizeRes", 106049).TextValue);
	elseif GlobalChatVoice.GVOICE_OPERR_TOTEXTPROCESSING_ERR == code then
		;
	elseif GlobalChatVoice.GVOICE_OPERR_CHANGEMODE_ERR == code then
		;
	else
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));--(Client.GetTableData("LocalizeRes", 106050).TextValue);
	end	
	
	GlobalChatVoice.OnSpeechToTextFailed();
end

function GVoice_DownloadFileSuccess()
	GlobalChatVoice.OnDownloadFileSuccess();
end

function GVoice_DownloadFileFailed(code)
	log("GVoice_DownloadFileFailed " .. tostring(code));
	
	if GlobalChatVoice.GVOICE_OPERR_HTTP_BUSY == code then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106049).TextValue);--(Client.GetTableData("LocalizeRes", 106049).TextValue);
	elseif GlobalChatVoice.GVOICE_OPERR_CHANGEMODE_ERR == code then
		;
	else
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));--(Client.GetTableData("LocalizeRes", 106050).TextValue);
	end
	
	GlobalChatVoice.OnDownloadFileFailed();
end

function GVoice_PlayFileSuccess()

end

function GVoice_PlayFileFailed(code)
	log("GVoice_PlayFileFailed " .. tostring(code));	
end

function GVoice_OpenSpeakerSuccess()
	log("GVoice_OpenSpeakerSuccess");
end

function GVoice_OpenSpeakerFailed(code)
	log("GVoice_OpenSpeakerFailed " .. tostring(code));
end

function GVoice_CloseSpeakerSuccess()
	log("GVoice_CloseSpeakerSuccess");
end

function GVoice_CloseSpeakerFailed(code)
	log("GVoice_CloseSpeakerFailed " .. tostring(code));
end

function GVoice_CloseMicSuccess()
	log("GVoice_CloseMicSuccess");
end

function GVoice_CloseMicFailed(code)
	log("GVoice_CloseMicFailed " .. tostring(code));
end

function GVoice_OpenMicSuccess()
	GlobalChatVoice.OnOpenMicSuccess();
end

function GVoice_OpenMicFailed(code)
	log("GVoice_OpenMicFailed " .. tostring(code));
	
	if (GlobalChatVoice.GVOICE_OPERR_PMSMIC_ERR == code) or (GlobalChatVoice.GVOICE_OPERR_PMSMIC_ERR2 == code) then
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106048).TextValue)--(Client.GetTableData("LocalizeRes", 106048).TextValue);
	else
		PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", 106050).TextValue .. tostring(code));
	end
	
	GlobalChatVoice.OnOpenMicFailed();
end

function GlobalChatVoice.HandleJoinRoomFailed()
	GlobalChatVoice.voiceErrHandle = GlobalChatVoice.voiceErrHandle + 1;
	
	if GlobalChatVoice.voiceErrHandle > GlobalChatVoice.voiceErrMaxHandle then
		log("GVoice_Try Redo Join Room Failed");
		GlobalChatVoice.voiceErrHandle = 0;
		GlobalChatVoice.voiceOperationLock = false;
		GlobalChatVoice.voiceIsInited = true;			
		GlobalChatVoice.voiceBufferRoomId = "";
		GlobalChatVoice.ResetVoiceOperation();
		GlobalChatVoice.AddVoiceOperation(GlobalChatVoice.VOICE_PROCEDURE_JOIN, "", false);
		GlobalChatVoice.HandleVoiceRoomOperation();
		return;
	end	
	
	GlobalChatVoice.voiceOperationLock = false;
	GlobalChatVoice.HandleVoiceRoomOperation();
end

function GlobalChatVoice.HandleQuitRoomFailed()
	if #GlobalChatVoice.voiceTeamOperationList > 0 then
		local opData = GlobalChatVoice.voiceTeamOperationList[1];
		if "" == opData.customData then			
			table.remove(GlobalChatVoice.voiceTeamOperationList, 1);					
		end
	else
		GlobalChatVoice.voiceErrHandle = GlobalChatVoice.voiceErrHandle + 1;
		if GlobalChatVoice.voiceErrHandle > GlobalChatVoice.voiceErrMaxHandle then
			log("GVoice_Try Redo Quit Room Failed");
			GlobalChatVoice.voiceErrHandle = 0;
			GlobalChatVoice.voiceOperationLock = false;		
			GlobalChatVoice.voiceIsInited = true;
			GlobalChatVoice.ResetVoiceOperation();
			return;
		end
	end	
	
	GlobalChatVoice.voiceOperationLock = false;
	GlobalChatVoice.HandleVoiceRoomOperation();
end

function GVoice_JoinRoomFailed(code)
	log("GVoice_JoinRoomFailed " .. tostring(code));
	
	if GlobalChatVoice.GVOICE_OPERR_ALREADYINROOM_ERR == code then		
		GlobalChatVoice.voiceOperationLock = false;
		GlobalChatVoice.ResetVoiceOperation();
		GlobalChatVoice.voiceEnterRoomId = GlobalChatVoice.voiceBufferRoomId;
		GlobalChatVoice.QuitRoomTemp();		
	else
		GlobalChatVoice.HandleJoinRoomFailed();
	end	
end

function GVoice_QuitRoomFailed(code)
	log("GVoice_QuitRoomFailed " .. tostring(code));
	
	GlobalChatVoice.HandleQuitRoomFailed();
end

function GVoice_OnCallGetAuthKey(code)

	log("GVoice_OnCallGetAuthKey " .. tostring(code));
end

function GVoice_JoinLbsRoomFailed(code)

	log("GVoice_JoinLbsRoomFailed " .. tostring(code));
end

function GVoice_QuitLbsRoomFailed(code)
	log("GVoice_QuitLbsRoomFailed " .. tostring(code));
end

function GVoice_MemberIsSpeakingNotify(room_name, member, status)
	--log("GVoice_MemberIsSpeakingNotify " .. room_name .. " " .. tostring(member) .. " " .. tostring(status))
	GlobalChatVoice.OnMemberSpeaking(room_name, member, status);
end

function GVoice_ReportVoiceTimeToServer(totalTalkingTime, totalGamingTime)
	log("----report player voice time: talkingTime = " .. tostring(totalTalkingTime).." --gameTime = "..tostring(totalGamingTime));
	NetUtil.SendPkg("report_game_activity", totalTalkingTime, totalGamingTime);
end

function GVoice_StatusUpdatedNotify(room_name, member_id)
	log("GVoice_StatusUpdatedNotify" .. room_name);
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_chat_voice));
	if "lobby" == curStatus and room_name == GlobalChatVoice.voiceLobbyRoomId then
		GlobalChatVoice.QuitRoomTemp();
	elseif "fighting" == curStatus and room_name == GlobalChatVoice.voiceGameRoomId then
		GlobalChatVoice.QuitRoomTemp();
	else
		log("GVoice_StatusUpdatedNotify other status " .. room_name .. " lobby room " .. GlobalChatVoice.voiceLobbyRoomId .. " game room " .. GlobalChatVoice.voiceGameRoomId);
		log("GVoice_StatusUpdatedNotify error stage " .. curStatus);
	end
end