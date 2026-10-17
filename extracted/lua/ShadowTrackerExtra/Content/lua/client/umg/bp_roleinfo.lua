--个人信息UI
RoleInfoUI = RoleInfoUI or
{
	RoleID = "";
}
local CombatUrl = "https://cgidev.datamore.qq.com/datamore/gzcjzone/index"

BP_SelfID = "";	--自己的UID
BP_Sign = "";	--签名内容
BP_RoleName = "";	--玩家姓名
BP_RoleID = "";		--玩家ID
BP_CombatUrl = CombatUrl;
BP_IsMaxLevel = false;	--是否满级
BP_SignHintText = "";
BP_ShowAddFriend = true;
BP_CombatModelType = 0;
BP_RolePlatform = 0;
BP_ShareNum = 0;
BP_IsShareAwardGold = false; --每日首分享是否金币奖励


 
-- 单个区的个人段位信息
BP_STRUCT_PersonalSegmentInfo = 
{
	role_segment_solo = 0,		--单人赛季段位
	role_segment_double = 0,	--双人赛季段位
	role_segment_team = 0,		--组队赛季段位
    role_segment_max = 0,		--最高赛季段位
}
-- 分区
BP_ARRAY_ZoneList = {0};

--个人信息基本信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_PersonalBasicInfo =
{
	role_name = "",				--姓名
	role_id = "",				--UID
	role_sex = "",				--性别
	role_image = "",			--头像
	role_curlevel = "",			--当前等级军衔
	role_nextlevel = "",		--下一等级军衔
	role_curexpnum = "",		--当前经验
	role_needexpnum = "",		--升级所需经验
	role_sign = "",				--签名
	role_curlevelnum = 0,		--当前等级
	role_nextlevelnum = 0,		--下一等级
	role_segment_solo = 0,		--单人赛季段位
	role_segment_double = 0,	--双人赛季段位
	role_segment_team = 0,		--组队赛季段位
	role_segment_max = 0,		--最高赛季段位
	role_startup_type = 0,		--启动类型
	role_qqvip = 0,				--qq会员等级
    role_avatar_frame = 0,		--头像框
};

--个人信息综合排行榜数据
BP_STRUCT_PersonalTotalRankInfo =
{
	role_totalrank = "",		--综合积分排名
};

--个人信息综合积分数据
BP_STRUCT_PersonalTotalScoreInfo =
{
	role_totalscore = "";		--综合积分
};

--个人战绩总数据（单人1，双人2，组队3, 总体4）
BP_STRUCT_CombatTotalInfo =
{
	role_allmatchnum = "",		--总场数
	role_winnum = "",
	role_toptennum = "",
	role_killnum = "",
	role_kd = "",
	role_critrate = "",
};

--个人战绩生存数据（单人1，双人2，组队3）
BP_STRUCT_CombatSurviveInfo =
{
	role_maxsurvivetime = "",	--最长存活时间
	role_avesurvivetime = "",	--场均存活时间
	role_maxdistance = "",		--最长移动距离
	role_avedistance = "",		--场均移动距离
	role_aveheal = "",			--场均治疗
	role_aidcount = "",			--单人没有
};

--个人战绩积分数据（单人1，双人2，组队3）
BP_STRUCT_CombatScoreInfo =
{
	role_score = "",			--总积分
	role_killscore = "",		--击败积分
	role_rankscore = "",		--生存积分
};

--个人战绩战斗数据（单人1，双人2，组队3）
BP_STRUCT_CombatBattleInfo =
{
	role_hitrate = "",			--命中率
	role_critcount = "",		--暴击数
	role_maxkill = "",			--单局最高击败
	role_maxdamage = "",		--单局最高伤害
	role_avedamage = "",		--场均伤害
};

