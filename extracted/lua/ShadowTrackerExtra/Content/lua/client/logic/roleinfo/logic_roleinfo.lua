--[[
  个人信息的相关逻辑
]]--

RoleInfoSystem = RoleInfoSystem or
{
	Update_Ctrl = 0;			--更新控制计数
	seasonid = 0;
	PlatID = "";
	IsMaxLevel = false;
	IsFriend = false;
	PersonalBasicInfo = {},
	PersonalTotalRankInfo = {},
	PersonalTotalScoreInfo = {},
	CombatTotalInfoList = {},
	CombatSurviveInfoList = {},
	CombatScoreInfoList = {},
	CombatBattleInfoList = {},
	
	CombatTotalInfo =
	{
		role_allmatchnum = 0,
		role_winnum = 0,
		role_toptennum = 0,
		role_killnum = 0,
		role_kd = 0,
		role_critrate = 0,
	},
	CombatSurviveInfo =
	{
		role_maxsurvivetime = 0,
		role_avesurvivetime = 0,
		role_maxdistance = 0,
		role_avedistance = 0,
		role_aveheal = 0,
		role_aidcount = 0,
	},
	CombatScoreInfo =
	{
		role_score = 0,
		role_killscore = 0,
		role_rankscore = 0,
	},
	CombatBattleInfo =
	{
		role_hitrate = 0,
		role_critcount = 0,
		role_maxkill = 0,
		role_maxdamage = 0,
		role_avedamage = 0,
	},
    CurShowPlayerInfoUid = 0,
}

CacheRoleInfo = {};

-- 分数类型 需要和 apollo topn服务定义的一致
local score_type = {
    total_rating       = 1000, -- 综合总积分
    solo_total_rating  = 1001, -- 单排总积分
    solo_win_rating    = 1002, -- 单排胜利积分
    solo_kill_rating   = 1003, -- 单排击败积分
    duo_total_rating   = 2001, -- 双排总积分
    duo_win_rating     = 2002, -- 双排胜利积分
    duo_kill_rating    = 2003, -- 双排击败积分
    squad_total_rating = 3001, -- 四排总积分
    squad_win_rating   = 3002, -- 四排胜利积分
    squad_kill_rating  = 3003, -- 四排击败积分
};

function RoleInfoSystem.Enter(uid)
	log("RoleInfoSystem Enter");
    RoleInfoSystem.CurShowPlayerInfoUid = uid;
	RoleInfoSystem.Update_Ctrl = 0;
	RoleInfoSystem.seasonid = 0;
	RoleInfoSystem.PlatID = "";
	RoleInfoSystem.IsMaxLevel = false;
	RoleInfoSystem.IsFriend = false;
	
	RoleInfoSystem.SetEmpty();
	RoleInfoSystem.IsRoleFriend(uid);
    RoleInfoSystem.RequestRoleInfo();
	--[[
	RoleInfoSystem.get_profile_info_req(uid);
	RoleInfoSystem.get_role_battle_info_req(uid);
	RoleInfoSystem.get_role_rank_info_req(uid, score_type.total_rating);
    ]]
end

--请求各种信息
function RoleInfoSystem.RequestRoleInfo()
    if BP_Back_ShowRoleInfoOfZoneId == 0 then
        BP_Back_ShowRoleInfoOfZoneId = DataMgr.GetOneZoneList();
    end
    --if tostring(RoleInfoSystem.CurShowPlayerInfoUid) ~= DataMgr.roleData.uid then
        RoleInfoSystem.get_profile_info_req(RoleInfoSystem.CurShowPlayerInfoUid);
	--end
	RoleInfoSystem.get_role_battle_info_req(RoleInfoSystem.CurShowPlayerInfoUid, BP_Back_ShowRoleInfoOfZoneId);
	RoleInfoSystem.get_role_rank_info_req(RoleInfoSystem.CurShowPlayerInfoUid, score_type.total_rating, BP_Back_ShowRoleInfoOfZoneId);
