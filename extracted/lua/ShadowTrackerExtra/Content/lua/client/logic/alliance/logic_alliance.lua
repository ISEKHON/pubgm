--[[
    分队相关逻辑
]]

AllianceSystem = AllianceSystem or
{
    --离线收到邀请进车队消息   
    OffMsgInfo = {},
    --[[
    uid为key
    offmsg:
       index:   索引
       uid:     uid
       type:    1 车队消息
       sendtime:    时间
       msg:     消息
        op    1 邀请; 2 通知审核完加入
        team_id   车队ID
        team_name 车队名称
        from_uid  邀请人uid
    --]]
    TeamMemberList = {},
    InWxGroupTeamMemberOpenIdList = {},
    NeedOpenPanel = false,
    ProfileRefreshTimestamp = 0,
    FetchClickTimeLength = 120,
}



function AllianceSystem.Entry()
    -- Event Register
    log("AllianceSystem Entry!!!!!!!!!!!!")
    EventSystem:registEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN, AllianceSystem.OnBackLogin);
    AllianceSystem.ReleaseData()
    AllianceSystem.GetAllianceData()
end

function AllianceSystem.Quit()
    -- Event Unregister
    EventSystem:unregistEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN, AllianceSystem.OnBackLogin);
end

-- 回到登录界面
function AllianceSystem.OnBackLogin()
    AllianceSystem.ReleaseData()
end

-- 清除数据
function AllianceSystem.ReleaseData()
    AllianceSystem.TeamMemberList = {}
    BP_ARRAY_Alliance_Member_Profile_List = {}
    BP_STRUCT_AllianceInfo = {}
end


function AllianceSystem.OpenAllianceUI()
    log("Try Open AllianceSystem")
    BP_Alliance_SelfUID = DataMgr.roleData.uid
    AllianceSystem.NeedOpenPanel = true
    NetUtil.SendPriorityPkg(true, "query_carteam_rsp", "query_carteam_req");
end

function AllianceSystem.GetAllianceData()
    log("query_carteam_req")
    NetUtil.SendPkg("query_carteam_req");
end

-- 获取车队成员列表
function AllianceSystem.GetAllianceProfileList()
    return BP_ARRAY_Alliance_Member_Profile_List
end

-- 获取车队成员列表（不含自己）
function AllianceSystem.GetAllianceProfileListWithoutSelf()
    local profileList = {}
    
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid ~= tostring(DataMgr.roleData.uid) and v.gid ~= "" then
            table.insert(profileList, v)
        end
    end
    --log_tree("GetAllianceProfileListWithoutSelf", profileList)
    return profileList
end

-- 判断是否车队成员
function AllianceSystem.IsAllianceMember(uid)
    
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(uid) then
            return true
        end
    end
    
    return false
end


--判断是否队长
function AllianceSystem.IsLeader()
    local result  = false;
    if BP_STRUCT_AllianceInfo ~= nil and BP_STRUCT_AllianceInfo.aid ~= nil and BP_STRUCT_AllianceInfo.captainId ~= nil then
       if DataMgr.roleData.uid == BP_STRUCT_AllianceInfo.captainId then
            result = true;
       end
    end

    return result;
end

function AllianceSystem.ConstructAllianceData(carteam)
    --MemberList
    -- Construct uidlist
    local uidList = {}
    local memberOpenidList = ""
    for k,v in pairs(carteam.members) do
        table.insert(uidList, k)
        memberOpenidList = memberOpenidList .. v.openid..","
    end
    log("Construct openId list:"..memberOpenidList)
    --AllianceInfo
    BP_STRUCT_AllianceInfo = 
    {
        aid = tostring(carteam.team_id),               -- 分队ID
        name = tostring(carteam.name),              -- 分队名称
        icon = "",              -- 分队资源图标路径
        iconId = carteam.icon,             -- 分队图标ID
        notice = tostring(carteam.announcement),            -- 分队公告
        memberNum = #uidList,          -- 分队人数 
        captainId = tostring(carteam.leader.uid),    -- 分队长资料
        captainName = tostring(carteam.leader.name),
        trainValue = 0,         -- 训练值
        bonusPercent = 0,       -- 训练奖励
        bind_group = tostring(carteam.bind_group),
    }

    AllianceSystem.TeamMemberList = carteam.members
    
    -- Send req
    AllianceSystem.on_profile_req(uidList, "alliance")
    
    -- Query Group Status
    log("Current Platform:!!!".. tostring(Client.GetDevicePlatformName()))
    if (string.lower(Client.GetDevicePlatformName()) == "android" or
        string.lower(Client.GetDevicePlatformName()) == "ios")  
    then
        if (BP_Platform == BP_ENUM_PLAYFORM_WX) then
            local params = 
            {
                unionId = carteam.team_id,
                openIdList = memberOpenidList
            }
            
            AllianceSystem.queryWechatGroup(params)
        elseif (BP_Platform == BP_ENUM_PLAYFORM_QQ) then
            AllianceSystem.SendQueryQQGroup()
        end  
    end

end

function AllianceSystem.QueryWxGroupStatus()
    
    local memberOpenidList = ""
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        memberOpenidList = memberOpenidList .. v.openid..","
    end
    log("Construct openId list:"..memberOpenidList)
    
    local params = 
    {
        unionId = BP_STRUCT_AllianceInfo.aid,
        openIdList = memberOpenidList
    }
    
    AllianceSystem.queryWechatGroup(params)
end

