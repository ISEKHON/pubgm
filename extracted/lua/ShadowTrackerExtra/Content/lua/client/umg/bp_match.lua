--匹配界面弹窗

MatchPopupUI = MatchPopupUI or 
{
	
}

BP_PassedTime= 0;	--重连后已经开始匹配了多少秒了
BP_Estimate_time = 0;
BP_PlayerStatus = 1;
BP_IsTeamLeader = true;

BP_IsMatchNoticeShowed = true;

BP_MatchPopUI_CurLevel = "";	--当前是哪个level（lobby or login etc.）
-- 国际化选服
BP_IsChooingZoneAccess = true;

--注册widget
function bp_match_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_match,
    {{Path="/Game/UMG/UI_BP/Match/MatchPopup_BP.MatchPopup_BP_C", Container="Default", ZOrder=15}},
    {"Lobby"},
	false,
	bp_match_OnModeSwitched ~= nil
  );
end


function EventFetchInfo()
	 
end

function bp_match_OnModeAboutToSwitched(gamestatus)

end


--跳转到Lobby
function bp_match_OnModeSwitched(gamestatus)
	BP_MatchPopUI_CurLevel = string.lower(gamestatus);
	if string.lower(gamestatus) == "lobby" then
        --拉起匹配UI--
        MatchPopupUI:Init();

        if LobbySystem.isInMatch == true then
        	MatchPopupUI.ResetWhenReconnected(NetUtil.GetCurServerTime() - LobbySystem.beginMatchTime);
        end
	end
end
function MatchPopupUI:Init()
	log("MatchPopupUI:Init UIShow");
	LuaClassObj.HandleUIMessage(bp_match, "UIShow");
	BP_IsMatchNoticeShowed = true;

	EventSystem:registEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC, MatchPopupUI.MatchUIEventHandler);
	EventSystem:registEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_FAILED, MatchPopupUI.MatchUIEventHandler);
	EventSystem:registEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, MatchPopupUI.MatchUIEventHandler);
	EventSystem:registEvent(EVENTTYPE_LOGIN, EVENTID_LOGIN_SUCCESS, MatchPopupUI.MatchUIEventHandler);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, MatchPopupUI.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, MatchPopupUI.WardRobeAvatarResetClose);
end

function MatchPopupUI:Release()
	EventSystem:unregistEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_TEAMINFO_SYNC, MatchPopupUI.MatchUIEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_FAILED, MatchPopupUI.MatchUIEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, MatchPopupUI.MatchUIEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_LOGIN, EVENTID_LOGIN_SUCCESS, MatchPopupUI.MatchUIEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, MatchPopupUI.WardRobeAvatarResetOpen);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, MatchPopupUI.WardRobeAvatarResetClose);
end

function MatchPopupUI.MatchUIEventHandler(eventType, eventID, vars)
	if eventID == EVENTID_TEAMUP_TEAMINFO_SYNC then
		MatchPopupUI.UpdateState();
	end

	if eventType == EVENTTYPE_NETWORK then
		if eventID == EVENTID_LOBBY_SERVER_CONNECT_FAILED then
			log("大厅连接断开,匹配计时暂停");
			LuaClassObj.HandleUIMessage(bp_match, "StopTimeCounting");
		end	
	end

	if eventType == EVENTTYPE_LOGIN then
		if eventID == EVENTID_BACKLOGIN  or  eventID == EVENTID_LOGIN_SUCCESS then
			if eventID == EVENTID_BACKLOGIN then
				log("----back to login-----");
			end

			if eventID == EVENTID_LOGIN_SUCCESS then
				log("----login(or reconnected log in)-----");
			end
			--判断一下上一次是否是在匹配状态，不是的话没必要刷状态，也没必要刷UI--
			if LobbySystem.isInMatch then
				log("----clear last match state by login msg-----");
				MatchPopupUI.OnMatchCancel();
				LobbySystem.ResetMatchInfo();
			end	
		end
	end
end

function MatchPopupUI:Hide()
	LuaClassObj.HandleUIMessage(bp_match, "UIHide");
end

function MatchPopupUI.WardRobeAvatarResetOpen()
	MatchPopupUI:Hide();
end

function MatchPopupUI.WardRobeAvatarResetClose()
	LuaClassObj.HandleUIMessage(bp_match, "UIShow");
end

function EventIsChoosingZoneAccess_Push()
	log("EventIsChoosingZoneAccess_Push, BP_IsChooingZoneAccess = "..tostring(BP_IsChooingZoneAccess));
