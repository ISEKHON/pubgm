
--[[
 排行榜相关逻辑
profile = {
    uid   = 0,
    name  = "",
    level = 0,
    city  = "",
    gender = 0,
    rankdata = {
      total_rank_rating,
      solo = {
       rank_rating =,  总积分
       playtime =, 生存时长
       win_rating =, 生存积分
       kill_rating =, 击败积分
       win_num =,   总吃鸡数
       top10_count =, 前十数
       win_ratio =, 吃鸡率
       kill_num =,  总击败数
       max_kill=,  单局最高击败
       kd =,  击败/淘汰
      },
      duo  = {
       rank_rating =,  总积分
       playtime =, 生存时长
       win_rating =, 胜利积分
       kill_rating =, 击败积分
       win_num =,   总吃鸡数
       win_ratio =, 胜率
       kill_num =,  总击败数
       max_kill=,  单局最高击败
       kd =,  击败/淘汰
      },
      squad = {
       rank_rating =,  总积分
       playtime =, 总游戏时长
       win_rating =, 胜利积分
       kill_rating =, 击败积分
       win_num =,   总吃鸡数
       win_ratio =, 胜率
       kill_num =,  总击败数
       max_kill=,  单局最高击败
       kd =,  击败/淘汰
      },
    },
}
]]--



RankSystem = RankSystem or
{
    RankRoleInfoItem =
    {
        uid   = "",
        name  = "",
        plat_name = "",
        url   = "",
        level = 0,
        city  = "",
        gender = 0,
		startup_type = 0,--启动类型
		qq_vip = 0,--qq会员
        rankdata = {
            total_rank_rating = 0,
            solo = {
                rank_rating = 0,    --总积分
                playtime = 0,       --生存时长
                win_rating = 0,     --生存积分
                kill_rating = 0,    --击败积分
                win_num = 0,        --总吃鸡数
                top10_count = 0,    --前十数
                win_ratio = 0,      --吃鸡率
                kill_num = 0,       --总击败数
                max_kill = 0,       --单局最高击败
                kd = 0,             --击败/淘汰
            },
            duo = {
                rank_rating = 0,    --总积分
                playtime = 0,       --生存时长
                win_rating = 0,     --生存积分
                kill_rating = 0,    --击败积分
                win_num = 0,        --总吃鸡数
                win_ratio = 0,      --胜率
                kill_num = 0,       --总击败数
                max_kill = 0,       --单局最高击败
                kd = 0,             --击败/淘汰
            },
            squad = {
                rank_rating = 0,    --总积分
                playtime = 0,       --生存时长
                win_rating = 0,     --生存积分
                kill_rating = 0,    --击败积分
                win_num = 0,        --总吃鸡数
                win_ratio = 0,      --胜率
                kill_num = 0,       --总击败数
                max_kill = 0,       --单局最高击败
                kd = 0,             --击败/淘汰
            },
        },
        segment_info = {
            [1] = 1,
            [2] = 1,
            [3] = 1,
        },
        all_segment_info = {},
        cur_avatar_box_id = 0,
    },
	--排行榜
    RankInfoListItem =
    {
        no = 0,
        uid = "",
        score = 0,
        name = "",              --名称
        url = "",               --头像
        level = 0,              --等级
        city = "",              --地点
        gender = 0,             --性别
        content1 = "",
        content2 = "",
        content3 = "",
        segment = 0,            --段位
        cur_avatar_box_id = 0,  --头像框
		startup_type = 0,--启动类型
		qq_vip = 0,--qq会员
    },
	RankInfoList = {},
    RankInfoSelf =
    {
        no = 0,
        uid = "",
        score = 0,
        name = "",              --名称
        url = "",               --头像
        level = 0,              --等级
        city = "",              --地点
        gender = 0,             --性别
        content1 = "",
        content2 = "",
        content3 = "",
        segment = 0,            --段位
        cur_avatar_box_id = 0,  --头像框
		startup_type = 0,--启动类型
		qq_vip = 0,--qq会员
    },
    --sum总分榜 win胜利榜 beat击败榜 total综合榜
    RankSelectType = "sum";
    --single单人 double双人 team组队
    RankSelectMemberType = "single";
    --all全区 friend好友
    RankRegionType = "all";
    RankFriendList = {},
    RankRoleInfo = {},
    RankRoleInfoSending = {},
    QueryRankRoleInfoByIdxFrom = 1,
    OnePageCount = 5,
    FriendRemark = {},
}
local ScoreType = {
    total_rating       = 1000, -- 综合总积分
    solo_total_rating  = 1001, -- 单排总积分
    solo_win_rating    = 1002, -- 单排胜利积分
    solo_kill_rating   = 1003, -- 单排击败积分
    duo_total_rating   = 2001, -- 双排总积分
    duo_win_rating     = 2002, -- 双排胜利积分
    duo_kill_rating    = 2003, -- 双排基本积分
    squad_total_rating = 3001, -- 四排总积分
    squad_win_rating   = 3002, -- 四排胜利积分
    squad_kill_rating  = 3003, -- 四排击败积分
}
local function scoretype2RankType(scoretype)
    local score_type_conv = {
        [ScoreType.total_rating      ] = {member_type = RankSystem.RankSelectMemberType, rank_type = "total"}, -- 综合总积分
        [ScoreType.solo_total_rating ] = {member_type = "single", rank_type = "sum"},   -- 单排总积分
        [ScoreType.solo_win_rating   ] = {member_type = "single", rank_type = "win"},   -- 单排胜利积分
        [ScoreType.solo_kill_rating  ] = {member_type = "single", rank_type = "beat"},  -- 单排击败积分
        [ScoreType.duo_total_rating  ] = {member_type = "double", rank_type = "sum"},   -- 双排总积分
        [ScoreType.duo_win_rating    ] = {member_type = "double", rank_type = "win"},   -- 双排胜利积分
        [ScoreType.duo_kill_rating   ] = {member_type = "double", rank_type = "beat"},  -- 双排基本积分
        [ScoreType.squad_total_rating] = {member_type = "team", rank_type = "sum"},     -- 四排总积分
        [ScoreType.squad_win_rating  ] = {member_type = "team", rank_type = "win"},     -- 四排胜利积分
        [ScoreType.squad_kill_rating ] = {member_type = "team", rank_type = "beat"},    -- 四排击败积分
    };
    return score_type_conv[scoretype];
