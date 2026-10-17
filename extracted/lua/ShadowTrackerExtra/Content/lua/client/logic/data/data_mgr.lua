-- 通用数据

struct_RoleAttri =
{
	attr_type_exp = 1,			-- 经验
	attr_type_level = 2,		-- 等级
	attr_type_gold = 3,			-- 金币
	attr_type_diamond = 4,		-- 钻石
	attr_type_signature = 5,	-- 签名
	attr_type_segment = 6,		-- 段位
}

struct_SegmentType =
{
	segment_type_solo = "solo",
	segment_type_double = "duo",
	segment_type_team = "squad",
}


--------------------------------------------------------------------
-- 所有的数据赋值必须通过mgr的set方法赋值，保障数据变更入口唯一
--------------------------------------------------------------------
DataMgr = DataMgr or
{
	-------------------------------------- 以下是人物基本属性 --------------------------------------
	roleData = 
	{
		openID = 0,
		uid = "",
		level = 0,
		roleExp = 0,
		nickName = "",
		gender = 0,		-- 平台性别
		headIconUrl = "",
		signature = "",	-- 个人签名
		segment = {},	-- 段位  solo-单人  double-双人  team-组队
		qq_vip = 0, --qq会员 0 无会员 1 普通会员 2 超级会员
        cur_avatar_box_id = 0,  --头像框
        allzoneSegment = {}, -- 二维数组：allzoneSegment[zone_id][type]： 第一维是分区zoneId，第二维存放当前区的segment（solo-单人  double-双人  team-组队）
	},
		
	gold = 0,
	
	anchor = 0,		--主播(1为主播，其他为非主播)
	
	-------------------------------------- 以下是人物当前穿戴数据 --------------------------------------
	avatarData=
	{
		headid = 0,
        hairid = 0,
		gamegender = 0,		-- 游戏内角色性别
	},
	
	rolewear = {}, --insID数组

	defaultParachuteResID = 0, -- 默认降落伞配置ID
	defaultParachuteInsID = "",
	parachute = "", -- instID,降落伞
	-------------------------------------- 以下是大厅仓库数据 --------------------------------------
	arrayHallDepotItemInfo = 
	{		
		item = 
		{
			insID = "";
			resID = 0;
			count = 0;		
			isNew = false,
			
			itemType = 0;
			itemSubType = 0;
			validHours = 0;
			expireTS = 0;
			mainTabType = 0;
			itemQuality = 0;
		},
	},
	
	mapSourceBookInfo = {},	-- 图鉴数据，结构参考arrayHallDepotItemInfo
	
	-------------------------------------- 以下是登录领奖相关数据 --------------------------------------
	SignInInfo =
	{
		login_reward = {},				--登录领奖状态
		last_login_reward_remind = 0, 	--上次登录时间戳（用于首次登录领奖打脸）
	},
	
	
	-------------------------------------- 以下是好友数据 --------------------------------------
	-------------------------------------- 以下是任务数据 --------------------------------------
	taskData = {
		daily_update_time = 0,
		list = {}	
	},
	-------------------------------------- 以下是活跃数据 --------------------------------------
	activeness = {
		daily_update_time = 0,
		value = 0,
		list = {}
	},

	-------------------------------------- 以下是BAN数据 --------------------------------------
    ban = 
    {
    },
    	-------------------------------------- 以下是周签到数据 --------------------------------------
	WeekSignUpInfo =
	{
		Resign_times = 0,
		AwardState = {}
	},

	-------------------------------------- 以下是活动数据 --------------------------------------
	activity = {
		isInit = false,
		hashList = {},
		activityMap = {},
		activityListMap = {},
		activityIdMap = {}, -- [子活动]<->[父活动]
		data = {}
	},
	bulletin = {
		hashList = {},
		data = {}
	},
	
	--------------------------------------- 以下是分享领奖数据 -------------------------------------------
	ShareAwardInfo = {
		daily_share_time = 0,
		share_times  = 0,
		AwardState = {}
	},

		--------------------------------------- 活动集合页数据 -------------------------------------------
	activityGroupList = 
	{
	},
	--------------------------------------- 限时直购数据 -------------------------------------------
	shopLimit = 
	{
		hash = "",
		buyInfo = {},
		template = {}
	},
    
    -------------------------------------- 以下是选服数据--------------------------------------
    AllZoneList = {},
    
    --这里存放的是单人 双人 四人在所有区中最高段位的数据
    maxSegmentSolo=
    {
        zoneid = 0,
        SegmentLevel = 0,
    },
    maxSegmentDuo = 
    {
        zoneid = 0,
        SegmentLevel = 0,
    },
    maxSegmentSquad = 
    {
        zoneid = 0,
        SegmentLevel = 0,
    },

	IsEightDaySlpaed = false,
	IsGmOpen = false,
    CurUpdateZoneSegementZoneId = 0,
}

-- 重置数据，用于重登陆
function DataMgr.ResetData()
	log("IDataMgr.ResetData!!!!");
		-- 重置活动集合页数据
	DataMgr.ResetActGrpData()
	-- 重置任务
	DataMgr.ResetTaskData()
	-- 重置活跃
	DataMgr.ResetActivenessData()
	-- 重置活动
	DataMgr.ResetActivityData()
	-- 重置公告数据
	DataMgr.ResetBulletin()
	-- 重置限时直购数据
	DataMgr.ResetShopLimit()

end