end
--如果是非队长，这里实际走的是准备协议，美术把按钮做在了一起--
function EventStartMatch()
    log("点击开始匹配");
    if BP_IsChooingZoneAccess then
        OkStartMatchCallback();
    else
        textTitle = Client.GetTableData("LocalizeRes", "101001").TextValue; --提示--
        textMsg =  Client.GetTableData("LocalizeRes", "1011").TextValue; --当前所选服务器存在网络问题，会有较高延迟或无法匹配，建议选择其他服务器，是否继续？--
        CommonMessageBoxUI:ShowPanel(2, textTitle, textMsg, OkStartMatchCallback, CancelStartMatchCallback);
       -- CommonMessageBoxUI:ShowPanel(2, "提示", "当前所选服务器存在网络问题，会有较高延迟或无法匹配，建议选择其他服务器，是否继续？", OkStartMatchCallback, CancelStartMatchCallback);	
    end
end
function OkStartMatchCallback()
    log("ok, 开始匹配");
    	BP_IsMatchNoticeShowed = false;
    BattleResult.IgnoreDSError = false;
    LobbySystem.on_start_match_req();
end

function CancelStartMatchCallback()
    log("no, 取消匹配");
    LuaClassObj.HandleUIMessage(bp_teamup, "OpenExpandPanel");
end
    
--非队长的取消准备事件
function EventCancelReady()
	LobbySystem.change_status_req();
end

function MatchPopupUI.OnMatchCancel()
	log("OnMatchCancel InitMatchState");
	BP_PassedTime = 0;
	LuaClassObj.HandleUIMessage(bp_match, "InitMatchState");
end

--更新按钮的状态
function MatchPopupUI.UpdateState()
	log("UpdateState InitMatchState");
	BP_PlayerStatus = TeamUpSystem.GetMyStatus();
	BP_IsTeamLeader = TeamUpSystem.IsTeamLeader();

	if LobbySystem.isInMatch == false then
		LuaClassObj.HandleUIMessage(bp_match, "InitMatchState");
	end
end

function EventCancelMatch()
	LobbySystem.on_match_cancel_req();
end
--拉起界面后显示剩余时间
function MatchPopupUI.RefreshRemainTime(estimate_time)
	BP_Estimate_time = estimate_time;
	log("RefreshRemainTime RefreshMatchingInfo");
	LuaClassObj.HandleUIMessage(bp_match, "RefreshMatchingInfo");
end

function MatchPopupUI.ResetWhenReconnected(lTime)
	BP_PassedTime = lTime;
	LuaClassObj.HandleUIMessage(bp_match, "ResetWhenReconnected");
end

function EventShowMatchFailedNotice()
	--local title = "提示";
	--local content = "未找到玩家，是否继续匹配?";
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue	
    local content = Client.GetTableData("LocalizeRes", "301169").TextValue
	CommonMessageBoxUI:ShowPanel(2, title, content, MatchPopupUI.NoticeSureCallback, MatchPopupUI.NoticeCancelCallback);

	BP_IsMatchNoticeShowed = true;
end

function MatchPopupUI.NoticeSureCallback()
	log("继续等待匹配");
end

function MatchPopupUI.NoticeCancelCallback()
	log("超时取消匹配");
	LobbySystem.on_match_cancel_req();
end

function MatchPopupUI.ShowMatchSuccess()
	if BP_IsMatchNoticeShowed then
		LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIHide");
	end

	--若匹配成功，默认显示过了弹窗
	BP_IsMatchNoticeShowed = true;
	log("SetAsMatchSuccess");
	LuaClassObj.HandleUIMessage(bp_match, "SetAsMatchSuccess");
end

function MatchPopupUI.OnApplicationDeactive()
	-- body
	log("---切后台，匹配状态先不要切换--");
end

function MatchPopupUI.OnApplicationReactive()
	log("---match ui receive application reactive message---");

	if LobbySystem.isInMatch then
		log("---reset match waiting time when reactive---");
		MatchPopupUI.ResetWhenReconnected(NetUtil.GetCurServerTime() - LobbySystem.beginMatchTime);
	end

	if BP_MatchPopUI_CurLevel == "lobby" then
		--查询匹配状态只在大厅的时候去请求--
		LobbySystem.QueryMatchStatus();
	end
end

function MatchPopupUI:Release()
end