end
local function RankType2scoretype(rank_type, member_type)
    local rank_type_conv = {
        sum = 1,
        win = 2,
        beat = 3,
    };
    local member_type_conv = {
        single = 1000,
        double = 2000,
        team = 3000,
    };
    if rank_type == "total" then
        return ScoreType.total_rating;
    end
    local hn = member_type_conv[member_type];
    local ln = rank_type_conv[rank_type];
    return hn + ln;
end

--时间转字符串
function RankTimeToStringHHMMSS(tm)
    if type(tm) ~= "number" then
        return ""
    end
    tm = math.modf(tm)
    local months = math.modf(tm / (60*60*24*30))
    if months >= 1 then
		local days = math.modf(math.fmod(tm, 60*60*24*30) / (60*60*24))
        if days > 0 then
			--return string.format("%d月%d天", months, days)
			return string.format(Client.GetTableData("LocalizeRes",301150).TextValue, months, days)
		else
			--return string.format("%d月", months)
			return string.format(Client.GetTableData("LocalizeRes",301151).TextValue, months)
		end
    end
	local days = math.modf(tm / (60*60*24))
    if days >= 1 then
		local hours = math.modf(math.fmod(tm, 60*60*24) / (60*60))
		if hours > 0 then
			--return string.format("%d天%d小时", days, hours)
			return string.format(Client.GetTableData("LocalizeRes",301152).TextValue, days, hours)
		else
			--return string.format("%d天", days)
			return string.format(Client.GetTableData("LocalizeRes",301153).TextValue, days)
		end
    end
	local hours = math.modf(tm / (60*60))
    if hours >= 1 then
		local mins = math.modf(math.fmod(tm, 60*60) / 60)
		if mins > 0 then
			--return string.format("%d小时%d分", hours, mins)
			return string.format(Client.GetTableData("LocalizeRes",301154).TextValue, hours, mins)
		else
			--return string.format("%d小时", hours)
			return string.format(Client.GetTableData("LocalizeRes",301155).TextValue, hours)
		end
    end
	local mins = math.modf(tm / 60)
	local last_tm = math.fmod(tm, 60)
    if mins >= 1 then
        --return string.format("%d分", mins)
		return string.format(Client.GetTableData("LocalizeRes",301156).TextValue, mins)
    end
    --return string.format("%d秒", last_tm)
	return string.format(Client.GetTableData("LocalizeRes",301157).TextValue, last_tm)
end

--积分四舍五入
local function RankSorceInt(score)
    return math.floor(score+0.5)
end