-- 初始化角色数据
function DataMgr.InitRoleData(roleDataTb)
	log("InitRoleData openID:" .. roleDataTb.openID .. " uid:" .. roleDataTb.uid);
	log("InitRoleData nickName:" .. roleDataTb.nickName .. " level:" .. roleDataTb.level .. " roleExp:" .. roleDataTb.roleExp .. " gender:" .. roleDataTb.gender);
	log("InitRoleData gold:" .. roleDataTb.gold);
	log("InitRoleData signature:" .. roleDataTb.signature);
	log("InitRoleData headIconUrl:" .. roleDataTb.headIconUrl);
	log_tree("InitRoleData avatar:", roleDataTb.avatar);
	--log_tree("InitRoleData depot:", roleDataTb.depot);
	log_tree("InitRoleData rolewear:", roleDataTb.rolewear);
	log("InitRoleData parachute:" .. roleDataTb.parachute);
	log_tree("InitRoleData segment:", roleDataTb.segment);
	log_tree("InitRoleData login_reward:", roleDataTb.login_reward);
	log("InitRoleData last_login_reward_remind:" .. roleDataTb.last_login_reward_remind);
	log_tree("InitRoleData week_signup:", roleDataTb.week_signup);
	log_tree("InitRoleData share_award:", roleDataTb.share_award);
	if roleDataTb.wxsubscribe then
		log("InitRoleData wxsubscribe 微信订阅信息:" .. roleDataTb.wxsubscribe);
	end

	if roleDataTb.qqsubscribe then
		log("InitRoleData qqsubscribe qq订阅信息:" .. roleDataTb.qqsubscribe);
	end
	log("InitRoleData anchor:"..roleDataTb.anchor)
	
	log("InitRoleData qq_vip:" .. tostring(roleDataTb.qq_vip));

	log("InitRoleData xy_red_point:" .. tostring(roleDataTb.xy_red_point));
	
	DataMgr.ResetData();
	
	DataMgr.roleData.openID = roleDataTb.openID;
	DataMgr.roleData.uid = roleDataTb.uid;
	DataMgr.roleData.nickName = roleDataTb.nickName;
	DataMgr.roleData.level = roleDataTb.level;
	DataMgr.roleData.roleExp = roleDataTb.roleExp;
	DataMgr.roleData.gender = roleDataTb.avatar.gamegender --roleDataTb.gender;
	DataMgr.roleData.signature = roleDataTb.signature;
	DataMgr.roleData.headIconUrl = roleDataTb.headIconUrl;
    DataMgr.roleData.cur_avatar_box_id = roleDataTb.cur_avatar_box_id;
	DataMgr.roleData.qq_vip = GetSafeNumber(roleDataTb.qq_vip);
	DataMgr.roleData.xy_red_point = roleDataTb.xy_red_point;
	Client.SetPlayerBaseInfo(GameFrontendHUD, roleDataTb.openID, roleDataTb.uid, roleDataTb.nickName, roleDataTb.headIconUrl)
		
     ------------------------------------intl modify----------------------------------------
     DataMgr.roleData.allzoneSegment = roleDataTb.segment; 
     SegmentZoneCount = #DataMgr.roleData.allzoneSegment;
    if SegmentZoneCount> 0 then
        for k, v in pairs(DataMgr.roleData.allzoneSegment) do	
            DataMgr.SetCurSegment(k) --waynedong wait check  DataMgr.roleData.segment
            break;
        end
    end
    --[[
	DataMgr.roleData.segment = 
	{
		solo = roleDataTb.segment[1],
		double = roleDataTb.segment[2],
		team = roleDataTb.segment[3],
	};]]
     ------------------------------------intl modify----------------------------------------
     
	DataMgr.UpdateTaskChange(false, roleDataTb.task)
	DataMgr.UpdateActiveChange(false, roleDataTb.activeness)
	
	DataMgr.UpdateTaskChange(false, roleDataTb.task)
	DataMgr.UpdateActiveChange(false, roleDataTb.activeness)

	DataMgr.gold = roleDataTb.gold;
	
	DataMgr.wxsubscribe = roleDataTb.wxsubscribe
	DataMgr.qqsubscribe = roleDataTb.qqsubscribe
	
	DataMgr.anchor = roleDataTb.anchor;
	
	-- 初始化avatar
	DataMgr.avatarData.headid = roleDataTb.avatar.headid;
	DataMgr.avatarData.gamegender = roleDataTb.avatar.gamegender;
	DataMgr.avatarData.hairid = roleDataTb.avatar.hairid;
    
	-- 初始化时装
	DataMgr.rolewear = {};
	for k,v in pairs(roleDataTb.rolewear) do
		if v ~= 0 then
			table.insert(DataMgr.rolewear, tostring(v));
		end
	end 

	-- 初始化降落伞数据
	local sysCfg = Client.GetTableData("SystemConfig", "DefaultParachute");
	DataMgr.defaultParachuteResID = 0;
	if sysCfg ~= nil then
		DataMgr.defaultParachuteResID = tonumber(sysCfg.ConfigValue);
	end
	DataMgr.parachute = tostring(roleDataTb.parachute);
	
	-- 初始化仓库数据
	DataMgr.InitHallDepotData(roleDataTb.depot);	
	
	--初始化登录领奖数据
	DataMgr.SignInInfo.login_reward = roleDataTb.login_reward;
	DataMgr.SignInInfo.last_login_reward_remind = roleDataTb.last_login_reward_remind;

	-- 初始化周签到数据
	DataMgr.InitWeekSignUpList(roleDataTb.week_signup);
	
	-- 初始化分享领奖数据
	if roleDataTb.share_award ~= nil then
		DataMgr.ShareAwardInfo.daily_share_time = roleDataTb.share_award.daily_share_time;
		DataMgr.ShareAwardInfo.share_times = roleDataTb.share_award.share_times;
		for k, v in pairs(roleDataTb.share_award.list) do
			DataMgr.ShareAwardInfo.AwardState[k] = v.status;
		end
		
		ShareAwardMgr.OnShareAwardInfoUpdate();
	else
		sandbox.LogError("roleDataTb.share_award == nil");
	end
    
    DataMgr.IsEightDaySlpaed = false;

    DataMgrInit = true;   
end


