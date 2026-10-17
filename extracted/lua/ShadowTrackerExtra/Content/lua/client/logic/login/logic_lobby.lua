--[[
  大厅和房间的相关逻辑
]]--

LobbySystem =  LobbySystem or {
	roomMode = 0;		--可以在UI 的BP里面赋值.
	matchZone = 0;
	autoFill = 1;
	isInMatch = false;
	beginMatchTime = 0;

    currentLobbyPlayNum = 1;

    statusReady = 1;
    statusUnready = 2;
    
    isNewPlayer = false;    --是否是新用户
    
    currentLobbyPlayerDataList = {};
    
    isWaittingEnterBattle = false;
    -- 功能开关
    LobbyMenuOpenStatus = {}
}




local ValidDeviceList = {
"ALP%-AL00",
"ALP%-TL00",
"BLA%-AL00",
"BLA%-TL00",
"MHA%-AL00",
"MHA%-TL00",
"LON%-AL00",
"LON%-AL00%-PD",
"BKL%-AL00",
"BKL%-AL20",
"BKL%-TL10",
"DUK%-AL20",
"STF%-AL00",
"STF%-AL10",
"STF%-TL10",
"VTR%-AL00",
"VTR%-TL00",
"VKY%-AL00",
"VKY%-TL00",
"MI 6",
"MIX 2",
"MI NOTE 3",
"OPPO R11",
"OPPO R11S",
"OPPO R11 PLUS",
"OPPO R11 PLUSKT",
"OPPO R11S PLUS",
"VIVO XPLAY6",
"VIVO XPLAY6L",
"VIVO X20A",
"VIVO X20",
"VIVO X20PLUS",
"G9550",
"G9500",
"N9500",
"DUK%-TL30",
"SC%-01K",
"SCV37",
"SM%-N9500",
"SM%-N9500",
"SM%-N9508",
"SM%-N9508",
"SM%-N950F",
"SM%-N950FD",
"SM%-N950N",
"SM%-N950U",
"SM%-N950U1",
"SM%-N950W",
"SM%-G9500",
"SM%-G9500",
"SM%-G950A",
"SM%-G950F",
"SM%-G950FD",
"SM%-G950K",
"SM%-G950L",
"SM%-G950P",
"SM%-G950R4",
"SM%-G950S",
"SM%-G950T",
"SM%-G950U",
"SM%-G950V",
"SM%-G950W",
"SM%-G9550",
"SM%-G9550",
"SM%-G955A",
"SM%-G955F",
"SM%-G955FD",
"SM%-G955K",
"SM%-G955L",
"SM%-G955P",
"SM%-G955R4",
"SM%-G955S",
"SM%-G955T",
"SM%-G955U",
"SM%-G955V",
"SM%-G955W",
"ONEPLUS A5010",
"MLA%-AL10",
"OPPO R11 Plusk",
"vivo X20Plus A",
"OPPO R11 Plusk",
"SM%-G9350",
"MI 5S PLUS",
"MI 5X",
"MIX",
"OPPO R9S",
"OPPO R9M",
"OPPO R9SK",
"OPPO R9S PLUS",
"OPPO R9TM",
"OPPO R9 PLUSM A",
"OPPO R9ST",
"OPPO R9 PLUSTM A",
"OPPO R9KM",
"OPPO R9S PLUST",
"OPPO R9T",
"OPPO R9SKT",
"OPPO R9 PLUST A",
"NOAIN R9S",
"VIVO X9PLUS",
"VIVO X9S",
"VIVO X9S PLUS",
"VIVO X9S L",
"VIVO X9S PLUS L",
"VIVO X9PLUS L"
};

--是否需要检测三、四档机
local NeedCheckDeviceLimit = true;

local NeedCheckDevice = false;



function LobbySystem.Enter()
	log("enter lobby");
	EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_ENTERLOBBY);
end


function LobbySystem.Leave()
	log("leave lobby");
  
end

local function LocalEnterLobby()
    log("on_sync_base_info EnterLobby");

    BP_InitPercent = 20
    BP_LoadingTo = 0
    LoadingUI:Init();
    
    LobbyUI.Init();
    LobbySystem.Enter();

    --请求分享数据
	ShareMgr.GetShareInfoReq();
end