function RankSystem.Enter()
	--log("RankSystem enter");
    
    RankSystem.RankInfoList = {};
    
    --这里应该加入自己的信息
    RankSystem.RankRoleInfo = {};
    RankSystem.RankRoleInfoSending = {};
    
    --log_tree("DataMgr.roleData=", DataMgr.roleData);
    local selfRole = FuncUtil:CopyTable(RankSystem.RankRoleInfoItem);
    selfRole.uid = tostring(DataMgr.roleData.uid);
    selfRole.name = DataMgr.roleData.nickName;
    selfRole.url = DataMgr.roleData.headIconUrl;
    selfRole.level = DataMgr.roleData.level;
    selfRole.gender = DataMgr.roleData.gender;
    selfRole.cur_avatar_box_id = DataMgr.roleData.cur_avatar_box_id;
	selfRole.startup_type = BP_StartUpType;
	selfRole.qq_vip = DataMgr.roleData.qq_vip;
    --log_tree("selfRole=", selfRole)
    RankSystem.RankRoleInfo[selfRole.uid] = selfRole;
    RankSystem.RankInfoSelf.uid = tostring(DataMgr.roleData.uid);
    log("BP_Back_ShowRankZoneId = "..BP_Back_ShowRankZoneId);
    RankSystem.UpdateRankSelf(BP_Back_ShowRankZoneId);
    --这里还缺rankdata，先拉取一下
    ProfileMgr.GetRankProfileList({tonumber(DataMgr.roleData.uid)}, RankSystem.RspRankRoleInfo)
    
    RankSystem.RankFriendList = {};
    
    --获得好友备注
    RankSystem.FriendRemark = {}
    for i,v in ipairs(BP_ARRAY_All_Friend_Profile) do
        if v.remarks_name ~= "" then
            RankSystem.FriendRemark[v.gid] = v.remarks_name
        end
    end
    
end

function RankSystem.Release()

	--log("RankSystem enter");
    RankSystem.RankInfoList = {};
    --这里应该加入自己的信息
    RankSystem.RankRoleInfo = {};
    RankSystem.RankRoleInfoSending = {};
    RankSystem.RankFriendList = {};
    RankSystem.FriendRemark = {}
end

function RankSystem.AddTestRank()
    
end

--请求拉取排行榜
function RankSystem.ReqFetchRankData(bQueryFriend, zoneId)
    log("RankSystem.ReqFetchRankData zoneid = "..zoneId..", bQueryFriend = "..tostring(bQueryFriend))
    if RankSystem.RankRegionType == "friend" then
        if bQueryFriend then
            RankSystem.ReqFriendRankRole(zoneId);
        else
            RankSystem.UpdateFriendRankRole(zoneId);
        end
    else
        local st = RankType2scoretype(RankSystem.RankSelectType, RankSystem.RankSelectMemberType);
        --log_tree("RankSystem.ReqFetchRankData", st);
        NetUtil.SendPriorityPkg(false, "get_topn_rank_rsp", "get_topn_rank", zoneId, st);
        --自己的
        NetUtil.SendPkg("get_one_user_rank", "rank", zoneId, 0, st);
    end
end

--返回拉取排行榜
function RankSystem.RspFetchRankData(ok, zone_id, score_type, list)
    --log_tree("RankSystem.RspFetchRankData ret=", {ok, zone_id, score_type, list})
    if ok == 0 then
        local st = scoretype2RankType(score_type)
        RankSystem.RankRegionType = "all";
        RankSystem.RankSelectType = st.rank_type
        RankSystem.RankSelectMemberType = st.member_type
        RankSystem.RankInfoList = {};
        if list == nil then
            list = {}
        end
        for i,v in ipairs(list) do
            local itm = FuncUtil:CopyTable(RankSystem.RankInfoListItem)
            itm.no = v.rank_no
            itm.uid = tostring(v.uid)
            itm.score = v.score
            RankSystem.UpdateRankRole(itm, v.uid, zone_id)
            itm.score = RankSorceInt(itm.score)
            table.insert(RankSystem.RankInfoList, itm)
        end
        EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_LIST)
    end
end