-- 设置当前的segment
function DataMgr.SetCurSegment(zoneId)
    -- 有数据且数据不为nil
     log("DataMgr.SetCurSegment, zoneId = "..zoneId);
    if #DataMgr.roleData.allzoneSegment > 0  and DataMgr.roleData.allzoneSegment[zoneId]~=nil then
         DataMgr.roleData.segment = 
         {
            solo     = DataMgr.roleData.allzoneSegment[zoneId][1],
            double = DataMgr.roleData.allzoneSegment[zoneId][2],
            team   = DataMgr.roleData.allzoneSegment[zoneId][3],
         }
    end
    log_tree("DataMgr.roleData.segment:", DataMgr.roleData.segment);
end

-- 设置当前的segment
function DataMgr.GetSegmentByZoneId(zoneId)
     log("DataMgr.GetSegmentByZoneId, zoneId = "..zoneId);
    if #DataMgr.roleData.allzoneSegment > 0  and DataMgr.roleData.allzoneSegment[zoneId]~=nil then
         segment = 
         {
            solo     = DataMgr.roleData.allzoneSegment[zoneId][1],
            double = DataMgr.roleData.allzoneSegment[zoneId][2],
            team   = DataMgr.roleData.allzoneSegment[zoneId][3],
         }
          log_tree("DataMgr.GetSegmentByZoneId:", segment);
         return segment
    end
    return nil
end


function DataMgr.InitBanData(banData)
    DataMgr.ban = banData;
end

-- 更新自己的概要数据
function DataMgr.UpdateMyRoleProfileData(data)
	--[[
	local data = 
	{
		uid = uid,
		city = profile.city,
		level = profile.level,
		lastLoginTime = profile.lastLoginTime,
		segment_info = profile.segment_info,
		nickName = profile.nickName,
		platName = profile.platName,
		sex = profile.sex,
		signature = profile.signature,
		lastOnlineTime = profile.lastOnlineTime,
		vipLevel = profile.vipLevel,
		picUrl = profile.picUrl,
		exp = profile.exp,
		startup_type = GetSafeNumber(profile.startup_type),
		qq_vip = GetSafeNumber(profile.qq_vip),		
		cur_avatar_box_id = profile.cur_avatar_box_id,	
	};	
	]]--
	
	DataMgr.roleData.nickName = data.nickName;
	DataMgr.roleData.level = data.level;
	--DataMgr.roleData.gender = roleDataTb.gender;
	--DataMgr.roleData.signature = data.signature;
	DataMgr.roleData.headIconUrl = data.picUrl;
	log("[HHF]OnBatchGetProfileRsp, headIconUrl = " .. DataMgr.roleData.headIconUrl);
    DataMgr.roleData.cur_avatar_box_id = data.cur_avatar_box_id;
	DataMgr.roleData.qq_vip = GetSafeNumber(data.qq_vip);
	--DataMgr.roleData.xy_red_point = data.xy_red_point;		
    
    
    DataMgr.roleData.allzoneSegment = data.segment_info; 
    SegmentZoneCount = #DataMgr.roleData.allzoneSegment;
    if SegmentZoneCount> 0 then
        for k, v in pairs(DataMgr.roleData.allzoneSegment) do	
            DataMgr.SetCurSegment(k)
            break;
        end
    end
    --[[
	DataMgr.roleData.segment = 
	{
		solo = data.segment_info[1],
		double = data.segment_info[2],
		team = data.segment_info[3],
	};]]
end


-- 初始化背包数据
--请求列表返回 wardrobe_items
--    item.instid = newinstid;
--    item.res_id = resid;
--    item.use_flag = 0;
--    item.count = count;
function DataMgr.InitHallDepotData(arrayItemData)
    log("DataMgr.InitHallDepotData:");	
	--log_tree("arrayItemData", arrayItemData);
	
	DataMgr.arrayHallDepotItemInfo = {};	
	
	--log_tree("itemDatas", itemDatasCfg);
		
 --    local id = 1;
	for k,v in pairs(arrayItemData) do
		--log_tree("onItem:", v);
		local itemDataCfg = Client.GetTableData("Item", v.res_id);
		--log_tree("itemDataCfg", itemDataCfg);
		if itemDataCfg then
			local itemInfo = {
				insID = tostring(v.instid),
				resID = v.res_id,
				count = v.count,
				isNew = (v.isnew == 1),
				
				itemType = itemDataCfg.ItemType,
				itemSubType = itemDataCfg.ItemSubType,
				itemQuality = itemDataCfg.ItemQuality,
				validHours = v.valid_hours or 0,
				expireTS = v.expire_ts or 0,
				mainTabType = itemDataCfg.WardrobeMainTab,
			};

			table.insert(DataMgr.arrayHallDepotItemInfo, itemInfo);

			if itemInfo.resID == DataMgr.defaultParachuteResID then
				DataMgr.defaultParachuteInsID = itemInfo.insID;
			end
		end
	end

	local itemDatasCfg = BP_ARRAY_Item;
	local pageType = 0;
	DataMgr.mapSourceBookInfo = {};
	for k,v in pairs(itemDatasCfg) do
		-- 初始化图鉴
		if v.SourceBookEnable == 1 then
			pageType = v.WardrobeMainTab or 0;
			DataMgr.mapSourceBookInfo[pageType] = DataMgr.mapSourceBookInfo[pageType] or {};
			DataMgr.mapSourceBookInfo[pageType][v.ItemSubType] = DataMgr.mapSourceBookInfo[pageType][v.ItemSubType] or {};

			table.insert(DataMgr.mapSourceBookInfo[pageType][v.ItemSubType], {
				insID = "",
				resID = v.ItemID,
				count = 0,
				isNew = false,

				itemType = v.ItemType,
				itemSubType = v.ItemSubType,
				itemQuality = v.ItemQuality,
				mainTabType = v.WardrobeMainTab,
			});
		end
	end

	-- 排序图鉴
	for k,v in pairs(DataMgr.mapSourceBookInfo) do
		for sk,sv in pairs(v) do
			table.sort(sv, function (a, b)

				if a.itemSubType ~= b.itemSubType then
					return a.itemSubType < b.itemSubType;
				elseif a.itemQuality ~= b.itemQuality then
					return a.itemQuality > b.itemQuality;
				elseif a.resID ~= b.resID then
					return a.resID < b.resID;
				else
					return false;
				end
			end);
		end
	end

	-- log_tree("DataMgr.mapSourceBookInfo", DataMgr.mapSourceBookInfo);

	--log_tree("arrayHallDepotItemInfo", DataMgr.arrayHallDepotItemInfo);	
