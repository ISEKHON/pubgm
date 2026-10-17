
--[[
 赛季相关逻辑
 GM命令
 设置当前赛季
 gm_set_season_index(index)
 加匹配次数
 gm_add_season_battle_count(segment_level, count)
 改服务器时间
 gm_time(type, value)
]]--

SeasonSystem = SeasonSystem or
{
    segment = {
        single = {rating = 0, rankno = 0, level = 0},
        double = {rating = 0, rankno = 0, level = 0},
        team = {rating = 0, rankno = 0, level = 0},
    },
    cur_season_id = 0,
    season_in_reward = {},
    season_end_reward = {},
    best_segment = 0,                   --当前赛季最高段位
    pre_best_segment = 0,               --上赛季最高段位
    curBattleInfoReqModeType ="solo",   -- 当前请求的 solo duo team
}

--积分四舍五入
local function SeasonSorceInt(score)
    return math.floor(score+0.5)
end

function SeasonSystem.Enter()
	--log("SeasonSystem.Enter");
    DataMgr.fillMaxSegmentInfo();
    SeasonSystem.segment.single.level  = tonumber(DataMgr.maxSegmentSolo.SegmentLevel )
    SeasonSystem.segment.double.level = tonumber(DataMgr.maxSegmentDuo.SegmentLevel)
    SeasonSystem.segment.team.level   =  tonumber(DataMgr.maxSegmentSquad.SegmentLevel)
    
    --[[
    SeasonSystem.segment.single.level = tonumber(DataMgr.roleData.segment.solo);
	SeasonSystem.segment.double.level = tonumber(DataMgr.roleData.segment.double);
	SeasonSystem.segment.team.level = tonumber(DataMgr.roleData.segment.team);
    ]]
    --log_tree("SeasonSystem.segment, " , SeasonSystem.segment);
    SeasonSystem.FetchData(DataMgr.maxSegmentSolo.zoneid); 
end

function SeasonSystem.Release()
	--log("SeasonSystem.Release");
end

function SeasonSystem.NextLevel(score)
    local data = Client.GetTable("RankIntegralLevel")
    local tmp = {}
	for k,v in pairs(data) do
        table.insert(tmp, {v.MinIntegral, v})
    end
    table.sort(tmp, function(a,b) return a[1]<b[1] end)
    for i,v in ipairs(tmp) do
        if v[2].MinIntegral > score then
            return v[2].Level
        end
    end
    return nil
end



function SeasonSystem.FetchData(solozoneid)
    log("SeasonSystem.FetchData");
    --单人总分
     --waynedong todo 2
    NetUtil.SendPkg("get_one_user_rank", "season_1001", solozoneid, 0, 1001);
    --战绩信息
    curBattleInfoReqModeType = "solo";
    SeasonSystem.segment.single.rating = 0;
    SeasonSystem.segment.double.rating = 0;
    SeasonSystem.segment.team.rating = 0;
    NetUtil.SendPkg("get_role_battle_max_rank_rating");
    --拉取任务列表
    NetUtil.SendPriorityPkg(false, "get_task_state_list_rsp", "get_task_state_list");
end

function SeasonSystem.TakeSeasonInReward(id)
    --log("SeasonSystem.TakeSeasonInReward="..id);
    NetUtil.SendPriorityPkg(false, "take_season_task_prize_rsp", "take_season_task_prize", id);
end

function SeasonSystem.TakeSeasonEndReward(season_id)
    --log("SeasonSystem.TakeSeasonEndReward="..season_id);
    NetUtil.SendPriorityPkg(false, "take_season_end_prize_rsp", "take_season_end_prize", season_id);
