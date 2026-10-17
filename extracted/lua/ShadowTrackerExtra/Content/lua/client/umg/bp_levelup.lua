LevelUpUI = LevelUpUI or 
{
}

-- 军衔数据
BP_LevelUp_OldLevel = 0
BP_LevelUp_OldRank_RankBgPath = ""
BP_LevelUp_OldRank_RankFgPath = ""
BP_LevelUp_OldRank_RankName = ""
BP_RankBgPath = ""
BP_RankFgPath = ""
BP_RankName = ""

-- 段位数据
BP_LevelUp_RankTypeName = ""
BP_LevelUp_RankType = 1
BP_LevelUp_NewRankName = ""
BP_LevelUp_NewRankLevel = 1
BP_LevelUp_OldRankName = ""
BP_LevelUp_OldRankLevel = 1
BP_LevelUp_OldRankMinIntergral = 0
BP_LevelUp_NewRankMinIntergral = 0
BP_LevelUp_OldRankMaxIntergral = 0
BP_LevelUp_NewRankMaxIntergral = 0

BP_LevelUp_PromoteToHigherRank = false

BP_LevelUp_OldRankPoint = 0
BP_LevelUp_NewRankPoint = 0
BP_LevelUp_RankImproveNum = 0
-- 段位动画类型  1 小段位晋升  2 大段位晋升  3 降级
BP_LevelUp_RankAnimation = 1
BP_LevelUp_ShowRankUp = false
BP_LevelUp_ShowLevelUp = false

BP_HasLevelupShareNum = 0;
BP_IsShareAwardGold = false; --每日首分享是否金币奖励

--注册Widget
function bp_levelup_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_levelup,
    {{Path="/Game/UMG/UI_Logic/LevelUp/LevelUp_LogicBP.LevelUp_LogicBP_C", Container="Top", ZOrder=BP_ENUM_UI_LEVEL_UP_ZORDER}},
    {"Lobby"},
	false,
	bp_levelup_OnModeSwitched ~= nil,
	true
  );
  BP_HasLevelupShareNum = 0;
  BP_IsShareAwardGold = false;
  
    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_levelup,
        "LevelUp_LogicBP_C",
		{
			"Overlay_ShareRankFather",
            "CanvasPanel_RankTipsGroupFather",  
            "CanvasPanel_LevelTipsGroupFather",
            "Overlay_levelbtnshowfather",
		}
	);
    end
end

