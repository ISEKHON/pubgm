-- 大厅UI
LobbyUI = LobbyUI or 
{
}

--玩家个人信息
BP_PlayerName = "";
BP_PlayerLevel = 1;
BP_PlayerGold = 0;
BP_PlayerExp = 0;
BP_PlayerUid = ""
BP_PlayerGender = 1
BP_PlayerIconUrl = ""
BP_Lobby_PlayerMaxRankLevel = 0
BP_PlayerQQVip = 0;
BP_Lobby_Role_Avatar_Frame = 0

--大厅组队信息
BP_LobbyPlayerNum = 0;

--大厅状态
BP_LobbyNetworkDelay = 0
BP_LobbyNetworkStatus = true
BP_CurrentMenuId = 0
BP_CurrentRedPointStatus = false
BP_LevelChange = false
BP_Lobby_RankChange = false
BP_CurrentMaxExp = 0
BP_Lobby_OpenShoporWardrobe = false
BP_Exciting_Party_Open = false  -- 刺激盛宴是否开启

BP_COLLECT_EQUIPMENT_Open = false --收集装备活动是否开启
BP_Free_Data_Open = false -- 免流状态 
BP_XinyueRedPointSvrOpen = false -- 心悦红点状态
BP_FriendApplyMessageCount = 0 --好友申请消息条数

-- 创建模型信息
BP_STRUCT_SpawnPlayerData =
{
    gid = "",
    sex = 1,
    headId = 401999,
    index = 1,
    BP_ARRAY_AvatarList = {
        401999
    }
}

-- 位置占用结构
BP_STRUCT_TransformUseList = 
{
    index = 1,
    inUse = false,
}

-- avatar变更信息
BP_STRUCT_AvatarChange = 
{
    gid = "",
    resId = 403000,
}

-- 光圈信息
BP_STRUCT_TeamUpRingsChange = 
{
    teamMemberNum = 4,
    BP_ARRAY_CurrentTeamMemberGidList = {"1"}
}

-- 初始化标签
DataMgrInit = false
LobbyModeSwitched = false
EmulatorCheck_FirstinLobby = true

-- 组队玩家信息列表
BP_ARRAY_LobbyPlayerDataList =
{
    BP_STRUCT_SpawnPlayerData = _G.BP_STRUCT_SpawnPlayerData, 
}

BP_STRUCT_ShopLimit = {
    Title = "",
    EndTime = "",
}

BP_STRUCT_ActivityBtnDisplay = {
    Priority = 1,
    ActivityName = "",
    IconPath = "",
    JumpUrl = "",
}

BP_ARRAY_LobbyActivityBtnDisplayList =
{
    BP_STRUCT_ActivityBtnDisplay = _G.BP_STRUCT_ActivityBtnDisplay, 
}

--注册Widget
function bp_lobby_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_lobby,
    {{Path="/Game/UMG/UI_Logic/Lobby/Lobby_Logic_BP.Lobby_Logic_BP_C", Container="Default", ZOrder=0}},
    {"Lobby"},
	false,
	bp_lobby_OnModeSwitched ~= nil
  );

    FaceSlapSystem.Init();
end