local function LocalEnterAuthorization()
    log("on_sync_base_info EnterAuthorization");
    LuaClassObj.HandleUIMessage(bp_noticebox, "UIHide");
    LuaClassObj.HandleUIMessage(bp_login, "UIHide");
    LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
    
    --LuaClassObj.HandleUIMessage(bp_global, "EnterLogin");
end

local function LocalEnterPlayerCreate()
    log("LocalEnterPlayerCreate");
    --进入创建角色切换
    LoginSystem.EnterPlayerCreate();
end
    
local function LocalUserAgreementCallBack()
	log("UserAgreementCallBack");
    LuaClassObj.HandleUIMessage(bp_noticebox, "UIHide");
	
    LocalEnterPlayerCreate();
	
    --if ( BP_Platform == BP_ENUM_PLAYFORM_TOURIST) then
    --    CommonNoticeBoxUI:ShowMessageBox(3, LongTxt.TouristSpecial_title, LongTxt.TouristSpecial_content, LongTxt.TouristSpecial_btnOK , LocalEnterPlayerCreate, LocalEnterAuthorization);
    --else
    --    if GlobalData:IsIOSCheck() then
    --        LocalEnterPlayerCreate();
    --        return
    --    end 
        
	--	local strPrompt = Client.GetTableData("LocalizeRes", "101001").TextValue;
    --    local text = Client.GetTableData("LocalizeRes", "115012").TextValue;
    --    CommonMessageBoxUI:ShowPanel(1, strPrompt, text, LocalEnterPlayerCreate);
    --end
end


function LobbySystem.on_please_create_role()
	log("please_create_role");
	local function CallBack()
	    local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
	    if(curStatus == "createrole")then    
	        log("is already in createrole");
	        return;
	    end
	    
	    LobbySystem.isNewPlayer = true;
	    
	    local channel = Client.GetLoginChannel(NetInterface);
	    log("GetLoginChannel:"..channel);
	    GlobalData:SetPlatform(channel);

	    --第一次进入需先显示用户协议界面
	    local language = Client.GetCurrentLanguage();
    	log("EventShowService: " .. language);    
    	--if(language == "zh") then
	    --	CommonNoticeBoxUI:ShowMessageBox(1, LongTxt.service_title, LongTxt.service_content, LongTxt.UserAgreement_BtnAccept , LocalUserAgreementCallBack, nil)
    	--else
	    	CommonNoticeBoxUI:ShowMessageBox(1, LongTxt.service_title_en, LongTxt.service_content_en, LongTxt.UserAgreement_BtnAccept , LocalUserAgreementCallBack, nil)
    	--end
    end
	LobbySystem.CheckDeviceType(CallBack);
end

function LobbySystem.on_sync_my_plat_name(nickname)
	log("on_sync_my_plat_name" .. nickname);
    CreateRoleUI:SetPlatformName(nickname);
end

function LobbySystem.on_create_role_respond(ret)
	log("create_role_respond -- " .. ret);
    
	ConnectionWaitingUI:Hide()
	Client.ReportEventRegisterCompleted();
    
    if(ret ~= "ok") then
        CreateRoleUI:ShowIllegalInfo(ret);
    end
    --遇到严重问题需要退到登录界面
    if(ret == "bad_param" or ret == "bad-request") then
        LoginSystem.backLogin();
    end

end

