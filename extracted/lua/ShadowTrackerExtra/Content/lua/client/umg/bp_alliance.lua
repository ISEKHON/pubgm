-- 分队UI
AllianceUI = AllianceUI or {}

-- 分队相关数据结构
BP_STRUCT_AllianceInfo = 
{
    aid = "",               -- 分队ID
    name = "",              -- 分队名称
    icon = "",              -- 分队资源图标路径
    iconId = 0,             -- 分队图标ID
    notice = "",            -- 分队公告
    memberNum = 0,          -- 分队人数 
    captainId = "",         -- 分队长资料
    captainName = "",       -- 分队长资料
    trainValue = 0,         -- 训练值
    bonusPercent = 0,       -- 训练奖励
    bind_group = "0",        -- 绑定群
}

--分队列表
BP_ARRAY_Alliance_Info_List =
{
    BP_STRUCT_AllianceInfo = _G.BP_STRUCT_AllianceInfo,
}

-- 分队成员相关数据结构
BP_STRUCT_AllianceMemberProfile =
{
    gid="",
	nickName = "",
	level = 0,
	militaryRank = "";
    picUrl = "",
    vipLevel = 0,
    ladder = 0,-- 天梯
    platName = "",
    sex = 0,
    lastOnlineTime = 0,
	lastOnlineTimeStr = "";
	lastLoginTime = 0;
	exp = 0;
	segment_info_solo = 0;-- 段位数据
	segment_info_duo = 0;
	segment_info_squad = 0;
	
	friendType = 0;-- 好友类型（平台1、游戏内0） 
	
    applyMsg="", --好友申请里的留言
	createTime = 0,--好友申请的发送时间
	createTimeStr = "";
	
	online = 1, -- 0为离线，1为在线
		
	teamState = 0, -- 0为空闲，1为组队中（组队中提供当前队伍人数，队伍最大可容纳人数，队伍id）,2为已开局状态（需已开局时间数据）
	currentTeamAmount = 1, -- 当前队伍人数
	maxTeamAmount = 4, -- 队伍最大可容纳人数
	teamId = 0, -- 队伍id
	timeSinceGameBegin = 0, -- 已开局时间
	timeSinceGameBeginStr = "",
    cur_avatar_box_id = 0, -- 头像框
    qq_vip = 0,
    
    ---- 车队相关信息 ----
    isCaptain = false,  -- 是否队长
    allianceId = "",     -- 车队ID
    isMyFriend = true,
    openId = "",
    isInSnsGroup = false,
};

--分队成员列表
BP_ARRAY_Alliance_Member_Profile_List =
{
    BP_STRUCT_AllianceMemberProfile = _G.BP_STRUCT_AllianceMemberProfile,
}

-- 车队规则
BP_Alliance_Rules = ""

-- 暂存变化值
BP_Alliance_TeamName = ""
BP_Alliance_SelectIconId = 1
BP_Alliance_Notice = ""

BP_Alliance_SelectIconFrom = 1

--Macros
BP_Alliance_FROMCREATEPANEL = 1
BP_Alliance_FROMMAINPANEL = 2

-- 选择人员profile
BP_STRUCT_Selected_Member_Profile = BP_STRUCT_AllianceMemberProfile

BP_Alliance_Selected_Member_Id = ""

BP_Alliance_SelfUID = ""
BP_Alliance_SelfJoinGroup = false

BP_Alliance_IsOpenMainPanel = false

