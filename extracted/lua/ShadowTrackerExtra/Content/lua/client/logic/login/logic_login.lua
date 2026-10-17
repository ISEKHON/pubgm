
--[[
 登录相关逻辑
]]--

LoginSystem = LoginSystem or
{
	isConnectingGate = false;
	isConnectedGate = false;
	
	isConnectingLobby = false;
	isConnectedLobby = false;
	
	loginType = 0;
	
	-- 是否是重新登录
	isRelogin = false;
	
	-- 是否登录到大厅
	isInitLogin = false;
	
	-- 是否被踢
	hasKickOut = false;
	
	-- 是否登出
	hasLogout = false;
	
	-- 是排队进的游戏
	isInWaiting = false;
	-- 是否手Q游戏中心进入
	isFromQQGameCenter = false;
	
	-- 是否WX游戏中心进入
	isFromWXGameCenter = false;
	
	--是否直连服务器，否则选区选服
	isDirectConnect = true;
	--设置直连服务器，目前分游客、手Q、微信
	direct_login_server_list = {};
  
	loginLobbyInfo = {};
	
	wakeupinfo = nil;
	extendInfo = {};

	loginLobbyUrlArray = {};
	loginLobbyIndex = 0,
    
    --成长守护被踢10秒倒计时踢回登录界面
    kickoutCountdown = 0,
}

-- 以下地址只能打开一个，其他注释掉 --
--LoginSystem.direct_login_server_list = {channelInfo = "iGame", name = "iGame主干", addr = {"tcp://101.226.129.164:14001"}, status = 0, tab = 0};
--LoginSystem.direct_login_server_list = {channelInfo = "北美提审服", name = "北美提审服", addr = {"tcp://apple.igamecj.com:17500"}, status = 0, tab = 0};
--LoginSystem.direct_login_server_list = {channelInfo = "北美预发布", name = "北美预发布", addr = {"tcp://ig-us-pre.igamecj.com:17500"}, status = 0, tab = 0};
LoginSystem.direct_login_server_list = {channelInfo = "北美正式服", name = "北美正式服", addr = {"tcp://lobby.igamecj.com:17500", "tcp://49.51.43.31:17500"}, status = 0, tab = 0};



