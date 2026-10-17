AuthorizationUI = AuthorizationUI or 
{
    --是否增加登录失败数次,手动点击的才能加，第一次自动鉴权不加
    addLoginTryCount = 0;
}

--第一次登录自动鉴权
BP_AutoAuthLogin = 1;
--输入用户名
BP_QQID = ""
BP_QQPasswd = ""
BP_GameVersion = ""
--微信是否安装，如果没有安卓，微信登录按钮需隐藏
BP_WECHAT_INSTALL = 0
--登录尝试次数
BP_LoginCount = 0;
--记录开始登录的时间
BP_LoginTime = 0;
--登录限制检查结果
BP_LoginCheck = 0;
--当前鉴权TOKEN有效性
BP_TokenIsValid = 0;

BP_DeviceNameBeforeAuthLogin = "";

BP_DeviceLimit = 0; -- -1: refuse, 0: tips, 1: normal

HasShowDeviceLimit = false;

--注册Widget
function bp_authorization_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_authorization,
		{
			{Path="/Game/UMG/UI_BP/Login/Authorization_BP.Authorization_BP_C", Container="Default", ZOrder=0},
            {Path="/Game/UMG/UI_BP/Login/Login_SplashScreen.Login_SplashScreen_C", Container="Default", ZOrder=0}
		},
		{"Update", "Login"},
		false,
		false
	);
    
    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_authorization,
        "Authorization_BP_C",
		{
			"Button_2",
            "Button_0",
            "Button_Help",
            "Button_Repair",
            "btnHelpLogin",
		}
	);
    end
end

function EventFetchInfo()
	
end

--开始鉴权流程
function EventStartAuthorization()
	log("start authorization");
    
    EventLoginCheck();
    if(BP_LoginCheck == 1) then
        return;
    end
    		
	if BP_QQID ~= "" and BP_QQPasswd ~= "" then
		Client.InitLoginAccount(NetInterface, tonumber(BP_QQID), BP_QQPasswd); 	
		LoginSystem.sendLogin(2);
	else
		LoginSystem.sendLogin(6);
	end		
end

--游客模式
function EventGuestLogin()
	log("EventGuestLogin");
    
    AuthorizationUI.addLoginTryCount = 1;
    EventLoginCheck();
    if(BP_LoginCheck == 1) then
        return;
    end
	
	LoginSystem.sendLogin(5);
end

--QQ登录
function EventQQLogin()
	log("EventQQLogin");	
    
    AuthorizationUI.addLoginTryCount = 1;
    EventLoginCheck();
    if(BP_LoginCheck == 1) then
        return;
    end
	
	LoginSystem.sendLogin(2);
end

--WX登录
function EventWXLogin()
	log("EventWXLogin");
    
    AuthorizationUI.addLoginTryCount = 1;
    EventLoginCheck();
    if(BP_LoginCheck == 1) then
        return;
    end
	
	--如果没有安装微信，则认为是微信扫码登录
	if Client.IsInstallWX(NetInterface) then
        LoginSystem.sendLogin(1);
    else
        LoginSystem.sendLogin(8);
    end
end

--强退游戏
function QuitGame()
	log("QuitGame");
    LuaClassObj.HandleUIMessage(bp_global, "quitGame");
end

--自动登录前做一些事情
--目前流程：更新-》内存提示-》停服公告-》登录前公告-》自动登录
function EventBeforeAuthLogin()
	local function doNext()
		local platName = Client.GetDevicePlatformName();
		if platName ~= "Windows" then
			LuaClassObj.HandleUIMessage(bp_notice_intl, "TryShowMaintenanceIMSDKNotice");
		else
			LuaClassObj.HandleUIMessage(bp_authorization, "doAutoLogin");
		end
	end
	local memoryStaus = Client.GetMemoryStats();
	local availablePhysical = memoryStaus.AvailablePhysical / 1048576;
	if availablePhysical == 0 or availablePhysical > 100 then
		--内存足够，进行下一步操作
		doNext();
	else
		--内存不足，弹出提示，之后进行下一步操作
		local tip = "";
		local msgConfig = Client.GetTableData("LocalizeRes", 101014);
		if msgConfig then
			tip = msgConfig.TextValue;
		end
        local tipTitle = Client.GetTableData("LocalizeRes", "101001").TextValue;
		CommonMessageBoxUI:ShowPanel(1, tipTitle, tip, doNext, doNext);
	end
	log("availablePhysical：" .. tostring(availablePhysical));