function LobbySystem.on_sync_base_info(roleData)
    --log_tree("LobbySystem.on_sync_base_info roleData,", roleData );
	local function CallBack()
		NetUtil.StopCheckLoginRsp();
		-- 开启DS状态检查
		NetUtil.StartCheckDSActive();
		
		LoginSystem.isInLobby = true;
	    if(CreateRoleUI.needClose) then
	        CreateRoleUI.needClose = false;
	    LuaClassObj.HandleUIMessage(bp_createrole, "UIHide");
	    end
	    local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
		log("LobbySystem.on_sync_base_info curStatus:"..curStatus..", isRelogin: "..tostring(LoginSystem.isRelogin));
		if curStatus == "fighting" then
			-- 如果当前处于战斗中  不做处理
			return;
		end
		
	    -- log_tree("LobbySystem.on_sync_base_info roleData", roleData);
	    FuncUtil.SetServerTimeInSec(roleData.svr_time)

		local roleDataTb = 
		{
			nickName = roleData.name,
			level = roleData.level,
			openID = roleData.openid,
			uid = tostring(roleData.uid),
			roleExp = roleData.exp,
			gold = roleData.gold,
			avatar = roleData.avatar,
			depot = roleData.depot.items,
			rolewear = roleData.rolewear,
	        parachute = roleData.parachute or "",
			signature = roleData.signature,
			headIconUrl = roleData.pic_url,
			log("[HHF]on_sync_base_info, headIconUrl = " .. roleData.pic_url);
			gender = roleData.rela_sex,
			segment = roleData.segment_info,
			login_reward = roleData.login_reward,
			last_login_reward_remind = roleData.last_login_reward_remind,
			activeness = roleData.activeness,
			task = roleData.task,
	        week_signup = roleData.week_signup,
			share_award = roleData.share_award,
			wxsubscribe = 0,		--微信订阅信息(0 未订阅 1已订阅
			qqsubscribe = 0,		--微信订阅信息(0 未订阅 1已订阅
			cur_avatar_box_id = roleData.cur_avatar_box_id, --头像框
			qq_vip = roleData.qq_vip, --qq会员 0 无会员 1 普通会员 2 超级会员
			anchor = 0,		--主播(1为主播，其他为非主播)
			xy_red_point = roleData.xy_red_point, --心悦服务器开关
		}

		if roleData.wxsubscribe then
			roleDataTb.wxsubscribe = roleData.wxsubscribe.setflag
		else
			sandbox.LogError("服务端没有下发roleData.wxsubscribe字段，请检查")
		end
		if roleData.qqsubscribe then
			roleDataTb.qqsubscribe = roleData.qqsubscribe.setflag
		else
			sandbox.LogError("服务端没有下发roleData.qqsubscribe字段，请检查")
		end
		
		if roleData.anchor ~= nil then
			roleDataTb.anchor = roleData.anchor;
		end

		Role.name = roleDataTb.nickName;
		Role.level = roleDataTb.level;
		--DataMgr.InitRoleData(nickName, level, openID, uid, roleExp, gold, avatar, depot.items, rolewear, signature, headIconUrl);
		DataMgr.InitRoleData(roleDataTb);

	    local channel = Client.GetLoginChannel(NetInterface);
	    log("GetLoginChannel:"..channel);
	    GlobalData:SetPlatform(channel);
		
		--设置启动类型
		if roleData.startup_type ~= nil then
			GlobalData:SetStartUpType(roleData.startup_type)
		end
	    
		-- 请求活动显示情况
	    LobbySystem.QueryActivityDisplayStatus()
	    
		--设置是否苹果审核
		if roleData.apple_audit ~= nil then
			GlobalData:SetIsAppleAudit(roleData.apple_audit)
		else
			GlobalData:SetIsAppleAudit(false)
		end

		--请求分享数据
		ShareMgr.GetShareInfoReq();
		
		LoginSystem.isInitLogin = true;
		
		if not LoginSystem.isRelogin then		
			--游客模式进入有提示
			--if ( BP_Platform == BP_ENUM_PLAYFORM_TOURIST and LobbySystem.isNewPlayer == false) then
			--	CommonNoticeBoxUI:ShowMessageBox(3, LongTxt.TouristSpecial_title, LongTxt.TouristSpecial_content, LongTxt.TouristSpecial_btnOK, LocalEnterLobby, LocalEnterAuthorization);
			--else
				--进入Lobby切换
				LocalEnterLobby();
			--end
			LobbySystem.query_gm_request();
		else
			--loginRsp回来，重连重新拉取下组队信息
			--请求队伍信息
			log("duan xian chogn lian team_info_request");
			TeamUpSystem.ReconnectFetchTeamUpInfo();
			--TeamUpSystem.team_info_request();
			LobbyChatroomLogic.HandleReconnectSuccess();  
	        
	        -- 断线重连回来刷新数据
			LobbyUI:RefreshPlayerData()
			
			--断线重连获取好友相关数据
			FriendSystem.GetFriendDataRequest();
			
			--断线重连获取房间数据
			log("duan xian chong lian room_info_request");
			NetUtil.SendPkg("room_info_request");
		end
	    
		TeamUpSystem.query_match_zone_list_req();
		GlobalChatVoice.ResetRoleInfo(DataMgr.roleData.uid, LoginSystem.isRelogin);
	    
	    -- 功能开关
	    if roleData.label_switch_info ~= nil then
	        LobbySystem.on_fetch_label_switch_res(roleData.label_switch_info)
	    end
		-- 心悦红点服务器开关
		if roleData.xy_red_point ~= nil then
			BP_XinyueRedPointSvrOpen = roleData.xy_red_point;
		end
		
		-- 请求免流数据
		FreeDataStreamMgr:SendGetFreeDatastreamState()
		
	    EventSystem:postEvent(EVENTTYPE_LOGIN, EVENTID_LOGIN_SUCCESS, LoginSystem.isRelogin);
	end
	LobbySystem.CheckDeviceType(CallBack);
end

function LobbySystem.on_sync_player_ban(banData)
    log("on_sync_player_ban")
    
    DataMgr.InitBanData(banData)
end

--[[
匹配
]]

function LobbySystem.SetRoomMode(roomMode)
	LobbySystem.roomMode = roomMode;
end

function LobbySystem.SetFillValue(tValue)
	LobbySystem.autoFill = tValue;
end

------------等待战斗场景的开始通知--------
function LobbySystem.OnBattleBeginPlay()
	log("----enter battle success---");
	LoadingUI.RefreshLoadPercent(1);
	LobbySystem.SetWaitingBattleFlag(false);
end

function LobbySystem.SetWaitingBattleFlag(tFlag)
	log("set waitting battle flag to ".. tostring(tFlag));
	LobbySystem.isWaittingEnterBattle = tFlag;
end

--------------------------------------------------------

function LobbySystem.on_start_match_req()
	--非队长只能准备或取消准备
	if TeamUpSystem.IsTeamLeader() == false then
		LobbySystem.change_status_req();
		return;
	end

	--是队长的状态下判断是否有玩家未准备
	if TeamUpSystem.IsEverybodyReady() == false then
		local data = Client.GetTableData("LocalizeRes", "111013");
		PopUpNoticeUI.ShowNewNotice(data.TextValue);
		return;
	end

	--读匹配配置表来修改默认值，由于目前ui还未实现，UI层会最终给定房间模式--
	if LobbySystem.roomMode == 0 then
		for key, value in pairs(BP_ARRAY_MatchModeTable) do  
			if BP_ARRAY_MatchModeTable[key].DefaultChosen == 1 then
				LobbySystem.roomMode = BP_ARRAY_MatchModeTable[key].ID;
				break;
			end
		end 
	end

	sandbox.LogNormal("start matching ...matching mode = ".. LobbySystem.roomMode.." fill = " ..LobbySystem.autoFill..", LobbySystem.matchZone = ".. LobbySystem.matchZone);
	--NetUtil.SendPkg("on_match_req", LobbySystem.roomMode, LobbySystem.matchZone, 1);

	--网络协议请求中--
	NetUtil.SendPriorityPkg(true, "on_match_res", "on_match_req", LobbySystem.roomMode,  LobbySystem.autoFill);
end

function LobbySystem.on_start_match_rsp(msg, waitTime, reason, surplustime)
	sandbox.LogNormal("---------receiving matching data, matching msg = " .. msg ..", need time = " ..waitTime);
    
	local str_prompt = Client.GetTableData("LocalizeRes",101001).TextValue;
	
    --被禁止该玩法
	if msg == "mode_banned" then
        local time = surplustime;
        --local date = os.date("%Y年%m月%d日%H时%M分%S秒", time);
		local date = os.date(Client.GetTableData("LocalizeRes",115005).TextValue, time);
        --CommonMessageBoxUI:ShowPanel(1, "提示", reason.."\n解封时间为: "..date);
		local str = string.format(Client.GetTableData("LocalizeRes",301129).TextValue, tostring(date));
        CommonMessageBoxUI:ShowPanel(1, str_prompt, reason..str);
        return;
	end
    --被禁止组队
	if msg == "member-play-banned" then
        local friend = FriendSystem.GetFriendDataByGID(reason)
        if(friend ~= nil) then
            --local date = os.date("%Y年%m月%d日%H时%M分%S秒", surplustime);
			local date = os.date(Client.GetTableData("LocalizeRes",115005).TextValue, surplustime);
            --CommonMessageBoxUI:ShowPanel(1, "提示", "好友["..friend.nickName.."]该模式被禁止！\n解封时间为: "..date);
            local str = Client.GetTableData("LocalizeRes",301130).TextValue;
            CommonMessageBoxUI:ShowPanel(1, str_prompt, string.format(str, friend.nickName, date));
        else
            --CommonMessageBoxUI:ShowPanel(1, "提示", "好友该模式被禁止！\n解封时间为: "..date);
            local str2 = Client.GetTableData("LocalizeRes",301131).TextValue;
            CommonMessageBoxUI:ShowPanel(1, str_prompt, string.format(str2, date));
        end
        return;
	end


	if msg == "member-not-ready" then
		local data = Client.GetTableData("LocalizeRes", "111013");
		PopUpNoticeUI.ShowNewNotice(data.TextValue);
		return;
	end
		
	if msg == "ok" then
		LobbySystem.isInMatch = true;
		LobbySystem.beginMatchTime = os.time();
		TeamUpUI.StartMatch();
		--show match ui --
		MatchPopupUI.RefreshRemainTime(waitTime);
		return;
	end

	--已经开始匹配了--
	if msg == "player_matching" then
		local data = Client.GetTableData("LocalizeRes", "111015");
		local msgContent = data.TextValue;	--string.format(data.TextValue, member.name);
		PopUpNoticeUI.ShowNewNotice(msgContent);
	elseif msg == "match_failed" then
		local content = Client.GetTableData("LocalizeRes", "9911101").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);
		LobbySystem.ResetMatchInfo();
		MatchPopupUI.OnMatchCancel();
	elseif msg == "mode_banned" then
		local content = Client.GetTableData("LocalizeRes", "9911102").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);

	elseif msg == "mode_is_shield" then
		local content = Client.GetTableData("LocalizeRes", "9911103").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);

	elseif msg == "invalid_match_mode" then
		local content = Client.GetTableData("LocalizeRes", "9911104").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);

	elseif msg == "player_matching" then
		local content = Client.GetTableData("LocalizeRes", "9911105").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);

	elseif msg == "player_gameing" then
		local content = Client.GetTableData("LocalizeRes", "9911106").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);

	elseif msg == "overload" then
		local content = Client.GetTableData("LocalizeRes", "9911107").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);
	elseif msg == "invalid_team_size" then
		local content = Client.GetTableData("LocalizeRes", "9911108").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);
	elseif msg == "member-offline" then
		local content = Client.GetTableData("LocalizeRes", "9911110").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);
	elseif msg == "member-in-game" then
		local content = Client.GetTableData("LocalizeRes", "9911111").TextValue;
		PopUpNoticeUI.ShowNewNotice(content); 
	else
		PopUpNoticeUI.ShowNewNotice("unknow error code :"..msg);	
	end