function LoginSystem.connectGateway(addrArray, addrID)
	if (addrArray == nil) or (#addrArray == 0) then
		return;
	end

	LoginSystem.loginLobbyUrlArray = addrArray;
	LoginSystem.loginLobbyIndex = 1;
	log("addrArray length: " .. #addrArray);

    --新的登录流程,不走网关,直接连大厅URL
    LoginSystem.loginLobbyInfo.Url = addrArray[1];
    LoginSystem.loginLobbyInfo.AddrID = addrID;
    LoginSystem.connectLobby();

--[[
	log("connectGateway = "..gate);
	 
	local function onConnected(eventType, eventID, vars)
		if eventType == EVENTTYPE_NETWORK and eventID == EVENTID_CONNECTED then
		
			local isConnected = vars[1];
			local reason  = vars[2];
			log("onConnected ".."reason = "..reason);

			LoginSystem.isConnectingGate = false;
			if isConnected then
				LoginSystem.isConnectedGate = true;
				
				LoginSystem.reqLobby();
				
				EventSystem:unregistEvent(EVENTTYPE_NETWORK, EVENTID_CONNECTED, onConnected);
			else
				log("connecting gate = "..gate.."failed for reason = "..reason);
			end
		end
	end
	EventSystem:registEvent(EVENTTYPE_NETWORK, EVENTID_CONNECTED, onConnected);


	NetUtil.ConnectToURL(gate);
	LoginSystem.isConnectingGate = true;
--]]
end

function LoginSystem.reconnectGateway()
	-- return true if have other option, by yarswang
	if(LoginSystem.loginLobbyIndex < #LoginSystem.loginLobbyUrlArray) then
		log("try reconnect");
		LoginSystem.loginLobbyIndex = LoginSystem.loginLobbyIndex + 1;
    	LoginSystem.loginLobbyInfo.Url = LoginSystem.loginLobbyUrlArray[LoginSystem.loginLobbyIndex];
    	LoginSystem.connectLobby();
		return true;
	end
	--or return false, by yarswang
	return false;
end

function LoginSystem.reqLobby()
	log("query lobby info--");
	LoginSystem.loginLobbyInfo.Ver = "1.0";
	NetUtil.SendPkg("query_lobby_info", LoginSystem.loginLobbyInfo.Ver);
end


function LoginSystem.connectLobby()
	local lobbyUrl = LoginSystem.loginLobbyInfo;
	log("lobby url = " .. LoginSystem.loginLobbyInfo.Url.."url id = ".. LoginSystem.loginLobbyInfo.AddrID);
	if not LoginSystem.loginLobbyInfo.Url or LoginSystem.loginLobbyInfo.Url == "" then
		return;
	end
		
	-- 停止游戏心跳，开启连接心跳
	NetUtil.connectionTick = true;
	NetUtil.gameTick = false;	

	-- 显示菊花
	ConnectionWaitingUI:Show();
	-- 记录时间
	NetUtil.SendTime = os.time();
	
	-- 发起连接
	NetUtil.ConnectToURL(LoginSystem.loginLobbyInfo.Url);
	Client.SetGameSrvID(GameFrontendHUD, LoginSystem.loginLobbyInfo.AddrID);
end

function LoginSystem.getStartUpType()
	local startup_type = BP_ENUM_STARTUPTYPE_COMM;
	if LoginSystem.isFromQQGameCenter then
		startup_type = BP_ENUM_STARTUPTYPE_QQGAME;
	elseif LoginSystem.isFromWXGameCenter then
		startup_type = BP_ENUM_STARTUPTYPE_WXGAME;
	end
	
	return startup_type;
end

function LoginSystem.reqLoginLobby(isRelogin)
	if LoginSystem.loginLobbyInfo == nil then
	log("LoginSystem.reqLoginLobby failed");
		return;
	end

	local ext_info = {
		--function c2s.login(ss, ver, device_info, startup_type, ext_info)
		--ext_info = {invite_info=sss, relogin=xxx, ...};
		relogin = isRelogin;
	}
	
	NetUtil.StartCheckLoginRsp();
	
	LoginSystem.isRelogin = isRelogin;
	
    local ver = Client.GetAppVersion();
	
    --local emulatorName = Client.GetEmulatorName();
    --log("LoginSystem.emulatorName = " .. emulatorName);

	local isEmulator = Client.IsEmulator();
	local device_type = isEmulator == true and 1 or 0;

	--local device_type = 0;
	
	log(string.format("LoginSystem send login %s, %s, %s", tostring(isRelogin), ver, device_type));
    --后台需要统计一些本地设备、系统信息
    DeviceOSInfo.getDeviceOSInfo();
	--启动来源要给后台
	local startup_type = LoginSystem.getStartUpType();
	local channelID = Client.GetInstallChannelID(NetInterface);
	local registerchannelID = Client.GetRegisterChannelID(NetInterface);
	log(string.format("reqLoginLobby channelID = %s, registerchannelID = %s", tostring(channelID), tostring(registerchannelID)));
    -- 初始化是否外发渠道
    local info = Client.GetTableData("ChannelInfo", tostring(channelID))
    if info and info.IsExternal == 1 then
        BP_IS_EXTERNAL_CHANNEL = true;
    else
        BP_IS_EXTERNAL_CHANNEL = false;
    end
    log(string.format("BP_IS_EXTERNAL_CHANNEL = %s", tostring(BP_IS_EXTERNAL_CHANNEL)))
	
	local currentTime = os.date("%Y-%m-%d %H:%M:%S", os.time());
	local timezone = Client.GetLocalTimezone();
    local language = Client.GetCurrentLanguage();
	NetUtil.SendPkg("login", ver, DeviceOSInfo.InfoList, startup_type, ext_info, device_type, channelID, registerchannelID, currentTime, language, timezone);--LoginSystem.loginLobbyInfo.Ver, LoginSystem.loginLobbyInfo.Key
end


function LoginSystem.OpenPGUrl()
    LuaClassObj.HandleUIMessage(bp_global, "OpenPGUrl");
end

function LoginSystem.banLoginOKCallback()
	LoginSystem.sendLogout();
	Client.OpenURL("https://game.qq.com/contract_en.shtml");
end

function LoginSystem.banLoginCancelCallback()
	LoginSystem.sendLogout();
    LuaClassObj.HandleUIMessage(bp_global, "ShowHelpshiftConversion");
end

function LoginSystem.on_login_failed(conn_idx, reason, banInfo, banTime)
	log("login_failed " .. conn_idx .. " " .. reason);
	-- 关闭登录重试逻辑
	NetUtil.StopCheckLoginRsp();
    
	LoginSystem.hasLogout = true;
	
	LoginSystem.isInitLogin = false;
	NetUtil.gameTick = false;
	NetUtil.connectionTick = false;
	
	-- 关闭连接
	NetUtil.Disconnect();
		
    ConnectionWaitingUI:Hide();
    
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue
    local text = Client.GetTableData("LocalizeRes", "101703").TextValue .. reason
    
    if (reason == "not-in-open-time") then
		-- 不在开放的时间
        text = Client.GetTableData("LocalizeRes", "101702").TextValue;
    elseif ( reason == "not-in-white-list") then
		-- 不在白名单
        --text = Client.GetTableData("LocalizeRes", "101704").TextValue;
        text = "尊敬的特种兵：\n        你暂未获得本次测试的体验资格，请留意官方最新公告。";
        textPG = Client.GetTableData("LocalizeRes", "110034").TextValue;
        CommonMessageBoxUI:ShowPanel(2, title, text, LoginSystem.OpenPGUrl, nil ,textPG, nil);
		--有登录态，需要刷新登录界面
		LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
		LuaClassObj.HandleUIMessage(bp_login, "UIHide");
        return
    elseif ( reason == "activation-code-not-exists" or reason == "need-activation-code") then
        --text = Client.GetTableData("LocalizeRes", "101704").TextValue;
        text = "尊敬的特种兵：\n        你暂未获得本次测试的体验资格，请留意官方最新公告。";
		textPG = Client.GetTableData("LocalizeRes", "110034").TextValue;
        CommonMessageBoxUI:ShowPanel(2, title, text, LoginSystem.OpenPGUrl, nil ,textPG, nil);
		--有登录态，需要刷新登录界面
		LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
		LuaClassObj.HandleUIMessage(bp_login, "UIHide");
    elseif ( reason == "ban-login") then
        local date = os.date("%Y-%m-%d %H:%M:%S", banTime);
        local textvalue = Client.GetTableData("LocalizeRes", "115007").TextValue;
        text = string.format(textvalue, banInfo.."\n", date)
		local btnOK = Client.GetTableData("LocalizeRes", "4003").TextValue;
		local btnCancel = Client.GetTableData("LocalizeRes", "4004").TextValue;
		CommonMessageBoxUI:ShowPanel(2, title, text, LoginSystem.banLoginCancelCallback, LoginSystem.banLoginOKCallback, btnCancel, btnOK)
        return;
    elseif ( reason == "aas_ban") then
        local timevalue = Client.GetTableData("LocalizeRes", "115005").TextValue;
        local date = os.date(timevalue, banTime);
        local textvalue = Client.GetTableData("LocalizeRes", "115011").TextValue;
        text = string.format(textvalue, date)
        CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin, nil);
        return;
    elseif ( reason == "low-version") then
        text = Client.GetTableData("LocalizeRes", "101706").TextValue;
        CommonMessageBoxUI:ShowPanel(1, title, text, QuitGame, nil);
        return;
    elseif ( reason == "low-version-diff") then
        text = Client.GetTableData("LocalizeRes", "101707").TextValue;
        CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin, nil);
        return;
    elseif ( reason == "not-same-device") then
		CommonMessageBoxUI:ShowPanel(1, title, "尊敬的特种兵： \n        首测期间每个账号仅可在同一台手机上登录，请更换首次注册手机后登录体验游戏。感谢你的理解和支持！", LoginSystem.backLogin, nil);
		return;
	elseif (reason == "register-exceed-limit") then
		CommonMessageBoxUI:ShowPanel(1, title, "尊敬的特种兵： \n        出生岛已达到今日的注册上限。为确保每位特种兵的完美体验，暂时关闭新的账号注册，开放时间请留意官方公告，感谢您的支持和理解！", LoginSystem.backLogin, nil);
		return;
	elseif (reason == "device-in-blacklist") then
		local function RefuseCallBack()
	        LuaClassObj.HandleUIMessage(bp_global, "quitGame");
	    end
		local tips = "尊敬的特种兵：\n        《绝地求生：刺激战场》为腾讯与PUBG联合出品，虚幻4引擎研发，致力于完美还原端游体验的正版手游。根据设备检测结果，此机型暂未支持，后续将开放更多机型适配，建议更换设备后运行游戏。感谢您的支持和理解！";;
        CommonMessageBoxUI:ShowPanel(1, "提示", tips, RefuseCallBack, RefuseCallBack);
		return;
    end
    
    --登录失败，要给一个强烈的提示
	CommonMessageBoxUI:ShowPanel(1, title, text);
end

function LoginSystem.EnterPlayerCreate()
	log("enter PlayerCreate");
    BP_InitPercent = 20
    BP_LoadingTo = 0
    LoadingUI:Init();
    --进入创建角色场景
    LuaClassObj.HandleUIMessage(bp_global, "EnterCreateRole");
end

function LoginSystem.on_sync_lobby_info(ret, addr, key, hotfix)
	sandbox.Log(Log, string.format("sync_lobby_info ret=%s ip=%s ,key = %s, hotfix=%s", ret, addr, key, hotfix));

	if ret == "ok" then
		LoginSystem.loginLobbyInfo =  
			{ 
				Url = addr,
				Key = key,
				Ver = ver,
				Hotfix = hotfix,
			}

		if (hotfix ~= nil and hotfix ~= "") then
			--dostring(hotfix)
		end
		
		log_tree("LoginSystem.loginLobbyInfo", LoginSystem.loginLobbyInfo);
		
		LoginSystem.connectLobby();
	else
		log("sync_lobby_info not ok:" .. ret);
	end
end

function LoginSystem.on_redirect(url)
    LoginSystem.loginLobbyInfo.Url = url;
    LoginSystem.connectLobby();
end

--成长守护等被踢10秒后回登录界面
function LoginSystem.kickoutCountdownTimerCallback()
    log("LoginSystem.kickoutCountdownTimerCallback" .. LoginSystem.kickoutCountdown);
    LoginSystem.kickoutCountdown = LoginSystem.kickoutCountdown + 1;
    if(LoginSystem.kickoutCountdown > 9) then
        LoginSystem.kickoutCountdown = 0;
    	CommonMessageBoxUI:HideAllMessageBox();
        LoginSystem.backLogin();
    end
end

-- 被踢响应
function LoginSystem.on_kickout(msg, banInfo, banTime)
    log("on_kickout " .. msg);
    LoginSystem.hasKickOut = true;
    
	-- 关闭连接
	NetUtil.Disconnect();
	
	-- 关闭菊花
	ConnectionWaitingUI:Hide();
	
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local text = Client.GetTableData("LocalizeRes", "111018").TextValue;
    if(msg == "not-in-open-time") then
        text = Client.GetTableData("LocalizeRes", "101702").TextValue;
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif (msg == "ban-login" or msg == "parents_ban") then
        --LoginSystem.sendLogout();
        if(banTime == -1) then
            CommonMessageBoxUI:ShowTimerPanel(1, title, banInfo, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        else
            local timevalue = Client.GetTableData("LocalizeRes", "115005").TextValue;
            local date = os.date(timevalue, banTime);
            local textvalue = Client.GetTableData("LocalizeRes", "115007").TextValue;
            text = string.format(textvalue, banInfo.."\n", date)
            CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.sendLogout, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        end
        return;
    elseif (msg == "idip-kick-out") then
        --LoginSystem.sendLogout();
        text = Client.GetTableData("LocalizeRes", "115006").TextValue;
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.sendLogout, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif (msg == "aas_once_force_rest") then
        --{reachTime=xxx,restTime=xxx}
        local a = banInfo.reachTime / 3600;
        local b = math.floor(banInfo.restTime / 60);
        local notice = Client.GetTableData("LocalizeRes", "115004").TextValue;
        text = string.format(notice, a, b)
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif (msg == "aas_acc_force_rest") then
        --{reachTime=xxx,restTime=xxx}
        local a = banInfo.reachTime / 3600;
        local b = math.floor(banInfo.restTime / 60);
        local notice = Client.GetTableData("LocalizeRes", "115004").TextValue;
        text = string.format(notice, a, b)
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif (msg == "aas_acc_ban") then
        --banInfo={endTime=xxx}
        local timevalue = Client.GetTableData("LocalizeRes", "115005").TextValue;
        local date = os.date(timevalue, banInfo.endTime);
        local textvalue = Client.GetTableData("LocalizeRes", "115011").TextValue;
        text = string.format(textvalue, date)
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif (msg == "aas_acc_curfew") then
        text = Client.GetTableData("LocalizeRes", "115010").TextValue;
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    elseif ( msg == "login-in-other-device") then
        CommonMessageBoxUI:ShowTimerPanel(1, title, text, LoginSystem.backLogin, nil, nil, nil, LoginSystem.kickoutCountdownTimerCallback);
        return;
    end
    CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin);
end

function LoginSystem.on_logout(msg)
	log("on_logout " .. msg);	
	
	-- 显示Loading
    BP_LoadingTo = 0
	LoadingUI:Init();
	
	LoginSystem.hasLogout = true;
	
	LoginSystem.isInitLogin = false;
	NetUtil.gameTick = false;
	NetUtil.connectionTick = false;
	
	-- 返回登录 关闭loading
	LoginSystem.backLogin();		
		
    Client.Logout(NetInterface);
	
	-- 关闭连接
	NetUtil.Disconnect();
end

function LoginSystem.sendLogin(loginType)	
	log("gavin LoginSystem.sendLogin "..tostring(loginType));
    
    ConnectionWaitingUI:Show();
    
	LoginSystem.hasLogout = false;
	LoginSystem.loginType = loginType;
	
	Client.Login(NetInterface, loginType);
end

function LoginSystem.sendLogout(reason)
	log("LoginSystem.sendLogout !!!!");
	DeviceOSInfo.getDeviceOSInfo();
	NetUtil.SendPkg("logout", DeviceOSInfo.InfoList);	
	
	-- 关闭连接返回登录
	LoginSystem.backLogin(reason);	
	
    Client.Logout(NetInterface);
end

function LoginSystem.sendLogoutWithoutLogoutAccount(reason)
	log("LoginSystem.sendLogoutWithoutLogoutAccount !!!!");
	DeviceOSInfo.getDeviceOSInfo();
	NetUtil.SendPkg("logout", DeviceOSInfo.InfoList);	
	
	-- 关闭连接返回登录
	LoginSystem.backLogin(reason);	
	
    --Client.Logout(NetInterface);
end

--返回到登入界面
--reason 1:异账号登陆
function LoginSystem.backLogin(reason)
    log("LoginSystem.backLogin");
    
    --各个系统要自己清理，界面要关闭
    EventSystem:postEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN);
	
    --跳转到登录
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_login));
	if curStatus ~= "login" then
		LuaClassObj.HandleUIMessage(bp_global, "EnterLogin");
	end
	
	if reason ~= 1 then
		LoginSystem.isFromQQGameCenter = false; 
		LoginSystem.isFromWXGameCenter = false;
	end
	
	LoginSystem.hasLogout = true;
	LoginSystem.isInitLogin = false;
	LoginSystem.hasKickOut = false;
	NetUtil.gameTick = false;
	NetUtil.connectionTick = false;
	
    --重新刷界面
    LuaClassObj.HandleUIMessage(bp_login, "UIHide");
	LuaClassObj.HandleUIMessage(bp_authorization, "hideAuthorizationUI");
	LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
    LuaClassObj.HandleUIMessage(bp_authorization, "showButtons");
	LuaClassObj.HandleUIMessage(bp_versionupdate, "Hide");
	
	-- 关闭菊花
	ConnectionWaitingUI:Hide();
	
	-- 关闭Loading
	LoadingUI.RefreshLoadPercent(1);
	
	-- 关闭所有提示框
	CommonMessageBoxUI:HideAllMessageBox();
	
	-- 关闭连接
	NetUtil.Disconnect();