--跳转到Lobby
function bp_lobby_OnModeSwitched(gamestatus)
	log("OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
        LoadingUI.RefreshLoadPercent(1)
        log("gavin OnModeSwitched          in lobby!!!");
		--显示LobbyUI
		LuaClassObj.HandleUIMessage(bp_lobby, "UIShow")
        
        --设置定时器
        LuaClassObj.HandleUIMessage(bp_lobby, "RefreshTimer")
        
        --设置电量及网络状态
        LuaClassObj.HandleUIMessage(bp_lobby, "UpdateBattery")
        LuaClassObj.HandleUIMessage(bp_lobby, "UpdateNetworkStatus")
        -- 察看刺激盛宴是否开启
        LuaClassObj.HandleUIMessage(bp_lobby, "UpdateExcitingPartyBtnState") 


        LuaClassObj.HandleUIMessage(bp_lobby, "InitialTranform")
        
        LobbyModeSwitched = true
        
        if (DataMgrInit)
        then
            LobbyUI:InitPlayerData()
            LobbyUI:CreateMyself()
        end
        ScrollNoticeSystem.Enter()
        LoginSystem.CheckWakeupDataForTeamup()
		UpdateLobbyTaskRedDot(TaskUI.GetTaskRedDot())
        LuaClassObj.HandleUIMessage(bp_lobby, "InitXinyueRedPoint")      
        LuaClassObj.HandleUIMessage(bp_lobby, "UpdateHuatiRedPoint")
        LuaClassObj.HandleUIMessage(bp_lobby, "UpdateCollectEquipRedPoint")  

        local is_lobby_show_red = ActivitySystem.HasActBtnRedPoint()
        UpdateLobbyActivityRedPoint(is_lobby_show_red) 
		
		LobbyChatEntranceUI.SetIsRoomMode(false);
        LobbyUI.SetGmButton();

        -- -1: refuse, 0: tips, 1: normal
        if (HasShowDeviceLimit == false) then
            LobbySystem.CheckDeviceTip();
        end
		
		if EmulatorCheck_FirstinLobby then
            local isEmulator = Client.IsEmulator();
            
            if isEmulator then
                local title = Client.GetTableData("LocalizeRes", 101001).TextValue;
                local tips = Client.GetTableData("LocalizeRes", 4051).TextValue;
                CommonMessageBoxUI:ShowPanel(1, title, tips);
                EmulatorCheck_FirstinLobby = false
            end
        end
	end
    
    -- 回到登录场景清数据
    if string.lower(gamestatus) == "login" then
        LobbyUI:ReleaseData()
    end
    
end

function LobbyUI.SetGmButton()
     log("DataMgr.IsGmOpen = " .. tostring(DataMgr.IsGmOpen));
    if (DataMgr.IsGmOpen == true) then
        LuaClassObj.HandleUIMessage(bp_lobby, "ShowGmButton")
    else
        LuaClassObj.HandleUIMessage(bp_lobby, "HideGmButton")
    end
end

function EventFetchInfo()
	
end

-- 更新网络延迟
function LobbyUI:UpdateNetworkDelay()
    LuaClassObj.HandleUIMessage(bp_lobby, "UpdateNetworkStatus")
end

function bp_lobby_OnModeAboutToSwitched()
    log("OnModeAboutToSwitched gamestatus = lobby");
end

local function lobbyEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_LOBBY then
		return;
	end

	if eventID == EVENTID_ENTERLOBBY then
		log("enter lobby!");
		if LuaClassObj ~= nil then
            
			LuaClassObj.HandleUIMessage(bp_global, "EnterLobby");
		end
	end
end

local function CheckIfOpenRankUpPanel()
    -- 在大厅中时不弹出段位升级面板
    if string.lower(LuaClassObj.GetGameStatus(bp_lobby)) == "lobby" then
        return
        --[[BP_Lobby_RankChange = true
        LevelUpUI:Init()
        BP_Lobby_RankChange = false]]
    else
        BP_Lobby_RankChange = true
    end
end

-- 玩家属性变更
local function PlayerDataChange(eventType, eventID, vars)
    log("PlayerDataChange "..eventType)
	if eventType ~= EVENTTYPE_DATA_MGR then
		return;
	end
    
    -- 更新大厅显示数据
    LobbyUI:RefreshPlayerData()
    
	if eventID == EVENTID_DATAMGR_GOLD_CHANGE then
		log("EVENTID_DATAMGR_GOLD_CHANGE");
		
    elseif eventID == EVENTID_DATAMGR_ROLE_LEVEL_CHANGE then
        log("EVENTID_DATAMGR_ROLE_LEVEL_CHANGE");
        
        -- 在大厅中时弹出军衔升级面板
        if string.lower(LuaClassObj.GetGameStatus(bp_lobby)) == "lobby" then
            log("remm levelup lobby direct popup")
            BP_LevelChange = true
            LevelUpUI:Init()
            BP_LevelChange = false
        else
            log("remm levelup lobby BP_LevelChange true")
            BP_LevelChange = true
        end

    elseif eventID == EVENTID_DATAMGR_ROLE_EXP_CHANGE then
        log("EVENTID_DATAMGR_ROLE_EXP_CHANGE");

    elseif eventID == EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE then
        log("EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE");
        --BP_LevelUp_RankTypeName = "单人模式"
	BP_LevelUp_RankTypeName = Client.GetTableData("LocalizeRes", "110049").TextValue
        BP_LevelUp_RankType = 1
        CheckIfOpenRankUpPanel()

    elseif eventID == EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE then
        log("EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE");
        --BP_LevelUp_RankTypeName = "双人模式"
	BP_LevelUp_RankTypeName = Client.GetTableData("LocalizeRes", "110050").TextValue
        BP_LevelUp_RankType = 2
        CheckIfOpenRankUpPanel()
        
    elseif eventID == EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE then
        log("EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE");
        --BP_LevelUp_RankTypeName = "四人模式"
	BP_LevelUp_RankTypeName = Client.GetTableData("LocalizeRes", "110051").TextValue
        BP_LevelUp_RankType = 4
        CheckIfOpenRankUpPanel()
	end
end

-- 登出、重连返回登录清除数据
local function ReleaseAllData(eventType, eventID, vars)
    log("ReleaseAllData "..eventType)
	if eventType ~= EVENTTYPE_LOGIN then
		return;
	end

	if eventID == EVENTID_BACKLOGIN then
		log("ReleaseAllData");
        LobbyUI:ReleaseData()
        
        -- 免流没有bp，在这里处理
        FreeDataStreamMgr:ClearFreeDataStatus() 
	end
end

-- 清除数据
function LobbyUI:ReleaseData()
    log("lobby release data")
    DataMgr.ResetData()
    LobbySystem.currentLobbyPlayerDataList = {}
    BP_LobbyPlayerNum = 0;
    BP_LobbyNetworkStatus = true
    BP_LevelChange = false
    BP_Lobby_RankChange = false
    --DataMgrInit = false
    LobbyModeSwitched = false
    ScrollNoticeUI:BackLoginReleaseData()
    FaceSlapSystem.Reset();
    LuaClassObj.HandleUIMessage(bp_lobby, "ReleaseData")
end

function LobbyUI:Init()
	log("lobby init");
	--LobbyUI:InitPlayerData()
	EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_ENTERLOBBY, lobbyEventHandler);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, PlayerDataChange);	
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_EXP_CHANGE, PlayerDataChange);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, PlayerDataChange);
    EventSystem:registEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, ReleaseAllData);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE, PlayerDataChange);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE, PlayerDataChange);
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE, PlayerDataChange);
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_LOBBY, LobbyUI.CloseOtherMenu);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, LobbyUI.WardRobeAvatarResetOpen);
    EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, LobbyUI.WardRobeAvatarResetClose);
    
    --- 活动跳转
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_EXCITING_FEAST, LobbyUI.OnOpenExcitingFeast)
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_COLLECT_EQUIPMENT, LobbyUI.OnOpenCollectEquipment)
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_FRONTIER_AWARD, LobbyUI.OnOpenFrontierAward)
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHARE_AWARD, LobbyUI.OnOpenShareAward)
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_OPENSERVICE_CARNIVAL, LobbyUI.OnOpenCarnival)
    
    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CR, LobbyUI.UpdateActivityBtnList)
end