end

--GM是否开放
function LobbySystem.query_gm_request()
	log("query_gm_request");
	NetUtil.SendPkg("query_gm_request");
end

--非队长的准备状态进行切换--
function LobbySystem.change_status_req()
	local curStatus = TeamUpSystem.GetMyStatus();
	local reqStatus = curStatus;
	if curStatus == LobbySystem.statusReady then
		reqStatus = LobbySystem.statusUnready;
	end

	if curStatus == LobbySystem.statusUnready then
		reqStatus = LobbySystem.statusReady;
	end
	sandbox.LogNormal("request switch my status to : " ..reqStatus);
	NetUtil.SendPkg("team_change_member_status_request", reqStatus);
end

--取消匹配--
function LobbySystem.on_match_cancel_req()
	sandbox.LogNormal("--cancel match --");
	NetUtil.SendPkg("on_match_cancel_req");
end

function LobbySystem.on_match_cancel_rsp(msg, userid)
	sandbox.LogNormal("-----receive player cancel match msg = " .. msg);
	if msg == "ok" then
		LobbySystem.ResetMatchInfo();
		MatchPopupUI.OnMatchCancel();

		if TeamUpSystem.IsTeamLeader() == false  and userid == TeamUpSystem.MyUserID then
			--如果不是队长并且是我点击的取消匹配，在取消匹配后需要切换到未准备状态
			NetUtil.SendPkg("team_change_member_status_request", LobbySystem.statusUnready);
		end

		--如果已经在等待进入战斗，不提示XXX取消了匹配的提示--
		if LobbySystem.isWaittingEnterBattle then
			--非自己取消匹配需要提示给玩家XXX取消了匹配
			if userid ~= TeamUpSystem.MyUserID then
				--userid = 0的情况是服务器取消了匹配，不需要展示给玩家--
				if userid ~= 0 then
					local member = TeamUpSystem.GetMemberInfo(userid);
					local data = Client.GetTableData("LocalizeRes", "111012");
					local msgContent = string.format(data.TextValue, member.name);
					sandbox.LogNormal(msgContent);
					PopUpNoticeUI.ShowNewNotice(msgContent);
				end
			end
		end
	end

	--已经匹配成功，无法取消--
	if msg == "not_found" then
		local msgContent = Client.GetTableData("LocalizeRes", "111016").TextValue;
		sandbox.LogNormal(msgContent);
		PopUpNoticeUI.ShowNewNotice(msgContent);
	end	
