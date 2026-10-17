--加载界面
ConnectionWaitingUI = ConnectionWaitingUI or 
{
	curTime = 0,
	isShowing = false,
}


--注册widget
function bp_connection_waiting_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_connection_waiting,
    {{Path="/Game/UMG/UI_Logic/Reconnect/Reconnect_BP.Reconnect_BP_C", Container="Top", ZOrder=BP_ENUM_UI_RECONNECT_WAITING_ZORDER}},
    {"Lobby","Login","Fighting","CreateRole", "Pending"},
	true,
	false,
	true
  );
end

-- 打开面板
function ConnectionWaitingUI:Show()
	LuaClassObj.HandleDynamicCreation(bp_connection_waiting);
	
	log("gavin ConnectionWaitingUI:Show()");
	
	ConnectionWaitingUI.isShowing = true;	
	LuaClassObj.HandleUIMessage(bp_connection_waiting, "UIShow");	
end

function ConnectionWaitingUI:ShowConnect()
	LuaClassObj.HandleDynamicCreation(bp_connection_waiting);
	
	ConnectionWaitingUI.isShowing = true;	
	LuaClassObj.HandleUIMessage(bp_connection_waiting, "UIShow");	
end

-- 关闭面板
function ConnectionWaitingUI:Hide()
	log("gavin ConnectionWaitingUI:Hide()");
	ConnectionWaitingUI.isShowing = false;	
	LuaClassObj.HandleUIMessage(bp_connection_waiting, "UIHide");	
end