end

-- 更新角色穿戴信息
function DataMgr.UpdateRoleWearData(putOnId, putDownId)
	local isFind = false;	
	if putOnId ~= "" then
		for k,v in pairs(DataMgr.rolewear) do
			if v == putOnId then
				isFind = true;
				v = putOnId;
				break;
			end
		end
	end
	
	if isFind == false then
		table.insert(DataMgr.rolewear, putOnId);
	end
	
	if putDownId ~= "" then
		for k,v in pairs(DataMgr.rolewear) do
			if v == putDownId then
				table.remove(DataMgr.rolewear, k);
				break;
			end
		end
	end
	
	DataMgr.UpdateItemNewFlag(putOnId, putDownId);
end

function DataMgr.UpdateItemNewFlag(putOnId, putDownId)
		for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.insID == putOnId or v.insID == putDownId then
			v.isNew = false;
		end
	end	
end

 -- 更新降落伞
 function DataMgr.UpdateParachute(putOnId)
 	-- 先更新标志
 	DataMgr.UpdateItemNewFlag(putOnId, DataMgr.parachute);

 	-- 后更新穿戴信息
	DataMgr.parachute = putOnId;
 end


-- 变更物品new便签
function DataMgr.ChangeHallDepotItemNewStatus(insID) 
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.insID == insID then
			v.isNew = false;
			break;
		end
	end
end

-- 获取大厅仓库数据
function DataMgr.GetHallDepotItemDataByInsID(insID)	
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.insID == insID then
			return v;
		end
	end
	
	return nil;
end

-- 获取大厅仓库数据
function DataMgr.GetHallDepotItemDataByResID(resID)	
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.resID == resID then
			return v;
		end
	end
	
	return nil;
end

-- 获取最高段位信息
function DataMgr.GetMaxRankLevel()
--[[
    local maxRankLevel = DataMgr.roleData.segment.solo;
    if maxRankLevel < DataMgr.roleData.segment.double then 
        maxRankLevel = DataMgr.roleData.segment.double
    end
    
    if maxRankLevel < DataMgr.roleData.segment.team then
        maxRankLevel = DataMgr.roleData.segment.team
    end
    ]]
    DataMgr.fillMaxSegmentInfo();
    maxRankLevel =  math.max(DataMgr.maxSegmentSolo.SegmentLevel, DataMgr.maxSegmentDuo.SegmentLevel, DataMgr.maxSegmentSquad.SegmentLevel);
    return maxRankLevel
end

-- 更新仓库数据
function DataMgr.UpdateHallDepotItemData(itemData)
	local isFind = false;
	for k,v in pairs(DataMgr.arrayHallDepotItemInfo) do
		if v.instid == tostring(itemData.instid) then
			isFind = true;			
			
			v.count = itemData.count;	
			v.isNew = itemData.isNew;	
			v.count = itemData.count;			
			
			if v.count <= 0 then
				table.remove(DataMgr.arrayHallDepotItemInfo, k);
			end
			break;
		end
	end
	
	if isFind == false and itemData.count > 0 then
		local itemDataCfg = Client.GetTableData("Item", itemData.res_id);
		if itemDataCfg ~= nil then
			table.insert(DataMgr.arrayHallDepotItemInfo,
				{
					insID = tostring(itemData.instid),
					resID = itemData.res_id,
					count = itemData.count,
					isNew = (itemData.isnew == 1),

					validHours = itemData.valid_hours or 0,
					expireTS = itemData.expire_ts or 0,
					
					itemType = itemDataCfg.ItemType,
					itemSubType = itemDataCfg.ItemSubType,
					mainTabType = itemDataCfg.WardrobeMainTab,
					itemQuality = itemDataCfg.ItemQuality,
				});
		end				
	end
end


function DataMgr.OnHallDepotDataNotify(changelist)
	-- log_tree("OnHallDepotDataNotify:changelist", changelist);
	-- for k,v in pairs(changelist) do
	-- 	-- print(os.date("%Y-%m-%d %H:%M:%S", 1517848234))
	-- 	if v.expire_ts then
	-- 		log("OnHallDepotDataNotify timeout:"..os.date("%Y-%m-%d %H:%M:%S", v.expire_ts))
	-- 	end
	-- end

	-- log_tree("arrayHallDepotItemInfo before", DataMgr.arrayHallDepotItemInfo);
	local hasNewItem = false;
	local isFind = false;
	for k,v in pairs(changelist) do
		isFind = false;
		
		if v.isnew == 1 then
			hasNewItem = true;
		end
		
		for kk,vv in pairs(DataMgr.arrayHallDepotItemInfo) do
			if tostring(v.instid) == vv.insID then
				isFind = true;
				
				if v.count > 0 then
					vv.resID = v.res_id;
					vv.count = v.count;
					vv.isNew = (v.isnew == 1);
					vv.validHours = v.valid_hours or vv.validHours or 0;
					vv.expireTS	 = v.expire_ts or vv.expireTS or 0;
				else
					table.remove(DataMgr.arrayHallDepotItemInfo, kk);
				end
				
				break;
			end
		end
		
		if isFind == false and v.count > 0 then
			-- 新增一个物品
			local itemDataCfg = Client.GetTableData("Item", v.res_id);
			if itemDataCfg ~= nil then
				table.insert(DataMgr.arrayHallDepotItemInfo,
					{
						insID = tostring(v.instid),
						resID = v.res_id,
						count = v.count,
						isNew = (v.isnew == 1),
						
						itemType = itemDataCfg.ItemType,
						itemSubType = itemDataCfg.ItemSubType,
						validHours = v.valid_hours or 0,
						expireTS = v.expire_ts or 0,
						mainTabType = itemDataCfg.WardrobeMainTab,
						itemQuality = itemDataCfg.ItemQuality,
					});
			end		
		end
	end
	--log_tree("arrayHallDepotItemInfo after", DataMgr.arrayHallDepotItemInfo);	
	
	--log("DataMgr.OnHallDepotDataNotify "..tostring(hasNewItem));
	if hasNewItem then
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_ADD_NEW, changelist);
	end
	
	-- 广播事件
	EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_DATA_CHANGE);
