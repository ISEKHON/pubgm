WeekSignUpUI = WeekSignUpUI or
{
    IsInited = false,

    StringID_Name = 430001, -- 第%d天
    StringID_Desc = 430002, -- 是否花费%d金币补签
    StringID_Resign = 430003,  -- 补签
    StringID_NotEnough = 110055, -- 补签金币不足
    StringID_OK = 110036, -- 确定

    -- CurrentSignUpDayInWeek = 0,
    StartTimeInSec = 0,
    EndTimeInSec = 0,
}

BP_STRUCT_WeekSignUpUI_Info =
{
    name = "",
    status = 0,
    itemName = "",
    itemImage = "",
    itemQuality = 0,
    itemResID = 0,
}

BP_CurrentSignUpDayInWeek = 0;
BP_Week_SignUp_TimeString = "";
BP_ARRAY_Week_SignUp_Info = { BP_STRUCT_WeekSignUpUI_Info = _G.BP_STRUCT_WeekSignUpUI_Info }
BP_Request_SignUp_day = 0;
BP_Week_SignUp_Platform = 0;
BP_Week_SignUp_Startup = 0;
BP_Week_SignUp_QQVip = 0;

function EventFetchInfo( ... )
    -- body
end

function EventWeekSignUpReq_Push( ... )
    -- body
end

function EventWeekSignUpReq( ... )
    log("EventWeekSignUpReq");

    local weekDay = FuncUtil.GetServerWeekDay();
    if BP_CurrentSignUpDayInWeek ~= weekDay then -- 不是同一天签到，刷新数据
        log(string.format("EventWeekSignUpReq:不是同一天签到，刷新数据 %d %d", BP_CurrentSignUpDayInWeek, weekDay));
        OnWeekSignUpUpdated();
        return;
    end

    -- 查找消耗，如果有消耗则弹窗
    local cost = WeekSignUpUI.GetSignUpCost(BP_Request_SignUp_day);
    if cost > 0 then
        -- 有消耗，弹提示窗
        local resign = FuncUtil.GetLocalizeResStr("430003");
        if DataMgr.gold < cost then   -- 钱不够
            local msg = string.format(FuncUtil.GetLocalizeResStr(WeekSignUpUI.StringID_NotEnough), cost);            
            msg = string.gsub(msg, "%$%$", "\"");            
            CommonMessageBoxUI:ShowPanel(1, resign, msg);
        else
            --StringID_Desc = 430002, -- 是否花费%d金币补签
            local msg = string.format(FuncUtil.GetLocalizeResStr("430002"), cost);            
            msg = string.gsub(msg, "%$%$", "\"");            
            CommonMessageBoxUI:ShowPanel(2, resign, msg, WeekSignUpUI.SendSignMsg);
        end
    else
        WeekSignUpUI.SendSignMsg();
    end
end

function EventWeekSignUpInit( ... )
    -- body
    log("EventWeekSignUpInit server time:"..os.date("%Y-%m-%d %H:%M:%S", FuncUtil.GetServerTimeInSec()));
    WeekSignUpUI.Init();
end

function EventWeekSignUpHide( ... )
    -- body
    WeekSignUpUI.HideUI();
end

function EventWeekSignPlatform_FetchInfo()
	BP_Week_SignUp_Platform = BP_Platform;
	BP_Week_SignUp_Startup = BP_StartUpType;
	BP_Week_SignUp_QQVip = DataMgr.roleData.qq_vip;
end

function WeekSignUpUI.SendSignMsg()
    local cost = WeekSignUpUI.GetSignUpCost(BP_Request_SignUp_day);
    log(string.format("RequestSign :%d %d", BP_Request_SignUp_day, cost));
    WeekSignUpSystem.SendWeekSignUpReq(BP_Request_SignUp_day, cost);
end

function WeekSignUpUI.GetSignUpCost(day)
    local cost = 0;
    if day < BP_CurrentSignUpDayInWeek then
        local data = Client.GetTableData("WeekSignUpResignCost", DataMgr.WeekSignUpInfo.Resign_times + 1);
        if data ~= nil then
            cost = data.ResignCost;
        end
    end

    return cost;
end

