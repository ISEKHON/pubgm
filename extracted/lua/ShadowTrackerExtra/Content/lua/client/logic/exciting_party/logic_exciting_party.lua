--[[
    刺激盛宴逻辑部分
]]

local TARGET_UNIT = { "万", "亿"}
local TARGET_SHARE_UNIT = {"w", "y"}

ExcitingPartyMgr = ExcitingPartyMgr or 
{
    OPEN_TIME_TEXT_ID = "9990001",
    ExcitingPartyInfo = { },
    -- 是否在吃鸡盛宴活动中
    isInTime = false,
    actDurationTime = ""
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

local function ConverRelativeTimeToTime(beginTime, relDay, relHour)
    -- local timeValBegin  = os.time({year = begDate[1], month = begDate[2], day = begDate[3], hour = begDate[4], min = begDate[5], sec = begDate[6]})
    local timeValBegin = beginTime + relDay * 86400 --延迟天数
    
    local beginTab = os.date("*t", timeValBegin)
    beginTab.hour = relHour
    beginTab.min = 0
    beginTab.sec = 0 

    timeValBegin = os.time(beginTab) 
    return timeValBegin
end

function ExcitingPartyMgr.DealExcitingPartyFromActivity()
     
    -- 清空一下数据
    ExcitingPartyMgr.ExcitingPartyInfo = {}
    local actData = DataMgr.GetActivityByType(ActivityType.GROUP_EXCITE)
    -- log_tree("exciting party = ", actData )
    if actData == nil then
        ExcitingPartyMgr.isInTime = false 
        return
    end

    local serverTime = FuncUtil.GetServerTimeInSec()

    if serverTime >= actData.StartTime and serverTime <= actData.EndTime then
        ExcitingPartyMgr.isInTime = true 
    end

    local dateFormat = Client.GetTableData("LocalizeRes", "110070").TextValue
    --ExcitingPartyMgr.actDurationTime = string.format("%s~%s", os.date("%Y年%m月%d日", actData.StartTime), os.date("%Y年%m月%d日", actData.EndTime))
    ExcitingPartyMgr.actDurationTime = string.format("%s~%s", os.date(dateFormat, actData.StartTime), os.date(dateFormat, actData.EndTime))

    local openTimeText  = Client.GetTableData("LocalizeRes", ExcitingPartyMgr.OPEN_TIME_TEXT_ID).TextValue  
    
    -- ExcitingPartyMgr.isInTime = FuncUtil.IsInTime(actData.StartTime ,actData.EndTime) 
    -- log("isInTime = " .. tostring(ExcitingPartyMgr.isInTime))
    for i=1,#actData.List do
        local one = actData.List[i]

        local actOne = {}
        actOne.itemIdx = one.Index 
        actOne.mainActID = actData.ID 
        actOne.actID = one.ID

        if one.Total > 10000 then
            -- 去掉小数后面的哦
            local showNum = one.Total / 10000 
            local finalNum = math.floor(showNum)

            if finalNum < showNum then
                finalNum = showNum 
            end
            actOne.targetNum = finalNum .. TARGET_UNIT[2] 
            actOne.shareNum = finalNum .. TARGET_SHARE_UNIT[2] 
        else
            actOne.targetNum = one.Total .. TARGET_UNIT[1] 
            actOne.shareNum = one.Total .. TARGET_SHARE_UNIT[1] 
        end

        actOne.shareNum = string.gsub(actOne.shareNum, "%.", "d")
        -- log("sharenum .. " .. actOne.shareNum)
        -- actOne.targetNum = one.Total 
        -- actOne.awardID = one.Drop[1].itemId   
        actOne.BP_ARRAY_Exciting_Party_Award_Infos = {}  
        for j=1,#one.Drop do
            local awardOne = {}
            awardOne.itemId = one.Drop[j].itemId   
            awardOne.count = one.Drop[j].count  
            awardOne.expireTime = one.Drop[j].expireTime  
            table.insert(actOne.BP_ARRAY_Exciting_Party_Award_Infos, awardOne)
        end

        if i == 1 or i == 5 then
            local itemCfg = Client.GetTableData("Item", one.Drop[1].itemId) 

            if itemCfg  then
                actOne.showName = string.format("%d%s", one.Drop[1].count, itemCfg.ItemName) 
            end
        elseif i == 6 then
            local itemCfg = Client.GetTableData("Item", one.Drop[1].itemId)  
            -- actOne.BP_ARRAY_Exciting_Party_Award_Infos[1].expireTime  =  30 * 24 
            -- one.Drop[1].expireTime = 30 * 24 
            if itemCfg then 
                if one.Drop[1].expireTime > 0 then
                    actOne.showName = string.format("%s(%d天)", itemCfg.ItemName, math.ceil(one.Drop[1].expireTime / 24)) 
                else
                    actOne.showName = itemCfg.ItemName
                end
                 
            end
        else
            actOne.showName = "" 
        end
        actOne.openTime = ConverRelativeTimeToTime(actData.StartTime, one.Arg1, one.Arg2) 
        actOne.openTimeStr = os.date(openTimeText, actOne.openTime) 
        -- log("activity child begin time = " .. actOne.opentime)
        actOne.title = one.Title  
        actOne.titleHide = string.gsub(one.Title, "%w+", "？")
        -- log("title hide = " .. actOne.titleHide )   
        actOne.status = one.Status 
        
        -- if actOne.status == 0 and serverTime > actOne.openTime  then
        --     actOne.status = 1 
        -- end
        table.insert(ExcitingPartyMgr.ExcitingPartyInfo, actOne)
    end
    -- log_tree("aaa", ExcitingPartyMgr.ExcitingPartyInfo )
    -- LuaClassObj.HandleUIMessage(bp_exciting_party, "UpdateData") 
end

function ExcitingPartyMgr.OpenUI()
    UIExcitingParty.InitExcitingPartyUIData() 
    LuaClassObj.HandleUIMessage(bp_exciting_party, "UIShow") 
    LuaClassObj.HandleUIMessage(bp_exciting_party, "UpdateData")
end