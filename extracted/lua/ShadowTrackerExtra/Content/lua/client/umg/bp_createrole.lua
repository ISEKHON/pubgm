CreateRoleUI = CreateRoleUI or 
{
    --进入大厅后关闭界面
    needClose = true;
    --换装时缓存
    sex = 0,
    head = 0,
    race = 0,
    hairType = 0,
    hairColor = 0,
    
    --重置卡ID
    cardID = 1601001,
    createRoleNameInit = false,
    platformName = "",
}

--玩家名字
BP_CreateRole_Name = "";
--玩家游戏性别 1：男性 2：女性
BP_CreateRole_Sex = 1;
--玩家种族（脸型） 1-6
BP_CreateRole_Race = 1;
BP_CreateRole_HeadId = 0;
--玩家发型
BP_CreateRole_HairType = 1;
--玩家发色
BP_CreateRole_HairColor = 1;
--头发ID
BP_CreateRole_HairID = 0;
--模式切换创建角色:1/重置外观:2
BP_CreateRole_Mode = 1;
--重置需要的花费
BP_CreateRole_ModeCost = 3000;
--从大厅到换装1or换装到大厅0
BP_CreateRole_LobbyToAvatar = 0;
--形象重置卡个数
BP_CreateRole_CardCount = 0;

  --注册Widget
function bp_createrole_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_createrole,
    {{Path="/Game/UMG/UI_BP/Lobby/Lobby_CreatingRole_UIBP.Lobby_CreatingRole_UIBP_C", Container="Default", ZOrder=0},
     {Path="/Game/UMG/UI_BP/Lobby/Item/Lobby_ResetRole_UIBP.Lobby_ResetRole_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_ResetRole},
     {Path="/Game/UMG/UI_BP/Lobby/Lobby_AvatarAnim_UIBP.Lobby_AvatarAnim_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_COMMON_ITEM_GET_ZORDER}
    },
	{"CreateRole","Lobby"},
	false,
	true
  );
  
  EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_OPEN, CreateRoleUI.OnOpenWardRobe);
  EventSystem:registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_CLOSE, CreateRoleUI.OnCloseWardRobe);
  EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_DATA_CHANGE, CreateRoleUI.OnDepotDataChange);

end

--设置平台名字
function CreateRoleUI:SetPlatformName(name)
    CreateRoleUI.platformName = name;
    log("CreateRoleUI:SetPlatformName:"..name)
    if (CreateRoleUI.createRoleNameInit == false) then
        CreateRoleUI.createRoleNameInit = true;
        BP_CreateRole_Name = name;
    end
    LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--显示创建角色界面
function CreateRoleUI:Init()
	log("CreateRoleUI init");
    
    BP_CreateRole_Sex = 1;
    BP_CreateRole_Race = 1;
    BP_CreateRole_HeadId = 0;
    BP_CreateRole_HairType = 1;
    BP_CreateRole_HairColor = 1;
    BP_CreateRole_HairID = 0;
    BP_CreateRole_CardCount = 0;

    EventUpdateCardCount();

    if(BP_CreateRole_Mode == 1) then 
        if ( BP_Platform == BP_ENUM_PLAYFORM_TOURIST) then
            -- 需求更新，去掉随机名字
            -- BP_CreateRole_Name = GetRandomName(BP_CreateRole_Sex);
            BP_CreateRole_Name = "";
        end
    end
    
    LuaClassObj.HandleUIMessage(bp_createrole, "UIShow");
    LuaClassObj.HandleUIMessage(bp_createrole, "SelectMale");
end

function CreateRoleUI:Release()
	log("CreateRoleUI release");
end

--异常提示
function CreateRoleUI:ShowIllegalInfo(info)
    local text = "";
    if (info == "name-too-long") then
        text = Client.GetTableData("LocalizeRes", "990002").TextValue;
    elseif (info == "name-too-short") then
        text = Client.GetTableData("LocalizeRes", "990003").TextValue;
    elseif (info == "have-dirty-in-name") then
        text = Client.GetTableData("LocalizeRes", "990004").TextValue;
    elseif (info == "name-exist") then
        text = Client.GetTableData("LocalizeRes", "990005").TextValue;
    elseif (info == "bad-request") then
        text = Client.GetTableData("LocalizeRes", "990006").TextValue;
    else
        text = info;
    end
    log(text)
    PopUpNoticeUI.ShowNewNotice(text);