end
--[[
function SeasonSystem.get_role_battle_info_rsp(res, callback, optype, role_combat_info, zone_id, seasonid)
	if optype ~= BP_COMBAT_MSG_TYPE_SEASON then
		return;
	end
    --log_tree(" SeasonSystem.get_role_battle_info_rsp", {res, callback, optype, role_combat_info, zone_id,seasonid});
    if res ~= 0 then
        DataMgr.ShowNoticeByID(res)
		return;
	end
    
    --log(" curBattleInfoReqModeType "..curBattleInfoReqModeType);
    
    if curBattleInfoReqModeType == "solo" then
        SeasonSystem.segment.single.rating = SeasonSorceInt(role_combat_info.warsolo.rank_rating);
        curBattleInfoReqModeType = "duo";
        NetUtil.SendPkg("get_role_battle_info", tonumber(DataMgr.roleData.uid), nil, BP_COMBAT_MSG_TYPE_SEASON, DataMgr.maxSegmentDuo.zoneid);
    elseif curBattleInfoReqModeType == "duo" then
        SeasonSystem.segment.double.rating = SeasonSorceInt(role_combat_info.warduo.rank_rating)
        curBattleInfoReqModeType = "team";
        NetUtil.SendPkg("get_role_battle_info", tonumber(DataMgr.roleData.uid), nil, BP_COMBAT_MSG_TYPE_SEASON, DataMgr.maxSegmentSquad.zoneid);
    elseif curBattleInfoReqModeType == "team" then
        SeasonSystem.segment.team.rating = SeasonSorceInt(role_combat_info.warsquad.rank_rating)
    end

    log_tree(" SeasonSystem.segment", SeasonSystem.segment);
    SeasonUI.RefreshSegment()
end
]]

function SeasonSystem.get_role_battle_max_rank_rating_rsp(solo_max_rank_rating, duo_max_rank_rating, squad_max_rank_rating)
    SeasonSystem.segment.single.rating = solo_max_rank_rating
    SeasonSystem.segment.double.rating = duo_max_rank_rating
    SeasonSystem.segment.team.rating = squad_max_rank_rating
    log_tree(" SeasonSystem.segment", SeasonSystem.segment);
    SeasonUI.RefreshSegment()
end

function SeasonSystem.get_one_user_rank_rsp(client_data, ok, zone_id, rank_info)
    --log_tree("SeasonSystem.get_one_user_rank_rsp=",{client_data, ok, zone_id, rank_info});
    if client_data == "season_1001" then
        --log_tree("SeasonSystem.get_one_user_rank_rsp=",{client_data, ok, rank_info});
        if ok == 0 then
            if rank_info.rank_no == nil then
                SeasonSystem.segment.single.rankno = 0
            else
                SeasonSystem.segment.single.rankno = rank_info.rank_no
            end
            SeasonUI.RefreshSegment()
            --双人总分
            NetUtil.SendPkg("get_one_user_rank", "season_2001", DataMgr.maxSegmentDuo.zoneid, 0, 2001);
        end
    elseif client_data == "season_2001" then
        --log_tree("SeasonSystem.get_one_user_rank_rsp=",{client_data, ok, rank_info});
        if ok == 0 then
            if rank_info.rank_no == nil then
                SeasonSystem.segment.double.rankno = 0
            else
                SeasonSystem.segment.double.rankno = rank_info.rank_no
            end
            SeasonUI.RefreshSegment()
            --四人总分
            NetUtil.SendPkg("get_one_user_rank", "season_3001", DataMgr.maxSegmentSquad.zoneid, 0, 3001);
        end
    elseif client_data == "season_3001" then
        --log_tree("SeasonSystem.get_one_user_rank_rsp=",{client_data, ok, rank_info});
        if ok == 0 then
            if rank_info.rank_no == nil then
                SeasonSystem.segment.team.rankno = 0
            else
                SeasonSystem.segment.team.rankno = rank_info.rank_no
            end
            SeasonUI.RefreshSegment()
        end
    end
end



--[[
    ├─ ok: 0
    └─ season:
        ├─ 1                        赛季ID
        │  ├─ 10102                 奖励ID
        │  │  ├─ condition2: 0      condition2 表示次数
        │  │  ├─ condition1: 0      condition1 = 1表示达标 0表示不达标
        │  │  └─ prize_status: 1    1表示未领取 2表示已领取
        │  └─ 10101
        │     ├─ condition2: 0
        │     ├─ condition1: 0
        │     └─ prize_status: 1    1表示未领取 2表示已领取
        └─ season_end_prize
            ├─ season_index: 1      赛季ID
            └─ status: 1            1表示未领取 2表示已领取
    cur_season_id                   当前赛季ID
    is_idle_time                    是否空窗期
    best_segment                    当前赛季最高段位
    pre_best_segment                上赛季最高段位
]]

