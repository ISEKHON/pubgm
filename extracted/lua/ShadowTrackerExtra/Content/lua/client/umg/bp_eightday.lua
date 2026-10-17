EightDayUI = EightDayUI or
{
    DayAmount = 8,

    StringID_Name = 430001, -- 第%d天
    StringID_DateFormat = 430101, -- 日期字符串
    StringNameFormat = "",
    StringDateFormat = "",

    BetterAwardLevel = {2,3,7,8},

    IsInited = false,
    IsFirstShow = true,
    IsUIShow = false,
    TimeStep = 60*60*24*14-1,

    ErrorCode_End = 430104,
}

BP_STRUCT_EightDayUI_Info =
{
    name = "",
    status = 0,
    itemName = "",
    itemImage = "",
    itemQuality = 0,
    itemID = 0,
}


BP_STRUCT_BetterAwardInfo = _G.BP_STRUCT_EightDayUI_Info;

BP_ARRAY_EightDay_Items = { BP_STRUCT_EightDayUI_Info = _G.BP_STRUCT_EightDayUI_Info }
BP_Request_EightDay_day = 0;    -- 签到第几天，从1开始
BP_String_EightDay_ActiveTime = "";

function EventEightDayUpdateTime()
    local actData = EightDayUI.GetActivityData();
    if actData == nil then
        sandbox.LogError("[HHF]EightDayUI.UpdateUI missing activity data");
        BP_String_EightDay_ActiveTime = "";
        return;
    else
        local startTime = FuncUtil.SecToDateString(actData.open_time);
        local endTimeInSec = actData.open_time + EightDayUI.TimeStep;
        local endTime = FuncUtil.SecToDateString(endTimeInSec);
        BP_String_EightDay_ActiveTime = string.format(EightDayUI.StringDateFormat, startTime, endTime);
    end
end

function EventFetchInfo()
end

function EventEightDaySignUpReq_Push()
end

function EventEightDaySignUpReq()
    local actData = EightDayUI.GetActivityData();
    local dateData = actData.List[BP_Request_EightDay_day];

    log(string.format("EventEightDaySignUpReq : day=%d id=%d index=%d status=%d", BP_Request_EightDay_day, dateData.ID, dateData.Index, dateData.Status));
    ActivitySystem.Req_TakeActivityAward(dateData.ID, dateData.Index);
end

function EventEightDayUpdateUI()
    EightDayUI.UpdateUI();
end

function EventEightDayHideUI( ... )
    EightDayUI.HideUI();
    LuaClassObj.HandleUIMessage(bp_eightday, "Hide");
end

function EightDayUI.UpdateUI()
    if not EightDayUI.IsUIShow then
        return;
    end

    -- 更新数据
    local actData = EightDayUI.GetActivityData();
    if actData == nil then
        sandbox.LogError("EightDayUI.UpdateUI missing activity data");
        EventEightDayHideUI();
        return;
    end
    -- log_tree("EightDayUI.UpdateUI actData:", actData);

    local lastSignInDay = 0;
    -- 八天数据

    for i = 1, EightDayUI.DayAmount do
        local dayData = actData.List[i];
        if dayData == nil then
            sandbox.LogError("EightDayUI.UpdateUI activity no data in day "..i);
            EventEightDayHideUI();
            return;
        end

        if not dayData.Drop or #dayData.Drop == 0 then
            sandbox.LogError("EightDayUI.UpdateUI activity no drop in day "..i);
            EventEightDayHideUI();
            return;
        end

        if dayData.Status == 2 then
            lastSignInDay = i;
        end

        local info = BP_ARRAY_EightDay_Items[i];
        EightDayUI.UpdateItem(i, info, dayData);
    end

    EightDayUI.UpdateBetterAward(actData, lastSignInDay);

    log_tree("EightDayUI.UpdateUI:", BP_ARRAY_EightDay_Items);
    LuaClassObj.HandleUIMessage(bp_eightday, "UpdateUI");
end

function EightDayUI.UpdateItem(day, info, dayData)
    local dropInfo = dayData.Drop[1];
    local id = dropInfo.itemId;
    local itemInfo = Client.GetTableData("Item", id);
    if itemInfo == nil then
        sandbox.LogError("itemInfo == nil id = "..id);
        EightDayUI.HideUI();
        return;
    end

    info.status = dayData.Status;
    info.name = string.format(EightDayUI.StringNameFormat, day);
    if dropInfo.count > 1 then
        info.itemName = dropInfo.count..itemInfo.ItemName;
    else
        info.itemName = itemInfo.ItemName;
    end
    info.itemImage = itemInfo.ItemBigIcon;
    info.itemQuality = itemInfo.ItemQuality;
    info.itemID = id;
end

-- 更新左边的较好奖励面板
function EightDayUI.UpdateBetterAward(actData, lastDay)
    local nextDay = 8;

    for i,v in ipairs(EightDayUI.BetterAwardLevel) do
        if lastDay < v then
            nextDay = v;
            break;
        end
    end

    log("EightDayUI.UpdateBetterAward nextDay:"..nextDay);
    log("EightDayUI.UpdateBetterAward lastDay:"..lastDay);
    EightDayUI.UpdateItem(nextDay, BP_STRUCT_BetterAwardInfo, actData.List[nextDay]);
    BP_STRUCT_BetterAwardInfo.name = tostring(nextDay - lastDay);
