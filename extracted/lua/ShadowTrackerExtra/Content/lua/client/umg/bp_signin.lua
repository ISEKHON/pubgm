--签到
SignInUI = SignInUI or
{
	ResignNeedGold = 900;
	
	struct_signin_state =
	{
		cannot_sign = 1,
		can_sign = 2,
		is_signed = 3,
		can_resign = 4,
	}
}

BP_SignInUITimeRange = "";	--活动时间区间
BP_SignInBtnNum = 0;	--记录蓝图点击哪天的领取按钮
BP_SignInTotalDays = 7;	--每轮循环的总天数

--签到信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_SignInUIInfo =
{
	sign_state = 0,	--1-未到，2-今日可签到，3-已签到，4-可补签
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

--签到信息列表(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
BP_ARRAY_SignInUIList =
{
	BP_STRUCT_SignInUIInfo = _G.BP_STRUCT_SignInUIInfo,	--定义结构体数组，这种写法要作为规范规定下来
};

--注册Widget
function bp_signin_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_signin,
		{{Path="/Game/UMG/UI_Logic/SignIn/SignIn_BP.SignIn_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SIGNIN_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
end

local function SignInEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_SIGNIN then
		return;
	end
	
	--领奖后更新界面信息
	if eventID == EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD then
		log("EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD");
		SignInUI.UnifyDataAfterGetAward();
		SignInUI.UpdateAfterGetAward();
	end
end

function SignInUI.Init(isLogin)
	log("SignInUI Init");
	
	if SignInSystem.bIsInPeriod then
		-- log("1111111111111111111111111111111111");
		if isLogin and SignInSystem.bIsFirstLogin == false then
			return;
		end
		
		BP_SignInUITimeRange = "";
		BP_SignInBtnNum = 0;
		
		EventSystem:registEvent(EVENTTYPE_SIGNIN, EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD, SignInEventHandler);
		
		SignInUI.UnifyAllData();
		SignInUI.UpdateSignInInfo();
	end
end

function SignInUI.Release()
	log("SignInUI Release");
	BP_SignInUITimeRange = "";
	BP_SignInBtnNum = 0;
	
	EventSystem:unregistEvent(EVENTTYPE_SIGNIN, EVENTID_SIGNIN_UPDATE_AFTER_GETAWARD, SignInEventHandler);
end

function SignInUI.Hide()
	log("SignInUI Hide");
	LuaClassObj.HandleUIMessage(bp_signin, "UIHide");
end

function SignInUI.UnifyAllData()
	log("SignInUI UnifyAllData");
	
	BP_ARRAY_SignInUIList = {};
	
	for i = 1, BP_SignInTotalDays do
		BP_ARRAY_SignInUIList[i] = FuncUtil:CopyTable(SignInSystem.SignInInfoList[i]);
	end
	
	BP_SignInUITimeRange = SignInSystem.SignInTimeRange;
end

function SignInUI.UpdateSignInInfo()
	LuaClassObj.HandleDynamicCreation(bp_signin);
	
	if LuaClassObj ~= nil then
		log("SignInUI UpdateSignInInfo");
		LuaClassObj.HandleUIMessage(bp_signin, "UIShow");
		LuaClassObj.HandleUIMessage(bp_signin, "UpdateSignInInfo");
	end
end

function SignInUI.UnifyDataAfterGetAward()
	log("SignInUI UnifyDataAfterGetAward");
	BP_ARRAY_SignInUIList[BP_SignInBtnNum].sign_state = SignInUI.struct_signin_state.is_signed;
end

function SignInUI.UpdateAfterGetAward()
	log("SignInUI UpdateAfterGetAward");
	
	LuaClassObj.HandleUIMessage(bp_signin, "UpdateAfterGetAward");
end

function SignInUI.ProcResignInBtn()
	log("SignInUI ProcResignInBtn");
	SignInSystem.ProcGetAwardBtnClick(BP_SignInBtnNum);
end


--(以Event开头的函数名就能暴露给蓝图调用)

function EventGetAwardBtnClick()
	log("SignInUI EventGetAwardBtnClick");
	-- log("BP_SignInBtnNum: "..BP_SignInBtnNum);
	-- log("SignInSystem.SignInCurDay: "..SignInSystem.SignInCurDay);
	
	if BP_SignInBtnNum == SignInSystem.SignInCurDay then
		SignInSystem.ProcGetAwardBtnClick(BP_SignInBtnNum);
	else
		if DataMgr.gold < SignInUI.ResignNeedGold then
			-- DataMgr.ShowMessageBoxByID(110053);
			local title_data = Client.GetTableData("LocalizeRes", 110052);
			local title = tostring(title_data.TextValue);
			local msg_data = Client.GetTableData("LocalizeRes", 110055);
			local msg = tostring(msg_data.TextValue);
			msg = string.format(msg, SignInUI.ResignNeedGold);
			CommonMessageBoxUI:ShowPanel(1, title, msg);
		else
			local title_data = Client.GetTableData("LocalizeRes", 110052);
			local title = tostring(title_data.TextValue);
			local msg_data = Client.GetTableData("LocalizeRes", 110054);
			local msg = tostring(msg_data.TextValue);
			msg = string.format(msg, SignInUI.ResignNeedGold);
			CommonMessageBoxUI:ShowPanel(2, title, msg, SignInUI.ProcResignInBtn);
		end
	end
end

function EventRelease()
	log("SignInUI EventRelease");
	SignInUI.Release();
	SignInSystem.Release();
end