end

function EventAutoAuthLogin()
	log("EventAutoAuthLogin"..BP_AutoAuthLogin);
    --只有第一次自动鉴权
    BP_AutoAuthLogin = 0;
end


--展示许可服务
function EventShowService()
	log("EventShowService");    
    --local language = Client.GetCurrentLanguage();
    --log("EventShowService: " .. language);    
    PopUpNoticeUI.ShowMessageBox(LongTxt.service_title_en, LongTxt.service_content_en);
    --[[
    if(language == "zh") then     
        PopUpNoticeUI.ShowMessageBox(LongTxt.service_title, LongTxt.service_content);
    else
        PopUpNoticeUI.ShowMessageBox(LongTxt.service_title_en, LongTxt.service_content_en);
    end
    ]]
end

--展示隐私服务
function EventShowPrivacyAgreement()
	log("EventShowPrivacyAgreement");    
    --local language = Client.GetCurrentLanguage();
    --log("EventShowPrivacyAgreement: " .. language);    
    PopUpNoticeUI.ShowMessageBox(LongTxt.PrivacyAgreement_title_en, LongTxt.PrivacyAgreement_content_en);
end

--展示拒绝用户协议
function EventShowRefuse()
	log("EventShowRefuse");
	local msg1 = Client.GetTableData("LocalizeRes", "101001");
	local msg2 = Client.GetTableData("LocalizeRes", "101008");
    CommonMessageBoxUI:ShowPanel(2, msg1.TextValue, msg2.TextValue, QuitGame, nil)
end

--展示游客数据提示
function EventShowTouristNotice()
	log("EventShowTouristNotice");
	--local msg1 = Client.GetTableData("LocalizeRes", "101001");
	--local msg2 = Client.GetTableData("LocalizeRes", "101009");
    --CommonMessageBoxUI:ShowPanel(2, msg1.TextValue, msg2.TextValue, EventGuestLogin, nil)
	EventGuestLogin();
end

function EventCheckWeChatInstalled()
    if Client.IsInstallWX(NetInterface) then
        BP_WECHAT_INSTALL = 1;
    else
        BP_WECHAT_INSTALL = 0;
    end
end

--获得界面版本号和TOKEN有效性
function EventGameVersion()
	log("EventGameVersion");
    BP_GameVersion = Client.GetAppVersion();
    log("EventGameVersion"..tostring(BP_GameVersion));
    if(Client.GetLoginChannel(NetInterface) == 0) then
        BP_TokenIsValid = 0;
    else
        BP_TokenIsValid = 1;
    end
    
	log("TokenIsValid:"..BP_TokenIsValid);
end

function EventAuthShowButtons()
	log("EventAuthShowButtons");
    ConnectionWaitingUI:Hide();
end

function EventAuthHideButtons()
	log("EventAuthHideButtons");
    ConnectionWaitingUI:Show();
end

function AuthorizationUI.GetTime()
    local curTime = os.time();
    local remainTime = math.abs(BP_LoginTime - curTime);
    local min = math.floor(remainTime / 60);
    local sec = remainTime % 60;
    --local text = string.format("登录过于频繁，请%d分%d秒后再尝试！", min, sec);
    local text = string.format(Client.GetTableData("LocalizeRes", "301162").TextValue, min, sec);
    if(min == 0) then
        --text = string.format("登录过于频繁，请%d秒后再尝试！", sec);
        text = string.format(Client.GetTableData("LocalizeRes", "301163").TextValue, sec);
    end
    return curTime, text