end


--主动查询当前的匹配状态
function LobbySystem.QueryMatchStatus()
	log("----query match status----");
	NetUtil.SendPkg("query_match_info");
end

--match_info = { match_mode = mode, begin_time = os.time(), fill = isfill};
--断线重连后刷新匹配信息
function LobbySystem.on_reconnect_sync_matchInfo(match_Info)
	if match_Info ~= nil then
		sandbox.LogNormal("----receive reconnect match info ----");
		LobbySystem.roomMode = match_Info.match_mode;
		LobbySystem.autoFill = match_Info.fill;
		LobbySystem.beginMatchTime = match_Info.begin_time;
		LobbySystem.isInMatch = true;
		TeamUpUI.StartMatch();
		local duration = NetUtil.GetCurServerTime() - match_Info.begin_time;
		sandbox.LogNormal("----reconnet: matched time = "..tostring(duration));
		MatchPopupUI.ResetWhenReconnected(duration);
	end

	if match_Info == nil then
		log("----player does not have match status----")
		LobbySystem.ResetMatchInfo();
		MatchPopupUI.OnMatchCancel();
	end
end

function LobbySystem.ResetMatchInfo()
	LobbySystem.isInMatch = false;
	LobbySystem.beginMatchTime = 0;
	TeamUpUI.StopMatch();