-- 刷新微信群状态
function AllianceSystem.RefreshWxGroupStatus(flag, wechatGroupInfo)
    
    if flag ~= 0 then
        return
    end
    -- 如果后台没绑，通知绑
    if BP_STRUCT_AllianceInfo.bind_group == "0" and 
        BP_STRUCT_AllianceInfo.captainId == DataMgr.roleData.uid then
        AllianceSystem.SendBindGroup(BP_STRUCT_AllianceInfo.aid)
    end
    
    local openidList = {}
    for s in string.gmatch(wechatGroupInfo.OpenIdList,"([^',']+)") do     --按照“,”分割字符串
        table.insert(openidList, s) 
    end
    
    --log_tree("In group openidList", openidList)
    AllianceSystem.InWxGroupTeamMemberOpenIdList = {}
    -- 遍历openidlist，检查车队成员加入群情况
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        AllianceSystem.InWxGroupTeamMemberOpenIdList[k] = false
        for k1, v1 in pairs(openidList) do
            if v.openid == v1 then
                AllianceSystem.InWxGroupTeamMemberOpenIdList[k] = true
            end
        end
    end
    
    BP_Alliance_SelfJoinGroup = AllianceSystem.InWxGroupTeamMemberOpenIdList[tonumber(DataMgr.roleData.uid)] 
    
    if BP_Alliance_IsOpenMainPanel then
        log("Refresh WxGroup Status")
        AllianceUI:RefreshTeamMainPanel()
    end
end

function AllianceSystem.ConstructSelfData()
    local data = {}
    data.nickName = DataMgr.roleData.nickName
    data.level = DataMgr.roleData.level
    local rank = Client.GetTableData("MilitaryRankLevel", DataMgr.roleData.level)
    if rank ~= nil then
        data.militaryRank = rank.MilitaryRankName
    end
    
    data.picUrl = DataMgr.roleData.headIconUrl
    data.vipLevel = 0
    data.qq_vip = DataMgr.roleData.qq_vip
    data.platName = ""
    data.sex = DataMgr.roleData.gender
    data.lastOnlineTime = 0
    data.lastOnlineTimeStr = ""
    data.lastLoginTime = 0
    data.exp = DataMgr.roleData.roleExp
    data.segment_info_solo = DataMgr.roleData.segment.solo -- need not change
    data.segment_info_duo = DataMgr.roleData.segment.double
    data.segment_info_squad = DataMgr.roleData.segment.team
    data.cur_avatar_box_id = DataMgr.roleData.cur_avatar_box_id
    data.AllSegment_Info = DataMgr.roleData.allzoneSegment
    return data
end

function AllianceSystem.OnTeamMemberProfileListReturn(role_basic_info_list)
    
	--log_tree("AllianceSystem.OnTeamMemberProfileListReturn  role_basic_info_list", role_basic_info_list)
    BP_ARRAY_Alliance_Member_Profile_List = {}
    for k,v in pairs(role_basic_info_list) do
        local data = {}

        if (tostring(v.uid) == DataMgr.roleData.uid) then
            data = AllianceSystem.ConstructSelfData()
        else
            data.nickName = v.nickName
            data.level = v.level
            local rank = Client.GetTableData("MilitaryRankLevel", v.level)
            if rank ~= nil then
                data.militaryRank = rank.MilitaryRankName
            end
        
            data.picUrl = v.picUrl
            data.vipLevel = v.vipLevel
            data.ladder = v.ladder
            data.qq_vip = v.qq_vip
            data.platName = v.platName
            data.sex = v.sex
            data.lastOnlineTime = v.lastOnlineTime
            data.lastOnlineTimeStr = FriendSystem.FormatTime(v.lastOnlineTime,"online")
            data.lastLoginTime = v.lastLoginTime
            data.exp = v.exp
            ----------------------------------------intl modify--------------------------------------
             --[[
            data.segment_info_solo = v.segment_info[1]
            data.segment_info_duo = v.segment_info[2]
            data.segment_info_squad = v.segment_info[3]
            ]]
             data.AllSegment_Info = v.segment_info; 
             for k, v in pairs(data.AllSegment_Info) do
                   data.segment_info_solo   = data.AllSegment_Info[k][1];
                   data.segment_info_duo    = data.AllSegment_Info[k][2];
                   data.segment_info_squad = data.AllSegment_Info[k][3];
                   break;
             end
             
             data.segment_info_solo, data.segment_info_duo,data.segment_info_squad =  FuncUtil.GetMaxSegement(data.AllSegment_Info);
             
            ----------------------------------------intl modify--------------------------------------
            data.cur_avatar_box_id = v.cur_avatar_box_id
        end
        data.gid = tostring(v.uid)
        data.friendType = 0
        data.online = AllianceSystem.TeamMemberList[v.uid].online_state
        data.teamState = AllianceSystem.TeamMemberList[v.uid].team_state
        data.currentTeamAmount = AllianceSystem.TeamMemberList[v.uid].team_amount
        data.maxTeamAmount = AllianceSystem.TeamMemberList[v.uid].team_max
        data.isMyFriend = FriendSystem.IsMyFriend(tostring(v.uid))
        data.openId = AllianceSystem.TeamMemberList[v.uid].openid
        
        data.isInSnsGroup = AllianceSystem.InWxGroupTeamMemberOpenIdList[v.uid]
        
        if tostring(data.gid) == BP_STRUCT_AllianceInfo.captainId then            
            data.isCaptain = true
        else
            data.isCaptain = false
        end
        
        table.insert(BP_ARRAY_Alliance_Member_Profile_List, data)
    end
    table.sort(BP_ARRAY_Alliance_Member_Profile_List, AllianceProfileSortFunc)
    --log_tree("AllianceSystem.OnTeamMemberProfileListReturn sort role_basic_info_list", BP_ARRAY_Alliance_Member_Profile_List)
    -- 打开主面板
    if AllianceSystem.NeedOpenPanel then
        log("AllianceSystem.OpenMainPanel!!!!!!!")
        AllianceUI:OpenTeamMainPanel()
        AllianceSystem.NeedOpenPanel = false
    else
        LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData");
    end    