end

--返回随机名字
function GetRandomName(sex)
    local name = ""
    if(BP_ARRAY_NameTable == nil) then
        return name;
    end
    local n = #BP_ARRAY_NameTable;
    local n0 = math.random(n)
    local n1 = math.random(n)
    if(BP_CreateRole_Sex == BP_ENUM_GENDER_MALE) then
        name = BP_ARRAY_NameTable[n0].b
    else
        name = BP_ARRAY_NameTable[n0].c
    end
    name = BP_ARRAY_NameTable[n1].a .. name
    return name
end

--点击按钮随机名字
function EventRandomName()
	log("EventRandomName");
    BP_CreateRole_Name = GetRandomName(BP_CreateRole_Sex);
    
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择男性
function EventSelectMale()
	log("EventSelectMale");
    BP_CreateRole_Sex = 1;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择女性
function EventSelectFeMale()
	log("EventSelectFeMale");
    BP_CreateRole_Sex = 2;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型1
function EventSelectRace1()
	log("BP_CreateRole_Race 1");
    BP_CreateRole_Race = 1;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型2
function EventSelectRace2()
	log("BP_CreateRole_Race 2");
    BP_CreateRole_Race = 2;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型3
function EventSelectRace3()
	log("BP_CreateRole_Race 3");
    BP_CreateRole_Race = 3;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型4
function EventSelectRace4()
	log("BP_CreateRole_Race 4");
    BP_CreateRole_Race = 4;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型5
function EventSelectRace5()
	log("BP_CreateRole_Race 5");
    BP_CreateRole_Race = 5;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择脸型6
function EventSelectRace6()
	log("BP_CreateRole_Race 6");
    BP_CreateRole_Race = 6;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择发型1
function EventSelectHairType1()
	log("BP_CreateRole_HairType 1");
    BP_CreateRole_HairType = 1;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型2
function EventSelectHairType2()
	log("BP_CreateRole_HairType 2");
    BP_CreateRole_HairType = 2;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型3
function EventSelectHairType3()
	log("BP_CreateRole_HairType 3");
    BP_CreateRole_HairType = 3;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型4
function EventSelectHairType4()
	log("BP_CreateRole_HairType 4");
    BP_CreateRole_HairType = 4;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型5
function EventSelectHairType5()
	log("BP_CreateRole_HairType 5");
    BP_CreateRole_HairType = 5;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型6
function EventSelectHairType6()
	log("BP_CreateRole_HairType 6");
    BP_CreateRole_HairType = 6;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型7
function EventSelectHairType7()
	log("BP_CreateRole_HairType 7");
    BP_CreateRole_HairType = 7;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型8
function EventSelectHairType8()
	log("BP_CreateRole_HairType 8");
    BP_CreateRole_HairType = 8;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发型9
function EventSelectHairType9()
	log("BP_CreateRole_HairType 9");
    BP_CreateRole_HairType = 9;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

--点击按钮选择发色1
function EventSelectHairColor1()
	log("BP_CreateRole_HairColor 1");
    BP_CreateRole_HairColor = 1;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发色2
function EventSelectHairColor2()
	log("BP_CreateRole_HairColor 2");
    BP_CreateRole_HairColor = 2;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发色3
function EventSelectHairColor3()
	log("BP_CreateRole_HairColor 3");
    BP_CreateRole_HairColor = 3;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发色4
function EventSelectHairColor4()
	log("BP_CreateRole_HairColor 4");
    BP_CreateRole_HairColor = 4;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发色5
function EventSelectHairColor5()
	log("BP_CreateRole_HairColor 5");
    BP_CreateRole_HairColor = 5;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end
--点击按钮选择发色6
function EventSelectHairColor6()
	log("BP_CreateRole_HairColor 6");
    BP_CreateRole_HairColor = 6;
    CreateRoleUI:UpdateButtonVisible();
	LuaClassObj.HandleUIMessage(bp_createrole, "RefreshUI");
