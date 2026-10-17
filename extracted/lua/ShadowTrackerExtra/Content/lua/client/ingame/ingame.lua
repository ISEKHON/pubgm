
function ingame_RegisterUI(self)
  
	ingame = self;
  InGameUIManager.SubUIWidgetList(self,
    {
	{Path="/Game/BluePrints/ControlInput/MainControlPanelTochButton.MainControlPanelTochButton_C", Container="Default", ZOrder=0}
	},
    {"Fighting", "Training"},
	false,
	true
  );
  
  FuncUtil:InitConfigs()
end

function ReturnToLobbyConfirm()

	local text = "<LightWhite>" + FuncUtil.GetLocalizeResStr("110140") + "</>";
	CommonMessageBoxUI:ShowPanel(2, FuncUtil.GetLocalizeResStr("101001"), text, ReturnToLobbyConfirm_YES, ReturnToLobbyConfirm_NO)
	
	--[[
	PopUpNoticeUI.ShowNewMessageBox({Title="确认", Content="<Red>请问是否退出战斗</>？...", 
		BP_ARRAY_Buttons={
			{ButtonText="确定", ButtonCallback="ReturnToLobbyConfirm_YES"},
			{ButtonText="取消", ButtonCallback="ReturnToLobbyConfirm_NO"},
		}
	});
	--]]
end

function ReturnToLobbyConfirm_YES()
	--
	Client.ReturnToLobby(GameFrontendHUD);
end

function OpenUISetting()
	SettingUI:Init();
end

function OpenReportBug()
	ReportBug:Init();
end

function OpenReportComplaint()
	ComplaintUI:Init();
end

function OpenReportComplaintInvalid()
	local InvalidStr = DataMgr.GetMsgByIDForBattleText(30022)
	-- log(string.format("samcen EventClickSubmit noSelectTips:"..noSelectTips));
	DataMgr.ShowNoticeByString(InvalidStr)
	PopUpNoticeUI:Init()
end

function CloseReportComplaint()
	ComplaintUI:Hide()
end

function ReturnToLobbyConfirm_NO()
	---
end

-- chat start
IngameChat = IngameChat or
{
}
-- 大厅向战斗内发消息
function IngameChat:on_notify_fight_friend_chat(str_gid, this_msg)
	--[[
		thisMsg.uid = str_gid;
		thisMsg.name = sender_name;
		thisMsg.msg = chat_content;	
		thisMsg.selfMsg = self_msg;	
	]]
	sandbox.LogNormal("on_friend_msg 3 sender_name:".. this_msg.name .. " says: ".. this_msg.msg);
	Client.OnNotifyFightFriendChat(GameFrontendHUD, this_msg);
end

-- 战斗内回信息
function EventSendFightChat(gid, content)
	LobbyChatSystem.fight_send_msg(gid, content);
end

-- 向大厅发送脏串
function EventSendDirtyToFilter(dirty)
	sandbox.LogNormal("EventSendDirtyToFilter:" .. dirty);
	LobbyChatSystem.filter_text_req(dirty);
end

-- 大厅返回过滤串
function IngameChat:on_filter_finish(filter_text)
	sandbox.LogNormal("on_filter_finish:" .. filter_text);
	Client.OnFilterFinish(GameFrontendHUD, filter_text);
end

-- 大厅邀请
function IngameChat:on_reserve_require_notify(str_gid, str_name)
	sandbox.LogNormal("on_reserve_require str_gid:".. str_gid .. " str_name: ".. str_name);
	Client.OnInviteNextBattle(GameFrontendHUD, str_gid, str_name);
end

-- 邀请回复
function EventReplyInviteNextBattle(gid, bReply)
	if bReply then
		sandbox.LogNormal("EventReplyInviteNextBattle gid:".. gid .. " bReply: true");
	else
		sandbox.LogNormal("EventReplyInviteNextBattle gid:".. gid .. " bReply: false");
	end
	LobbyChatSystem.on_reserve_reply_req(gid, bReply);
end

-- 进入私聊
function EventEnterFightChat(str_gid)
	LobbyChatSystem.on_enter_fight_chat(str_gid)
end

-- 离开私聊
function EventQuitFightChat()
	LobbyChatSystem.on_quit_fight_chat();
end
-- chat end