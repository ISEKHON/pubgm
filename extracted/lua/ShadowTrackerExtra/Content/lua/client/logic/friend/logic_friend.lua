-- 好友相关逻辑
FriendSystem = FriendSystem or
{
	FetchTimer = 0.0;			----每隔10分钟更新一下好友数据
	FetchTimelength = 600;		----每隔10分钟更新一下好友数据
	FetchTimeStamp = 0;			----点击UI的话，2分钟内更新一下好友数据
	FetchClickTimeLength = 120;	----点击UI的话，2分钟内更新一下好友数据
	HasInit = false;
	NeedRefresh = false;
}

ID_PLAT_FRIENDLIST={}
ID_INNER_FRIENDLIST={}
ID_RECENT_TEAMMATELIST={}

BP_ARRAY_All_Friend_Profile = {}
BP_ARRAY_Inner_Friend_Profile = {}
BP_ARRAY_Plat_Friend_Profile = {}

BP_ARRAY_Search_Friend_Profile = {}
BP_ARRAY_Apply_Friend_Profile = {}
BP_ARRAY_Friend_ID_Blacklist = {}

FRIEND_AGREE_UID = 0
FRIEND_REFUSE_UID = 0

-- 标识符均为true表示好友的概要，在线及组队信息均已拿到（注意拿到汇总数据后重置标识符）
FLAG_PROFILE_ALL = false
FLAG_ONLINE_AND_TEAMINFO_ALL = false

function FriendSystem.OnRefreshFriendProfile()
	log("eventlobbyfriendgetfriendprofile")
	if (FriendSystem.HasInit == true) then
		if (bp_lobby ~= nil) then
			local timeDiff = os.time() - FriendSystem.FetchTimeStamp;
			log("timeDiff2: "..tostring(timeDiff))
			local curStatus = string.lower(LuaClassObj.GetGameStatus(bp_lobby));
			if curStatus == "lobby" then
				FriendSystem.FetchTimeStamp = os.time()
				FriendSystem.getServerFriendIDList()
				log("eventlobbyfriendgetfriendprofile getserverfriendidlist")
			end
		end
	end
end

function FriendSystem.FetchFriendList()
	local timeDiff = os.time() - FriendSystem.FetchTimeStamp;
	if (timeDiff >= FriendSystem.FetchClickTimeLength) then
		FriendSystem.FetchTimeStamp = os.time();
		FriendSystem.getServerFriendIDList();
		log("[HHF]FriendSystem.FetchFriendList, timeDiff = " .. tostring(timeDiff) .. " >= " .. tostring(FriendSystem.FetchClickTimeLength));
	else
		FriendSystem.getFriendIDList();
		log("[HHF]FriendSystem.FetchFriendList, timeDiff = " .. tostring(timeDiff) .. " < " .. tostring(FriendSystem.FetchClickTimeLength));
	end
end

function FriendSystem.CheckFetchFriendList()
	log("FriendSystem.CheckFetchFriendList");
	local timeDiff = os.time() - FriendSystem.FetchTimeStamp;
	log("timeDiff3: "..tostring(timeDiff))
	if (timeDiff >= FriendSystem.FetchClickTimeLength) then
		FriendSystem.FetchTimeStamp = os.time();
		FriendSystem.getServerFriendIDList();
	end
end

function FriendSystem.getServerFriendIDList()
	log("[HHF]getServerFriendIDList");
	FriendSystem.NeedRefresh = true;
	FriendSystem.getFriendIDList();
	LuaClassObj.HandleUIMessage(bp_lobby, "UpdateFriendList");
end

-- 登出清理数据，关闭好友界面
local function BackLoginEventHandler(eventType, eventID, vars)
    if eventType ~= EVENTTYPE_LOGIN then
      return
    end
    if eventID == EVENTID_BACKLOGIN then 
		FriendSystem.Quit()
    end
end

function FriendSystem.ResetData()
	log("friendsystem resetdata")
	
	ID_PLAT_FRIENDLIST={}
    ID_INNER_FRIENDLIST={}
	ID_RECENT_TEAMMATELIST={}

	BP_ARRAY_All_Friend_Profile = {}
	BP_ARRAY_Inner_Friend_Profile = {}
	BP_ARRAY_Plat_Friend_Profile = {}

	BP_ARRAY_Search_Friend_Profile = {}
	BP_ARRAY_Apply_Friend_Profile = {}
	BP_ARRAY_Friend_ID_Blacklist = {}

	FRIEND_AGREE_UID = 0
	FRIEND_REFUSE_UID = 0
	
	-- 标识符均为true表示好友的概要，在线及组队信息均已拿到（注意拿到汇总数据后重置标识符）
	FLAG_PROFILE_ALL = false
	FLAG_ONLINE_AND_TEAMINFO_ALL = false
	
	FriendSystem.NeedRefresh = false
end

function FriendSystem.Quit()
	EventSystem:unregistEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN,BackLoginEventHandler)
	FriendSystem.ResetData()
	LobbyFriendUI:Hide()
end

-- 断线重连重新拉取好友数据（好友申请，在线和组队状态）
function FriendSystem.GetFriendDataRequest()
	log("[HHF]FriendSystem.GetFriendDataRequest");
	FriendSystem.ResetData()
    --请求好友列表
	FriendSystem.getFriendIDList()
	FriendSystem.get_black_list_req()
	FriendSystem.get_addfriend_reqlist_req()
end

function FriendSystem.Enter()
	log("[HHF]FriendSystem.Enter()");
	FriendSystem.HasInit = true;
	LuaClassObj.HandleUIMessage(bp_lobby, "UpdateFriendList");
	FriendSystem.FetchTimeStamp = os.time();
	
	EventSystem:unregistEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN,BackLoginEventHandler)
	EventSystem:registEvent(EVENTTYPE_LOGIN,EVENTID_BACKLOGIN,BackLoginEventHandler)
	
	--游戏返回大厅,拉取数据
	FriendSystem.getFriendIDList()
	FriendSystem.get_black_list_req()
	FriendSystem.get_addfriend_reqlist_req()
	
	--进入大厅拉取最近组队数据
	FriendSystem.getRecentTeammate()
end
-----------------------------------------------------------请求好友id列表----------------------------------------
function FriendSystem.getFriendIDList()
	log("[HHF]getFriendIDList, Send get_all_friendlist_req.")
	-- 所有好友
	FLAG_PROFILE_ALL = false
	FLAG_ONLINE_AND_TEAMINFO_ALL = false
	
	-- 点击好友按钮清理原始数据
	--BP_ARRAY_All_Friend_Profile = {}
	
	NetUtil.SendPkg("get_all_friendlist_req")
	FriendSystem.FetchTimer = 0.0;
end
-----------------------------------------------------------请求好友id列表----------------------------------------

-----------------------------------------------------------批量请求组队状态--------------------------------------
-- 批量请求组队状态
function FriendSystem.batchGetTeamInfoList()
	local list = FriendSystem.UnionFriendIDList(ID_INNER_FRIENDLIST,ID_PLAT_FRIENDLIST)
	
	if next(list) == nil then
		return
	end	
	NetUtil.SendPkg("batch_get_group_and_online_req","updateteam",list)
end
-----------------------------------------------------------批量请求组队状态--------------------------------------

-----------------------------------------------------------回包好友id列表----------------------------------------
-- 所有好友id列表
function FriendSystem.on_get_all_friendlist_rsp(res,friendlist)
	--log_tree("get_all_friendlist_rsq", friendlist)
	log("[HHF]on_get_all_friendlist_rsp, res = " .. tostring(res))
	ID_PLAT_FRIENDLIST={}
    ID_INNER_FRIENDLIST={}
	
	local curTime = FuncUtil.GetServerTimeInSec()
	if res == "ok" then
		if next(friendlist) ~= nil then
			--平台好友数据
			for k,v in pairs(friendlist.plat_list) do
				table.insert(ID_PLAT_FRIENDLIST,k)
				local has = false
				for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
					if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(k) then
						BP_ARRAY_All_Friend_Profile[i].lastInviteTime = v.lastInviteTime
						-- 平台好友亲密度默认值为0，如果也是游戏好友，再赋值下亲密度
						BP_ARRAY_All_Friend_Profile[i].intimacy = 0
						BP_ARRAY_All_Friend_Profile[i].remarks_name = v.remarks_name
						
						if v.presented ~= nil and tonumber(v.presented) == 0 then
							BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime = 0
							BP_ARRAY_All_Friend_Profile[i].bPresentedCoin = 0
							
						else
							BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime = curTime
							BP_ARRAY_All_Friend_Profile[i].bPresentedCoin = 1
						end
						
						has = true
						break
					end
				end
				if not has then
					local profile = {gid=tostring(k),intimacy=0,lastInviteTime=v.lastInviteTime,remarks_name=v.remarks_name}
					
					if v.presented ~= nil and tonumber(v.presented) == 0 then
						profile.lastPresentCoinTime = 0
						profile.bPresentedCoin = 0
					else
						profile.lastPresentCoinTime = curTime
						profile.bPresentedCoin = 1
					end
					
					table.insert(BP_ARRAY_All_Friend_Profile,profile)
				end
			end
		
			--游戏好友数据
			for k,v in pairs(friendlist.inner_list) do
				table.insert(ID_INNER_FRIENDLIST,k)
				local has = false
				for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
					if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(k) then
						BP_ARRAY_All_Friend_Profile[i].intimacy = v.intimacy
						
						if v.presented ~= nil and tonumber(v.presented) == 0 then
							BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime = 0
							BP_ARRAY_All_Friend_Profile[i].bPresentedCoin = 0
							
						else
							BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime = curTime
							BP_ARRAY_All_Friend_Profile[i].bPresentedCoin = 1
						end
						
						has = true
						break
					end
				end
				if not has then
					local profile = {gid=tostring(k),intimacy=v.intimacy}
					if v.presented ~= nil and tonumber(v.presented) == 0 then
						profile.lastPresentCoinTime = 0
						profile.bPresentedCoin = 0
					else
						profile.lastPresentCoinTime = curTime
						profile.bPresentedCoin = 1
					end
					table.insert(BP_ARRAY_All_Friend_Profile,profile)
				end
			end
			--log_tree("[HHF]BP_ARRAY_All_Friend_Profile = ", BP_ARRAY_All_Friend_Profile)

			local list = FriendSystem.UnionFriendIDList(ID_INNER_FRIENDLIST,ID_PLAT_FRIENDLIST)
			--log_tree("union all friend list:",list)
			
			if next(list) == nil or ProfileMgr == nil then
				log("[HHF]friendIDlist is nil!")
				LobbyFriendUI:UpdatePlatList()
				LobbyFriendUI:UpdateInnerList()
				return
			end
			
			if FriendSystem.NeedRefresh == true then
				ProfileMgr.GetFriendProfileList(list,FriendSystem.on_batch_get_all_profile_rsp,true)
				FriendSystem.NeedRefresh = false
				log("friendsystem needrefresh true")
			else
				ProfileMgr.GetFriendProfileList(list,FriendSystem.on_batch_get_all_profile_rsp)
				log("friendsystem needrefresh false")
			end
			NetUtil.SendPkg("batch_get_group_and_online_req", "all", list)
			log("[HHF]Send batch_get_group_and_online_req!")
		end
	else
		log("get_all_friendlist_rsq fail:"..res)
	end
end
-----------------------------------------------------------回包好友id列表----------------------------------------

