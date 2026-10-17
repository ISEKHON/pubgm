
BattleResultUI = BattleResultUI or {}

--注册Widget
function bp_battleresult_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_battleresult,
		{
			{Path="/Game/BluePrints/ControlInput/ResultsshareUI/Results_BP.Results_BP_C", Container="Default", ZOrder=BP_ENUM_UI_RANK_ZORDER},
			{Path="/Game/BluePrints/ControlInput/ResultsshareUI/ResultsRanking_BP.ResultsRanking_BP_C", Container="Default", ZOrder=BP_ENUM_UI_RANK_ZORDER},
			--{Path="/Game/BluePrints/ControlInput/ResultsshareUI/Shareinterface_UIBP.Shareinterface_UIBP_C", Container="Default", ZOrder=0},
			{Path="/Game/BluePrints/ControlInput/ResultsshareUI/WatchGame_UIBP.WatchGame_UIBP_C", Container="Bottom", ZOrder=BP_ENUM_UI_RANK_ZORDER},
		},
		{"Fighting"},
		false,
		true
	);
    
    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_battleresult,
        "ResultsRanking_BP_C",
		{
			"Overlay_ShareBtn",
            "FlauntBox",
            "Overlay_ShareTips",
		}
	);
    end
end

--[[
	视频录制上传数据结构
--]]
BP_STRUCT_RecordingUpload = 
{
	platform = "",--平台:"QQ"/"WX"
	openUid = "",--平台UID
	roleUid = "",--角色UID
	battleUid = "",--当局战斗UID
	killNum = 0,--击杀熟
	HeadShotNum = 0,--爆头数
	MaxKillDistane = 0,--最远击杀距离
};

BP_STRUCT_BTRating = 
{
    rank_rating=0,  --变化后总积分
    kill_rating=0,  --变化后击杀积分
    win_rating=0,   --变化后胜利积分
    change_rank_rating=0,  --当局总积分变化值
    change_kill_rating=0,  --当局击杀积分变化值
    change_win_rating=0,   --当局胜利积分变化值
};

BP_STRUCT_MemBTResultData = 
{
    Name = "",
	Kill = 0,
    State = "",
    travelDistance = 0,   -- 总距离
    marchDistance=0,      -- 行走距离
	driveDistance=0,      -- 驾驶距离
    DamageAmount = 0,
   	surviveTime=0,
   	AssistNum=0,
	HeadShotNum=0,
	rescueTimes=0,
    HealAmount = 0,
    title_id = -1,         -- 称号id
    UID = "",  --  玩家ID
	ShouldShowAddFriendBtn = 0, -- 0 已经是好友,不需要显示  1 正常显示  2 已经添加了,不能再点击状态

	-- 分数维度统计
	SurviveScore = 0;
	BattleScore = 0;
	SupportScore = 0;
	TravelScore = 0;
	SupplyScore = 0;
	FinalScore_f = 0;
	IsMVP = false;
};

BPRecordAddFriendIndex = 0; -- BP 会调用加好友的协议 这个变量记录想加哪个为好友.

BP_STRUCT_BattleResultData = 
{
	Reason = "",
	RemainingPlayerCount=0,
	TotalPlayerCount=100,
	RemainingTeamCount=0,
	TotalTeamCount=25,
	IsSolo=true,
	ShootWeaponShotNum=0,
	ShootWeaponShotAndHitPlayerNum=0,
	HealTimes=0,
	destroyVehicleNum=0,
	HeadShotRatio=0.2,
	add_exp=0,
	add_gold=0,
	battle_id=0,
	max_game_num=1,
	person_rank=1,
	team_rank=1,
	final_level=0,
	is_team_result=false,
	is_last_survive=false,
	is_version_match=false,
    BP_ARRAY_TeammateList = 
	{
		tmp_UseExist_BP_STRUCT_MemBTResultData = {},
	},
	BP_STRUCT_BTRating = _G.BP_STRUCT_BTRating
};


BP_myname = "yoman";
BP_mykill=3;
BP_mystate="";
BP_IsTodayShareDone = false;
BP_IsShareAwardGold = false;

BP_EnterSpectateMode = false;

BP_MyFinalLevel = 5;

--登陆平台（微信，手Q）
BP_LoginChannel = 1;
--服务器时间秒数，供蓝图用
BP_ServerTimeSecNow = 0;

--举报界面打开与否
BP_IsReportComplaintShow = false;