end

function LobbySystem.on_match_success(msg, team_info)
	log_tree("team info", team_info);
	
	sandbox.LogNormal("receive match success response msg = " ..msg);

	if msg == "ok" then
		LobbySystem.ResetMatchInfo();
		LobbySystem.ShowMatchSuccess();
		GlobalChatVoice.JoinGameVoiceRoom(team_info);
		return;
	end

	if msg == "match_failed" then
		local content = Client.GetTableData("LocalizeRes", "9911101").TextValue;
		PopUpNoticeUI.ShowNewNotice(content);
		LobbySystem.ResetMatchInfo();
		MatchPopupUI.OnMatchCancel();
	end

	if msg == "load-game-fail!" then
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		local content = Client.GetTableData("LocalizeRes", "9911109").TextValue;
		CommonMessageBoxUI:ShowPanel(1, title, content, LobbySystem.onLoadServerFailed, nil);
	end
	--
	if msg == "version-not-support" then
		local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
		local content = Client.GetTableData("LocalizeRes", "9911112").TextValue;
		CommonMessageBoxUI:ShowPanel(1, title, content, LobbySystem.onLoadServerFailed, nil);
	end
end

function LobbySystem.onLoadServerFailed()
	-- body
	log("load server failed");
	LoadingUI.RefreshLoadPercent(1);
	Client.ReturnToLobby(GameFrontendHUD);
end

function LobbySystem.ShowMatchSuccess()
	MatchPopupUI.ShowMatchSuccess();
    -- 关闭其他面板
    LobbyUI:GotoGameHidePanels();
	TeamUpUI.ClearData();
    BP_LoadingTo = 1
	LoadingUI:Init();
    BP_LoadingTo = 0
    
	LobbySystem.SetWaitingBattleFlag(true);
end



function LobbySystem.on_remind_window_pop(title, content)
    log("on_remind_window_pop");
    CommonMessageBoxUI:ShowPanel(1, title, content);
end

local function LocalIsExternalChannel(menuid)
    if (menuid == 20003 or 
    menuid == 20004 or 
    menuid == 20005 or 
    menuid == 20007 or 
    menuid == 20010 or 
    menuid == 20013 or 
    menuid == 20014 or 
    menuid == 20016 ) and
    GlobalData:IsExternalChannel() then
        log("true!!!!!"..tostring(menuid))
        return true
    else
        return false
    end
end

