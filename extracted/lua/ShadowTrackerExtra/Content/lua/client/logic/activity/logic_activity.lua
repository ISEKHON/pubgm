ActivitySystem = ActivitySystem or {}

local ActivityStatus = {
	["UNDONE"] = 0,
	["DONE"] = 1,
	["AWARDED"] = 2
}
function ActivitySystem.Req_AcitvityOneData(activityId)
	NetUtil.SendPkg("get_activity_one_req", activityId)
end

function ActivitySystem.Req_TakeActivityAward(activityId, awardIndex)
	NetUtil.SendPkg("take_activity_award_req", activityId, awardIndex)
end

function ActivitySystem.Req_DealActivity(activityId, awardIndex, select)
	NetUtil.SendPkg("deal_activity_req", activityId, awardIndex, select)
end

function ActivitySystem.Req_ActivityCheckList()
	NetUtil.SendPkg("check_activity_list_req")
end

function ActivitySystem.Req_BulletinHashList()
	NetUtil.SendPkg("bulletin_get_hashlist_req")
end

function ActivitySystem.HasNoticeRedDot()
	return true
end

function ActivitySystem.HasActivityRedDot(typeList)
	local map = DataMgr.activity.activityListMap
	if map == nil then
		log("[ Error when HasActivityRedDot : activity data need init]")
		return false
	end
	for _, subActivity in pairs(map) do
		if typeList ~= nil then
			if typeList[subActivity.Type] ~= nil
			and subActivity.Status == ActivityStatus["DONE"] then
				return true
			end
		else
			if subActivity.Status == ActivityStatus["DONE"] then
				return true
			end
		end
	end
	return false
end

function ActivitySystem.HasNoticeRedDotByID(noticeId)
	return false --true
end

function ActivitySystem.HasActBtnRedPoint()
	for _, activity in pairs(DataMgr.activity.data) do
		-- 排除吃鸡盛典和新兵八天活动 只显示通用活动
		if activity and activity.Type ~= nil and 
			(activity.Type == 2 or activity.Type == 3 or activity.Type == 4 or activity.Type == 5
				 or activity.Type == 6 or activity.Type == 7 or activity.Type == 8 or activity.Type == 10 or activity.Type == 13)
			then
			local IsRedPoint = ActivitySystem.HasActivityRedDotByID(activity.ID)
			if IsRedPoint then
				return true
			end
		end
	end
	return false
end

function ActivitySystem.HasActivityRedDotByID(activityId)
	local map = DataMgr.activity.activityMap
	if map == nil then
		log("[ Error when HasActivityRedDotByID : activity data need init]")
		return false
	end
	local activity = map[activityId]
	if activity == nil then
		log("[ Error when HasActivityRedDotByID : activity not found id :]" .. activityId)
		return false
	end
	for _,subActivity in ipairs(activity.List) do

		--区分下是否是兑换活动，兑换活动只有勾选了兑换提醒才计算红点信息
		if subActivity.Type == 8 then
			if subActivity.IsCheckNotice == 1 and subActivity.Status == ActivityStatus["DONE"] then
				--log("兑换活动"..activityId.."有小红点")
				return true
			end
		else

			if subActivity.Status == ActivityStatus["DONE"] then
				--log("活动"..activityId.."有小红点")
				return true
			end
		end
	end
	--log("活动"..activityId.."没有小红点")
	return false
end

function ActivitySystem.Res_TakeActivityAward(errorCode, activityId, awardIndex)
	if errorCode == NetErrorCode_NONE then
		local key = string.format("%d_%d", activityId, awardIndex)
		local subActivity = DataMgr.activity.activityListMap[key]
		if subActivity ~= nil then
			local arrayItemData = {}
			for index, dropData in ipairs(subActivity.Drop) do
				table.insert(arrayItemData, {res_id = dropData.itemId, count = dropData.count})
			end

			CommonItemGetUI:ShowPanel(arrayItemData)
		end
	else
		ShowNotice(errorCode)
	end
end