end

--更新登录领奖相关数据
function DataMgr.UpdateSignInData(period, day)
	log("DataMgr UpdateSignInData");
	if DataMgr.SignInInfo.login_reward[period] == nil then
		DataMgr.SignInInfo.login_reward[period] = {};
	end
	if DataMgr.SignInInfo.login_reward[period][day] == nil then
		DataMgr.SignInInfo.login_reward[period][day] = true;
	end
end

-- 角色属性变化通知
function DataMgr.OnRoleAttrChangeNotify(attriType, attriValue, attriTab)
	log("OnRoleAttrChangeNotify attriType:"..attriType..", attriValue:"..attriValue);
	
	if attriType == struct_RoleAttri.attr_type_gold then
		DataMgr.gold = attriValue;
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, attriValue);
        
	elseif attriType == struct_RoleAttri.attr_type_exp then
		DataMgr.roleData.roleExp = attriValue;
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_EXP_CHANGE, attriValue);
        
	elseif attriType == struct_RoleAttri.attr_type_level then
        
        BP_LevelUp_OldLevel = DataMgr.roleData.level
		DataMgr.roleData.level = attriValue;
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, attriValue);
        
	elseif attriType == struct_RoleAttri.attr_type_signature then
		DataMgr.roleData.signature = attriValue;
        
	elseif attriType == struct_RoleAttri.attr_type_segment then
        
        BP_LevelUp_OldRankPoint = attriTab.old_rating
        BP_LevelUp_NewRankPoint = attriTab.new_rating
        
        UpdateZoneSegementById(attriTab.zone_id, attriTab.segment_type, attriTab.segment_value)
        --[[
		if attriTab.segment_type == struct_SegmentType.segment_type_solo then
            
            BP_LevelUp_OldRankLevel = DataMgr.roleData.segment.solo
            
			DataMgr.roleData.segment.solo = attriTab.segment_value;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE, attriValue);
		elseif attriTab.segment_type == struct_SegmentType.segment_type_double then
            
            BP_LevelUp_OldRankLevel = DataMgr.roleData.segment.double
            
			DataMgr.roleData.segment.double = attriTab.segment_value;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE, attriValue);
		elseif attriTab.segment_type == struct_SegmentType.segment_type_team then
            
            BP_LevelUp_OldRankLevel = DataMgr.roleData.segment.team

			DataMgr.roleData.segment.team = attriTab.segment_value;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE, attriValue);
		end
        ]]
	end
end

--更新已有的segement数据 --wayendong
function UpdateZoneSegementById(zoneId, attrType, segmentValue)
        log("UpdateZoneSegementById, zoneId = "..zoneId..", attrType = "..attrType..", segmentValue = "..segmentValue )
        DataMgr.UpdateZoneSegementZoneId = zoneId
        if attrType == struct_SegmentType.segment_type_solo then
            BP_LevelUp_OldRankLevel = DataMgr.roleData.allzoneSegment[zoneId][1];
            DataMgr.roleData.allzoneSegment[zoneId][1] = segmentValue;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE, attriValue);
		elseif attrType == struct_SegmentType.segment_type_double then
            BP_LevelUp_OldRankLevel = DataMgr.roleData.allzoneSegment[zoneId][2];
			DataMgr.roleData.allzoneSegment[zoneId][2] = segmentValue;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE, attriValue);
		elseif attrType == struct_SegmentType.segment_type_team then
            BP_LevelUp_OldRankLevel = DataMgr.roleData.allzoneSegment[zoneId][3];
			DataMgr.roleData.allzoneSegment[zoneId][3]  = segmentValue;
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE, attriValue);
		end
        log_tree("DataMgr.roleData.allzoneSegment[zoneId]", DataMgr.roleData.allzoneSegment[zoneId]);    
end

-- 弹出通用提示框
function DataMgr.ShowMessageBoxByID(msgID)
	local msgConfig = Client.GetTableData("LocalizeRes", msgID);
	
	if msgConfig then
		--CommonMessageBoxUI:ShowPanel(1, "提示", msgConfig.TextValue, nil, nil);
		CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes",101001).TextValue, msgConfig.TextValue, nil, nil);
	end
end

-- 弹出通用飘字
function DataMgr.ShowNoticeByID(msgID)
	local msgConfig = Client.GetTableData("LocalizeRes", msgID);
	
	if msgConfig then
		PopUpNoticeUI.ShowNewNotice(msgConfig.TextValue);
	end
end


-- 弹出通用飘字
function DataMgr.ShowNoticeQueueByID(msgID)
	local msgConfig = Client.GetTableData("LocalizeRes", msgID);
	
	if msgConfig then
		PopUpNoticeUI.ShowNewNoticeQueue(msgConfig.TextValue);
	end