end

function EightDayUI.GetActivityData()
    return DataMgr.GetActivityByType(ActivityType["NEW_PLAYER"]);
end

function bp_eightday_OnModeSwitched(gamestatus)
    log("bp_eightday_OnModeSwitched : "..gamestatus);
    -- 回到登录场景清数据
    if string.lower(gamestatus) == "login" then
    elseif string.lower(gamestatus) == "lobby" then
    end
end

function EightDayUI.OnJumpUrl(eventType, eventID, vars)
    EightDayUI.ShowUI();
end

function bp_eightday_RegisterUI()
    LuaClassObj.SubUIWidgetList(bp_eightday,
    {{Path="/Game/UMG/UI_Logic/EightDay/EightDay_BP.EightDay_BP_c", Container="Default", ZOrder=BP_ENUM_UI_EIGHTDAY_ZORDER}},
    {"Lobby"},
    false,
    bp_eightday_OnModeSwitched ~= nil,
	true);
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_EIGHT_DAY, EightDayUI.OnJumpUrl);
end

function EightDayUI.OnActivityChange()
    log("EightDayUI.OnActivityChange");
    EightDayUI.UpdateUI();
end

function EightDayUI.GetShowErrorCode(outputError)
    local actData = EightDayUI.GetActivityData();
    log_tree("EightDayUI.GetShowErrorCode actData", actData);
    if actData == nil then
        return 1;
    end

    -- 是否已经到期
    local endTime = actData.open_time + EightDayUI.TimeStep;
    if FuncUtil.GetServerTimeInSec() > endTime then
        return EightDayUI.ErrorCode_End;
    end

    -- 数据是否合法
    local signedCount = 0;
    for i = 1, EightDayUI.DayAmount do
        local dayData = actData.List[i];
        if dayData.Status == 2 then
            signedCount = signedCount + 1;
        end

        if dayData == nil then
            if outputError then
                sandbox.LogError("EightDayUI.GetShowErrorCode activity no data in day "..i);
            end
            return 1;
        end

        if not dayData.Drop or #dayData.Drop == 0 then
            if outputError then
                sandbox.LogError("EightDayUI.GetShowErrorCode activity no drop in day "..i);
            end
            return 1;
        end
    end

    if signedCount >= EightDayUI.DayAmount then
        return EightDayUI.ErrorCode_End;
    end

    return 0;
end

function EightDayUI.ShowUI()
    local errorCode = EightDayUI.GetShowErrorCode();
    if errorCode ~= 0 then
        if errorCode == EightDayUI.ErrorCode_End then
            ShowNotice(errorCode);
        end
        return;
    end

	LuaClassObj.HandleDynamicCreation(bp_eightday);

    EightDayUI.IsUIShow = true;
    EightDayUI.InitDayList();

    local textData = Client.GetTableData("LocalizeRes", EightDayUI.StringID_Name);
    if textData ~= nil then
        EightDayUI.StringNameFormat = textData.TextValue;
    end

    textData = Client.GetTableData("LocalizeRes", EightDayUI.StringID_DateFormat);
    if textData ~= nil then
        EightDayUI.StringDateFormat = textData.TextValue;
    end

    if not EightDayUI.IsInited then
        EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, EightDayUI.OnActivityChange);
        EightDayUI.IsInited = true;
    end
    EightDayUI.IsFirstShow = false;
    LuaClassObj.HandleUIMessage(bp_eightday, "UIShow");
end

function EightDayUI.InitDayList()
    if #BP_ARRAY_EightDay_Items ~= 0 then
        return;
    end

    for i = 1, EightDayUI.DayAmount do
        BP_ARRAY_EightDay_Items[i] = BP_ARRAY_EightDay_Items[i] or FuncUtil:CopyTable(BP_STRUCT_EightDayUI_Info);
    end
end

function EightDayUI.ResetData()
    EightDayUI.IsFirstShow = true;
end

function EightDayUI.HideUI()
    EightDayUI.IsUIShow = false;
    if EightDayUI.IsInited then
        EventSystem:unregistEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, EightDayUI.OnActivityChange);
        EightDayUI.IsInited = false;
    end
    FaceSlapSystem.ShowNext(BP_ENUM_MODULE_EIGHT_DAY);
end

function EightDayUI.ShouldSlap()
    log("EightDayUI.ShouldSlap");
    local actData = EightDayUI.GetActivityData();
    if actData == nil then
        return false;
    end

    if EightDayUI.GetShowErrorCode() ~= 0 then
        return false;
    end

    local hasSignIn = false;
    for i = 1, EightDayUI.DayAmount do
        local dayData = actData.List[i];
        if dayData == nil then  -- 不可能为空数据，如果为空则不显示
            return false;
        end

        if dayData.Status == 1 then -- 有可签到状态才弹
            hasSignIn = true;
        end
    end

    DataMgr.IsEightDaySlpaed = hasSignIn;
    log("EightDayUI.ShouldSlap DataMgr.IsEightDaySlpaed = "..tostring(DataMgr.IsEightDaySlpaed));
    return hasSignIn;
end