function ActivitySystem.RemoveActivity(activityId)
	DataMgr.activity.hashList[activityId] = nil
	DataMgr.activity.activityMap[activityId] = nil
	for key, activity in pairs(DataMgr.activity.activityListMap) do
		if activity.ID == activityId then
			DataMgr.activity.activityListMap[key] = nil
		end
	end

	local del = {}
	for key, activity in pairs(DataMgr.activity.data) do
		if activity.ID == activityId then
			del[key] = true
		end
	end

	for key,_ in pairs(del) do
		table.remove(DataMgr.activity.data, key)
	end
end

function ActivitySystem.InitHashList(hashList)
	--log_tree("==============old hash list", DataMgr.activity.hashList)
	--log_tree("==============init hash list", hashList)
	local removeMark = false
	for id, hash in pairs(DataMgr.activity.hashList) do
		if hashList.activity_chk[id] == nil then
			-- remove activity
			ActivitySystem.RemoveActivity(id)
			removeMark = true
		end
	end
	if removeMark then
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CR)
	end

	local changeList = {}
	for id, hashCode in pairs(hashList.activity_chk) do
		local activity = DataMgr.activity.hashList[id]
		if activity == nil then
			log("[Error : activity not found id:]" .. id)
			changeList[id] = true
		else
			if activity.HashCode ~= hashCode then
				changeList[id] = true
			end
		end
	end
	for id,updateTime in pairs(hashList.activity_update) do
		local activity = DataMgr.activity.hashList[id]
		if activity == nil then
			log("[Error : activity not found id:]" .. id)
			changeList[id] = true
		else
			if activity.UpdateTime ~= updateTime then
				changeList[id] = true
			end
		end
	end
	local finalList = {}
	for id,_ in pairs(changeList) do
		table.insert(finalList, id)
	end

	if #finalList > 0 then
		NetUtil.SendPkg("get_activity_batch_req", finalList)
	end
end

local function InitParentNode(node, id, data)
	DataMgr.activity.activityIdMap[id] = id
	node.ID = id
	node.Desc = data.activity_desc
	node.Detail = data.activity_detail
	node.Title = data.activity_name
	node.ImgUrl = data.activity_image_link
	node.ImgLink = data.page_link
	node.DailyStartTime = data.daily_start_time
	node.DailyEndTime = data.daily_end_time
	node.StartTime = data.start_time
	node.EndTime = data.end_time
	node.DailyStartTimeStr = os.date("%H:%M:%S", data.daily_start_time);--FormatTime(data.daily_start_time)
	node.DailyEndTimeStr = os.date("%H:%M:%S", data.daily_end_time);--FormatTime(data.daily_end_time)
	node.StartTimeStr = os.date("%Y-%m-%d %H:%M:%S", data.start_time);--FormatTime(data.start_time)
	node.EndTimeStr = os.date("%Y-%m-%d %H:%M:%S", data.end_time);--FormatTime(data.end_time)
	node.JoinLevelLimitUp = data.join_level_up_limit
	node.JoinLevelLimitLow = data.join_level_down_limit
	node.JoinVipLimitUp = data.join_vip_up_limit
	node.JoinVipLimitLow = data.join_vip_down_limit
	node.LabelDesc = ""
	node.LabelType = data.left_label
	--log("[HHF] id = " .. tostring(id));
	--log("[HHF] daily_start_time = " .. tostring(data.daily_start_time) .. " -> " .. tostring(node.DailyStartTimeStr));
	--log("[HHF] daily_end_time = " .. tostring(data.daily_end_time) .. " -> " .. tostring(node.DailyEndTimeStr));
	--log("[HHF] start_time = " .. tostring(data.start_time) .. " -> " .. tostring(node.StartTimeStr));
	--log("[HHF] end_time = " .. tostring(data.end_time) .. " -> " .. tostring(node.EndTimeStr));
	--log("[HHF]");
	if data.left_label == 1 then
		node.LabelDesc = "火爆"
	end
	if data.left_label == 2 then
		node.LabelDesc = "限时"
	end
	if data.left_label == 3 then
		node.LabelDesc = "预告"
	end
	if data.left_label == 4 then
		node.LabelDesc = "推荐"
	end
	if data.left_label == 5 then
		node.LabelDesc = "最新"
	end
	node.Order = data.show_order
	node.JumpActivity = data.jump_activity_id or 0
	node.Type = data.type
	node.List = node.List or {}
	DataMgr.activity.activityMap[id] = node
	--log("Init activity : " ..  id)
