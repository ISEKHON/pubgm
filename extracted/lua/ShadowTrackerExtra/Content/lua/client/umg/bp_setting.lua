--设置界面

SettingUI = SettingUI or 
{
	
}

--设置界面区分大厅和游戏内--
BP_IsInLobby = false;
BP_IsInGame = false;
BP_CurSettingPage = 1;
BP_UrlStr1 = "http://game.qq.com/contract.shtml";
BP_UrlStr2 = "http://www.tencent.com/en-us/zc/privacypolicy.shtml";
BP_UrlStr3 = "http://www.tencent.com/en-us/zc/termsofservice.shtml";

--iTOP绑定事件
BP_Setting_IMSDKNotifyEvent=0;
--账号系统通用提示框确认按钮回调
BP_Setting_IMSDKTipMsgBtnOKEvent=0;

--登陆平台（微信，手Q）
BP_LoginChannel = 1;
BP_CanShowVideoSetting = true;

--注册widget
function bp_setting_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_setting,
    {{Path="/Game/UMG/UI_BP/Setting/Setting_UIBP.Setting_UIBP_C", Container="Default", ZOrder = 50}},
    {"Lobby", "Fighting"},
	true,
	bp_setting_OnModeSwitched ~= nil,
	true
  );
  
  if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_setting,
            "Setting_UIBP_C",
            {
                "Overlay_CustomerServiceFather",
            }
        );
    end
end


function bp_setting_OnModeAboutToSwitched(gamestatus)

end


--跳转到Lobby
function bp_setting_OnModeSwitched(gamestatus)
	if string.lower(gamestatus) == "lobby" then
		BP_IsInLobby = true;
	else
		BP_IsInLobby = false;
	end
	if string.lower(gamestatus) == "fighting" then
		BP_IsInGame = true;
	else
		BP_IsInGame = false;
	end

	log("bp_setting_OnModeSwitched"..BP_IsInGame);
	if string.lower(gamestatus) == "login" and LoginSystem.hasLogout then
        SettingUI:Hide()
    end
end

--通用的开关类按钮--
function EventClickSwitchButton()
	-- body
end

function EventFetchInfo()
	 
end

function SettingUI:Init()
	LuaClassObj.HandleDynamicCreation(bp_setting);
	
	BP_LoginChannel = Client.GetLoginChannel(NetInterface);

	if GlobalData:IsPlatformTourist() then
		BP_CanShowVideoSetting = false;
	end

	if GlobalData:IsIOSCheck() then
		BP_CanShowVideoSetting = false;
	end
	-- BP_CanShowVideoSetting = true;
	LuaClassObj.HandleUIMessage(bp_setting, "UIShow");
end

function EventHelpshiftShowConversation()
	log("helpshift show conversation");
	Client.HelpshiftShowConversion();
end

function EventHelpshiftSetRedPoints()
	Client.HelpshiftRequestUnreadMessagesCount();
	-- 上边是个异步调用，下一次调用本函数下边的值才会更新。不影响逻辑
	local count = Client.HelpshiftGetUnreadMessgesCount();
	if count ~= 0 then
		log("helpshift red on");
		LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_SETTING, true);
		LuaClassObj.HandleUIMessage(bp_setting, "TurnOnHelpRedPoint");
	else
		EventHelpshiftClearRedPoints();
	end
end

function EventHelpshiftClearRedPoints()
	log("helpshift red clear");
	Client.HelpshiftClearUnreadMessgesCount();
	LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_SETTING, false);
	LuaClassObj.HandleUIMessage(bp_setting, "TurnOffHelpRedPoint");
end


function EventShowBackToLobbyNotice()
	local function confirmClick()
		log("--游戏内,退出回到大厅 ---");
        BP_LoadingTo = 0
		LoadingUI:Init();
		SettingUI:Hide();
		--游戏中退出到大厅，请求退出游戏--
		NetUtil.SendPkg("giveup_enter_game");
		Client.ReturnToLobby(GameFrontendHUD);
	end

	CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "110140").TextValue, confirmClick);
end

function EventShowLogOutNoticce()
    local function LogOut()
        log("...log out from settingUI...");       
        SettingUI:Hide();
		
        LoginSystem.sendLogout();
    end

    CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "102012").TextValue, Client.GetTableData("LocalizeRes", "111019").TextValue, LogOut);
end

--确认更改画面品质的提示
function EventSettingConfirmModifyArtQuality_Push()
	log("---set art quality--");
	local content = Client.GetTableData("LocalizeRes", "116005").TextValue;
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, content);
end

--低配手机不能更改到高清画质提示
function EventSettingCannotSetHigherQuality_Push()
	log("---can not set art quality--");
	local content = Client.GetTableData("LocalizeRes", "116006").TextValue;
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, content);
end


function EventSettingCannotSetHigherFps_Push()
	PopUpNoticeUI:Init();
	--CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, "您的设备不能支持更高的帧率");
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "301182").TextValue);
end

function EventSettingShowConfirmModifyFps()
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "116007").TextValue);
end

function EventSettingNotSupportHDR()
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "116006").TextValue);
end

function EventSettingShowConfirmModifyHDR()
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "116008").TextValue);
end

--超高清画质未开放
function EventSettingNoticeHighestArtClosed()
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, Client.GetTableData("LocalizeRes", "116009").TextValue);
end