function LobbyUI:Release()
	log("lobby release");
	EventSystem:unregistEvent(EVENTTYPE_LOBBY, EVENTID_ENTERLOBBY, lobbyEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_EXP_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, ReleaseAllData);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE, PlayerDataChange);
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_LOBBY, LobbyUI.CloseOtherMenu);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN, LobbyUI.WardRobeAvatarResetOpen);
    EventSystem:unregistEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE, LobbyUI.WardRobeAvatarResetClose);
    
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_EXCITING_FEAST, LobbyUI.OnOpenExcitingFeast)
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_COLLECT_EQUIPMENT, LobbyUI.OnOpenCollectEquipment)
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_FRONTIER_AWARD, LobbyUI.OnOpenFrontierAward)
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_SHARE_AWARD, LobbyUI.OnOpenShareAward)
    EventSystem:unregistEvent(EVENTTYPE_URL, BP_ENUM_MODULE_OPENSERVICE_CARNIVAL, LobbyUI.OnOpenCarnival)
    
    EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CR, LobbyUI.UpdateActivityBtnList)
end

-- 更新玩家数据
function LobbyUI:RefreshPlayerData()
    BP_PlayerName = DataMgr.roleData.nickName;
	BP_PlayerLevel = DataMgr.roleData.level;	
    BP_PlayerGold = DataMgr.gold;
    BP_PlayerExp = DataMgr.roleData.roleExp;
    BP_PlayerUid = DataMgr.roleData.uid
    BP_PlayerGender = DataMgr.avatarData.gamegender
    BP_PlayerIconUrl = DataMgr.roleData.headIconUrl
    BP_Lobby_PlayerMaxRankLevel = DataMgr.GetMaxRankLevel()
	BP_PlayerQQVip = DataMgr.roleData.qq_vip
    BP_Lobby_Role_Avatar_Frame = DataMgr.roleData.cur_avatar_box_id
    log("remm RefreshPlayerData".. BP_PlayerName .." " .. BP_PlayerGold .. " " .. BP_PlayerExp.."max rank ".. BP_Lobby_PlayerMaxRankLevel)    
    LuaClassObj.HandleUIMessage(bp_lobby, "InitPlayerData")
	LuaClassObj.HandleUIMessage(bp_lobby, "UpdatePlatformRight")
end

-- 初始化大厅UI显示数据
function LobbyUI:InitPlayerData()
    log("lobby initPlayerData")
    LobbySystem.currentLobbyPlayerDataList = {}
    BP_LobbyPlayerNum = 0
    
    LobbyUI:RefreshPlayerData()
end

-- 创建自己的模型
function LobbyUI:CreateMyself()
    local rolewear = {}
    WardrobeSystem.UpdateInvalidWearInfo(nil);

    for k,v in pairs(DataMgr.rolewear) do
        if (DataMgr.GetHallDepotItemDataByInsID(v) ~= nil) then
            table.insert(rolewear, DataMgr.GetHallDepotItemDataByInsID(v).resID)	
        end
	end
    --log_tree("remmm create avatar inst id", DataMgr.rolewear)
    --log_tree("remmm create avatar", rolewear)
    
    local avatarSt = {
        gamegender = DataMgr.avatarData.gamegender,
        headid = DataMgr.avatarData.headid,
        hairid = DataMgr.avatarData.hairid
    }

    local playerData =
    {
        gid = tostring(DataMgr.roleData.uid),
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = rolewear
    }
    
    LobbyUI:SpawnPlayer(playerData, true)

end

function LobbyUI.CloseOtherMenu()
    LuaClassObj.HandleUIMessage(bp_lobby, "CloseOtherMenu")
    EventTaskHideUI()
end

function LobbyUI:WardRobeAvatarResetOpen()
    log("WardRobeAvatarResetOpen")
    LuaClassObj.HandleUIMessage(bp_lobby, "UIHide");
	LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIHide")
end

function LobbyUI:WardRobeAvatarResetClose()
    log("WardRobeAvatarResetClose")
    if WardrobeUI.saveIsShowing then
        LuaClassObj.HandleUIMessage(bp_lobby, "UIShowFromAvatarReset");
        CreateRoleUI.OnOpenWardRobe();
        --LuaClassObj.HandleUIMessage(bp_createrole, "UIShowResetAvatar");
    end
    
end

--点击按钮请求进入房间
function EventEnterRoom()
	log("enter room");
	--RoomUI:Init();
	--RoomSystem.Enter();
	--LobbySystem.on_start_match_req(TeamUp_Team_Type);
end

--点击按钮进入商城
function EventEnterShop()
	log("enter Shop");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_SHOP) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
	if ShopUI.isShow == false then
        BP_Lobby_OpenShoporWardrobe = true
		LuaClassObj.HandleUIMessage(bp_lobby, "CloseOtherMenu")
        BP_Lobby_OpenShoporWardrobe = false
	end
	ShopUI.Init();
	ShopSystem.Enter();
    
    ClientSendBAReport(BP_BA_LOBBY_SHOP_PANEL, 0);
end
-- 进入车队
function EventLobbyEnterAlliance()
    log("EventLobbyEnterAlliance")
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_ALLIANCE) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    
    AllianceSystem.OpenAllianceUI()
    
    ClientSendBAReport(BP_BA_LOBBY_ALLIANCE_PANEL, 0);
end
--点击进入邮件系统
function EventEnterMail()
	log("Enter Mail");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_MAIL) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
	MailSystem.Enter();
	MailUI.Init();
    
    ClientSendBAReport(BP_BA_LOBBY_MAIL_PANEL, 0);
end

--点击进入赛季系统
function EventEnterSeason()
    log("Enter Season");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_SEASON) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    
    SeasonUI.Show();
    
    ClientSendBAReport(BP_BA_LOBBY_SEASON_PANEL, 0);
end

BP_RankSavedChoosingZoneId = 0
function EventRankSavedChoosingZoneId_Push()
BP_Back_ShowRankZoneId = BP_RankSavedChoosingZoneId
log("EventRankSavedChoosingZoneId_Push:BP_Back_ShowRankZoneId = "..BP_Back_ShowRankZoneId)
end
--点击进入排行榜系统
function EventEnterRank()
	log("Enter Rank");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_RANK) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
	RankSystem.Enter();
	RankUI.Init();
    
    ClientSendBAReport(BP_BA_LOBBY_RANK_PANEL, 0);