--个人战绩总数据(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
BP_ARRAY_CombatTotalInfoList = 
{
	BP_STRUCT_CombatTotalInfo=_G.BP_STRUCT_CombatTotalInfo, --定义结构体数组，这种写法要作为规范规定下来
};

--个人战绩生存数据
BP_ARRAY_CombatSurviveInfoList = 
{
	BP_STRUCT_CombatSurviveInfo=_G.BP_STRUCT_CombatSurviveInfo,
};

--个人战绩积分数据
BP_ARRAY_CombatScoreInfoList = 
{
	BP_STRUCT_CombatScoreInfo=_G.BP_STRUCT_CombatScoreInfo,
};

--个人战绩战斗数据
BP_ARRAY_CombatBattleInfoList = 
{
	BP_STRUCT_CombatBattleInfo=_G.BP_STRUCT_CombatBattleInfo,
};

--注册Widget
function bp_roleinfo_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_roleinfo,
		{{Path="/Game/UMG/UI_Logic/RoleInfo/RoleInfo_BP.RoleInfo_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ROLEINFO_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
    
    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_roleinfo,
            "RoleInfo_BP_C",
            {
                "Canvas_QQStartup",
                "Canvas_QQVip",
                "Overlay_TipsFather",
                "HorizontalBox_9",
                "Overlay_RealNameFather",
            }
        );
    end
end

local function RoleInfoEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_ROLEINFO then
		return;
	end
	
	--更新个人基本信息
	if eventID == EVENTID_ROLEINFO_UPDATE_ROLEINFO then
		log("EVENTID_ROLEINFO_UPDATE_ROLEINFO");
		RoleInfoUI.UnifyAllData();
		RoleInfoUI.UpdateRoleInfo();
	--修改签名
	elseif eventID == EVENTID_ROLEINFO_MODIFY_SIGNINFO then
		log("EVENTID_ROLEINFO_MODIFY_SIGNINFO");
		RoleInfoUI.ModifyRoleInfoSign();
	--签名过长
	elseif eventID == EVENTID_ROLEINFO_TOOLONG_SIGNINFO then
		log("EVENTID_ROLEINFO_TOOLONG_SIGNINFO");
		RoleInfoUI.TooLongRoleInfoSign();
	--非法字符
	elseif eventID == EVENTID_ROLEINFO_DIRTY_SIGNINFO then
		log("EVENTID_ROLEINFO_DIRTY_SIGNINFO");
		RoleInfoUI.DirtyRoleInfoSign();
	end
end

function RoleInfoUI.Init(bShowAddFriend)
	log("RoleInfoUI_Init");
	BP_SelfID = DataMgr.roleData.uid;
	BP_Sign = "";
	BP_RoleName = "";
	BP_RoleID = "";
	BP_CombatUrl = CombatUrl;
	BP_IsMaxLevel = false;
	BP_SignHintText = "";
	if bShowAddFriend ~= nil then
		BP_ShowAddFriend = bShowAddFriend;
	end
	RoleInfoUI.RoleID = "";
	BP_CombatModelType = 0;
	BP_RolePlatform = 0;
	BP_ShareNum = 0;
	BP_IsShareAwardGold = false;
	
	EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, RoleInfoEventHandler);
	EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_MODIFY_SIGNINFO, RoleInfoEventHandler);
	EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_TOOLONG_SIGNINFO, RoleInfoEventHandler);
	EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_DIRTY_SIGNINFO, RoleInfoEventHandler);
	-- LuaClassObj.HandleUIMessage(bp_roleinfo, "UIShow");
	--测试
	-- RoleInfoUI.UnifyAllData();
	-- RoleInfoUI.UpdateRoleInfo();
end

function RoleInfoUI.Release()
	log("RoleInfoUI Release");
	BP_SelfID = "";
	BP_Sign = "";
	BP_RoleName = "";
	BP_RoleID = "";
	BP_CombatUrl = CombatUrl;
	BP_IsMaxLevel = false;
	BP_SignHintText = "";
	BP_ShowAddFriend = true;
	RoleInfoUI.RoleID = "";
	BP_CombatModelType = 0;
	BP_RolePlatform = 0;
	BP_ShareNum = 0;
	BP_IsShareAwardGold = false;
	
	EventSystem:unregistEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, RoleInfoEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_MODIFY_SIGNINFO, RoleInfoEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_TOOLONG_SIGNINFO, RoleInfoEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_DIRTY_SIGNINFO, RoleInfoEventHandler);
end

function RoleInfoUI.Hide()
	log("RoleInfoUI Hide");
	LuaClassObj.HandleUIMessage(bp_roleinfo, "UIHide");
end