-----------------------------------------------------------合并uid列表-------------------------------------------
-- 合并两个uid列表
function FriendSystem.UnionFriendIDList(list1,list2)
	local list = {}
	for i = #list1,1,-1 do
		table.insert(list,list1[i])
	end

	for i = #list2,1,-1 do
		local has = false
		for j = #list1,1,-1 do
			if tonumber(list1[j]) == tonumber(list2[i]) then
				has = true
				break
			end
		end

		if not has then
			table.insert(list,list2[i])
		end
	end
	return list
end
-----------------------------------------------------------合并uid列表-------------------------------------------

-----------------------------------------------------------请求最近组队队友----------------------------------------
function FriendSystem.getRecentTeammate()
	log("getRecentTeammate")
	
	NetUtil.SendPkg("get_recent_teammate_req")
end
-----------------------------------------------------------请求最近组队队友----------------------------------------

-----------------------------------------------------------回包最近组队队友----------------------------------------
function FriendSystem.on_get_recent_teammate_rsp(list)
	--log_tree("on_get_recent_teammate_rsp list",list)
	log("on_get_recent_teammate_rsp")
	
	if next(list) == nil then
		log("on_get_recent_teammate_rsp list is nil")
		return
	end

	ID_RECENT_TEAMMATELIST = {}
	BP_ARRAY_Recent_Teammate_Profile = {}
	local idlist = {}
	
	for i = 1,#list,1 do
		table.insert(ID_RECENT_TEAMMATELIST,list[i].uid)
		local profile = {gid = tostring(list[i].uid),endtime = list[i].endtime,endtimeStr = FriendSystem.FormatTime(list[i].endtime,""),rank=list[i].rank,total=list[i].total,score=tostring(list[i].score),kill=list[i].kill,mode=list[i].mode}
		if list[i].mode == TEAMUP_TEAM_TYPE_SOLO then
			profile.modeStr = DataMgr.GetMsgByID(110049)
		elseif list[i].mode == TEAMUP_TEAM_TYPE_DOUBLE then
			profile.modeStr = DataMgr.GetMsgByID(110050)
		elseif list[i].mode == TEAMUP_TEAM_TYPE_QUAD then
			profile.modeStr = DataMgr.GetMsgByID(110051)
		end
		table.insert(BP_ARRAY_Recent_Teammate_Profile,profile)
		table.insert(idlist,list[i].uid)
	end
	
	--log_tree("BP_ARRAY_Recent_Teammate_Profile",BP_ARRAY_Recent_Teammate_Profile)
		
	ProfileMgr.GetProfileList(idlist,FriendSystem.on_batch_get_recentteammate_profile_rsp)
	NetUtil.SendPkg("batch_get_group_and_online_req", "recentteammate", idlist)
end
-----------------------------------------------------------回包最近组队队友----------------------------------------

-----------------------------------------------------------返回概要信息----------------------------------------
--获取所有好友概要数据
function FriendSystem.on_batch_get_all_profile_rsp(profileList)
	--log_tree("[HHF]on_batch_get_all_profile_rsp = ", profileList)
	--log("on_batch_get_all_profile_rsp");
	for k,v in pairs(profileList) do
		local has = false
		for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(v.uid) then
				BP_ARRAY_All_Friend_Profile[i].nickName = v.nickName
				BP_ARRAY_All_Friend_Profile[i].level = v.level
				BP_ARRAY_All_Friend_Profile[i].vipLevel = v.vipLevel
				BP_ARRAY_All_Friend_Profile[i].picUrl = v.picUrl
				BP_ARRAY_All_Friend_Profile[i].platName = v.platName
				BP_ARRAY_All_Friend_Profile[i].sex = v.sex
				BP_ARRAY_All_Friend_Profile[i].lastOnlineTime = v.lastOnlineTime
				BP_ARRAY_All_Friend_Profile[i].lastOnlineTimeStr = FriendSystem.FormatTime(v.lastOnlineTime,"online")
				BP_ARRAY_All_Friend_Profile[i].lastLoginTime = v.lastLoginTime
				BP_ARRAY_All_Friend_Profile[i].exp = v.exp
				--[[if v.segment_info then
					BP_ARRAY_All_Friend_Profile[i].segment_info_solo = v.segment_info[1]
					BP_ARRAY_All_Friend_Profile[i].segment_info_duo = v.segment_info[2]
					BP_ARRAY_All_Friend_Profile[i].segment_info_squad = v.segment_info[3]
                end]]
                ----------------------------------------intl modify--------------------------------------
                BP_ARRAY_All_Friend_Profile[i].AllSegment_Info = v.segment_info;
                for k, v in pairs(BP_ARRAY_All_Friend_Profile[i].AllSegment_Info) do
                        BP_ARRAY_All_Friend_Profile[i].segment_info_solo  = BP_ARRAY_All_Friend_Profile[i].AllSegment_Info[k][1];
                        BP_ARRAY_All_Friend_Profile[i].segment_info_duo   = BP_ARRAY_All_Friend_Profile[i].AllSegment_Info[k][2];
                        BP_ARRAY_All_Friend_Profile[i].segment_info_squad = BP_ARRAY_All_Friend_Profile[i].AllSegment_Info[k][3];
                    break;
                end
                
                BP_ARRAY_All_Friend_Profile[i].segment_info_solo, BP_ARRAY_All_Friend_Profile[i].segment_info_duo,BP_ARRAY_All_Friend_Profile[i].segment_info_squad =  FuncUtil.GetMaxSegement(BP_ARRAY_All_Friend_Profile[i].AllSegment_Info);
                ----------------------------------------intl modify--------------------------------------
                
				BP_ARRAY_All_Friend_Profile[i].startup_type = GetSafeNumber(v.startup_type)
				BP_ARRAY_All_Friend_Profile[i].qq_vip = GetSafeNumber(v.qq_vip)
				BP_ARRAY_All_Friend_Profile[i].cur_avatar_box_id = v.cur_avatar_box_id
				has = true
				break
			end
		end

		if not has then
			local data = {}
			data.gid = v.uid
			data.friendType = 0
			data.nickName = v.nickName
			data.level = v.level
			data.vipLevel = v.vipLevel
			data.picUrl = v.picUrl
			data.platName = v.platName
			data.sex = v.sex
			data.lastOnlineTime = v.lastOnlineTime
			data.lastOnlineTimeStr = FriendSystem.FormatTime(v.lastOnlineTime,"online")
			data.lastLoginTime = v.lastLoginTime
			data.exp = v.exp
             ----------------------------------------intl modify--------------------------------------
			--[[if v.segment_info then
				data.segment_info_solo = v.segment_info[1]
				data.segment_info_duo = v.segment_info[2]
				data.segment_info_squad = v.segment_info[3]
            end]]
            
             data.AllSegment_Info = v.segment_info;
             for k, v in pairs(data.AllSegment_Info) do
                   data.segment_info_solo   = data.AllSegment_Info[k][1];
                   data.segment_info_duo    = data.AllSegment_Info[k][2];
                   data.segment_info_squad = data.AllSegment_Info[k][3];
                   break;
             end
             
             data.segment_info_solo, data.segment_info_duo,data.segment_info_squad =  FuncUtil.GetMaxSegement(data.AllSegment_Info);
             ----------------------------------------intl modify--------------------------------------
			data.startup_type = GetSafeNumber(v.startup_type)
			data.qq_vip = GetSafeNumber(v.qq_vip)
			data.cur_avatar_box_id = v.cur_avatar_box_id
			data.bPresentedCoin = 0
			data.lastPresentCoinTime = 0
			table.insert(BP_ARRAY_All_Friend_Profile, data)
		end
    end
	
	--刷新界面，通知其他系统更新
	FLAG_PROFILE_ALL = true
	FriendSystem.NotifyPullFriendList()
end

-- 获取最近组队队友概要信息
function FriendSystem.on_batch_get_recentteammate_profile_rsp(profileList)
	--log_tree("recentteammate profile:",profileList)
	
	for k,v in pairs(profileList) do
		for kk,vv in pairs(BP_ARRAY_Recent_Teammate_Profile) do
			if tonumber(vv.gid) == tonumber(v.uid) then
				vv.nickName = v.nickName
				vv.level = v.level
				vv.picUrl = v.picUrl
				vv.vipLevel = v.vipLevel
				vv.platName = v.platName
				vv.sex = v.sex
				vv.lastOnlineTime = v.lastOnlineTime
				vv.lastLoginTime = v.lastLoginTime
				vv.exp = v.exp
                 ----------------------------------------intl modify--------------------------------------
                 vv.AllSegment_Info = v.segment_info;
                 for kseg, vseg in pairs(vv.AllSegment_Info) do
                       vv.segment_info_solo   = vv.AllSegment_Info[kseg][1];
                       vv.segment_info_duo    = vv.AllSegment_Info[kseg][2];
                       vv.segment_info_squad = vv.AllSegment_Info[kseg][3];
                       break;
                 end
                 vv.segment_info_solo, vv.segment_info_duo, vv.segment_info_squad =  FuncUtil.GetMaxSegement(vv.AllSegment_Info);
                --[[
				vv.segment_info_solo = v.segment_info[1]
				vv.segment_info_duo = v.segment_info[2]
				vv.segment_info_squad = v.segment_info[3]
                ]]
                 ----------------------------------------intl modify--------------------------------------
				vv.startup_type = GetSafeNumber(v.startup_type)
				vv.qq_vip = GetSafeNumber(v.qq_vip)
				vv.cur_avatar_box_id = v.cur_avatar_box_id
			end
		end
	end
			
	table.sort(BP_ARRAY_Recent_Teammate_Profile,SortRecentFunc)
	--log_tree("BP_ARRAY_Recent_Teammate_Profile",BP_ARRAY_Recent_Teammate_Profile)
end

-----------------------------------------------------------查找好友----------------------------------------
--通过名字查找uid 精确查找 名字必须输全
function FriendSystem.find_uid_by_name_req(name)
    log("find_uid_by_name_req:"..name)
    NetUtil.SendPkg("find_uid_by_name_req", name)
end

--查找回包
function FriendSystem.on_find_uid_by_name_rsp(res, name, uids)
    log("on_find_uid_by_name_rsp:"..res.." name:"..name)
	if res == "ok" then
		log("search success")
		ProfileMgr.GetProfileList(uids,FriendSystem.on_batch_get_search_profile_rsp)
	else
		log("search fail")
		LobbyFriendUI:ShowSearchFailResult()
	end
end
-----------------------------------------------------------查找好友----------------------------------------