function SeasonSystem.get_task_state_list_rsp(ok, season, cur_season_id, is_idle_time, best_segment, pre_best_segment)
    log_tree("SeasonSystem.get_task_state_list_rsp=", {ok, season, cur_season_id, is_idle_time, best_segment, pre_best_segment})
    if ok ~= 0 then
        DataMgr.ShowNoticeByID(ok)
		return;
    end
    SeasonSystem.cur_season_id = cur_season_id
    
    --如果当前赛季最高段位无效，取当前最高段位
    local cfg_segment = Client.GetTableData("RankIntegralLevel", best_segment)
    if cfg_segment == nil then
        local tmp = {}
        table.insert(tmp, SeasonSystem.segment.single.level)
        table.insert(tmp, SeasonSystem.segment.double.level)
        table.insert(tmp, SeasonSystem.segment.team.level)
        table.sort(tmp, function(a,b) return a>b end)
        SeasonSystem.best_segment = tmp[1]
        --log("SeasonSystem.best_segment="..SeasonSystem.best_segment)
    else
        SeasonSystem.best_segment = best_segment
    end
    
    --如果上赛季最高段位无效，取当前最高段位
    local cfg_segment = Client.GetTableData("RankIntegralLevel", pre_best_segment)
    if cfg_segment == nil then
        SeasonSystem.pre_best_segment = SeasonSystem.best_segment
    else
        SeasonSystem.pre_best_segment = pre_best_segment
    end
    
    SeasonSystem.is_idle_time = is_idle_time
    SeasonSystem.season_in_reward = {}
    if type(season.task_list) == "table" then
        for k,v in pairs(season.task_list) do
            local reword = {}
            reword.id = k
            local cfg = Client.GetTableData("SeasonInReward", reword.id)
            if cfg then
                reword.sort_n = cfg.SortID
            else
                reword.sort_n = reword.id
            end
            reword.condition1 = v.condition1
            reword.condition2 = v.condition2
            reword.prize_status = v.prize_status
            table.insert(SeasonSystem.season_in_reward, reword)
        end
        table.sort(SeasonSystem.season_in_reward, function(a,b) return a.sort_n < b.sort_n end)
    end
    SeasonSystem.season_end_reward = {}
    if type(season.season_end_prize) == "table" then
        SeasonSystem.season_end_reward = FuncUtil:CopyTable(season.season_end_prize)
    end
    SeasonUI.RefreshSeason()
end

function SeasonSystem.take_season_task_prize_rsp(ok, itmid)
    log_tree("SeasonSystem.take_season_task_prize_rsp=", {ok, itmid})
    if ok ~= 0 then
        DataMgr.ShowNoticeByID(ok)
		return;
	end
    --DataMgr.ShowNoticeByString("成功领取赛季任务奖励！");
    DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301289").TextValue);
    --拉取任务列表
    NetUtil.SendPriorityPkg(false, "get_task_state_list_rsp", "get_task_state_list");
end

function SeasonSystem.take_season_end_prize_rsp(ok, itmid)
    log_tree("SeasonSystem.take_season_end_prize_rsp=", {ok, itmid})
    if ok ~= 0 then
        DataMgr.ShowNoticeByID(ok)
		return;
	end
    --DataMgr.ShowNoticeByString("成功领取赛季结束奖励！");
    DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301290").TextValue);
    --拉取任务列表
    NetUtil.SendPriorityPkg(false, "get_task_state_list_rsp", "get_task_state_list");
end

--[[网络回调]]--
s2c["get_task_state_list_rsp"] = SeasonSystem.get_task_state_list_rsp;
s2c["take_season_task_prize_rsp"] = SeasonSystem.take_season_task_prize_rsp;
s2c["take_season_end_prize_rsp"] = SeasonSystem.take_season_end_prize_rsp;
s2c["get_role_battle_max_rank_rating_rsp"] = SeasonSystem.get_role_battle_max_rank_rating_rsp;