end

function RoleInfoSystem.Release()
	log("RoleInfoSystem Release");
	RoleInfoSystem.Update_Ctrl = 0;
	RoleInfoSystem.seasonid = 0;
	RoleInfoSystem.PlatID = "";
	RoleInfoSystem.IsMaxLevel = false;
	RoleInfoSystem.IsFriend = false;
	
	RoleInfoSystem.PersonalBasicInfo = {};
	RoleInfoSystem.PersonalTotalRankInfo = {};
	RoleInfoSystem.PersonalTotalScoreInfo = {};
	RoleInfoSystem.CombatTotalInfoList = {};
	RoleInfoSystem.CombatSurviveInfoList = {};
	RoleInfoSystem.CombatScoreInfoList = {};
	RoleInfoSystem.CombatBattleInfoList = {};
end

function RoleInfoSystem.SetEmpty()
	log("RoleInfoSystem SetEmpty");
	
	RoleInfoSystem.PersonalBasicInfo = {};
	RoleInfoSystem.PersonalTotalRankInfo = {};
	RoleInfoSystem.PersonalTotalScoreInfo = {};
	RoleInfoSystem.CombatTotalInfoList = {};
	RoleInfoSystem.CombatSurviveInfoList = {};
	RoleInfoSystem.CombatScoreInfoList = {};
	RoleInfoSystem.CombatBattleInfoList = {};
	
	RoleInfoSystem.PersonalBasicInfo =
	{
		role_name = "",
		role_id = "",
		role_sex = "",
		role_image = "",
		role_curlevel = "",
		role_nextlevel = "",
		role_curexpnum = "",
		role_needexpnum = "",
		role_sign = "",
		role_curlevelnum = 0,
		role_nextlevelnum = 0,
		role_segment_solo = 0,
		role_segment_double = 0,
		role_segment_team = 0,
		role_segment_max = 0,
		role_startup_type = 0,
		role_qqvip = 0,
        role_avatar_frame = 0,
        all_segment_info = {},
	};
	
	RoleInfoSystem.PersonalTotalRankInfo =
	{
		role_totalrank = "",
	}
	
	RoleInfoSystem.PersonalTotalScoreInfo =
	{
		role_totalscore = "";
	}
	
	for i = 1, 4 do
		RoleInfoSystem.CombatTotalInfoList[i] =
		{
			role_allmatchnum = "",
			role_winnum = "",
			role_toptennum = "",
			role_killnum = "",
			role_kd = "",
			role_critrate = "",
		};
	end
	
	for i = 1, 3 do
		RoleInfoSystem.CombatSurviveInfoList[i] =
		{
			role_maxsurvivetime = "",
			role_avesurvivetime = "",
			role_maxdistance = "",
			role_avedistance = "",
			role_aveheal = "",
			role_aidcount = "",
		};
		RoleInfoSystem.CombatScoreInfoList[i] =
		{
			role_score = "",
			role_killscore = "",
			role_rankscore = "",
		};
		RoleInfoSystem.CombatBattleInfoList[i] =
		{
			role_hitrate = "",
			role_critcount = "",
			role_maxkill = "",
			role_maxdamage = "",
			role_avedamage = "",
		};
	end
	
	RoleInfoUI.SetEmptyData();
end

function RoleInfoSystem.IsRoleFriend(uid)
	log("RoleInfoSystem IsRoleFriend");
	for k,v in pairs(ID_INNER_FRIENDLIST) do
		if tostring(v) == tostring(uid) then
			RoleInfoSystem.IsFriend = true;
			return;
		end
	end
end