end

local function InitCond(activityType, cond, subActivity)
	if activityType == ActivityType["ITEM_EXCHANGE"] then
		local args = string.split(cond, ",")
		subActivity.Total = tonumber(args[5])
		for i = 1,4,2 do
			table.insert(subActivity.CostList, {itemId = tonumber(args[i]), count = tonumber(args[i+1])})
		end
	elseif activityType == ActivityType["BATTLEROUND"] then
		local args = string.split(cond, ",")
		subActivity.Total = tonumber(args[2])
	elseif activityType == ActivityType["BATTLEFIRST"] then
		local args = string.split(cond, ",")
		subActivity.Total = tonumber(args[2])
	elseif activityType == ActivityType["SHARE"] then
		local args = string.split(cond, ",")
		subActivity.Total = tonumber(args[2])
	elseif activityType == ActivityType["GROUP_EXCITE"] or activityType == ActivityType["PROMOTOR"]  then
		local args = string.split(cond, ",")
		subActivity.Total = tonumber(args[1]) 
	else
		if cond == nil then
			subActivity.Total = 0
		else
			subActivity.Total = tonumber(cond)
		end
	end

	subActivity.Total = subActivity.Total or 0
end

local function InitSubActivityNode(parentNode, id, data)
	for index,award in ipairs(data.award) do
		local key = string.format("%d_%d", id, index)
		local subActivity = DataMgr.activity.activityListMap[key]
		if subActivity == nil then
			subActivity = {}
			table.insert(parentNode.List, subActivity)
			DataMgr.activity.activityListMap[key] = subActivity
		end
		subActivity.ID = id
		subActivity.Index = index
		subActivity.Title = award.task_title 
		subActivity.Arg1 = award.extern_arg_1  
		subActivity.Arg2 = award.extern_arg_2 
		subActivity.Key = key
		subActivity.Drop = {}
		subActivity.CostList = {}
		subActivity.Type = data.type
		subActivity.Order = data.show_order * 10000 + (100 - index)
		InitCond(subActivity.Type, award.cond, subActivity)
		DataMgr.activity.activityIdMap[id] = parentNode.ID

		subActivity.IsCheckNotice = 0
		for _,dropItem in ipairs(award.drop) do
			table.insert(subActivity.Drop, {
				itemId = dropItem.item_id,
				count = dropItem.item_num,
				expireTime = dropItem.item_expire_time,
				reviseId = dropItem.item_revise_id,
			})
		end

		subActivity.Progress = 0
		subActivity.Status = 0
		--log("Init activity subActivity : " ..  key)
	end
end

function ActivitySystem.InitActivityList(activityTable)
	DataMgr.activity.isInit = true
	ActivitySystem.InitActivityData(activityTable)
end

function ActivitySystem.InitActivityData(activityTable)
	-- log("===============printStart")
	--log_tree("recv pkg get_activity_list_res", activityTable)
	-- log("===============printEnd")

	local changeList = {idList = {}, typeList = {}}
	local newActivityMark = false
	local temp = DataMgr.activity.data
	-- 初始化模板表
	for activityId, activityData in pairs(activityTable) do
		local cfg = activityData.cfg
		cfg.father_activity_id = cfg.father_activity_id or 0
		cfg.show_order = cfg.show_order or 1000
		local parentNode = nil
		local parentId = cfg.father_activity_id == 0 and activityId or cfg.father_activity_id
		parentNode = DataMgr.activity.activityMap[parentId]
		if parentNode == nil then
			parentNode = {ID = parentId, List = {}}
			table.insert(temp, parentNode)
			DataMgr.activity.activityMap[parentId] = parentNode
			newActivityMark = true
		end
		-- 是父节点
		if cfg.father_activity_id == 0 then
			InitParentNode(parentNode, activityId, cfg)
		end

		-- 处理子节点
		InitSubActivityNode(parentNode, activityId, cfg)

		DataMgr.activity.hashList[activityId] = {HashCode = cfg.chk_str, UpdateTime = 0}

		changeList.idList[(DataMgr.activity.activityIdMap[activityId] or -1)] = true
		changeList.typeList[cfg.type] = true
	end


	-- ActivitySystem.ArrangeActivity()

	-- 初始化数据
	for activityId, activityData in pairs(activityTable) do
		local data = activityData.data
		ActivitySystem.UpdateOneActivityData(activityId, data)
	end
	table.sort(DataMgr.activity.data, function(a, b)
		return a.Order < b.Order
	end)
	for _,activity in pairs(DataMgr.activity.activityMap) do
		table.sort(activity.List, function(a, b)
			return a.Order > b.Order
		end)
	end

	-- log("===============printStart")
	-- log_tree("=================activityData", temp)
	-- log("===============printEnd")
	-- 派发事件给依赖于活动的系统处理
	if DataMgr.activity.isInit then
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, changeList)
		if newActivityMark then
			EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CR)
		end
	end
	-- ExcitingPartyMgr.DealExcitingPartyFromActivity() 
