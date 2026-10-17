ShareAwardMgr = ShareAwardMgr or {
	arrDelayAwardItems = nil,
}

function ShareAwardMgr.Init()
	EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, ShareAwardMgr.EventHandler);
end

function ShareAwardMgr.EventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_SHARE then
		return;
	end
	
	if eventID == EVENTID_SHARE_SUCESSFUL then
		local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
		if curStatus == "lobby" then
			ShareAwardMgr.CheckDelayAward();
			--ShareAwardMgr.CheckGetAward();
		end
	end
end

function ShareAwardMgr.GetShareTimes()
	return DataMgr.ShareAwardInfo.share_times;
end

function ShareAwardMgr.IsTodayShareDone()
	local lastShareTime = DataMgr.ShareAwardInfo.daily_share_time;
	local curTime = FuncUtil.GetServerTimeInSec();
	
	if FuncUtil.IsSameDay(curTime, lastShareTime) then
		return true;
	else
		return false;
	end	
end

function ShareAwardMgr.GetShareAwardState(day)
	local state = DataMgr.ShareAwardInfo.AwardState[day];
	if nil == state then
		return 0
	end
	
	return state;
end

function ShareAwardMgr.GetAwardItemByDropId(dropId)
	local list = GetDropList(dropId);
	if #list <= 0 then
		return 0, 0, "";
	end
	
	return list[1].DropItemID, list[1].DropItemNum, list[1].Desc;
end

function ShareAwardMgr.Release()
	EventSystem:unregistEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, ShareAwardMgr.EventHandler);
	DataMgr.ShareAwardInfo.daily_share_time = 0;
	DataMgr.ShareAwardInfo.share_times = 0;
	DataMgr.ShareAwardInfo.AwardState = {};
	ShareAwardMgr.arrDelayAwardItems = nil;
end

function ShareAwardMgr.CheckDelayAward()
	if ShareAwardMgr.arrDelayAwardItems ~= nil then
		CommonItemGetUI:ShowPanel(ShareAwardMgr.arrDelayAwardItems);
		ShareAwardMgr.arrDelayAwardItems = nil;
	end
end

function ShareAwardMgr.CheckGetAward()
	local awardConfigTab = Client.GetTable("ShareAwardConfig");
	for k, v in pairs(awardConfigTab) do
		if ShareAwardMgr.GetShareTimes() >= v.Day and ShareAwardMgr.GetShareAwardState(v.Day) == 0 then
			if v.AwardType == 1 then
				ShareAwardMgr.ReqShareGetAward(v.Day, 0);
			else
				local item1, num1, name1 = ShareAwardMgr.GetAwardItemByDropId(v.MaleAwardID);
				local item2, num2, name2 = ShareAwardMgr.GetAwardItemByDropId(v.FemaleAwardID);
				ShareAwardUI.OpenSelAwardPanel(v.Day, item1, num1, name1, item2, num2, name2);
			end
			return;
		end
	end
end

function ShareAwardMgr.CheckAwardRedPoint()
	LobbyUI:LobbyRedPointUpdate(BP_ENUM_MODULE_SHARE_AWARD, false);
	
	local awardConfigTab = Client.GetTable("ShareAwardConfig");
	for k, v in pairs(awardConfigTab) do
		if ShareAwardMgr.GetShareTimes() >= v.Day and ShareAwardMgr.GetShareAwardState(v.Day) == 0 then
			LobbyUI:LobbyRedPointUpdate(BP_ENUM_MODULE_SHARE_AWARD, true);
			return;
		end
	end
end

function ShareAwardMgr.IsAllAwardHasGet()
	--[[local awardConfigTab = Client.GetTable("ShareAwardConfig");
	for k, v in pairs(awardConfigTab) do
		if ShareAwardMgr.GetShareAwardState(v.Day) == 0 then
			return false;
		end
	end--]]
	if ShareAwardMgr.GetShareTimes() < 7 then
		return false;
	end
	
	return true;
end
	
function ShareAwardMgr.OnShareAwardInfoUpdate()
	ShareAwardMgr.CheckAwardRedPoint();
	RoleInfoUI.UpdateUI();
	LevelUpUI:UpdateUI();
	if BattleResult.IsPopUpBattleResult then
		BattleResultUI.UpdateShareBtnState();
	end
	EventSystem:postEvent(EVENTTYPE_SHARE_AWARD, EVENTID_SHARE_AWARD_SYNCINFO); 
end

function ShareAwardMgr.ReqShareGetAward(id, gender)
	--NetUtil.SendPriorityPkg(true, "share_get_award_res", "share_get_award_req", id, gender);
	NetUtil.SendPkg("share_get_award_req", id, gender);
end

function ShareAwardMgr.RspShareGetAward(ret, id, itemlist)
	log("ShareAwardMgr.RspShareGetAward ret=" .. tostring(ret));
	if ret ~= nil and string.lower(ret) == "ok" then
		log("ShareAwardMgr.RspShareGetAward id=" .. tostring(id));
		log_tree("ShareAwardMgr.RspShareGetAward itemlist=", itemlist);
		
		if id > 0 then
			DataMgr.UpdateShareAwardState(id, 1)
			CommonItemGetUI:ShowPanel(itemlist);
		else
			--local arrayItemData = {}
			--for k, v in pairs(itemlist) do
				--local item = {res_id = tonumber(k),count = tonumber(v),};
				--table.insert(arrayItemData, item);
			--end
			ShareAwardMgr.arrDelayAwardItems = itemlist;
		end
	else
		ShowNotice(ret);
	end
end


s2c["share_get_award_res"] = ShareAwardMgr.RspShareGetAward