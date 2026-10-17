_G.s2c = s2c or {};
_G.UnrealNet = UnrealNet or {};

_G.NetUtil = NetUtil or 
{
	s2cNeedWaiting = {},	
};

-- tables exported from C++
_G.Net = _G.ScriptHelperNetInterface;
_G.Client = _G.ScriptHelperClient;

-- object pointers exported from C++
--[[
	LuaStateWrapper
	NetInterface
	GameFrontendHUD
--]]


NetUtil.SendTime = NetUtil.SendTime or 0;
NetUtil.RecvTime = NetUtil.RecvTime or 0;

NetUtil.LobbyDelaySendTime = NetUtil.LobbyDelaySendTime or 0;
NetUtil.LobbyDelayRecvTime = NetUtil.LobbyDelayRecvTime or 0;

-- 重要请求发起时间
NetUtil.c2sTime = NetUtil.c2sTime or 0;
-- 断线重连，网络重接中tick激活标签
NetUtil.connectionTick = NetUtil.connectionTick or false;
-- 断线重连，游戏中tick激活标签
NetUtil.gameTick = NetUtil.gameTick or false;
-- 断线重连msgbox提示计数
NetUtil.showConnectionMsgTimes = NetUtil.showConnectionMsgTimes or 0;

-- 网络异常的时候尝试重连一次
NetUtil.hasTryConnectForNetworkError = NetUtil.hasTryConnectForNetworkError or false;

-- 进入战斗loading中重连等待re_enter_game
-- 在战斗中重连回来等待re_enter_game
NetUtil.checkWaitingReEnterGameNotify = NetUtil.checkWaitingReEnterGameNotify or false;
NetUtil.waitingReEnterGameStartTime = NetUtil.waitingReEnterGameStartTime or 0;

-- 战斗中大厅服务器断开后 静默重连设置
NetUtil.checkConnectingInFighting = false;
NetUtil.waitingConnectSuccessStartTime = NetUtil.waitingConnectSuccessStartTime or 0;

-- 重登陆login重发机制
NetUtil.checkLoginRsp = NetUtil.checkLoginRsp or false;
NetUtil.checkLoginRetryTime = NetUtil.checkLoginRetryTime or 0;
NetUtil.sendLoginTime = NetUtil.sendLoginTime or 0;

-- ds服务器超时重试次数
NetUtil.dsTimeOutRetryTimes = NetUtil.dsTimeOutRetryTimes or 0;

NetUtil.CurTickTime = NetUtil.CurTickTime or 0;
NetUtil.LastTickTime = NetUtil.LastTickTime or 0;
-- global tick for lua, maybe an event should be post here
function Tick(DeltaTime)
	Timer.Tick(DeltaTime)
	NetUtil.CurTickTime = NetUtil.CurTickTime + DeltaTime;
	FuncUtil.LocalTimeTick = FuncUtil.LocalTimeTick + DeltaTime;
	if NetUtil.CurTickTime - NetUtil.LastTickTime > 5 then
		log("gavin Tick Time ".. NetUtil.CurTickTime..", gameTick:"..tostring(NetUtil.gameTick)..", connectionTick:"..tostring(NetUtil.connectionTick)..", c2sTime:"..NetUtil.c2sTime..", os.clock:"..os.time()..", SendTime:"..NetUtil.SendTime..", kickout:"..tostring(LoginSystem.hasKickOut));
		NetUtil.LastTickTime = NetUtil.CurTickTime;
	end

	NetUtil.CheckTime();
	
    NetUtil.OnTick(os.time(), DeltaTime);	
	--log("test screen log",true);
	
	LobbyChatLogic.Tick();
end



-- 服务器回包
function NetUtil.DispatchPacket(msg, ... )
    --log("NetUtil.DispatchPacket:" .. msg);
	local proc = s2c[msg];
	if not proc then
        log(string.format("undefined msg: %s", msg));
		--log_err("undefined msg: %s", msg);
		return;
	end
	
	for i,v in ipairs(NetUtil.s2cNeedWaiting) do
		if v.callback == msg then
			table.remove(NetUtil.s2cNeedWaiting, i);
			
			if #NetUtil.s2cNeedWaiting == 0 then
				ConnectionWaitingUI:Hide();
				NetUtil.c2sTime = 0;
				log("NetUtil.DispatchPacket  hide  ConnectWaitingUI");
			else
				-- 更新sendTime
				NetUtil.c2sTime = NetUtil.s2cNeedWaiting[1].sendTime;
				log("NetUtil.DispatchPacket change c2sTime:"..NetUtil.c2sTime);
			end			
			break;
		end
	end
		
	xpcall(proc, function(msg) log(msg) log(debug.traceback()) end, ...);
	-- if not ok then
	-- 	log(string.format("failed to call msg: %s, %s", msg, err));
	-- 	log(..debug.traceback())
 --        --log_err("failed to call msg: %s", msg);
	-- 	--log_err(err);
	-- end
end

function NetUtil.SendTss()
	TssManager.SendSkdData(Tss, LuaStateWrapper, NetInterface, "on_recv_client_data");
end

--tss回包
function NetUtil.OnTssRsp(datalen, data)
	TssManager.OnRecvData(Tss, datalen, data);
end

function NetUtil.SendPkg(...)
	local arg={...};
	log("NetUtil.SendPkg: "..arg[1]);
	
	if Client.IsConnected(NetInterface) then
		Net.SendPacket(LuaStateWrapper, NetInterface, ...);
	else
		log("gavin connection is failed throw pkg "..arg[1]);
	end
end


function NetUtil.SendPriorityPkg(needTryConnect, callback, ...)	
	local arg={...};
	
	if not Client.IsConnected(NetInterface) then
		log("gavin connection is failed throw pkg 2 "..arg[1]);
		return;
	end

	local isFind = false;
	for i,v in ipairs(NetUtil.s2cNeedWaiting) do
		if v == callback then
			-- 一个响应只储存一份
			isFind = true;	
			break;
		end
	end
	if not isFind then		
		table.insert(NetUtil.s2cNeedWaiting,
			{needTryConnect = needTryConnect, 
			callback = callback,
			sendPkg = arg[1],
			sendTime = os.time()});
	end
		
	ConnectionWaitingUI:Show();
	
	if NetUtil.c2sTime == 0 then
		NetUtil.c2sTime = os.time();
	end
	
	NetUtil.SendPkg(...);
