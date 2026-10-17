--系统报错界面
LobbyReportBug = LobbyReportBug or 
{
}


REPROTBUG_REASON_CANNOTENTERBATTLE = 10;

--注册widget
function bp_lobby_reportbug_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_lobby_reportbug,
    {{Path="/Game/UMG/UI_BP/PopupNotice/LobbyReportBug_UIBP.LobbyReportBug_UIBP_C", Container="Default", ZOrder = BP_ENUM_UI_COMMON_ITEM_GET_ZORDER}},
    {"Lobby"},
	false,
	false,
	true);
end


function EventShowLobbyBugReportPanel()
	LobbyReportBug:Init();
end

function LobbyReportBug:Init()
	LuaClassObj.HandleDynamicCreation(bp_lobby_reportbug);
	LuaClassObj.HandleUIMessage(bp_lobby_reportbug, "UIShow");
end

function EventShowLobbyBugReportSuccessMsg()
	PopUpNoticeUI:Init()
	local suggestText = DataMgr.GetMsgByIDForBattleText(30008)
	DataMgr.ShowNoticeByString(suggestText)
end

function LobbyReportBug:Release()

end

function LobbyReportBug:Hide()
	LuaClassObj.HandleUIMessage(bp_lobby_reportbug, "UIHide");
end