end

--点击按钮进入仓库
function EventEnterWardrobe()
	log("enter Wardrobe" .. tostring(WardrobeUI.isShowing ));
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_WARDROBE) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    if WardrobeUI.isShowing == false then
        BP_Lobby_OpenShoporWardrobe = true
		LuaClassObj.HandleUIMessage(bp_lobby, "CloseOtherMenu")
        BP_Lobby_OpenShoporWardrobe = false
	end
    WardrobeSystem.Enter();
    
    ClientSendBAReport(BP_BA_LOBBY_WARDROBE_PANEL, 0);
end

function EventOpenChatUI()
	log("open chat ui");
	LobbyChatLogic.Init();	
end

-- 点击进入好友系统
function EventEnterFriendList()
    log("friend list open");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_FRIEND) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    LobbyFriendUI:Init();
    LobbyFriendUI:Show();
    
    ClientSendBAReport(BP_BA_LOBBY_FRIEND_PANEL, 0);
end

-- 打开设置
function EventEnterConfig()
	log("enter setting ui");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_SETTING) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    SettingUI:Init();
    
    ClientSendBAReport(BP_BA_LOBBY_SETTING_PANEL, 0);
end

--世界观弹窗
function EventOpenWorldView()
	log("Enter OpenWorldView");
	if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_WORLDVIEW) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    PopUpNoticeUI.ShowMessageBox(LongTxt.WorldView_Title, LongTxt.WorldView_Content);
    
    ClientSendBAReport(BP_BA_LOBBY_WORLDVIEW_PANEL, 0);
end

function EventOpenGuidePanel()
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_HELP) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    GuideUI:Show()
    
    ClientSendBAReport(BP_BA_LOBBY_GUIDE_PANEL, 0);
end

BP_Lobby_IsActivityOpened = true;
function EventIsActivityOpened()
	if LobbySystem.LobbyMenuOpenStatus[BP_ENUM_LOBBY_MENU_ACTIVITY] == nil then
        BP_Lobby_IsActivityOpened = true;
    end
    
    if LobbySystem.LobbyMenuOpenStatus[BP_ENUM_LOBBY_MENU_ACTIVITY].is_open == 0 then        
        BP_Lobby_IsActivityOpened = false;
    else 
        BP_Lobby_IsActivityOpened = true;
    end
	
	log("[HHF]BP_Lobby_IsActivityOpened = " .. tostring(BP_Lobby_IsActivityOpened));
end

function EventOpenActivityPanel()
    log("Enter Activity");
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_ACTIVITY) then
        BP_Lobby_MenuOpen = false
        return
    end
    log("open!!!!!!!!")
    BP_Lobby_MenuOpen = true
    LuaClassObj.HandleDynamicCreation(bp_activty);
    LuaClassObj.HandleUIMessage(bp_activty, "TryToShowActivty");
    
    ClientSendBAReport(BP_BA_LOBBY_ACTIVITY_CENTER, 0);
end

--进入组队界面
function EventEnterTeamUp()
	log("Enter TeamUp");
	--TeamUpSystem.Enter();
	--TeamUpUI.Init();
end


BP_RoleInfoSavedChoosingZoneId = 0
function EventRoleInfoSavedChoosingZoneId_Push()
BP_Back_ShowRoleInfoOfZoneId = BP_RoleInfoSavedChoosingZoneId
log("EventRoleInfoSavedChoosingZoneId_Push:BP_Back_ShowRoleInfoOfZoneId = "..BP_Back_ShowRoleInfoOfZoneId)
end

-- 进入个人信息面板
function EventEnterRoleInfo()
    log("Enter roleinfo")
    RoleInfoSystem.Enter(DataMgr.roleData.uid)
    RoleInfoUI.Init();
    LobbyUI:RefreshPlayerData()
end

-- 进入分享
function EventClickDailyShareBtn()
    log("Enter EventClickDailyShareBtn")
	--ShareDayUI.ShowUI();
    ShareAwardUI.Show();
end

-- 进入签到
function EventEnterSigninSystem()
    log("Enter EventEnterSigninSystem")
	-- SignInSystem.Enter(false);
end

-- 打开收集装备
function LobbyUI.OnOpenCollectEquipment()
    LuaClassObj.HandleUIMessage(bp_lobby, "OnCollectEquipmentBtnClick")
end

-- 打开刺激盛宴
function LobbyUI.OnOpenExcitingFeast()
    ExcitingPartyMgr.OpenUI() 
end

-- 打开先锋好礼
function LobbyUI.OnOpenFrontierAward()
    LuaClassObj.HandleUIMessage(bp_lobby, "OpenFrontierAward")
end

-- 打开分享有礼
function LobbyUI.OnOpenShareAward()
	ShareAwardUI.Show();
end

-- 打开开服狂欢
function LobbyUI.OnOpenCarnival()
    EventOpenActivityGroupUI()
end

function LobbyUI.UpdateActivityBtnList()
    LobbySystem.QueryActivityDisplayStatus()
end

-- 打开内置浏览器判断
BP_Lobby_CanOpenUrl = true
function EventCanOpenUrl()
    BP_Lobby_CanOpenUrl = true
    return
    -- 暂时屏蔽
    --[[
    if TeamUpUI.IsMatching() then
        BP_Lobby_CanOpenUrl = false
        DataMgr.ShowNoticeByID(110017)
		return
    end
    
    if BP_LobbyPlayerNum > 1 then
        BP_Lobby_CanOpenUrl = false
        DataMgr.ShowNoticeByID(110067)
    end]]
end

-- 关闭商城
function EventLobbyHideShop()
    LuaClassObj.HandleUIMessage(bp_shop, "UIHide")
    --EventShopHide()
end

-- 关闭仓库
function EventLeaveWardrobe()
	log("leave Wardrobe");
	WardrobeUI:Hide();