--获取要添加的玩家的概要数据
function FriendSystem.on_batch_get_search_profile_rsp(profileList)
	--log_tree("search profile:", profileList)
	
	if next(profileList) == nil then
		log("search empty")
		LobbyFriendUI:ShowSearchFailResult()
		return
	end
			
    BP_ARRAY_Search_Friend_Profile = {}
	for k,v in pairs(profileList) do
		local has = false
		for i = #BP_ARRAY_Search_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_Search_Friend_Profile[i].gid) == tonumber(v.uid) then
				BP_ARRAY_Search_Friend_Profile[i].nickName = v.nickName
				BP_ARRAY_Search_Friend_Profile[i].level = v.level
				BP_ARRAY_Search_Friend_Profile[i].picUrl = v.picUrl
				BP_ARRAY_Search_Friend_Profile[i].vipLevel = v.vipLevel
				BP_ARRAY_Search_Friend_Profile[i].platName = v.platName
				BP_ARRAY_Search_Friend_Profile[i].sex = v.sex
				BP_ARRAY_Search_Friend_Profile[i].lastOnlineTime = v.lastOnlineTime
				BP_ARRAY_Search_Friend_Profile[i].lastLoginTime = v.lastLoginTime
				BP_ARRAY_Search_Friend_Profile[i].exp = v.exp
                ----------------------------------------intl modify--------------------------------------               
                --[[
				BP_ARRAY_Search_Friend_Profile[i].segment_info_solo = v.segment_info[1]
				BP_ARRAY_Search_Friend_Profile[i].segment_info_duo = v.segment_info[2]
				BP_ARRAY_Search_Friend_Profile[i].segment_info_squad = v.segment_info[3]
                ]]
                BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info = v.segment_info; 
                for k, v in pairs(BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info) do
                    BP_ARRAY_Search_Friend_Profile[i].segment_info_solo   = BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info [k][1];
                    BP_ARRAY_Search_Friend_Profile[i].segment_info_duo    = BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info [k][2];
                    BP_ARRAY_Search_Friend_Profile[i].segment_info_squad = BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info [k][3];
                    break;
                end
                BP_ARRAY_Search_Friend_Profile[i].segment_info_solo, BP_ARRAY_Search_Friend_Profile[i].segment_info_duo, BP_ARRAY_Search_Friend_Profile[i].segment_info_squad =  FuncUtil.GetMaxSegement(BP_ARRAY_Search_Friend_Profile[i].AllSegment_Info);
                ----------------------------------------intl modify--------------------------------------
				BP_ARRAY_Search_Friend_Profile[i].startup_type = GetSafeNumber(v.startup_type)
				BP_ARRAY_Search_Friend_Profile[i].qq_vip = GetSafeNumber(v.qq_vip)
				BP_ARRAY_Search_Friend_Profile[i].cur_avatar_box_id = v.cur_avatar_box_id
				has = true
				break
			end
		end

		if not has then
			local data = {}
			data.gid = v.uid
			data.nickName = v.nickName
			data.level = v.level
			data.picUrl = v.picUrl
			data.vipLevel = v.vipLevel
			data.platName = v.platName
			data.sex = v.sex
			data.lastOnlineTime = v.lastOnlineTime
			data.lastLoginTime = v.lastLoginTime
			data.exp = v.exp
           
            ----------------------------------------intl modify--------------------------------------
            --[[
			data.segment_info_solo = v.segment_info[1]
			data.segment_info_duo = v.segment_info[2]
			data.segment_info_squad = v.segment_info[3]
            ]]
             data.AllSegment_Info = v.segment_info;
             for kseg, v in pairs(data.AllSegment_Info) do
                   data.segment_info_solo   = data.AllSegment_Info[kseg][1];
                   data.segment_info_duo    = data.AllSegment_Info[kseg][2];
                   data.segment_info_squad = data.AllSegment_Info[kseg][3];
                   break;
             end
             data.segment_info_solo,  data.segment_info_duo,  data.segment_info_squad =  FuncUtil.GetMaxSegement( data.AllSegment_Info );
            ----------------------------------------intl modify--------------------------------------
            
			data.startup_type = GetSafeNumber(v.startup_type)
			data.qq_vip = GetSafeNumber(v.qq_vip)
			data.cur_avatar_box_id = v.cur_avatar_box_id
			table.insert(BP_ARRAY_Search_Friend_Profile, data)
		end
    end
	--log_tree("BP_ARRAY_Search_Friend_Profile:", BP_ARRAY_Search_Friend_Profile)
    --刷新查找列表
	LobbyFriendUI:UpdateSearchList()
end

--请求黑名单拉取陌生人概要数据
function FriendSystem.on_batch_get_blacklist_profile_rsp(profileList)
	--log_tree("black profile:",profileList)
	
	for k,v in pairs(profileList) do
		local has = false
		for i= #BP_ARRAY_Blacklist_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_Blacklist_Friend_Profile[i].gid) == tonumber(v.uid) then
				BP_ARRAY_Blacklist_Friend_Profile[i].nickName = v.nickName
				BP_ARRAY_Blacklist_Friend_Profile[i].level = v.level
				BP_ARRAY_Blacklist_Friend_Profile[i].picUrl = v.picUrl
				BP_ARRAY_Blacklist_Friend_Profile[i].vipLevel = v.vipLevel
				BP_ARRAY_Blacklist_Friend_Profile[i].platName = v.platName
				BP_ARRAY_Blacklist_Friend_Profile[i].sex = v.sex
				BP_ARRAY_Blacklist_Friend_Profile[i].lastOnlineTime = v.lastOnlineTime
				BP_ARRAY_Blacklist_Friend_Profile[i].lastLoginTime = v.lastLoginTime
				BP_ARRAY_Blacklist_Friend_Profile[i].exp = v.exp
                ----------------------------------------intl modify--------------------------------------            
                --[[
				BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_solo = v.segment_info[1]
				BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_duo = v.segment_info[2]
				BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_squad = v.segment_info[3]
                ]]
                BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info = v.segment_info; 
                for k, v in pairs(BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info) do
                    BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_solo   = BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info [k][1];
                    BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_duo    = BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info [k][2];
                    BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_squad = BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info [k][3];
                    break;
                end
                BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_solo,  BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_duo,  BP_ARRAY_Blacklist_Friend_Profile[i].segment_info_squad =  FuncUtil.GetMaxSegement( BP_ARRAY_Blacklist_Friend_Profile[i].AllSegment_Info );
                ----------------------------------------intl modify--------------------------------------
				BP_ARRAY_Blacklist_Friend_Profile[i].startup_type = GetSafeNumber(v.startup_type)
				BP_ARRAY_Blacklist_Friend_Profile[i].qq_vip = GetSafeNumber(v.qq_vip)
				BP_ARRAY_Blacklist_Friend_Profile[i].cur_avatar_box_id = v.cur_avatar_box_id
				has = true
				break
			end
		end
				
		if not has then
			local data = {}
			data.gid = v.uid
			data.nickName = v.nickName
			data.level = v.level
			data.picUrl = v.picUrl
			data.vipLevel = v.vipLevel
			data.platName = v.platName
			data.sex = v.sex
			data.lastOnlineTime = v.lastOnlineTime
			data.lastLoginTime = v.lastLoginTime
			data.exp = v.exp
            ----------------------------------------intl modify--------------------------------------
            --[[
			data.segment_info_solo = v.segment_info[1]
			data.segment_info_duo = v.segment_info[2]
			data.segment_info_squad = v.segment_info[3]
            ]]
            data.AllSegment_Info = v.segment_info;
            for kseg, v in pairs(data.AllSegment_Info) do
                 data.segment_info_solo   = data.AllSegment_Info[kseg][1];
                 data.segment_info_duo    = data.AllSegment_Info[kseg][2];
                 data.segment_info_squad = data.AllSegment_Info[kseg][3];
                 break;
            end
            data.segment_info_solo,  data.segment_info_duo,  data.segment_info_squad =  FuncUtil.GetMaxSegement( data.AllSegment_Info );
             ----------------------------------------intl modify--------------------------------------
			data.startup_type = GetSafeNumber(v.startup_type)
			data.qq_vip = GetSafeNumber(v.qq_vip)
			data.cur_avatar_box_id = v.cur_avatar_box_id
			table.insert(BP_ARRAY_Blacklist_Friend_Profile, data)
		end
	end
			
	--log_tree("BP_ARRAY_Blacklist_Friend_Profile",BP_ARRAY_Blacklist_Friend_Profile)
	--刷新黑名单列表
	if BP_Is_Show then
		LobbyFriendUI:UpdateBlackist()
	end
end

-----------------------------------------------------------拉黑好友----------------------------------------
function FriendSystem.AddBlack(friUid)
	FriendSystem.add_black_list_req(friUid)
end

--拉黑好友
-- uid: 准备拉黑的好友uid
function FriendSystem.add_black_list_req(friUid)
    --log("add_black_list_req:"..friUid)
	
	for i = 1,#BP_ARRAY_Friend_ID_Blacklist,1 do
		if tonumber(BP_ARRAY_Friend_ID_Blacklist[i]) == tonumber(friUid) then
			--已经拉黑该好友
			DataMgr.ShowNoticeByID(200009)
		end
	end
    NetUtil.SendPkg("add_black_list_req", tonumber(friUid))
end

--拉黑回包
-- res 字符串返回码, "ok" 正常， 其他为错误
-- uid: 拉黑的好友uid
function FriendSystem.on_add_black_list_rsp(res,friUid)
	log("on_add_black_list_rsp:"..res)
	if res == "ok" then
		--拉黑成功
		DataMgr.ShowNoticeByID(200010)
		table.insert(BP_ARRAY_Friend_ID_Blacklist,friUid)
		--刷新黑名单列表
		if BP_Is_Show then
			FriendSystem.refresh_black_list_panel(BP_ARRAY_Friend_ID_Blacklist)
		end
		
		--拉黑以后告知聊天和组队系统（显示上移除）
		FriendSystem.ProcessDeleteFriend(friUid)
	elseif res == "fri_repeat" then
		--已经在黑名单中
		DataMgr.ShowNoticeByID(200009)
	elseif res == "fri_list_full" then
		--黑名单列表已满
		DataMgr.ShowNoticeByID(200012)
	elseif res == "fri_not_exist" then
		--好友不存在
		DataMgr.ShowNoticeByID(200013)
	end
end

--解除屏蔽
-- uid: 准备从黑名单中移除的好友uid
function FriendSystem.del_black_list_req(friUid)
	log("del_black_list_req:"..friUid)
    NetUtil.SendPkg("del_black_list_req", friUid)
end

-- res 字符串返回码,"ok" 正常,其他为错误
-- uid: 从黑名单移除的的好友uid
function FriendSystem.on_del_black_list_rsp(res,friUid)
	log("[HHF]on_del_black_list_rsp: " .. res .. ", uid = " .. tostring(friUid))
	
	if res == "ok" then
		for i = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
			if tonumber(BP_ARRAY_Friend_ID_Blacklist[i]) == tonumber(friUid) then
				table.remove(BP_ARRAY_Friend_ID_Blacklist,i)
				break
			end
		end
		--log_tree("blacklist_id",BP_ARRAY_Friend_ID_Blacklist)

		for i = #BP_ARRAY_Blacklist_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_Blacklist_Friend_Profile[i].gid) == tonumber(friUid) then
				table.remove(BP_ARRAY_Blacklist_Friend_Profile,i)
				break
			end
		end

		--log_tree("blacklist_profile",BP_ARRAY_Blacklist_Friend_Profile)
		--刷新黑名单列表
		if BP_Is_Show then
			LobbyFriendUI:UpdateBlackist()
			
			-- 将拉黑好友显示到好友列表
			local isInnerFriend = FriendSystem.IsInnerFriend(friUid)
			if isInnerFriend then
				FriendSystem.SortInnerFriendList()
				LobbyFriendUI:UpdateInnerList()
			end
			
			local isPlatFriend = FriendSystem.IsPlatFriend(friUid)
			if isPlatFriend then
				FriendSystem.SortPlatFriendList()
				LobbyFriendUI:UpdatePlatList()
			end

			--通知其他系统
			FriendSystem.ProcessAddFriend()
		end
	else
		log("delete black fail")
	end
end

--请求黑名单列表
function FriendSystem.get_black_list_req()
    log("get_black_list_req")
	
    NetUtil.SendPkg("get_black_list_req")
end

-- 黑名单列表回包
-- res 字符串返回码, "ok" 正常， 其他为错误
-- uid 玩家uid
-- list = {[1]=uid1, [2]=uid2, [3]=uid3, ...}
function FriendSystem.on_get_black_list_rsp(res,uid,blacklist)
    --log_tree("on_get_black_list_rsp:", blacklist)

	-- 返回给自己
	if res == "ok" then
		if tonumber(uid) == tonumber(DataMgr.roleData.uid) then
			BP_ARRAY_Friend_ID_Blacklist = {}
			BP_ARRAY_Blacklist_Friend_Profile = {}
			for k,v in pairs(blacklist) do
				table.insert(BP_ARRAY_Friend_ID_Blacklist, v)
			end
			--刷新黑名单列表
			if BP_Is_Show then
				FriendSystem.refresh_black_list_panel(BP_ARRAY_Friend_ID_Blacklist)
			end
		end
	else
		log("on_get_black_list_rsp.."..res)
	end
