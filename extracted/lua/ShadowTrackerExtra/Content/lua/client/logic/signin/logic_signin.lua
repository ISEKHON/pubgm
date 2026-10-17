--[[
  签到的相关逻辑
]]--

SignInSystem = SignInSystem or
{
	TotalDays = 28;			--所有循环的总天数
	TotalDaysOnTurn = 7;	--每轮循环的总天数
	SignInPeriod = 0;
	SignInCurDay = 0;		--七天内的当天
	SignInCurDayTotal = 0;	--全部天数的当天
	SignInStartDay = 0;		--每轮循环起始的那天
	SignInEndDay = 0;		--每轮循环结束的那天
	SignInCurDayStart = 0;	--今日开启时间
	bIsInPeriod = false;
	bIsFirstLogin = false;
	SignInBtnNum = 0;		--七天中点击某天
	SignInClickDay = 0;		--所有天中点击某天
	SignInTimeRange = "";	--活动时间区间
	ServerTime = 0;			--服务器当前时间
	IsLogin = false;		--是否为登录请求
	
	SignInInfoList = {};
	SignInInfo =
	{
		sign_state = 0,	-- 1-未到，2-今日可签到，3-今日已签到，4-可补签，5-已签到
		sign_awardname1 = "",
		sign_awardimage1 = "",
		sign_awardnum1 = 0,
		sign_awardname2 = "",
		sign_awardimage2 = "",
		sign_awardnum2 = 0,
		sign_awardID1 = 0,
		sign_awardID2 = 0,
		sign_awardquality1 = 0,
		sign_awardquality2 = 0,
	};
	
	struct_signin_state =
	{
		cannot_sign = 1,
		can_sign = 2,
		is_signed = 3,
		can_resign = 4,
	}
}

function SignInSystem.Enter(isLogin)
	log("SignInSystem Enter");
	SignInSystem.IsLogin = isLogin;
	
	SignInSystem.query_server_ts_req();
end

function SignInSystem.Release()
	log("SignInSystem Release");
	SignInSystem.SignInPeriod = 0;
	SignInSystem.SignInCurDay = 0;
	SignInSystem.SignInCurDayTotal = 0;
	SignInSystem.SignInStartDay = 0;
	SignInSystem.SignInEndDay = 0;
	SignInSystem.SignInCurDayStart = 0;
	SignInSystem.bIsInPeriod = false;
	SignInSystem.bIsFirstLogin = false;
	SignInSystem.SignInBtnNum = 0;
	SignInSystem.SignInClickDay = 0;
	SignInSystem.SignInTimeRange = "";
	SignInSystem.ServerTime = 0;
	SignInSystem.IsLogin = false;
	SignInSystem.SignInInfoList = {};
end

function SignInSystem.IsInPeriod()
	log("SignInSystem IsInPeriod");
	
	local periodconf = Client.GetTable("SignInPeriodConfig");
	local start_time = 0;
	local end_time = 0;
	local cur_time = SignInSystem.ServerTime;
	--测试
	-- local cur_time = os.time({year =2017, month = 12, day =14, hour =23, min =59, sec = 59});
	for k,v in pairs(periodconf) do
		start_time = SignInSystem.TransDateToTime(v.StartTime);
		end_time = SignInSystem.TransDateToTime(v.EndTime);
		if cur_time >= start_time and cur_time <= end_time then
			SignInSystem.SignInPeriod = v.Period;
			SignInSystem.SignInCurDayStart = start_time;
			SignInSystem.bIsInPeriod = true;
			return true;
		end
	end
	
	return false;
end

