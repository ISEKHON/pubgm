LoginUI = LoginUI or
{
	
}

--蓝图调用
BP_InputOpenId = ""

--服务器信息
BP_STRUCT_ServerInfo =
{
	addrArray = {},
	showAddrInfo = "",
    channelInfo = "",
    serverStatus = 0,
    tab = 0,
};

--服务器列表
BP_ARRAY_ServerList_Info =
{
	BP_STRUCT_ServerInfo = _G.BP_STRUCT_ServerInfo,
};

--当前选择的ServerInfo
BP_SelectedShowServerInfo = 0;

--注册Widget
function bp_login_RegisterUI()

    LoginUI.initServerList()

	LuaClassObj.SubUIWidgetList(bp_login,
		{
            {Path="/Game/UMG/UI_BP/Login/Login_ServerList_UIBP.Login_ServerList_UIBP_C", Container="Default", ZOrder=0}
        },
		{"Login"},
		false,
		false
	);
end

function LoginUI.initServerList()
	local LOGIN_SERVER_LIST = {
	};

	table.insert(LOGIN_SERVER_LIST, {channelInfo = "iGame", name = "FB测试服", addr = {"tcp://101.227.130.125:14014"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "iGame", name = "iGame主干", addr = {"tcp://101.226.129.164:14001"}, status = 0, tab =0});	
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "测试专用", name = "测试1服", addr = {"tcp://101.227.139.182:10001"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "测试专用", name = "测试2服", addr = {"tcp://101.227.139.182:10002"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "测试专用", name = "测试3服", addr = {"tcp://117.144.243.183:10013"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "iGame", name = "iGame正式服", addr = {"tcp://lobby.igamecj.com:17500"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "北美测试服", name = "北美测试一服", addr = {"tcp://ig-us-test1.igamecj.com:17500"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "北美测试服", name = "北美测试二服", addr = {"tcp://ig-us-test2.igamecj.com:17500"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "北美预发布", name = "北美预发布服", addr = {"tcp://ig-us-pre.igamecj.com:17500"}, status = 0, tab =0});
	table.insert(LOGIN_SERVER_LIST, {channelInfo = "北美提审服", name = "北美提审服", addr = {"tcp://apple.igamecj.com:17500"}, status = 0, tab =0});
     table.insert(LOGIN_SERVER_LIST, {channelInfo = "iGame", name = "gpc", addr = {"tcp://180.163.15.191:10012"}, status = 0, tab =0});

	BP_ARRAY_ServerList_Info = {};

	for index=1, #LOGIN_SERVER_LIST do
		local serverObj = LOGIN_SERVER_LIST[index];

		local BP_ServerObj = {};
		BP_ServerObj.showAddrInfo = (serverObj.name);
		BP_ServerObj.addrArray = serverObj.addr;
		BP_ServerObj.serverStatus = serverObj.status;
		BP_ServerObj.channelInfo = serverObj.channelInfo;
		BP_ServerObj.tab = serverObj.tab;
		table.insert(BP_ARRAY_ServerList_Info,BP_ServerObj);
	end
	--备用IP
	--移动
	--LoginUI.backup_ip_list_CMCC = {"tcp://183.192.199.48:17500", "tcp://183.192.199.63:17500"};
	--联通
	--LoginUI.backup_ip_list_WCDMA = {"tcp://223.167.104.59:17500","tcp://223.167.105.81:17500"};
	--电信
	--LoginUI.backup_ip_list_CDMA = {"tcp://61.151.186.58:17500", "tcp://180.163.26.85:17500"};
	--国内CAP(除了三大运营商其他所有小运营商的集合)
	--LoginUI.backup_ip_list_CAP = {"tcp://182.254.74.196", "tcp://182.254.74.197:17500"};
	--香港海外
	--LoginUI.backup_ip_list_OVERSEA = {"tcp://203.205.128.17:17500", "tcp://203.205.147.186:17500"};

end

function EventFetchInfo()

end

--点击登录
function EventConnectToGate()
	if BP_InputOpenId ~= nil and BP_InputOpenId ~= "" then
		--设置登录帐号
		log("InputOpenId = " .. BP_InputOpenId)
		Client.InitLoginAccount(NetInterface, BP_InputOpenId);
	end

	local _addrArray = {};
	local _addrID = 0;
	if LoginSystem.isDirectConnect == false then
	for i=1, #BP_ARRAY_ServerList_Info do
		if i == (BP_SelectedShowServerInfo + 1) then
			_addrArray = BP_ARRAY_ServerList_Info[i].addrArray;
			_addrID = i;
			break;
		end
	end
	else
		--local channel = Client.GetLoginChannel(NetInterface);
		local serverInfo = LoginSystem.direct_login_server_list;
		if serverInfo ~= nil then
			
			--local _telecomSvrName = Client.GetTelecomSvr();
			--local _addrBackupArray = {};

			--if(_telecomSvrName == "ChinaMobile") then
			--	_addrBackupArray = LoginUI.backup_ip_list_CMCC;
			--elseif(_telecomSvrName == "ChinaUnicom") then
			--	_addrBackupArray = LoginUI.backup_ip_list_WCDMA;
			--elseif(_telecomSvrName == "ChinaTelecom") then
			--	_addrBackupArray = LoginUI.backup_ip_list_CDMA;
			--elseif(_telecomSvrName == "Unknown") then
			--	_addrBackupArray = LoginUI.backup_ip_list_OVERSEA;
			--else
			--	_addrBackupArray = LoginUI.backup_ip_list_CAP;
			--end

			--if(_addrBackupArray~=nil and (#_addrBackupArray>0)) then
			--	_addrArray = FuncUtil.TableConcat(serverInfo.addr, _addrBackupArray)
			--else
				_addrArray = serverInfo.addr;
			--end
		end
	end
	if _addrArray~=nil and (#_addrArray > 0) then
		LoginSystem.connectGateway(_addrArray, _addrID);
	else
		log("not selected addr info！");
	end
end

--隐藏选区
function EventShowScrollView()
	log("EventShowScrollView");
	LuaClassObj.HandleUIMessage(bp_login, "ShowScrollView");
end

--隐藏选区
function EventHideScrollView()
	log("EventHideScrollView");
	LuaClassObj.HandleUIMessage(bp_login, "HideScrollView");
end

--显示当前选区
function EventShowCurrentSelect()
	log("EventShowCurrentSelect");
	LuaClassObj.HandleUIMessage(bp_login, "ShowCurrentSelect");
end

--点击测试UMG
function EventOpenExampleUI()
	log("EventOpenExampleUI");
	LuaClassObj.HandleUIMessage(bp_test_entrance, "showUI");
end

--注销帐号
function EventLogout()
	log("EventLogout");
	Client.Logout(NetInterface);
end

function bp_login_OnModeSwitched(gamestatus)
	log("bp_login_OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "login" then
		--显示UI
        LuaClassObj.HandleUIMessage(bp_login, "UIHide");
        LuaClassObj.HandleUIMessage(bp_authorization, "showAuthorizationUI");
	end
end

function bp_login_OnModeAboutToSwitched()
end


-- 打开语言设置
function EventEnterLanguageSetting()
	log("enter language setting ui");
    SettingLanguageUI.ShowUIInLoginPanel();
end