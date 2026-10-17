--系统报错界面
ReportBug = ReportBug or 
{
}

REPROTBUG_REASON_MAP_ERROR = 0
REPROTBUG_REASON_MINIMAP_ERROR = 1
REPROTBUG_REASON_GAMENOTSMOOTH = 2
REPROTBUG_REASON_ABNORMAL_ANIMATION = 3
REPROTBUG_REASON_RECONNECTION_ERROR = 4
REPROTBUG_REASON_CHARACTER_NOTSMOOTH = 5
REPROTBUG_REASON_VEHICLE_NOTSMOOTH = 6
REPROTBUG_REASON_LOWFPS = 7
REPROTBUG_REASON_BAD_NET = 8
REPROTBUG_REASON_OTHER = 9

--- user select info start ---
Bug_Report_Info_DeviceName = ""
Bug_Report_Info_Reason = REPROTBUG_REASON_OTHER
Bug_Report_Info_text = ""

Bug_Report_Info_PosX = 0
Bug_Report_Info_PosY = 0
Bug_Report_Info_PosZ = 0

Bug_Report_Info_Angle = 0
----- end ----------

--注册widget
function bp_reportbug_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_reportbug,
    {{Path="/Game/UMG/UI_BP/PopupNotice/ReportBug_BP.ReportBug_BP_C", Container="Default", ZOrder = BP_ENUM_UI_COMMON_ITEM_GET_ZORDER}},
    {"Fighting"},
	false,
	false,
	true);
end

function EventClickSubmit()
	-- 没有选择
	if Bug_Report_Info_Reason == REPROTBUG_REASON_NO_SELECT then
		local noSelectTips = DataMgr.GetMsgByIDForBattleText(30009)
		-- log(string.format("samcen EventClickSubmit noSelectTips:"..noSelectTips));
		DataMgr.ShowNoticeByString(noSelectTips)
		PopUpNoticeUI:Init()
		return
	-- 选择了其它 没有内容
	elseif Bug_Report_Info_Reason == REPROTBUG_REASON_OTHER and Bug_Report_Info_text == "" then
		-- log(string.format("samcen EventClickSubmit 2"));
		--local noContentTips = DataMgr.GetMsgByIDForBattleText(30007)
		--DataMgr.ShowNoticeByString(noContentTips)
		--PopUpNoticeUI:Init()
		--return
	end
	
	local tPos = {
		x = Bug_Report_Info_PosX,
		y = Bug_Report_Info_PosY,
		z = Bug_Report_Info_PosZ
	}

	-- 发送
	local suggestText = DataMgr.GetMsgByIDForBattleText(30008)
	DataMgr.ShowNoticeByString(suggestText)
	PopUpNoticeUI:Init()
	
	LogicReportBug:report(Bug_Report_Info_DeviceName, tPos, Bug_Report_Info_Angle, Bug_Report_Info_Reason, Bug_Report_Info_text)
	ReportBug:Hide()
end

function EventClose()
    ReportBug:Hide()
end

-- 不能删除，蓝图里面调用该函数才能保证变量成功存储到lua
function EventRefreshUI()

end

function ReportBug:Init()
	LuaClassObj.HandleDynamicCreation(bp_reportbug);
	-- log(string.format("ReportBug:Init "));
	LuaClassObj.HandleUIMessage(bp_reportbug, "UIShow");
	-- 初始化数值
	self:Release()
	-- 初始化控件
	LuaClassObj.HandleUIMessage(bp_reportbug, "InitUIInfo");
	-- LuaClassObj.HandleUIMessage(bp_gm, "UIShow");
	-- LuaClassObj.HandleUIMessage(bp_setting, "UIShow");
end

function EventShowSendSuccessMsg()
	local suggestText = DataMgr.GetMsgByIDForBattleText(30008)
	DataMgr.ShowNoticeByString(suggestText)
	PopUpNoticeUI:Init()
end

function ReportBug:Release()
	-- log(string.format("ReportBug:Release "));
	Bug_Report_Info_DeviceName = ""
	Bug_Report_Info_Reason = 0
	Bug_Report_Info_text = ""

	Bug_Report_Info_PosX = 0
	Bug_Report_Info_PosY = 0
	Bug_Report_Info_PosZ = 0

	Bug_Report_Info_Angle = 0
end

function ReportBug:Hide()
	LuaClassObj.HandleUIMessage(bp_reportbug, "UIHide");
end