end

-- 整理刚刚初始化玩的数据
function ActivitySystem.ArrangeActivity()
	-- 把兑换的活动移到正常活动中
	for _, activityData in ipairs(DataMgr.activity.data) do
		--log_tree("[Error: ArrangeActivity]", activityData.JumpActivity)
		if activityData.JumpActivity ~= 0 then
			local temp = DataMgr.activity.activityMap[activityData.JumpActivity]
			if temp ~= nil then
				for _,subActivityNode in ipairs(temp.List) do
					table.insert(activityData.List, subActivityNode)
				end
			else
				--log_tree("[Error: activity data error]" .. (activityData.JumpActivity or 0), DataMgr.activity)
			end
		end
	end
end

function ActivitySystem.UpdateActivityData(_, activityData)
	-- log("===============printStart")
	-- log_tree("=================UpdateActivityData" .. (id or ""), activityData)
	-- log("===============printEnd")

	local changeList = {idList = {}, typeList = {}}
	for id, data in pairs(activityData) do
		ActivitySystem.UpdateOneActivityData(id, data)
		changeList.idList[(DataMgr.activity.activityIdMap[id] or -1)] = true
		changeList.typeList[data.type] = true
	end
	if DataMgr.activity.isInit then
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, changeList)
	end
	-- ExcitingPartyMgr.DealExcitingPartyFromActivity() 
end

function ActivitySystem.UpdateOneActivityData(id, data)
	if DataMgr.activity.hashList[id] ~= nil then
		DataMgr.activity.hashList[id].UpdateTime = data.update_time
	else
		log("[Error : activity not found in hashList id ]" .. id)
	end
	for index, statusData in ipairs(data.award) do
		local key = string.format("%d_%d", id, index)
		local subActivity = DataMgr.activity.activityListMap[key]
		if subActivity == nil then
			log(string.format("[Error : activity can't find on id:%d index:%d ]", id, index))
		else
			subActivity.Status = statusData.status
			if subActivity.Type == ActivityType["ITEM_EXCHANGE"] then
				subActivity.Progress = statusData.exchange_cnt or 0
				subActivity.IsCheckNotice = statusData.has_point or 0
			end
		end
	end
	data.type = tonumber(data.type)
	-- 累计登陆不需要同步进度
	if data.type == ActivityType["TOTAL_LOGIN"]
	or data.type == ActivityType["SPRING_REDPACKET"] then
		return
	end
	-- 新兵八天需要额外的open_time字段
	local activity = DataMgr.activity.activityMap[id]
	if data.type == ActivityType["NEW_PLAYER"] and activity ~= nil then
		activity.open_time = data.open_time
	end
	for _, progressData in pairs(data.other) do
		if type(progressData) == "table" then
			for index,value in pairs(progressData) do
				local key = id.."_"..index
				local subActivity = DataMgr.activity.activityListMap[key]
				subActivity.Progress = value
			end
		end
	end
end

s2c["take_activity_award_res"] = ActivitySystem.Res_TakeActivityAward
s2c["get_activity_batch_res"] = ActivitySystem.InitActivityData
s2c["get_activity_list_res"] = ActivitySystem.InitActivityList
s2c["get_activity_one_res"] = ActivitySystem.UpdateActivityData
s2c["check_activity_list_res"] = ActivitySystem.InitHashList