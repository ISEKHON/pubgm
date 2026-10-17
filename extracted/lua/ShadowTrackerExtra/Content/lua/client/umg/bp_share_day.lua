--[[
	每日分享 2017-12-16
--]]

ShareDayUI = ShareDayUI or {
	
}

--面板是否显示
BP_ShareDayIsShow = false;

--每日分享次数
BP_ShareDayNum = 0;

BP_ShareDayGold = 0;

--是否首次分享
BP_ShareFirst = false;

function bp_share_day_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_day,
		{				
			{Path="/Game/UMG/UI_Logic/Share/Share_DayLogicBP.Share_DayLogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_Share_Day_ZORDER},
		},
		{"Lobby"},
		false,
		false,
		true
	);
end	

function ShareDayUI.UpdateUI()
	if BP_ShareDayIsShow == false then
		return;
	end
	
	BP_ShareDayNum = ShareMgr.GetShareNum();
	log("BP_ShareDayNum"..BP_ShareDayNum);
	if BP_ShareDayNum == 0 then		
		BP_ShareFirst = true;
	end
	BP_ShareDayGold = DataMgr.GetSystemConfig("FirstShareRewardGold");
	
	LuaClassObj.HandleUIMessage(bp_share_day, "UpdateUI");	
end 

--显示UI 
function ShareDayUI.ShowUI()
	LuaClassObj.HandleDynamicCreation(bp_share_day);
	--请求分享数据
	--ShareMgr.GetShareInfoReq();
	--test
	--ShareMgr.ShareSuccReq();	
	LuaClassObj.HandleUIMessage(bp_share_day, "UIShow");	
	ShareDayUI.UpdateUI();

end

function EventShareDay_Push()
	--蓝图变量同步给lua
end

function EventShareDayFetchInfo()
	--lua变量同步蓝图
end

--关闭UI
function EventHideUI()
	LuaClassObj.HandleUIMessage(bp_share_day, "UIHide");	
end

--我要分享
function EventClickShareBtn()
	log("EventClickShareBtn");	
	--LuaClassObj.HandleUIMessage(bp_share_day, "UIHide");	
	ShareDayFinalyShareUI.ShowUI(); 
end