--返回自己的排行榜
function RankSystem.RspFetchSelfRankData(client_data,  ok, zoneId, rank_info)
    if client_data == "rank" then
        --log("client_data = "..client_data ..", ok="..ok..", zoneId = "..zoneId)
        --log_tree("wayne rank_info=", rank_info)
        if ok == 0 then
            if rank_info.rank_no == nil then
                RankSystem.RankInfoSelf.no = 0;
                RankSystem.RankInfoSelf.score = 0;
            else
                RankSystem.RankInfoSelf.no = rank_info.rank_no;
                RankSystem.RankInfoSelf.score = rank_info.score;
            end
            RankSystem.RankInfoSelf.score = RankSorceInt(RankSystem.RankInfoSelf.score)
            --log_tree("RankSystem.RankInfoSelf ", RankSystem.RankInfoSelf );
            RankSystem.UpdateRankRole(RankSystem.RankInfoSelf, tostring(DataMgr.roleData.uid), zoneId);
            EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF);
        end
    end
end

function RankSystem.QueryRankRoleInfoByScroll()
    local listUid = {}
    local pageidx = math.modf(RankSystem.QueryRankRoleInfoByIdxFrom / RankSystem.OnePageCount)
    for i=pageidx-1,pageidx+2 do
        for j=1,RankSystem.OnePageCount do
            local idx = i*RankSystem.OnePageCount + j
            local itm = RankSystem.RankInfoList[idx]
            if itm then
                local role = RankSystem.RankRoleInfo[itm.uid];
                if role == nil then
                    local curtm = os.time();
                    local tm = RankSystem.RankRoleInfoSending[itm.uid];
                    if tm == nil or (curtm - tm > 30) then
                        RankSystem.RankRoleInfoSending[itm.uid] = curtm;
                        table.insert(listUid, tonumber(itm.uid));
                    end
                end
            end
            
        end
    end
    if #listUid > 0 then
        ProfileMgr.GetRankProfileList(listUid, RankSystem.RspRankRoleInfo)
    end
end

function RankSystem.RspRankRoleInfo(profileList)

    --log_tree("RankSystem.RspRankRoleInfo profileList", profileList)
    if type(profileList) ~= "table" then
        return
    end
    local list = {}
    for i,v in ipairs(profileList) do
        list[v.uid] = v
    end
    for k,v in pairs(list) do
        local role = FuncUtil:CopyTable(RankSystem.RankRoleInfoItem)
        role.uid = tostring(k)
        role.name  = v.nickName
        --平台名
        if type(v.platName) == "string" and v.platName ~= "" then
            role.plat_name = v.platName
        else
            role.plat_name = ""
        end
        --备注名
        local remark = RankSystem.FriendRemark[role.uid]
        if remark then
            role.plat_name = remark
        end
        role.url   = v.picUrl
        role.level = v.level
        role.city  = ""
        role.gender = v.sex
        if v.startup_type ~= nil then
            role.startup_type = v.startup_type
        end
        if v.qq_vip ~= nil then
            role.qq_vip = v.qq_vip
        end
        
        -------------------------------intl modify----------------------------------
        --[[
        if type(v.rankdata) == "table" then
            role.rankdata = FuncUtil:CopyTable(v.rankdata)
        end
        if type(v.segment_info) == "table" then
            for i1,v1 in ipairs(role.segment_info) do
                local n = v.segment_info[i1]
                if type(n) == "number" then
                    role.segment_info[i1] = n
                end
            end
        end
        ]]
       --记录所有区排行榜数据
       role.allzonerankdata = v.rankdata;
       -- 选当前区的排行信息
        if type(v.rankdata) == "table" then
            if v.rankdata[BP_Back_ShowRankZoneId] ~= nil then
                role.rankdata = FuncUtil:CopyTable(v.rankdata[BP_Back_ShowRankZoneId])
            end
        end
        -- 选当前区的段位信息
        role.all_segment_info =v.segment_info;
        cur_zone_segment_info = role.all_segment_info[BP_Back_ShowRankZoneId];
        if cur_zone_segment_info ~= nil then
             for i1,v1 in ipairs(role.segment_info) do
                    role.segment_info[i1] = cur_zone_segment_info[i1]
             end
        end
        
        log_tree("RankSystem.RspRankRoleInfo Role = " , role)
        -------------------------------intl modify----------------------------------
        
        if type(v.cur_avatar_box_id) == "number" then
            role.cur_avatar_box_id = v.cur_avatar_box_id
        end
        RankSystem.RankRoleInfo[role.uid] = role
        RankSystem.RankRoleInfoSending[role.uid] = nil
    end
    for i,v in ipairs(RankSystem.RankInfoList) do
        if list[tonumber(v.uid)] then
            RankSystem.UpdateRankRole(v, v.uid, BP_Back_ShowRankZoneId)
            EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_ITEM, v)
        end
    end
    for k,v in pairs(list) do
        if tostring(DataMgr.roleData.uid) == tostring(k) then
            --log("RspRankRoleInfo EVENTID_RANK_UPDATE_SELF")
            RankSystem.UpdateRankSelf(BP_Back_ShowRankZoneId)
            break
        end
    end