function RoleInfoUI.SetEmptyData()
	log("RoleInfoUI_SetEmptyData");
	
	for k,v in pairs(RoleInfoSystem.PersonalBasicInfo) do
		BP_STRUCT_PersonalBasicInfo[k] = v;
	end
	
	for k,v in pairs(RoleInfoSystem.PersonalTotalRankInfo) do
		BP_STRUCT_PersonalTotalRankInfo[k] = v;
	end
	
	for k,v in pairs(RoleInfoSystem.PersonalTotalScoreInfo) do
		BP_STRUCT_PersonalTotalScoreInfo[k] = v;
	end
	
	BP_ARRAY_CombatTotalInfoList = {};
	BP_ARRAY_CombatSurviveInfoList = {};
	BP_ARRAY_CombatScoreInfoList = {};
	BP_ARRAY_CombatBattleInfoList = {};
	
	for i = 1, 4 do
		BP_ARRAY_CombatTotalInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatTotalInfoList[i]);
	end
	
	for i = 1, 3 do
		BP_ARRAY_CombatSurviveInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatSurviveInfoList[i]);
		BP_ARRAY_CombatScoreInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatScoreInfoList[i]);
		BP_ARRAY_CombatBattleInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatBattleInfoList[i]);
	end
	
	if LuaClassObj ~= nil then
		LuaClassObj.HandleUIMessage(bp_roleinfo, "SetEmptyData");
	end
end

function RoleInfoUI.UnifyAllData()
	log("RoleInfoUI_UnifyAllData");
	
	for k,v in pairs(RoleInfoSystem.PersonalBasicInfo) do
		BP_STRUCT_PersonalBasicInfo[k] = v;
		if k == "role_id" then
			RoleInfoUI.RoleID = v;
		end
	end
	
	for k,v in pairs(RoleInfoSystem.PersonalTotalRankInfo) do
		BP_STRUCT_PersonalTotalRankInfo[k] = v;
	end
	
	for k,v in pairs(RoleInfoSystem.PersonalTotalScoreInfo) do
		BP_STRUCT_PersonalTotalScoreInfo[k] = v;
	end
	
	BP_ARRAY_CombatTotalInfoList = {};
	BP_ARRAY_CombatSurviveInfoList = {};
	BP_ARRAY_CombatScoreInfoList = {};
	BP_ARRAY_CombatBattleInfoList = {};
	
	for i = 1, 4 do
		BP_ARRAY_CombatTotalInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatTotalInfoList[i]);
	end
	
	for i = 1, 3 do
		BP_ARRAY_CombatSurviveInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatSurviveInfoList[i]);
		BP_ARRAY_CombatScoreInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatScoreInfoList[i]);
		BP_ARRAY_CombatBattleInfoList[i] = FuncUtil:CopyTable(RoleInfoSystem.CombatBattleInfoList[i]);
	end
    
    local enc_uid = Client.EncryptUID(RoleInfoUI.RoleID, "6bdZX[5]s&3LadBV")
    --local zoneid = RoleInfoSystem.ZoneID
    local zoneid = 0
    --areaid 1微信，2手Q   platid 0 IOS，1安卓
    local areaid = 2
    if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
        areaid = 1
	end
	local platid = 0
	if string.lower(Client.GetDevicePlatformName()) == "android" then 
		platid = 1
	end
    local seasonid = 0
    if RoleInfoSystem.seasonid ~= nil then
        seasonid = RoleInfoSystem.seasonid
    end
	BP_CombatUrl = BP_CombatUrl.."?uid="..enc_uid.."&zoneid="..zoneid.."&platid="..platid.."&areaid="..areaid.."&season="..seasonid.."&dmsourceid=fet01"
	
	BP_IsMaxLevel = RoleInfoSystem.IsMaxLevel;
	
	local data = Client.GetTableData("LocalizeRes", 105003);
	BP_SignHintText = tostring(data.TextValue);
	
	if RoleInfoSystem.IsFriend == true then
		BP_ShowAddFriend = false;
	end
	
	BP_RolePlatform = BP_Platform;
	
	BP_ShareNum = RoleInfoUI.GetShareNum();--ShareMgr.GetShareNum();
	BP_IsShareAwardGold = ShareAwardMgr.IsAllAwardHasGet();
end

function RoleInfoUI.UpdateRoleInfo()
	LuaClassObj.HandleDynamicCreation(bp_roleinfo);
	if LuaClassObj ~= nil then
		log("UpdateRoleInfo");
		LuaClassObj.HandleUIMessage(bp_roleinfo, "UIShow");
		LuaClassObj.HandleUIMessage(bp_roleinfo, "UpdateRoleInfo");
		LuaClassObj.HandleUIMessage(bp_roleinfo, "UpdatePlatformRight");
	end
end