end

--刷新黑名单界面（黑名单只存id列表，概要数据从好友系统获取）
function FriendSystem.refresh_black_list_panel(idList)
	if next(idList) == nil then
		log("black list is nil")
	end

	local list = FriendSystem.SortFriendList2() -- 已做去重
	local toGetList = {}
	for k,v in pairs(idList) do
		local has = false
		for i = #list,1,-1 do
			if tonumber(list[i].gid) == tonumber(v) then
				table.insert(BP_ARRAY_Blacklist_Friend_Profile,list[i])
				has = true
				break
			end
		end
		
		-- 黑名单中存在未缓存的id，再请求一次概要
		if not has then
			table.insert(toGetList,v)
		end
	end
	
	--无额外数据需要请求，刷新界面
	if next(toGetList) == nil then
		LobbyFriendUI:UpdateBlackist()
	else
		-- 需要请求陌生人的概要数据
		ProfileMgr.GetProfileList(toGetList,FriendSystem.on_batch_get_blacklist_profile_rsp)
	end
end
-----------------------------------------------------------拉黑好友----------------------------------------

function FriendSystem.on_batch_get_apply_profile_rsp(profileList)
	--log_tree("apply profile:", profileList)
	
    for k,v in pairs(profileList) do
        for kk, vv in pairs(BP_ARRAY_Apply_Friend_Profile) do
            if tonumber(vv.gid) == tonumber(v.uid) then
                vv.nickName = v.nickName
				vv.level = v.level
				vv.picUrl = v.picUrl
				vv.vipLevel = v.vipLevel
				vv.platName = v.platName
				vv.sex = v.sex
				vv.lastOnlineTime = v.lastOnlineTime
				vv.lastLoginTime = v.lastLoginTime
				vv.exp = v.exp
                ----------------------------------------intl modify--------------------------------------
                --[[
				vv.segment_info_solo = v.segment_info[1]
				vv.segment_info_duo = v.segment_info[2]
				vv.segment_info_squad = v.segment_info[3]
                ]]
                vv.AllSegment_Info = v.segment_info
                 for kseg, vseg in pairs(vv.AllSegment_Info) do
                       vv.segment_info_solo   = vv.AllSegment_Info[kseg][1];
                       vv.segment_info_duo    = vv.AllSegment_Info[kseg][2];
                       vv.segment_info_squad = vv.AllSegment_Info[kseg][3];
                       break;
                 end
                vv.segment_info_solo,  vv.segment_info_duo,  vv.segment_info_squad =  FuncUtil.GetMaxSegement( vv.AllSegment_Info );
                ----------------------------------------intl modify--------------------------------------
                
				vv.startup_type = GetSafeNumber(v.startup_type)
				vv.qq_vip = GetSafeNumber(v.qq_vip)
				vv.cur_avatar_box_id = v.cur_avatar_box_id
				break
            end
        end
    end

	--刷新小红点
	if BP_Is_Show then
		LobbyFriendUI:UpdateApplyNewTips()
		LobbyFriendUI:UpdateApplyList()
	end

	FriendSystem.UpdateLobbyFriendNewTips()
	--log_tree("BP_ARRAY_Apply_Friend_Profile:", BP_ARRAY_Apply_Friend_Profile)
end

-----------------------------------------------------------请求申请列表好友----------------------------------------
--请求申请列表
function FriendSystem.get_addfriend_reqlist_req()
    log("get_addfriend_reqlist_req")
	
    NetUtil.SendPkg("get_addfriend_reqlist_req")
end

function FriendSystem.on_get_addfriend_reqlist_rsp(res, uid, addfriend_reqlist)
    --log_tree("on_get_addfriend_reqlist_rsp:", addfriend_reqlist)
	
    local idlist = {}
    BP_ARRAY_Apply_Friend_Profile = {}
    for k,v in pairs(addfriend_reqlist) do
        table.insert(idlist, k)
        local pro = {gid = k, op = v.op, applyMsg = v.applyMsg,createTime = v.createTime,createTimeStr = FriendSystem.FormatTime(v.createTime,"")}
        table.insert(BP_ARRAY_Apply_Friend_Profile, pro)
    end
	
	if next(idlist) == nil then
		return
	else
		-- 好友申请列表不为空显示小红点
		if BP_Is_Show then
			LobbyFriendUI:UpdateApplyNewTips()
		end
		FriendSystem.UpdateLobbyFriendNewTips()
	end
	
    ProfileMgr.GetProfileList(idlist,FriendSystem.on_batch_get_apply_profile_rsp)
	--log_tree("BP_ARRAY_Apply_Friend_Profile:", BP_ARRAY_Apply_Friend_Profile)
end
-----------------------------------------------------------请求申请列表好友----------------------------------------

-- 批量返回好友在线和组队信息
function FriendSystem.on_batch_get_group_and_online_rsp(listType,res,infos)
	log("[HHF]on_batch_get_group_and_online_rsp, res = " .. res .. ", listType = " .. listType)
	
	if res == "ok" then
		if listType == "all" then
			--log_tree("online and team info all",infos)			
			FriendSystem.updateOnlineAndGroupInfo(infos,BP_ARRAY_All_Friend_Profile,listType)
			FLAG_ONLINE_AND_TEAMINFO_ALL = true
			FriendSystem.NotifyPullFriendList()
		elseif listType == "updateteam" then
			--log_tree("online and team info updateteam",infos)		
			FriendSystem.updateOnlineAndGroupInfo(infos,BP_ARRAY_All_Friend_Profile,listType)
			FriendSystem.ProcessStateChange()
		elseif listType == "recentteammate" then
			--log_tree("online and team info recentteammate",infos)
			FriendSystem.updateOnlineAndGroupInfo(infos,BP_ARRAY_Recent_Teammate_Profile,listType)
			table.sort(BP_ARRAY_Recent_Teammate_Profile,SortRecentFunc)
			--派发最近组队成员状态变化事件
			EventSystem:postEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_RECENT_STATE_UPDATE);
		end
	else
		log("on_batch_get_group_and_online_rsp fail:"..res)
	end
end

function FriendSystem.updateOnlineAndGroupInfo(infos,profileList,listType)
	--log_tree("[HHF]updateOnlineAndGroupInfo, infos = ", infos);
	for k,v in pairs(infos) do
		local has = false
		for	i = #profileList,1,-1 do
			if tonumber(profileList[i].gid) == tonumber(k) then
				profileList[i].online = v.online
				profileList[i].teamState = v.teamState
				profileList[i].currentTeamAmount = v.currentTeamAmount
				profileList[i].maxTeamAmount = v.maxTeamAmount
				profileList[i].timeSinceGameBegin = v.timeSinceGameBegin
				profileList[i].timeSinceGameBeginStr = FriendSystem.FormatTime2(v.timeSinceGameBegin)
				has = true
				if listType ~= "recentteammate" then
					break
				end
			end
		end
				
		if not has then
			local data = {}
			data.gid = k
			data.online = v.online
			data.teamState = v.teamState
			data.currentTeamAmount = v.currentTeamAmount
			data.maxTeamAmount = v.maxTeamAmount
			data.timeSinceGameBegin = v.timeSinceGameBegin
			data.timeSinceGameBeginStr = FriendSystem.FormatTime2(v.timeSinceGameBegin)
			table.insert(profileList,data)
		end
	end
	
	--log_tree("profileList",profileList)
end

function FriendSystem.NotifyPullFriendList()
	if FLAG_PROFILE_ALL == true and FLAG_ONLINE_AND_TEAMINFO_ALL == true then
		FLAG_PROFILE_ALL = false
		FLAG_ONLINE_AND_TEAMINFO_ALL = false
		log("friendsystem notifypullfriendlist")
		
		--log_tree("BP_ARRAY_All_Friend_Profile all:", BP_ARRAY_All_Friend_Profile)
		FriendSystem.RefreshFriendList(ADD_FRIEND)
		if ADD_FRIEND then
			-- 弹出提示，和谁成为好友
			if tonumber(FRIEND_AGREE_UID) ~= 0 then
				for i = 1,#BP_ARRAY_All_Friend_Profile,1 do
					if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(FRIEND_AGREE_UID) then
						local msg = Client.GetTableData("LocalizeRes",200014)
						if msg then
							local str = string.format(msg.TextValue,BP_ARRAY_All_Friend_Profile[i].nickName)
							PopUpNoticeUI.ShowNewNotice(str)
							FRIEND_AGREE_UID = 0
						end
						break
					end
				end
			end
			FriendSystem.ProcessAddFriend()
			ADD_FRIEND = false
		end
		FriendSystem.PullFriendList()
	end
end

function FriendSystem.RefreshFriendList(addFriend)
	log("[HHF]RefreshFriendList, BP_Platform = " .. tostring(BP_Platform))
	if BP_Platform == BP_ENUM_PLAYFORM_WX or BP_Platform == BP_ENUM_PLAYFORM_QQ then
		if BP_Is_Show then
			FriendSystem.SortPlatFriendList()
			FriendSystem.SortInnerFriendList()
			
			LobbyFriendUI:UpdatePlatList()
			LobbyFriendUI:UpdateInnerList()
			LobbyFriendUI:UpdateApplyNewTips()
		end
	elseif BP_Platform == BP_ENUM_PLAYFORM_TOURIST then
		if BP_Is_Show then
			FriendSystem.SortInnerFriendList()
			
			LobbyFriendUI:UpdateInnerList()
			LobbyFriendUI:UpdateApplyNewTips()
		end
	end
end
-----------------------------------------------------------返回概要信息----------------------------------------

-----------------------------------------------------------发送好友申请----------------------------------------
function FriendSystem.AddFriend(friUid,from)
	FriendSystem.add_inner_friend_req(friUid, "",from)
end

--请求加好友 from标识从哪里加好友,用于经分统计,类型定义在cs_macros.lua中
function FriendSystem.add_inner_friend_req(friUid, msg,from)
	if friUid == nil then
		return
	end
	
	local fromSystem = 0;
	if from ~= nil and from ~= "" then
		fromSystem = from
	end
    log("add_inner_friend_req:" .. friUid .. "  msg:" .. msg)
	if msg == "" then
		msg = Client.GetTableData("LocalizeRes",200006).TextValue
	end
    NetUtil.SendPkg("add_inner_friend_req", tonumber(friUid), msg,fromSystem)
end

function FriendSystem.present_friend_gold_req(friUid,optype)
	log("FriendSystem.present_friend_gold_req!")
	--客户端自定义字段，服务器透传
	--op = 1时，表示邮件批量赠送时调用，不需要在on_present_friend_gold_rsp里提示
	local msg = { op = optype} ;
    NetUtil.SendPkg("present_friend_gold_req", tonumber(friUid),msg)
end

