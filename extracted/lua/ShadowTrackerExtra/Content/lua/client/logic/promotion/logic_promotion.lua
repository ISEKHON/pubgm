--[[    
    游戏内推广员活动
]]
PromotionMgr = PromotionMgr or
{
    RES_OK = "ok",
    -- PromotionInfos = {} 
}

-- activity data 示例
-- data = {
-- 	[1] = {
-- 		ID = 1392,
-- 		Title = "活动标题",
-- 		Desc = "活动详情",
-- 		Detail = "活动详细描述",
-- 		ImgUrl = "http://imgur.com",
-- 		ImgLink = "http://qq.com",
-- 		Type = 1,
-- 		List = {
-- 			[1] = {
-- 				ID = 1391,
-- 				Index = 1,
-- 				Type = 1,
-- 				Title = "",
-- 				Status = 1,
-- 				Total = 3,
-- 				Progress = 1,
--              Arg1 = 0,
--              Arg2 = 0,  
-- 				Drop = {
-- 					{itemId = 1, count = 10},
-- 					{itemId = 1, count = 10},
-- 					{itemId = 1, count = 10},
-- 				}
-- 			}
-- 		},
-- 		DailyStartTime = "2017-12-13 04:59:55",
-- 		DailyEndTime = "2017-12-13 04:59:55",
-- 		StartTime = "2017-12-13 04:59:55",
-- 		EndTime = "2017-12-13 04:59:55",
-- 		JoinLevelLimit = {up = 30, low = 10},
-- 		JoinVipLimit = {up = 10, low = 0},
-- 		LabelType = 1,
-- 		LabelDesc = "热门",
-- 		Order = 1,
-- 		Arg1 = "",
-- 		Arg2 = "",
-- 		Arg3 = "",
-- 		Arg4 = "",
-- 		Arg5 = "",
-- 	},
-- } 
-- 客户端活动信息
-- BP_STRUCT_Exciting_Party_Info =
-- {
-- 	itemIdx = 0,
-- 	targetNum = 0,
-- 	awardID = 0,
-- 	opentime = 0,
-- 	title = "",
-- } 

function PromotionMgr.DealPromotionFromActivity()

	-- 清空一下数据
	-- PromotionMgr.PromotionInfos = {}
	local actData = DataMgr.GetActivityByType(ActivityType.PROMOTOR)
	log_tree("promotion info = ", actData)
	if actData == nil then
		return
    end
    
    UIPromotion.InitAwardData(actData) 
	-- for i = 1, #actData.List do
	-- 	local one = actData.List[i]
		
	-- 	local actOne = {}
	-- 	actOne.itemIdx = one.Index
	-- 	actOne.mainActID = actData.ID
	-- 	actOne.actID = one.ID
    --     actOne.needInviteCount = one.Total
    --     actOne.currentInviteCount  = one.Progress 
	-- 	actOne.awardID = one.Drop[1].itemId
	-- 	actOne.status = one.Status
		
	-- 	table.insert(PromotionMgr.PromotionInfos, actOne)
	-- end
end

function PromotionMgr.SendGetPromotionInfo()
    NetUtil.SendPkg("promotor_get_info_req") 
end

function PromotionMgr.SendInviteFriend(openid)
    NetUtil.SendPkg("promotor_invite_req", openid)
end

function PromotionMgr.on_promotor_invite_rsp(res, sopenid)
    log("Promotion invite res " .. res)
    if res == PromotionMgr.RES_OK then
        log("Promotion invite OpenID " .. sopenid) 
        UIPromotion.UpdateFriendInviteStatus(sopenid) 
    elseif res == "invite-repeat" or res == "send-repeat" then
        DataMgr.ShowNoticeByID(9990003) 
    elseif res == "send-failed" then
	    DataMgr.ShowNoticeByID(9990004) 
    else
        -- 其他服务器错误
        log("PromotionMgr:on_promotor_get_info_rsp error!") 
        DataMgr.ShowNoticeByID(106036) 
	end
end

function PromotionMgr.on_promotor_get_info_rsp(res, data)
    log("Promotion info res " .. res)
    
    if res == PromotionMgr.RES_OK then
        log_tree("Promotion info = ", data) 
        UIPromotion.OnGetPromotionFriendList(data.sns_fri_list, data.reg_fri_list) 
        UIPromotion.OpenUI() 
    elseif res == "invite-repeat" or res == "send-repeat" then
        DataMgr.ShowNoticeByID(9990003) 
    elseif res == "send-failed" then
	    DataMgr.ShowNoticeByID(9990004) 
    else
        -- 其他服务器错误
        log("PromotionMgr:on_promotor_get_info_rsp error!") 
        DataMgr.ShowNoticeByID(106036) 
	end
end 


--[[   
    网络回调
]]--
s2c["promotor_invite_rsp"] = PromotionMgr.on_promotor_invite_rsp  
s2c["promotor_get_info_rsp"] = PromotionMgr.on_promotor_get_info_rsp   