end

--(自己>在线>组队中>游戏中>离线(离线按最近登录时间排序)
function AllianceProfileSortFunc(a,b)
    if tostring(a.gid) == tostring(DataMgr.roleData.uid) then
        return true
    end
    
    if tostring(b.gid) == tostring(DataMgr.roleData.uid) then
        return false
    end
    
	if a.online == nil or b.online == nil then
		return false
	end

	if a.online == b.online then
		if a.teamState == nil or b.teamState == nil then
				return false
			end
			
		if a.teamState == b.teamState then
	
            if a.level == nil or b.level == nil then
                return false
            end
                
            if a.level == b.level then
                return tonumber(a.lastOnlineTime) > tonumber(b.lastOnlineTime)
            else
                return a.level > b.level
            end

		else
			return a.teamState < b.teamState
		end
	else
		return a.online > b.online
	end
end

-- 更新队长
function AllianceSystem.UpdateTeamCaptain(uid)
    
    log("AllianceSystem.UpdateTeamCaptain" .. tostring(uid))
    --log_tree("AllianceSystem.UpdateTeamCaptain", BP_ARRAY_Alliance_Member_Profile_List)
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(uid) then
            BP_STRUCT_AllianceInfo.captainName = v.nickName
            BP_STRUCT_AllianceInfo.captainId = tostring(uid)
            v.isCaptain = true
            log("Update Captain success!!!!")
            
            if tostring(v.gid) == tostring(DataMgr.roleData.uid) then
                --PopUpNoticeUI.ShowNewNotice("恭喜你，你被任命为新的队长。")
                PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301281").TextValue)
            end
            
        else
            v.isCaptain = false
        end
        
    end
    
    --log_tree("AllianceSystem.UpdateTeamCaptain after", BP_ARRAY_Alliance_Member_Profile_List)
end

-- 删除队员
function AllianceSystem.KickoutTeamMember(uid)
    
    
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(uid) then
            table.remove(BP_ARRAY_Alliance_Member_Profile_List, k)
            BP_STRUCT_AllianceInfo.memberNum = BP_STRUCT_AllianceInfo.memberNum - 1
            log("KickoutTeamMember success!!!!")
            break
        end
    end
    
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        if tostring(k) == tostring(uid) then
            AllianceSystem.TeamMemberList[k] = nil
            
            log("KickoutTeamMember success TeamMemberList!!!!")
            break
        end
    end
    
    --log_tree("KickoutTeamMember BP_ARRAY_Alliance_Member_Profile_List", BP_ARRAY_Alliance_Member_Profile_List)
    --log_tree("KickoutTeamMember AllianceSystem.TeamMemberList", AllianceSystem.TeamMemberList)
end

-- 添加队员
function AllianceSystem.AddTeamMember(uid, member)
    
    --log_tree("AllianceSystem.AddTeamMember"..tostring(uid), member)
    AllianceSystem.TeamMemberList[tonumber(uid)] = member
    
    --log_tree("AllianceSystem.AddTeamMember", AllianceSystem.TeamMemberList)
    
    local uidList = {}
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        table.insert(uidList, k)
    end
    
    BP_STRUCT_AllianceInfo.memberNum = #uidList
    -- Send req
    AllianceSystem.on_profile_req(uidList, "alliance")
    
end

--members
--└─ 410000001
------├─ name: "幽灵阿布利"
------├─ invite_uid: 0
------├─ status: 3
------├─ team_max: 0
------├─ openid: "E7055DD4366F8545EDA1775542CC0ABD"
------├─ room_state: 0
------├─ team_amount: 0
------├─ online_state: 1
------└─ team_state: 0

-- 更新队员
function AllianceSystem.UpdateTeamMember(uid, member)
    
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        if v.gid == tostring(uid) then
            AllianceSystem.TeamMemberList[k] = member
            
            log("UpdateTeamMember success TeamMemberList!!!!")
            break
        end
    end
    
    for k,v in pairs(BP_ARRAY_Alliance_Member_Profile_List) do
        if v.gid == tostring(uid) then
            
            v.online = member.online_state
            v.teamState = member.team_state
            v.currentTeamAmount = member.team_amount
            v.maxTeamAmount = member.team_max
        
            log("UpdateTeamMember BP_ARRAY_Alliance_Member_Profile_List success TeamMemberList!!!!")
            break
        end
    end
    
    table.sort(BP_ARRAY_Alliance_Member_Profile_List, AllianceProfileSortFunc)
    --[[local uidList = {}
    for k,v in pairs(AllianceSystem.TeamMemberList) do
        table.insert(uidList, k)
    end
    AllianceSystem.on_profile_alliance_req(uidList, true);]]
end

-----------------------------------请求分割线--------------------------
--请求申请列表,成功后在请求概要信息
function AllianceSystem.SendGetApplyListReq()    
    NetUtil.SendPriorityPkg(false, "get_carteam_apply_list_rsp", "get_carteam_apply_list_req");
end

--招募
function AllianceSystem.SendInviteCarTeamReq(inviteID)
    log("SendInviteTeamReq"..tostring(inviteID));
    NetUtil.SendPriorityPkg(true, "invite_join_carteam_rsp", "invite_join_carteam_req", tonumber(inviteID));   
end

--接受邀请 is_accept为true就是接受, 否则为拒绝
function AllianceSystem.SendAcceptJoinReq(team_id, from_uid, offmsg_id, is_accept)
    log("SendAcceptJoinReq team_id:"..tostring(team_id).."from_uid:"..tostring(from_uid).."offmsg_id:"..tostring(offmsg_id).."is_accept:"..tostring(is_accept));
    NetUtil.SendPriorityPkg(true, "accept_join_carteam_rsp", "accept_join_carteam_req", tonumber(team_id),tonumber(from_uid),tonumber(offmsg_id),is_accept);   
end

--请求拉取离线消息，type = 1为车队邀请信息
function AllianceSystem.SendAllOffMsgReq(type)
    log("SendAllOffMsgReq"..type);
    NetUtil.SendPkg("get_all_offmsg_req", type);
end

--队长审核
function AllianceSystem.SendApproveReq(uid, isPass)
    log("SendApproveReq"..tostring(uid));
    NetUtil.SendPriorityPkg(true, "approve_join_carteam_rsp", "approve_join_carteam_req", tonumber(uid), isPass);   
end

-- 请求创建车队
function AllianceSystem.SendCreateTeamReq(name, icon, announcement)
    NetUtil.SendPriorityPkg(true, "create_carteam_rsp", "create_carteam_req", name, icon, announcement);
end

-- 请求更新车队信息
function AllianceSystem.SendChangeTeamInfo(changeType, value)
    if BP_STRUCT_AllianceInfo.captainId ~= DataMgr.roleData.uid then
        log("Not Captain!")
        --PopUpNoticeUI.ShowNewNotice("车队队长才可编辑")
        PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301280").TextValue)
        AllianceUI:RefreshTeamMainPanel()
        return
    end
    log("change_carteam_req"..tostring(changeType)..tostring(value))
    NetUtil.SendPriorityPkg(true, "change_carteam_rsp", "change_carteam_req", changeType, value);
end

-- 请求退出车队
function AllianceSystem.SendExitTeamReq()
    log("exit_carteam_req")
    NetUtil.SendPriorityPkg(true, "exit_carteam_rsp", "exit_carteam_req");
end

-- 请求踢出车队
function AllianceSystem.KickoutTeamReq(uid)
    log("KickoutTeamReq"..tostring(uid))
    NetUtil.SendPkg("kickout_carteam_req", tonumber(uid));
end

-- 请求任命队长
function AllianceSystem.SendAppointmentReq(uid)
    log("transfer_carteam_leader_req"..tostring(uid))
    NetUtil.SendPkg("transfer_carteam_leader_req", tonumber(uid));
end


-- 请求绑定群
function AllianceSystem.SendBindGroup(group_id)
    log("bind_carteam_group_req"..tostring(group_id))
    NetUtil.SendPkg("bind_carteam_group_req", tonumber(group_id));
end

-- 请求解绑群
function AllianceSystem.SendUnbindGroup()
    log("unbind_carteam_group_req")
    NetUtil.SendPkg("unbind_carteam_group_req");
end

-- 请求加入qq群
function AllianceSystem.SendJoinGroup()
    log("join_carteam_group_req")
    NetUtil.SendPkg("join_carteam_group_req");
end

-- 请求查询qq群
function AllianceSystem.SendQueryQQGroup()
    log("get_carteam_group_relation_req")
    NetUtil.SendPkg("get_carteam_group_relation_req");
end

-- 请求创建车队资格判断
function AllianceSystem.SendPreCreateTeamCheck()
    log("pre_create_carteam_req")
    NetUtil.SendPriorityPkg(true, "pre_create_carteam_rsp", "pre_create_carteam_req");
end
-----------------------------------后台返回分割线----------------------

-- 创建车队
function AllianceSystem.on_create_carteam_rsp(ok, reason, carteam)
    log("AllianceSystem.on_create_carteam_rsp")
    if not ok then
        log("AllianceSystem.on_create_carteam_rsp not ok"..tostring(reason))
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    log_tree("AllianceSystem.on_create_carteam_rsp", carteam)
    
    -- 创建成功关闭创建面板
    AllianceUI:CloseCreateTeamPanel()
    -- 构造车队数据结构
    AllianceSystem.ConstructAllianceData(carteam)
    
    AllianceSystem.NeedOpenPanel = true
end

-- 修改车队
function AllianceSystem.on_change_carteam_rsp(ok, reason)
    log("AllianceSystem.on_change_carteam_rsp")
    if not ok then
        log("AllianceSystem.on_change_carteam_rsp not ok"..tostring(reason))
        AllianceUI.ProtocolErroCode(reason);
        return
    end
end

-- 更新车队(nil解散)
function AllianceSystem.on_notify_update_carteam_info(team_id, changeType, value)
    log("AllianceSystem.on_notify_update_carteam_info"..tostring(team_id).." "..tostring(changeType).." "..tostring(value))
    
    if BP_STRUCT_AllianceInfo.aid ~= tostring(team_id) then
        log("Not my team")
        return
    end
    
    -- 车队名称修改
    if changeType == 1 then
        BP_STRUCT_AllianceInfo.name = value
    end
    
    -- 车队图标修改
    if changeType == 2 then
        BP_STRUCT_AllianceInfo.iconId = value
        LuaClassObj.HandleUIMessage(bp_alliance, "HideSelectIconPanel");
    end
    
    -- 车队公告修改
    if changeType == 3 then
        BP_STRUCT_AllianceInfo.notice = value
    end
    
    -- 车队队长修改
    if changeType == 4 then
        AllianceSystem.UpdateTeamCaptain(value)
        LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData");

        local isCaptain = AllianceSystem.IsLeader();
        if isCaptain == true then
            AllianceSystem.SendGetApplyListReq();
        end
        
        return
    end
    
    AllianceUI:RefreshTeamMainPanel()
end

-- 邀请加入车队
function AllianceSystem.on_invite_join_carteam_rsp(ok, reason, to_uid)
    log("on_invite_join_carteam_rsp ok:"..tostring(ok).."reason:"..tostring(reason).."uid:"..tostring(uid)) 
    if ok == true then
        --发送邀请成功
        AllianceUI.ProtocolErroCode("client_send_ok");
         log("on_invite_join_carteam_rsp ok"..to_uid);
         AllianceRecruitUI.HasSendInvite(to_uid);

    elseif ok == false then
      log("on_invite_join_carteam_rsp failed"..reason);
        AllianceUI.ProtocolErroCode(reason);

    end
end

-- 通知有消息了，采用离线消息形式,客户端在线收到上面的notify时　使用请求拉取离线消息
function AllianceSystem.on_notify_receive_offmsg(msgtype)
    log("on_notify_receive_offmsg"..msgtype);
    AllianceSystem.SendAllOffMsgReq(msgtype); 
end

-- 接受邀请
function AllianceSystem.on_accept_join_carteam_rsp(ok, reason, carteam_id, offmsg_id, carteam) --need_leader_approve, carteam)
    local logStr = string.format("on_accept_join_carteam_rsp: ok:%s,reason:%s,carteam_id:%s, offmsg_id:%s",tostring(ok),tostring(reason),tostring(carteam_id), tostring(offmsg_id));
     log(logStr);
    --need_leader_approve为false就是队长邀请, true表示队员邀请，
    --带过来 team_id和false
    --如果拒绝的话 ok返回true   
    if ok == false then
        log("on_accept_join_carteam_rsp failed");
        AllianceUI.ProtocolErroCode(reason);

        --处理下一条离线消息
        AllianceRecruitUI.PopQueueMsgInfoTips();
        return;
    end

    --不等于空表示接受，
    if carteam ~= nil then
        --log_tree("on_accept_join_carteam_rsp",carteam);
        AllianceUI.ProtocolErroCode("cline_JoinCarTeam",carteam.name);
        --接受后清空消息列表，并且同步后台数据
        AllianceSystem.OffMsgInfo = {};
        --加入战队(1表示战队离线消息)后同步下离线消息，因为后台会清离线消息，前台有可能还会有。。所以.
        AllianceSystem.SendAllOffMsgReq(1);
        
        -- 构造车队数据结构
        AllianceSystem.ConstructAllianceData(carteam)
    end

    --处理下一条离线消息
    AllianceRecruitUI.PopQueueMsgInfoTips();
    --false表示队长邀请（不需要审批）
    --if need_leader_approve == false then
        --弹出提示
    --end