-- 系统开关
function LobbySystem.on_fetch_label_switch_res(info)   
    --log_tree("on_fetch_label_switch_res", info); 
    
    LobbySystem.LobbyMenuOpenStatus = info
    
    -- 关闭聊天窗
    if LobbySystem.LobbyMenuOpenStatus[BP_ENUM_LOBBY_MENU_CHAT].is_open == 0 then
        LobbyChatSystem.canOpenChatWnd = false
    end
    
    -- 关闭活动按钮
    BP_ARRAY_Lobby_ActivityNotOpenList = {}
    for k,v in pairs(LobbySystem.LobbyMenuOpenStatus) do
        if LobbySystem.LobbyMenuOpenStatus[k].is_open == 0 or
        LocalIsExternalChannel(k) then
            table.insert(BP_ARRAY_Lobby_ActivityNotOpenList, k)
        end
    end
    --log_tree("BP_ARRAY_Lobby_ActivityNotOpenList ", BP_ARRAY_Lobby_ActivityNotOpenList)
end

function LobbySystem.on_modify_role_face_respond(ret)
    log("on_modify_role_face_respond")
    if (ret == "bad_param") then
        --PopUpNoticeUI.ShowNewNotice("购买失败，参数错误！");
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301270").TextValue);
    elseif (ret == "no enough gold or item") then
        --PopUpNoticeUI.ShowNewNotice("重置失败！金币不足。");
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301269").TextValue);
    elseif (ret == "ok") then
        --PopUpNoticeUI.ShowNewNotice("重置成功！");
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301268").TextValue);
        DataMgr.roleData.gender = BP_CreateRole_Sex;
        CreateRoleUI:BuyAvatarOK();
        LobbyUI:UpdatePlayer();
    end
end

-- 查询活动显示情况
function LobbySystem.QueryActivityDisplayStatus()
	log("QueryActivityDisplayStatus");
	NetUtil.SendPkg("get_activity_display_req");
end

local function LocalIfActivityShow(activityName)
    
    if activityName == "累计分享" and GlobalData:IsPlatformTourist() then
        return false
    end
        
    if activityName == "8天" and  EightDayUI.GetShowErrorCode() ~= 0 then
        return false
    end
    
    return true
end


function LobbySystem.on_get_activity_display_res(activity_display_table)
    --log_tree("on_get_activity_display_res", activity_display_table)
    BP_ARRAY_LobbyActivityBtnDisplayList = {}
    for k,v in pairs(activity_display_table) do
        local data = {}
        data.Priority = v.display
        data.ActivityName = v.activity_name
        data.IconPath = v.icon
        data.JumpUrl = v.jump
        
        if LocalIfActivityShow(data.ActivityName) then
            table.insert(BP_ARRAY_LobbyActivityBtnDisplayList, data)
        end
    end
    table.sort(BP_ARRAY_LobbyActivityBtnDisplayList, LobbySystem.SortActivityDisplayListFunc)
    --log_tree("BP_ARRAY_LobbyActivityBtnDisplayList ", BP_ARRAY_LobbyActivityBtnDisplayList)
    
    LuaClassObj.HandleUIMessage(bp_lobby, "InitActivityList");
end

function LobbySystem.SortActivityDisplayListFunc(a, b)
    return a.Priority < b.Priority
end
function LobbySystem.query_gm_respond(IsGmOpen)
	log("query_gm_respond = " .. tostring(IsGmOpen));
	DataMgr.IsGmOpen = IsGmOpen;
	LobbyUI.SetGmButton();
end


function LobbySystem.CheckDeviceType(CallBack)

	log("LobbySystem.CheckDeviceType NeedCheckDeviceLimit = " .. tostring(NeedCheckDeviceLimit));
	if (NeedCheckDeviceLimit == false) then
		CallBack();
		return;
	end


	log("CheckDeviceType BP_DeviceLimit = " .. tostring(BP_DeviceLimit));
	-- -1: refuse, 0: tips, 1: normal
    if (BP_DeviceLimit == -1) then
        LobbySystem.CheckDeviceLimitRefuse();
    else
    	CallBack();
    end
    
	if (BP_DeviceNameBeforeAuthLogin ~= nil) then
		log("BP_DeviceNameBeforeAuthLogin = " .. BP_DeviceNameBeforeAuthLogin);
	end
end