--请求玩家基本信息
function RoleInfoSystem.get_profile_info_req(uid)
	log("get_profile_info_req");
	ProfileMgr.GetProfile(tonumber(uid), 
        function(listInfo)
            if tostring(uid) ~= DataMgr.roleData.uid then
                RoleInfoSystem.get_role_basic_info_rsp(listType, "ok", listInfo, BP_PROFILE_MSG_TYPE_ROLEINFO)
            else
                RoleInfoSystem.GetSelfBasicInfo();
            end
        end,
	true);
	
	--NetUtil.SendPriorityPkg(true, "batch_get_profile_rsp", "batch_get_profile_req", "", {tonumber(uid)}, BP_PROFILE_MSG_TYPE_ROLEINFO);
end

--请求玩家排行榜信息
function RoleInfoSystem.get_role_rank_info_req(uid, rank_type, zoneId)
	log("get_role_rank_info_req, zoneId = "..zoneId);
	NetUtil.SendPriorityPkg(true, "get_one_user_rank_rsp", "get_one_user_rank", "roleinfo", zoneId, tonumber(uid), rank_type);	
end

--请求玩家战绩信息
function RoleInfoSystem.get_role_battle_info_req(uid, zoneId)
	log("get_role_battle_info_req, zoneId = "..zoneId);
	NetUtil.SendPriorityPkg(true, "get_role_battle_info_rsp", "get_role_battle_info", tonumber(uid), nil, BP_COMBAT_MSG_TYPE_ROLEINFO, zoneId);
end

--请求修改签名
function RoleInfoSystem.send_modify_roleinfo_sign()
	log("send_modify_roleinfo_sign");
	NetUtil.SendPriorityPkg(true, "modify_role_signature_respond", "modify_role_signature", BP_Sign);
end








--拉取自己的概要信息
function RoleInfoSystem.GetSelfBasicInfo()
	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	log("11111111111111111111111111111111111111: "..RoleInfoSystem.Update_Ctrl);
	log("自己自己自己自己自己自己自己自己自己自己自己自己自己");
	
	RoleInfoSystem.PersonalBasicInfo = {};
	RoleInfoSystem.PersonalBasicInfo =
	{
		role_name = DataMgr.roleData.nickName,
		role_id = DataMgr.roleData.uid,
		role_sex = DataMgr.roleData.gender - 1,
		role_image = DataMgr.roleData.headIconUrl,
		role_curlevel = "",
		role_nextlevel = "",
		role_curexpnum = DataMgr.roleData.roleExp,
		role_needexpnum = "",
		role_sign = DataMgr.roleData.signature,
		role_startup_type = BP_StartUpType,
		role_qqvip = DataMgr.roleData.qq_vip,
	};
	RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalBasicInfo);
	RoleInfoSystem.PersonalBasicInfo["role_curlevelnum"] = tonumber(DataMgr.roleData.level);
	RoleInfoSystem.PersonalBasicInfo["role_nextlevelnum"] = tonumber(DataMgr.roleData.level) + 1;
    
    --国际化：处理个人段位信息（国服的单区数据改为多区）
	RoleInfoSystem.RoleSegmentInfo();
    --[[
	RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber(DataMgr.roleData.segment.solo);
	RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(DataMgr.roleData.segment.double);
	RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(DataMgr.roleData.segment.team);
    RoleInfoSystem.PersonalBasicInfo["role_avatar_frame"] = tonumber(DataMgr.roleData.cur_avatar_box_id);
	if DataMgr.roleData.segment.solo > DataMgr.roleData.segment.double then
		if DataMgr.roleData.segment.solo > DataMgr.roleData.segment.team then
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.solo);
		else
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.team);
		end
	elseif DataMgr.roleData.segment.double > DataMgr.roleData.segment.team then
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.double);
	else
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.team);
	end
	]]
	local curlevel = tonumber(DataMgr.roleData.level);
	-- local curlevel = tonumber(100);
	--判断是否满级
	if curlevel >= 100 then
		local curmilitarylevel = Client.GetTableData("MilitaryRankLevel", 100);
		RoleInfoSystem.PersonalBasicInfo["role_curlevel"] = tostring(curmilitarylevel.MilitaryRankName);
		RoleInfoSystem.PersonalBasicInfo["role_curexpnum"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_needexpnum"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_nextlevel"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_curlevelnum"] = 100;
		RoleInfoSystem.PersonalBasicInfo["role_avatar_frame"] = tonumber(DataMgr.roleData.cur_avatar_box_id);
		RoleInfoSystem.IsMaxLevel = true;
	elseif curlevel > 0 then
		local curmilitarylevel = Client.GetTableData("MilitaryRankLevel", curlevel);
		local nextmilitarylevel = Client.GetTableData("MilitaryRankLevel", curlevel + 1);
		RoleInfoSystem.PersonalBasicInfo["role_curlevel"] = tostring(curmilitarylevel.MilitaryRankName);
		RoleInfoSystem.PersonalBasicInfo["role_needexpnum"] = tostring(curmilitarylevel.Exp);
		RoleInfoSystem.PersonalBasicInfo["role_nextlevel"] = tostring(nextmilitarylevel.MilitaryRankName);
		RoleInfoSystem.PersonalBasicInfo["role_avatar_frame"] = tonumber(DataMgr.roleData.cur_avatar_box_id);
		RoleInfoSystem.IsMaxLevel = false;
	end
	
	log_tree("PersonalBasicInfo:",RoleInfoSystem.PersonalBasicInfo);
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

-- 设置段位信息( 带段位信息的)
function RoleInfoSystem.RoleSegmentInfo()
    -- 设置查看当前zone的段位信息
    DataMgr.SetCurSegment(BP_Back_ShowRoleInfoOfZoneId);
    RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber(DataMgr.roleData.segment.solo);
	RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(DataMgr.roleData.segment.double);
	RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(DataMgr.roleData.segment.team);
	if DataMgr.roleData.segment.solo > DataMgr.roleData.segment.double then
		if DataMgr.roleData.segment.solo > DataMgr.roleData.segment.team then
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.solo);
		else
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.team);
		end
	elseif DataMgr.roleData.segment.double > DataMgr.roleData.segment.team then
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.double);
	else
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(DataMgr.roleData.segment.team);
	end