end

-- 队长审核
function AllianceSystem.on_approve_join_carteam_rsp(ok, reason, ispass, op_uid)
    if ok == false then 
        log("on_approve_join_carteam_rsp"..reason);
        AllianceUI.ProtocolErroCode(reason);
        return;
    end
    log("on_approve_join_carteam_rsp", reason);
    if ispass == true then
        --同意入队
        AllianceRecruitUI.RemoveApplyList(op_uid);
         log("on_approve_join_carteam_rsp true");
    elseif ispass == false then
        log("on_approve_join_carteam_rsp false");
        AllianceRecruitUI.RemoveApplyList(op_uid);
        --拒绝入队
    end


end

-- 队长审核后通知申请者（在线）
function AllianceSystem.on_notify_join_carteam(ok, reason, carteam)
end

-- 转移队长
function AllianceSystem.on_transfer_carteam_leader_rsp(ok, reason, carteam)
    log("on_transfer_carteam_leader_rsp"..tostring(ok)..tostring(reason))
    if not ok then 
        log("on_transfer_carteam_leader_rsp"..reason);
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    --log_tree("on_transfer_carteam_leader_rsp", carteam)
    
    --PopUpNoticeUI.ShowNewNotice("成功转移队长")
    PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301279").TextValue)

    --因为后台不会把申请列表带给前台，导致小红点无法显示,所以前台要自己请求申请列表
    AllianceRecruitUI.UpdateRepoint(0);

    
    --AllianceSystem.UpdateTeamCaptain(uid)

    --AllianceUI:RefreshTeamMainPanel()