end

function NetUtil.ConnectToURL(ip)
	log("NetUtil.ConnectToURL "..ip..", time"..tostring(os.time()),true);
    Client.ConnectToURL(NetInterface, ip);
end

function NetUtil.Disconnect()
	log("NetUtil.Disconnect()",true);
	Client.Disconnect(NetInterface);
end

function NetUtil.EnterBattle(ip, port, key, name, packet_key, game_id)
	log("NetUtil.EnterBattle()",true);
    Client.EnterBattle(GameFrontendHUD, ip, port, key, name, packet_key, game_id)
end

function NetUtil.OnConnected(isConnected, nReason)
	-- 获取当前游戏阶段
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));	
	log("gavin NetUtil.OnConnected "..tostring(isConnected)..", nReason: "..nReason..", isInitLogin:"..tostring(LoginSystem.isInitLogin),true);
	
	--登陆阶段连接超时后，先尝试其它可能, by yarswang
	if(isConnected == false and curStatus == "login" and (nReason == GCLOULD_ErrorTimeout or nReason == GCLOULD_ErrorConnectFailed)) then
		if(LoginSystem.reconnectGateway()) then
			log("gavin LoginSystem.reconnectGateway()")
			return;
		end
	end

	--[[
	kSuccess = 0,
	kErrorInnerError = 1,
	kErrorNetworkException = 2,
	kErrorTimeout = 3,
	kErrorInvalidArgument = 4,
	kErrorLengthError = 5,
	kErrorUnknown = 6,
	kErrorEmpty = 7,
	kErrorNotInitialized = 9,
	kErrorNotSupported = 10,
	kErrorNotInstalled = 11,
	kErrorSystemError = 12,
	kErrorNoPermission = 13,
	]]--
	
	-- 关闭菊花				
	ConnectionWaitingUI:Hide();
	
	if isConnected then						
		-- 异常重连成功 重置状态
		NetUtil.hasTryConnectForNetworkError = false;	
		
        -- 排队的进的游戏需关闭下面板
        if (LoginSystem.isInWaiting) then
			log("is in LoginSystem.isInWaiting");
            CommonMessageBoxUI:HideAllMessageBox();
        end
		
		-- 关闭连接异常的消息面板
		if CommonMessageBoxUI.isShowing and CommonMessageBoxUI.isConnectionPanel then
			log("Close ConnectionMessageBoxUI!!!!");
			CommonMessageBoxUI:HideConnectionPanel();
		end
				
		if LoginSystem.hasKickOut then
			-- 当前处理被踢状态 则不进行重连
			
			NetUtil.gameTick = false;
			NetUtil.connectionTick = false;
		else
			-- 连接成功发起login
			LoginSystem.reqLoginLobby(LoginSystem.isInitLogin);
			
			-- 停止连接心跳，开启游戏心跳
			NetUtil.connectionTick = false;
			NetUtil.gameTick = true;
						
		end
			
		-- 归零弹出提示次数
		NetUtil.showConnectionMsgTimes = 0;
		HeartBeatServerTime = NetUtil.GetCurServerTime(); -- 更新服务器时间
		NetUtil.SendTime = os.time(); 
		NetUtil.RecvTime = os.time(); 
		NetUtil.LobbyDelaySendTime = os.clock();
        NetUtil.LobbyDelayRecvTime = os.clock();
		
		-- 清空
		NetUtil.c2sTime = 0; 
		NetUtil.s2cNeedWaiting = {};
		
		-- 设置连接检查
		NetUtil.checkConnectingInFighting = false;
		
		BP_LobbyNetworkStatus = true;
		LobbyUI:UpdateNetworkDelay();
		
		EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_SUCCESS);
	else
		log("--- OnConnected Failed curStatus = "..curStatus..", url = "..LoginSystem.loginLobbyInfo.Url.." for reason = "..nReason,true);
		
		EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_FAILED);
				
		if LoginSystem.hasKickOut or LoginSystem.hasLogout then
			-- 如果当前处于被踢状态 不做连接异常处理
			log("--- tryConnectLobby failed is in kickout or logout state! hasKickOut:"..tostring(LoginSystem.hasKickOut)..", hasLogout:"..tostring(LoginSystem.hasLogout));
			NetUtil.connectionTick = false;
			NetUtil.gameTick = false;
			return;
		end
		
		local errorMsg = FuncUtil:GetGCloudErrorMsg(nReason);
		
		-- 设置连接状态
		if curStatus == "fighting" then
			-- 战斗中不弹出任何大厅连接异常的提示
			-- 开启定时重连
			if not NetUtil.checkConnectingInFighting then
				-- 开启静默连接等待大厅连接成功
				NetUtil.checkConnectingInFighting = true;
				NetUtil.waitingConnectSuccessStartTime = os.time();
				log("gavin waitingConnectSuccessStartTime:"..NetUtil.waitingConnectSuccessStartTime);	
			end
			log("OnConnected Failed is in fighting return!!!! ");			
		else
			-- 其他阶段
			if nReason == -1 
				or nReason == GCLOULD_ErrorNetworkException
				or nReason == GCLOULD_ErrorTimeout
				or nReason == GCLOULD_ErrorChecking
				or nReason == GCLOULD_ErrorConnectFailed then
				
				-- 连接失败，需要提示尝试重连
				if not NetUtil.hasTryConnectForNetworkError then
					log("--- After Connect Failed For Newwork Try Connect One Time......");
					NetUtil.hasTryConnectForNetworkError = true;
					NetUtil.tryConnect();
				else
					-- 连接失败，等待连接心跳超时
					log("--- Show ConnectingErrorMsg ......");
					NetUtil.showConnectionMsgTimes = NetUtil.showConnectionMsgTimes + 1;
					NetUtil.ShowConnectionMsgBox(NetUtil.showConnectionMsgTimes, errorMsg);	
				end			
			
			else
				-- 连接失败  关闭模态菊花
				NetUtil.connectionTick = false;
				NetUtil.gameTick = false;
		
				local strTile = DataMgr.GetMsgByID(102012);
				
				-- 只有确定
				CommonMessageBoxUI:ShowConnectionPanel(1, strTile, errorMsg, 
					function()								
						-- 登出逻辑
						LoginSystem.backLogin();
					end);				
			end
		end
	end		
	
	local param = {};
	table.insert(param, isConnected);
	table.insert(param, nReason);
	EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_CONNECTED, param);
