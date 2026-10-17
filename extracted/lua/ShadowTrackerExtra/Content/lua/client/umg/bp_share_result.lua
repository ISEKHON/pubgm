--[[
	结算分享页面 2017-12-12
--]]

ShareResultUI = ShareResultUI or {

}

-- 根据玩家排名来获取不同的bg
BP_PlayerRank = 1;
--
BP_PlayerCount = 100;
--
BP_KillNum = 0;
--
BP_TeamNum = 0;
--
BP_PlayerIcon = "";
--
BP_PlayerName = "LightSpeed";
--
BP_ModeKillInfo = "";
--
BP_ShareImagePath = "";

BP_LoginChannel = 0;

BP_SHARE_RESULT_TYPE = 1;  --1游戏名次分享，2游戏数据分享


--只在战斗中拉起--
function bp_share_result_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_result,
		{
			{Path="/Game/BluePrints/ControlInput/ResultsshareUI/ShareBP/ShareResult_UIBP.ShareResult_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_Share_Game_Result_ZORDER},
		},
		{"Fighting"},
		false,
		false,
		true
	);
end	 


function EventShareResult_ShowUI_Push()
	BP_PlayerName = BP_myname;
	BP_KillNum = BP_mykill;

	local msg = "";
	--单人结算和组队排名是两个字段
	if BP_STRUCT_BattleResultData.IsSolo then
		BP_PlayerRank = BP_STRUCT_BattleResultData.person_rank;
		msg = string.format(Client.GetTableData("LocalizeRes", "116002").TextValue, BP_KillNum);
	else
		BP_PlayerRank = BP_STRUCT_BattleResultData.team_rank;

		if BP_TeamNum == 1 then
			msg = string.format(Client.GetTableData("LocalizeRes", "116002").TextValue, BP_KillNum);
		end

		if BP_TeamNum == 2 then
			msg = string.format(Client.GetTableData("LocalizeRes", "116003").TextValue, BP_KillNum);
		end	

		if BP_TeamNum == 4 then
			msg = string.format(Client.GetTableData("LocalizeRes", "116004").TextValue, BP_KillNum);
		end
	end

	BP_ModeKillInfo = msg;
	BP_PlayerCount = BP_STRUCT_BattleResultData.TotalPlayerCount;
	BP_TeamNum = BP_STRUCT_BattleResultData.max_game_num;

	ShareResultUI.ShowUI();
end


--显示UI 
--参数依次为116001 116002
function ShareResultUI.ShowUI()
	LuaClassObj.HandleDynamicCreation(bp_share_result);
	BP_LoginChannel = Client.GetLoginChannel(NetInterface);
	LuaClassObj.HandleUIMessage(bp_share_result, "UIShow");	

	ClientSendBAReport(BP_BA_SHARE_MAINPANEL, 0);	--分享界面打开次数

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_BATTLEGRADEPAENL, 0);	--打开了战绩分享界面
	end	
end

--关闭UI
function ShareResultUI.HideUI()
	LuaClassObj.HandleUIMessage(bp_share_result, "UIHide");	
end

--保存本地
function EventShareResult_BtnSave()
	LuaClassObj.HandleUIMessage(bp_share_result, "SaveLocalImage");	
end

--名次分享
local  function ShareReqRankResult()
	ShareMgr.ShareSuccReq(4);
end

--战绩分享
local  function ShareReqBattleResult()
	ShareMgr.ShareSuccReq(5);
end  

--截图
function EventShareResult_BtnCaptureScreen()
	
end

function EventShareResultPanelClosed()
	BattleResultUI.EnableTickSwitch();
end

--wechat分享朋友圈
function EventShareResult_BtnShareTimeLine()

	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	if BP_SHARE_RESULT_TYPE == 2 then
		--战绩分享
		if ShareMgr.CanShareByType(5) == false then
	   		return;
		end
		ShareMgr.SetShareLimit(5);
	elseif BP_SHARE_RESULT_TYPE == 1 then
		--
		if ShareMgr.CanShareByType(4) == false then
   		return;
		end
		ShareMgr.SetShareLimit(4);
	end

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_RESULT, BP_ShareImagePath, "", "", ShareType.Moment);

	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_GRADE, 0);
		ShareReqBattleResult();		
	elseif BP_SHARE_RESULT_TYPE == 1 then
		ShareReqRankResult();
	end