--发送加好友请求
function EventAddFriendRequest_Push()
	log("BattleResultUI start add friend  " .. (BPRecordAddFriendIndex + 1));		

	if BP_STRUCT_BattleResultData~=nil and BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList ~=nil and
		BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1] ~=nil 
		and BPRecordAddFriendIndex > -1 then

		log_tree("BattleResultUI v is ", BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1]);

		log("BattleResultUI send friend invite to "..BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1].UID)
		FriendSystem.AddFriend("" .. BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1].UID,BP_ENUM_ADD_FRIEND_FROM_BATTLE_RESULT) -- tostring
		BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1].ShouldShowAddFriendBtn = 2; -- clicked
	end

	if BP_STRUCT_BattleResultData == nil then
		log("BattleResultUI BP_STRUCT_BattleResultData is nill")
	elseif BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList == nil then
		log("BattleResultUI BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList is nill")
	elseif BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1] then
		log("battleresultui BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[BPRecordAddFriendIndex + 1] == nil")
	elseif BPRecordAddFriendIndex <= -1 then
		log("BattleResultUI index < 0 "..BPRecordAddFriendIndex)
	end

end

function BattleResultUI.UpdateShareBtnState()
	BP_IsTodayShareDone = ShareAwardMgr.IsTodayShareDone();
	BP_IsShareAwardGold = ShareAwardMgr.IsAllAwardHasGet();
	LuaClassObj.HandleUIMessage(bp_battleresult, "SetShareBtnState");
end

--显示结算界面的内容
function BattleResultUI.OnBattleResult(uid, result)
	log("g_game_id is "..g_game_id);
	log("result.battle_id is "..result.battle_id);
	log("BattleResultUI param uid is  "..uid);
	if g_game_id ~= result.battle_id then
		return;
	end

	--视频录取上传数据
	BP_STRUCT_RecordingUpload.platform = _G.BP_Platform == BP_ENUM_PLAYFORM_QQ and "QQ" or "WX";
	BP_STRUCT_RecordingUpload.openUid = tostring(DataMgr.roleData.openID);
	BP_STRUCT_RecordingUpload.roleUid = tostring(DataMgr.roleData.uid);
	BP_STRUCT_RecordingUpload.battleUid = tostring(BattleResult.battleGID);
	log_tree("BP_STRUCT_RecordingUpload ",BP_STRUCT_RecordingUpload)

	BP_myname = DataMgr.roleData.nickName;
	--DataMgr.roleData.level = level;
	BP_STRUCT_BattleResultData = result;
	BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList = {};
	BP_STRUCT_BattleResultData.BP_STRUCT_BTRating = result.rating;
	BP_STRUCT_BattleResultData.IsSolo = result.max_game_num <= 1;
	--BP_MyFinalLevel = result.final_level;	-- 最终评价(SSS)
	local MyDmg = 0;
	local MyHeadShotRatio = 0;
	local MyTravelDis = 0;
	local MyHeal = 0;

	BP_mykill = 0;

	local MaxScore = 0;
	local MVP;
	for k,v in pairs(result.TeammateList) do
		if v.Name == BP_myname then
			BP_mykill = v.Kill;
			BP_mystate = v.State;
		end

		if v ~= nil then
			log("BattleResultUI Name "..v.Name);
			log("BattleResultUI Kill "..v.Kill);
			log("BattleResultUI Damage "..v.DamageAmount);
			v.UID = "" .. v.UID -- 转为字符串
		end
		v.ShouldShowAddFriendBtn = 0;
		log("BattleResultUI is solo ".. tostring(BP_STRUCT_BattleResultData.IsSolo));
		if BP_STRUCT_BattleResultData.IsSolo ~= true  -- not sole
			and FriendSystem.IsMyFriend("" .. v.UID) ~= true -- not friend
			and tonumber(DataMgr.roleData.uid) ~= tonumber(v.UID) then -- not self
			v.ShouldShowAddFriendBtn = 1;
			log("BattleResultUI name " .. v.Name .. " can be invited " .. v.ShouldShowAddFriendBtn .. " with id " .. v.UID);
		end

		if FriendSystem.IsMyFriend("" .. v.UID) == true then
			log("BattleResultUI FriendSystem.IsMyFriend( .. v.UID) == true ")
		end
		
		v.FinalScore_f = string.format("%.1f", v.FinalScore);

		local FinalLevel = CalcFinalRank(v.FinalScore);
		if v.Name == BP_myname then
			BP_MyFinalLevel = FinalLevel;
			log("BP_MyFinalLevel "..BP_MyFinalLevel);
		end
		
		table.insert(BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList, v);

		--录屏参数
		if v.UID == DataMgr.roleData.uid then
			BP_STRUCT_RecordingUpload.killNum = v.Kill;
			BP_STRUCT_RecordingUpload.HeadShotNum = v.HeadShotNum;
		end

		log_tree("BattleResultUI v is ", v);
	end

	log_tree("BattleResultUI.OnBattleResult", BP_STRUCT_BattleResultData);
	Client.OnBattleResult(GameFrontendHUD, BP_STRUCT_BattleResultData);

	-- 举报界面记录需要举报的队友
	ComplaintUI:CacheTeamMateList(result.TeammateList)

	BP_ServerTimeSecNow = FuncUtil.GetServerTimeInSec();

	if BP_STRUCT_BattleResultData.IsSolo == false then
		if BP_STRUCT_BattleResultData.is_last_survive then
			log("BattleResultUI last survive!!!!!")
			-- 最后一个死亡则直接显示队伍结算界面
			BP_EnterSpectateMode = false;
		elseif BP_STRUCT_BattleResultData.is_team_result then
			-- 非小队最后一个死亡 并且此时是队伍结算
			-- 可能需要重新刷新处理
			BP_EnterSpectateMode = false;
		else
			-- 非小队最后死亡 并且此时是个人结算         
			BP_EnterSpectateMode = true;
		end
		LuaClassObj.HandleUIMessage(bp_battleresult, "ShowBattleRankingUI");
	else
		BP_STRUCT_BattleResultData.is_last_survive = true;
		BP_EnterSpectateMode = false;
		LuaClassObj.HandleUIMessage(bp_battleresult, "ShowBattleRankingUI");
	end
	
	BattleResultUI.UpdateShareBtnState();
	
	--在战斗外收到了结算消息
	if string.lower(LuaClassObj.GetGameStatus(bp_battleresult)) ~= "fighting" 
	--可观战不忽略断线错误
	or BP_EnterSpectateMode
	then
		BattleResult.IgnoreDSError = false;
	else
        BattleResult.IgnoreDSError = true;
        NetUtil.StopCheckDSActive();
    end
	
    log("IgnoreDSError = " .. tostring(BattleResult.IgnoreDSError));
	
	--上报延迟数据
	local zone_id = Client.GetCurrentZoneID();
	local ping_data = Client.GetPingReportData(GameFrontendHUD);
	NetUtil.SendPkg("report_zone_ping", zone_id, ping_data);
