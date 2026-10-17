CommonRightNotifyUI = CommonRightNotifyUI or
{
	isShowing = false,
	isLobby = false,
	listShowInfo = {},
}

BP_CommonRightNotify_Msg = "";

-- 注册面板

function bp_common_rightnotify_tips_panel_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_common_rightnotify_tips_panel,
		{{Path="/Game/UMG/UI_BP/Common/Lobby_ReservationTips_UIBP.Lobby_ReservationTips_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_COMMON_RIGHT_NOTIFY_ZORDER}},
		{"Lobby"},
		false,
		true,
		true
	);
end

function bp_common_rightnotify_tips_panel_OnModeSwitched(gamestatus)
	local status = string.lower(gamestatus);
	if "lobby" == status then
		CommonRightNotifyUI.isLobby = true;
		CommonRightNotifyUI.FirstDelayShow();
	elseif "login" == status then
		CommonRightNotifyUI.isShowing = false;
		CommonRightNotifyUI.isLobby = false;
		CommonRightNotifyUI.listShowInfo = {};
	else		
		CommonRightNotifyUI.isLobby = false;
	end
end

function EventFetchInfo()
    
end

function CommonRightNotifyUI.FirstDelayShow()
	if #CommonRightNotifyUI.listShowInfo > 0 then
		CommonRightNotifyUI.isShowing = true;
	
		LuaClassObj.HandleDynamicCreation(bp_common_rightnotify_tips_panel);			
		LuaClassObj.HandleUIMessage(bp_common_rightnotify_tips_panel, "EnterLobbyDelay");
	end	
end

function CommonRightNotifyUI.ShowNotify(str_msg, call_back)
	log("CommonRightNotifyUI show notify " .. str_msg);	
	
	local msg_notify = {};
	msg_notify.msg = str_msg;
	msg_notify.callBack = call_back;
	
	table.insert(CommonRightNotifyUI.listShowInfo, msg_notify);
	
	CommonRightNotifyUI.ShowNext();	
end

function CommonRightNotifyUI.ShowNext()
	if 0 == #CommonRightNotifyUI.listShowInfo then
		log("CommonRightNotifyUI empty show info ");
		return;
	end
	
	if (CommonRightNotifyUI.isShowing) or (false == CommonRightNotifyUI.isLobby) then
		log("CommonRightNotifyUI false show");
	else
		LuaClassObj.HandleDynamicCreation(bp_common_rightnotify_tips_panel);
		
		log("CommonRightNotifyUI show");
		local msg = CommonRightNotifyUI.listShowInfo[1];
		BP_CommonRightNotify_Msg = msg.msg;
		
		if nil ~= msg.callBack then
			msg.callBack();
		end
		
		table.remove(CommonRightNotifyUI.listShowInfo, 1);
		LuaClassObj.HandleUIMessage(bp_common_rightnotify_tips_panel, "ShowNotify");
	end		
end

function EventOnAfterShow()
	CommonRightNotifyUI.isShowing = true;
end

function EventOnAfterHide()
	CommonRightNotifyUI.isShowing = false;
	CommonRightNotifyUI.ShowNext();
end