end


--响应玩家基本信息
function RoleInfoSystem.get_role_basic_info_rsp(listType, res, role_basic_info_list, systemType)
	if systemType ~= BP_PROFILE_MSG_TYPE_ROLEINFO then
		return;
	end
	--log_tree("RoleInfoSystem.get_role_basic_info_rsp role_basic_info_list , ", role_basic_info_list);
	if res ~= "ok" then
		print("Error: "..res);
		RoleInfoSystem.ProcessBasicInfoError();
		return;
	end
	
	-- log_tree("get_role_basic_info_rsp ret=", {listType, res, role_basic_info_list, systemType});

	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	log("11111111111111111111111111111111111111: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalBasicInfo = {};
	local ProfileInfo = {};
	for k,v in pairs(role_basic_info_list) do
		--v.uid = k;
		table.insert(ProfileInfo, v);
	end
	
	log_tree("ProfileInfo", ProfileInfo);
	
	RoleInfoSystem.PersonalBasicInfo =
	{
		role_name = ProfileInfo[1].nickName,
		role_id = ProfileInfo[1].uid,
		role_sex = ProfileInfo[1].sex - 1,
		role_image = ProfileInfo[1].picUrl,
		role_curlevel = "",
		role_nextlevel = "",
		role_curexpnum = ProfileInfo[1].exp,
		role_needexpnum = "",
		role_sign = ProfileInfo[1].signature,
		role_startup_type = GetSafeNumber(ProfileInfo[1].startup_type),
		role_qqvip = GetSafeNumber(ProfileInfo[1].qq_vip),
	};
	RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalBasicInfo);
	RoleInfoSystem.PersonalBasicInfo["role_curlevelnum"] = tonumber(ProfileInfo[1].level);
	RoleInfoSystem.PersonalBasicInfo["role_nextlevelnum"] = tonumber(ProfileInfo[1].level) + 1;
	--[[
    RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber(ProfileInfo[1].segment_info[1]);
	RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(ProfileInfo[1].segment_info[2]);
	RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(ProfileInfo[1].segment_info[3]);
    RoleInfoSystem.PersonalBasicInfo["role_avatar_frame"] = tonumber(ProfileInfo[1].cur_avatar_box_id);
	if ProfileInfo[1].segment_info[1] > ProfileInfo[1].segment_info[2] then
		if ProfileInfo[1].segment_info[1] > ProfileInfo[1].segment_info[3] then
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(ProfileInfo[1].segment_info[1]);
		else
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(ProfileInfo[1].segment_info[3]);
		end
	elseif ProfileInfo[1].segment_info[2] > ProfileInfo[1].segment_info[3] then
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(ProfileInfo[1].segment_info[2]);
	else
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = tonumber(ProfileInfo[1].segment_info[3]);
	end
	]]
    --RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber(ProfileInfo[1].segment_info[1]);
	--RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(ProfileInfo[1].segment_info[2]);
	--RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(ProfileInfo[1].segment_info[3]);
    ----------------------------------------------------------INTL modify ------------------------------------------------------------------
    RoleInfoSystem.PersonalBasicInfo.all_segment_info = ProfileInfo[1].segment_info;
    --[[
    for k, v in pairs(RoleInfoSystem.PersonalBasicInfo.all_segment_info) do
        RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber (RoleInfoSystem.PersonalBasicInfo.all_segment_info [k][1]);
        RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(RoleInfoSystem.PersonalBasicInfo.all_segment_info [k][2]);
        RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(RoleInfoSystem.PersonalBasicInfo.all_segment_info [k][3]);
        break;
    end]]
    --waynedong debug 212
   -- RoleInfoSystem.PersonalBasicInfo["role_segment_solo"],  RoleInfoSystem.PersonalBasicInfo["role_segment_double"],  RoleInfoSystem.PersonalBasicInfo["role_segment_team"] =  FuncUtil.GetMaxSegement( RoleInfoSystem.PersonalBasicInfo.all_segment_info );
    
    if RoleInfoSystem.PersonalBasicInfo.all_segment_info[BP_Back_ShowRoleInfoOfZoneId]~=nil then
        RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] = tonumber (RoleInfoSystem.PersonalBasicInfo.all_segment_info [BP_Back_ShowRoleInfoOfZoneId][1]);
        RoleInfoSystem.PersonalBasicInfo["role_segment_double"] = tonumber(RoleInfoSystem.PersonalBasicInfo.all_segment_info [BP_Back_ShowRoleInfoOfZoneId][2]);
        RoleInfoSystem.PersonalBasicInfo["role_segment_team"] = tonumber(RoleInfoSystem.PersonalBasicInfo.all_segment_info [BP_Back_ShowRoleInfoOfZoneId][3]);
    end
    if RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] > RoleInfoSystem.PersonalBasicInfo["role_segment_double"]  then
		if RoleInfoSystem.PersonalBasicInfo["role_segment_solo"]  > RoleInfoSystem.PersonalBasicInfo["role_segment_team"] then
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = (RoleInfoSystem.PersonalBasicInfo["role_segment_solo"] );
		else
			RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = (RoleInfoSystem.PersonalBasicInfo["role_segment_team"]);
		end
	elseif RoleInfoSystem.PersonalBasicInfo["role_segment_double"]  > RoleInfoSystem.PersonalBasicInfo["role_segment_team"] then
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = (RoleInfoSystem.PersonalBasicInfo["role_segment_double"] );
	else
		RoleInfoSystem.PersonalBasicInfo["role_segment_max"] = (RoleInfoSystem.PersonalBasicInfo["role_segment_team"]);
	end
    -----------------------------------------------------------INTL modify -----------------------------------------------------------------
	
	local curlevel = tonumber(ProfileInfo[1].level);
	-- local curlevel = tonumber(100);
	--判断是否满级
	if curlevel >= 100 then
		local curmilitarylevel = Client.GetTableData("MilitaryRankLevel", 100);
		RoleInfoSystem.PersonalBasicInfo["role_curlevel"] = tostring(curmilitarylevel.MilitaryRankName);
		RoleInfoSystem.PersonalBasicInfo["role_curexpnum"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_needexpnum"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_nextlevel"] = "";
		RoleInfoSystem.PersonalBasicInfo["role_curlevelnum"] = 100;
		RoleInfoSystem.IsMaxLevel = true;
	elseif curlevel > 0 then
		local curmilitarylevel = Client.GetTableData("MilitaryRankLevel", curlevel);
		local nextmilitarylevel = Client.GetTableData("MilitaryRankLevel", curlevel + 1);
		RoleInfoSystem.PersonalBasicInfo["role_curlevel"] = tostring(curmilitarylevel.MilitaryRankName);
		RoleInfoSystem.PersonalBasicInfo["role_needexpnum"] = tostring(curmilitarylevel.Exp);
		RoleInfoSystem.PersonalBasicInfo["role_nextlevel"] = tostring(nextmilitarylevel.MilitaryRankName);
		RoleInfoSystem.IsMaxLevel = false;
	end
    RoleInfoSystem.PersonalBasicInfo["role_avatar_frame"] = tonumber(ProfileInfo[1].cur_avatar_box_id);
	
	
	log_tree("PersonalBasicInfo:",RoleInfoSystem.PersonalBasicInfo);
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
	--测试
	-- EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