end

function BattleResultUI.ShowBattleResultUI()
	LuaClassObj.HandleUIMessage(bp_battleresult, "ShowBattleRankingUI")
	BattleResultUI.UpdateShareBtnState();
end

function BattleResultUI.HideBattleResultUI()
	LuaClassObj.HandleUIMessage(bp_battleresult, "HideRankingUI")
end

function BattleResultUI.ShowLoadingUI()
	log("RecordingReplay ShowLoadingUI");
	LoadingUI:Init();
end

function BattleResultUI.HideLoadingUI()
	log("RecordingReplay HideLoadingUI");
	LoadingUI.RefreshLoadPercent(1);
end

function BattleResultUI.SetIsReportComplaintShow(IsShow)
	BP_IsReportComplaintShow = IsShow
end

function bp_battleresult_OnModeSwitched(gamestatus)
	log("bp_battleresult_OnModeSwitched:" .. gamestatus)
    BP_LoginChannel = Client.GetLoginChannel(NetInterface);
    
    if string.lower(gamestatus) == "fighting" then
        BattleResult.IgnoreDSError = false;
        --LuaClassObj.HandleUIMessage(bp_battleresult, "ShowSpectatingUI");
        ------------------------------
        if false then
		BP_STRUCT_BattleResultData = 
		{
			Reason = "win",
			RemainingPlayerCount=15,
			TotalPlayerCount=40,
			RemainingTeamCount=5,
			TotalTeamCount=25,
			person_rank=31,
			team_rank=21,
			add_exp=110,
			add_gold=450,
			IsSolo=true,
			is_last_survive=false,
			is_team_result=false,
			is_version_match=false,
    		BP_ARRAY_TeammateList = 
			{
				{    
		   			Name = "yoman",
		   			Kill = 3,
					State = "",
					travelDistance = 4200,
   					DamageAmount = 500,
    				HealAmount = 60,
    				surviveTime=300,
    				AssistNum=2,
					HeadShotNum=1,
					rescueTimes=1,
					HeadShotRatio=0.34,
    				ShouldShowAddFriendBtn = 1,
    				SurviveScore = 22.41,
    				BattleScore = 100,
					SupportScore = 28,
					TravelScore = 78.18,
					FinalScore_f = 95.122,
					IsMVP = true,
					title_id = 1
				},
				{    
		   			Name = "haha222",
		   			Kill = 1,
					State = "",
					travelDistance = 121,
   					DamageAmount = 18.44,
    				HealAmount = 3,
    				surviveTime=1900,
    				HeadShotRatio=0.4,
    				AssistNum=1,
					HeadShotNum=1,
					rescueTimes=1,
    				ShouldShowAddFriendBtn = 2,
    				SurviveScore = 20,
    				BattleScore = 0,
					SupportScore = 0,
					TravelScore = 0,
					FinalScore_f = 40.133,
					IsMVP = false,
					title_id = 1
				}
	   		},
	   		BP_STRUCT_BTRating =
	   		{
	   			rank_rating=1100,  --变化后总积分
    			kill_rating=1200,  --变化后击杀积分
    			win_rating=1300,   --变化后胜利积分
			    change_rank_rating=-100,  --当局总积分变化值
			    change_kill_rating=-300,  --当局击杀积分变化值
			    change_win_rating=-300,   --当局胜利积分变化值
	   		}
	   	}

	   	if BP_STRUCT_BattleResultData.is_team_result then
	   		log("show team result!!!!!");
	   	end

	   	if Retry then
	   		BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[1].Kill = 100;
	   		Retry = false;
	   	end

	   	for k, v in pairs(BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList) do
	   		local FinalLevel = CalcFinalRank(v.FinalScore);
	   		if v.Name == BP_myname then
				BP_MyFinalLevel = FinalLevel;
			end
			v.FinalScore_f = string.format("%.1f", v.FinalScore_f);
			log("v.FinalScore_f "..v.FinalScore_f);
	   	end

	   	log(BP_STRUCT_BattleResultData.BP_ARRAY_TeammateList[1].FinalScore)

		if BP_STRUCT_BattleResultData.IsSolo == false then
			if BP_STRUCT_BattleResultData.is_last_survive then
				log("BattleResultUI last survive!!!!!")
				-- 最后一个死亡则直接显示队伍结算界面
				BP_EnterSpectateMode = false;
			elseif BP_STRUCT_BattleResultData.is_team_result then
				-- 非小队最后一个死亡 并且此时是队伍结算
				-- 可能需要重新刷新处理
				BP_EnterSpectateMode = false;
			else
				-- 非小队最后死亡 并且此时是个人结算
				log("BP_EnterSpectateMode!!!!!")
				BP_EnterSpectateMode = true;
			end
			LuaClassObj.HandleUIMessage(bp_battleresult, "ShowBattleRankingUI");
		else
			log("Solo Mode!!!!!")
			BP_STRUCT_BattleResultData.is_last_survive = true;
			BP_EnterSpectateMode = false;
			LuaClassObj.HandleUIMessage(bp_battleresult, "ShowBattleRankingUI");
		end
		BattleResultUI.UpdateShareBtnState();
	end
    ------------------------------
    end