function FriendSystem.on_present_friend_gold_rsp(res,friUid,msg)
	if res == "ok" then
        --赠送成功
        log("[HHF]on_present_friend_gold_rsp succ")
		local curTime = FuncUtil.GetServerTimeInSec()
		local friend = FriendSystem.GetFriendDataByGID(friUid);
		
		local function shareToFriend()
			--好友数据里没有openid的信息，只能根据昵称去查询openid。(不要问我为什么。。。)
			FriendSystem.get_openid_by_nickname_req(friend.nickName,"friendpresentcoin")
			--local params = {openid = friend.openid,title = DataMgr.GetMsgByID(200021),desc = DataMgr.GetMsgByID(200022)}
			--ShareMgr:shareToFriend(params)
			DataMgr.ShowNoticeFastQueueByID(102031);
			--log("----------------------shareToFriend")
		end
		
		
		
		-- op = 0 表示单个赠送，op = 1表示批量同时调用此接口
		if msg ~= nil and msg.op == 1 then
			--不提示
		else
			if friend ~= nil then
				friend.lastPresentCoinTime = curTime
				friend.bPresentedCoin = 1 
				if FriendSystem.IsPlatFriend(friUid) then
					
					if GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_WX then
						CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102032), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
					elseif GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_QQ then 
						--CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102028), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
					end
				
				end
			end
		end
		
		local friendPlat = FriendSystem.GetPlatFriendDataByGID(friUid);
		if friendPlat ~= nil then
			friendPlat.lastPresentCoinTime = curTime
			friendPlat.bPresentedCoin = 1 
			LobbyFriendUI:UpdatePlatList()
		end
		
		local friendInner = FriendSystem.GetInnerFriendDataByGID(friUid);
		if friendInner ~= nil then
			friendInner.lastPresentCoinTime = curTime
			friendInner.bPresentedCoin = 1 
			LobbyFriendUI:UpdateInnerList()
		end
		
		--DataMgr.ShowNoticeByString("赠送成功")		
		local msgConfig = Client.GetTableData("LocalizeRes", 200018);
		if msgConfig then
			DataMgr.ShowNoticeByString(msgConfig.TextValue);
			--PopUpNoticeUI.ShowFastNoticeQueue(msgConfig.TextValue);			
		end
	elseif res == "limit" then
		--每日赠送次数达到上限;
		log("present_friend-limit")
		local msgConfig = Client.GetTableData("LocalizeRes", 200019);
		if msgConfig then
			DataMgr.ShowNoticeByString(msgConfig.TextValue);
			--PopUpNoticeUI.ShowFastNoticeQueue(msgConfig.TextValue);
		end
	elseif res == "in_blacklist" then
		--每日赠送次数达到上限;
		log("present_friend-in_blacklist")
		local msgConfig = Client.GetTableData("LocalizeRes", 200023);
		if msgConfig then
			DataMgr.ShowNoticeByString(msgConfig.TextValue);
			--PopUpNoticeUI.ShowFastNoticeQueue(msgConfig.TextValue);
		end
	elseif res == "repeat" then
		--同一个好友不能赠送多次
		log("present_friend-repeat")
		local curTime = FuncUtil.GetServerTimeInSec()
		local friend = FriendSystem.GetFriendDataByGID(friUid);
		if friend ~= nil then
			friend.lastPresentCoinTime = curTime
			friend.bPresentedCoin = 1 
		end
		
		friend = FriendSystem.GetPlatFriendDataByGID(friUid);
		if friend ~= nil then
			friend.lastPresentCoinTime = curTime
			friend.bPresentedCoin = 1 
			LobbyFriendUI:UpdatePlatList()
		end
		
		friend = FriendSystem.GetInnerFriendDataByGID(friUid);
		if friend ~= nil then
			friend.lastPresentCoinTime = curTime
			friend.bPresentedCoin = 1 
			LobbyFriendUI:UpdateInnerList()
		end
		
		local msgConfig = Client.GetTableData("LocalizeRes", 200020);
		if msgConfig then
			--PopUpNoticeUI.ShowFastNoticeQueue(msgConfig.TextValue);
			DataMgr.ShowNoticeByString(msgConfig.TextValue);
		end
	end
	--do something
	
end

--请求加好友,只针对这个消息是否发送成功，返回给发送者
function FriendSystem.on_add_inner_friend_rsp(res)
	log("on_add_inner_friend_rsp")

    if res == "ok" then
        --发送成功
        log("send invite succ")
		DataMgr.ShowNoticeByID(200001)
	elseif res == "fri_already" then
		--已经是好友
		log("fri_already")
		DataMgr.ShowNoticeByID(200007)
	elseif res == "fri_list_full" then
		--对方好友申请已满
		log("fri_list_full")
		--DataMgr.ShowNoticeByID(200008)
	elseif res == "fri_repeat" then
		log("fri_repeat")
		DataMgr.ShowNoticeByID(200002)
	elseif res == "fri_self" then
		log("fri_self")
		DataMgr.ShowNoticeByID(200004)
	else
		log("add friend fail")
		DataMgr.ShowNoticeByID(200005)
    end
	LobbyFriendUI:SendInviteSuccess()
end

--请求加好友,返回给被接收者，add_req_friend为发送申请者的ID
function FriendSystem.on_add_inner_friend_notify(add_req_friend, msg,msgcreateTime)
    --将这个塞到邀请列表里面 BP_ARRAY_Apply_Friend_Profile
	log("on_add_inner_friend_notify")
	
	local idlist = {}
	table.insert(idlist, add_req_friend)
    local pro = {gid = tostring(add_req_friend), op = -1, applyMsg = msg,createTime = msgcreateTime,createTimeStr = FriendSystem.FormatTime(msgcreateTime,"")}
    table.insert(BP_ARRAY_Apply_Friend_Profile, pro)
	
	--log_tree("BP_ARRAY_Apply_Friend_Profile:",BP_ARRAY_Apply_Friend_Profile)
	ProfileMgr.GetFriendProfileList(idlist,FriendSystem.on_batch_get_apply_profile_rsp)
end
-----------------------------------------------------------发送好友申请----------------------------------------

-----------------------------------------------------------处理好友申请----------------------------------------
--被邀请人回复friUid是否同意  op=1，同意；op=0,拒绝；-1 未操作
function FriendSystem.add_inner_friend_op_req(friUid, op)
    log("add_inner_friend_op_req:"..friUid.." op:"..op)
	
    NetUtil.SendPkg("add_inner_friend_op_req", friUid, op)

	if op == 1 then
		FRIEND_AGREE_UID = friUid
	else
		FRIEND_REFUSE_UID = friUid
	end
end

--添加好友请求好友数据，设置亲密度，赠送金币等默认值
function FriendSystem.AddFriendRequestData(friUid)
	log("[HHF]AddFriendRequestData, add inner friend, id = " .. tostring(friUid))
	ADD_FRIEND = true
	
	table.insert(ID_INNER_FRIENDLIST, friUid)
	FriendSystem.on_become_friend_delete_black_data(friUid)
	
	--添加好友设置亲密度默认值，赠送金币
	local profile = {gid=tostring(friUid),intimacy=0,bPresentedCoin=0,lastPresentCoinTime=0}
	local has = false
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(friUid) then
			has = true
			-- 如果也是平台好友，好友数据不会删除，需要刷新亲密度,赠送金币属性不用重置,否则赠送金币会自动加平台好友为游戏好友后又可以赠送一次金币
			BP_ARRAY_All_Friend_Profile[i].intimacy = 0
			--BP_ARRAY_All_Friend_Profile[i].bPresentedCoin = 0
			--BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime = 0
			break
		end
	end
	if not has then
		table.insert(BP_ARRAY_All_Friend_Profile,profile)
	end
	
	local list = {friUid}
	ProfileMgr.GetFriendProfileList(list,FriendSystem.on_batch_get_all_profile_rsp)
	NetUtil.SendPkg("batch_get_group_and_online_req","all",list)
end

--被邀请人收到是否同意的回包，返回ok表示已经成为好友（加好友仅针对游戏内好友）
function FriendSystem.on_add_inner_friend_op_rsp(res, friUid,op)
    --这里还不知道谁和玩家是好友关系，所以要再加个id
    log("on_add_inner_friend_op_rsp")

    if res == "ok" then
		if op == 1 then
			FriendSystem.AddFriendRequestData(FRIEND_AGREE_UID)
			FriendSystem.on_refresh_friend_apply_lists(FRIEND_AGREE_UID)
		else
			FriendSystem.on_refresh_friend_apply_lists(FRIEND_REFUSE_UID)
			FRIEND_REFUSE_UID = 0
		end
		log("add inner friend op rsp success")
		-- 同意或者拒绝后更新小红点
		if BP_Is_Show then
			LobbyFriendUI:UpdateApplyNewTips()
		end

		-- 更新大厅界面好友小红点
		FriendSystem.UpdateLobbyFriendNewTips()
	elseif res == "fri_not_exist" then
		log("add inner friend op rsp fri_not_exist")
		DataMgr.ShowNoticeByID(200024)
		FriendSystem.on_delete_invalid_data(op,FRIEND_AGREE_UID,FRIEND_REFUSE_UID)
	elseif res == "fri_already" then
		log("add inner friend op rsp fri_already")
		DataMgr.ShowNoticeByID(200007)
		FriendSystem.on_delete_invalid_data(op,FRIEND_AGREE_UID,FRIEND_REFUSE_UID)
	elseif res == "fri_list_full" then
		log("add inner friend op rsp fri_list_full")
		DataMgr.ShowNoticeByID(200008)
	else
		log("add inner friend op rsp fail")
		FriendSystem.on_delete_invalid_data(op,FRIEND_AGREE_UID,FRIEND_REFUSE_UID)
    end
end

-- 成为好友后清理拉黑数据
function FriendSystem.on_become_friend_delete_black_data(friUid)
	--如果加为好友的人之前被拉黑，加为好友后从黑名单中移除
	for i= #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
		if tonumber(BP_ARRAY_Friend_ID_Blacklist[i]) == tonumber(friUid) then
			table.remove(BP_ARRAY_Friend_ID_Blacklist,i)
			break
		end
	end
			
	for j = #BP_ARRAY_Blacklist_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_Blacklist_Friend_Profile[j].gid == tonumber(friUid)) then
			table.remove(BP_ARRAY_Blacklist_Friend_Profile,j)
			break
		end
	end
end

-- 申请列表无效数据点击同意后根据错误码进行清理
function FriendSystem.on_delete_invalid_data(op,agreeuid,refuseuid)
	if op == 1 then
		FriendSystem.on_refresh_friend_apply_lists(agreeuid)
	else
		FriendSystem.on_refresh_friend_apply_lists(refuseuid)
	end
	
	if BP_Is_Show then
		LobbyFriendUI:UpdateApplyNewTips()
	end
	FriendSystem.UpdateLobbyFriendNewTips()
end

--点击同意或者拒绝移除数据，刷新界面
function FriendSystem.on_refresh_friend_apply_lists(removeUid)
	for i = #BP_ARRAY_Apply_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_Apply_Friend_Profile[i].gid) == tonumber(removeUid) then
			table.remove(BP_ARRAY_Apply_Friend_Profile,i)
			break
		end
	end
	if BP_Is_Show then
		LobbyFriendUI:UpdateApplyList()
	end
end

--邀请人收到是否同意的回包
function FriendSystem.on_add_inner_friend_op_notify(op, friUid)
    log("on_add_inner_friend_op_notify")

    if op == 1 then
		FriendSystem.AddFriendRequestData(friUid)
	else
		log("add inner friend op notify fail")
    end
end

--平台好友一起开黑自动添加好友
function FriendSystem.on_auto_add_inner_friend_notify(uid)
	log(" auto_add_inner_friend_notify"..tostring(uid))
	FriendSystem.AddFriendRequestData(uid)
end