end

-- 弹出通用快速飘字
function DataMgr.ShowNoticeFastQueueByID(msgID)
	local msgConfig = Client.GetTableData("LocalizeRes", msgID);
	
	if msgConfig then
		PopUpNoticeUI.ShowFastNoticeQueue(msgConfig.TextValue);
	end
end

-- 弹出通用飘字
function DataMgr.ShowNoticeByString(tipString)
	PopUpNoticeUI.ShowNewNotice(tipString);
end

--读取本地化表的文字
function DataMgr.GetMsgByID(msgID)
	local msgConfig = Client.GetTableData("LocalizeRes", msgID);	
	return (msgConfig == nil and "") or msgConfig.TextValue;
end

-- 战斗内文字表
function DataMgr.GetMsgByIDForBattleText(msgID)
	local msgConfig = Client.GetTableData("BattleText", msgID);	
	return (msgConfig == nil and "") or msgConfig.BattleTextValue;
end


-- 获取头像边框路径
function DataMgr.GetPlayerFramePath(rankIntegral)
	local path = "/Game/Arts/UI/Item_Icon/AvatarFrames/Style1/AvatarFrame_";
	local name = "Default";
	local rankIntegralCfg = Client.GetTableData("RankIntegralLevel", rankIntegral);
	if rankIntegralCfg then
		name = tostring(rankIntegralCfg.FrameID);
	end

	return path..name..".AvatarFrame_"..name;
end

-- 获取系统参数
function DataMgr.GetSystemConfig(configName)
	local msgConfig = Client.GetTableData("SystemConfig", configName);
	
	if msgConfig then
		return msgConfig.ConfigValue;
	end
	return nil;
end

-- 通过物品类型获取当前穿戴衣服对应的仓库物品
function DataMgr.GetWearItemByType(itemSubType)
	local itemData = nil;
	
	for k,v in pairs(DataMgr.rolewear) do
		for kk,vv in pairs(DataMgr.arrayHallDepotItemInfo) do
			if v == vv.insID and vv.itemSubType == itemSubType then
				itemData = vv;
				break;
			end
		end
		
		if itemData then
			break;
		end
	end
	
	return itemData;
end

-- 更新任务信息
function DataMgr.ResetTaskData()
	DataMgr.taskData = {
		daily_update_time = 0,
		list = {}	
	}
	DataMgr.taskData.daily_update_time = 3600
	local tbTaskData = Client.GetTable("Task")
	for _, tbTaskInfo in pairs(tbTaskData) do
		if tbTaskInfo.TaskType == TaskType["FIX"] then
			local flag = true
			if GlobalData:IsIOSCheck() then
				flag = flag and (tbTaskInfo.IOSCheck == 1)
			end
			if Client.GetLoginChannel(NetInterface) == BP_ENUM_PLAYFORM_TOURIST then
				flag = flag and (tbTaskInfo.TouristSwitch == 1)
			end
			if flag then
				DataMgr.taskData.list[tbTaskInfo.ID] = {status = 0, progress = 0}
			end
		end
	end
end

function DataMgr.ResetActivenessData()
	DataMgr.activeness = {
		daily_update_time = 0,
		value = 0,
		list = {}
	}
	DataMgr.activeness.daily_update_time = 3600
	DataMgr.activeness.value = 0
	local tbActiveData = Client.GetTable("TaskActive")
	for _, tbActiveInfo in pairs(tbActiveData) do
		DataMgr.activeness.list[tbActiveInfo.ID] = {status = 0}
	end
end

function DataMgr.UpdateActiveChange(isAll, active)
	if active == nil then
		sandbox.LogError("active can't be nil")
		return
	end
	if isAll then
		DataMgr.ResetActivenessData()
	end
	DataMgr.activeness.daily_update_time = active.daily_update_time
	-- 只需要更新进度，不需要更新状态
	DataMgr.activeness.value = active.value
	if active.list ~= nil then
		for activenessId, data in pairs(active.list) do
			DataMgr.activeness.list[activenessId] = data
		end
	end
	EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVENESS_CHANGE)
	TaskUI.RefreshAwradInfo()
end

function DataMgr.UpdateTaskChange(isAll, task)
	--log_tree("=========task change " .. (isAll and "true" or "false"), task)
	if task == nil then
		sandbox.LogError("task can't be nil")
		return
	end
	if isAll == true then
		DataMgr.ResetTaskData()
	end
	DataMgr.taskData.daily_update_time = task.daily_update_time
	for taskId,data in pairs(task.list) do
		local flag = true
		local tbTaskInfo = Client.GetTableData("Task", taskId)
		if GlobalData:IsExternalChannel() then
			flag = flag and (tbTaskInfo.TaskType ~= TaskType["PLATFORM"])
		end
		if GlobalData:IsIOSCheck() then
			flag = flag and (tbTaskInfo.IOSCheck == 1)
		end
		if Client.GetLoginChannel(NetInterface) == BP_ENUM_PLAYFORM_TOURIST then
			flag = flag and (tbTaskInfo.TouristSwitch == 1)
		end
		if flag then
			DataMgr.taskData.list[taskId] = data
		end
	end
	EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_TASK_CHANGE)
	--log_tree(DataMgr.taskData)
end

function DataMgr.TestProgress(taskId)
end

-- 周签到相关
function DataMgr.InitWeekSignUpList(week_signup)
	if week_signup ~= nil then
		for i = 1, #week_signup.list do
			local wsStatus = week_signup.list[i];
			if wsStatus ~= nil then
				DataMgr.WeekSignUpInfo.AwardState[i] = wsStatus.status;
			end
		end

		DataMgr.WeekSignUpInfo.Resign_times = week_signup.resign_times;
		WeekSignUpSystem.PostUpdateStatus();
	else
		sandbox.LogError("week_signup == nil");
	end
end