--注册Widget
function bp_alliance_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_alliance,
    {
        {Path="/Game/UMG/UI_Logic/Lobby_Team/LobbyTeam_NoTeam_LogicBP.LobbyTeam_NoTeam_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_ALLIANCE_ZORDER},
        {Path="/Game/UMG/UI_Logic/Lobby_Team/LobbyTeam_CreateTeam_LogicBP.LobbyTeam_CreateTeam_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_ALLIANCE_ZORDER + 3},
        {Path="/Game/UMG/UI_Logic/Lobby_Team/LobbyTeamMain_LogicBP.LobbyTeamMain_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_ALLIANCE_ZORDER},
        {Path="/Game/UMG/UI_Logic/Lobby_Team/LobbyTeam_SelectIcon_LogicBP.LobbyTeam_SelectIcon_LogicBP_C", Container="Default", ZOrder=BP_ENUM_UI_ALLIANCE_ZORDER + 6},
        
    },
    {"Lobby"},
	false,
	false,
	true
  );

    if GlobalData:IsIOSCheck() then
        LuaClassObj.SubCollapseWidgetList(bp_alliance,
        "LobbyTeamMain_LogicBP_C",
		{
			"PlatformGroupBtns",
		}
	);
    end
end

function EventFetchInfo()	
end

function EventSetInfo_Push()
end

--协议错误码处理
function AllianceUI.ProtocolErroCode(errorString, param)

    if errorString == "already-in-carteam" then
        --已经在车队里
         --DataMgr.ShowNoticeByString("已经在车队里");
         DataMgr.ShowNoticeByID(117001);
    elseif errorString == "not-in-carteam" then
        --不在车队里
        --DataMgr.ShowNoticeByString("不在车队里");
        DataMgr.ShowNoticeByID(117002);
    elseif errorString == "carteam-exists" then
        --车队已存在  
        --DataMgr.ShowNoticeByString("车队已存在");
        DataMgr.ShowNoticeByID(117003);
    elseif errorString == "db-error" then
        --DB出错
        --DataMgr.ShowNoticeByString("DB出错");
        DataMgr.ShowNoticeByID(117004);
    elseif errorString  == "insert-offmsg-failed" then  
        --插入离线消息失败 
        --DataMgr.ShowNoticeByString("插入离线消息失败");   
        DataMgr.ShowNoticeByID(117005);  
    elseif errorString == "invite-already" then
        --已被邀请
        --DataMgr.ShowNoticeByString("已被邀请");
        DataMgr.ShowNoticeByID(117006); 
    elseif errorString == "have-member-in-carteam" then
        --队长退出时, 车队还有其它人
        --DataMgr.ShowNoticeByString("车队还有其它人");
        DataMgr.ShowNoticeByID(117007);
    elseif errorString == "carteam-not-exists" then
        --车队不存在
        --DataMgr.ShowNoticeByString("车队不存在");
        DataMgr.ShowNoticeByID(117008);
    elseif errorString == "not-carteam-leader" then  
        --不是车队队长
        --DataMgr.ShowNoticeByString("不是车队队长");  
        DataMgr.ShowNoticeByID(117009);
    elseif errorString == "not-invited" then      
        --没被邀请
        --DataMgr.ShowNoticeByString("没被邀请");
        DataMgr.ShowNoticeByID(117010);
        
    elseif errorString == "level-not-enough" then  
        --创建时,等级不够
        local tipsStr = DataMgr.GetMsgByID(117011) -- "达到%s才能创建车队!";
        local rankConfig = Client.GetTableData("MilitaryRankLevel", param);	
        local name = ""
        if rankConfig ~= nil then
            name = rankConfig.MilitaryRankName
        end
        local strFormat = string.format(tipsStr, tostring(param), name);

        DataMgr.ShowNoticeByString(strFormat);
        
    elseif errorString == "carteam-is-full" then  
        --车队已满      
        DataMgr.ShowNoticeByID(117012);       
        
    elseif errorString == "create-too-much-today" then
        -- 当天创建次数过多
        --DataMgr.ShowNoticeByString("当天创建次数过多"); 
        DataMgr.ShowNoticeByID(117013);  
    
    elseif errorString == "group-not-bind" then
        -- 群尚未绑定
        --DataMgr.ShowNoticeByString("群尚未绑定");  
        DataMgr.ShowNoticeByID(117037);  
        
    elseif errorString == "apollo-failed" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("解绑失败");  
        --DataMgr.ShowNoticeByID(117038);  
        DataMgr.ShowNoticeByID(117051);  

    elseif errorString == "bind-apollo-failed" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("解绑失败");  
        --DataMgr.ShowNoticeByID(117038);  
        DataMgr.ShowNoticeByID(117052);  
        
    elseif errorString == "get-apollo-failed" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("解绑失败");  
        --DataMgr.ShowNoticeByID(117038);  
        DataMgr.ShowNoticeByID(117055);  
    
    elseif errorString == "join-apollo-failed" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("解绑失败");  
        --DataMgr.ShowNoticeByID(117038);  
        DataMgr.ShowNoticeByID(117053);  
    
    elseif errorString == "have-bind-this-day" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("今天已经创建过群了");  
        DataMgr.ShowNoticeByID(117056);  
        
    elseif errorString == "unbind-apollo-failed" then
        -- 解绑失败，Apollo内部错误
        --DataMgr.ShowNoticeByString("解绑失败");  
        --DataMgr.ShowNoticeByID(117038);  
        DataMgr.ShowNoticeByID(117054);  
       
    elseif errorString == "name-is-empty" then
        -- 名字为空
        --DataMgr.ShowNoticeByString("名字为空");  
        DataMgr.ShowNoticeByID(117039);  
        
    elseif errorString == "name-too-short" then
        -- 名字太短
        --DataMgr.ShowNoticeByString("名字太短"); 
        DataMgr.ShowNoticeByID(117040);  
        
    elseif errorString == "name-too-long" then
        -- 名字太长
        --DataMgr.ShowNoticeByString("名字太长"); 
        DataMgr.ShowNoticeByID(117041);  
        
    elseif errorString == "have-dirty-in-name" then
        -- 含有敏感词
        --DataMgr.ShowNoticeByString("名字含有敏感词"); 
        DataMgr.ShowNoticeByID(117042);  
    
    elseif errorString == "announcement-too-long" then
        -- 公告太长
        --DataMgr.ShowNoticeByString("公告太长"); 
        DataMgr.ShowNoticeByID(117043);  
    
    elseif errorString == "have-dirty-in-announcement" then
        -- 公告中含敏感词
        --DataMgr.ShowNoticeByString("公告中含敏感词"); 
        DataMgr.ShowNoticeByID(117044);  
        ---------------------------------------------------客户端的提示-------------- 
    elseif errorString == "client_send_ok" then
        --DataMgr.ShowNoticeByString("邀请已经发送");
         DataMgr.ShowNoticeByID(117014);  
        
    elseif errorString == "cline_JoinCarTeam" then
        local tipsStr =DataMgr.GetMsgByID(117015); -- "恭喜你成为<MessageProductColor>%s</>车队一员,今后请和大家一起建设车队吧!";
        local strFormat = string.format(tipsStr,param);
        local promptTip = FuncUtil.GetLocalizeResStr("101001");
        CommonMessageBoxUI:ShowPanel(1, promptTip, strFormat);
        
------ 建群错误提示 -------
    elseif errorString == "SnsGroupError" then
        if param == -1 then
            --DataMgr.ShowNoticeByString("创建错误"); 
            DataMgr.ShowNoticeByID(117016);              
        elseif param == 2009 or param == -10001 then
            --DataMgr.ShowNoticeByString("游戏没有建群权限"); 
            DataMgr.ShowNoticeByID(117017);
        elseif param == 2010 or param == -10002 then
            --DataMgr.ShowNoticeByString("参数检查错误"); 
            DataMgr.ShowNoticeByID(117018);
        elseif param == 2011 or param == -10005 then
            --DataMgr.ShowNoticeByString("微信群已存在"); 
            DataMgr.ShowNoticeByID(117019);
        elseif param == 2012 or param == -10006 then
            --DataMgr.ShowNoticeByString("建群数量超过上限"); 
            DataMgr.ShowNoticeByID(117020);
        elseif param == 2013 or param == -10007 then
            --DataMgr.ShowNoticeByString("群ID不存在"); 
            DataMgr.ShowNoticeByID(117021);
        elseif param == 2014 or param == -10008 then
            --DataMgr.ShowNoticeByString("ID今天已建过群，每天每个ID只能创建一个"); 
            DataMgr.ShowNoticeByID(117022);
        elseif param == 2015 then
            --DataMgr.ShowNoticeByString("加群数量超限，每天每个ID最多可加2个群");
            DataMgr.ShowNoticeByID(117023); 
        else
            --群功能失败，错误码为
            local tipsStr =DataMgr.GetMsgByID(117024);            
            DataMgr.ShowNoticeByString(string.format(tipsStr,tostring(param)));             
        end
        
    end
    
end

-- 打开未加入车队面板
function AllianceUI:OpenNoTeamPanel()
    log("AllianceUI:OpenNoTeamPanel")
	LuaClassObj.HandleDynamicCreation(bp_alliance);
    --BP_Alliance_Rules = LongTxt.AllianceRule
    BP_Alliance_Rules = FuncUtil.GetLocalizeResStr("301349");
    LuaClassObj.HandleUIMessage(bp_alliance, "ShowNoTeamPanel");
end

-- 关闭未加入车队面板
function AllianceUI:CloseNoTeamPanel()
    log("AllianceUI:CloseNoTeamPanel")
    LuaClassObj.HandleUIMessage(bp_alliance, "HideNoTeamPanel");
end

-- 打开创建车队面板
function AllianceUI:OpenCreateTeamPanel()
    log("AllianceUI:OpenCreateTeamPanel")
	LuaClassObj.HandleDynamicCreation(bp_alliance);
    LuaClassObj.HandleUIMessage(bp_alliance, "ShowCreateTeamPanel");
end

-- 关闭创建车队面板
function AllianceUI:CloseCreateTeamPanel()	
    log("AllianceUI:CloseCreateTeamPanel")
    LuaClassObj.HandleUIMessage(bp_alliance, "HideCreateTeamPanel");
end

-- 打开选择图标界面
function AllianceUI:OpenSelectIconPanel()
	LuaClassObj.HandleDynamicCreation(bp_alliance);
    LuaClassObj.HandleUIMessage(bp_alliance, "ShowSelectIconPanel");
end

-- 打开车队主面板
function AllianceUI:OpenTeamMainPanel()
    log("AllianceUI:OpenTeamMainPanel")
	LuaClassObj.HandleDynamicCreation(bp_alliance);
    LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData");
    LuaClassObj.HandleUIMessage(bp_alliance, "ShowTeamMainPanel");
    BP_Alliance_IsOpenMainPanel = true
    log("BP_Alliance_IsOpenMainPanel "..tostring(BP_Alliance_IsOpenMainPanel))
end

-- 关闭车队主面板
function AllianceUI:CloseTeamMainPanel()
    log("AllianceUI:CloseTeamMainPanel")
    LuaClassObj.HandleUIMessage(bp_alliance, "CloseTeamMainPanel");
    BP_Alliance_IsOpenMainPanel = false
    log("BP_Alliance_IsOpenMainPanel "..tostring(BP_Alliance_IsOpenMainPanel))
end

-- 刷新车队主面板
function AllianceUI:RefreshTeamMainPanel()
    log("AllianceUI:RefreshTeamMainPanel")
    LuaClassObj.HandleUIMessage(bp_alliance, "RefreshTeamMainPanel");
    log("BP_Alliance_IsOpenMainPanel "..tostring(BP_Alliance_IsOpenMainPanel))
end

-- 蓝图调用
function EventClickAllianceCreateTeamBtn()
    AllianceSystem.SendPreCreateTeamCheck()
end

-- 点击关闭主面板按钮
function EventClickAllianceCloseMainPanel()
    BP_Alliance_IsOpenMainPanel = false
    log("BP_Alliance_IsOpenMainPanel "..tostring(BP_Alliance_IsOpenMainPanel))
end

--点击按钮随机名字
function EventClickAllianceRandomNameBtn()
	log("EventRandomName");
    BP_Alliance_TeamName = GetRandomName(BP_CreateRole_Sex);
    
	LuaClassObj.HandleUIMessage(bp_alliance, "CreateTeamRefreshTeamName");
end

--选择车队图标
function EventClickAllianceSelectIcon()
    if BP_Alliance_SelectIconFrom == BP_Alliance_FROMCREATEPANEL then
        LuaClassObj.HandleUIMessage(bp_alliance, "FinishSelectIcon");
        LuaClassObj.HandleUIMessage(bp_alliance, "HideSelectIconPanel");
    elseif BP_Alliance_SelectIconFrom == BP_Alliance_FROMMAINPANEL then
        EventAllianceChangeTeamIcon()
    end

end

-- 创建结束
function EventAllianceFinishCreation()
    BP_Alliance_TeamName = FuncUtil:StrTrim(BP_Alliance_TeamName);

	local ret, len, retStr = FuncUtil:CheckName(BP_Alliance_TeamName, true, nil, true);
    log(ret)
    if ret then
		DataMgr.ShowNoticeByID(990004);
        return;
	end	

    if len > 20 then
		DataMgr.ShowNoticeByID(117041);
        return;
    end	
    AllianceSystem.SendCreateTeamReq(BP_Alliance_TeamName, BP_Alliance_SelectIconId, "")
end

-- 修改车队名
function EventAllianceChangeTeamName()
    AllianceSystem.SendChangeTeamInfo(1, BP_Alliance_TeamName)
end

-- 修改车队图标
function EventAllianceChangeTeamIcon()
    AllianceSystem.SendChangeTeamInfo(2, BP_Alliance_SelectIconId)
end

-- 修改车队公告
function EventAllianceChangeTeamNotice()
    AllianceSystem.SendChangeTeamInfo(3, BP_Alliance_Notice)
end

-- 点击显示选择icon面板
function EventClickShowSelectIconMainPanel_FromCreatePanel()
    BP_Alliance_SelectIconFrom = BP_Alliance_FROMCREATEPANEL
    AllianceUI:OpenSelectIconPanel()
end

-- 点击显示选择icon面板
function EventClickShowSelectIconMainPanel_FromMainPanel()
    BP_Alliance_SelectIconFrom = BP_Alliance_FROMMAINPANEL
    AllianceUI:OpenSelectIconPanel()
end

-- 点击招募队友
function EventAllianceClickRecruit()
    -- 古咕咕咕个哥哥
    log("EventAllianceClickRecruit");
    AllianceRecruitUI.ShowUIRecruit();
end

local function LocalAllianceExitTeamReq()
    AllianceSystem.SendExitTeamReq()
end

-- 点击退出车队
function EventAllianceClickExitTeam()
    
    local promptTip = FuncUtil.GetLocalizeResStr("101001");
    -- 是队长
    if BP_STRUCT_AllianceInfo.captainId == DataMgr.roleData.uid then
        -- 有队员
        if BP_STRUCT_AllianceInfo.memberNum > 1 then
            --你是队长，只有将队长职位转让给其他成员后，你才能退出小分队
            local tipsStr =DataMgr.GetMsgByID(117025);
            CommonMessageBoxUI:ShowPanel(1, promptTip, tipsStr, nil, nil);
        -- 无队员
        else
            --退出后，小分队将被解散，你确定要退出吗？
            local tipsStr =DataMgr.GetMsgByID(117026);
            CommonMessageBoxUI:ShowPanel(2, promptTip, tipsStr, LocalAllianceExitTeamReq, nil);
        end
    else
        -- 不是队长
        --你确定要退出小分队吗？
        local tipsStr =DataMgr.GetMsgByID(117027);
        CommonMessageBoxUI:ShowPanel(2, promptTip, tipsStr, LocalAllianceExitTeamReq, nil);
    end
    
end

-- 点击查看个人信息
function EventAllianceClickOpenView()
    log("EventAllianceClickOpenView"..BP_Alliance_Selected_Member_Id)
    RoleInfoSystem.Enter(BP_Alliance_Selected_Member_Id)
    RoleInfoUI.Init();
end

-- 点击添加好友
function EventAllianceClickAddFriend()
    log("EventAllianceClickAddFriend"..BP_Alliance_Selected_Member_Id)
    FriendSystem.AddFriend(BP_Alliance_Selected_Member_Id, BP_ENUM_ADD_FRIEND_FROM_ALLIANCE)
end

local function LocalAllianceKickout()
    AllianceSystem.KickoutTeamReq(BP_Alliance_Selected_Member_Id)
end

-- 点击踢出车队
function EventAllianceClickKickout()
    log("EventAllianceClickKickout"..BP_Alliance_Selected_Member_Id)
    
    local selectedName = ""
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(BP_Alliance_Selected_Member_Id) then
            selectedName = v.nickName
        end
    end
    local tipsStr =DataMgr.GetMsgByID(117028);
    --"你确定要把<MessageProductColor>"..selectedName.."</>移除小分队吗？""你确定要把<MessageProductColor>"..selectedName.."</>移除小分队吗？"
    local promptTip = FuncUtil.GetLocalizeResStr("101001");
    CommonMessageBoxUI:ShowPanel(2, promptTip, string.format(tipsStr,selectedName), LocalAllianceKickout, nil);
end

local function LocalAllianceAppointment()
    AllianceSystem.SendAppointmentReq(BP_Alliance_Selected_Member_Id)
end

-- 点击任命队长
function EventAllianceClickAppointment()
    log("EventAllianceClickAppointment"..BP_Alliance_Selected_Member_Id)
    
    local selectedName = ""
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(BP_Alliance_Selected_Member_Id) then
            selectedName = v.nickName
        end
    end
    local tipsStr =DataMgr.GetMsgByID(117029);
     --移交后你将失去对小分队进行管理的权限，你确定要把队长移交给<MessageProductColor>"..selectedName.."</>吗？
    local promptTip = FuncUtil.GetLocalizeResStr("101001");
    CommonMessageBoxUI:ShowPanel(2, promptTip, string.format(tipsStr,selectedName), LocalAllianceAppointment, nil);

end

-- 点击聊天
function EventAllianceClickChat()
    log("EventAllianceClickChat"..BP_Alliance_Selected_Member_Id)
    LobbyChatSystem.ChatWithFriend(BP_Alliance_Selected_Member_Id)	
end

-- 点击建微信群
function EventAllianceClickBuildWxGroup()
    log("EventAllianceClickBuildWxGroup")
    local params =
    {
        unionId = BP_STRUCT_AllianceInfo.aid,
        chatRoomName = BP_STRUCT_AllianceInfo.name
    }
    AllianceSystem.createWechatGroup(params)
end

-- 点击加微信群
function EventAllianceClickJoinWxGroup()
    log("EventAllianceClickBuildWxGroup")

    if BP_STRUCT_AllianceInfo.bind_group == "0"then
        --"还没有创建群"
        PopUpNoticeUI.ShowNewNotice(DataMgr.GetMsgByID(117030))
        return
    end
    
    if BP_Alliance_SelfJoinGroup then
        --PopUpNoticeUI.ShowNewNotice("已经加入群了")
        DataMgr.ShowNoticeByID(117045);  
        return
    end
    
    local params =
    {
        unionId = BP_STRUCT_AllianceInfo.aid,
        chatRoomName = BP_STRUCT_AllianceInfo.name
    }
    AllianceSystem.joinWechatGroup(params)
end

-- 点击解绑微信群
function EventAllianceClickUnbindWxGroup()
    --你确定要解除车队与这个群的绑定吗
    local promptTip = FuncUtil.GetLocalizeResStr("101001");
    CommonMessageBoxUI:ShowPanel(2, promptTip, DataMgr.GetMsgByID(117031), 
        function ()
            AllianceSystem.SendUnbindGroup()
        end
        );
end

-- 点击建qq群
function EventAllianceClickBuildQQGroup()
    AllianceSystem.SendBindGroup(nil) 
end

-- 点击加QQ群
function EventAllianceClickJoinQQGroup()
    log("EventAllianceClickJoinQQGroup")

    if BP_STRUCT_AllianceInfo.bind_group == "0"then
        --"还没有创建群"
        PopUpNoticeUI.ShowNewNotice(DataMgr.GetMsgByID(117030))
        return
    end
    
    if BP_Alliance_SelfJoinGroup then
        --PopUpNoticeUI.ShowNewNotice("已经加入群了")
        DataMgr.ShowNoticeByID(117045);  
        return
    end
    
    AllianceSystem.SendJoinGroup()
end

-- 点击解绑QQ群
function EventAllianceClickUnbindQQGroup()
    --你确定要解除车队与这个群的绑定吗    
    local promptTip = FuncUtil.GetLocalizeResStr("101001");
    CommonMessageBoxUI:ShowPanel(2, promptTip, DataMgr.GetMsgByID(117031), 
        function ()
            AllianceSystem.SendUnbindGroup()
        end
        );
end

-- 蓝图调用End
--返回随机名字
function AllianceUI:GetRandomTeamName()
    local name = ""
    if(AllianceIconPathTable == nil) then
        return name;
    end
    local n = #AllianceIconPathTable;
    local n0 = math.random(n)
    local n1 = math.random(n)

    name = AllianceIconPathTable[n0].a .. AllianceIconPathTable[n1].b
    return name
end

BP_Alliance_RecruitRedPointStatus = false

-- 红点显示
function AllianceUI:RedPointStatusUpdate(show)
    log("AllianceUI:RedPointStatusUpdate:"..tostring(show))
    -- 大厅上红点
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_ALLIANCE, show)
    
    -- 车队主界面红点
    BP_Alliance_RecruitRedPointStatus = show
    LuaClassObj.HandleUIMessage(bp_alliance, "SetRedPointStatus")
end