--双方互相加好友时其中一方已点击同意，删除另一方相应好友请求
function FriendSystem.on_del_addfriend_req_notify(uid)
	log("on_del_addfriend_req_notify"..uid)
	
	for i = 1,#BP_ARRAY_Apply_Friend_Profile,1 do
		if BP_ARRAY_Apply_Friend_Profile[i] ~= nil then
			if tonumber(BP_ARRAY_Apply_Friend_Profile[i].gid) == tonumber(uid) then
				table.remove(BP_ARRAY_Apply_Friend_Profile,i)
				break
			end
		end
	end
	--刷新小红点，更新申请列表
	if BP_Is_Show then
		LobbyFriendUI:UpdateApplyNewTips()
		LobbyFriendUI:UpdateApplyList()
	end
	FriendSystem.UpdateLobbyFriendNewTips()
end
-----------------------------------------------------------处理好友申请----------------------------------------

-----------------------------------------------------------删除好友----------------------------------------
--请求删除好友
function FriendSystem.del_inner_friend_req(friUid)
    log("del_inner_friend_req:"..friUid)
	
	if friUid ~= nil then
		NetUtil.SendPkg("del_inner_friend_req", friUid)
	end
end

--删除好友回包(给自己)
function FriendSystem.on_del_inner_friend_rsp(res)
    log("on_del_inner_friend_rsp:" .. res)
	log("del_inner_friend_id:"..BP_Delete_Friend_ID)
	
	if res == "ok" then
		FriendSystem.UpdateDeleteFriendData(BP_Delete_Friend_ID)
	end
end

--删除好友回包(给被删除方)
function FriendSystem.on_del_inner_friend_notify(uid)
    log("on_del_inner_friend_notify")
	log("del_inner_friend_id:"..uid)
	
	FriendSystem.UpdateDeleteFriendData(uid)
end

function FriendSystem.UpdateDeleteFriendData(uid)
	local isPlatFriend = false
	for i = #ID_PLAT_FRIENDLIST,1,-1 do
		if tonumber(ID_PLAT_FRIENDLIST[i]) == tonumber(uid) then
			isPlatFriend = true
			break
		end
	end

	if not isPlatFriend then
		for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(uid) then
				table.remove(BP_ARRAY_All_Friend_Profile,i)
				break
			end
		end
		
		-- 删除好友时如果该好友已被拉黑且不是平台好友需要删除黑名单相关信息
		for j = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
			if tonumber(BP_ARRAY_Friend_ID_Blacklist[j]) == tonumber(uid) then
				table.remove(BP_ARRAY_Friend_ID_Blacklist,j)
				break
			end
		end
		for k = #BP_ARRAY_Blacklist_Friend_Profile,1,-1 do
			if tonumber(BP_ARRAY_Blacklist_Friend_Profile[k].gid) == tonumber(uid) then
				table.remove(BP_ARRAY_Blacklist_Friend_Profile,k)
				break
			end
		end
		
		--非平台好友才可以删除
		FriendSystem.ProcessDeleteFriend(uid)
	end

	for i = #ID_INNER_FRIENDLIST,1,-1 do
		if tonumber(ID_INNER_FRIENDLIST[i]) == tonumber(uid) then
			table.remove(ID_INNER_FRIENDLIST,i)
			break
		end
	end
	if BP_Is_Show then
		FriendSystem.SortInnerFriendList()
		
		--删除好友item
		LobbyFriendUI:UpdateInnerList()
	end
end
-----------------------------------------------------------删除好友----------------------------------------

-----------------------------------------------------------好友亲密度变更------------------------------------------
--只通知自己
function FriendSystem.notify_friend_intimacy_chg(friUid,chg,newIntimacy)
	log("notify_friend_intimacy_chg "..friUid.." chg"..chg)
	local nickName = ""
	for i = 1,#BP_ARRAY_All_Friend_Profile,1 do
		if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(friUid) then
			BP_ARRAY_All_Friend_Profile[i].intimacy = tonumber(newIntimacy)
			nickName = BP_ARRAY_All_Friend_Profile[i].nickName
			break
		end
	end
	
	--tips提示（和xxx亲密度变化多少）
	local msg = Client.GetTableData("LocalizeRes",200017);
	if msg then
		local str = string.format(msg.TextValue,nickName,tonumber(chg));
		DataMgr.ShowNoticeByString(msgConfig.TextValue);
		--PopUpNoticeUI.ShowFastNoticeQueue(str)
	end
	
	--刷新游戏好友界面亲密度显示
	if BP_Is_Show then
		FriendSystem.SortInnerFriendList()
		LobbyFriendUI:UpdateInnerList()
	end
end
-----------------------------------------------------------好友亲密度变更------------------------------------------

-----------------------------------------------------------好友组队状态变更----------------------------------------
-- 更新好友在线状态
function FriendSystem.on_notify_online_status_chg(uid,isOnline)
	log("on_notify_online_status_chg uid:"..uid.."isOnline:"..tostring(isOnline))

	if next(BP_ARRAY_All_Friend_Profile) == nil then
		return
	end
	
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(uid) then
			BP_ARRAY_All_Friend_Profile[i].online = isOnline
			break
		end
	end
	--log_tree("on_notify_online_status_chg all", BP_ARRAY_All_Friend_Profile)
	
	FriendSystem.ProcessOnlineStateChange()
end

-- 更新好友组队状态
function FriendSystem.on_notify_group_status_chg(uid,newStatus)
	--log_tree("on_notify_group_status_chg:",newStatus)

	if next(BP_ARRAY_All_Friend_Profile) == nil then
		return
	end
	
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(uid) then
			BP_ARRAY_All_Friend_Profile[i].teamState = newStatus.teamState
			BP_ARRAY_All_Friend_Profile[i].currentTeamAmount = newStatus.currentTeamAmount
			BP_ARRAY_All_Friend_Profile[i].maxTeamAmount = newStatus.maxTeamAmount
			BP_ARRAY_All_Friend_Profile[i].teamId = newStatus.teamId
			BP_ARRAY_All_Friend_Profile[i].timeSinceGameBegin = newStatus.timeSinceGameBegin
			BP_ARRAY_All_Friend_Profile[i].timeSinceGameBeginStr = FriendSystem.FormatTime2(newStatus.timeSinceGameBegin)
			break
		end
	end
	--log_tree("on_notify_online_status_chg all", BP_ARRAY_All_Friend_Profile)
	
	FriendSystem.ProcessStateChange()
end
-----------------------------------------------------------好友组队状态变更----------------------------------------

-----------------------------------------------------------查询好友openid----------------------------------------
function FriendSystem.get_openid_by_nickname_req(nickname, cb)
	log("FriendSystem.get_openid_by_nickname_req")
	NetUtil.SendPkg("get_openid_by_nickname_req", nickname, cb)
end

function FriendSystem.get_openid_by_nickname_rsp(nickname, res, openid, cb)
	log("FriendSystem.get_openid_by_nickname_rsp")
	if res == "ok" then
		if cb == "offlineInvite" then
			--如果是邀请上线查询，则发送邀请上线分享
			local friend = FriendSystem.GetFriendDataByNickname(nickname);
			local gid = nil;
			if friend ~= nil then
				gid = tonumber(friend.gid);
				FriendSystem.check_and_update_invite_plat_req(gid);
			end
			local params = {};
			params.openid = openid;
			params.title = DataMgr.GetMsgByID(110106);
			params.desc = DataMgr.GetMsgByID(110107);
			if gid ~= nil then
				local extendInfo = {};
				extendInfo.invite_info = {inviter = gid};
				params.extendInfo = FuncUtil:EncodeURI(json.encode(extendInfo));
			end
			ShareMgr:shareToFriend(params);
			
		elseif cb == "friendpresentcoin" then
			local params = {openid = openid,title = DataMgr.GetMsgByID(200021),desc = DataMgr.GetMsgByID(200022) ,adtag = GameCenterADTAG.heart,gameTag="MSG_HEART_SEND"}
			ShareMgr:shareToFriend(params);
		end
		
	end
end
-----------------------------------------------------------查询好友openid----------------------------------------

-----------------------------------------------------------更新邀请好友上线时间----------------------------------------
function FriendSystem.check_and_update_invite_plat_req(friUid)
	log("FriendSystem.check_and_update_invite_plat_req");
	NetUtil.SendPkg("check_and_update_invite_plat_req", friUid);
end

function FriendSystem.check_and_update_invite_plat_rsp(res, friUid)
	log("FriendSystem.check_and_update_invite_plat_rsp");
	if res == "ok" then
		local friend = FriendSystem.GetFriendDataByGID(friUid);
		if friend ~= nil then
			friend.lastInviteTime = FuncUtil.GetServerTimeInSec();
			TeamUPFriendUI.UpdateAllFriendStatus();
		end
		--DataMgr.ShowNoticeByString("邀请成功");
		DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301265").TextValue);
	else
		log("FriendSystem.check_and_update_invite_plat_rsp:" .. res);
	end
end
-----------------------------------------------------------更新邀请好友上线时间----------------------------------------

-----------------------------------------------------------通知最近组队数据--------------------------------
function FriendSystem.on_notify_team_result_finished()
	log("on notify team result finished")
	FriendSystem.getRecentTeammate()
end
-----------------------------------------------------------通知最近组队数据--------------------------------
           
