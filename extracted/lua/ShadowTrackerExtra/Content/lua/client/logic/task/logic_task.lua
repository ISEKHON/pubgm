TaskSystem = TaskSystem or {}

TaskType = {
	["FIX"] = 1,
	["RANDOM"] = 2,
	["PLATFORM"] = 3
}

function TaskSystem.Req_TaskGetAward(taskId)
	NetUtil.SendPkg("task_get_award_req", taskId)
end

function TaskSystem.Req_ActivenessGetAward(rewardId)
	NetUtil.SendPkg("activeness_get_award_req", rewardId)
end

function TaskSystem.Res_TaskGetAward(res, taskId, itemList)
	if res == NetErrorCode_NONE then
		-- 客户端自动设置任务状态
		local taskData = DataMgr.taskData.list[taskId]
		if taskData == nil then
			log("Error: task data can't find ID :" .. taskId)
			return
		end
		taskData.status = 2

		TaskUI.TaskGetAward(taskId, itemList)
	else
		ShowNotice(res)
	end
end

function TaskSystem.Res_ActivenessGetAward(res, rewardId, itemList)
	if res == NetErrorCode_NONE then
		-- 客户端自动设置任务状态
		local rewardData = DataMgr.activeness.list[rewardId]
		if rewardData == nil then
			log("Error: reward data can't find ID :" .. rewardId)
			return
		end
		rewardData.status = 1

		TaskUI.ActivenessGetAward(rewardId, itemList)
	else
		ShowNotice(res)
	end
end

s2c["task_get_award_res"] = TaskSystem.Res_TaskGetAward
s2c["activeness_get_award_res"] = TaskSystem.Res_ActivenessGetAward


