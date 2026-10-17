
GlobalData = GlobalData or 
{
}


BP_Platform = 0;
--是否播放过CG
BP_played_cg = 0;
--跳转url
BP_Global_Url = "";
--禁止聊天
BP_ChatBan = 0;
--启动类型 0:正常 1:手Q游戏中心 2:微信游戏中心
BP_StartUpType = 0;
--是否外部服务器(包括苹果审核服和外发服) 平台特权专用，其他地方切勿使用
BP_IsAppleAudit = false;

BP_GlobalTips_ItemID =0;

--手动输入状态下，输入点击位置或者按钮位置，panel再计算摆放
BP_STRUCT_GlobalTips_Pos = { x = 0,y = 0}

--物品限时信息
BP_STRUCT_GlobalTips_TimeInfo = {is_limit = false, time_s = ""}

BP_String_ServerTime = "";

BP_HadPlayAnimation = false

-- 是否提审
BP_IOS_CHECK = false;

-- 是否是外发渠道
BP_IS_EXTERNAL_CHANNEL = false;
function bp_global_RegisterUI()
    
	LuaClassObj.SubUIWidgetList(bp_global,
		{{Path="/Game/UMG/UI_Logic/Global_Bp.Global_Bp_C", Container="Default", ZOrder=0}},
		{"Lobby","Login"},
		true,
		true
	);	
end

function bp_global_OnModeSwitched(gamestatus)
	log("bp_global OnModeSwitched gamestatus = " .. gamestatus);
    -- 进入战斗场景成功关闭之前的背景音乐
    if string.lower(gamestatus) == "fighting" then
        LuaClassObj.HandleUIMessage(bp_global, "EnterFightStopMusic");	
    elseif string.lower(gamestatus) == "login" then

    elseif string.lower(gamestatus) == "lobby" then
	end
end

function bp_createrole_OnModeAboutToSwitched()
end

function GlobalData:SetPlatform(platform)
	BP_Platform = platform;
	log("SetPlatform "..BP_Platform);

    GlobalData:HideWidgetsByTourist()
end



function GlobalData:GetPlatform()
	return BP_Platform ;
end


function GlobalData:SetStartUpType(iType)
	BP_StartUpType = iType;
	log("SetStartUpType "..BP_StartUpType);
end

function GlobalData:SetIsAppleAudit(bValue)
	if bValue == true then
		BP_IsAppleAudit = bValue;
	elseif BP_IOS_CHECK == true then
		BP_IsAppleAudit = BP_IOS_CHECK;
	else
		BP_IsAppleAudit = BP_IS_EXTERNAL_CHANNEL;
	end
	log("SetIsAppleAudit "..tostring(BP_IsAppleAudit));
end

function EventSetInfo_Push()
end

function EventFetchInfo()
	-- 需要时时获取的变量，赋值逻辑写在这里
end

local lastUpdate = 0;
function EventUpdateServerTime( ... )
    local cur = FuncUtil.GetServerTimeInSec();
    if math.abs(cur - lastUpdate) >= 1 then
        lastUpdate = cur;
        BP_String_ServerTime = os.date("%Y-%m-%d %H:%M:%S", cur);
    end
end

function EventSetPlayedCG()
    BP_played_cg = 1;
end

--跳转url
--以game://打头，为游戏内跳转，参考格式为game://?module=1000100&{参数1}=1&{参数2}=2
--其他方式，如http://，为网页跳转，参考格式为http://pg.qq.com?{参数1}=1&{参数2}=2
function EventJumpUrl()
	if string.starts(BP_Global_Url, "game://") then
		local params = FuncUtil:ParseURLParams(BP_Global_Url);
		local moduleId = tonumber(params["module"]);
		EventSystem:postEvent(EVENTTYPE_URL, moduleId, params);
	else
		Client.OpenURL(BP_Global_Url);
	end
end
function GlobalData:JumpUrl(url)
	BP_Global_Url = url;
	EventJumpUrl();
end

--安卓点击返回键退出游戏
function EventAndroidQuitGame()
    local function clickOkCallback()
        LuaClassObj.HandleUIMessage(bp_global, "quitGame");
    end
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
    --CommonMessageBoxUI:ShowPanel(2, "提示", "您确定要退出游戏？", clickOkCallback, nil)
    CommonMessageBoxUI:ShowPanel(2, title, Client.GetTableData("LocalizeRes", "301168").TextValue, clickOkCallback, nil)
end

function EventChatCheckBan()
    log("EventChatCheckBan");
    BP_ChatBan = 0;
    if(DataMgr.ban ~= nil) then
        if(DataMgr.ban[2] ~= nil and type(DataMgr.ban[2]) == "table") then
            BP_ChatBan = 1;
        end
    end
    log("EventChatCheckBan = "..BP_ChatBan);
end

function EventChatBanInfo()
    log("EventChatBanInfo");
    if(DataMgr.ban ~= nil) then
        if(DataMgr.ban[2] ~= nil and type(DataMgr.ban[2]) == "table") then
            local time = DataMgr.ban[2].end_time;
            local reason = DataMgr.ban[2].reason;
            --local date = os.date("%Y年%m月%d日%H时%M分%S秒", time);
            --CommonMessageBoxUI:ShowPanel(1, "提示", reason.."\n解封时间为: "..date);
			local title = Client.GetTableData("LocalizeRes", "101001").TextValue
			local date = os.date(Client.GetTableData("LocalizeRes", "115005").TextValue, time);
			local str = string.format(Client.GetTableData("LocalizeRes",301129).TextValue, date);
			CommonMessageBoxUI:ShowPanel(1, title, reason..str);
        end
    end