end

function EventBattleResult_BackToLobby()
	log("EventBattleResult_BackToLobby");
    BattleResult.IgnoreDSError = true;
    if CommonMessageBoxUI ~= nil then
    	CommonMessageBoxUI:HidePanel();
    end
	Client.ReturnToLobby(GameFrontendHUD);
end

--结算倒计时开关打开
function BattleResultUI.EnableTickSwitch()
	--分享界面关闭的时候刷新一下分享tips
	BattleResultUI.UpdateShareBtnState();
	LuaClassObj.HandleUIMessage(bp_battleresult, "EnableResultsTick");
end

--显示观战界面
function BattleResultUI.EnterSpectating()
    LuaClassObj.HandleUIMessage(bp_battleresult, "ShowSpectatingUI");
end

function CalcDimensionScore(TValue, scaleparam1, scaleparam2)
	log("CalcDimensionScore "..TValue);

	local stepOne = 1 / (1 + math.exp(-0.8 * TValue)) - 0.5;
	log("stepOne "..stepOne)
	local stepTwo = stepOne * scaleparam1 + scaleparam2;
	log("stepTwo "..stepTwo)
	local stepThree = math.max(math.min(stepTwo, 1), 0);
	log("stepThree "..stepThree)
	return stepThree * 100;
end

