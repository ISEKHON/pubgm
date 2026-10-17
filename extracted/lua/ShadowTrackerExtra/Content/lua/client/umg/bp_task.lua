TaskUI = TaskUI or {}
-- 当前活跃
BP_TaskActiveNum = 0
-- 同步物品掉落列表
BP_STRUCT_DropItem = {
	DropItemID = 0, 
	DropItemNum = 0, 
	DropItemSort = 0
}
BP_ARRAY_CurrentDropList = {
	BP_STRUCT_DropItem = BP_STRUCT_DropItem
}
-- 当前任务列表
BP_STRUCT_TaskInfo = {
	id = 0,
	status = "",
	progress = 0,
	BP_ARRAY_CurrentDropList = BP_ARRAY_CurrentDropList
}

BP_STRUCT_TaskCategory = {
	name = "",
	reddot = false,
	BP_ARRAY_Task = {
		BP_STRUCT_TaskInfo = BP_STRUCT_TaskInfo
	}
}
BP_ARRAY_TaskInfos = {
	BP_STRUCT_TaskCategory = BP_STRUCT_TaskCategory
}
-- 活跃礼包信息
BP_STRUCT_ActiveAwardInfo = {
	id = 0,
	value = 0,
	status = ""
}
BP_ARRAY_ActiveAwardInfos = {
	BP_STRUCT_ActiveAwardInfo = BP_STRUCT_ActiveAwardInfo
}
BP_AwardRedDot = false

-- 数据刷新时间
BP_RefreshTaskTimeLast = 0
BP_RefreshAwardTimeLast = 0

-- 用于同步lua参数
BP_CurrentOperateTaskId = 0
BP_CurrentOperateAwardId = 0



BP_STRUCT_ActiveAwardItem = {
	BP_ARRAY_FixItemList = {
		BP_STRUCT_DropItem = BP_STRUCT_DropItem
	},
	BP_ARRAY_RandomItemList = {
		BP_STRUCT_DropItem = BP_STRUCT_DropItem
	}
}

local UIState = {
	["PROGRESS"] = "PROGRESS",
	["DONE"] = "DONE",
	["AWARDED"] = "AWARDED",
}
local TaskState = {
	["PROGRESS"] = 0,
	["DONE"] = 1,
	["AWARDED"] = 2
}
local AwardState = {
	["UNDONE"] = 0,
	["DONE"] = 1
}

--注册Widget
function bp_task_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_task,
		{{Path="/Game/UMG/UI_Logic/Task/Task_BP.Task_BP_C", Container="Default", ZOrder=BP_ENUM_UI_TASK_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
	BP_ARRAY_TaskInfos = {}
	BP_ARRAY_ActiveAwardInfos = {}
	BP_STRUCT_ActiveAwardItem = {}

	EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_TASK, EventTaskHideUI);
	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVENESS_CHANGE, TaskUI.RefreshAwradInfo)
	EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_TASK_CHANGE, TaskUI.RefreshTaskInfo)
end

local function SortTask()
	for _,taskCate in pairs(BP_ARRAY_TaskInfos) do
		table.sort(taskCate.BP_ARRAY_Task, function(a, b)
			local function getSortValue(info)
				if (info.status == UIState["DONE"]) then
					return 3
				elseif info.status == UIState["PROGRESS"] then
					return 2
				else
					return 1
				end
			end
			local sortValue1 = getSortValue(a)
			local sortValue2 = getSortValue(b)
			if sortValue1 == sortValue2 then
				return a.sort < b.sort
			else
				return getSortValue(a) > getSortValue(b)
			end
		end)
	end
end

function TaskUI.GetTaskRedDot()
	for _, taskInfo in ipairs(BP_ARRAY_TaskInfos) do
		if taskInfo.reddot then
			return true
		end
	end

	for _,awardInfo in ipairs(BP_ARRAY_ActiveAwardInfos) do
		if awardInfo.status == UIState["DONE"] then
			return true
		end
	end

	return false
end

local function getTaskUIState(status)
	if status == TaskState["PROGRESS"] then
		return UIState["PROGRESS"]
	elseif status == TaskState["DONE"] then
		return UIState["DONE"]
	elseif status == TaskState["AWARDED"] then
		return UIState["AWARDED"]
	end

	return UIState["PROGRESS"]
end

function TaskUI.RefreshTaskInfo()
	local taskData = DataMgr.taskData
	BP_ARRAY_TaskInfos = {}
	BP_RefreshTaskTimeLast = taskData.daily_update_time
	for taskId,taskInfo in pairs(taskData.list) do
		local tableTaskInfo = Client.GetTableData("Task", taskId)
		if tableTaskInfo ~= nil then
			local taskCate = BP_ARRAY_TaskInfos[tableTaskInfo.TaskCategory]
			if taskCate == nil then
				taskCate = {
					name = tableTaskInfo.TaskCategoryDesc or "NONE",
					reddot = false,
					BP_ARRAY_Task = {}
				}
				BP_ARRAY_TaskInfos[tableTaskInfo.TaskCategory] = taskCate
				log(tableTaskInfo.TaskCategory)
			end
			table.insert(taskCate.BP_ARRAY_Task, {
				id = taskId,
				status = getTaskUIState(taskInfo.status),
				progress = taskInfo.progress,
				sort = tableTaskInfo.Sort,
				BP_ARRAY_CurrentDropList = GetDropsList({tableTaskInfo.DropID})
			})

			if taskInfo.status == TaskState["DONE"] then
				taskCate.reddot = true
			end
		end
	end
	SortTask()
	UpdateLobbyTaskRedDot(TaskUI.GetTaskRedDot())
	-- log_tree(BP_ARRAY_TaskInfos)