end

--连接状态回调
function NetUtil.OnStateChange(state, param1, param2, param3)
	log(string.format("NetUtil.OnStateChange State(%d), Param1(%d), Param2(%d), Param3(%d)：", state, param1, param2, param3),true);
	if state == 0 then
		log("GCloud::Conn::kConnectorStateRunning");
		--正在运行,无需处理
	elseif state == 1 then
		log("GCloud::Conn::kConnectorStateReconnecting.......");
		--正在重连,不处理
	elseif state == 2 then
		log("GCloud::Conn::kConnectorStateReconnected isConnect:"..param1);
		-- 进入重连响应
		NetUtil.OnConnected((param1 == 0), param1);
	elseif state == 3 then
		log("GCloud::Conn::kConnectorStateStayInQueue");
		local queuePosition = param1;
		local queueLength = param2;
		local estimateTime = param3;
		log(string.format("Queue, current position:%d of total quque length:%d,estimateTime=%d", queuePosition, queueLength, estimateTime));
        
        LoginSystem.isInWaiting = true;
		NetUtil.connectionTick = false;
		NetUtil.gameTick = false;
        
		local function cancelWaiting()
            log("cancelWaiting..")
            LoginSystem.backLogin();
        end
        local timewait = math.floor(estimateTime / 60);
        CommonMessageBoxUI:HideAllMessageBox();
		local str = Client.GetTableData("LocalizeRes",301108).TextValue;
		local str2 = Client.GetTableData("LocalizeRes",301109).TextValue;
		local str3 = Client.GetTableData("LocalizeRes",110035).TextValue;
		--local text = string.format("服务器已满，您现在正在队列中。\n        您在队列中的位置:%d\n          预计等待时间%d分钟", queuePosition, timewait);
		local text = string.format(str, queuePosition, timewait);
		--CommonMessageBoxUI:ShowPanel(1, "登录队列", text, cancelWaiting, nil, "取消");
		CommonMessageBoxUI:ShowPanel(1, str2, text, cancelWaiting, nil, str3);
	elseif state == 4 then
		log("GCloud::Conn::kConnectorStateError");
		local errorCode = param1;
		log("errorCode == "..errorCode);
		
		if errorCode == 207 or errorCode == 205 then
			log("GCloud::Conn::kErrorSendError");
			NetUtil.OnConnected(false, 201);
		else
			if param2 == 7 then
				log("后台主动将客户端踢下线");
				log("extendCodeOfGameSvr = "..param3);
			else
				log("extend = "..param2.."extend2 = "..param3);
			end	
			
			NetUtil.OnConnected(false, errorCode);
		end
		--[[
		if errorCode == 2 then
			log("GCloud::Conn::kErrorNetworkException");
			NetUtil.OnConnected(false, 2);

		elseif errorCode == 201 then
			log("GCloud::Conn::kErrorConnectFailed");
			NetUtil.OnConnected(false, 201);

		elseif errorCode == 213 then
			log("GCloud::Conn::kErrorOverflow!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		
		elseif errorCode == 205 then
			log("GCloud::Conn::kErrorPeerStopSession");
			local extend = param2;
			if extend == 7 then
				local extendCodeOfGameSvr = param3;
				log("后台主动将客户端踢下线");
				log("extendCodeOfGameSvr = "..extendCodeOfGameSvr);
			else
				log("extend = "..extend.."extend2 = "..param3);
			end		
			NetUtil.OnConnected(false, errorCode);
		elseif errorCode == 207 then
			log("GCloud::Conn::kErrorSendError");
			NetUtil.OnConnected(false, 201);
		else
			NetUtil.OnConnected(false, errorCode);
		end
		]]--
	end
end


function NetUtil.OnDisconnected(nReason)
	sandbox.LogError("NetUtil.OnDisconnected nReason：".. nReason);
	log("NetUtil.OnDisconnected nReason：".. nReason,true);
end

-- tick检查逻辑
function NetUtil.CheckTime()
	
	if NetUtil.checkLoginRsp then
		-- 检查login回包
		if NetUtil.sendLoginTime > 0 and os.time() - NetUtil.sendLoginTime > 5 then
			if NetUtil.checkLoginRetryTime == 0 then
				-- 只做一次重试
				log("gavin checkLoginRsp timeout!! "..NetUtil.checkLoginRetryTime..", isRelogin:"..tostring(LoginSystem.isRelogin));
				LoginSystem.reqLoginLobby(LoginSystem.isRelogin);				
				NetUtil.checkLoginRetryTime = NetUtil.checkLoginRetryTime + 1;
			end
		end
	end


	if NetUtil.checkWaitingReEnterGameNotify then
		if os.time() - NetUtil.waitingReEnterGameStartTime > 5 then
			-- 关闭超时检查
			NetUtil.StopCheckDSActive();			
			local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));			
			log("gavin checkWaitingReEnterGameNotify timeout!! curStatus:"..curStatus..", isWaittingEnterBattle:"..tostring(LobbySystem.isWaittingEnterBattle));			
			
			-- 关闭菊花
			ConnectionWaitingUI:Hide();
			
			if LobbySystem.isWaittingEnterBattle then
				-- 当前在loading页面，重置匹配状态			
				LobbySystem.SetWaitingBattleFlag(false);
				-- 强行返回大厅
				Client.ReturnToLobby(GameFrontendHUD);
			elseif curStatus == "fighting" then
				-- 提示
				local strTile =DataMgr.GetMsgByID(102012);
				-- 战斗已结束，请返回大厅
				--local strMsg = "战斗已结束，请返回大厅";
				local strMsg = Client.GetTableData("LocalizeRes",301111).TextValue;
				CommonMessageBoxUI:ShowConnectionPanel(1, strTile, strMsg, 
					function()
						-- 重新获取一下游戏状态
						curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
						if curStatus == "fighting" then
							-- 打开loading
							BP_LoadingTo = 0
							LoadingUI:Init();
							-- 强行返回大厅
							Client.ReturnToLobby(GameFrontendHUD);
							
							-- 上报战斗服务器连接异常
							Client.TApmDisconnectReport(GameFrontendHUD, 11);
						end
					end);
			end		
		end
	end
	
	-- 战斗中大厅连接断开  间隔时间尝试重连
	if NetUtil.checkConnectingInFighting then
		if os.time() - NetUtil.waitingReEnterGameStartTime > 5 then
			-- 每5s静默重连一次,直到连上为止
			local status = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			log("tryConnect lobby in fighting!!! curTime:"..os.time()..", startTime:"..NetUtil.waitingReEnterGameStartTime..", curStatus:"..status);
			if not Client.IsConnected(NetInterface) and status == "fighting" then
				NetUtil.tryConnect();
			else
				log("gavin stop checkConnectingInFighting");
				NetUtil.checkConnectingInFighting = false;
				NetUtil.waitingReEnterGameStartTime = 0;
			end
			
			-- 更新时间
			NetUtil.waitingReEnterGameStartTime = os.time();
		end
	end