end

--wechat分享好友
function EventShareResult_BtnShareFriend()

	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(110126);
		return;
	end

	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_RESULT, BP_ShareImagePath, "", "", ShareType.Friend);

	ClientSendBAReport(BP_BA_SHARE_WXFRIEND, 0);
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_GRADE, 0);	--战绩分享
		ShareReqBattleResult();
	elseif BP_SHARE_RESULT_TYPE == 1 then
		ShareReqRankResult();
	end
end

function EventShareResultVariable_Push()
	-- body
	log(BP_ShareImagePath);
end

--分享到qq好友
function EventShareResult_BtnShareQQFriend()
	--[[
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end
	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_RESULT, nil, BP_ShareImagePath, ShareType.Friend);

	ClientSendBAReport(BP_BA_SHARE_QQFRIEND, 0);
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_GRADE, 0);	--战绩分享
		ShareReqBattleResult();
	elseif BP_SHARE_RESULT_TYPE == 1 then
		ShareReqRankResult();
	end
	--]]
	
	log("[HHF]EventShareResult_BtnShareQQFriend");
	if Client.IsInstallWX(NetInterface) == false then 
		--你还没有安装微信，无法使用此功能
		DataMgr.ShowNoticeByID(4005);
		return;
	end

	--[[
	if BP_SHARE_RESULT_TYPE == 2 then
		--战绩分享
		if ShareMgr.CanShareByType(5) == false then
	   		return;
		end
		ShareMgr.SetShareLimit(5);
	elseif BP_SHARE_RESULT_TYPE == 1 then
		--
		if ShareMgr.CanShareByType(4) == false then
   		return;
		end
		ShareMgr.SetShareLimit(4);
	end
	--]]

	ConnectionWaitingUI:Show();
	ShareMgr:shareWechatWithPhoto(MEDIA_TAG_SHARE_RESULT, BP_ShareImagePath, "", "", ShareType.Moment);

	ClientSendBAReport(BP_BA_SHARE_WXFRIENDCIRCLE, 0);
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_GRADE, 0);
		ShareReqBattleResult();		
	elseif BP_SHARE_RESULT_TYPE == 1 then
		ShareReqRankResult();
	end
end

--分享到qqzone
function EventShareResult_BtnShareQQZone()
	log("[HHF]EventShareResult_BtnShareQQZone");
	if Client.IsInstallQQ(NetInterface) == false then 
		--你还没有安装QQ，无法使用此功能
		DataMgr.ShowNoticeByID(110125);
		return;
	end

	--[[
	if BP_SHARE_RESULT_TYPE == 2 then
		--游戏数据分享
		if ShareMgr.CanShareByType(5) == false then
	   		return;
		end
		ShareMgr.SetShareLimit(5);
	elseif BP_SHARE_RESULT_TYPE == 1 then
		--游戏名次分享
		if ShareMgr.CanShareByType(4) == false then
   		return;
		end
		ShareMgr.SetShareLimit(4);
	end
	--]]

	ShareMgr:shareQQWithPhoto(MEDIA_TAG_SHARE_RESULT, nil, BP_ShareImagePath, ShareType.Moment);

	ClientSendBAReport(BP_BA_SHARE_QQSPACE, 0);
	ClientSendBAReport(BP_BA_SHARE_SHAREBTN, 0);

	if BP_SHARE_RESULT_TYPE == 2 then
		ClientSendBAReport(BP_BA_SHARE_GRADE, 0);	--战绩分享
		ShareReqBattleResult();
	elseif BP_SHARE_RESULT_TYPE == 1 then
		ShareReqRankResult();
	end
end



--分享到qq部落
function EventShareResult_BtnShareQQTribe()
	
end

--分享到游戏圈
function EventShareResult_BtnShareGameZone()
	
end