end

function EventUpdateCardCount()
    local itemData = DataMgr.GetHallDepotItemDataByResID(CreateRoleUI.cardID);
    if(itemData ~= nil) then
        BP_CreateRole_CardCount = itemData.count;
    else
        BP_CreateRole_CardCount = 0;
    end
    log("BP_CreateRole_CardCount:"..BP_CreateRole_CardCount);
end

--Avatar设置模式
function EventOpenAvatarResetPanel()
	log("EventOpenAvatarResetPanel xxx"..DataMgr.avatarData.headid);
	log("EventOpenAvatarResetPanel xxx"..DataMgr.avatarData.hairid);
	log("EventOpenAvatarResetPanel xxx"..DataMgr.avatarData.gamegender);
    
    BP_CreateRole_LobbyToAvatar = 1;
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_OPEN)
    CreateRoleUI:DataMgrToAvatarData();
    LuaClassObj.HandleUIMessage(bp_createrole, "UIShowAvatarAni");
    LuaClassObj.HandleUIMessage(bp_createrole, "SwitchCameraFarImmediate");
end

--显示Avatar设置UI
function EventOpenAvatarResetPanelInter()
	log("EventOpenAvatarResetPanelInter xxx");
    BP_CreateRole_Mode = 2;
    EventUpdateCardCount();

    LuaClassObj.HandleUIMessage(bp_createrole, "UIShow");
    LuaClassObj.HandleUIMessage(bp_createrole, "HideResetButton");
    LuaClassObj.HandleUIMessage(bp_createrole, "PlayFadeIn");
end

--还原Avatar设置
function EventCancelAvatarReset()
    log("EventCancelAvatarReset")
    
    CreateRoleUI:DataMgrToAvatarData();
    LuaClassObj.HandleUIMessage(bp_createrole, "CreateAvatar");
    LuaClassObj.HandleUIMessage(bp_createrole, "UIShow");
    LuaClassObj.HandleUIMessage(bp_createrole, "HideResetButton");
    LuaClassObj.HandleUIMessage(bp_createrole, "SwitchCameraFar");
end

--关闭Avatar设置
function EventCloseAvatarResetPanel()
    log("EventCloseAvatarResetPanel")
    
    BP_CreateRole_Mode = 1;
    BP_CreateRole_LobbyToAvatar = 0;
    LuaClassObj.HandleUIMessage(bp_createrole, "UIShowAvatarAni");
end

--关闭Avatar设置
function EventCloseAvatarResetPanelInter()
    log("EventCloseAvatarResetPanelInter")
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE)
end

--购买二次确认
function EventShowAvatarResetBuyPanel()
    local tip = "";
    if(BP_CreateRole_CardCount > 0) then
        --tip = string.format("是否以<img src=\"AvatarResetImage\"/><MessageGoldColor></>*1重置外观<MessageProductColor></>?");
        tip = string.format(Client.GetTableData("LocalizeRes", "301291").TextValue);
        tip = (string.gsub(tip, "\'", "\""));
    else
        --tip = string.format("是否以<img src=\"GoldImage\"/><MessageGoldColor>%s</>重置外观<MessageProductColor></>?",  BP_CreateRole_ModeCost);
        tip = string.format(Client.GetTableData("LocalizeRes", "301292").TextValue, BP_CreateRole_ModeCost);
        tip = (string.gsub(tip, "\'", "\""));
    end
    local function callbackOK()
        log("callbackOK")
        EventGetCreateRoleHairID();
        NetUtil.SendPriorityPkg(true, "modify_role_face_respond", "modify_role_face", BP_CreateRole_Sex, BP_CreateRole_HeadId, BP_CreateRole_HairID);
    end
    
    --CommonMessageBoxUI:ShowPanel(2, "购买", tip, callbackOK);
    CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "301185").TextValue, tip, callbackOK);
end

--过滤不合法字符
function EventFilterName()
    _ , _ , BP_CreateRole_Name = FuncUtil:CheckName(BP_CreateRole_Name, true, 14);
	LuaClassObj.HandleUIMessage(bp_createrole, "UpdatePlayerName");