end


function LoginSystem.enableLoginButton()
    LuaClassObj.HandleUIMessage(bp_login, "EnableLoginButton");
end

--快速登录，包括异帐号处理
--wakeupinfo见GCloudQuickLoginServiceObserver的OnWakeupNotify
function LoginSystem.OnQuickLogin(wakeupinfo)
	if wakeupinfo["roominfo"] ~= nil then
		log("QRCode OnQuickLogin")
		-- 房间的信息是单独的，在QuickLogin后到达
		local roominfo = wakeupinfo["roominfo"];
		local roompwpos = string.find(roominfo, "rmpw");
		local roomttpos = string.find(roominfo, "t:");
		
		if RoomSystem.QRCodeRoomInfo == nil then
			RoomSystem.QRCodeRoomInfo = {};
		end;
		
		RoomSystem.QRCodeRoomInfo.game_roomid = string.sub(roominfo, 6, roompwpos - 2);
		if roomttpos == nil then
			RoomSystem.QRCodeRoomInfo.game_roompw = string.sub(roominfo, roompwpos+5, -1);
			RoomSystem.QRCodeRoomInfo.game_roomtime = 0;
		else
			RoomSystem.QRCodeRoomInfo.game_roompw = string.sub(roominfo, roompwpos+5, roomttpos - 2);
			RoomSystem.QRCodeRoomInfo.game_roomtime = string.sub(roominfo, roomttpos+2, -1);
		end;
		
		local nNow = math.floor(os.time() / 60);
		local QRCodeTime = tonumber(RoomSystem.QRCodeRoomInfo.game_roomtime);
		if nNow > ( QRCodeTime + 360 ) then
			log("QRCode Expired");
			RoomSystem.QRCodeRoomInfo = nil;
			-- 二维码失效
			DataMgr.ShowNoticeByID(110131);
			return;
		end;
		
		ClientSendBAReport(BP_BA_SHARE_ROOMQRCODE, 0);  -- 扫二维码登录房间
		
		if wakeupinfo["roominfoImm"] ~= nil and wakeupinfo["roominfoImm"] == "true" then
			RoomUI.OnQuickJoinRoom(RoomSystem.QRCodeRoomInfo);
		end;
		return;
	end;
	local state = math.floor(tonumber(wakeupinfo["Base_State"]));
	log("state".. tostring(state));
	local platform = math.floor(tonumber(wakeupinfo["Base_Platform"]));
	log("platform".. tostring(platform));
	log_tree("wakeupinfo", wakeupinfo);
	LoginSystem.wakeupinfo = wakeupinfo;
	LoginSystem.CheckWakeupInfo();
	if state == 2 then
		--异帐号处理
		local toLoginPlatform = "";
		local currentLoginPlatform = "";
		if platform == BP_ENUM_PLAYFORM_WX then
			--toLoginPlatform = "微信";
			toLoginPlatform = Client.GetTableData("LocalizeRes", "101012").TextValue;
		elseif platform == BP_ENUM_PLAYFORM_QQ then
			--toLoginPlatform = "QQ";
			toLoginPlatform = Client.GetTableData("LocalizeRes", "301288").TextValue;
		end
		if BP_Platform == BP_ENUM_PLAYFORM_WX then
			--currentLoginPlatform = "微信";
			currentLoginPlatform = Client.GetTableData("LocalizeRes", "101012").TextValue;
		elseif BP_Platform == BP_ENUM_PLAYFORM_WX then
			--currentLoginPlatform = "QQ";
			currentLoginPlatform = Client.GetTableData("LocalizeRes", "301288").TextValue;
		end
		--local tip = string.format("此%s帐号与当前游戏登录的帐号不一致，是否切换帐号？", toLoginPlatform);
		local tip = string.format(Client.GetTableData("LocalizeRes", "301138").TextValue, toLoginPlatform);
		CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "301137").TextValue, tip, function()
			Client.SwitchUser(NetInterface, true);
			LoginSystem.sendLogout(1);
		end);
	end