function DataMgr.UpdateWeekSignUpInfo(day, state)
	DataMgr.WeekSignUpInfo.AwardState[day] = state;
end


function DataMgr.ResetWeekSignUpInfo()
	DataMgr.WeekSignUpInfo.Resign_times = 0;
	DataMgr.WeekSignUpInfo.AwardState[1] = 1;
	local itemCount = #DataMgr.WeekSignUpInfo.AwardState;
	for i = 2, itemCount do
		DataMgr.WeekSignUpInfo.AwardState[i] = 0;
	end
end
function DataMgr.UpdateShareAwardState(id, state)
	DataMgr.ShareAwardInfo.AwardState[id] = state;
	
	ShareAwardMgr.OnShareAwardInfoUpdate();
end

function DataMgr.UpdateShareChange(share_times)
	if DataMgr.ShareAwardInfo.share_times < share_times then
		DataMgr.ShareAwardInfo.daily_share_time = FuncUtil.GetServerTimeInSec();
	end
	
	DataMgr.ShareAwardInfo.share_times = share_times;

	ShareAwardMgr.OnShareAwardInfoUpdate();
end

function DataMgr.SendSubscribeRet()
	-- if DataMgr.wxsubscribe and DataMgr.wxsubscribe == 1 then
	-- 	log("已经订阅")
	-- 	CommonMessageBoxUI:ShowPanel(1, "提示", "已经微信订阅", nil, nil)
	-- 	return
	-- end
	--微信订阅
	log("发送微信订阅")
	NetUtil.SendPkg("set_wxsubscribe_list_req")
end

function DataMgr.SendQQSubscribeRet()
	-- if DataMgr.qqsubscribe and DataMgr.qqsubscribe == 1 then
	-- 	log("已经qq订阅")
	-- 	CommonMessageBoxUI:ShowPanel(1, "提示", "已经qq订阅", nil, nil)
	-- 	return
	-- end
	--qq订阅
	log("发送qq订阅")
	NetUtil.SendPkg("set_qqsubscribe_list_req")
end

function DataMgr.OnSubscribeRet(result)
	if not result then
		CommonMessageBoxUI:ShowPanel(1, "提示", "微信订阅返回nil结果", nil, nil)
		return
	end
	--微信订阅回包
	log("微信订阅回包 result ="..result)

	if result == 0 then
		CommonMessageBoxUI:ShowPanel(1, "提示", "微信订阅成功", nil, nil)
		DataMgr.wxsubscribe = 1
	else
		CommonMessageBoxUI:ShowPanel(1, "提示", "微信订阅错误 错误码 = "..result, nil, nil)
	end
end

function DataMgr.OnQQSubscribeRet(result)
	if not result then
		CommonMessageBoxUI:ShowPanel(1, "提示", "QQ订阅返回nil结果", nil, nil)
		return
	end
	--qq订阅回包
	log("qq订阅回包 result ="..result)

	if result == 0 then
		CommonMessageBoxUI:ShowPanel(1, "提示", "QQ订阅成功", nil, nil)
		DataMgr.qqsubscribe = 1
	else
		CommonMessageBoxUI:ShowPanel(1, "提示", "QQ订阅错误 错误码 = "..result, nil, nil)
	end
end

--------------------------[[活动数据]]----------------------------------
-- 活动数据处理部分放在logic_activity.lua ActivitySystem中
function DataMgr.ResetActivityData()
	DataMgr.activity = {
		isInit = false,
		hashList = {},
		activityMap = {},
		activityListMap = {},
		activityIdMap = {},
		data = {}
	}

	log("send pkg get_activity_list_req")
	NetUtil.SendPkg("get_activity_list_req")
end

function DataMgr.ResetActGrpData()
	DataMgr.activityGroupList = 
	{
	}

	log("send pkg get_act_gather_list_req")
	ActivityGroupSystem.ReqGetActivityGroupList()
end

function DataMgr.GetActivityByType(activityType)
	for _, activity in ipairs(DataMgr.activity.data) do
		if tonumber(activity.Type) == activityType then
			return activity
		end
	end
	log("[Error : activity not found on type " .. (activityType or "nil") .. " ]")
	return nil
end

--------------------------[[公告系统]]----------------------------------
function DataMgr.ResetBulletin()
	DataMgr.bulletin = {hashList = {}, data = {}}
	NetUtil.SendPkg("bulletin_get_hashlist_req")
end

function DataMgr.InitBulletin(ret, bulletinList)
	if ret ~= NetErrorCode_NONE then
		ShowNotice(ret)
	else
		DataMgr.bulletin.data = bulletinList
	end
	--log_tree("========initBulletin ret: " .. ret, bulletinList)
	EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_BULLETIN_CHANGE)

end

function DataMgr.InitActivityGroupDataList(dataList)
	local newDataMap = {}
	for key, groupInfo in pairs(dataList) do
		newDataMap[groupInfo.position] = newDataMap[groupInfo.position] or {}
		table.insert(newDataMap[groupInfo.position], groupInfo)
		groupInfo.id = key
	end

	DataMgr.activityGroupList= ActivityGroupSystem.SortDataList(newDataMap)
end

function DataMgr.InitHashList(ret, hashlist)
	local changeList = {}
	for id, hashCode in pairs(hashlist) do
		if DataMgr.bulletin.hashList[id] ~= hashCode then
			table.insert(changeList, id)
		end 
	end

	if #changeList > 0 then
		NetUtil.SendPkg("bulletin_get_list_req", changeList)
	end

	-- del overdue bulletin
	local delList = {}
	for id, _ in pairs(DataMgr.bulletin.hashList) do
		if hashlist[id] == nil then
			table.insert(delList, id)
		end
	end
	for _,id in ipairs(delList) do
		DataMgr.bulletin.hashList[id] = nil
	end
	if #delList > 0 then
		EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_BULLETIN_CHANGE) 
	end

	--log_tree("=======bulletin hashlist", DataMgr.bulletin.hashList)
	DataMgr.bulletin.hashList = hashlist
	--log_tree("=======new hashlist", hashlist)