end

--还原Avatar数据
function CreateRoleUI:DataMgrToAvatarData()
    log("CreateRoleUI:DataMgrToAvatarData()");
    --DataMgr.avatarData.hairid
    if(DataMgr.avatarData.hairid < 500000) then
        log("log old style hairid = ".. DataMgr.avatarData.hairid);
        DataMgr.avatarData.hairid = 40601001;
    end
    local data =  DataMgr.avatarData.hairid % (BP_ENUM_AVATAR_HAIR * 100000);
    local hairColor = math.floor(data / 1000);
    local hairtype = data % 1000;
    BP_CreateRole_Sex = DataMgr.avatarData.gamegender;
    BP_CreateRole_HeadId = DataMgr.avatarData.headid;
    CreateRoleUI:GetCreateRoleHeadOrRace(false);
    BP_CreateRole_HairType = hairtype;
    BP_CreateRole_HairColor = hairColor;
    BP_CreateRole_HairID = DataMgr.avatarData.hairid;
    CreateRoleUI.sex = DataMgr.avatarData.gamegender;
    CreateRoleUI.head = DataMgr.avatarData.headid;
    CreateRoleUI.race = BP_CreateRole_Race;
    CreateRoleUI.hairType = BP_CreateRole_HairType;
    CreateRoleUI.hairColor = BP_CreateRole_HairColor;
	log("DataMgrToAvatarData xxx "..CreateRoleUI.sex);
	log("DataMgrToAvatarData xxx "..CreateRoleUI.head);
	log("DataMgrToAvatarData xxx "..CreateRoleUI.race);
	log("DataMgrToAvatarData xxx "..CreateRoleUI.hairType);
	log("DataMgrToAvatarData xxx "..CreateRoleUI.hairColor);
end

--购买AVATAR
function CreateRoleUI:BuyAvatarOK()
    local needRebuild = false;
    if( DataMgr.avatarData.gamegender ~= BP_CreateRole_Sex) then
        needRebuild = true;
    end
    if( DataMgr.avatarData.headid ~= BP_CreateRole_HeadId) then
        needRebuild = true;
    end
    DataMgr.avatarData.gamegender = BP_CreateRole_Sex;
    DataMgr.avatarData.headid = BP_CreateRole_HeadId;
    DataMgr.avatarData.hairid = BP_CreateRole_HairID;
    CreateRoleUI:DataMgrToAvatarData();
    LuaClassObj.HandleUIMessage(bp_createrole, "HideResetButton");
    LuaClassObj.HandleUIMessage(bp_createrole, "SwitchCameraFar");
    return needRebuild;
end

function CreateRoleUI:GetCreateRoleHeadOrRace(r2h)
    --6个头ID
    local heads = {401999,401998,401997,401996,401995,401994};
    if(r2h) then
        BP_CreateRole_HeadId = heads[BP_CreateRole_Race];
    else
        BP_CreateRole_Race = 1;
        for i,v in ipairs(heads) do
            if( v == BP_CreateRole_HeadId) then
                BP_CreateRole_Race = i;
            end
        end
    end
    log("CreateRoleUI:GetCreateRoleHeadOrRace:" .. BP_CreateRole_Race.." "..BP_CreateRole_HeadId);
end

function CreateRoleUI:UpdateButtonVisible()
    local show = false;
    if( BP_CreateRole_Sex ~= CreateRoleUI.sex) then
        show = true;
    end
    if (BP_CreateRole_Race ~= CreateRoleUI.race) then
        show = true;
    end
    if (BP_CreateRole_HairType ~= CreateRoleUI.hairType) then
        show = true;
    end
    if (BP_CreateRole_HairColor ~= CreateRoleUI.hairColor) then
        show = true;
    end
    if( show ) then
        LuaClassObj.HandleUIMessage(bp_createrole, "ShowResetButton");
    else
        LuaClassObj.HandleUIMessage(bp_createrole, "HideResetButton");
    end
    LuaClassObj.HandleUIMessage(bp_createrole, "SwitchCameraClosein");
end