end

function LoginSystem.on_notify_game_rest_remind(isAcc, reachTime)
    log("on_notify_game_rest_remind "..isAcc.." "..reachTime)
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local a = reachTime / 3600;
    if( isAcc == 1) then
        local notice = Client.GetTableData("LocalizeRes", "115001").TextValue;
        local text = string.format(notice, a);
        CommonMessageBoxUI:ShowPanel(1, title, text);
    else
        local notice = Client.GetTableData("LocalizeRes", "115002").TextValue;
        local text = string.format(notice, a);
        CommonMessageBoxUI:ShowPanel(1, title, text);
    end
end

function LoginSystem.on_notify_game_rest_force(isAcc, reachTime, restTime)
    log("on_notify_game_rest_force "..isAcc.." "..reachTime.." "..restTime)
    
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local a = reachTime / 3600;
    local b = math.floor(restTime / 60);
    
    if( isAcc == 1) then
        local notice = Client.GetTableData("LocalizeRes", "115003").TextValue;
        local text = string.format(notice, a, b)
        CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin);
    else
        local notice = Client.GetTableData("LocalizeRes", "115004").TextValue;
        local text = string.format(notice, a, b)
        CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin);
    end
end

function LoginSystem.on_notify_game_aas_ban(banEndTime)
    log("notify_game_aas_ban "..banEndTime)
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    local timevalue = Client.GetTableData("LocalizeRes", "115005").TextValue;
    local date = os.date(timevalue, banEndTime);
    local textvalue = Client.GetTableData("LocalizeRes", "115011").TextValue;
    local text = string.format(textvalue, date)
    CommonMessageBoxUI:ShowPanel(1, title, text, LoginSystem.backLogin);