end
--------------------------[[限时直购]]----------------------------------
function DataMgr.ResetShopLimit()
	DataMgr.shopLimit = {hash = "", buyInfo = {}, template = {}}
	NetUtil.SendPkg("get_direct_buy_list_req")
	NetUtil.SendPkg("get_direct_buy_info_req", {})
end

function DataMgr.InitShopLimitTemplate(template, hash)
	--log_tree("================shop limit template ", template)
	DataMgr.shopLimit.hash = hash
	DataMgr.shopLimit.template = template
	EventSystem:postEvent(EVENTTYPE_SHOPLIMIT, EVENTID_SHOPLIMIT_TEMPLATECHANGE)
end

function DataMgr.InitShopLimitRoleData(buyInfo)
	--log_tree("================shop limit role data ", buyInfo)
	DataMgr.shopLimit.buyInfo = buyInfo
	EventSystem:postEvent(EVENTTYPE_SHOPLIMIT, EVENTID_SHOPLIMIT_BUYINFOCHANGE)
end

--判断有无安装对应的平台APP
function DataMgr.HasInstallPlatApp()
	local result = true;
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then

		if Client.IsInstallQQ(NetInterface) == false then 
			--没有安装QQ	
			result = false;
		end

	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		
		if Client.IsInstallWX(NetInterface) == false then 
			--没有安装微信
			result = false;
		end
	end

	return result;
end



---------------------------intl modify-----------------------------
-- 国际化：游戏内的选服列表zonelist同步
function DataMgr.SyncZoneList(tpingsvr_tab)
    DataMgr.AllZoneList ={};
    if(tpingsvr_tab ~= null) then
		for k,v in pairs(tpingsvr_tab) do
			zone_id = v.zone_id;
			table.insert(DataMgr.AllZoneList, zone_id);
		end
	end 
    --table.insert(DataMgr.AllZoneList, 2);
    log_tree("--- DataMgr.AllZoneList ",TeamUpSystem.ChooseZoneList);
end
 
function DataMgr.GetOneZoneList()
    for k,v in pairs(DataMgr.AllZoneList) do
        return k;
    end
    return 0;
end


function DataMgr.resetMaxSegmentInfo()
    DataMgr.maxSegmentSolo.zoneid = 0;
    DataMgr.maxSegmentSolo.SegmentLevel = 0;
    DataMgr.maxSegmentDuo.zoneid = 0;
    DataMgr.maxSegmentDuo.SegmentLevel = 0;
    DataMgr.maxSegmentSquad.zoneid = 0;
    DataMgr.maxSegmentSquad.SegmentLevel = 0;
end

function DataMgr.fillMaxSegmentInfo()
    DataMgr.resetMaxSegmentInfo();
    --log_tree("DataMgr.roleData.allzoneSegment",DataMgr.roleData.allzoneSegment );
    
    for k, v in pairs(DataMgr.roleData.allzoneSegment) do	
        if DataMgr.maxSegmentSolo.SegmentLevel < DataMgr.roleData.allzoneSegment[k][1] then
            DataMgr.maxSegmentSolo.zoneid = k
            DataMgr.maxSegmentSolo.SegmentLevel = DataMgr.roleData.allzoneSegment[k][1]
        end
         if DataMgr.maxSegmentDuo.SegmentLevel < DataMgr.roleData.allzoneSegment[k][2] then
            DataMgr.maxSegmentDuo.zoneid = k
            DataMgr.maxSegmentDuo.SegmentLevel = DataMgr.roleData.allzoneSegment[k][2]
        end
         if DataMgr.maxSegmentSquad.SegmentLevel < DataMgr.roleData.allzoneSegment[k][3] then
            DataMgr.maxSegmentSquad.zoneid = k
            DataMgr.maxSegmentSquad.SegmentLevel = DataMgr.roleData.allzoneSegment[k][3]
        end
    end
    --log_tree("DataMgr.maxSegmentSolo",DataMgr.maxSegmentSolo );
    --log_tree("DataMgr.maxSegmentDuo",DataMgr.maxSegmentDuo );
    --log_tree("DataMgr.maxSegmentSquad",DataMgr.maxSegmentSquad );
end

function DataMgr.GetMultiLineMsgByID(msgID)
	local str = DataMgr.GetMsgByID(msgID);
	return (str == nil and "") or string.gsub(str, "\\n", "\n");
end

--
---------------------------intl modify-----------------------------

--------------------------[[网络通知]]----------------------------------
s2c["notify_depot_item_change"] = DataMgr.OnHallDepotDataNotify;
s2c["notify_roleattr_change"] = DataMgr.OnRoleAttrChangeNotify;
-- 任务系统
s2c["activeness_notify_chg"] = DataMgr.UpdateActiveChange
s2c["task_notify_chg"] = DataMgr.UpdateTaskChange
-- 分享
s2c["share_notify_chg"] = DataMgr.UpdateShareChange
-- 活动系统

--微信订阅
s2c["set_wxsubscribe_list_res"] = DataMgr.OnSubscribeRet
s2c["set_qqsubscribe_list_res"] = DataMgr.OnQQSubscribeRet

-- 公告系统
s2c["bulletin_get_hashlist_res"] = DataMgr.InitHashList
s2c["bulletin_get_list_res"] = DataMgr.InitBulletin

--活动页
s2c["get_act_gather_list_res"] = DataMgr.InitActivityGroupDataList

--限时直购
s2c["get_direct_buy_list_res"] = DataMgr.InitShopLimitTemplate
s2c["get_direct_buy_info_res"] = DataMgr.InitShopLimitRoleData