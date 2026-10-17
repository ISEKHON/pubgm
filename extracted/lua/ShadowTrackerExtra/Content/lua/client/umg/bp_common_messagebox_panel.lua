CommonMessageBoxUI = CommonMessageBoxUI or 
{
	mySelf,
	onClickOkCallback,
	onClickCancelCallback,
    onTimerInvoke,
	isShowing = false,
	
	isConnectionPanel = false,
		
	listShowInfo = {},
}

-- 显示的标题
BP_CommonMessageBox_title = "";
-- 显示的信息
BP_CommonMessageBox_msg = "";
-- 样式类型
-- 1 只有确定按钮
-- 2 有确定和取消按钮
BP_CommonMessageBox_style= 1;
--按钮文字
BP_CommonMessageBox_OK = "";
BP_CommonMessageBox_Cancel = "";


-- 注册面板
function bp_common_messagebox_panel_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_common_messagebox_panel,
		{{Path="/Game/UMG/UI_Logic/Common/Common_MessageBox_Panel_BP.Common_MessageBox_Panel_BP_C", Container="Top", ZOrder=BP_ENUM_UI_COMMON_MESSAGEBOX_ZORDER}},
		{"Lobby","Login","Fighting","CreateRole", "Pending"},
		true,
		false,
		true
	);	
    
	--BP_CommonMessageBox_OK = "确定";
    --BP_CommonMessageBox_Cancel = "取消";
	BP_CommonMessageBox_OK = Client.GetTableData("LocalizeRes",110036).TextValue;
    BP_CommonMessageBox_Cancel = Client.GetTableData("LocalizeRes",110035).TextValue;
	
	CommonMessageBoxUI.listBoxInfo = {};
	CommonMessageBoxUI.isShowing = false;
	CommonMessageBoxUI.isConnectionPanel = false;
end

-- 通用提示框
-- styleType 	1 只有确定按钮
-- 				2 有确定和取消按钮
function CommonMessageBoxUI:ShowPanel(styleType, title, msg, clickOkCallback, clickCancelCallback, btnOK, btnCancel, isConnectionPanel, timerCallback)
	LuaClassObj.HandleDynamicCreation(bp_common_messagebox_panel);

	log("CommonMessageBoxUI:ShowPanel ".. msg..", isShowing: "..tostring(self.isShowing));
	
	if CommonMessageBoxUI.mySelf and CommonMessageBoxUI.mySelf.isShowing and BP_CommonMessageBox_msg == msg then
		log("same CommonMessageBoxUI 1");
		return false;
	end
	
	for k,v in pairs(CommonMessageBoxUI.listShowInfo) do
		if v.msg == msg then
			log("same CommonMessageBoxUI 2");
			return false;
		end
	end
	
	local msgInfo = {
		styleType = styleType,
		title = title,
		msg = msg,
		clickOkCallback = clickOkCallback,
		clickCancelCallback = clickCancelCallback,
        onTimerInvoke = timerCallback,
		btnOK = btnOK,
		btnCancel = btnCancel,
		isConnectionPanel = isConnectionPanel or false,
		};
	
	table.insert(CommonMessageBoxUI.listShowInfo, msgInfo);
	
	CommonMessageBoxUI.mySelf = self;	
	if not CommonMessageBoxUI.mySelf.isShowing then
		CommonMessageBoxUI:ShowNextPanel();
	end	
	
	return true;
end

-- 显示网络连接相关的提示面板
function CommonMessageBoxUI:ShowConnectionPanel(styleType, title, msg, clickOkCallback, clickCancelCallback, btnOK, btnCancel)
	local isShowResult = CommonMessageBoxUI:ShowPanel(styleType, title, msg, clickOkCallback, clickCancelCallback, btnOK, btnCancel, true);			
end

-- 显示每秒刷新相关的提示面板
function CommonMessageBoxUI:ShowTimerPanel(styleType, title, msg, clickOkCallback, clickCancelCallback, btnOK, btnCancel,timercallback)
	CommonMessageBoxUI:ShowPanel(styleType, title, msg, clickOkCallback, clickCancelCallback, btnOK, btnCancel, false, timercallback);
end

function CommonMessageBoxUI:HideAllMessageBox()
	log("CommonMessageBoxUI:HideAllMessageBox");
	CommonMessageBoxUI.listShowInfo = {};
	
	if CommonMessageBoxUI.mySelf ~= nil and CommonMessageBoxUI.mySelf.isShowing then
		CommonMessageBoxUI:HidePanel();
	end
end