local WeekSignUpSecondsOfDay = 24*60*60;
function WeekSignUpUI.UpdateTimeString( ... )

    local curTime = FuncUtil.GetServerTimeInSec();
    local curDate = os.date("*t", curTime);

    -- 时间设置到0点
    curDate.hour = 0;
    curDate.min = 0;
    curDate.sec = 0;

    BP_CurrentSignUpDayInWeek = FuncUtil.GetWeekDay(curDate.wday); -- 装换一下周几，lua中1代表星期天

    local timeOffset = BP_CurrentSignUpDayInWeek - 1; -- 减掉周一获取偏移量

    WeekSignUpUI.StartTimeInSec = os.time(curDate) - timeOffset * WeekSignUpSecondsOfDay;  -- 第一天的0点
    WeekSignUpUI.EndTimeInSec = WeekSignUpUI.StartTimeInSec + 7 * WeekSignUpSecondsOfDay - 1; -- 最后一天的23.59.59
    local startTime = os.date("%Y.%m.%d", WeekSignUpUI.StartTimeInSec);    -- 第一天
    local endTime = os.date("%Y.%m.%d", WeekSignUpUI.EndTimeInSec);    -- 第七天

    BP_Week_SignUp_TimeString = string.format("%s-%s", startTime, endTime);
end

function OnWeekSignUpUpdated(...)
    -- 如果不是第一次更新
    -- if BP_CurrentSignUpDayInWeek ~= 0 then
    --     local currentTime = FuncUtil.GetServerTimeInSec();

    --     if currentTime > WeekSignUpUI.EndTimeInSec then -- 超过最后一天了，刷新数据
    --         log(string.format("EventWeekSignUpReq:超过最后一天了，刷新数据 %d %d", currentTime, WeekSignUpUI.EndTimeInSec));

    --         WeekSignUpUI.ResetData();
    --         DataMgr.ResetWeekSignUpInfo();
    --         OnWeekSignUpUpdated();
    --         return;
    --     end
    -- end

    -- 刷新时间
    WeekSignUpUI.UpdateTimeString();

    -- 刷新界面状态
    local hasResign = false;
    local weekData = WeekSignUpSystem.GetWeekData(WeekSignUpUI.StartTimeInSec);
    log_tree("OnWeekSignUpUpdated 1", weekData);
    if weekData == nil then
        return;
    end

    for i = 1, WeekSignUpSystem.day_amount do
        local newStatus = DataMgr.WeekSignUpInfo.AwardState[i];
        local resignCost = 0;
        if newStatus ~= WeekSignUpSystem.status_awarded then  -- 如果没有领取过奖励，判断一下是补签还是签到
            if i < BP_CurrentSignUpDayInWeek then
                if hasResign then
                    newStatus = WeekSignUpSystem.status_notfinish;
                else
                    newStatus = WeekSignUpSystem.status_resignup;
                    hasResign = true;
                end
            elseif i == BP_CurrentSignUpDayInWeek then
                newStatus = WeekSignUpSystem.status_notaward;
            elseif i > BP_CurrentSignUpDayInWeek then
                newStatus = WeekSignUpSystem.status_notfinish;
            end
        end

        local signUpCfg = weekData[i];
        BP_ARRAY_Week_SignUp_Info[i].status = newStatus;
        WeekSignUpUI.InitItemInfo(BP_ARRAY_Week_SignUp_Info[i], signUpCfg.DropID);
    end

    -- log_tree("OnWeekSignUpUpdated 2", BP_ARRAY_Week_SignUp_Info);
    LuaClassObj.HandleUIMessage(bp_week_signup, "UpdateUI");
end


function WeekSignUpUI.InitItemInfo(info, dropID)
    local dropList = GetDropList(dropID);

    if #dropList ~= 0 then
        local firstDrop = dropList[1];
        local itemInfo = Client.GetTableData("Item", firstDrop.DropItemID);
        -- log_tree("WeekSignUpUI.InitItemInfo : ", itemInfo);
        info.itemName = firstDrop.Desc;
        info.itemImage = itemInfo.ItemBigIcon;
        info.itemQuality = itemInfo.ItemQuality;
        info.itemResID = itemInfo.ItemID;
    else
        sandbox.LogError("WeekSignUpUI.InitItemInfo dropList is empty!");
    end
end