end

function RankSystem.UpdateRankRole(itm, uid, zoneId)
    local role = RankSystem.RankRoleInfo[uid];
    if role == nil then
        return false
    end
    if RankSystem.RankRegionType == "friend" and 
        role.plat_name ~= "" and 
        tostring(DataMgr.roleData.uid) ~= tostring(uid) then
        itm.name = string.format("%s(%s)", role.name, role.plat_name)
    else
        itm.name = role.name
    end
    itm.url = role.url
    itm.level = role.level
    itm.city = role.city
    itm.gender = role.gender
	itm.startup_type = role.startup_type
	itm.qq_vip = role.qq_vip
    itm.content1 = ""
    itm.content2 = ""
    itm.content3 = ""
    itm.segment = 1
    itm.cur_avatar_box_id = role.cur_avatar_box_id
    local mt = nil
    --log("RankSystem.UpdateRankRole zoneId =" ..zoneId)
    --log_tree("--------- RankSystem.UpdateRankRole role", role);
    if zoneId~=nil and zoneId > 0 and role.allzonerankdata~=nil and role.allzonerankdata[zoneId]~=nil then
        role.rankdata = role.allzonerankdata[zoneId]
    end
    if RankSystem.RankSelectMemberType == "single" then
        mt = role.rankdata.solo
        itm.segment = role.segment_info[1]
    elseif RankSystem.RankSelectMemberType == "double" then
        mt = role.rankdata.duo
        itm.segment = role.segment_info[2]
    elseif RankSystem.RankSelectMemberType == "team" then
        mt = role.rankdata.squad
        itm.segment = role.segment_info[3]
    end
    if mt then
        if RankSystem.RankSelectType == "sum" then
            itm.content1 = RankTimeToStringHHMMSS(mt.playtime)
            itm.content2 = tostring(RankSorceInt(mt.win_rating))
            itm.content3 = tostring(RankSorceInt(mt.kill_rating))
        elseif RankSystem.RankSelectType == "win" then
            itm.content1 = tostring(mt.win_num)
            itm.content2 = tostring(mt.top10_count)
            itm.content3 = string.format("%.2f%%", mt.win_ratio*100)
        elseif RankSystem.RankSelectType == "beat" then
            itm.content1 = tostring(mt.kill_num)
            itm.content2 = tostring(mt.max_kill)
            itm.content3 = string.format("%.2f", mt.kd)
        end
    end
    if RankSystem.RankSelectType == "total" then
        itm.content1 = tostring(RankSorceInt(role.rankdata.solo.rank_rating))
        itm.content2 = tostring(RankSorceInt(role.rankdata.duo.rank_rating))
        itm.content3 = tostring(RankSorceInt(role.rankdata.squad.rank_rating))
        --取最高段位
        local tmp = FuncUtil:CopyTable(role.segment_info)
        table.sort(tmp, function(a,b) return a > b end)
        itm.segment = tmp[1]
    end
    --未上榜读取自己的分数
    if itm.no == 0 then
        itm.score = role.rankdata.total_rank_rating
        if RankSystem.RankSelectMemberType == "single" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = role.rankdata.solo.rank_rating
            elseif RankSystem.RankSelectType == "win" then
                itm.score = role.rankdata.solo.win_rating
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = role.rankdata.solo.kill_rating
            end
        elseif RankSystem.RankSelectMemberType == "double" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = role.rankdata.duo.rank_rating
            elseif RankSystem.RankSelectType == "win" then
                itm.score = role.rankdata.duo.win_rating
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = role.rankdata.duo.kill_rating
            end
        elseif RankSystem.RankSelectMemberType == "team" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = role.rankdata.squad.rank_rating
            elseif RankSystem.RankSelectType == "win" then
                itm.score = role.rankdata.squad.win_rating
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = role.rankdata.squad.kill_rating
            end
        end
        itm.score = RankSorceInt(itm.score)
    end
    return true
end

function RankSystem.UpdateRankSelf(zoneId)
    RankSystem.UpdateRankRole(RankSystem.RankInfoSelf, tostring(DataMgr.roleData.uid), zoneId);
    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF);
end