end

--响应玩家排行榜信息
function RoleInfoSystem.get_role_rank_info_rsp(client_data, res, zone_id, role_rank_info)
	log("get_role_rank_info_rsp");
	
	if client_data ~= "roleinfo" then
		return;
	end
	
	if res ~= 0 then
		print("Error: "..res);
		RoleInfoSystem.ProcessRankInfoError();
		return;
	end
	
    --log_tree("get_role_rank_info_rsp ret=",{client_data, res, role_rank_info});
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	log("22222222222222222222222222222222222222: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalTotalRankInfo = {};
	
	if role_rank_info.rank_no == nil then
		local data = Client.GetTableData("LocalizeRes", 102127);
		local text = tostring(data.TextValue);
		RoleInfoSystem.PersonalTotalRankInfo =
		{
			role_totalrank = text,
		}
	else
		RoleInfoSystem.PersonalTotalRankInfo =
		{
			role_totalrank = role_rank_info.rank_no,
		}
	end
	RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalRankInfo);
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

--响应玩家战绩信息
function RoleInfoSystem.get_role_combat_info_rsp(res, callback, optype, role_combat_info, zoneid, seasonid)
	log("get_role_combat_info_rsp ");
	
	if optype ~= BP_COMBAT_MSG_TYPE_ROLEINFO then
		return;
	end
	
	RoleInfoSystem.seasonid = seasonid;
	
	if res ~= 0 then
		print("Error: "..res);
		RoleInfoSystem.ProcessCombatInfoError();
		return;
	end
	
	-- log_tree("get_role_combat_info_rsp ret=",{res, callback, optype, role_combat_info, zoneid});
	
	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	log("33333333333333333333333333333333333333: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalTotalScoreInfo = {};
	RoleInfoSystem.CombatTotalInfoList = {};
	RoleInfoSystem.CombatSurviveInfoList = {};
	RoleInfoSystem.CombatScoreInfoList = {};
	RoleInfoSystem.CombatBattleInfoList = {};
	
	RoleInfoSystem.PersonalTotalScoreInfo =
	{
		role_totalscore = role_combat_info.warall.rank_rating;
	}
	RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalScoreInfo);
	
	local role_info;
	for i = 1, 4 do
		if i == 1 then
			role_info = role_combat_info.warsolo;
		elseif i == 2 then
			role_info = role_combat_info.warduo;
		elseif i == 3 then
			role_info = role_combat_info.warsquad;
		elseif i == 4 then
			role_info = role_combat_info.warall;
		end
		
		if role_info ~= nil then
			if i == 4 then
				RoleInfoSystem.CombatTotalInfoList[i] =
				{
					role_allmatchnum = role_info.game_num,
					role_winnum = role_info.win_num,
					role_toptennum = role_info.top10_count,
					role_killnum = role_info.kill_num,
					role_kd = role_info.kd,
					role_critrate = role_info.head_shot_ratio,
				};
			else
				RoleInfoSystem.CombatTotalInfoList[i] =
				{
					role_allmatchnum = role_info.game_num,
					role_winnum = role_info.win_num,
					role_toptennum = role_info.top10_count,
					role_killnum = role_info.kill_num,
					role_kd = role_info.kd,
					role_critrate = role_info.head_shot_ratio,
				};
				RoleInfoSystem.CombatSurviveInfoList[i] =
				{
					role_maxsurvivetime = role_info.max_live_time,
					role_avesurvivetime = role_info.avg_live_time,
					role_maxdistance = role_info.max_move,
					role_avedistance = role_info.avg_move,
					role_aveheal = role_info.avg_cure,
					role_aidcount = role_info.rescue_teammates,
				};
				RoleInfoSystem.CombatScoreInfoList[i] =
				{
					role_score = role_info.rank_rating,
					role_killscore = role_info.kill_rating,
					role_rankscore = role_info.win_rating,
				};
				RoleInfoSystem.CombatBattleInfoList[i] =
				{
					role_hitrate = role_info.avg_shot_hit_ratio,
					role_critcount = role_info.head_shot_num,
					role_maxkill = role_info.max_kill,
					role_maxdamage = role_info.max_hurt,
					role_avedamage = role_info.avg_hurt,
				};
			end
		end
	end
	RoleInfoSystem.FormatCombatInfo();
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatTotalInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatSurviveInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatScoreInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatBattleInfoList);
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