end

local function getAwardUIState(awardId, awardInfo, cond)
	if awardInfo.status == AwardState["UNDONE"] then
		if cond <= BP_TaskActiveNum then
			return UIState["DONE"]
		else
			return UIState["PROGRESS"]
		end
	else
		return UIState["AWARDED"]
	end
end

function TaskUI.RefreshAwradInfo()
	local awardData = DataMgr.activeness
	if awardData == nil then
		return
	end
	BP_RefreshAwardTimeLast = awardData.daily_update_time
	BP_TaskActiveNum = awardData.value
	BP_ARRAY_ActiveAwardInfos = {}
	for awardId,awardInfo in pairs(awardData.list) do
		local tableAwardInfo = Client.GetTableData("TaskActive", awardId)
		local status = getAwardUIState(awardId, awardInfo, tableAwardInfo.Cond)
		table.insert(BP_ARRAY_ActiveAwardInfos, {
			id = awardId,
			value = tableAwardInfo.Cond,
			status = status
		})
		if status == UIState["DONE"] then
			BP_AwardRedDot = true
		end
	end

	UpdateLobbyTaskRedDot(TaskUI.GetTaskRedDot())
	-- log_tree(BP_ARRAY_ActiveAwardInfos)
end

function TaskUI.TaskGetAward(taskId, itemList)
	CommonItemGetUI:ShowPanel(itemList)
	TaskUI.RefreshTaskInfo()
	SortTask()
	BP_CurrentOperateTaskId = taskId
	LuaClassObj.HandleUIMessage(bp_task, "UpdatePanel")
end

function TaskUI.ActivenessGetAward(awardId, itemList)
	CommonItemGetUI:ShowPanel(itemList)
	TaskUI.RefreshAwradInfo()
	BP_CurrentOperateAwardId = awardId
	LuaClassObj.HandleUIMessage(bp_task, "UpdateDetailPanel")
end

function EventTaskFinishTask_Push()
	local taskInfo = DataMgr.taskData.list[BP_CurrentOperateTaskId]
	if taskInfo == nil then
		log("[ERROR : task not found ID ]" .. BP_CurrentOperateTaskId)
		return
	end
	if taskInfo.status == TaskState["AWARDED"] then
		ShowNotice(108013)
		return
	end
	TaskSystem.Req_TaskGetAward(BP_CurrentOperateTaskId)
end

function EventTaskGetReward_Push()
	local activenessInfo = DataMgr.activeness.list[BP_CurrentOperateAwardId]
	if activenessInfo == nil then
		log("[ERROR : activeness not found ID ]" .. BP_CurrentOperateAwardId)
		return
	end
	if activenessInfo.status == AwardState["DONE"] then
		ShowNotice(108013)
		return
	end
	TaskSystem.Req_ActivenessGetAward(BP_CurrentOperateAwardId)
end

function EventTaskShowRewardDetailPopup_Push()
	CommonTreasureBoxPopup:ShowPanel(BP_CurrentOperateAwardId)
	local tableAwardInfo = Client.GetTableData("TaskActive", BP_CurrentOperateAwardId)
	CommonTreasureBoxPopup:SetTitleString(Client.GetTableData("LocalizeRes", tableAwardInfo.BoxTitleName).TextValue)
end

function EventTestAddProgress_Push()
	DataMgr.TestProgress(BP_CurrentOperateTaskId)
end

function EventTaskGetTaskReward_Push()
	local tableTaskInfo = Client.GetTableData("Task", BP_CurrentOperateTaskId)
	if tableTaskInfo == nil then
		log("task table data not found - taskId: " .. BP_CurrentOperateTaskId)
		return
	end
	BP_ARRAY_CurrentDropList = GetDropsList({tableTaskInfo.DropID})
end

function EventTaskShowUI()	
	LuaClassObj.HandleDynamicCreation(bp_task);
	TaskUI.RefreshTaskInfo()
	TaskUI.RefreshAwradInfo()
	LuaClassObj.HandleUIMessage(bp_task, "UIShow")
end

function EventTaskHideUI()
	LuaClassObj.HandleUIMessage(bp_task, "UIClose")
end

function EventTaskGoTo_Push()
	local tableTaskInfo = Client.GetTableData("Task", BP_CurrentOperateTaskId)
	if tableTaskInfo == nil then
		log("task table data not found - taskId: " .. BP_CurrentOperateTaskId)
		return
	end
	if tableTaskInfo.JumpTo == "WX_PECULIAR" then
		EventShowPlatWXStartup()
	elseif tableTaskInfo.JumpTo == "QQ_PECULIAR" then
		EventShowPlatQQStartup()
	else
		if _G[tableTaskInfo.JumpTo] ~= nil then
			LobbyUI.CloseOtherMenu()
			GlobalData:JumpUrl("game://?module=" .. _G[tableTaskInfo.JumpTo])
		end
	end
end

function EventTaskClickAwarded_Push()
	ShowNotice(108013)
end