ProfileMgr = ProfileMgr or
{
	-- 详情数据结构
	profileData = 
	{
		uid = 0,
		city = "",	-- 所在城市
		level = 0,	-- 等级
		lastLoginTime = 0,	-- 上次登录时间
		segment_info = {},	-- 段位数据，数组
		nickName = "",	-- 游戏玩家名称
		platName = "",	-- 平台玩家名称
		sex = 1,	-- 性别
		signature = "",	-- 签名
		lastOnlineTime = 0,	-- 上次在线时间
		vipLevel = 0,	-- vip等级
		picUrl = "",	-- 头像url
		exp = 0,		-- 经验
	},
	
	-- 陌生人详情信息
	dicStrangerProfile = {},
	-- 好友详情信息
	dicFriendProfile = {},
	
	-- 发送请求列表
	dicSendList = {},
	
	sendSeq = 0,
}

-- 获取好友详情数据
function ProfileMgr.GetFriendProfileList(listUid, callback, needRefresh)
	log("[HHF]GetFriendProfileList, total = " .. #listUid .. ", needRefresh = " .. tostring(needRefresh))
	local listGot = {};
	local listNotGet = {};
	
	for k,v in pairs(listUid) do
		if needRefresh == nil or needRefresh == false then
			if ProfileMgr.dicFriendProfile[v] then
				table.insert(listGot, ProfileMgr.dicFriendProfile[v]);
			else
				table.insert(listNotGet, v);
			end
		else
			table.insert(listNotGet, v);
		end
	end
	
	if #listNotGet > 0 then
		ProfileMgr.GetProfileReq(listNotGet, listGot, true, callback, 0);
	elseif callback then
		log("[HHF]GetFriendProfileList has Got, and invoke callback immediately!");
		--log_tree("listGot", listGot);
		callback(listGot);
	end
end

function ProfileMgr.GetProfileReq(listNotGet, listGot, isFriend, callback, type)
	log("[HHF]GetProfileReq, total list.num = " .. #listNotGet .. ", hasRankData = " .. tostring(type));
	-- 分批拉取，每次上限100个
	local numperrequest = 100;
	if #listNotGet <= numperrequest then
		ProfileMgr.BatchGetProfileReq(listNotGet, listGot, isFriend, callback, type);
	else
		local listPerReq = {};
		for k, v in pairs(listNotGet) do
			if #listPerReq == numperrequest then
				ProfileMgr.BatchGetProfileReq(listPerReq, listGot, isFriend, callback, type);
				listPerReq = {};
			else
				table.insert(listPerReq, v);
			end
		end
		if #listPerReq > 0 then
			ProfileMgr.BatchGetProfileReq(listPerReq, listGot, isFriend, callback, type);
		end
	end
end

function ProfileMgr.BatchGetProfileReq(listNotGet, listGot, isFriend, callback, type)
	ProfileMgr.sendSeq = ProfileMgr.sendSeq + 1;
	table.insert(ProfileMgr.dicSendList, {sendSeq = ProfileMgr.sendSeq, listGot = listGot, listNotGet = listNotGet, isFriend = isFriend, callback = callback})
	NetUtil.SendPkg("batch_get_profile_req", ProfileMgr.sendSeq, listNotGet, type);
	log("[HHF]BatchGetProfileReq, ProfileMgr.sendSeq = " .. tostring(ProfileMgr.sendSeq) .. ", list.num = " .. #listNotGet);
end

-- 清理好友数据
function ProfileMgr.ClearFriendProfileList()
	ProfileMgr.dicFriendProfile = {};
end

-- 获取陌生人详情数据
function ProfileMgr.GetProfileList(listUid, callback, needRefresh)	
	local listGot = {};
	local listNotGet = {};
	--log_tree("GetProfileList: listUid", listUid);
	
	for k,v in pairs(listUid) do
		if needRefresh == nil or needRefresh == false then
			if ProfileMgr.dicFriendProfile[v] then
				-- 先去好友里找
				table.insert(listGot, ProfileMgr.dicFriendProfile[v]);
			elseif ProfileMgr.dicStrangerProfile[v] then
				-- 再去陌生人里找
				table.insert(listGot, ProfileMgr.dicStrangerProfile[v]);
			else
				table.insert(listNotGet, v);
			end
		else
			table.insert(listNotGet, v);
		end
	end	
	
	--log_tree("listGot", listGot);
	--log_tree("listNotGet", listNotGet);
		
	if #listNotGet > 0 then
		log("[HHF]ProfileMgr.GetProfileList, too many invokes.");
		ProfileMgr.GetProfileReq(listNotGet, listGot, false, callback, 0);
	elseif callback then	
		log("GetProfileList has got");
		callback(listGot);
	end
end

function ProfileMgr.GetRankProfileList(listUid, callback)
	log("[HHF]ProfileMgr.GetRankProfileList.");
	listGot = {};
	ProfileMgr.GetProfileReq(listUid, listGot, false, callback, 1);
end	

-- 清理陌生人数据
function ProfileMgr.ClearStrangerProfileList()
	ProfileMgr.dicStrangerProfile = {};
end

-- 获取一个陌生人详情数据
function ProfileMgr.GetProfile(uid, callback, needRefresh)
	ProfileMgr.GetProfileList({uid}, callback, needRefresh);
end

-- 详情协议返回
function ProfileMgr.OnBatchGetProfileRsp(sendSeq, res, profileList, hasRankData)
	log("[HHF]OnBatchGetProfileRsp res:" .. res .. ", sendSeq:" .. sendSeq .. ", profileList.num:" .. FuncUtil:CountTable(profileList) .. ", hasRankData:" .. hasRankData);
	if res ~= "ok" then
		DataMgr.ShowMessageBoxByID(res);
		return;	
	end
	--log_tree("[HHF]profileList = ", profileList);
	--log_tree("ProfileMgr.dicSendList", ProfileMgr.dicSendList);
	
	for k,v in pairs(ProfileMgr.dicSendList) do
		if v.sendSeq == sendSeq then
			for kk,vv in pairs(profileList) do
				local data = ProfileMgr.CreateProfileData(kk, vv);	
				
				if tostring(data.uid) == tostring(DataMgr.roleData.uid) then
					-- 是自己的详情数据
					DataMgr.UpdateMyRoleProfileData(data);
				end
				
				-- 存储/更新详情数据
				if v.isFriend then
					ProfileMgr.dicFriendProfile[kk] = data;	
				elseif ProfileMgr.dicFriendProfile[kk] then
					ProfileMgr.dicFriendProfile[kk] = data;	
				else
					ProfileMgr.dicStrangerProfile[kk] = data;
				end
				
				if hasRankData == 1 then
					-- 带有排行榜数据的详情数据
					local dataIncludeRank = ProfileMgr.CreateProfileData(kk, vv);	
					-- 补充排行榜数据
					dataIncludeRank.rankdata = vv.rankdata;
					table.insert(v.listGot, dataIncludeRank);	
				else
					-- 普通详情数据
					table.insert(v.listGot, data);	
				end
			end		
			
			if v.callback then
				log("OnBatchGetProfileRsp callback");
				--log_tree("listGot", v.listGot);
				v.callback(v.listGot);
			end
			
			table.remove(ProfileMgr.dicSendList, k);
			break;
		end
	end
    
    --log_tree("ProfileMgr.OnBatchGetProfileRsp: ProfileMgr.dicSendList, ", ProfileMgr.dicSendList);
end

-- 创建数据
function ProfileMgr.CreateProfileData(uid, profile)
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
	
	return data;
end


---------------------------------获取概要信息公共协议--------------------------------

--回包参数：
--listType			--列表类型
--res				--回包确认
--profileList		--概要信息列表
--systemType		--透传参数，判断是否本系统使用
--s2c["batch_get_profile_rsp"] = ProfileMgr.OnBatchGetProfileRsp;

s2c["batch_get_profile_rsp"] = function(...)
	log("batch_get_profile_rsp..................")
	ProfileMgr.OnBatchGetProfileRsp(...);
	
	--FriendSystem.on_batch_get_profile_rsp(...);
	--RoleInfoSystem.get_role_basic_info_rsp(...);
    --RankSystem.RspRankRoleInfo(...);
	--LobbyChatSystem.on_profile_rsp(...);
	--LobbyChatSystem.on_chatroom_profile_rsp(...);
	--AllianceSystem.on_profile_rsp(...); --车队陌生人申请列表
end


s2c["batch_get_group_and_online_rsp"] = function(...)
	FriendSystem.on_batch_get_group_and_online_rsp(...);-- 返回好友在线和组队信息
	TeamUpSystem.on_stranger_staus_rsp(...); --返回陌生人状态信息
	LobbyChatSystem.on_chatroom_status_rsp(...); --返回陌生人状态信息
end