-----------------------------------------------------------数据排序----------------------------------------
--(在线>组队中>游戏中>离线(离线按最近登录时间排序)
function SortFunc(a,b)
	if a.online == nil or b.online == nil then
		return false
	end

	if a.online == b.online then
		if a.teamState == nil or b.teamState == nil then
				return false
			end
			
		if a.teamState == b.teamState then
			if a.intimacy == nil or b.intimacy == nil then
				return false
			end
				
			if a.intimacy == b.intimacy then
				if a.level == nil or b.level == nil then
					return false
				end
					
				if a.level == b.level then
					return tonumber(a.lastOnlineTime) > tonumber(b.lastOnlineTime)
					
				else
					return a.level > b.level
				end
			else
				return a.intimacy > b.intimacy
			end
		else
			return a.teamState < b.teamState
		end
	else
		return a.online > b.online
	end
end

function SortRecentFunc(a,b)
	if a.endtime == nil or b.endtime == nil then
		return false
	end
	
	if a.endtime == b.endtime then
		if a.online == nil or b.online == nil then
			return false
		end
		
		if a.online == b.online then
			if a.teamState == nil or b.teamState == nil then
				return false
			end
		
			if a.teamState == b.teamState then
				if a.intimacy == nil or b.intimacy == nil then
					return false
				end
				
				if a.intimacy == b.intimacy then
					if a.level == nil or b.level == nil then
						return false
					end
					
					if a.level == b.level then
						return tonumber(a.lastOnlineTime) > tonumber(b.lastOnlineTime)
					else
						return a.level > b.level
					end
				else
					return a.intimacy > b.intimacy
				end
			else
				return a.teamState < b.teamState
			end
		else
			return a.online > b.online
		end
	else
		return a.endtime > b.endtime
	end
end

--好友数据排序(供聊天和组队使用)
function FriendSystem.SortFriendList()
	local list = {}
	
	--过滤脏数据
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if BP_ARRAY_All_Friend_Profile[i].nickName == "" or BP_ARRAY_All_Friend_Profile[i].nickName == nil then 
			table.remove(BP_ARRAY_All_Friend_Profile,i)
		end
	end

	local curTime = FuncUtil.GetServerTimeInSec()
	for i = 1,#BP_ARRAY_All_Friend_Profile,1 do
		local profile = BP_ARRAY_All_Friend_Profile[i]
		--默认不显示邀请
		profile.showInviteIcon = 0
		local lastInviteTime = profile.lastInviteTime
		if profile.online == 0 and FriendSystem.IsPlatFriend(profile.gid) then
			if lastInviteTime == nil or FuncUtil.IsSameDay(curTime, lastInviteTime) == false then
				--不在同一天，显示可邀请
				profile.showInviteIcon = 1
			else
				--在同一天，显示已邀请
				profile.showInviteIcon = 2
			end
		end
		
		table.insert(list,BP_ARRAY_All_Friend_Profile[i])
	end
	
	-- 过滤黑名单数据
	for i = #list,1,-1 do
		for j = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
			if tonumber(list[i].gid) == tonumber(BP_ARRAY_Friend_ID_Blacklist[j]) then
				table.remove(list,i)
				break
			end
		end
	end
	
	--获取最新概要数据
	for k = #list,1,-1 do
		if ProfileMgr.dicFriendProfile[tonumber(list[k].gid)] then
			if ProfileMgr.dicFriendProfile[tonumber(list[k].gid)].cur_avatar_box_id ~= nil then
				list[k].cur_avatar_box_id = ProfileMgr.dicFriendProfile[tonumber(list[k].gid)].cur_avatar_box_id
				list[k].nickName = ProfileMgr.dicFriendProfile[tonumber(list[k].gid)].nickName
				list[k].level = ProfileMgr.dicFriendProfile[tonumber(list[k].gid)].level
			end
		end
	end
	
	table.sort(list,SortFunc)
	return list
end

--仅供黑名单使用
function FriendSystem.SortFriendList2()
	local list = {}
	
	--过滤脏数据
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if BP_ARRAY_All_Friend_Profile[i].nickName == "" or BP_ARRAY_All_Friend_Profile[i].nickName == nil then 
			table.remove(BP_ARRAY_All_Friend_Profile,i)
		end
	end

	for i = 1,#BP_ARRAY_All_Friend_Profile,1 do
		table.insert(list,BP_ARRAY_All_Friend_Profile[i])
	end

	table.sort(list,SortFunc)
	return list
end

--供最近队友列表使用
function FriendSystem.SortRecentList()
	local list = {}
	local ids = {}
	
	--过滤脏数据
	for i = #BP_ARRAY_Recent_Teammate_Profile,1,-1 do
		if BP_ARRAY_Recent_Teammate_Profile[i].nickName == "" or BP_ARRAY_Recent_Teammate_Profile[i].nickName == nil then 
			table.remove(BP_ARRAY_Recent_Teammate_Profile,i)
		end
	end

	for i = 1,#BP_ARRAY_Recent_Teammate_Profile,1 do
		if ids[BP_ARRAY_Recent_Teammate_Profile[i].gid] == nil then
			table.insert(list,BP_ARRAY_Recent_Teammate_Profile[i])
			ids[BP_ARRAY_Recent_Teammate_Profile[i].gid] = BP_ARRAY_Recent_Teammate_Profile[i].gid
		end
	end

	table.sort(list,SortRecentFunc)

	return list
end

--游戏内好友排序
function FriendSystem.SortInnerFriendList()
	log("sortinnerfriendlist")
	BP_ARRAY_Inner_Friend_Profile = {}
		
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if BP_ARRAY_All_Friend_Profile[i].nickName == "" or BP_ARRAY_All_Friend_Profile[i].nickName == nil then 
			table.remove(BP_ARRAY_All_Friend_Profile,i)
		end
	end
	
	local curTime = FuncUtil.GetServerTimeInSec()
	
	for	i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		local has = false;
		for j = #ID_INNER_FRIENDLIST,1,-1 do
			if tonumber(ID_INNER_FRIENDLIST[j]) == tonumber(BP_ARRAY_All_Friend_Profile[i].gid) then
				has = true
				break
			end
		end
		if has then
			local data = {}
			-- 值拷贝
			data.gid = BP_ARRAY_All_Friend_Profile[i].gid
			data.nickName = BP_ARRAY_All_Friend_Profile[i].nickName
			data.level = BP_ARRAY_All_Friend_Profile[i].level
			data.militaryRank = BP_ARRAY_All_Friend_Profile[i].militaryRank
			data.picUrl = BP_ARRAY_All_Friend_Profile[i].picUrl
			data.vipLevel = BP_ARRAY_All_Friend_Profile[i].vipLevel
			data.ladder = BP_ARRAY_All_Friend_Profile[i].ladder
			data.platName = BP_ARRAY_All_Friend_Profile[i].platName
			data.sex = BP_ARRAY_All_Friend_Profile[i].sex
			data.lastOnlineTime = BP_ARRAY_All_Friend_Profile[i].lastOnlineTime
			data.lastLoginTime = BP_ARRAY_All_Friend_Profile[i].lastLoginTime
			data.exp = BP_ARRAY_All_Friend_Profile[i].exp
			data.segment_info_solo = BP_ARRAY_All_Friend_Profile[i].segment_info_solo
			data.segment_info_duo = BP_ARRAY_All_Friend_Profile[i].segment_info_duo
			data.segment_info_squad = BP_ARRAY_All_Friend_Profile[i].segment_info_squad
			data.friendType = 0
			data.teamState = BP_ARRAY_All_Friend_Profile[i].teamState
			data.currentTeamAmount = BP_ARRAY_All_Friend_Profile[i].currentTeamAmount
			data.maxTeamAmount = BP_ARRAY_All_Friend_Profile[i].maxTeamAmount
			data.timeSinceGameBegin = BP_ARRAY_All_Friend_Profile[i].timeSinceGameBegin
			data.timeSinceGameBeginStr = BP_ARRAY_All_Friend_Profile[i].timeSinceGameBeginStr
			data.online = BP_ARRAY_All_Friend_Profile[i].online
			data.lastOnlineTimeStr = BP_ARRAY_All_Friend_Profile[i].lastOnlineTimeStr
			data.startup_type = BP_ARRAY_All_Friend_Profile[i].startup_type
			data.qq_vip = BP_ARRAY_All_Friend_Profile[i].qq_vip
					
			data.intimacy = BP_ARRAY_All_Friend_Profile[i].intimacy
			data.lastPresentCoinTime = BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime
			data.cur_avatar_box_id = BP_ARRAY_All_Friend_Profile[i].cur_avatar_box_id
			data.remarks_name = ""
			
			local lastPresentCoinTime = data.lastPresentCoinTime
			if lastPresentCoinTime ~= nil and FuncUtil.IsSameDay(curTime, lastPresentCoinTime) == false then
				data.bPresentedCoin = 0
			else
				data.bPresentedCoin = 1
			end	
			table.insert(BP_ARRAY_Inner_Friend_Profile,data)
		end
	end
	
	-- 过滤黑名单数据
	for i = #BP_ARRAY_Inner_Friend_Profile,1,-1 do
		for j = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
			if tonumber(BP_ARRAY_Inner_Friend_Profile[i].gid) == tonumber(BP_ARRAY_Friend_ID_Blacklist[j]) then
				table.remove(BP_ARRAY_Inner_Friend_Profile,i)
				break
			end
		end
	end
	
	table.sort(BP_ARRAY_Inner_Friend_Profile,SortFunc)
	
	local xiaoyueProfile = {bXiaoYue=1,bNewMessage=BP_XY_API_RedPoint}
	--table.insert(BP_ARRAY_Inner_Friend_Profile,1,xiaoyueProfile)
	
	--log_tree("ID_INNER_FRIENDLIST:",ID_INNER_FRIENDLIST)
	--log_tree("BP_ARRAY_Inner_Friend_Profile:",BP_ARRAY_Inner_Friend_Profile)
end

--平台好友排序
function FriendSystem.SortPlatFriendList()
	log("[HHF]SortPlatFriendList")
	BP_ARRAY_Plat_Friend_Profile = {}
	
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if BP_ARRAY_All_Friend_Profile[i].nickName == "" or BP_ARRAY_All_Friend_Profile[i].nickName == nil then 
			table.remove(BP_ARRAY_All_Friend_Profile,i)
		end
	end
	
	local curTime = FuncUtil.GetServerTimeInSec()
	
	for	i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		local has = false;
		for j = #ID_PLAT_FRIENDLIST,1,-1 do
			if tonumber(ID_PLAT_FRIENDLIST[j]) == tonumber(BP_ARRAY_All_Friend_Profile[i].gid) then
				has = true
				break
			end
		end
		if has then
			local data = {}
			-- 值拷贝
			data.gid = BP_ARRAY_All_Friend_Profile[i].gid
			data.nickName = BP_ARRAY_All_Friend_Profile[i].nickName
			data.level = BP_ARRAY_All_Friend_Profile[i].level
			data.militaryRank = BP_ARRAY_All_Friend_Profile[i].militaryRank
			data.picUrl = BP_ARRAY_All_Friend_Profile[i].picUrl
			data.vipLevel = BP_ARRAY_All_Friend_Profile[i].vipLevel
			data.ladder = BP_ARRAY_All_Friend_Profile[i].ladder
			data.platName = BP_ARRAY_All_Friend_Profile[i].platName
			data.sex = BP_ARRAY_All_Friend_Profile[i].sex
			data.lastOnlineTime = BP_ARRAY_All_Friend_Profile[i].lastOnlineTime
			data.lastLoginTime = BP_ARRAY_All_Friend_Profile[i].lastLoginTime
			data.exp = BP_ARRAY_All_Friend_Profile[i].exp
			data.segment_info_solo = BP_ARRAY_All_Friend_Profile[i].segment_info_solo
			data.segment_info_duo = BP_ARRAY_All_Friend_Profile[i].segment_info_duo
			data.segment_info_squad = BP_ARRAY_All_Friend_Profile[i].segment_info_squad
			data.friendType = 1
			data.teamState = BP_ARRAY_All_Friend_Profile[i].teamState
			data.currentTeamAmount = BP_ARRAY_All_Friend_Profile[i].currentTeamAmount
			data.maxTeamAmount = BP_ARRAY_All_Friend_Profile[i].maxTeamAmount
			data.timeSinceGameBegin = BP_ARRAY_All_Friend_Profile[i].timeSinceGameBegin
			data.timeSinceGameBeginStr = BP_ARRAY_All_Friend_Profile[i].timeSinceGameBeginStr
			data.online = BP_ARRAY_All_Friend_Profile[i].online
			data.lastOnlineTimeStr = BP_ARRAY_All_Friend_Profile[i].lastOnlineTimeStr
			data.startup_type = BP_ARRAY_All_Friend_Profile[i].startup_type
			data.qq_vip = BP_ARRAY_All_Friend_Profile[i].qq_vip
					
			data.intimacy = 0
			data.lastPresentCoinTime = BP_ARRAY_All_Friend_Profile[i].lastPresentCoinTime
			data.cur_avatar_box_id = BP_ARRAY_All_Friend_Profile[i].cur_avatar_box_id
			data.remarks_name = BP_ARRAY_All_Friend_Profile[i].remarks_name
			
			local lastPresentCoinTime = data.lastPresentCoinTime
			if lastPresentCoinTime ~= nil and FuncUtil.IsSameDay(curTime, lastPresentCoinTime) == false then
				data.bPresentedCoin = 0
			else
				data.bPresentedCoin = 1
			end	
			
			table.insert(BP_ARRAY_Plat_Friend_Profile,data)
		end
	end
	--过滤黑名单数据
	for i = #BP_ARRAY_Plat_Friend_Profile,1,-1 do
		for j = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
			if tonumber(BP_ARRAY_Plat_Friend_Profile[i].gid) == tonumber(BP_ARRAY_Friend_ID_Blacklist[j]) then
				table.remove(BP_ARRAY_Plat_Friend_Profile,i)
				break
			end
		end
	end
	table.sort(BP_ARRAY_Plat_Friend_Profile,SortFunc)
	
	--local xiaoyueProfile = {bXiaoYue=1,bNewMessage=BP_XY_API_RedPoint}
	--table.insert(BP_ARRAY_Plat_Friend_Profile,1,xiaoyueProfile)
	
	--log_tree("ID_PLAT_FRIENDLIST:",ID_PLAT_FRIENDLIST)
	--log_tree("BP_ARRAY_Plat_Friend_Profile:",BP_ARRAY_Plat_Friend_Profile)
end
-----------------------------------------------------------数据排序----------------------------------------

-----------------------------------------------------------格式化日期------------------------------------------
function FriendSystem.FormatTime(t,s)
	if t == nil then
		return ""
	end
	
	local str = ""
	if s == "online" then
		--str = "最近上线 ";
		str = Client.GetTableData("LocalizeRes",301101).TextValue;
	end
	
	local diff = os.time() - t
    local days = math.floor(diff/86400)
    local hours = math.fmod(math.floor(diff/3600), 24)
    local mins = math.fmod(math.floor(diff/60), 60)
    local seconds = math.fmod(diff, 60)
    	
    if days >= 1 then
		if hours >= 1 then
		    --return str..days.."天前";
			return str..string.format(Client.GetTableData("LocalizeRes", "301255").TextValue, tostring(days));
		elseif hours < 1 and hours >= 0 then
			--return str..days.."天前";
			return str..string.format(Client.GetTableData("LocalizeRes", "301255").TextValue, tostring(days));
		end
    end
    if hours >= 1 then
		if mins >= 1 then
		    --return str..hours.."小时前";
			return str..string.format(Client.GetTableData("LocalizeRes", "301257").TextValue, tostring(hours));
		elseif mins < 1 and mins >= 0 then
			--return str..hours.."小时前";
			return str..string.format(Client.GetTableData("LocalizeRes", "301257").TextValue, tostring(hours));
		end
    end
    if mins >= 1 then
        --return str..mins.."分钟前";
		return str..string.format(Client.GetTableData("LocalizeRes", "301264").TextValue, tostring(mins));
	else
		--return str.."1分钟前";
		return str..Client.GetTableData("LocalizeRes", "301105").TextValue;
    end
end

function FriendSystem.FormatTime2(t)
	if t == nil then
		return "0"
	end
	
    local hours = math.fmod(math.floor(t/3600), 24)
    local mins = math.fmod(math.floor(t/60), 60)
    local seconds = math.fmod(t, 60)

    if hours >= 1 then
		if mins >= 1 then
		    --return "(已开局"..hours.."小时)";
		    return string.format(Client.GetTableData("LocalizeRes",301128).TextValue, tostring(hours));
		elseif mins < 1 and mins >= 0 then
			--return "(已开局"..hours.."小时)";
			return string.format(Client.GetTableData("LocalizeRes",301128).TextValue, tostring(hours));
		end
    end
    if mins >= 1 then
        --return "(已开局"..mins.."分钟)";
        return string.format(Client.GetTableData("LocalizeRes",301127).TextValue, tostring(mins));
	else
		--return "(已开局1分钟)";
		return Client.GetTableData("LocalizeRes",301126).TextValue;
    end
end
-----------------------------------------------------------格式化日期------------------------------------------

function FriendSystem.UpdateLobbyFriendNewTips()
	-- 更新大厅小红点
	log("updatelobbyfriendnewtips")
	if next(BP_ARRAY_Apply_Friend_Profile) ~= nil then
		log("updatelobbyfriendnewtips BP_ARRAY_Apply_Friend_Profile is not nil")
		LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_FRIEND, true)
		LobbyUI:LobbySystemMessageUpdate(BP_ENUM_LOBBY_MENU_FRIEND,#BP_ARRAY_Apply_Friend_Profile)
	else
		log("updatelobbyfriendnewtips BP_ARRAY_Apply_Friend_Profile is nil")
		LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_FRIEND, false)
		LobbyUI:LobbySystemMessageUpdate(BP_ENUM_LOBBY_MENU_FRIEND,0)
	end
