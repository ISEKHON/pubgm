WeekSignUpSystem = WeekSignUpSystem or
{
    day_amount = 7, --7天的数据

    -- 预定义状态
    status_notfinish = 0; --未完成
    status_notaward = 1; --未领取
    status_awarded = 2; --已领取
    status_resignup = 3;    -- 补签

    LastWeek = 0;
    TableData = nil;
}

function WeekSignUpSystem.week_signup_award_res(res, day, itemList)
    log("WeekSignUpSystem.week_signup_award_res :"..res);

    -- body
    if res ~= nil and string.lower(res) == "ok" then
        DataMgr.UpdateWeekSignUpInfo(day, WeekSignUpSystem.status_awarded);
        
        if day < FuncUtil.GetServerWeekDay() then
            DataMgr.WeekSignUpInfo.Resign_times = DataMgr.WeekSignUpInfo.Resign_times + 1;
        end

        WeekSignUpSystem.PostUpdateStatus(); 
        log_tree(string.format("-- day[%d] itemList:", day), itemList);
        EventSystem:postEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_AWARD_RESULT, {isSuccessed = true, dropList = itemList}); 
    else
        if res ~= nil then
            DataMgr.ShowMessageBoxByID(res);
        end
        EventSystem:postEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_AWARD_RESULT, {isSuccessed = false}); 
    end 
end

function WeekSignUpSystem.week_signup_chg_notify(signup)
    log_tree("WeekSignUpSystem.week_signup_chg_notify :", signup);
    DataMgr.InitWeekSignUpList(signup);
end

function WeekSignUpSystem.PostUpdateStatus()
    -- body
    EventSystem:postEvent(EVENTTYPE_WEEK_SIGNUP, EVENTID_WEEK_SIGNUP_SYNCINFO); 
end

function WeekSignUpSystem.SendWeekSignUpReq(day, gold)
    -- body    
    NetUtil.SendPriorityPkg(false, "week_signup_award_res", "week_signup_award_req", day, gold);
end

function WeekSignUpSystem.GetWeekData(timeInSec)
    WeekSignUpSystem.InitTableData();

    -- log_tree(string.format("WeekSignUpSystem.GetWeekData ：%d %d", timeInSec, WeekSignUpSystem.LastWeek), WeekSignUpSystem.TableData);
    -- log("WeekSignUpSystem.GetWeekData :"..os.date("%x", timeInSec));

    if timeInSec > WeekSignUpSystem.LastWeek then
        return WeekSignUpSystem.TableData[WeekSignUpSystem.LastWeek];
    end

    local result = WeekSignUpSystem.TableData[timeInSec];
    if result == nil then
        sandbox.LogError("WeekSignUpSystem.TableData[timeInSec] == nil");
        return nil;
    end

    return result;
end

function WeekSignUpSystem.InitTableData()
    if WeekSignUpSystem.TableData ~= nil then
        return;
    end

    -- 初始化表格数据容器
    WeekSignUpSystem.TableData = {};
    WeekSignUpSystem.LastWeek = 0;
    local tempTable = {};
    local cfgTable = Client.GetTable("WeekSignUpTable");
    -- log_tree("WeekSignUpSystem.InitTableData", cfgTable);
    for k,v in pairs(cfgTable) do
        tempTable[v.Date] = tempTable[v.Date] or {};
        tempTable[v.Date][v.WeekDay] = v;
    end

    -- log_tree("WeekSignUpSystem.InitTableData 1", tempTable);


    -- 转成时间后保存
    for k,v in pairs(tempTable) do
        local strY, strM, strD = string.match(k, "(%d+)-(%d+)-(%d+)");
        local sec =os.time({year=tonumber(strY), month=tonumber(strM), day=tonumber(strD), hour = 0});
        WeekSignUpSystem.LastWeek = math.max(WeekSignUpSystem.LastWeek, sec);
        WeekSignUpSystem.TableData[sec] = v;
    end
    -- log_tree("WeekSignUpSystem.InitTableData 2", WeekSignUpSystem.TableData);
end

function WeekSignUpSystem.ResetData()
    WeekSignUpSystem.TableData = nil;
end

s2c = s2c or {};
s2c["week_signup_award_res"] = WeekSignUpSystem.week_signup_award_res; 
s2c["week_signup_chg_notify"] = WeekSignUpSystem.week_signup_chg_notify;