CommonNoticeBoxUI = CommonNoticeBoxUI or 
{
	mySelf,
	onClickOkCallback,
	onClickCloseCallback,
}

--标题和内容
BP_CommonNoticeBox_Title = "";
BP_CommonNoticeBox_Msg = "";
--OK按钮上的文字
BP_CommonNoticeBox_BtnOKTxt = "";
--1:只显示确定按钮 2:只显示关闭按钮，3：关闭和确定按钮都显示
BP_CommonNoticeBox_style= 1;

-- 注册面板
function bp_noticebox_panel_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_noticebox_panel,
		{{Path="/Game/UMG/UI_BP/PopupNotice/NoticeBox_BP.NoticeBox_BP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICEBOX_ZORDER}},
		{"Lobby","Login","CreateRole"},
		false,
		false,
		true
	);
    EventSystem:registEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN, CommonNoticeBoxUI.on_backto_login);
end


function bp_noticebox_panel_OnModeAboutToSwitched(gamestatus)

end

--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
	
end

function CommonNoticeBoxUI.on_backto_login()
	LuaClassObj.HandleUIMessage(bp_noticebox_panel, "UIHide");
end

function CommonNoticeBoxUI:ShowMessageBox(style, title, msg, btnOKText, clickOkCallback, clickCloseCallback)
	LuaClassObj.HandleDynamicCreation(bp_noticebox_panel);
    log("CommonNoticeBoxUI:ShowMessageBox");
    BP_CommonNoticeBox_style = style;
	BP_CommonNoticeBox_Msg = msg;
    BP_CommonNoticeBox_Title = title;
    BP_CommonNoticeBox_BtnOKTxt = btnOKText;
    
	mySelf = self;
	mySelf.onClickOkCallback = clickOkCallback;
	mySelf.onClickCloseCallback = clickCloseCallback;
    
	LuaClassObj.HandleUIMessage(bp_noticebox_panel, "UIShow");
end

function EventCommonNoticeBoxClickOK()
    log("CommonNoticeBoxUI:EventCommonNoticeBoxClickOK");
	if mySelf.onClickOkCallback ~= nil then
		mySelf.onClickOkCallback();
	end
end

function EventCommonNoticeBoxClickClose()
    log("CommonNoticeBoxUI:EventCommonNoticeBoxClickClose");
	if mySelf.onClickCloseCallback ~= nil then
		mySelf.onClickCloseCallback();
	end
end