end

-- 开启login回包检查
function NetUtil.StartCheckLoginRsp()
	-- 开启重试逻辑
	log("NetUtil.StartCheckLoginRsp......");
	NetUtil.checkLoginRsp = true;
	NetUtil.sendLoginTime = os.time();
end
-- 关闭login回包检查
function NetUtil.StopCheckLoginRsp()
	log("NetUtil.StopCheckLoginRsp!!!!!");
	NetUtil.checkLoginRsp = false;
	NetUtil.sendLoginTime = 0;
	NetUtil.checkLoginRetryTime = 0;
end
-- 开启战斗断线重连ds是否存在检查
function NetUtil.StartCheckDSActive()	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	log("gavin StartCheckDSActive isWaittingEnterBattle: "..tostring(LobbySystem.isWaittingEnterBattle)..", curStatus: "..curStatus);
	-- 如果处于等待进入战斗的loading中			
	if (LobbySystem.isWaittingEnterBattle or curStatus == "fighting") and NetUtil.checkWaitingReEnterGameNotify == false then
		-- 开启超时检查，在loading中断开时，如果ds正在启动中（3s-4s），这时候重连回来大厅是不知道要重回战斗中的
		-- 需要客户端自行增加超时机制 强回大厅
		NetUtil.checkWaitingReEnterGameNotify = true;
		NetUtil.waitingReEnterGameStartTime = os.time();
		log("gavin waitingReEnterGameStartTime:"..NetUtil.waitingReEnterGameStartTime);
	end
end
-- 关闭战斗断线重连ds是否存在检查
function NetUtil.StopCheckDSActive()
	log("gavin StopCheckDSActive");
	NetUtil.checkWaitingReEnterGameNotify = false;
	NetUtil.waitingReEnterGameStartTime = 0;
end


function NetUtil.OnTick(curTime, deltaTime)	
	if LoginSystem.hasKickOut then
		-- 被踢出游戏后不进行心跳
		return;
	end

	if NetUtil.gameTick then		
		if NetUtil.c2sTime > 0 and curTime - NetUtil.c2sTime > 7 then
			-- 请求包超过7s没有返回时，发起重连
			log("heart_beat c2sTime response time out!!! curTime:" .. curTime..", c2sTime:"..NetUtil.c2sTime, true);
			log_tree("NetUtil.s2cNeedWaiting", NetUtil.s2cNeedWaiting);
			-- 检查第一个存入的请求属性
			for i,v in ipairs(NetUtil.s2cNeedWaiting) do
				if v.needTryConnect then
					-- 需要重连
					NetUtil.tryConnect();
				else
					-- 不需要重连 并给出提示
					--DataMgr.ShowNoticeByString("服务器没有响应，请稍后再试");
					DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes",301112).TextValue);
					-- 清空等待队列
					NetUtil.c2sTime = 0; 
					NetUtil.s2cNeedWaiting = {};
					-- 关闭菊花
					ConnectionWaitingUI:Hide();
				end
				
				break;
			end
			
			
		elseif curTime - NetUtil.SendTime >= 5 then		
			-- 每5s同步一次心跳
			NetUtil.SendTime = curTime;		
			NetUtil.LobbyDelaySendTime = os.clock()
			--local curStatus = LuaClassObj.GetGameStatus(bp_lobby);
			--log("NetUtil.OnTick "..curStatus);
			
			if curTime - NetUtil.RecvTime > 30 then
				-- 心跳回包时间间隔超过10s时，发起重连
				log("heart_beat response time out:" .. curTime);
                LoginSystem.isInLobby = false;
				NetUtil.tryConnect();
			else
				log("heart_beat req:" .. curTime);
				NetUtil.SendPkg("heart_beat", curTime);		
			end
            if LoginSystem.isInLobby then
                --登录成功了才每5s发一次Tss
                NetUtil.SendTss()
            end
		end		
	elseif NetUtil.connectionTick then
		if curTime - NetUtil.SendTime > 10 then		
			-- 连接超时10s后，弹出面板提示
			log("heart_beat connectionTick time out:" .. curTime..", SendTime:"..NetUtil.SendTime,true);
			NetUtil.showConnectionMsgTimes = NetUtil.showConnectionMsgTimes + 1;
			local errMsg = FuncUtil:GetGCloudErrorMsg(GCLOULD_ErrorNetworkException);
			NetUtil.ShowConnectionMsgBox(NetUtil.showConnectionMsgTimes, errMsg);
		end
	end	
end

HeartBeatServerTime = 0;

-- 获取当前服务器时间
function NetUtil.GetCurServerTime()
    if HeartBeatServerTime <= 0 then
        return os.time()
    end
	return HeartBeatServerTime + os.time() - NetUtil.RecvTime;