function CalcPlayerScore(TeammateInfo)
	log("CalcPlayerScore");

	local SurviveT = TeammateInfo.surviveTime / 360 - 1;
	TeammateInfo.SurviveScore = CalcDimensionScore(SurviveT, 1.68, 0.28);
	log("BP_SurviveScore "..TeammateInfo.SurviveScore);

	local KillRef = 3;
	local DmgRef = 380;
	local HeadShotRef = 0.25;
	local KillRating = math.min(TeammateInfo.Kill / KillRef, 1) * 40;
	local DmgRating = math.min(TeammateInfo.DamageAmount / DmgRef, 1) * 40;
	local HeadShotRating = math.min(TeammateInfo.HeadShotRatio / HeadShotRef, 1) * 20;
	local BattleBaseScore = KillRating + DmgRating + HeadShotRating;
	local BattleT = BattleBaseScore / 20 - 1;
	log ("BattleT "..BattleT);
	TeammateInfo.BattleScore = CalcDimensionScore(BattleT, 1.68, 0.28);
	log("BP_BattleScore "..TeammateInfo.BattleScore);

	local SupportBase = 0;
	local HealRef = 300;
	local AssistRef = 0.8;
	local RescueRef = 0.3;
	if BP_STRUCT_BattleResultData.IsSolo then
		SupportBase = math.min(TeammateInfo.HealAmount / HealRef, 1) * 100;
	else
		local AssistScore = math.min(TeammateInfo.AssistNum / AssistRef, 1) * 30;
		local HealScore = math.min(TeammateInfo.HealAmount / HealRef, 1) * 60;
		local RescueScore = math.min(TeammateInfo.rescueTimes / RescueRef) * 10;
		SupportBase = AssistScore + HealScore + RescueScore;
		log("SupportBase "..SupportBase)
	end

	local SupportT = SupportBase / 20 - 1;
	TeammateInfo.SupportScore = CalcDimensionScore(SupportT, 1.68, 0.28);
	log("TeammateInfo.SupportScore "..TeammateInfo.SupportScore);

	local TravelRef = 1200;
	local TravelT = TeammateInfo.travelDistance / TravelRef - 2;
	TeammateInfo.TravelScore = CalcDimensionScore(TravelT, 1.31, 0.43); 
	log("TeammateInfo.TravelScore "..TeammateInfo.TravelScore);

	-- 物资分直接给了
	TeammateInfo.FinalScore = TeammateInfo.SurviveScore * 0.4 + TeammateInfo.BattleScore * 0.3 + TeammateInfo.SupportScore * 0.15 + TeammateInfo.TravelScore * 0.05 + 10;
	log("FinalScore "..TeammateInfo.FinalScore);

	local FinalLevel = CalcFinalRank(TeammateInfo.FinalScore);
	if TeammateInfo.Name == BP_myname then
		BP_MyFinalLevel = FinalLevel;
		log("BP_MyFinalLevel "..BP_MyFinalLevel);
	end

	TeammateInfo.IsMVP = false;
end

function CalcFinalRank(Score)
	if Score == nil then
		return 0;
	end

	local FinalRank = 0;
	if Score < 50 then
		FinalRank = 0;
	elseif Score < 60 then
		FinalRank = 1;
	elseif Score < 70 then
		FinalRank = 2;
	elseif Score < 75 then
		FinalRank = 3;
	elseif Score < 80 then
		FinalRank = 4;
	elseif Score < 85 then
		FinalRank = 5;
	elseif Score < 90 then
		FinalRank = 6;
	elseif Score < 95 then
		FinalRank = 7;
	elseif Score <= 100 then
		FinalRank = 8;
	end
	return FinalRank;
end

Retry = false;
function EventDelayCall()
	Retry = true;
	bp_battleresult_OnModeSwitched("fighting");
end

function EventClientExitGame()
    log("EventClientExitGame")
    BattleResult.IgnoreDSError=true;
    NetUtil.StopCheckDSActive();
    NetUtil.SendPkg("giveup_enter_game");
    NetUtil.SendPkg("exit_result");
end

function EventCloseBattleResult()
	log("EventCloseBattleResult");
	NetUtil.SendPkg("exit_result");
end

function EventShowGameJoyRecordFailNotice()
	local str = DataMgr.GetMsgByID(890006);
	ShowNotice(str);
end