function OnWeekSignUpResult(eventType, eventID, result)
    -- body
    if result.isSuccessed then
        log_tree("OnWeekSignUpResult", result);
        local arrayItemData = result.dropList or {}
        -- if result.dropList ~= nil then
        --     for k, v in pairs(result.dropList) do
        --         table.insert(arrayItemData, {res_id = k, count = v});
        --     end
        -- end

        if #arrayItemData == 0 then
            sandbox.LogError("OnWeekSignUpResult list empty!");
        else
            log_tree("OnWeekSignUpResult:arrayItemData=",arrayItemData);
            CommonItemGetUI:ShowPanel(arrayItemData);
        end
    else
        OnWeekSignUpUpdated();  -- 出错了，刷新一下界面状态
    end
end

function WeekSignUpUI.ResetData()
    BP_CurrentSignUpDayInWeek = 0;
    WeekSignUpUI.StartTimeInSec = 0;
    WeekSignUpUI.EndTimeInSec = 0;
end

function WeekSignUpUI.OnJumpUrl(eventType, eventID, vars)
    log("WeekSignUpUI.OnJumpUrl");
    WeekSignUpUI.ShowUI();
end

function WeekSignUpUI.Init(...)
    if not WeekSignUpUI.IsInited then
        log("WeekSignUpUI.Init");

        local data = Client.GetTableData("LocalizeRes", WeekSignUpUI.StringID_Name);
        local info = nil;
        for i = 1, WeekSignUpSystem.day_amount do
            info = FuncUtil:CopyTable(BP_STRUCT_WeekSignUpUI_Info);
            info.name = string.format(data.TextValue, i);
            BP_ARRAY_Week_SignUp_Info[i] = info;
        end

        EventSystem:registEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_SYNCINFO, OnWeekSignUpUpdated);
        EventSystem:registEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_AWARD_RESULT, OnWeekSignUpResult);
        WeekSignUpUI.IsInited = true;
    end
    OnWeekSignUpUpdated();
end

function WeekSignUpUI.Release(...)

    if WeekSignUpUI.IsInited then
        log("WeekSignUpUI.Release");
        EventSystem:unregistEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_SYNCINFO, OnWeekSignUpUpdated);
        EventSystem:unregistEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_AWARD_RESULT, OnWeekSignUpResult);
        WeekSignUpUI.IsInited = false;
    end
end

function WeekSignUpUI.ShowUI( ... )
	LuaClassObj.HandleDynamicCreation(bp_week_signup);
    log("WeekSignUpUI.ShowUI");
    LuaClassObj.HandleUIMessage(bp_week_signup, "UIShow");
end

function WeekSignUpUI.HideUI( ... )
    WeekSignUpUI.Release();
    FaceSlapSystem.ShowNext(BP_ENUM_MODULE_WEEK_SIGNUP);
end

function bp_week_signup_OnModeSwitched(gamestatus)
    log("bp_week_signup_OnModeSwitched : "..gamestatus);
    -- 回到登录场景清数据
    if string.lower(gamestatus) == "login" then
        WeekSignUpSystem.ResetData();
        WeekSignUpUI.ResetData();
        WeekSignUpUI.Release();
    elseif string.lower(gamestatus) == "lobby" then

    end
end

function WeekSignUpUI.ShouldSlap()
    log("WeekSignUpUI.ShouldSlap");
    if #DataMgr.WeekSignUpInfo.AwardState == 0 then
        return false
    end

    local weekDay = FuncUtil.GetServerWeekDay();
    if DataMgr.WeekSignUpInfo.AwardState[weekDay] == WeekSignUpSystem.status_awarded then
        return false;
    end

    -- if DataMgr.IsEightDaySlpaed then
    --     return false;
    -- end

    log("WeekSignUpUI.ShouldSlap true");
    return true;
end

function bp_week_signup_RegisterUI()
    LuaClassObj.SubUIWidgetList(bp_week_signup,
        {{Path = "/Game/UMG/UI_Logic/WeekSignUp/WeekSignUp_BP.WeekSignUp_BP_c", Container = "Default", ZOrder = BP_ENUM_UI_SIGNIN_ZORDER}},
        { "Lobby"},
        false,
        bp_week_signup_OnModeSwitched ~= nil,
		true);
    EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_WEEK_SIGNUP, WeekSignUpUI.OnJumpUrl);
end