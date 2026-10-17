ActivityGroupSystem = ActivityGroupSystem or {}
local PlatformStr = {
	BP_ENUM_PLAYFORM_WX = "WX",
	BP_ENUM_PLAYFORM_QQ = "QQ",
}
function ActivityGroupSystem.SortDataList(dataMap)
	local currentTime = FuncUtil.GetServerTimeInSec()
	
	local result = {}
	if #dataMap == 8 then
		for i,list in ipairs(dataMap) do
			if #list > 1 then
				table.sort(list, function(a, b)
					log(string.format("%d | %d %d  ===  %d %d", i, a.open_time, a.end_time, b.open_time, b.end_time))
					return a.open_time > b.open_time
					end)
			end
		end

		local found;
		for _,list in ipairs(dataMap) do
			found = false
			for _,data in ipairs(list) do
				data.platform = data.platform or "QQ"
				if currentTime <= data.end_time and data.platform == PlatformStr[BP_Platform] then
					table.insert(result, data)
					found = true
					break
				end
			end

			if found ~= true then
				table.insert(result, list[#list])
			end
		end
	end

	return result
end

function ActivityGroupSystem.CheckShowRedPoint()
	for _,info in ipairs(DataMgr.activityGroupList) do
		if ActivitySystem.HasActivityRedDotByID(info.activity_id) then
			return true
		end
	end
	return false
end

function  ActivityGroupSystem.ReqGetActivityGroupList()
	NetUtil.SendPkg("get_act_gather_list_req")
end

function ActivityGroupSystem.ReqButtonClickedEvent(buttonID)
	NetUtil.SendPkg("button_click_log", buttonID, "");
end

function ActivityGroupSystem.ActivityInfoRefresh()
	LobbyUI:UpdateLobbyActGroupRedDot()
end