end

function LoginSystem.CheckWakeupInfo()
	if LoginSystem.wakeupinfo == nil then
		log("CheckWakeupInfo:LoginSystem.wakeupinfo == nil");
		return;
	end

	local wakeupinfo = LoginSystem.wakeupinfo
	
	--登陆来源检查
	LoginSystem.isFromQQGameCenter = false; 
	if wakeupinfo["launchfrom"] ~= nil and wakeupinfo["launchfrom"] == "sq_gamecenter" then
		LoginSystem.isFromQQGameCenter = true;
	end
	
	LoginSystem.isFromWXGameCenter = false
	if wakeupinfo["Base_OpenId"] ~= nil and wakeupinfo["Base_OpenId"] ~= "" and wakeupinfo["Base_MessageExt"] == "WX_GameCenter" then
		LoginSystem.isFromWXGameCenter = true;
	end
	
	local platform = math.floor(tonumber(wakeupinfo["Base_Platform"]));
	local extinfo = nil;
	if platform == BP_ENUM_PLAYFORM_WX then
		log("CheckWakeupInfo:BP_ENUM_PLAYFORM_WX");
		if wakeupinfo["Base_MessageExt"] ~= nil and wakeupinfo["Base_MessageExt"] ~= "" then
			log("MessageExt" .. tostring(wakeupinfo["Base_MessageExt"]));
			extinfo = wakeupinfo["Base_MessageExt"];
		end
	elseif platform == BP_ENUM_PLAYFORM_QQ then
		log("CheckWakeupInfo:BP_ENUM_PLAYFORM_QQ");
		if wakeupinfo["gamedata"] ~= nil and wakeupinfo["gamedata"] ~= "" then
			log("gamedata" .. tostring(wakeupinfo["gamedata"]));
			extinfo = wakeupinfo["gamedata"];
		end
	end

	if extinfo ~= nil then
		local decodedstr = FuncUtil:DecodeURI(extinfo);
		local decodedXML = FuncUtil:DecodeXML(decodedstr);
		local gamedata = json.decode (decodedXML);
		--保存透传数据供外部使用
		LoginSystem.extendInfo = gamedata;
		LoginSystem.CheckWakeupDataForTeamup();
	else
		LoginSystem.extendInfo = {};
	end
	
	LoginSystem.wakeupinfo = nil;