end

-- 关闭获得物品面板
function EventLobbyLeaveItemGet()
    CommonItemGetUI:Hide()
end

function EventLobbyLeaveChatWnd()
	LobbyChatLogic.CloseUI();
end

function EventLobbyLeaveRankList()
end

function EventLobbyLeaveFriend()
end

function EventLobbyLeaveMail()
end

function EventLobbyLeaveSetting()
    SettingUI:Hide()
end

function EventLobbyLeaveWorldView()
end

function EventLobbyLeaveRoleInfo()
end

function EventLobbyLeaveGuidePanel()
    GuideUI:Hide()
end

function EventLeaveWeekSignUp()
    WeekSignUpUI.HideUI();
end

function EventLobbyLeaveTask()
    EventTaskHideUI()
end

_ValidPopUI = {
    ["Wardrobe_BP_C"] = function()
        LuaClassObj.HandleUIMessage(bp_wardrobe, "UIHide");
     end,
    ["Shop_BP_C"] = function()
        LuaClassObj.HandleUIMessage(bp_shop, "UIHide");
     end,
    ["LobbyFriendList_UIBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_lobby_friend, "UIHide");
     end,
    ["LobbyFriendList_UIBP_C_BlackList"] = function() 
        LuaClassObj.HandleUIMessage(bp_lobby_friend, "CloseBlackList");
     end,
    ["LobbyFriendList_UIBP_C_ApplyPanel"] = function() 
        LuaClassObj.HandleUIMessage(bp_lobby_friend, "CloseApplyPanel");
     end,
    ["LobbyFriendList_UIBP_C_InviteVerify"] = function() 
        LuaClassObj.HandleUIMessage(bp_lobby_friend, "CloseInviteVerify");
     end,
    ["Mail_BP_C"] = function() 
        EventMailClose();
     end,
    ["Rank_BP_C"] = function() 
        EventRankClose();
     end,
    ["RoleInfo_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_roleinfo, "UIHide");
     end,
    ["RoleInfo_AvatarFrame_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_roleinfo_avatarframe, "Close");
     end,
    ["RoomWaiting_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_room_waiting, "CloseRoomWaiting");
     end,
    ["RoomList_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_room, "Hide");
     end,
    ["RoomList_BP_C_CreatRoom"] = function() 
        LuaClassObj.HandleUIMessage(bp_room, "CloseCreatRoom");
     end,
    ["Setting_UIBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_setting, "UIHide");
     end,
    ["Setting_language02_UIBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_setting_language, "UIHide");
     end,

    ["UIElemLayout_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_setting, "CloseUIElemPanel");
     end,
    ["CtrGuide_UIBP_C"] = function() 
        GuideUI:Hide()
     end,
    ["UIBindMain_Intl_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_bind_main_intl, "UIHide");
     end,
    ["UIGenTransferCode_Intl_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_bind_main_intl, "CloseGenTransferCode");
     end,
    ["UIBindAccount_Intl_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_bind_main_intl, "CloseBIndAccount");
     end,
    ["UISwitchAccount_Intl_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_bind_main_intl, "CloseSwitchAccount");
     end,
    ["UIInputTransferCode_Intl_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_bind_main_intl, "CloseInputTransferCode");
     end,
    ["Common_MessageBox_Panel_BP_C"] = function() 
        if BP_CommonMessageBox_style == 1 then
            EventCommonMessageBoxClickOK();
        else
            EventCommonMessageBoxClickCancel();
        end
        LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIHide");
     end,
    ["PopupNotice_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_popup_notice, "Close");
     end,
    ["RecruitLogic_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_recruit, "OnBtnClikClose");
     end,
    ["ChatMain_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_chat_main, "UIHide");
     end,
    ["Common_Item_Get_Panel_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_common_item_get_panel, "UIHide");
     end,
    ["ReportBug_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_reportbug, "UIHide");
     end,
    ["MainBackPackPanel_BP_C"] = function()
        InGameUIManager.HandleUIMessage(ingame, "CloseBackpack");
     end,
    ["NewEntireMap_C"] = function()
        InGameUIManager.HandleUIMessage(ingame, "CloseMap");
     end,
    ["LobbyTeam_NoTeam_LogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_alliance, "HideNoTeamPanel");
     end,
    ["LobbyTeam_CreateTeam_LogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_alliance, "HideCreateTeamPanel");
     end,
    ["LobbyTeamMain_LogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_alliance, "CloseTeamMainPanel");
        LuaClassObj.HandleUIMessage(bp_alliance, "EventClickAllianceCloseMainPanel");
     end,
    ["LobbyTeam_SelectIcon_LogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_alliance, "HideSelectIconPanel");
     end,
    ["LobbyTeam_LogicRecruitBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_alliance_recruit, "OnClickBtnClose");
     end,
    ["Newteaching_LogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_newteaching, "HideUI");
     end,
    ["Task_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_task, "OnCloseButtonClicked");
     end,
    ["Activty_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_activty, "OnCloseBtn");
     end,
    ["LobbyReportBug_UIBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_lobby_reportbug, "UIHide");
     end,

    ["Good_Item_Get_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_good_item_get_panel, "Close");
     end,

    ["Share_DayFinalyLogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_dayfinaly, "UIHide");
     end,
    ["Share_DayLogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_day, "UIHide");
     end,
    ["Share_Item_Get_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_item_get_share, "UIHide");
     end,
    ["Share_LevelUp_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_levelup, "UIHide");
     end,
    ["Share_PersonLogicBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_person, "UIHide");
     end,
    ["Share_Rank_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_rank, "UIHide");
     end,

    ["Share_ExcitingPartyBP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_share_exciting_party, "Share_ExcitingPartyBP");
     end,

    ["OpenBox_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_open_box_panel, "UIHide");
     end,

    ["Season_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_season, "OnClickClose");
     end,
    ["EightDay_BP_C"] = function() 
        LuaClassObj.HandleUIMessage(bp_eightday, "HideUI");
     end,
    [""] = function() 
        log("Exit");
        EventAndroidQuitGame();
    end,
}

-- Android back 逻辑
-- 为了保证以后合入方便没有直接使用 closeOtherMenu, closeOtherMenu实现不完备
function EventLobbyAndroidBack()
    local currentOpendUI = Client.GetCurrentOpenedUI();
    log("CurrentOpenedUI" .. currentOpendUI );
    closeFunc = _ValidPopUI[currentOpendUI];
    if closeFunc == nil then
	    sandbox.LogError("CurrentOpenUI is not set correctly");
    else
        closeFunc();
    end
    return 
end

function EventGetFriendProfile()
	FriendSystem.OnRefreshFriendProfile()
end

-- 进入游戏关闭其他面板
function LobbyUI:GotoGameHidePanels()
    LuaClassObj.HandleUIMessage(bp_lobby, "CloseOtherMenu")
	CommonMessageBoxUI:HidePanel();
	EventTaskHideUI()
	LuaClassObj.HandleUIMessage(bp_good_item_get_panel, "Hide");
	LuaClassObj.HandleUIMessage(bp_item_get_share, "Hide");
	LuaClassObj.HandleUIMessage(bp_lobby_reportbug, "UIHide");
end


-- 创建avatar变更数据结构
function LobbyUI:CreateAvatarChangeData(gid, resId)
    local playerData =
    {
        gid = tostring(gid),
        resId = resId,
    }
    
    return playerData
end

-- 创建组队玩家变更数据结构
function LobbyUI:CreateSpawnPlayerData(gid, sex, headId, hairid, avatarList)
    local avatarSt = {
        gamegender = sex,
        headid = headId,
        hairid = hairid
    }

    local spawnPlayerData =
    {
        gid = tostring(gid),
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = avatarList
    }
    
    return spawnPlayerData
end

-- 判断组队玩家是否已经在大厅中
local function IsPlayerAlreadyInLobby(playerData)
    log("LobbySystem.currentLobbyPlayerDataList " .. tostring(next(LobbySystem.currentLobbyPlayerDataList) == nil))
    for k,v in pairs(LobbySystem.currentLobbyPlayerDataList) do
        log(playerData.gid .. " " .. v.gid .. "aaaaaaaaaaaaaaaaaa" .. tostring(playerData.gid == v.gid))
        if tostring(playerData.gid) == tostring(v.gid) then
            return true
		end
	end
    
    return false
end

function EventSetInfo_Push()
end

-----------------------------------------------------
----------- 组队进入\退出玩家，创建模型 -------------
BP_LOBBY_SPAWNPOS = 0

function LobbyUI:SpawnPlayer(playerData, spawn)
    
    log("spawnPlayer " .. playerData.gid .. tostring(spawn))
    
    BP_STRUCT_SpawnPlayerData =
    {
        gid = tostring(playerData.gid),
        sex = playerData.avatar.gamegender,
        headId = playerData.avatar.headid,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = playerData.BP_ARRAY_AvatarList
    }
    
    BP_STRUCT_SpawnPlayerData.sex = BP_STRUCT_SpawnPlayerData.sex - 1
    table.insert(BP_STRUCT_SpawnPlayerData.BP_ARRAY_AvatarList, playerData.avatar.hairid)
    
    if spawn then
        
        --- 判断是否合法 ---
        if BP_LobbyPlayerNum >= 4 then
            log("To many player in lobby!!!!!")
            return
        end
        
        if IsPlayerAlreadyInLobby(playerData) then
            log("Player already in!!!!!  PlayerGID : " .. playerData.gid)
            return
        end
        ---------------------
        
        LuaClassObj.HandleUIMessage(bp_lobby, "SpawnPlayer")
        
        BP_LobbyPlayerNum = BP_LobbyPlayerNum + 1

        
        LobbyUI:SwitchToTeamorMenuCamera(false)
        
        -- 活动隐藏
        if BP_LobbyPlayerNum == 2 then
            LuaClassObj.HandleUIMessage(bp_lobby, "HideActivityBtnList")
        end
        
        -- 加入当前玩家数据
        BP_STRUCT_SpawnPlayerData.index = BP_LOBBY_SPAWNPOS + 1
        LobbySystem.currentLobbyPlayerDataList[tostring(playerData.gid)] = BP_STRUCT_SpawnPlayerData
        --log_tree("currentlobbyplayerdata add:", LobbySystem.currentLobbyPlayerDataList)
        log("currentlobbyplayerdata add pos : "..tostring(BP_STRUCT_SpawnPlayerData.index))
        
        return BP_LOBBY_SPAWNPOS + 1
    else
        
        --- 判断是否合法 ----
        if BP_LobbyPlayerNum <= 0 then
            log("No player in lobby!!!!!")
            return
        end
        
        if not IsPlayerAlreadyInLobby(playerData) then
            log("Player is not in!!!!!  PlayerGID : " .. playerData.gid)
            return
        end
        ----------------------
        
        LuaClassObj.HandleUIMessage(bp_lobby, "DelPlayer")
        
        BP_LobbyPlayerNum = BP_LobbyPlayerNum - 1
        LobbyUI:SwitchToMainCamera(false)
        -- 活动显示
        if BP_LobbyPlayerNum == 1 then
            LuaClassObj.HandleUIMessage(bp_lobby, "ShowActivityBtnList")
        end
        -- 删除当前玩家数据
        LobbySystem.currentLobbyPlayerDataList[tostring(playerData.gid)] = nil
        --log_tree("currentlobbyplayerdata del:", LobbySystem.currentLobbyPlayerDataList)
        
        return 
    end
end

function LobbyUI:UpdatePlayer()
    log("LobbyUI:UpdatePlayer")
    
    BP_STRUCT_SpawnPlayerData =
    {
        gid = tostring(DataMgr.roleData.uid),
        sex = DataMgr.avatarData.gamegender,
        headId = DataMgr.avatarData.headid,
        index = 1,
        BP_ARRAY_AvatarList = rolewear
    }
    
    LuaClassObj.HandleUIMessage(bp_lobby, "DelPlayer")
    
    local rolewear = {}
    for k,v in pairs(DataMgr.rolewear) do
        if (DataMgr.GetHallDepotItemDataByInsID(v) ~= nil) then
            table.insert(rolewear, DataMgr.GetHallDepotItemDataByInsID(v).resID)	
        end
	end
    --log_tree("LobbyUI:UpdatePlayer inst id", DataMgr.rolewear)
    --log_tree("LobbyUI:UpdatePlayer", rolewear)
    
    BP_STRUCT_SpawnPlayerData =
    {
        gid = tostring(DataMgr.roleData.uid),
        sex = DataMgr.avatarData.gamegender,
        headId = DataMgr.avatarData.headid,
        index = 1,
        BP_ARRAY_AvatarList = rolewear
    }
    
    BP_STRUCT_SpawnPlayerData.sex = BP_STRUCT_SpawnPlayerData.sex - 1
    table.insert(BP_STRUCT_SpawnPlayerData.BP_ARRAY_AvatarList, DataMgr.avatarData.hairid)
    
    LobbySystem.currentLobbyPlayerDataList[tostring(BP_STRUCT_SpawnPlayerData.gid)] = BP_STRUCT_SpawnPlayerData
        
    LuaClassObj.HandleUIMessage(bp_lobby, "SpawnPlayer")
end

-- 获取组队玩家位置index
function LobbyUI:GetSpawnPlayerPos(uid)
    if LobbySystem.currentLobbyPlayerDataList[tostring(uid)] ~= nil then
        return LobbySystem.currentLobbyPlayerDataList[tostring(uid)].index
    else 
        return nil
    end
end

-----------------------------------------------

-----------------------------------------------
-------- avatar变更接口 -----------------------
function LobbyUI:AvatarChange(playerData, open)

    if not IsPlayerAlreadyInLobby(playerData) then
        log("LobbyUI:AvatarChange : Player is not in!!!!!  PlayerGID : " .. playerData.gid)
        return
    end
        
    BP_STRUCT_AvatarChange =
    {
        gid = tostring(playerData.gid),
        resId = playerData.resId,
    }
    
    if open then
        LuaClassObj.HandleUIMessage(bp_lobby, "PutOnAvatar")
    else
        LuaClassObj.HandleUIMessage(bp_lobby, "PutOffAvatar")
    end
end
------------------------------------------------


-- 测试接口 --------------------------------------------
function EventTestSpawnPlayer()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "1",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    LobbyUI:SpawnPlayer(playerData, true)
end

function EventTestSpawnPlayer2()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "2",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    
    LobbyUI:SpawnPlayer(playerData, true)
end

function EventTestSpawnPlayer3()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "3",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    
    LobbyUI:SpawnPlayer(playerData, true)
end

function EventTestRemovePlayer()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "1",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    LobbyUI:SpawnPlayer(playerData, false)
end

function EventTestRemovePlayer2()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "2",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    
    LobbyUI:SpawnPlayer(playerData, false)
end
function EventTestRemovePlayer3()
    local avatarSt = 
    {
        gamegender = 1,
        headid = 401999,
        hair = 406001
    }
    local playerData =
    {
        gid = "3",
        avatar = avatarSt,
        index = BP_LobbyPlayerNum,
        BP_ARRAY_AvatarList = {}
    }
    
    
    LobbyUI:SpawnPlayer(playerData, false)
end


function EventAvatarChange()
    
    local playerData =
    {
        gid = tostring(DataMgr.roleData.uid ),
        resId = 403000,
    }
    LobbyUI:AvatarChange(playerData, true)
end


function EventTeamUpRings()
    local teamNum = 4
    local uidList = {}

    LobbyUI:CreateTeamUpRings(teamNum, uidList)
end


-----------------------------------------------------------

--创建脚底光圈接口
function LobbyUI:CreateTeamUpRings(teamNum, uidList)
    
    --[[BP_STRUCT_TeamUpRingsChange = 
    {
        teamMemberNum = teamNum,
        BP_ARRAY_CurrentTeamMemberGidList = uidList
    }

    LuaClassObj.HandleUIMessage(bp_lobby, "CreateRings")]]--

end

-- 红点状态更新
function LobbyUI:LobbyRedPointUpdate(menuId, show)
    BP_CurrentMenuId = menuId
    BP_CurrentRedPointStatus = show
    log("LobbyRedPointUpdate ".. tostring(menuId) .." " .. tostring(show))
    LuaClassObj.HandleUIMessage(bp_lobby, "UpdateRedPointStatus")
end

--系统消息数量更新（数量控制显示与否）
function LobbyUI:LobbySystemMessageUpdate(menuId,count)
	if menuId == BP_ENUM_LOBBY_MENU_FRIEND then
		BP_CurrentMenuId = menuId
		BP_FriendApplyMessageCount = count
	end
	
	log("LobbySystemMessageUpdate "..tostring(count))
	LuaClassObj.HandleUIMessage(bp_lobby,"UpdateSystemMessageCount")
end

function EventTestRedpoint()
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_MODULE_SHARE_AWARD, true)
end

function EventTestLevelUp()
    LevelUpUI:Init()
end

-- 打开GM面板
function EventOpenGMMenu()
    GM_UI:ShowPanel();
end


function EventTestScrollMsg()
    EventShowNextMsg()
end

function EventOpenMissionUI()
    if not LobbyUI:CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_TASK) then
        BP_Lobby_MenuOpen = false
        return
    end
    BP_Lobby_MenuOpen = true
    EventTaskShowUI()
    
    ClientSendBAReport(BP_BA_LOBBY_TASK_PANEL, 0);
end

function EventInitActivityListComplete()
    ShareAwardMgr.CheckAwardRedPoint();--分享有礼红点
    LobbyUI:UpdateLobbyActGroupRedDot()
    LuaClassObj.HandleUIMessage(bp_lobby, "UpdateCollectEquipRedPoint")
end


-- 回到大厅重播跑马灯
function EventRerollAllScrollMsg()
    ScrollNoticeUI:RerollScrollNotice()
end

-- 打开全屏面板隐藏跑马灯
function EventHideScrollMsg()
    ScrollNoticeUI:HideScrollNotice()
end

function UpdateLobbyTaskRedDot(is_show_redDot)
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_TASK, is_show_redDot);
end

function LobbyUI:UpdateLobbyActGroupRedDot()
    local isShow = ActivityGroupSystem.CheckShowRedPoint()
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_MODULE_OPENSERVICE_CARNIVAL, isShow);
end

-- 判断功能是否开启
BP_Lobby_MenuOpen = true
BP_ARRAY_Lobby_ActivityNotOpenList = {1}

function LobbyUI:CheckLobbyMenuOpen(menuId)
    
    if LobbySystem.LobbyMenuOpenStatus[menuId] == nil then
        return true
    end
    
    if LobbySystem.LobbyMenuOpenStatus[menuId].is_open == 0 then
    
        local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
        local text = Client.GetTableData("LocalizeRes", "120001").TextValue;

        CommonMessageBoxUI:ShowPanel(1, title, text);
        
        return false
    else 
        return true
    end

end

-- 相机切换接口
function LobbyUI:SwitchToMainCamera(isMenu)
    if (BP_CreateRole_LobbyToAvatar == 1) then
        return;
    end

    if (BP_LobbyPlayerNum == 1 and ((not ShopUI.isShow and not WardrobeUI.isShowing) or isMenu)) then
        LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_CloseMenu");
    end
    
end

function LobbyUI:SwitchToTeamorMenuCamera(isMenu)
    if (BP_CreateRole_LobbyToAvatar == 1) then
        return;
    end

    if (isMenu and BP_LobbyPlayerNum == 1) or (BP_LobbyPlayerNum > 1) then
        LuaClassObj.HandleUIMessage(bp_lobby, "SwitchCamera_OpenMenu");
    end
    
end

-- 获取收集装备活动状态
function EventGetCollectEquipOpenState()
	BP_COLLECT_EQUIPMENT_Open = RedPacketSystem.IsActivityInTime( ActivityType.COLLECT_EQUIPMENT )
end

-- 获取刺激盛宴状态
function EventGetExcitingPartyOpenState()
	-- BP_Exicting_Party_Open = false 
	BP_Exciting_Party_Open = ExcitingPartyMgr.isInTime
end

-- 打开刺激盛宴UI
function EventOpenGetExcitingPartyUI()
	PromotionMgr.SendGetPromotionInfo() 
end 

function EventOpenShopLimitUI()
    EventShopLimitShowUI()
end

function EventGetShopLimitTitle()
    local limit = ShowLimitSystem.GetShowLimit()
    if #limit == 0 then
        BP_STRUCT_ShopLimit.IsOpen = false
        return
    end
    local shopLimitInfo = limit[1]
    BP_STRUCT_ShopLimit.IsOpen = true
    BP_STRUCT_ShopLimit.Title = shopLimitInfo.typename
    BP_STRUCT_ShopLimit.EndTime = showLimitInfo.end_time
end

function UpdateLobbyActivityRedPoint(is_show_redPoint)
    if is_show_redPoint then
        LuaClassObj.HandleUIMessage(bp_lobby, "ShowActivityRedPoint");
    else
        LuaClassObj.HandleUIMessage(bp_lobby, "HideActivityRedPoint");
    end
end
function EventOpenCollectEquipment( )
    local baseUrl = "https://pg.qq.com/act/a20180104share/index.shtml";

    local finalEncodeUrl = Client.GetEncodeUrl(baseUrl);
    log("finalEncodeUrl url = " .. finalEncodeUrl)
    local accessToken = Client.GetAccessToken(NetInterface);
    local urlWithToken = string.format( "%s&access_token=%s", finalEncodeUrl, accessToken )
    log("urlWithToken url = " .. urlWithToken)
    Client.OpenURL(urlWithToken);
   
end
function LobbyUI:UpdateFreeDataState()
	BP_Free_Data_Open = FreeDataStreamMgr.isFreeState
	LuaClassObj.HandleUIMessage(bp_lobby, "UpdateFreeDataState")	
end

function EventOpenXinyue()
    XinyueSystem.OpenXinYueURL();
end

function EventOpenESportTV()
    if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
        Client.OpenURL("https://game.weixin.qq.com/cgi-bin/h5/static/embedgame/index.html?pt=1&gameid=wxc4c0253df149f02d");
    elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
        Client.OpenURL("http://info.gamecenter.qq.com/cgi-bin/platform_game_handle_ticket?gc_t=1&url_id=1113");
    end
end

 
-- 免流
function EventOpenFreeDataUrl()
	FreeDataStreamMgr:OpenFreeDataUrl() 
end 

-- 打开活动集合页UI
function EventOpenActivityGroupUI()
    ActivityGroupShowUI()
end 

function EventOpenQQVip()
	EventShowPlatQQVip();
end

function EventOpenQQlibao()
	local baseURL = "https://imgcache.qq.com/gc/gamecenterV2/dist/index/gift/search_gift.html?_wv=1031&_wwv=4&appid=1106467070&apptype=1&ADTAG=game_gift_juediqiusheng";
	Client.OpenURL(baseURL);
end


function EventOpenCommunityInLobby()
    local url = "https://pg.qq.com/m/ingame/all/index.shtml";
    log("EventOpenCommunityInLobby url = " .. url);
    GlobalData:JumpUrl(url);
end

function EventOpenHuati()
	TopicQuanSystem.OpenTopicQuanURL();
end