end

-- 心跳响应
function NetUtil.OnHeartBeatRsp(key, now)
	log("heart_beat rsp upTime:"..key..", svrTime:"..now);	
    HeartBeatServerTime = now;
    NetUtil.RecvTime = os.time();    
    FuncUtil.SetServerTimeInSec(now);
    NetUtil.LobbyDelayRecvTime = os.clock()
    BP_LobbyNetworkDelay = math.floor((NetUtil.LobbyDelayRecvTime - NetUtil.LobbyDelaySendTime) * 1000);

	--log("heart_beat rsp upTime:"..NetUtil.LobbyDelaySendTime..", svrTime:"..NetUtil.LobbyDelayRecvTime..", networkDelay:"..BP_LobbyNetworkDelay);	
    -- 大厅网络状态标志
    if BP_LobbyNetworkDelay <= 5000 then
        BP_LobbyNetworkStatus = true
        LobbyUI:UpdateNetworkDelay()
    end
end

-- 战斗中断线重连通知
function NetUtil.OnReEnterGameNotify(ip, port, key, packet_key, game_id, res, team_info)
	log("gavin on_re_enter_game_notify ip:"..ip..", port:"..port..", key:"..key..", game_id:"..game_id..", res:"..res,true);	
	log_tree("team info on_re_enter_game_notify", team_info);
	
	NetUtil.StopCheckDSActive();
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	
	-- ds服务器当前状态
	local dsState = Client.GetUnrealNetworkStatus(GameFrontendHUD);
	-- dsState    
	log("gavin CurDSSeverState: "..dsState..", gameStatus: "..curStatus);
	
	local strTile = DataMgr.GetMsgByID(102012);
	local strMsg = "";	
	
	if res ~= "ok" then
		--strMsg = "您已经被淘汰，无法重回战斗";
		strMsg = Client.GetTableData("LocalizeRes",301113).TextValue;
		if res == "version_mismatch" then
			--strMsg = "版本不匹配，无法重回战斗";
			strMsg = Client.GetTableData("LocalizeRes",301114).TextValue;
		end
		
		CommonMessageBoxUI:ShowPanel(1, strTile, strMsg, 
		function()
			curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			if curStatus == "fighting" then
				--如果在战斗中  返回大厅
                BP_LoadingTo = 0
				LoadingUI:Init();
				Client.ReturnToLobby(GameFrontendHUD);
							
				-- 上报战斗服务器连接异常
				Client.TApmDisconnectReport(GameFrontendHUD, 12);
			elseif LobbySystem.isWaittingEnterBattle then
				-- 重置匹配状态
				LobbySystem.SetWaitingBattleFlag(false);
				-- 关闭loading
				LoadingUI.RefreshLoadPercent(1);
				Client.ReturnToLobby(GameFrontendHUD);
			end
		end, nil);			
		return;
	end
	
	-- game_id 供游戏结算逻辑使用
	g_game_id = game_id;		
	
	if dsState == "Connecting" then
		-- ds在建立连接成功后会拉玩家进入战场 这时不需要发起enterbattle流程		
		log("gavin CurDSSeverState is Connecting  not need enter battle!! ");
		return;
	end
	
	if curStatus == "fighting" then
		-- 如果当前ds处于Online状态则不做任何处理，否则发起EnterBattle流程
		if dsState == "Online" or dsState == "RecoverableLost" then
			-- do nothing
		else
			-- 如果在战斗中则静默重进战斗
			log("gavin NetUtil.EnterBattle 2 dsState:"..dsState..", ip:"..ip..", port:"..port..", key:"..key);
			NetUtil.EnterBattle(ip, port, key, DataMgr.roleData.nickName, packet_key, g_game_id);
			LobbySystem.ResetMatchInfo();

			GlobalChatVoice.JoinGameVoiceRoom(team_info);
			Client.JoinLbsVoiceRoom(GameFrontendHUD, game_id, DataMgr.roleData.openID);
		end
		return;
	end	
	
    -- 大厅网络状态标志
    BP_LobbyNetworkStatus = true
    LobbyUI:UpdateNetworkDelay()
                
	local function clickOkCallback()
		-- 进入游戏
		log("gavin NetUtil.EnterBattle 1 ip:"..ip..", port:"..port..", key:"..key);
		--重连之后显示loading
        BP_LoadingTo = 1
		LoadingUI:Init();
		BP_LoadingTo = 0
        
		NetUtil.EnterBattle(ip, port, key, DataMgr.roleData.nickName, packet_key, g_game_id);
		LobbySystem.ResetMatchInfo();

		GlobalChatVoice.JoinGameVoiceRoom(team_info);
		Client.JoinLbsVoiceRoom(GameFrontendHUD, game_id, DataMgr.roleData.openID);
	end
	
	local function clickCancelCallback()
		-- 返回大厅，进入强制退出逻辑
		log("gavin giveup_enter_game curStatus:"..curStatus..", isWaittingEnterBattle:"..tostring(LobbySystem.isWaittingEnterBattle));
		NetUtil.SendPkg("giveup_enter_game");
		curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
		if curStatus == "fighting" then
			-- 如果当前不在大厅中 则loading 然后回大厅
            BP_LoadingTo = 0
			LoadingUI:Init();
			Client.ReturnToLobby(GameFrontendHUD);
							
			-- 上报战斗服务器连接异常
			Client.TApmDisconnectReport(GameFrontendHUD, 13);
		elseif LobbySystem.isWaittingEnterBattle then
			-- 如果在战斗等待页面 则直接返回大厅
			-- 重置匹配状态
			LobbySystem.SetWaitingBattleFlag(false);
			-- 关闭loading
			LoadingUI.RefreshLoadPercent(1);
			Client.ReturnToLobby(GameFrontendHUD);
		end
	end
	
	--是否重新进入战斗？
	strMsg =DataMgr.GetMsgByID(103016);	
	CommonMessageBoxUI:ShowPanel(2, strTile, strMsg, clickOkCallback, clickCancelCallback);	
end