end

-- 退出车队
function AllianceSystem.on_exit_carteam_rsp(ok, reason)
    log("AllianceSystem.on_exit_carteam_rsp" .. tostring(ok))
    if ok == false then 
        log("on_exit_carteam_rsp"..reason);
        AllianceUI.ProtocolErroCode(reason);
        return;
    end
    
    AllianceUI:CloseTeamMainPanel()
    AllianceRecruitUI.CloseUI()
    AllianceSystem.ReleaseData()
    
end

-- 踢出车队
function AllianceSystem.on_kickout_carteam_rsp(ok, reason, uid)
    log("on_kickout_carteam_rsp"..tostring(ok)..tostring(reason)..tostring(uid))
    if not ok then 
        log("on_kickout_carteam_rsp"..reason);
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    
    AllianceSystem.KickoutTeamMember(uid)
    
    --PopUpNoticeUI.ShowNewNotice("成功踢出车队")
    PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "301278").TextValue)
    LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData");        
end

-- 拉取车队信息
function AllianceSystem.on_query_carteam_rsp(ok, reason, carteam)
    log("AllianceSystem.on_query_carteam_req")
    
    if not ok then
        log("AllianceSystem.on_query_carteam_req not ok"..tostring(reason));
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    
    if carteam == nil then
        log("AllianceSystem.on_query_carteam_req no Team")
        if AllianceSystem.NeedOpenPanel then
            log("AllianceSystem.open no Team")
            AllianceUI:OpenNoTeamPanel()
            AllianceSystem.NeedOpenPanel = false
        end
    else
        --log_tree("AllianceSystem.on_query_carteam_req have Team", carteam)
        AllianceSystem.ConstructAllianceData(carteam);


        if AllianceSystem.IsLeader() == true then
            --列表请求
            AllianceSystem.SendGetApplyListReq();
        else
            --隐藏所有红点
            AllianceRecruitUI.UpdateRepoint(0);
        end

    end
    
