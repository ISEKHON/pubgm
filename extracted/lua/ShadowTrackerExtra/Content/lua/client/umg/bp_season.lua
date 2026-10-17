--赛季系统
SeasonUI = SeasonUI or
{
    bShow = false,
    --积分调整了，这里需要修改
    high_segment = function(lvl) return lvl == 701 or lvl == 801 end,
    --客户端进度条显示下限
    min_rating = 1200,
}

--single double team
Season_SelectMode = ""
--赛季名
Season_Name = ""
--赛季时间
Season_Time = ""

--段位显示
Season_Segment_Name = ""--waynedong season
Season_Sum_Score_Progress = ""
Season_Sum_Score_ProgressNum = ""
Season_Sum_Score = ""
Season_RankNo = ""
Season_Segment_Level = 0
Season_HightLevel = false
Season_Show_Score_ProgressNum = false

--赛季中奖励
SeasonInReward_ItemID = 0
SeasonInReward_ItemTime = 0
SeasonInReward_Condition1_Txt = ""
SeasonInReward_Condition1_Finish = false
SeasonInReward_Condition2_Txt1 = ""
SeasonInReward_Condition2_Txt2 = ""
SeasonInReward_Condition2_Finish = false
SeasonInReward_TakeId = 0
SeasonInReward_TakeState = 0       --0未领取，1可领取，2已领取

--赛季结束奖励
SeasonEndReward_SeasonID = 0
SeasonEndReward_ItemID = 0
SeasonEndReward_Txt = ""
SeasonEndReward_TakeState = 0       --0未领取，1可领取，2已领取

BP_ARRAY_SeasonSegmentTypeList = 
{--waynedong season
	BP_STRUCT_SeasonSegmentType = {
        Segment_Level = 0,
        SegmentType_Name = "",
        SegmentType_Text = "",
    },
};