-- 尝试重连大厅服务器
function NetUtil.ShowConnectionMsgBox(showPanelTimes, errorMsg)
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	log("gavin NetUtil.ShowConnectionMsgBox: "..showPanelTimes..", curStatus:"..curStatus,true);
        
	if curStatus == "lobby" then
		--大厅网络状态标识
		BP_LobbyNetworkStatus = false;
		LobbyUI:UpdateNetworkDelay();
	end
	
	NetUtil.connectionTick = false;
	NetUtil.gameTick = false;

	local function clickOkCallback()
		-- 再次尝试重连
		NetUtil.tryConnect();
        
        LoginSystem.enableLoginButton();
	end
	
	local function clickCancelCallback()	
		-- 登出逻辑
		LoginSystem.backLogin();
	end
	
	ConnectionWaitingUI:Hide();
	
	local strTile =DataMgr.GetMsgByID(102012);
	
	--无法连接到服务器，请检查你的网络。
	local strMsg =DataMgr.GetMsgByID(103015);		
	if showPanelTimes == 2 then
		--strMsg = "连接服务器没有响应，请稍后再试";
		strMsg = Client.GetTableData("LocalizeRes", "301226").TextValue;
	elseif showPanelTimes == 3 then
		--strMsg = "连接服务器没有响应，请确认你的网络是否正常";
		strMsg = Client.GetTableData("LocalizeRes", "301227").TextValue;
	else
		--strMsg = "连接服务器没有响应，请返回登录重试";
		strMsg = Client.GetTableData("LocalizeRes", "301228").TextValue;
	end
	
    
	if showPanelTimes < 4 then
		-- 有确定取消
		CommonMessageBoxUI:ShowConnectionPanel(2, strTile, strMsg, clickOkCallback, clickCancelCallback);
	else
		-- 只有确定
		CommonMessageBoxUI:ShowConnectionPanel(1, strTile, strMsg, clickCancelCallback);
	end
end

-- 尝试建立连接
function NetUtil.tryConnect()	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));	
	local lobbyInfo = LoginSystem.loginLobbyInfo;
	log("gavin NetUtil.tryConnect url = " .. lobbyInfo.Url..", curStatus:"..curStatus);
	-- 停止游戏心跳，开启连接心跳
	NetUtil.connectionTick = true;
	NetUtil.gameTick = false;
	
	-- 记录时间
	NetUtil.SendTime = os.time();
	
	local isConnected = Client.IsConnected(NetInterface);
	log("Client.IsConnected is "..tostring(isConnected));
	
	if curStatus ~= "fighting" then
		-- 显示菊花
		ConnectionWaitingUI:Show();		
	end
	
	-- 发起连接
	NetUtil.ConnectToURL(LoginSystem.loginLobbyInfo.Url);
end

function NetUtil.OnNetworkEvent(eventID, eventParam)
	log("gavin OnNetworkEvent: eventID = " .. eventID.." eventParam = "..eventParam,true);
	
    ConnectionWaitingUI:Hide();
	if eventID == 1 then
		log("authorization initialized");
	elseif eventID == 2 then 
		log("authorization login notify");
		if eventParam == 0 then
			log("login ok");
            --清理登录尝试次数
			LuaClassObj.HandleUIMessage(bp_authorization, "clearLoginCount");
            local function UpdateEndCallBack()
                log("UpdateEndCallBack")
                if LoginSystem.isDirectConnect == false then
                    log("hideAuthorizationUI")
                    LuaClassObj.HandleUIMessage(bp_login, "UIShow");
                    LuaClassObj.HandleUIMessage(bp_authorization, "hideAuthorizationUI");
                    local channel = Client.GetLoginChannel(NetInterface);
                    log("authorization login ok, channel = " .. channel);
					local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_login));
                    if channel == BP_ENUM_PLAYFORM_WX and curStatus == "login" then
	                    DataMgr.ShowNoticeByID("101709");	--登陆授权成功
	                end
                else
                    log("Connect to Gate Directly")
                    EventConnectToGate();
                end
				--刷新accesstoken
				if Client.IsConnected(NetInterface) and Client.GetLoginChannel(NetInterface) == BP_ENUM_PLAYFORM_WX then
					local accessToken = Client.GetAccessToken(NetInterface);
					NetUtil.SendPkg("refresh_wx_atk", accessToken);
				end
            end
            ---登录成功,开始尝试灰度更新
            ---游戏一次启动仅尝试一次
            if not VersionUpdate.AlreadyGrayUpdate then
                log("will gray update")
                VersionUpdate.StartGrayUpdate(UpdateEndCallBack)
            else
                log("no gray update")
                --无需灰度更新
                UpdateEndCallBack()
            end
        elseif eventParam == 3 then
        	log("auth fail need retry");
			DataMgr.ShowNoticeByID("101713");	--授权失败，请您重新授权！
        elseif eventParam == 106 then
        	log("auth fail for user cancel");
        	DataMgr.ShowNoticeByID("101711");
        	--local channel = Client.GetLoginChannel(NetInterface);
        	--log("channel = " .. channel);
        	--[[
        	if channel == BP_ENUM_PLAYFORM_WX then
        		log("channel == BP_ENUM_PLAYFORM_WX");
                DataMgr.ShowNoticeByID("101711");	--您取消了授权
            elseif channel == BP_ENUM_PLAYFORM_QQ then
            	log("channel == BP_ENUM_PLAYFORM_QQ");
            	DataMgr.ShowNoticeByID("101712");	--您取消了QQ授权
            end
            ]]
		else
			log("login failed:"..eventParam);
			--如果不是自动鉴权失败或取消鉴权需弹出提示
            if eventParam ~= -1 and eventParam ~= 6 and eventParam ~= 7 and eventParam ~= 106 and eventParam ~= 107 and eventParam ~= 109 and eventParam ~= 200 then
                --记录登录尝试次数
                LuaClassObj.HandleUIMessage(bp_authorization, "addLoginCount");
                local title = DataMgr.GetMsgByID(101001);
                local notice = DataMgr.GetMsgByID(101100 + eventParam)
                CommonMessageBoxUI:ShowPanel(1, title, notice);
                return;
            end

            --记录登录尝试次数
			LuaClassObj.HandleUIMessage(bp_authorization, "addLoginCount");
			LuaClassObj.HandleUIMessage(bp_login, "UIHide");
			LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
            LuaClassObj.HandleUIMessage(bp_authorization, "showButtons");
            if eventParam == 7 and Client.GetDevicePlatformName() == "Windows" then
        		DataMgr.ShowNoticeByID("101710");
            end
		end
	elseif eventID == 3 then
		if eventParam == 0 then
			log("logout change account");
            LoginSystem.backLogin(1);
		else
			log("logout failed");
		end
	elseif eventID == 4 then
		ConnectionWaitingUI:Hide();
		if eventParam == 0 then
			log("shared success");
			ShareMgr:onShareResult(1, "");
		else
			log("shared failed");
			ShareMgr:onShareResult(0, "");
		end
	elseif eventID == 255 then
		--国际化绑定事件
		log("received bind intl event,eventid : "..eventParam);
		EventSystem:postEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_NOTIFY,eventParam);
	elseif eventID == 254 then
		--连接服务器成功后刷新的绑定信息
		local bind_fb=0;
		local bind_gc=0;
		local bind_gp=0;
		if eventParam == 1 or eventParam == 3 or eventParam == 5 or eventParam == 7 then
			bind_fb=1;
		end
		if eventParam == 2 or eventParam == 3 or eventParam == 6 or eventParam == 7 then
			bind_gc=1;
		end
		if eventParam == 4 or eventParam == 5 or eventParam == 6 or eventParam == 7 then
			bind_gp=1;
		end

		log("received bind info,eventid : "..eventParam..",bind_fb : "..bind_fb..",bind_gc : "..bind_gc..",bind_gp : "..bind_gp);
		NetUtil.SendPkg("report_player_bind_info", bind_fb,bind_gc,bind_gp);
		EventSystem:postEvent(EVENTTYPE_BIND_INTL,EVENTID_INTL_BIND_NOTIFY,1);--notify refreshed bind info
	end