--响应修改签名
function RoleInfoSystem.modify_role_signature_respond(res)
	if res == "ok" then
		--修改签名
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_MODIFY_SIGNINFO);
	elseif res == "signature-too-long" then
		log("Error: "..res);
		--恢复签名
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_TOOLONG_SIGNINFO);
	elseif res == "have-dirty-in-signature" then
		log("Error: "..res);
		--非法字符
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_DIRTY_SIGNINFO);
	end
end

--设置table的所有v为string类型
function RoleInfoSystem.SetElementToString(tab)
	for k, v in pairs(tab or {}) do
		if type(v) ~= "table" then
			tab[k] = tostring(v);
		else
			RoleInfoSystem.SetElementToString(v);
		end
	end
end

--格式化战绩信息
function RoleInfoSystem.FormatCombatInfo()
	log("RoleInfoSystem FormatCombatInfo");
	for i = 1, 4 do
		local totalinfo = RoleInfoSystem.CombatTotalInfoList[i];
		totalinfo["role_kd"] = string.format("%.2f", totalinfo["role_kd"]);
		totalinfo["role_critrate"] = string.format("%.1f", totalinfo["role_critrate"]*100);
	end
	for i = 1, 3 do
		local surviveinfo = RoleInfoSystem.CombatSurviveInfoList[i];
		surviveinfo["role_maxsurvivetime"] = string.format("%.1f", surviveinfo["role_maxsurvivetime"]/60);
		surviveinfo["role_avesurvivetime"] = string.format("%.1f", surviveinfo["role_avesurvivetime"]/60);
		surviveinfo["role_maxdistance"] = string.format("%.2f", surviveinfo["role_maxdistance"]/1000);
		surviveinfo["role_avedistance"] = string.format("%.2f", surviveinfo["role_avedistance"]/1000);
		surviveinfo["role_aveheal"] = string.format("%.1f", surviveinfo["role_aveheal"]);
		
		local battleinfo = RoleInfoSystem.CombatBattleInfoList[i];
		battleinfo["role_hitrate"] = string.format("%.1f", battleinfo["role_hitrate"]*100);
		battleinfo["role_avedamage"] = string.format("%.1f", battleinfo["role_avedamage"]);
		battleinfo["role_maxdamage"] = string.format("%.0f", battleinfo["role_maxdamage"]);
	end