end

function EventRedoAutoAuthorization()
	log("EventRedoAutoAuthorization");
    
    local function RedoAutoAuthorization()
        log("RedoAutoAuthorization");
        LuaClassObj.HandleUIMessage(bp_authorization, "showButtons");
    end
    
    local curTime,text = AuthorizationUI.GetTime()
    
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local msg = Client.GetTableData("LocalizeRes", "103015").TextValue;
    
    if (BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT2 and curTime < BP_LoginTime) then
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, RedoAutoAuthorization, nil,nil,nil,AuthorizationUI.TimerInvoke1);
    elseif (BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT1 and curTime < BP_LoginTime ) then
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, RedoAutoAuthorization, nil,nil,nil,AuthorizationUI.TimerInvoke2);
    else
        CommonMessageBoxUI:ShowPanel(1, title, msg, RedoAutoAuthorization);
    end
end

function EventUpdateLoginTime()
    if( AuthorizationUI.addLoginTryCount == 1) then
        if(BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT2) then
            BP_LoginTime = os.time() + BP_ENUM_LOGINLIMIT_TIME2;
        elseif ( BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT1) then
            BP_LoginTime = os.time() + BP_ENUM_LOGINLIMIT_TIME1;
        end
    end
end

function EventAddLoginCount()
    log("EventAddLoginCount "..AuthorizationUI.addLoginTryCount);
    
    if( AuthorizationUI.addLoginTryCount == 1) then
        BP_LoginCount = BP_LoginCount + 1;
    end
end

function EventClearLoginLimit()
    log("EventClearLoginLimit")
    BP_LoginCount = 0;
    BP_LoginTime = 0;
end

function EventLoginCheck()
    log("EventLoginCheck"..os.time().." " .. BP_LoginTime)
    
    local curTime, text = AuthorizationUI.GetTime()
    if(curTime > BP_LoginTime) then
        log("EventLoginCheck "..curTime..":" .. BP_LoginTime)
        BP_LoginCheck = 0;
        return;
    end
    
    local function RedoAutoAuthorization()
        log("RedoAutoAuthorization");
        LuaClassObj.HandleUIMessage(bp_authorization, "showButtons");
    end
    
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    if (BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT2) then
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, RedoAutoAuthorization, nil,nil,nil,AuthorizationUI.TimerInvoke1);
        BP_LoginCheck = 1;
        return;
    elseif (BP_LoginCount > BP_ENUM_LOGINLIMIT_COUNT1) then
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, RedoAutoAuthorization, nil,nil,nil,AuthorizationUI.TimerInvoke2);
        BP_LoginCheck = 1;
        return;
    end
end

function AuthorizationUI.TimerInvoke1()
    local curTime, text = AuthorizationUI.GetTime()
    if(curTime > BP_LoginTime) then
        CommonMessageBoxUI:HidePanel();
        return;
    end
    CommonMessageBoxUI:UpdateMsg(text)
end

function AuthorizationUI.TimerInvoke2()
    local curTime, text = AuthorizationUI.GetTime()
    if(curTime > BP_LoginTime) then
        CommonMessageBoxUI:HidePanel();
        return;
    end
    CommonMessageBoxUI:UpdateMsg(text)
end


--注销帐号
function EventLogout()
	log("EventLogout");
	Client.Logout(NetInterface);
end

function EventClickKefu()
    KefuSystem.OpenLoginKefuURL();
end

function EventDeleteSavedDir()
    log("EventDeleteSavedDir")
    
    local function Exit()
        Client.ExitGame();
    end
    
	local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local msg = Client.GetTableData("LocalizeRes", "101714").TextValue;
	CommonMessageBoxUI:ShowPanel(1, title, msg, Exit);
end

-- 打开语言设置
function EventEnterLanguageSetting()
    log("enter language setting ui");
    SettingLanguageUI.ShowUIInLoginPanel();
end