function RoleInfoUI.ModifyRoleInfoSign()
	log("RoleInfoUI_ModifyRoleInfoSign");
	BP_STRUCT_PersonalBasicInfo["role_sign"] = BP_Sign;
	LuaClassObj.HandleUIMessage(bp_roleinfo, "SetSignInfo");
end

function RoleInfoUI.TooLongRoleInfoSign()
	log("RoleInfoUI_TooLongRoleInfoSign");
	BP_Sign = "";
	LuaClassObj.HandleUIMessage(bp_roleinfo, "SetSignInfo");
	DataMgr.ShowMessageBoxByID(105002);
end

function RoleInfoUI.DirtyRoleInfoSign()
	log("RoleInfoUI_DirtyRoleInfoSign");
	BP_Sign = "";
	LuaClassObj.HandleUIMessage(bp_roleinfo, "SetSignInfo");
	local title_data = Client.GetTableData("LocalizeRes", 105004);
	local title = tostring(title_data.TextValue);
	local msg_data = Client.GetTableData("LocalizeRes", 105005);
	local msg = tostring(msg_data.TextValue);
	CommonMessageBoxUI:ShowPanel(1, title, msg, nil, nil);
end

function RoleInfoUI.GetShareData()
	return RoleInfoSystem.CombatTotalInfoList[BP_CombatModelType];
end

function RoleInfoUI.UpdateUI()
	BP_ShareNum = RoleInfoUI.GetShareNum();--ShareMgr.GetShareNum();
	BP_IsShareAwardGold = ShareAwardMgr.IsAllAwardHasGet();
	LuaClassObj.HandleUIMessage(bp_roleinfo, "SetShareBtnState");
end

function RoleInfoUI.GetShareNum()
	if ShareAwardMgr.IsTodayShareDone() then
		return 1;
	else
		return 0;
	end
end

function RoleInfoUI.UpdateAvatarFrame()
	log("RoleInfoUI.UpdateAvatarFrame");
    RoleInfoSystem.PersonalBasicInfo.role_avatar_frame = tonumber(DataMgr.roleData.cur_avatar_box_id);
    BP_STRUCT_PersonalBasicInfo.role_avatar_frame = tonumber(DataMgr.roleData.cur_avatar_box_id);
	LuaClassObj.HandleUIMessage(bp_roleinfo, "UpdateAvatar");
end

--(以Event开头的函数名就能暴露给蓝图调用)

function EventRoleInfoSendSign()
	log("EventRoleInfoSendSign");
	RoleInfoSystem.send_modify_roleinfo_sign();
end

function EventCopyName()
	log("EventCopyName");
	Client.ClipBoardCopy(BP_RoleName);
	BP_RoleName = "";
	DataMgr.ShowNoticeByID(105001);
end

function EventCopyID()
	log("EventCopyID");
	Client.ClipBoardCopy(BP_RoleID);
	BP_RoleID = "";
	DataMgr.ShowNoticeByID(105001);
end

function EventAddFriend()
	log("EventAddFriend");
	FriendSystem.AddFriend(RoleInfoUI.RoleID,BP_ENUM_ADD_FRIEND_FROM_ROLEINFO);
end

function EventRoleInfoRelease()
	log("EventRoleInfoRelease");
	RoleInfoUI.Release();
	RoleInfoSystem.Release();
end

function EventSetCombatModelType()
	log("EventSetCombatModelType:"..BP_CombatModelType);
end

function EventShareCombatBtnClicked()
	log("EventShareCombatBtnClicked");
	SharePersonUI.ShowUI(BP_CombatModelType);
end

function EventRankDetailBtnClicked()
	log("EventRankDetailBtnClicked");
	RankDetailSystem.Enter();
	RankDetailUI.Init();
end

function EventRoleInfoAvatarClicked()
	--log_tree("EventRoleInfoAvatarClicked=", {BP_SelfID, BP_STRUCT_PersonalBasicInfo.role_id});
    if BP_SelfID == BP_STRUCT_PersonalBasicInfo.role_id then
        RoleInfoAvatarFrameSystem.Enter();
        RoleInfoAvatarFrameUI.Init();
    end
end



function EventGetZoneList()
	log("EvenGetZoneList");
    BP_ARRAY_ZoneList = DataMgr.AllZoneList;
end

BP_Back_ShowRoleInfoOfZoneId = 0
function EventRoleInfo_Push()
    log("BP_Back_ShowRoleInfoOfZoneId = "..BP_Back_ShowRoleInfoOfZoneId)
    RoleInfoSystem.RequestRoleInfo();
    --刷新UI
end