end

-- 检查是否平台拉起组队
function LoginSystem.CheckWakeupDataForTeamup()
	local gamedata = LoginSystem.extendInfo;
	if string.lower(LuaClassObj.GetGameStatus(bp_lobby)) == "lobby" and gamedata ~= nil and type(gamedata) == "table" then 
		if gamedata.team_roleid ~= nil and gamedata.team_teamid ~= nil then
			TeamUpSystem.JoinTeamByChat(tonumber(gamedata.team_roleid), tonumber(gamedata.team_teamid), "plat-invite");
		end
		LoginSystem.extendInfo = {};
	end
end

--收到服务器3秒重连问题
function LoginSystem.on_login_next(msg)   
	log("on_login_next"); 
	ConnectionWaitingUI:Show();
	if (msg == "Please try after 3 second") then
		log("Timer.InsertTimer(3, LoginSystem.OnLoginNextCallBack, false)");
		Timer.InsertTimer(3, LoginSystem.OnLoginNextCallBack, false);
	end
end

--3秒结束后，重连
function LoginSystem.OnLoginNextCallBack()
	log("LoginSystem.OnLoginNextCallBack");
	ConnectionWaitingUI:Hide();
	if (LoginSystem.isInitLogin == false) then
		log("LoginSystem.reqLoginLobby(false)");
		LoginSystem.reqLoginLobby(false);
	end
end

--[[网络回调]]--
s2c["login_failed"] = LoginSystem.on_login_failed;
s2c["sync_lobby_info"] = LoginSystem.on_sync_lobby_info;
s2c["redirect"] = LoginSystem.on_redirect;

s2c["kickout"] = LoginSystem.on_kickout;
s2c["logout_rsp"] = LoginSystem.on_logout;

s2c["notify_game_rest_remind"] = LoginSystem.on_notify_game_rest_remind;
s2c["notify_game_rest_force"] = LoginSystem.on_notify_game_rest_force;
s2c["notify_game_aas_ban"] = LoginSystem.on_notify_game_aas_ban;

s2c["login_next"] = LoginSystem.on_login_next;

--[[
连接后,客户端发送: c2s.login(ver), 其中ver是客户端版本号,
如果登录异常,会返回消息: s2c.login_failed(reason),可能的原因有角色被冻结之类的.
另外,也可能会返回消息要求客户端重定向到别的服务器,比如: s2c.redirect(url), 如果收到此消息,客户端应该断开连接,到指定的url重连登录.
成功则继续往下.
--]]
