--系统报错界面
ComplaintUI = ComplaintUI or 
{
}

COMPLAINT_REASON_NOSELECT = 0
COMPLAINT_REASON_HANGMACHINE = 1
COMPLAINT_REASON_DIRTYWORD = 2
COMPLAINT_REASON_CHEATED = 4
COMPLAINT_REASON_USEBUG = 8
COMPLAINT_REASON_NEGATIVE = 16
COMPLAINT_REASON_OTHER = 32

Complaint_BeComplaint_UserName = ""
Complaint_RoleID = ""
Complaint_StrOpenID = ""
Complaint_ReportCamp = 1
Complaint_Type1 = 0--举报类型
Complaint_Type2 = 0
Complaint_Type3 = 0
Complaint_Content = ""
Complaint_RankType = 1
Complaint_PlayerNumber = 0
Complaint_IsAI = false

BP_STRUCT_ComplaintTeammateItem = 
{
    Name = "",
}

BP_ARRAY_ComplaintTeammateList = {
	tmp_UseExist_BP_STRUCT_ComplaintTeammateItem = {},
}
----- end ----------

--注册widget
function bp_complaint_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_complaint,
    {{Path="/Game/UMG/UI_BP/PopupNotice/Inform_BP.Inform_BP_C", Container="Default", ZOrder = BP_ENUM_UI_COMMON_ITEM_GET_ZORDER}},
    {"Lobby","Login","Fighting"},
	false,
	false,
	true);
end

function EventComplaintClickSubmit()
	-- 发送
	local suggestText = DataMgr.GetMsgByIDForBattleText(30016)
	DataMgr.ShowNoticeByString(suggestText)
	PopUpNoticeUI:Init()
	
	local tSelectType = {
		type1 = Complaint_Type1,
		type2 = Complaint_Type2,
		type3 = Complaint_Type3,
	}

	LogicComplaint:Submit(Complaint_BeComplaint_UserName, Complaint_IsAI, Complaint_StrOpenID, Complaint_RoleID, Complaint_ReportCamp, tSelectType, Complaint_Content, Complaint_RankType, Complaint_PlayerNumber)
	ComplaintUI:Hide()
end

function EventComplaintClose()
	-- log("samcen EventClose")
    ComplaintUI:Hide()
end

-- 不能删除，蓝图里面调用该函数才能保证变量成功存储到lua
function EventComplaintRefreshUI()
	
end

function EventComplaintNumOverTips()
	local NumOverTips = DataMgr.GetMsgByIDForBattleText(30014)
	-- log(string.format("samcen EventClickSubmit noSelectTips:"..noSelectTips));
	DataMgr.ShowNoticeByString(NumOverTips)
	PopUpNoticeUI:Init()
end

function EventComplaintNumEmptyTips()
	local NumEmptyTips = DataMgr.GetMsgByIDForBattleText(30015)
	-- log(string.format("samcen EventClickSubmit noSelectTips:"..noSelectTips));
	DataMgr.ShowNoticeByString(NumEmptyTips)
	PopUpNoticeUI:Init()
end

function EventNameHadComplaintedTips()
	local HadComplatintedTips = DataMgr.GetMsgByIDForBattleText(30063)
	-- log(string.format("samcen EventClickSubmit noSelectTips:"..noSelectTips));
	DataMgr.ShowNoticeByString(HadComplatintedTips)
	PopUpNoticeUI:Init()
end

function ComplaintUI:Init()
	--log("samcen ComplaintUI:Init 1")
	-- for test
	--[[if BP_ARRAY_ComplaintTeammateList == nil or #BP_ARRAY_ComplaintTeammateList == 0 then
		log("samcen ComplaintUI:Init 2")
		local testNames = {{Name = "samcen20181"}, {Name = "samcen20182"}, {Name = "samcen20183"}, {Name = "samcen20184"}}
		self:CacheTeamMateList(testNames)
	end
	--end test
	]]
	LuaClassObj.HandleDynamicCreation(bp_complaint);
	LuaClassObj.HandleUIMessage(bp_complaint, "UIShow");

	-- 初始化控件和蓝图数据
	LuaClassObj.HandleUIMessage(bp_complaint, "InitUIInfo");
	BattleResultUI.SetIsReportComplaintShow(true)
end

function ComplaintUI:Hide()
	-- log("samcen ComplaintUI:Hide")
	BattleResultUI.SetIsReportComplaintShow(false)
	LuaClassObj.HandleUIMessage(bp_complaint, "UIHide");
end

function ComplaintUI:CacheTeamMateList(TeammateList)
	if TeammateList == nil then
		return
	end
	BP_ARRAY_ComplaintTeammateList = {}
	for k,v in pairs(TeammateList) do
		if  v.Name ~= nil then
			local item = {}
			item.Name = v.Name
			--log("samcen ComplaintUI:Init 3")
			table.insert(BP_ARRAY_ComplaintTeammateList, item);
		end
	end
end