--注册Widget
function bp_season_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_season,
		{{Path="/Game/UMG/UI_Logic/Season/Season_BP.Season_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SEASON_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
end

local function localText(id)
    local data = Client.GetTableData("LocalizeRes",id);
    if data then
        return data.TextValue
    end
    return ""
end

function SeasonUI.Init()
	--log("SeasonUI.Init");
    if Season_SelectMode == "" then
        --默认选最强的
        Season_SelectMode = SeasonUI.BeatSegment()[2]
    end
    SeasonUI.FillSegmentTips()
end

function SeasonUI.Release()
	--log("SeasonUI.Release");
    BP_ARRAY_SeasonSegmentTypeList = {}
end

function SeasonUI.BeatSegment()
	local tmp = {}
    table.insert(tmp, {SeasonSystem.segment.single.level+0.1, "single"})
    table.insert(tmp, {SeasonSystem.segment.double.level+0.2, "double"})
    table.insert(tmp, {SeasonSystem.segment.team.level+0.3, "team"})
    table.sort(tmp, function(a,b) return a[1]>b[1] end)
    return tmp[1]
end

function SeasonUI.Refresh()
    if not SeasonUI.IsShow() then
        return;
    end
	--log("SeasonUI.Refresh");
    LuaClassObj.HandleUIMessage(bp_season, "Refresh");
end

function SeasonUI.RefreshSegment()
    if not SeasonUI.IsShow() then
        return;
    end
    --log("SeasonUI.RefreshSegment");
    
    --段位
    Season_Segment_Level = SeasonSystem.segment[Season_SelectMode].level
    
    --段位名
    local cfg = Client.GetTableData("RankIntegralLevel", Season_Segment_Level)
    if cfg then
        Season_Segment_Name = cfg.Name
    else
        Season_Segment_Name = "error"
    end
    
    Season_Sum_Score_Progress = ""
    Season_Sum_Score_ProgressNum = "0"
    Season_Sum_Score = ""
    Season_RankNo = ""
    Season_HightLevel = SeasonUI.high_segment(Season_Segment_Level)
    Season_Show_Score_ProgressNum = false
    
    --最强
    if Season_HightLevel then
        local rating = SeasonSystem.segment[Season_SelectMode].rating
        --Season_Sum_Score = string.format("总积分:%d", rating)
        Season_Sum_Score = string.format(Client.GetTableData("LocalizeRes", "301301").TextValue, rating)
        local rankno = SeasonSystem.segment[Season_SelectMode].rankno
        --Season_RankNo = string.format("全服排名:%d", rankno)
        Season_RankNo = string.format(Client.GetTableData("LocalizeRes", "301302").TextValue, rankno)
    else
        --总积分进度
        local rating = SeasonSystem.segment[Season_SelectMode].rating
        local next_level = SeasonSystem.NextLevel(rating)
        if next_level then
            local next_cfg = Client.GetTableData("RankIntegralLevel", next_level)
            if next_cfg then
                --Season_Sum_Score_Progress = string.format("总积分:%d/%d", rating, next_cfg.MinIntegral)
                Season_Sum_Score_Progress = string.format(Client.GetTableData("LocalizeRes", "301303").TextValue, rating, next_cfg.MinIntegral)
                if rating >= SeasonUI.min_rating then
                    Season_Show_Score_ProgressNum = true
                    local progress_min_rating = cfg.MinIntegral
                    if progress_min_rating < SeasonUI.min_rating then
                        progress_min_rating = SeasonUI.min_rating
                    end
                    local percent = (rating - progress_min_rating) / (next_cfg.MinIntegral - progress_min_rating)
                    Season_Sum_Score_ProgressNum = string.format("%f", percent)
                end
            end
        end
    end
    LuaClassObj.HandleUIMessage(bp_season, "RefreshSegment");
end

function SeasonUI.RefreshSeason()
    if not SeasonUI.IsShow() then
        return;
    end
    --log("SeasonUI.RefreshSeason");
    
    local cfg = Client.GetTableData("SeasonInfo", SeasonSystem.cur_season_id)
    if cfg then
        Season_Name = cfg.SeasonName
        --Season_Time = cfg.DisplayTime
        local StartTime = os.date(Client.GetTableData("LocalizeRes",4011).TextValue,tonumber(cfg.StartTimeStamp))
        local EndTime = os.date(Client.GetTableData("LocalizeRes",4011).TextValue,tonumber(cfg.EndTimeStamp))
        Season_Time = StartTime.."-"..EndTime
    end
    
    --赛季中奖励
    SeasonInReward_ItemID = 0
    SeasonInReward_ItemTime = 0
    SeasonInReward_Condition1_Txt = ""
    SeasonInReward_Condition1_Finish = false
    SeasonInReward_Condition2_Txt1 = ""
    SeasonInReward_Condition2_Txt2 = ""
    SeasonInReward_Condition2_Finish = false
    SeasonInReward_TakeId = 0
    SeasonInReward_TakeState = 0
    local function next_season_in_reward()
        for i,v in ipairs(SeasonSystem.season_in_reward) do
            if v.prize_status == 1 then
                return v
            end
        end
    end
    local rew = next_season_in_reward()
    if rew then
        local cfg = Client.GetTableData("SeasonInReward", rew.id)
        if cfg then
            SeasonInReward_TakeId = rew.id
            local dropList = GetDropsList({cfg.RewardItemID})
            if #dropList > 0 then
                local firstDrop = dropList[1];
                SeasonInReward_ItemID = firstDrop.DropItemID
                SeasonInReward_ItemTime = firstDrop.DropItemTime
            end
            SeasonInReward_Condition1_Txt = cfg.Condition1_Desc
            if rew.condition1 == 1 then
                SeasonInReward_Condition1_Finish = true
            end
            SeasonInReward_Condition2_Txt1 = cfg.Condition2_Desc
            SeasonInReward_Condition2_Txt2 = string.format("%d/%d", rew.condition2, cfg.Condition2_Param2)
            if rew.condition2 >= cfg.Condition2_Param2 then
                SeasonInReward_Condition2_Finish = true
            end
            if rew.prize_status == 1 and SeasonInReward_Condition1_Finish and SeasonInReward_Condition2_Finish then
                SeasonInReward_TakeState = 1
            end
        end
    else
        SeasonInReward_TakeState = 2
        local n = #SeasonSystem.season_in_reward
        if n > 0 then
            local rew = SeasonSystem.season_in_reward[n]
            local cfg = Client.GetTableData("SeasonInReward", rew.id)
            if cfg then
                SeasonInReward_TakeId = rew.id
                local dropList = GetDropsList({cfg.RewardItemID})
                if #dropList > 0 then
                    local firstDrop = dropList[1];
                    SeasonInReward_ItemID = firstDrop.DropItemID
                    SeasonInReward_ItemTime = firstDrop.DropItemTime
                end
            end
        end
    end
    
    --赛季结束奖励
    SeasonEndReward_SeasonID = SeasonSystem.cur_season_id
    SeasonEndReward_ItemID = 0
    SeasonEndReward_Txt = ""
    SeasonEndReward_TakeState = 0
    local function find_season_end_reward()
        local best_segment = 0
        if SeasonSystem.season_end_reward.season_index == SeasonSystem.cur_season_id then
            best_segment = SeasonSystem.best_segment
        else
            best_segment = SeasonSystem.pre_best_segment
        end
        local cfgs = Client.GetTable("SeasonEndReward")
        if cfgs then
            for k,v in pairs(cfgs) do
                if SeasonSystem.season_end_reward.season_index == v.SeasonID and best_segment == v.Condition_Param then
                    return v
                end
            end
        end
    end
    local rew = find_season_end_reward()
    if rew then
        SeasonEndReward_ItemID = rew.RewardItemID
        SeasonEndReward_Txt = rew.Condition_Desc
        --首先判断是否未领取
        if SeasonSystem.season_end_reward.status == 1 then
            if SeasonSystem.season_end_reward.end_prize_can_take then
                SeasonEndReward_TakeState = 1
            end
        else
            SeasonEndReward_TakeState = 2
        end
    end
    
    LuaClassObj.HandleUIMessage(bp_season, "RefreshSeason");
end

function SeasonUI.FillSegmentTips()
    --log("SeasonUI.FillSegmentTips");
    local data = Client.GetTable("RankIntegralLevel")
    local tmp1 = {}
	for k,v in pairs(data) do
        local obj = tmp1[v.IntegralType]
        if obj then
            if obj.cfg.IntegralTypeOrder < v.IntegralTypeOrder then
                obj.cfg = v
            end
            obj.count = obj.count + 1
        else
            tmp1[v.IntegralType] = {cfg=v,count=1}
        end
    end
    local tmp2 = {}
    for k,v in pairs(tmp1) do
        table.insert(tmp2, v)
    end
    table.sort(tmp2, function(a,b) return a.cfg.IntegralType < b.cfg.IntegralType end)
    BP_ARRAY_SeasonSegmentTypeList = {}
    for i,v in ipairs(tmp2) do
        local obj = {
            Segment_Level = v.cfg.Level,
            SegmentType_Name = v.cfg.IntegralTypeName,
            SegmentType_Text = "",
        }
        if v.count > 1 then
            --obj.SegmentType_Text = string.format("（共%d段）", v.count)
            obj.SegmentType_Text = string.format(Client.GetTableData("LocalizeRes", "301304").TextValue, v.count)
        end
        table.insert(BP_ARRAY_SeasonSegmentTypeList, obj)
    end
    --log_tree("BP_ARRAY_SeasonSegmentTypeList=",BP_ARRAY_SeasonSegmentTypeList);
end

function SeasonUI.Show()
	LuaClassObj.HandleDynamicCreation(bp_season);
	--log("SeasonUI.Show");
    SeasonSystem.Enter();
    SeasonUI.Init();
    SeasonUI.bShow = true
    LuaClassObj.HandleUIMessage(bp_season, "ShowUI");
end

function SeasonUI.IsShow()
    return SeasonUI.bShow
end

--(以Event开头的函数名就能暴露给蓝图调用)

function EventSeasonUIClose()
	--log("EventSeasonUIClose");
    SeasonUI.Release()
    SeasonSystem.Release()
    SeasonUI.bShow = false
end

function EventSeasonSelectMode()
	--log("EventSeasonSelectMode="..Season_SelectMode);
    SeasonUI.RefreshSegment()
end

function EventSeasonTips()
    local content = localText(102200)
    content = string.gsub(content, "/n", "\n")
	--PopUpNoticeUI.ShowMessageBox("赛季规则",content)
    PopUpNoticeUI.ShowMessageBox(Client.GetTableData("LocalizeRes", "301305").TextValue,content)    
end

function EventTakeSeasonInReward()
    SeasonSystem.TakeSeasonInReward(SeasonInReward_TakeId)
end

function EventTakeSeasonEndReward()
    SeasonSystem.TakeSeasonEndReward(SeasonSystem.season_end_reward.season_index)
end