end

--拉取申请列表返回，拉取概要
function AllianceSystem.on_get_carteam_applylist_rsp(ok, reason, member_list)
    log("on_get_carteam_applylist_rsp state:"..reason);

    if ok == true then

      --更新小红点  
       AllianceRecruitUI.UpdateRepoint(#member_list);

      --log_tree("on_get_carteam_applylist_rsp", member_list);
      if #member_list == 0 then
        AllianceRecruitUI.UpdateApplyList(true);
      else
         --批量拉取好友概要信息
        AllianceSystem.on_profile_req(member_list, "alliance_recruit");
      end  

    elseif ok == false then
      log("on_get_carteam_applylist_rsp is none");
      AllianceUI.ProtocolErroCode(reason);
      --清空小红点
      AllianceRecruitUI.UpdateRepoint(0);
       --错误码处理TODO   
    end 
end  

--车队成员列表概要信息
function AllianceSystem.on_profile_alliance_req(uidList, needRefresh)
   ProfileMgr.GetProfileList(uidList, AllianceSystem.on_profile_alliance_rsp, needRefresh);
end

function AllianceSystem.on_profile_alliance_rsp(role_basic_info_list)
    log("AllianceSystem.on_profile_alliance_rsp");
    AllianceSystem.OnTeamMemberProfileListReturn(role_basic_info_list)
end

--申请列表概要信息
function AllianceSystem.on_profile_recruitApply_req(uidList, needRefresh)
   ProfileMgr.GetProfileList(uidList, AllianceSystem.on_profile_recruitApply_rsp, needRefresh);
end

function AllianceSystem.on_profile_recruitApply_rsp(role_basic_info_list)
    log("AllianceSystem.on_profile_recruitApply_rsp");
    --派发事件更新UI
    EventSystem:postEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_RECRUIT_APPLIST,role_basic_info_list);  
end

--车队的概要信息请求
function AllianceSystem.on_profile_req(uidList, systemType)
    --log_tree("getprofileReq ", uidList);
    if "alliance" == systemType then  
        local timeDiff = os.time() - AllianceSystem.ProfileRefreshTimestamp;
        log(tostring(AllianceSystem.ProfileRefreshTimestamp).." " .. tostring(os.time()).. " ".."getprofileReq timeDiff: "..tostring(timeDiff))
        local needRefresh = false
        if (timeDiff >= AllianceSystem.FetchClickTimeLength) then
            AllianceSystem.ProfileRefreshTimestamp = os.time();
            needRefresh = true
        end
        AllianceSystem.on_profile_alliance_req(uidList, needRefresh);

    elseif "alliance_recruit" == systemType then

        AllianceSystem.on_profile_recruitApply_req(uidList, true)
    end

    --NetUtil.SendPkg("batch_get_profile_req", "", uidList, systemType)
end

--列表成员概要
--[[
function AllianceSystem.on_profile_rsp(listType, res, role_basic_info_list, systemType)
    -- 成员列表

    if "alliance" == systemType then     
        if "ok" ~= res then
            log("get team member profileRsp failed")
            return
        end
        
        AllianceSystem.OnTeamMemberProfileListReturn(role_basic_info_list)
    end

    -- 申请列表
    if "alliance_recruit" == systemType then        
        if "ok" ~= res then
            log("getprofileRsp failed");
            return;
        end
        log("AllianceSystem.on_profile_rsp");

        --派发事件更新UI
        EventSystem:postEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_RECRUIT_APPLIST,role_basic_info_list);  
    end
end
]]

--获得离线消息
function AllianceSystem.GetOffmsgInfoByIndex(index)
   local  locIndex = tonumber(index);
   for k,v in pairs(AllianceSystem.OffMsgInfo) do
       if locIndex == v.index then
            return v;
       end
   end

   return nil;
  
end

--移除离线消息
function AllianceSystem.RemoveOffMsgInfoByIndex(index)    
    local  msgInfo = AllianceSystem.GetOffmsgInfoByIndex(index)
    if msgInfo ~= nil then
       for k,v in pairs(AllianceSystem.OffMsgInfo) do
           if v.index == tonumber(index) then
                table.remove(AllianceSystem.OffMsgInfo,k);
           end
       end
    end
end

--拉取离线消息返回
function AllianceSystem.on_get_all_offmsg_rsp(offmsg_list)
    if offmsg_list == nil then
        log("on_get_all_offmsg_rsp is none");
        return;
    end 
    local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
    log("on_get_all_offmsg_rsp status:"..tostring(curStatus));
    if curStatus == "lobby" then       
   --[[
    离线消息数据结构
    offmsg:
       index:   索引
       uid:     uid
       type:    1 车队消息
       sendtime:    时间
       msg:     消息
        op    1 邀请; 2 通知审核完加入
        team_id   车队ID
        team_name 车队名称
        from_uid  邀请人uid
   ]]
   --log_tree("on_get_all_offmsg_rsp",offmsg_list);
   for k,v in pairs(offmsg_list) do    
            --去除重复的离线消息
           local hasMsg = AllianceSystem.GetOffmsgInfoByIndex(v.index);
           if hasMsg == nil then
             table.insert(AllianceSystem.OffMsgInfo,v);
           end
       end  
       AllianceRecruitUI.PopQueueMsgInfoTips();
    end


end