function SignInSystem.GetSignInInfo()
	log("SignInSystem GetSignInInfo");
	
	local curPeriodStateList = DataMgr.SignInInfo.login_reward[SignInSystem.SignInPeriod];
	if curPeriodStateList == nil then
		curPeriodStateList = {};
	end
	--测试
	-- local curPeriodStateList = {true,nil,true,nil,true,nil,true,
								-- nil,true,true,nil,true,nil,nil,
								-- true,true,nil,nil,true,nil,nil,
								-- nil,nil,nil,nil,nil,nil,nil};
	local start_time = 0;
	local end_time = 0;
	local cur_time = SignInSystem.ServerTime;
	--测试
	-- local cur_time = os.time({year =2017, month = 12, day =14, hour =23, min =59, sec = 59});
	local start_date = "";
	local end_date = "";
	local awardconf = Client.GetTable("SignInAwardConfig");
	
	--设置各天数参数
	for k,v in pairs(awardconf) do
		start_time = SignInSystem.TransDateToTime(v.StartTime);
		end_time = SignInSystem.TransDateToTime(v.EndTime);
		if cur_time >= start_time and cur_time <= end_time then
			SignInSystem.SignInCurDayTotal = v.Day;
			SignInSystem.SignInCurDay = math.fmod(v.Day, SignInSystem.TotalDaysOnTurn);
			if SignInSystem.SignInCurDay == 0 then
				SignInSystem.SignInCurDay = SignInSystem.TotalDaysOnTurn;
			end
			SignInSystem.SignInStartDay = v.Day - SignInSystem.SignInCurDay + 1;
			SignInSystem.SignInEndDay = SignInSystem.SignInStartDay + SignInSystem.TotalDaysOnTurn - 1;
			break;
		end
	end
	
	--设置奖励列表数据
	for k,v in pairs(awardconf) do
		if v.Day >= SignInSystem.SignInStartDay and v.Day <= SignInSystem.SignInEndDay then
			local index = v.Day - SignInSystem.SignInStartDay + 1;
			SignInSystem.SignInInfoList[index] = FuncUtil:CopyTable(SignInSystem.SignInInfo);
			local Info = SignInSystem.SignInInfoList[index];
			local itemData = Client.GetTableData("Item", v.AwardID1);
			if itemData ~= nil then
				Info["sign_awardname1"] = itemData.ItemName;
				Info["sign_awardimage1"] = itemData.ItemBigIcon;
				Info["sign_awardnum1"] = v.AwardNum1;
				Info["sign_awardID1"] = v.AwardID1;
				Info["sign_awardquality1"] = itemData.ItemQuality;
				log_tree("SignInSystem SignInInfoList itemData:", Info);
			end
			
			if v.Day == SignInSystem.SignInStartDay then
				start_date = v.StartTime;
			end
			if v.Day == SignInSystem.SignInEndDay then
				end_date = v.StartTime;
			end
		end
	end
	
	--设置奖励领取状态sign_state
	for k,v in pairs(SignInSystem.SignInInfoList) do
		local index = SignInSystem.SignInStartDay + k - 1;
		local bIsGetAward = curPeriodStateList[index];
		if k > SignInSystem.SignInCurDay then
			v.sign_state = SignInSystem.struct_signin_state.cannot_sign;
		elseif k == SignInSystem.SignInCurDay then
			if bIsGetAward == nil then
				v.sign_state = SignInSystem.struct_signin_state.can_sign;
			else
				v.sign_state = SignInSystem.struct_signin_state.is_signed;
			end
		else
			if bIsGetAward == nil then
				v.sign_state = SignInSystem.struct_signin_state.can_resign;
			else
				v.sign_state = SignInSystem.struct_signin_state.is_signed;
			end
		end
	end
	
	--设置活动时间区间
	start_date = SignInSystem.FormatDate(start_date);
	end_date = SignInSystem.FormatDate(end_date);
	SignInSystem.SignInTimeRange = start_date .. "-" .. end_date;
	
	log_tree("SignInSystem SignInInfoList:", SignInSystem.SignInInfoList);
end

function SignInSystem.TransDateToTime(date_str)
	log("SignInSystem TransDateToTime");
	
	local date_tab = {};
	local index = 1;
	for value in string.gmatch(date_str, "%d+") do
		date_tab[index] = tonumber(value);
		index = index + 1;
	end
	for i = 1, 6 do
		if date_tab[i] == nil then
			return 0;
		end
	end
	local time_num = os.time({year=date_tab[1], month=date_tab[2], day=date_tab[3],
							hour=date_tab[4], min=date_tab[5], sec=date_tab[6]});
	return time_num;
end