-- 显示下一个提示面板
function CommonMessageBoxUI:ShowNextPanel()
	if #CommonMessageBoxUI.listShowInfo == 0 then
		return;
	end
	
	LuaClassObj.HandleDynamicCreation(bp_common_messagebox_panel);
	
	local showInfo = CommonMessageBoxUI.listShowInfo[1];
	log_tree("CommonMessageBoxUI:ShowNextPanel", showInfo);
	
	BP_CommonMessageBox_style = showInfo.styleType;
	BP_CommonMessageBox_title = showInfo.title;
	BP_CommonMessageBox_msg = showInfo.msg;
	BP_CommonMessageBox_OK = showInfo.btnOK;
	BP_CommonMessageBox_Cancel = showInfo.btnCancel;
    if showInfo.btnOK == nil then
        BP_CommonMessageBox_OK = Client.GetTableData("LocalizeRes", "110036").TextValue
    end
    if showInfo.btnCancel == nil then
        BP_CommonMessageBox_Cancel = Client.GetTableData("LocalizeRes", "110035").TextValue
    end
    
	CommonMessageBoxUI.onClickOkCallback = showInfo.clickOkCallback;
	CommonMessageBoxUI.onClickCancelCallback = showInfo.clickCancelCallback;
	CommonMessageBoxUI.onTimerInvoke = showInfo.onTimerInvoke;
	CommonMessageBoxUI.isShowing = true;
	CommonMessageBoxUI.isConnectionPanel = showInfo.isConnectionPanel;
	
	LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIShow");
    
    if(CommonMessageBoxUI.onTimerInvoke ~= nil) then
        LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "StartTimerInvoke");
    end
	
	table.remove(CommonMessageBoxUI.listShowInfo, 1);
end

-- 关闭面板
function CommonMessageBoxUI:HidePanel()
	log("CommonMessageBoxUI:HidePanel "..BP_CommonMessageBox_msg);
	if CommonMessageBoxUI.mySelf then
		CommonMessageBoxUI.mySelf.isShowing = false;
		LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIHide");	
	end
end

-- 关闭连接异常面板
function CommonMessageBoxUI:HideConnectionPanel()
	log("CommonMessageBoxUI:HideConnectionPanel "..BP_CommonMessageBox_msg);
	-- 先删除队列中的连接异常消息
	local index = 1;
	while( CommonMessageBoxUI.listShowInfo and #CommonMessageBoxUI.listShowInfo > 0 and index <= #CommonMessageBoxUI.listShowInfo ) do
		if CommonMessageBoxUI.listShowInfo[index].isConnectionPanel then
			table.remove(CommonMessageBoxUI.listShowInfo, index);
		else
			index = index + 1;
		end
	end
	
	-- 删除当前弹出的连接异常消息
	if CommonMessageBoxUI.mySelf and CommonMessageBoxUI.mySelf.isConnectionPanel then
		CommonMessageBoxUI.mySelf.isShowing = false;
		LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UIHide");	
	end	
end

-- 当前是否开启面板
function CommonMessageBoxUI:IsShowing()
	if CommonMessageBoxUI.mySelf then
		return CommonMessageBoxUI.mySelf.isShowing;
	else
		return false;
	end
end

function CommonMessageBoxUI:UpdateMsg(msg)
    if(CommonMessageBoxUI.mySelf.onTimerInvoke == nil) then
        LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "DeleteTimerInvoke");	
        return;
    end
    BP_CommonMessageBox_msg = msg;
	LuaClassObj.HandleUIMessage(bp_common_messagebox_panel, "UpdateMsg");	
end

function EventFetchInfo()
    
end

-- 通用提示框关闭回调
function EventCommonMessageBoxAfterHide()
	log("EventCommonMessageBoxAfterHide");
	
	if CommonMessageBoxUI.mySelf then
		CommonMessageBoxUI.mySelf.isShowing = false;
	end
	
	CommonMessageBoxUI:ShowNextPanel();
end

function EventCommonMessageBoxClickOK()
	log("EventCommonMessageBoxClickOK");
	if CommonMessageBoxUI.mySelf.onClickOkCallback ~= nil then
		CommonMessageBoxUI.mySelf.onClickOkCallback();
	end
	CommonMessageBoxUI.mySelf.isShowing = false;
end

function EventCommonMessageBoxClickCancel()
	log("EventCommonMessageBoxClickCancel");
	if CommonMessageBoxUI.mySelf.onClickCancelCallback ~= nil then
		CommonMessageBoxUI.mySelf.onClickCancelCallback();
	end
	CommonMessageBoxUI.mySelf.isShowing = false;
end

function EventCommonMessageBoxTimerInvoke()
    if( CommonMessageBoxUI.mySelf.onTimerInvoke ~= nil) then
        CommonMessageBoxUI.mySelf.onTimerInvoke();
    end
end