-- 绑定群
function AllianceSystem.on_bind_carteam_group_rsp(ok, reason, group_id)
    if not ok then
        log("AllianceSystem.on_bind_carteam_group_rsp not ok"..tostring(reason));
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    log("AllianceSystem.on_bind_carteam_group_rsp"..tostring(group_id))
    --DataMgr.ShowNoticeByString("绑定群成功")
    
    local prompt = FuncUtil.GetLocalizeResStr("101001");
    if (BP_Platform == BP_ENUM_PLAYFORM_WX) then
        DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301277").TextValue)
    elseif (BP_Platform == BP_ENUM_PLAYFORM_QQ) then
        CommonMessageBoxUI:ShowPanel(1, prompt, Client.GetTableData("LocalizeRes", "117050").TextValue);
    end
    
    BP_STRUCT_AllianceInfo.bind_group = tostring(group_id)
    AllianceUI:RefreshTeamMainPanel()
end

-- 解绑群
function AllianceSystem.on_unbind_carteam_group_rsp(ok, reason)
    if not ok then
        log("AllianceSystem.on_unbind_carteam_group_rsp not ok"..tostring(reason));
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    log("AllianceSystem.on_unbind_carteam_group_rsp"..tostring(group_id))
    --DataMgr.ShowNoticeByString("解绑群成功")
    DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301276").TextValue)
    BP_STRUCT_AllianceInfo.bind_group = "0"
    AllianceUI:RefreshTeamMainPanel()
end

-- 加入群
function AllianceSystem.on_join_carteam_group_rsp(ok, reason)
    if not ok then
        log("AllianceSystem.on_join_carteam_group_rsp not ok"..tostring(reason));
        AllianceUI.ProtocolErroCode(reason);
        return
    end
    log("AllianceSystem.on_join_carteam_group_rsp ok")
    
    if (BP_Platform == BP_ENUM_PLAYFORM_WX) then
            
    elseif (BP_Platform == BP_ENUM_PLAYFORM_QQ) then
        local prompt = FuncUtil.GetLocalizeResStr("101001");
        CommonMessageBoxUI:ShowPanel(1, prompt, Client.GetTableData("LocalizeRes", "117049").TextValue);
    end
        
    BP_Alliance_SelfJoinGroup = true
    AllianceUI:RefreshTeamMainPanel()
end

-- 查询成员与绑定群关系
function AllianceSystem.on_get_carteam_group_relation_rsp(ok, reason, relation)
    if not ok then
        log("AllianceSystem.on_get_carteam_group_relation_rsp not ok"..tostring(reason));
        --AllianceUI.ProtocolErroCode(reason);
        BP_Alliance_SelfJoinGroup = false
        return
    end
    log("AllianceSystem.on_get_carteam_group_relation_rsp"..tostring(relation))

    if (relation == 4) then
        BP_Alliance_SelfJoinGroup = false
    else
        BP_Alliance_SelfJoinGroup = true
    end
    AllianceUI:RefreshTeamMainPanel()
end

-- 车队队员变更
function AllianceSystem.on_notify_update_carteam_member(team_id, msgType, uid, member)
    --log_tree("AllianceSystem.on_notify_update_carteam_member".." "..tostring(team_id).." "..tostring(msgType).." " ..tostring(uid), member)
    
    if BP_STRUCT_AllianceInfo.aid ~= tostring(team_id) then
        log("AllianceSystem.on_notify_update_carteam_member Not my team")
       return
    end
    
    -- add
    if msgType == 1 then
        AllianceSystem.AddTeamMember(uid, member)
    end
    
    -- del
    if msgType == 2 then
        
        if tostring(uid) == DataMgr.roleData.uid then
            -- 自己被踢出队伍
            AllianceSystem.ReleaseData()
            AllianceUI:CloseTeamMainPanel()
            AllianceRecruitUI.CloseUI()
            
            PopUpNoticeUI.ShowNewNotice(Client.GetTableData("LocalizeRes", "111014").TextValue)
        else 
            AllianceSystem.KickoutTeamMember(uid)
            LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData")
        end
    
    end
    
    -- update
    if msgType == 3 then
        AllianceSystem.UpdateTeamMember(uid, member)
        LuaClassObj.HandleUIMessage(bp_alliance, "SetTeamData")
    end

    --派发事件，成员列表有更新
    EventSystem:postEvent(EVENTTYPE_ALLIANCE, EVENTID_ALLIANCE_UPDATE_MEMBER, msgType);
    
end

--通知队长有新的审批
function AllianceSystem.notify_join_carteam_rsp()
   --刷新小红点,传1表示要显示小红点
   log("notify_join_carteam_rsp");
   AllianceRecruitUI.UpdateRepoint(1);
end

-- 创建车队检查回复
function AllianceSystem.on_pre_create_carteam_rsp(ok, reason, min_level)
    log("on_pre_create_carteam_rsp")
    
    if not ok then
        log("AllianceSystem.on_pre_create_carteam_rsp not ok"..tostring(reason));
        AllianceUI.ProtocolErroCode(reason, min_level);
        return
    end
    
    AllianceUI:CloseNoTeamPanel()
    AllianceUI:OpenCreateTeamPanel()
end

--***************************************************平台工会群方法******************
--创建微信工会群
function AllianceSystem.createWechatGroup(params)
	if params == nil then
		return;
	end
	params.unionId = params.unionId;
	--params.chatRoomName = params.chatRoomName or "工会群";
    local allianceGroup = Client.GetTableData("LocalizeRes", "301275").TextValue;
    params.chatRoomName = params.chatRoomName or allianceGroup;
    
	params.chatRoomNickName = params.chatRoomNickName or DataMgr.roleData.nickName;
	log("create wechat group!");
	Client.WechatCreateGroup(NetInterface, params.unionId, params.chatRoomName, params.chatRoomNickName);
end

--加入微信工会群
function AllianceSystem.joinWechatGroup(params)
	if params == nil then
		return;
	end
	params.unionId = params.unionId;
	params.chatRoomNickName = params.chatRoomNickName or DataMgr.roleData.nickName;
	log("join wechat group!");
	Client.WechatJoinGroup(NetInterface, params.unionId, params.chatRoomNickName);