end

-- DS服务器连接异常通知
function NetUtil.OnDSServerConnectionErrorNotify(gameID, reason)
	log("gavin OnDSServerConnectionErrorNotify -------- gameID:"..gameID..", reason:"..reason..", BattleResult:"..tostring(BattleResult.IgnoreDSError),true);
	
	if BattleResult.IgnoreDSError then
		log("gavin BattleResult.IgnoreDSError return！！！！");	
		return;
	end
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	if curStatus ~= "fighting" then
		log("gavin not in fighting dont show msgbox!!!"..curStatus);
		return;
	end	
	
	local strTile =DataMgr.GetMsgByID(102012);
	--local strMsg = "战斗服务器连接已断开！";
	local strMsg = Client.GetTableData("LocalizeRes", "301229").TextValue;
	if reason == "timeout" then
		--strMsg = "战斗服务器连接超时，请返回大厅！";
		strMsg = Client.GetTableData("LocalizeRes", "301230").TextValue;
	elseif reson == "active-timeout" then
		--strMsg = "战斗服务器响应超时，请返回大厅！";
		strMsg = Client.GetTableData("LocalizeRes", "301231").TextValue;
	end
	
	CommonMessageBoxUI:ShowConnectionPanel(1, strTile, strMsg, 
		function()
			--返回大厅
            BP_LoadingTo = 0
			LoadingUI:Init();
			Client.ReturnToLobby(GameFrontendHUD);
			LoginSystem.reqLoginLobby(true);
										
			-- 上报战斗服务器连接异常
			Client.TApmDisconnectReport(GameFrontendHUD, 14);
		end);
end

function NetUtil.LogOut()
    log("NetUtil.LogOut()");
	NetUtil.SendPkg("logout");
end

function NetUtil.OnEcho(msg)	
	log(string.format("echo :%s", msg or "nil"));
end

function NetUtil.sync_time(serverTime)	
	log(string.format("sync_time :%s", os.date("%Y-%m-%d %H:%M:%S", serverTime)));
	FuncUtil.SetServerTimeInSec(serverTime);
end
---------------------------------------------------------------------------------------------------------

UnrealNet.NetworkStatus =
{
	Offline = "Offline",
	Connecting = "Connecting",
	Online = "Online",
	Lost = "Lost",
	RecoverableLost = "RecoverableLost"
}

UnrealNet.NetworkEvent = 
{
	-- OnActorChannel of PlayerController called
	NetworkEstablished = "NetworkEstablished",

	-- RecentlyReceived of NetConnection broadcasted
	NetworkRecovered= "NetworkRecovered"
};

UnrealNet.NetworkException = 
{
	-- NMT_Failure received, typically player validation failed, or reconnection failed, or replication or RPC failed
	FailureReceived = "FailureReceived",

	-- connection closed, typically connection closed locally or received a close bunch from DS
	ConnectionLost = "ConnectionLost",

	-- connection timeout detected locally, triggered by NetConnection
	ConnectionTimeout = "ConnectionTimeout",

	-- timeout while connecting to DS, typically send handshake failed, or DS is down, triggered by GameFrontendHUD
	ConnectingTimeout = "ConnectingTimeout",

	-- typically player validation failed in PreLogin
	PendingConnectionFailure = "PendingConnectionFailure",

	-- a critical socket error detected locally, typically socket resource released by operating system and will never be available again
	CriticalSocketError = "CriticalSocketError",

	-- actor channel process bunch error, typically a property or RPC mismatch
	ActorChannelError = "ActorChannelError"
};

UnrealNet.FailureReceivedReason =
{
	CharacterDead = "CharacterDead",
	TeammatesAllDead = "TeammatesAllDead",
	GameOver = "GameOver"
}

-- ds状态变更通知
function UnrealNet.HandleNetworkEvent(EventType, ...)
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	sandbox.Log(string.format("gavins NetworkEvent %s, curstatus %s", EventType, curStatus));
	
	-- DS服务器状态变更通知
	if EventType == "NetworkEstablished" or EventType == "NetworkRecovered" then
		-- 收到ds超时重连恢复消息
		-- 关闭模态菊花
		ConnectionWaitingUI:Hide();
		
		NetUtil.dsTimeOutRetryTimes = 0;
		
		if curStatus == "fighting" then
			-- 关闭所有网络异常面板
			CommonMessageBoxUI:HideAllMessageBox();
		end
	end