end

--处理基本信息收包错误
function RoleInfoSystem.ProcessBasicInfoError()
	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	-- log("44444444444444444444444444444444444444: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalBasicInfo = {};
	RoleInfoSystem.PersonalBasicInfo =
	{
		role_name = "nil",
		role_id = "nil",
		role_sex = "0",
		role_image = "",
		role_curlevel = "",
		role_nextlevel = "",
		role_curexpnum = "0",
		role_needexpnum = "1",
		role_sign = "",
		role_curlevelnum = 0,
		role_nextlevelnum = 0,
		role_segment_solo = 0,
		role_segment_double = 0,
		role_segment_team = 0,
		role_segment_max = 0,
		role_startup_type = 0,
		role_qqvip = 0,
        role_avatar_frame = 0,
        all_segment_info ={},
	};
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

--处理排行榜信息收包错误
function RoleInfoSystem.ProcessRankInfoError()
	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	-- log("55555555555555555555555555555555555555: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalTotalRankInfo =
	{
		role_totalrank = "nil",
	}
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

--处理战绩收包错误
function RoleInfoSystem.ProcessCombatInfoError()
	if RoleInfoSystem.Update_Ctrl >= 3 then
		RoleInfoSystem.Update_Ctrl = 0;
	end
	RoleInfoSystem.Update_Ctrl = RoleInfoSystem.Update_Ctrl + 1;
	-- log("66666666666666666666666666666666666666: "..RoleInfoSystem.Update_Ctrl);
	
	RoleInfoSystem.PersonalTotalScoreInfo = {};
	RoleInfoSystem.CombatTotalInfoList = {};
	RoleInfoSystem.CombatSurviveInfoList = {};
	RoleInfoSystem.CombatScoreInfoList = {};
	RoleInfoSystem.CombatBattleInfoList = {};
	
	RoleInfoSystem.PersonalTotalScoreInfo =
	{
		role_totalscore = 0;
	}
	RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalScoreInfo);
	
	for i = 1, 4 do
		if i == 4 then
			RoleInfoSystem.CombatTotalInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatTotalInfo);
		else
			RoleInfoSystem.CombatTotalInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatTotalInfo);
			RoleInfoSystem.CombatSurviveInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatSurviveInfo);
			RoleInfoSystem.CombatScoreInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatScoreInfo);
			RoleInfoSystem.CombatBattleInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatBattleInfo);
		end
	end
	RoleInfoSystem.FormatCombatInfo();
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatTotalInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatSurviveInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatScoreInfoList);
	RoleInfoSystem.SetElementToString(RoleInfoSystem.CombatBattleInfoList);
	
	if RoleInfoSystem.Update_Ctrl == 3 then
		--更新玩家信息
		EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO);
	end
end

--战绩清零
function RoleInfoSystem.SetElementToZero(tab)
	for k, v in pairs(tab) do
		if type(v) ~= "table" then
			tab[k] = "0";
		else
			RoleInfoSystem.SetElementToZero(v);
		end
	end
end

s2c["get_role_battle_info_rsp"] = function(...)
    RoleInfoSystem.get_role_combat_info_rsp(...);
    --SeasonSystem.get_role_battle_info_rsp(...);
end
s2c["modify_role_signature_respond"] = RoleInfoSystem.modify_role_signature_respond;
--测试
-- s2c["get_one_user_rank_rsp"] = RoleInfoSystem.get_role_rank_info_rsp;










