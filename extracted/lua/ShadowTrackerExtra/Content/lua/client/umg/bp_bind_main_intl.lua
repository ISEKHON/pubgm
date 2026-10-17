UIBindMainIntl = UIBindMainIntl or 
{

}

--提示框标题
BP_UIBindMainIntl_title ="bind";
--提示框内容
BP_UIBindMainIntl_msg = "bind";

--打开绑定页面的途径(1 设置界面;2创建角色界面)
--有些这两个界面进来有些提示会不同
BP_UIBindMainIntl_OpenWay=1;

--生成迁移码界面打开时，是否清空已有的迁移码
BP_UIBindMainIntl_ClearTransferCodeWhenShow=false;
--注册Widget
function bp_bind_main_intl_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_bind_main_intl,
		{{Path="/Game/UMG/UI_BP/Setting/UILayout/UIBindMain_Intl.UIBindMain_Intl_C", Container="Default", ZOrder=51}},
		{"CreateRole","Lobby"},
		false,
		bp_bind_main_intl_OnModeSwitched ~= nil,
		false
	);
end

function EventShowTip_Push()

end

function EventShowTipMsg()
	log("Bind Main EventShowTipMsg");
	--PopUpNoticeUI.ShowMessageBox(BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg);
	CommonMessageBoxUI:ShowPanel(1,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg);
end

function EventShowTransferSuccessTipMsg()
	log("Bind Main EventShowTransferSuccessTipMsg");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKTransferSuccess");
	end
	CommonMessageBoxUI:ShowPanel(1,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventShowSwitchAccountSuccessTipMsg()
	log("Bind Main EventShowSwitchAccountSuccessTipMsg");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKSwitchAccountSuccess");
	end
	CommonMessageBoxUI:ShowPanel(1,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventShowMsgAskStartNewGame()
	--开始新游戏时未绑定账号询问
	log("Bind Main EventShowMsgAskStartNewGame");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKAskStartNewGame");
	end
	CommonMessageBoxUI:ShowPanel(2,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventShowMsgAskSwitchAccountFB()
	--切换账号时未绑定账号询问
	log("Bind Main EventShowMsgAskSwitchAccountFB");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKAskSwitchAccountFB");
	end
	CommonMessageBoxUI:ShowPanel(2,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventShowMsgAskSwitchAccountGPGC()
	--切换账号时未绑定账号询问
	log("Bind Main EventShowMsgAskSwitchAccountGPGC");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKAskSwitchAccountGPGC");
	end
	CommonMessageBoxUI:ShowPanel(2,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventShowMsgAskUseTransferCode()
	--使用迁移码时未绑定账号询问
	log("Bind Main EventShowMsgAskUseTransferCode");
	local function clickOKCallback()
		LuaClassObj.HandleUIMessage(bp_bind_main_intl,"TipMsgButtonOKAskUseTransferCode");
	end
	CommonMessageBoxUI:ShowPanel(2,BP_UIBindMainIntl_title, BP_UIBindMainIntl_msg, clickOKCallback);
end

function EventLogOut()
	log("Bind Main EventLogOut");
	--EventHideMainUI();
	--SettingUI:Hide();
	--NetUtil.LogOut();
	log("...log out from settingUI...");       
	SettingUI:Hide();
	
	LoginSystem.sendLogout();
end

function EventShowMainUI()
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"UIShow");
end

function EventHideMainUI()
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"UIHide");
end

function EventShowSwitchAccountUI()
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"ShowSwitchAccountPanel");
end

function EventHideSwitchAccountUI()
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"HideSwitchAccountPanel");
end

function EventRegistIMSDKEvents()
	--log("Bind Main RegistIMSDKEvents");
	--EventSystem:registEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_NOTIFY,OnIMSDKNotify);
end

function EventUnRegistIMSDKEvents()
	--log("Bind Main UnRegistIMSDKEvents");
	--EventSystem:unregistEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_SWITCH_ACCOUNT_FB,OnSwitchAccountFB);
end

function OnIMSDKNotify(eventType, eventID, vars)
	log("Bind Main OnIMSDKNotify");

	if vars == 1 then
		OnRefreshedBindInfo();
	elseif vars == 2 then
		OnBindFB();
	elseif vars == 3 then
		OnBindGPGC();
	elseif vars == 4 then
		OnDeleteAccount();
	elseif vars == 5 then
		OnGenerateTransferCode();
	elseif vars == 6 then
		OnTransfer();
	elseif vars == 7 then
		OnSwitchAccountFB();
	elseif vars == 8 then
		OnSwitchAccountGPGC();
	end
end

function OnRefreshedBindInfo()
	log("Bind Main OnRefreshedBindInfo");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKRefreshedBindInfo");
end

function OnBindFB()
	log("Bind Main OnBindFB");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKBindFBCallBack");
end

function OnBindGPGC()
	log("Bind Main OnBindGPGC");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKBindGPGCCallBack");
end

function OnDeleteAccount()
	log("Bind Main OnDeleteAccount");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKDeleteAccountCallBack");
end

function OnGenerateTransferCode()
	log("Bind Main OnGenerateTransferCode");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKGenerateTransferCodeCallBack");
end

function OnTransfer()
	log("Bind Main OnTransfer");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKTransferCallBack");
end

function OnSwitchAccountFB()
	log("Bind Main OnSwitchAccountFB");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKSwitchAccountFBCallBack");
end

function OnSwitchAccountGPGC()
	log("Bind Main OnSwitchAccountGPGC");
	LuaClassObj.HandleUIMessage(bp_bind_main_intl,"OnIMSDKSwitchAccountGPGCCallBack");
end

function bp_bind_main_intl_OnModeSwitched(gamestatus)
	if string.lower(gamestatus) == "login" and LoginSystem.hasLogout then
		log("Bind Main OnModeSwitched login");
		EventHideMainUI();
    end
end