--跳转到Lobby
function bp_levelup_OnModeSwitched(gamestatus)
	log("bp_levelup_OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
        log("remm levelup"..tostring(BP_LevelChange) .. " " .. tostring(BP_Lobby_RankChange))
        if BP_LevelChange or BP_Lobby_RankChange then
            LevelUpUI:Init()
            BP_LevelChange = false
            BP_Lobby_RankChange = false
        end
        
	end
end

function LevelUpUI:GetShareNum()
    if ShareAwardMgr.IsTodayShareDone() then
        return 1;
    else
        return 0;
    end
end

function EventFetchInfo()
	
end

function bp_levelup_OnModeAboutToSwitched()
    log("OnModeAboutToSwitched gamestatus = levelup");
end

-- 军衔
function LevelUpUI:GetLevelTabelData()
    local rankConfig = Client.GetTableData("MilitaryRankLevel", DataMgr.roleData.level);	
    local oldRankConfig = Client.GetTableData("MilitaryRankLevel", BP_LevelUp_OldLevel);	
    
    if rankConfig == nil then
        return
    end
  
    BP_RankBgPath = rankConfig.MilitaryRankTypeIconPath
    BP_RankFgPath = rankConfig.MilitaryRankBigIconPath
    BP_RankName = rankConfig.MilitaryRankName
    
    log(rankConfig.MilitaryRankTypeIconPath)
    log(rankConfig.MilitaryRankBigIconPath)
    log(rankConfig.MilitaryRankName)
    
    BP_LevelUp_OldRank_RankBgPath = oldRankConfig.MilitaryRankTypeIconPath
    BP_LevelUp_OldRank_RankFgPath = oldRankConfig.MilitaryRankBigIconPath
    BP_LevelUp_OldRank_RankName = oldRankConfig.MilitaryRankName
end

-- 段位

--EVENTID_DATAMGR_ROLE_SOLO_SEG_CHANGE
--EVENTID_DATAMGR_ROLE_DOUBLE_SEG_CHANGE
--EVENTID_DATAMGR_ROLE_TEAM_SEG_CHANGE
--段位变化时抛出以上事件才会触发调用下面接口.
function LevelUpUI:GetRankTabelData()
    -- 段位变化类型
     if DataMgr.UpdateZoneSegementZoneId <= 0 then
        return
     end
    -- 根据
    RankSegment = DataMgr.GetSegmentByZoneId(DataMgr.UpdateZoneSegementZoneId)
    if RankSegment == nil then
        return
    end
    if BP_LevelUp_RankType == 1 then
        BP_LevelUp_NewRankLevel = RankSegment.solo 
    elseif BP_LevelUp_RankType == 2 then
        BP_LevelUp_NewRankLevel = RankSegment.double 
    else
        BP_LevelUp_NewRankLevel = RankSegment.team 
    end
     

    -- 段位升降类型  1 小段位晋升  2 大段位晋升  3 降级
    if BP_LevelUp_NewRankLevel < BP_LevelUp_OldRankLevel then
        BP_LevelUp_RankAnimation = 3
    elseif LevelUpUI:CanPromoteToHigherRank(BP_LevelUp_OldRankLevel, BP_LevelUp_NewRankLevel) then
        BP_LevelUp_PromoteToHigherRank = true
        BP_LevelUp_RankAnimation = 2
    else
        BP_LevelUp_PromoteToHigherRank = false
        BP_LevelUp_RankAnimation = 1
    end
    
    -- 段位信息
    local rankConfig = Client.GetTableData("RankIntegralLevel", BP_LevelUp_NewRankLevel);	
    local oldRankConfig = Client.GetTableData("RankIntegralLevel", BP_LevelUp_OldRankLevel);	
    
    if rankConfig == nil or oldRankConfig == nil then
        return
    end
  
    BP_LevelUp_NewRankName = rankConfig.Name
    BP_LevelUp_NewRankMinIntergral = rankConfig.MinIntegral

    BP_LevelUp_OldRankName = oldRankConfig.Name
    BP_LevelUp_OldRankMinIntergral = oldRankConfig.MinIntegral
    
    
    BP_LevelUp_OldRankMaxIntergral = 0
    BP_LevelUp_NewRankMaxIntergral = 0


    BP_LevelUp_RankImproveNum = LevelUpUI:CalRankImproveNum(BP_LevelUp_OldRankLevel, BP_LevelUp_NewRankLevel)
    
    log("BP_LevelUp_OldRankPoint "..tostring(BP_LevelUp_OldRankPoint))
    log("BP_LevelUp_NewRankPoint "..tostring(BP_LevelUp_NewRankPoint))
end

-- 计算晋升多少小段
function LevelUpUI:CalRankImproveNum(oldId, newId)
    local rankConfig = Client.GetTableData("RankIntegralLevel", BP_LevelUp_NewRankLevel);	
    local oldRankConfig = Client.GetTableData("RankIntegralLevel", BP_LevelUp_OldRankLevel);	
    
    if rankConfig == nil or oldRankConfig == nil then
        return 0
    end
    
    local num = (rankConfig.IntegralType - oldRankConfig.IntegralType) * 5 + (rankConfig.IntegralTypeOrder - oldRankConfig.IntegralTypeOrder)
    
    return num
end

-- 判断是否进行大段
function LevelUpUI:CanPromoteToHigherRank(oldLevelId, newLevelId)
    local oldRank = Client.GetTableData("RankIntegralLevel", oldLevelId).IntegralType;
    local newRank = Client.GetTableData("RankIntegralLevel", newLevelId).IntegralType;
    
    if newRank > oldRank then
        return true
    else
        return false
    end
end

function LevelUpUI:Init()
    LuaClassObj.HandleDynamicCreation(bp_levelup);
	
    log("remm levelup levelupui init"..tostring(BP_LevelChange) .. " " .. tostring(BP_Lobby_RankChange))
    BP_LevelUp_ShowLevelUp = BP_LevelChange
    BP_LevelUp_ShowRankUp = BP_Lobby_RankChange

    BP_HasLevelupShareNum =  LevelUpUI:GetShareNum();--ShareMgr.GetShareNum();
    BP_IsShareAwardGold = ShareAwardMgr.IsAllAwardHasGet();
    
    if BP_LevelUp_ShowLevelUp then
        LevelUpUI:GetLevelTabelData()
    end
    
    if BP_LevelUp_ShowRankUp then
        LevelUpUI:GetRankTabelData()    
    end
    
    LuaClassObj.HandleUIMessage(bp_levelup, "UIShow");
    
end

function LevelUpUI:UpdateUI()
	BP_HasLevelupShareNum =  LevelUpUI:GetShareNum();
    BP_IsShareAwardGold = ShareAwardMgr.IsAllAwardHasGet();
	LuaClassObj.HandleUIMessage(bp_levelup, "UpdateUI");
end

--段位升级分享
function EventLevelUpShareRank()
	log("EventLevelUpShareRank");
	ShareRankUI:ShowSharePanel();
end

--军衔升级分享
function EventLevelUpShareLevel()
	log("EventLevelUpShareLevel");
	ShareLevelUpUI:ShowSharePanel();
end