function SettingUI:Release()

end

function SettingUI:Hide()
	LuaClassObj.HandleUIMessage(bp_setting, "UIHide");
end

--local language = Client.GetCurrentLanguage(); // 待shuzhilu提交语言设置
--NetUtil.SendPkg("set_lang_req", language);

function SettingUI:Release()
end

function EventOpenKefuUrl()
	KefuSystem.OpenSettingKefuURL();
end

function EventTurnonMomentRecord()
	log("EventTurnonMomentRecord fail ,show notice")
	--打开精彩视频开关
	local str = DataMgr.GetMsgByID(890008);
	ShowNotice(str);
end

function EventTurnonManualRecord()
	log("EventTurnonManualRecord fail ,show notice")
	local str = DataMgr.GetMsgByID(890007);
	ShowNotice(str);
end

function EventShowMyRecordVideos()
	log("EventShowMyRecordVideos fail ,show notice")
	local str = DataMgr.GetMsgByID(890009);
	ShowNotice(str);
end

function EventShowWaitingUI()
	log("show");
	ConnectionWaitingUI:Show();
end

function EventHideWaitingUI()
	log("hide");
	ConnectionWaitingUI:Hide();
end

function EventSendLanguageSettingToServer()
	log("--上报语言设置---");
	local language = Client.GetCurrentLanguage();
	NetUtil.SendPkg("set_lang_req", language);
end

function EventShowLogOutNoticceForSettingLanguage()
    local function LogOut()        
		LuaClassObj.HandleUIMessage(bp_setting, "LogOutWhenSettingLanguage");
    end

    CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "102012").TextValue, Client.GetTableData("LocalizeRes", "4015").TextValue, LogOut);
end

function EventLogOutForSettingLanguage()
	log("...log out from setting language...");       
    SettingUI:Hide();
	LoginSystem.sendLogoutWithoutLogoutAccount();
end


--imsdk fb setting panel control
function EventSettingPanelRegistIMSDKEvents()
	log("Bind Main EventSettingPanelRegistIMSDKEvents");
	EventSystem:registEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_NOTIFY,OnSettingPanelIMSDKNotify);
end

function EventSettingPanelUnRegistIMSDKEvents()
	log("Bind Main EventSettingPanelUnRegistIMSDKEvents");
	EventSystem:unregistEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_NOTIFY,OnSettingPanelIMSDKNotify);
end

function EventSettingPanelShowConnectingUI()
	ConnectionWaitingUI:Show();
end

function EventSettingPanelHideConnectingUI()
	ConnectionWaitingUI:Hide();
end

function OnSettingPanelIMSDKNotify(eventType, eventID, vars)
	log("Bind Main OnSettingPanelIMSDKNotify");
	BP_Setting_IMSDKNotifyEvent = vars;

	--绑定FB事件
	if vars == 2 then
		EventSettingPanelHideConnectingUI();
	end

	LuaClassObj.HandleUIMessage(bp_setting,"OnSettingPanelIMSDKNotify");

end

--询问是否绑定FB
function EventSettingPanelAskBindAccountMsgBox()
	log("Bind Main ShowAskBindAccountMsgBox");
	local msgTitle = FuncUtil.GetLocalizeResStr("4039");
	local msgContent = FuncUtil.GetLocalizeResStr("4040");
	local function clickOKCallback()
		BP_Setting_IMSDKTipMsgBtnOKEvent = 1;
		LuaClassObj.HandleUIMessage(bp_setting,"IMSDKTipMsgButtonOKEvent");
	end
	CommonMessageBoxUI:ShowPanel(2,msgTitle, msgContent, clickOKCallback);
end

--绑定成功提示
function EventSettingPanelShowTipMsgBindFBSuccess()
	log("Bind Main EventSettingPanelShowTipMsgBindFBSuccess");
	local msgTitle = FuncUtil.GetLocalizeResStr("4039");
	local msgContent = FuncUtil.GetLocalizeResStr("4041");

	local function clickOKCallback()
		--重新登录
		SettingUI:Hide();
		LoginSystem.sendLogoutWithoutLogoutAccount();

	end
	CommonMessageBoxUI:ShowPanel(1,msgTitle, msgContent,clickOKCallback);
end

--绑定失败提示
function EventSettingPanelShowTipMsgBindFBFail()
	log("Bind Main EventSettingPanelShowTipMsgBindFBFail");
	local msgTitle = FuncUtil.GetLocalizeResStr("4039");
	local msgContent = FuncUtil.GetLocalizeResStr("4042");
	
	CommonMessageBoxUI:ShowPanel(1,msgTitle, msgContent);
end

--绑定失败，该账号已绑定其他角色，询问玩家是否返回登录界面
function EventSettingPanelAskAlreadyBindFB()
	log("Bind Main EventSettingPanelAskAlreadyBindFB");
	local msgTitle = FuncUtil.GetLocalizeResStr("4039");
	local msgContent = FuncUtil.GetLocalizeResStr("4043");
	local function clickOKCallback()
		--重新登录
		SettingUI:Hide();
		LoginSystem.sendLogout();
	end
	CommonMessageBoxUI:ShowPanel(2,msgTitle, msgContent, clickOKCallback);
end

--imsdk fb setting panel control end