function RankSystem.ReqFriendRankRole(zoneid)
    --获得好友列表
    local tmp = {};
    --log_tree("ID_PLAT_FRIENDLIST", ID_PLAT_FRIENDLIST);
    --log_tree("ID_INNER_FRIENDLIST", ID_INNER_FRIENDLIST);
    --去重
    for i,v in ipairs(ID_PLAT_FRIENDLIST) do
        tmp[v] = 1;
    end
    for i,v in ipairs(ID_INNER_FRIENDLIST) do
        tmp[v] = 1;
    end
    local lstFriendUid = {};
    table.insert(lstFriendUid, tonumber(DataMgr.roleData.uid));
    for k,v in pairs(tmp) do
        table.insert(lstFriendUid, tonumber(k));
        if #lstFriendUid >= 300 then
            --log_tree("lstFriendUid=", lstFriendUid)
            NetUtil.SendPriorityPkg(false, "get_friend_rank_rsp", "get_friend_rank", zoneid, lstFriendUid);
            lstFriendUid = {};
        end
    end
    --请求好友排行榜
    if #lstFriendUid > 0 then
        --log_tree("lstFriendUid=", lstFriendUid)
        NetUtil.SendPriorityPkg(false, "get_friend_rank_rsp", "get_friend_rank", zoneid, lstFriendUid);
    end
    RankSystem.RankFriendList = {};
end

function RankSystem.RspFriendRankRole(ok, zoneid, list)
    --log_tree("get_friend_rank_rsp ok=", ok)
    --log_tree("get_friend_rank_rsp list=", list)
    log("RankSystem.RspFriendRankRole zoneid = "..zoneid)
    if ok == 0 then
        for k,v in pairs(list) do
            RankSystem.RankFriendList[k] = v;
        end
        RankSystem.UpdateFriendRankRole(zoneid);
    end
    --log_tree("RankSystem.RankFriendList", RankSystem.RankFriendList)
end

function RankSystem.UpdateFriendRankRole(zoneId)
    log("RankSystem.UpdateFriendRankRole，zoneId= "..zoneId)
    RankSystem.RankRegionType = "friend";
    RankSystem.RankInfoList = {};
    RankSystem.RankInfoSelf.no = 0;
    RankSystem.RankInfoSelf.score = 0;
    for k,v in pairs(RankSystem.RankFriendList) do
        local itm = FuncUtil:CopyTable(RankSystem.RankInfoListItem)
        itm.uid = tostring(k);
        itm.score = v.total_rank_rating;
        if RankSystem.RankSelectMemberType == "single" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = v.solo_rank_rating;
            elseif RankSystem.RankSelectType == "win" then
                itm.score = v.solo_win_rating;
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = v.solo_kill_rating;
            end
        elseif RankSystem.RankSelectMemberType == "double" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = v.duo_rank_rating;
            elseif RankSystem.RankSelectType == "win" then
                itm.score = v.duo_win_rating;
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = v.duo_kill_rating;
            end
        elseif RankSystem.RankSelectMemberType == "team" then
            if RankSystem.RankSelectType == "sum" then
                itm.score = v.squad_rank_rating;
            elseif RankSystem.RankSelectType == "win" then
                itm.score = v.squad_win_rating;
            elseif RankSystem.RankSelectType == "beat" then
                itm.score = v.squad_kill_rating;
            end
        end
        itm.score = RankSorceInt(itm.score)
        table.insert(RankSystem.RankInfoList, itm);
    end
    local function compFunc(a1, a2)
        return a1.score > a2.score;
    end
    table.sort(RankSystem.RankInfoList, compFunc)
    for i,v in ipairs(RankSystem.RankInfoList) do
        v.no = i;
        RankSystem.UpdateRankRole(v, v.uid, zoneId);
    end
    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_LIST);
    --log_tree("----------- RankSystem.RankInfoList, " , RankSystem.RankInfoList)
    for i,v in pairs(RankSystem.RankInfoList) do
        if tostring(v.uid) == tostring(DataMgr.roleData.uid) then
            RankSystem.RankInfoSelf = FuncUtil:CopyTable(v)
            break
        end
    end
    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF);
end

--[[网络回调]]--
s2c["get_topn_rank_rsp"] = RankSystem.RspFetchRankData;
s2c["get_one_user_rank_rsp"] = function(...)
    RankSystem.RspFetchSelfRankData(...);
	RoleInfoSystem.get_role_rank_info_rsp(...);
    SeasonSystem.get_one_user_rank_rsp(...);
end;
s2c["get_friend_rank_rsp"] = RankSystem.RspFriendRankRole;

