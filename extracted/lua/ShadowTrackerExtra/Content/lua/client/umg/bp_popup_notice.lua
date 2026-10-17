PopUpNoticeUI = PopUpNoticeUI or 
{
}

BP_NoticeTitle = "光速小子";
BP_NoticeMsg = "光速小子";

BP_STRUCT_MessageBoxButton =
{
	ButtonText = "", -- text to show on the button
	ButtonCallback = "", -- global function to call on clicked
};

BP_STRUCT_MessageBoxData =
{
	Title = "",
	Content = "",

	BP_ARRAY_Buttons =
	{
		BP_STRUCT_MessageBoxButton = _G.BP_STRUCT_MessageBoxButton,
	}
}

BP_ARRAY_MessageBoxStack =
{
	BP_STRUCT_MessageBoxData = _G.BP_STRUCT_MessageBoxData,
}

BP_PendingMessageBoxCallback = "";

popup_notice_inited = false;

--注册Widget
function bp_popup_notice_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_popup_notice,
	{{Path="/Game/UMG/UI_BP/PopupNotice/PopupNotice_BP.PopupNotice_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_ITEMTIPS_ZORDER},
	 {Path="/Game/UMG/UI_BP/PopupNotice/GeneralPopupNotice_BP.GeneralPopupNotice_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_ITEMTIPS_ZORDER}},
    {"Lobby", "Fighting"},
	true,
	bp_popup_notice_OnModeSwitched ~= nil
  );
end


function bp_popup_notice_OnModeAboutToSwitched(gamestatus)

end


--跳转到Lobby
function bp_popup_notice_OnModeSwitched(gamestatus)
	if string.lower(gamestatus) == "lobby" then
        --拉起弹出窗控制层--
        PopUpNoticeUI:Init();
  elseif string.lower(gamestatus) == "login" and LoginSystem.hasLogout then
        popup_notice_inited = false;
        PopUpNoticeUI:Hide();
	end
end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function PopUpNoticeUI:Init()
    if(popup_notice_inited) then
        return;
    end
    popup_notice_inited = true;
	LuaClassObj.HandleUIMessage(bp_popup_notice, "UIShow");
end

function PopUpNoticeUI:Release()
end

function PopUpNoticeUI:Hide()
	LuaClassObj.HandleUIMessage(bp_popup_notice, "UIHide");
end

-- 直接弹出tips
function PopUpNoticeUI.ShowNewNotice(notice_content)
	BP_NoticeMsg = notice_content;
	PopUpNoticeUI.Init();
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowPopNotice");
end

-- 进入tips队列
function PopUpNoticeUI.ShowNewNoticeQueue(notice_content)
	BP_NoticeMsg = notice_content;
    PopUpNoticeUI.Init();
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowPopNoticeQueue");
end

-- 进入快速tips队列
function PopUpNoticeUI.ShowFastNoticeQueue(notice_content)
	BP_NoticeMsg = notice_content;
    PopUpNoticeUI.Init();
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowPopNoticeFast");
end

function PopUpNoticeUI.ShowNewMessageBox(msgbox_data)
	table.insert(BP_ARRAY_MessageBoxStack, msgbox_data);
    log_tree("BP_ARRAY_MessageBoxStack:", BP_ARRAY_MessageBoxStack);
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowMessageBox");
end

function PopUpNoticeUI.ShowMessageBox(title, msg)
	BP_NoticeMsg = msg;
    BP_NoticeTitle = title;
    PopUpNoticeUI.Init();
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowMsgBox");
end

function EventShrinkMessageBoxStack()
	table.remove(BP_ARRAY_MessageBoxStack);
end

function EventCallPendingMessageBoxCallback_Push()
	local callback = _G[BP_PendingMessageBoxCallback];
	if callback then
		pcall(callback);
	end
end

function EventShowOpenSpeakerAtFirst_Push()
	BP_NoticeMsg = Client.GetTableData("LocalizeRes", "106011").TextValue;
	PopUpNoticeUI.Init();
	LuaClassObj.HandleUIMessage(bp_popup_notice, "ShowPopNotice");
end

function EventPopupNoticeShowBox_Push()
    log_tree("BP_STRUCT_MessageBoxData:", BP_STRUCT_MessageBoxData);
    local title = Client.GetTableData("LocalizeRes", "101001").TextValue;
	CommonMessageBoxUI:ShowPanel(2, title, BP_STRUCT_MessageBoxData.." NoticePush", nil, nil);	
    --PopUpNoticeUI.ShowNewMessageBox(BP_STRUCT_MessageBoxData);
end