end

-- 返回好友gid列表
function FriendSystem.GetFriendUidList()
	return ID_PLAT_FRIENDLIST,ID_INNER_FRIENDLIST
end

-- 第一次拉取好友列表
function FriendSystem.PullFriendList()
	log("FriendSystem.PullFriendList")

	--更新组队信息
	TeamUPFriendUI.UpdateFriend()
	LobbyChatSystem.UpdateFriend()
end

--添加好友
function FriendSystem.ProcessAddFriend()
	log("FriendSystem.ProcessAddFriend add")
	--更新组队信息
	TeamUPFriendUI.UpdateFriend()
	LobbyChatSystem.UpdateFriend()
end

--删除好友
function FriendSystem.ProcessDeleteFriend(uid)
	log("FriendSystem.ProcessDeleteFriend del")
	--更新组队信息
	TeamUPFriendUI.UpdateFriend()
	LobbyChatSystem.UpdateFriend()
	LobbyChatSystem.DeleteFriend(uid)
end

--状态变更（组队状态）[好友那边做定时拉取派发状态更新]
function FriendSystem.ProcessStateChange()
	log("FriendSystem.ProcessStateChange status")

	--更新组队状态
	TeamUPFriendUI.UpdateAllFriendStatus()
	LobbyChatSystem.UpdateFriend()
	--FriendSystem.RefreshFriendList()
end

--状态变更（在线状态）
function FriendSystem.ProcessOnlineStateChange()
	log("FriendSystem.ProcessOnlineStateChange online")

	--更新组队好友在线状态
	TeamUPFriendUI.UpdateOnlineNum()
	LobbyChatSystem.UpdateFriend()
	--FriendSystem.RefreshFriendList()
end

-- 获取单个好友数据
function FriendSystem.GetFriendDataByGID(gid)
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_All_Friend_Profile[i].gid) == tonumber(gid) then
			return BP_ARRAY_All_Friend_Profile[i]
		end
	end
	return nil
end



-- 获取单个平台好友数据
function FriendSystem.GetPlatFriendDataByGID(gid)
	for i = #BP_ARRAY_Plat_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_Plat_Friend_Profile[i].gid) == tonumber(gid) then
			return BP_ARRAY_Plat_Friend_Profile[i]
		end
	end
	return nil
end

-- 获取单个内部好友数据
function FriendSystem.GetInnerFriendDataByGID(gid)
	for i = #BP_ARRAY_Inner_Friend_Profile,1,-1 do
		if tonumber(BP_ARRAY_Inner_Friend_Profile[i].gid) == tonumber(gid) then
			return BP_ARRAY_Inner_Friend_Profile[i]
		end
	end
	return nil
	
end

-- 根据昵称获取好友信息
function FriendSystem.GetFriendDataByNickname(nickname)
	for i = #BP_ARRAY_All_Friend_Profile,1,-1 do
		if BP_ARRAY_All_Friend_Profile[i].nickName == nickname then
			return BP_ARRAY_All_Friend_Profile[i];
		end
	end
	return nil;
end

-- 是否是好友
function FriendSystem.IsMyFriend(gid)
	local isFriend = false
	
	--被拉黑属不属于于好友？
	
	if ID_PLAT_FRIENDLIST ~= nil then
		for i = #ID_PLAT_FRIENDLIST,1,-1 do
			if tonumber(ID_PLAT_FRIENDLIST[i]) == tonumber(gid) then
				isFriend = true
				break
			end
		end
	end

	if ID_INNER_FRIENDLIST ~= nil then
		for i = #ID_INNER_FRIENDLIST,1,-1 do
			if tonumber(ID_INNER_FRIENDLIST[i]) == tonumber(gid) then
				isFriend = true
				break
			end
		end
	end

	return isFriend
end

-- 是否被拉黑
function FriendSystem.IsPulBlack(gid)
	local isPullBlack = false
	for i = #BP_ARRAY_Friend_ID_Blacklist,1,-1 do
		if tonumber(BP_ARRAY_Friend_ID_Blacklist[i]) == tonumber(gid) then
			isPullBlack = true
			break
		end
	end
	return isPullBlack
end

function FriendSystem.IsPlatFriend(gid)
	local isPlat = false
    for k,v in pairs(ID_PLAT_FRIENDLIST) do
        if tonumber(v) == tonumber(gid) then
            isPlat = true
            break
        end
    end
	return isPlat
end

function FriendSystem.IsInnerFriend(gid)
	local isInner = false
	for k,v in pairs(ID_INNER_FRIENDLIST) do
		if tonumber(v) == tonumber(gid) then
			isInner = true
			break
		end
	end
	return isInner
end

-- 是否是游戏好友但不是平台好友
function FriendSystem.IsInnerFriendNotPlatFriend(gid)
	local isInner = false
    
    for k,v in pairs(ID_INNER_FRIENDLIST) do
        if tonumber(v) == tonumber(gid) then
            isInner = true
            break
        end
    end
    
    if not isInner then
        return false
    end
    
    local isPlat = false
    for k,v in pairs(ID_PLAT_FRIENDLIST) do
        if tonumber(v) == tonumber(gid) then
            isPlat = true
            break
        end
    end
  
    if not isPlat then
        return true
    else 
        return false
    end
end

function FriendSystem.on_notify_friend_redpoint_chg(redpoint_pos)
    log("FriendSystem.on_notify_friend_redpoint_chg:"..redpoint_pos);
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_FRIEND, true)
    EventSetXYAPIShowRedPoint();
end

--[[网络回调]]--
s2c["get_all_friendlist_rsp"] = FriendSystem.on_get_all_friendlist_rsp

s2c["add_inner_friend_rsp"] = FriendSystem.on_add_inner_friend_rsp
s2c["add_inner_friend_notify"] = FriendSystem.on_add_inner_friend_notify

s2c["add_inner_friend_op_rsp"] = FriendSystem.on_add_inner_friend_op_rsp
s2c["add_inner_friend_op_notify"] = FriendSystem.on_add_inner_friend_op_notify
s2c["auto_add_inner_friend_notify"] = FriendSystem.on_auto_add_inner_friend_notify

s2c["del_inner_friend_rsp"] = FriendSystem.on_del_inner_friend_rsp
s2c["del_inner_friend_notify"] = FriendSystem.on_del_inner_friend_notify

s2c["find_uid_by_name_rsp"] = FriendSystem.on_find_uid_by_name_rsp

s2c["get_addfriend_reqlist_rsp"] = FriendSystem.on_get_addfriend_reqlist_rsp
s2c["del_addfriend_req_notify"] = FriendSystem.on_del_addfriend_req_notify

s2c["add_black_list_rsp"] = FriendSystem.on_add_black_list_rsp
s2c["del_black_list_rsp"] = FriendSystem.on_del_black_list_rsp
s2c["get_black_list_rsp"] = FriendSystem.on_get_black_list_rsp

s2c["notify_online_status_chg"] = FriendSystem.on_notify_online_status_chg
s2c["notify_group_status_chg"] = FriendSystem.on_notify_group_status_chg

s2c["get_openid_by_nickname_rsp"] = FriendSystem.get_openid_by_nickname_rsp

s2c["check_and_update_invite_plat_rsp"] = FriendSystem.check_and_update_invite_plat_rsp

s2c["get_recent_teammate_rsp"] = FriendSystem.on_get_recent_teammate_rsp

s2c["present_friend_gold_rsp"] = FriendSystem.on_present_friend_gold_rsp;

s2c["notify_friend_intimacy_chg"] = FriendSystem.notify_friend_intimacy_chg

s2c["friend_redpoint_res"] = FriendSystem.on_notify_friend_redpoint_chg;

s2c["notify_team_result_finished"] = FriendSystem.on_notify_team_result_finished