function LobbySystem.CheckDeviceTypeBak(CallBack)

	log("LobbySystem.CheckDeviceType NeedCheckDevice = " .. tostring(NeedCheckDevice));
	
	if (NeedCheckDevice == false) then
		CallBack();
		return;
	end
	
    
    if (BP_DeviceNameBeforeAuthLogin ~= nil) then
    	
    	BP_DeviceNameBeforeAuthLogin = LobbySystem.trim(BP_DeviceNameBeforeAuthLogin);

        log("BP_DeviceNameBeforeAuthLogin = " .. BP_DeviceNameBeforeAuthLogin);

        local listCount = #ValidDeviceList;
        local inList = false;

        if (listCount > 0) then
	        for i = 1, listCount, 1 do

	            local deviceName = ValidDeviceList[i];
	            
	            log("deviceName in check List " .. deviceName);
	            --log("string.lower(BP_DeviceNameBeforeAuthLogin) = " .. string.lower(BP_DeviceNameBeforeAuthLogin));
	            --log("string.lower(deviceName) = " .. string.lower(deviceName));
	            --local deviceMatch = string.match(string.lower(BP_DeviceNameBeforeAuthLogin), string.lower(deviceName));
				local deviceMatch = string.find(string.lower(BP_DeviceNameBeforeAuthLogin), string.lower(deviceName));
	            if (deviceMatch ~= nil) then
					log("inList = true");
	                inList = true;
	                break;
	            end
	        end 
	    end
        
        if (inList == true) then
            log("device is in deviceList");
            CallBack();
            --CommonMessageBoxUI:ShowPanel(1, "提示", "device is in deviceList", CheckNoticeBeforeAuthLogin, CheckNoticeBeforeAuthLogin);
        else
            log("device is not in deviceList");
            local function RefuseCallBack()
		        LuaClassObj.HandleUIMessage(bp_global, "quitGame");
		    end
		    local tips = DataMgr.GetMultiLineMsgByID(101716);
            CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, tips, RefuseCallBack, RefuseCallBack);
        end
    else
        log("BP_DeviceNameBeforeAuthLogin == nil");
        CallBack();
    end
end

function LobbySystem.CheckDeviceLimitRefuse()

	if (NeedCheckDeviceLimit == false) then
		return;
	end

	HasShowDeviceLimit = true;

	local function RefuseCallBack()
        LuaClassObj.HandleUIMessage(bp_global, "quitGame");
    end

	local tips = DataMgr.GetMultiLineMsgByID(101716);
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, tips, RefuseCallBack, RefuseCallBack);

end

function LobbySystem.CheckDeviceLimitTip()
	if (NeedCheckDeviceLimit == false) then
		return;
	end

	HasShowDeviceLimit = true;

	local tips = DataMgr.GetMultiLineMsgByID(101716);
	CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, tips);
	
end

function LobbySystem.CheckDeviceTip()

	if (NeedCheckDeviceLimit == false) then
		return;
	end

	if (HasShowDeviceLimit == true) then
		return;
	end

	log("BP_DeviceLimit = " .. tostring(BP_DeviceLimit));

	HasShowDeviceLimit = true;
	-- -1: refuse, 0: tips, 1: normal
	local tips = "";
	if (BP_DeviceLimit == 0) then
		log("BP_DeviceLimit == 0");
		tips = DataMgr.GetMultiLineMsgByID(101715);
		CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, tips);
	elseif (BP_DeviceLimit == -1) then
		log("BP_DeviceLimit == -1");
		tips = DataMgr.GetMultiLineMsgByID(101716);
		CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "101001").TextValue, tips);
	end
end

--[[网络回调]]--
s2c["please_create_role"] = LobbySystem.on_please_create_role;
s2c["sync_my_plat_name"]= LobbySystem.on_sync_my_plat_name;
s2c["create_role_respond"] = LobbySystem.on_create_role_respond;
s2c["sync_base_info"] = LobbySystem.on_sync_base_info;
s2c["sync_player_ban"] = LobbySystem.on_sync_player_ban;

s2c["re_match_sync"] = LobbySystem.on_reconnect_sync_matchInfo;
s2c["on_match_res"] = LobbySystem.on_start_match_rsp;
--s2c["on_match_cancel_req"] = LobbySystem.on_match_cancel_req;
s2c["get_activity_display_res"] = LobbySystem.on_get_activity_display_res;
s2c["on_match_cancel_res"] = LobbySystem.on_match_cancel_rsp;
s2c["on_match_success"] = LobbySystem.on_match_success;
--s2c["team_change_member_status_request"] = LobbySystem.change_status_req;

s2c["remind_window_pop"] = LobbySystem.on_remind_window_pop;
s2c["modify_role_face_respond"] = LobbySystem.on_modify_role_face_respond;
s2c["query_gm_respond"] = LobbySystem.query_gm_respond;