end

function OnApplicationDeactivated()
	log("OnApplicationDeactivated");
	
	GlobalChatVoice.OnApplicationDeactivated();
	MatchPopupUI.OnApplicationDeactive();
end

function OnApplicationReactivated()
	log("OnApplicationReactivated");
	
	GlobalChatVoice.OnApplicationReactivated();
	MatchPopupUI.OnApplicationReactive();
end


function OnApplicationEnterBackground()
	log("OnApplicationEnterBackground");
	
	--GlobalChatVoice.OnApplicationDeactivated();
end

function OnApplicationEnterForeground()
	log("OnApplicationEnterForeground");
end

function OnApplicationWillTerminate()
	log("OnApplicationWillTerminate");
end

-- 经分接口 ---
BP_BA_BUTTON_TYPE = 1
BP_BA_REASON = 1

function EventSendBAReport()
    ClientSendBAReport(BP_BA_BUTTON_TYPE, BP_BA_REASON)
end

function ClientSendBAReport(button_type, reason)
    log("button_click_log"..tostring(button_type)..tostring(reason))
    NetUtil.SendPkg("button_click_log", button_type, reason);
end

function  EventGlobalShowItemTips_Push()
    CommonItemTipsUI:SetPanelTimeInfo(BP_STRUCT_GlobalTips_TimeInfo)
    CommonItemTipsUI:ShowPanel(BP_GlobalTips_ItemID,BP_STRUCT_GlobalTips_Pos)
end

function  EventGlobalCloseItemTips()
	CommonItemTipsUI:ClosePanel()
end

function EventShowPlatQQStartup()
	LobbyPlatformUI.ShowQQRightPanel();
end

function EventShowPlatQQVip()
	local roleId = tostring(DataMgr.roleData.uid);
	local baseURL = "https://mq.vip.qq.com/m/game/vipembed?sRoleId="..roleId.."&sPartition=1&sPfkey=pfkey"
	log("Open QQVip Url="..baseURL);
	Client.OpenURL(baseURL);
end

function EventShowPlatWXStartup()
	LobbyPlatformUI.ShowWXRightPanel();
end

function EventShowPlatIconTips()
	if BP_Platform == BP_ENUM_PLAYFORM_WX then
		ShowNotice(660011)
	end
end

-- 系统开关
BP_CHECK_MENU_OPEN_ID = 0
BP_CHECK_MENU_OPEN_RESULT = false

function EventCheckIfMenuOpen()

    if LobbySystem.LobbyMenuOpenStatus[BP_CHECK_MENU_OPEN_ID] == nil then
        BP_CHECK_MENU_OPEN_RESULT = true
        return
    end

    if LobbySystem.LobbyMenuOpenStatus[tonumber(BP_CHECK_MENU_OPEN_ID)].is_open == 0 then
        BP_CHECK_MENU_OPEN_RESULT = false
    else 
        BP_CHECK_MENU_OPEN_RESULT = true
    end
    
end

-- 是否IOS审核
function GlobalData:IsIOSCheck()
    return BP_IOS_CHECK
end

-- 是否游客登录
function GlobalData:IsPlatformTourist()
    return BP_Platform == BP_ENUM_PLAYFORM_TOURIST
end

-- 是否外发渠道
function GlobalData:IsExternalChannel()
    return BP_IS_EXTERNAL_CHANNEL;
end

-- 游客模式开关
function GlobalData:HideWidgetsByTourist()
    if not GlobalData:IsPlatformTourist() then
        return
    end
    
    LuaClassObj.SubCollapseWidgetList(bp_roleinfo,
        "RoleInfo_BP_C",
		{
			"Canvas_QQStartup",
            "Canvas_QQVip",
            "Overlay_TipsFather",
            "HorizontalBox_9",
            "Overlay_RealNameFather",
		}
	);
    
    LuaClassObj.SubCollapseWidgetList(bp_teamup_friend,
        "Lobby_InviteFriendLogic_BP_C",
        {
            "WidgetSwitcher_WXorQQ",
            "Overlay_OfflineShareFather",
        }
    );
    
    LuaClassObj.SubCollapseWidgetList(bp_alliance,
        "LobbyTeamMain_LogicBP_C",
		{
			"PlatformGroupBtns",
		}
    );
    
    LuaClassObj.SubCollapseWidgetList(bp_battleresult,
        "ResultsRanking_BP_C",
		{
			"Overlay_ShareBtn",
            "FlauntBox",
            "Overlay_ShareTips",
		}
    );
    
    LuaClassObj.SubCollapseWidgetList(bp_good_item_get_panel,
        "Good_Item_Get_BP_C",
		{
			"Overlay_Sharebtn",
            "Overlay_GridTips",
            
		}
    );
    
    LuaClassObj.SubCollapseWidgetList(bp_levelup,
        "LevelUp_LogicBP_C",
		{
			"Overlay_ShareRankFather",
            "CanvasPanel_RankTipsGroupFather",  
            "CanvasPanel_LevelTipsGroupFather",
            "Overlay_levelbtnshowfather",
		}
    );
    -- Now we only have one customer mode, show up the btn
    --[[
    LuaClassObj.SubCollapseWidgetList(bp_setting,
        "Setting_UIBP_C",
        {
            "Overlay_CustomerServiceFather",
        }
    );
    --]]
end