--[[
	吃鸡红包分享 2017-12-16
--]]

ShareCJHBUI = ShareCJHBUI or {
	
}

BP_CJHBRoomId = "";
BP_CJHBRemainNum = "";

function bp_share_cjhb_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_cjhb,
		{				
			{Path="/Game/UMG/UI_Logic/Share/Share_CJ_LogicBP.Share_CJ_LogicBP_C", Container="Top", ZOrder=BP_ENUM_UI_Share_cjhb_ZORDER},
		},
		{"Lobby", "Fighting"},      -- 在login调试，最后改成 Fighting
		false,
		false
	);
end	

function ShareCJHBUI.UpdateUI()

	LuaClassObj.HandleUIMessage(bp_share_cjhb, "UpdateUI");	
end 

--显示UI 
function ShareCJHBUI.ShowUI()

	
	LuaClassObj.HandleUIMessage(bp_share_cjhb, "ShowUI");	
end

function ShareCJHBUI.SetRoomId(roomid, remainNum)
	if roomid ~= nil then
		BP_CJHBRoomId = tostring(roomid);
	end
	if remainNum ~= nil then
		BP_CJHBRemainNum = string.format(Client.GetTableData("LocalizeRes", "301295").TextValue, remainNum);
	end
	--请求服务器代发http请求
	-- RedPacketSystem.HttpReqTryTime = 3;
	-- RedPacketSystem.SendHttpReq(roomid);
end

function EventShareCJFinaly_Push()
	--蓝图变量同步给lua
end

function EventShareCJFinalyFetchInfo()
	--lua变量同步蓝图
end

--给蓝图调用的HideUI
function EventHideCJUI()
	LuaClassObj.HandleUIMessage(bp_share_cjhb, "HideUI");	
end

--我要分享
function EventClickShareCJBtn()
	log("EventClickShareCJBtn");	
	--LuaClassObj.HandleUIMessage(bp_share_cjhb, "HideUI");	  --暂时不关闭方便调试
	RedPacketSystem.ShareSpringPacketToFrd(BP_CJHBRoomId);
end