end

--查询微信工会群
function AllianceSystem.queryWechatGroup(params)
	if params == nil then
		return;
	end
	params.unionId = params.unionId;
	params.openIdList = params.openIdList or DataMgr.roleData.openID;
	log("query wechat group!"..tostring(params.unionId).. "openidList".. params.openIdList);
	Client.WechatQueryGroup(NetInterface, params.unionId, params.openIdList);
end

--工会群回调
--SnsAction见MsdkAdapterPublicDefine的SnsAction
--groupInfo中的错误码参见http://wiki.msdk.qq.com/Unity/const.html#Unity_GroupRet eFlag
function AllianceSystem.OnGroupNotify(snsAction)
	log("onGroupResult snsAction" .. tostring(snsAction));
	local groupInfo = Client.GetGroupInfo(NetInterface, tonumber(snsAction));
	log_tree("onGroupResult groupInfo", groupInfo);
	if groupInfo == nil then
		log("AllianceSystem OnGroupNotify is null!");
		return;
	end
	--local snsAction = groupInfo["SnsAction"];
	local flag = tonumber(groupInfo["Flag"]);
	local errorCode = groupInfo["ErrorCode"];
	local platform = groupInfo["Platform"];
	local desc = groupInfo["Desc"];
    local wechatGroupInfo = groupInfo["wechatGroupInfo"]
    
	if flag ~= 0 then
		log("工会群功能失败，错误码为" .. tostring(flag));
        
        if snsAction ~= 111 then
            if flag == -1 then
                flag = errorCode
            end
            AllianceUI.ProtocolErroCode("SnsGroupError", flag)
            return
        end
	end
    
	if snsAction == 112 then
		--创建微信工会
		log("AllianceSystem OnGroupNotify create wechat group");
        AllianceSystem.SendBindGroup(BP_STRUCT_AllianceInfo.aid)
        
	elseif snsAction == 113 then
		--加入微信工会
		log("AllianceSystem OnGroupNotify join wechat group");
        --DataMgr.ShowNoticeByString("成功加入微信群"); 
        DataMgr.ShowNoticeByID(117046);  
        AllianceSystem.QueryWxGroupStatus()
        
	elseif snsAction == 111 then
		--查询微信工会
		log("AllianceSystem OnGroupNotify query wechat group");
        
        AllianceSystem.RefreshWxGroupStatus(flag, wechatGroupInfo)
	end
end
--***************************************************平台工会群方法******************

--***************************************************跨平台包装方法******************
function AllianceSystem.createGroup(params)
	log_tree("createGroup params", params);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		AllianceSystem.createWechatGroup(params);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		log("create qq Group is not supported yet");
	end
end
--***************************************************跨平台包装方法******************

--[[网络回调]]--
-- 创建车队
s2c["create_carteam_rsp"] = AllianceSystem.on_create_carteam_rsp;
-- 修改车队
s2c["change_carteam_rsp"] = AllianceSystem.on_change_carteam_rsp;
-- 更新车队(nil解散)
s2c["notify_update_carteam_info"] = AllianceSystem.on_notify_update_carteam_info;
-- 邀请加入车队
s2c["invite_join_carteam_rsp"] = AllianceSystem.on_invite_join_carteam_rsp;
-- 接受邀请
s2c["accept_join_carteam_rsp"] = AllianceSystem.on_accept_join_carteam_rsp;
-- 队长审核
s2c["approve_join_carteam_rsp"] = AllianceSystem.on_approve_join_carteam_rsp;
-- 队长审核后通知申请者（在线）
s2c["notify_join_carteam"] = AllianceSystem.on_notify_join_carteam;
-- 转移队长
s2c["transfer_carteam_leader_rsp"] = AllianceSystem.on_transfer_carteam_leader_rsp;
-- 退出车队
s2c["exit_carteam_rsp"] = AllianceSystem.on_exit_carteam_rsp;
-- 踢出车队
s2c["kickout_carteam_rsp"] = AllianceSystem.on_kickout_carteam_rsp;
-- 拉取车队信息
s2c["query_carteam_rsp"] = AllianceSystem.on_query_carteam_rsp;

--拉取申请列表
--c2s.get_carteam_apply_list_req()
--s2c.get_carteam_apply_list_rsp(ok, reason, member_list);
s2c["get_carteam_apply_list_rsp"] = AllianceSystem.on_get_carteam_applylist_rsp;
--通知有消息了
s2c["notify_receive_offmsg"] = AllianceSystem.on_notify_receive_offmsg;
--队长、队员邀请你了
s2c["get_all_offmsg_rsp"] = AllianceSystem.on_get_all_offmsg_rsp; 
-- 通知队长有新的审批
s2c["notify_join_carteam_rsp"] = AllianceSystem.notify_join_carteam_rsp; 

-- 绑定群
s2c["bind_carteam_group_rsp"] = AllianceSystem.on_bind_carteam_group_rsp; 
-- 解绑群
s2c["unbind_carteam_group_rsp"] = AllianceSystem.on_unbind_carteam_group_rsp; 
-- 车队队员变更  type 1 add; 2 del; 3 update
s2c["notify_update_carteam_member"] = AllianceSystem.on_notify_update_carteam_member; 
-- 创建车队前检查
s2c["pre_create_carteam_rsp"] = AllianceSystem.on_pre_create_carteam_rsp; 
-- 加入绑定群
s2c["join_carteam_group_rsp"] = AllianceSystem.on_join_carteam_group_rsp;
-- 查询成员与绑定群关系
s2c["get_carteam_group_relation_rsp"] = AllianceSystem.on_get_carteam_group_relation_rsp;