--获得当前选定的头ID
function EventGetCreateRoleHeadID()
    log("EventGetCreateRoleHeadID")
    CreateRoleUI:GetCreateRoleHeadOrRace(true)
end

--获取当前获得的头发ID
function EventGetCreateRoleHairID()
    local hairIdStr = string.format("%s%02s%03s", BP_ENUM_AVATAR_HAIR, BP_CreateRole_HairColor, BP_CreateRole_HairType);
    BP_CreateRole_HairID = tonumber(hairIdStr, 10); 
    log("EventGetCreateRoleHairID:" .. BP_CreateRole_HairID);
end

function CreateRoleUI.OnOpenWardRobe()
    log("CreateRoleUI OnOpenWardRobe")
  
    LuaClassObj.HandleUIMessage(bp_createrole, "UIShowResetAvatar");
end

function CreateRoleUI.OnCloseWardRobe()
    log("CreateRoleUI OnCloseWardRobe")
	LuaClassObj.HandleUIMessage(bp_createrole, "UIHideResetAvatar");
end

function CreateRoleUI.OnDepotDataChange()
    log("CreateRoleUI OnDepotDataChange")
    EventUpdateCardCount();
    LuaClassObj.HandleUIMessage(bp_createrole, "UpdateCost");
end

--点击按钮进入大厅
function EventEnterLobby()
	log("EventEnterLobby from createrole:"..BP_CreateRole_Name);
    
    local ret, len, retStr = FuncUtil:CheckName(BP_CreateRole_Name, true);
    if ret then
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "990004").TextValue);
        return;
    elseif len > 14 then
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "990002").TextValue);
        return;
    elseif len == 0 then
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "990003").TextValue);
        return;
    end
    
    --后台需要统计一些本地设备、系统信息
    DeviceOSInfo.getDeviceOSInfo();
    
    EventGetCreateRoleHeadID()
    
    EventGetCreateRoleHairID();
    
    --BP_CreateRole_HeadId = 401997;
    --BP_CreateRole_HairID = 406003;
    log("create_role_respond: " .. BP_CreateRole_Name .. " " .. BP_CreateRole_Sex .. " " .. BP_CreateRole_HeadId .." " .. BP_CreateRole_HairID);
    NetUtil.SendPriorityPkg(true, "create_role_respond", "create_role_request", BP_CreateRole_Name, BP_CreateRole_Sex, BP_CreateRole_HeadId, BP_CreateRole_HairID, DeviceOSInfo.InfoList);
    
    ConnectionWaitingUI:Show()

end

--点物品或金币TIPS
function  EventCreateRoleShowItemTips()
    CommonItemTipsUI:ShowPanel(CreateRoleUI.cardID, { x = 460,y = 500})
end

function  EventCreateRoleHideItemTips()
    CommonItemTipsUI:ClosePanel();
end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function bp_createrole_OnModeSwitched(gamestatus)
	log("bp_createrole_OnModeSwitched gamestatus = " .. gamestatus);
    status = string.lower(gamestatus);
	if status == "createrole" then
        LoadingUI.RefreshLoadPercent(1)
		--显示UI
        PopUpNoticeUI:Init();
        CreateRoleUI:Init();
         -- -1: refuse, 0: tips, 1: normal
        if (HasShowDeviceLimit == false) then
            LobbySystem.CheckDeviceTip();
        end
    else
        BP_CreateRole_LobbyToAvatar = 0;
        CreateRoleUI.needClose = true;
        BP_CreateRole_Name = CreateRoleUI.platformName;
        CreateRoleUI.createRoleNameInit = false;
	end
end

function bp_createrole_OnModeAboutToSwitched()
end

-- 打开语言设置
function EventEnterLanguageSetting()
    log("enter language setting ui");
    SettingLanguageUI.ShowUIInLoginPanel();
end

function EventCreateRolePanelLogOut()
    local function LogOut()
        log("...log out from createRolePanel...");
        
        LoginSystem.sendLogout();
    end

    CommonMessageBoxUI:ShowPanel(2, Client.GetTableData("LocalizeRes", "102012").TextValue, Client.GetTableData("LocalizeRes", "111019").TextValue, LogOut);
end