function SignInSystem.FormatDate(date_str)
	log("SignInSystem FormatDate");
	
	local date_tab = {};
	local index = 1;
	for value in string.gmatch(date_str, "%d+") do
		date_tab[index] = tonumber(value);
		index = index + 1;
	end
	for i = 1, 3 do
		if date_tab[i] == nil then
			return date_str;
		end
	end
	local format_date = table.concat(date_tab, ".", 1, 3);
	
	return format_date;
end

function SignInSystem.ProcGetAwardBtnClick(day)
	SignInSystem.SignInBtnNum = day;
	SignInSystem.SignInClickDay = SignInSystem.SignInStartDay + day - 1;
	SignInSystem.fetch_login_reward_req(SignInSystem.SignInPeriod, SignInSystem.SignInClickDay);
	--测试
	-- SignInSystem.GetAward();
end




--请求获取服务器时间
function SignInSystem.query_server_ts_req()
	log("SignInSystem query_server_ts_req");
	NetUtil.SendPriorityPkg(true, "query_server_ts_res", "query_server_ts_req");
end

--请求获取奖励
function SignInSystem.fetch_login_reward_req(period, day)
	log("SignInSystem fetch_login_reward_req");
	NetUtil.SendPriorityPkg(true, "fetch_login_reward_res", "fetch_login_reward_req", period, day);
end



--响应请求服务器时间
function SignInSystem.query_server_ts_res(server_ts)
	log("SignInSystem query_server_ts_res");
	SignInSystem.ServerTime = server_ts;
	SignInSystem.SignInPeriod = 0;
	SignInSystem.SignInCurDay = 0;
	SignInSystem.SignInCurDayTotal = 0;
	SignInSystem.SignInStartDay = 0;
	SignInSystem.SignInEndDay = 0;
	SignInSystem.SignInCurDayStart = 0;
	SignInSystem.bIsInPeriod = false;
	SignInSystem.bIsFirstLogin = false;
	SignInSystem.SignInBtnNum = 0;
	SignInSystem.SignInClickDay = 0;
	SignInSystem.SignInTimeRange = "";
	SignInSystem.SignInInfoList = {};
	
	local bInPeriod = SignInSystem.IsInPeriod();
	if bInPeriod then
		SignInSystem.GetSignInInfo();
		if SignInSystem.IsLogin then
			if DataMgr.SignInInfo.last_login_reward_remind < SignInSystem.SignInCurDayStart then
				SignInSystem.bIsFirstLogin = true;
				NetUtil.SendPkg("recv_login_reward_remind");
			end
		end
	end
	
	SignInUI.Init(SignInSystem.IsLogin);
end

--响应获取奖励
function SignInSystem.fetch_login_reward_res(res, reward_detail)
	log("SignInSystem fetch_login_reward_res");
	
	if res ~= 0 then
		DataMgr.ShowMessageBoxByID(res);
		return;
	end
	
	--修改界面状态
	SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_state = SignInSystem.struct_signin_state.is_signed;
	EventSystem:postEvent(EVENTTYPE_SIGNIN, EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD);
	
	--修改大厅领取信息
	DataMgr.UpdateSignInData(SignInSystem.SignInPeriod, SignInSystem.SignInClickDay);
	
	--显示领取到的数据
	local arrayItemData = 
	{
		{
			res_id = SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_awardID1,
			count = SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_awardnum1,
		},
	}
	CommonItemGetUI:ShowPanel(arrayItemData);
end



--测试
function SignInSystem.GetAward()
	log("SignInSystem GetAward");
	
	--修改界面状态
	SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_state = SignInSystem.struct_signin_state.is_signed;
	EventSystem:postEvent(EVENTTYPE_SIGNIN, EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD);
	
	--修改大厅领取信息
	
	--显示领取到的数据
	local arrayItemData = 
	{
		{
			res_id = SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_awardID1,
			count = SignInSystem.SignInInfoList[SignInSystem.SignInBtnNum].sign_awardnum1,
		},
	}
	log_tree("arrayItemData=",arrayItemData);
	CommonItemGetUI:ShowPanel(arrayItemData);
end





s2c["fetch_login_reward_res"] = SignInSystem.fetch_login_reward_res;
s2c["query_server_ts_res"] = SignInSystem.query_server_ts_res;