end

function UnrealNet.HandleNetworkException(ExceptionType, ErrorMessage, bShouldWait, ...)

	-- send to lobby for statistics
	NetUtil.SendPkg("report_unrealnet_exception", g_game_id, ExceptionType, ErrorMessage);

	-- 'ActorChannelError' is only for reporting and statistics
	if ExceptionType == UnrealNet.NetworkException.ActorChannelError then
		return;
	end

	sandbox.LogError(string.format("gavin NetworkFailure %s %s", ExceptionType, ErrorMessage));
	log("gavin NetworkFailure "..ExceptionType..", "..ErrorMessage..", "..tostring(bShouldWait)..", dsTimeOutTimes:"..NetUtil.dsTimeOutRetryTimes, true);
	
	local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	log("gavin CurStatus: "..curStatus);
	if curStatus == "login" then
		-- 在登录阶段不弹出ds相关异常
		return;
	end
	
	-- 默认关一下loading页面
	LoadingUI.RefreshLoadPercent(1);	
	
	if curStatus == "fighting" and bShouldWait == true and NetUtil.dsTimeOutRetryTimes < 3 and not BattleResult.IgnoreDSError then
		-- 超时计数由ds维护 这边只接收消息做表现
		-- 不需要判断ExceptionType
		NetUtil.dsTimeOutRetryTimes = NetUtil.dsTimeOutRetryTimes + 1;
		local prompt = Client.GetTableData("LocalizeRes", "101001").TextValue;
		local msg = Client.GetTableData("LocalizeRes", "301232").TextValue;
		--CommonMessageBoxUI:ShowConnectionPanel(2, "提示", "战斗服务器响应超时，是否尝试重连？", 
		CommonMessageBoxUI:ShowConnectionPanel(2, prompt, msg, 
		function()
			--开启菊花等待ds服务器响应
			curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			log("gavin click ds timeout panel ok: "..curStatus);
			if curStatus == "fighting" then
				ConnectionWaitingUI:Show();
			end
		end,
		function()
			-- 返回大厅
			curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			log("gavin click ds timeout panel cancel: "..curStatus);
			if curStatus == "fighting" then
				-- 在战斗中返回大厅
                BP_LoadingTo = 0
				LoadingUI:Init();
				Client.ReturnToLobby(GameFrontendHUD);				
				LoginSystem.reqLoginLobby(true);
				
				-- 上报战斗服务器连接异常
				Client.TApmDisconnectReport(GameFrontendHUD, 15);
			end
		end);
		
		return;
	end
	
	
	-- 以下逻辑都默认ds的错误是不可恢复的  需要回到大厅
	local strTile =DataMgr.GetMsgByID(102012);
	-- 战斗服务器连接已断开，请重新开始游戏。
	local strMsg = DataMgr.GetMsgByID(103017);
	local needRelogin = false;
	
	if ExceptionType == "FailureReceived" or ExceptionType == UnrealNet.NetworkException.PendingConnectionFailure then
		if ErrorMessage == "CharacterDead" then
			--strMsg = "您上一局游戏已经结束";
			strMsg = Client.GetTableData("LocalizeRes",120004).TextValue;
		elseif ErrorMessage == "TeammatesAllDead" then
			--strMsg = "您的队伍已经被淘汰";
			strMsg = Client.GetTableData("LocalizeRes",120007).TextValue;
		elseif ErrorMessage == "GameOver" then
			--strMsg = "当前战斗已结束，无法进入";
			strMsg = Client.GetTableData("LocalizeRes",301117).TextValue;
		end
	elseif ExceptionType == "ConnectionTimeout" then
		--strMsg = "战斗服务器连接超时，请重新开始游戏";
		strMsg = Client.GetTableData("LocalizeRes",301118).TextValue;
		needRelogin = false;
	elseif ExceptionType == "ConnectingTimeout" then
		--strMsg = "战斗服务器没有响应，请稍后再试";
		strMsg = Client.GetTableData("LocalizeRes",301233).TextValue;
		needRelogin = true;		
	else
		needRelogin = true;
	end
	
    log("NetworkFailure, IgnoreDSError -- " .. tostring(BattleResult.IgnoreDSError) .. " needRelogin -- " .. tostring(needRelogin));
    if BattleResult.IgnoreDSError then
 --为了改这个bug，http://tapd.oa.com/10168201/bugtrace/bugs/view?bug_id=1110168201055963844 删掉额外判断---
		log("gavin DS BattleResult.IgnoreDSError return！！！！");
		return;
	end
    
	CommonMessageBoxUI:ShowPanel(1, strTile, strMsg, 
		function()
			--返回返回大厅
			curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));	
			log("gavinsun start ReturnToLobby needRelogin: "..tostring(needRelogin)..", curStatus:"..curStatus..", isWaittingEnterBattle"..tostring(LobbySystem.isWaittingEnterBattle));		
			if curStatus == "fighting" or curStatus == "pending" or LobbySystem.isWaittingEnterBattle then
				-- 在战斗中或者在进入战斗的loading中才处理
                BP_LoadingTo = 0
				LoadingUI:Init();
				Client.ReturnToLobby(GameFrontendHUD);
				
				if needRelogin then
					LoginSystem.reqLoginLobby(true);
				end
							
				-- 上报战斗服务器连接异常
				Client.TApmDisconnectReport(GameFrontendHUD, 16);
			end
		end);
		
	EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_DS_SERVER_CONNECT_FAILED);
end

s2c["heart_beat"] = NetUtil.OnHeartBeatRsp;
s2c["re_enter_game"] = NetUtil.OnReEnterGameNotify;
s2c["on_send_client_data"] = NetUtil.OnTssRsp;
s2c["game_unusual_end"] = NetUtil.OnDSServerConnectionErrorNotify;
s2c["echo"] = NetUtil.OnEcho;
s2c["sync_time"] = NetUtil.sync_time;
