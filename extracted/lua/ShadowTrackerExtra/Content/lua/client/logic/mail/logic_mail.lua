
--[[
 邮件相关逻辑
]]--

MailSystem = MailSystem or
{
	--邮件总列表
	MailInfoList = {},
    --是否有未读邮件
    MailHasNotRead = false,
	RecvCoinMailLeftCount = 10 ,
}

local function localText(id)
    local data = Client.GetTableData("LocalizeRes",id);
    if data then
        return data.TextValue
    end
    return ""
end

--时间转字符串
function MailTimeToStringLost(tm)
    if type(tm) ~= "number" then
        return ""
    end
    tm = math.modf(tm)
    local nowtime = NetUtil.GetCurServerTime()
    local last_tm = nowtime - tm
    local days = math.modf(last_tm / (60*60*24))
    if days >= 1 then
        --return string.format("%d天前", days)
		return string.format(Client.GetTableData("LocalizeRes",301146).TextValue, days);
    end
    local hours = math.modf(last_tm / (60*60))
    if hours >= 1 then
        --return string.format("%d小时前", hours)
        return string.format(Client.GetTableData("LocalizeRes",301147).TextValue, hours);
    end
    local mins = math.modf(last_tm / 60)
    if mins >= 1 then
        --return string.format("%d分钟前", mins)
        return string.format(Client.GetTableData("LocalizeRes",301148).TextValue, mins);
    end
	if last_tm < 1 then
        last_tm = 1
    end
    --return string.format("%d秒前", last_tm)
    return string.format(Client.GetTableData("LocalizeRes",301149).TextValue, last_tm);
end

--时间转换成XXX小时/天
function MailTimeToStringHours(h)
    if type(h) ~= "number" then
        return ""
    end
    h = math.floor(h)
	local days = math.floor(h / 24)
    if days >= 1 then
        days = math.ceil(h / 24)
        --return string.format("%d天", days)
        return string.format(Client.GetTableData("LocalizeRes",301153).TextValue, days)
    end
	--return string.format("%d小时", h)
	return string.format(Client.GetTableData("LocalizeRes",301155).TextValue, h)
end

--读取

--剩余时间
function MailTimeToStringLeftDay(tm,addlefttm)
    tm = math.modf(tm)
    addlefttm = math.modf(addlefttm)
    local nowtime = NetUtil.GetCurServerTime()
    local left_tm = (tm+addlefttm)-nowtime
    local days = math.ceil(left_tm / (60*60*24))
    if days >= 0 then
        --return string.format("剩余%d天", days)
        return string.format(Client.GetTableData("LocalizeRes",301272).TextValue, days)
    end
    return ""
end

function MailSystem.Enter()
	--log("MailSystem enter"); 
	MailSystem.get_friend_misc_info_req();
	MailSystem.query_mail_summary_req()
	
end

function MailSystem.Release()
	--log("MailSystem release");
end

function MailSystem.add_test_mails()
	--NetUtil.SendPkg("exec", [[gm_send_mail("", "版本更新说明", "亲爱的玩家，目前版本更新到V0.02版本，更新时间从2017年12月2日9时至2017年12月2日18时，有不便之处敬请谅解。更新后会有玩家补偿哦！", nil, {type = 1, top = true})]]);
	--NetUtil.SendPkg("exec", [[gm_send_mail("", "游戏活动", "亲爱的玩家，目前游戏官方有福利活动，请玩家前往<a id=\"MailHyLink\" style=\"MailLink\" url=\"http://pg.qq.com/\">官网</>进行参与。祝您游戏愉快！", nil, {type = 1, top = false})]]);
	--NetUtil.SendPkg("exec", [[gm_send_mail("", "充值补发", "亲爱的玩家，补发已到帐，请查收。祝您游戏愉快。", {items = {[402002] = 1, [402001] = 1}}, {type = 1, top = false})]]);
    --NetUtil.SendPkg("exec", [[gm_send_mail("", "通知", "亲爱的玩家，目前版本更新到V0.02版本，更新时间从2017年12月2日9时至2017年12月2日18时，有不便之处敬请谅解。更新后会有玩家补偿哦！", nil, {type = 1, top = false})]]);
    for i=1,5 do
        NetUtil.SendPkg("exec", [[gm_send_mail("", "充值补发1", "亲爱的玩家，补发已到帐，请查收。祝您游戏愉快。", {items = {[40604009] = 1}}, {type = 1, top = false})]]);
    end
    for i=1,5 do
        NetUtil.SendPkg("exec", [[gm_send_mail("", "充值补发2", "亲爱的玩家，补发已到帐，请查收。祝您游戏愉快。", {items = {[401009] = 1, [403021] = 1}}, {type = 1, top = false})]]);
    end
	--log("add_test_mails exec ");
end

--请求邮件摘要
function MailSystem.query_mail_summary_req()
	--log("query_mail_summary_req");
	NetUtil.SendPriorityPkg(false, "on_query_mail_summary_res", "on_query_mail_summary");
end

--改变邮件读取状态
function MailSystem.set_mail_readflag(themailid, readflag)
	--log("set_mail_readflag, id:" .. themailid);
	NetUtil.SendPkg("on_set_mail_readflag", themailid, readflag);
	--后台不返回信息，客户端直接改状态
	MailSystem.MailInfoList[themailid].mail_readtag = readflag;
    MailSystem.CheckNotRead();
end

--获取邮件附件
function MailSystem.fetch_mail_attach(mailid)
	--log("fetch_mail_attach: " .. mailid);
	NetUtil.SendPriorityPkg(false, "on_fetch_attach_res", "on_fetch_mail_attach", mailid);
end

--删除邮件
function MailSystem.delete_mail_list_notify(mailidlist)
	--log_tree("delete_mail_list", mailidlist);
	NetUtil.SendPkg("on_delete_mail_list", mailidlist);
	--log_tree("delete_mail_list_notify", MailSystem.MailInfoList);
end

--获取摘要响应
function MailSystem.on_query_mail_summary_res(mailslist)
	--刷新列表信息
	--log_tree("mailslist", mailslist);
	MailSystem.MailInfoList = {};
    local addtm_top = 300000000
    local addtm_att = 200000000
    local addtm_nor = 100000000
	local curTime = FuncUtil.GetServerTimeInSec()
	local blackmaillist = {}
	for k,v in pairs(mailslist) do
        local minfo =
        {
            mail_id = k,
            mail_type = v.opt.type,
			mail_subtype = v.opt.subtype,
            mail_top = false,
            mail_title = v.title,
            mail_content = v.content,
            mail_time = MailTimeToStringLost(v.time),
            mail_readtag = v.read,
            mail_sender = v.sender,
			mail_sendername = v.sendername,
			mail_sender_uid = v.opt.sender_uid,
            mail_withattach = false,
            mail_attachtag = false,
            mail_sort = v.time,
            BP_ARRAY_MailAttachList = {},
        };
		
		local isInBlackList = false
		--好友邮件处理
		if minfo.mail_type ~= nil and minfo.mail_type == 2 then
			minfo.mail_sender_presentedcoin = 1	
			
			isInBlackList = FriendSystem.IsPulBlack(minfo.mail_sender_uid)
			if isInBlackList then
				table.insert(blackmaillist,minfo.mail_id)
			end
			
			local friend = FriendSystem.GetFriendDataByGID(minfo.mail_sender_uid)
			--log_tree("FriendSystem.GetFriendDataByGID=",friend );
			if friend ~= nil then
				minfo.mail_sender_iconUrl = friend.picUrl
				minfo.mail_sender_gender = friend.sex 
				
				if minfo.mail_subtype ~= nil and tonumber(minfo.mail_subtype) == 1 then
					-- subtype=1代表是赠送金币的邮件,是否赠送过金币
					local lastPresentCoinTime = friend.lastPresentCoinTime or 0
					if lastPresentCoinTime ~= nil and FuncUtil.IsSameDay(curTime, lastPresentCoinTime) == false then
						minfo.mail_sender_presentedcoin = 0
					end
				end
			end
		end
		
		
        if v.opt.top then
            minfo.mail_top = true
        end
        if v.opt.from_idip ~= nil then
            minfo.mail_title = FuncUtil:DecodeURI(minfo.mail_title)
            minfo.mail_content = FuncUtil:DecodeURI(minfo.mail_content)
        end
        local addlefttm = 30*24*3600
        if type(v.opt.expire_hours) == "number" then
            addlefttm = v.opt.expire_hours*3600;
        end
        minfo.mail_lefttime = MailTimeToStringLeftDay(v.time, addlefttm)
        local attach = v.attachments;
        if (attach and attach.items) then
            minfo.mail_attachtag = attach.fetched;
            for attachK, attachV in pairs(attach.items) do
                local m = {
                    attach_id = attachK,
                    attach_count = attachV,
                    attach_valid = 0,
                };
                if type(v.opt.dyn_attr_list) == "table" then
                    local dyn = v.opt.dyn_attr_list[m.attach_id]
                    if dyn and type(dyn.valid_hours) == "number" then
                        local h = math.floor(dyn.valid_hours)
                        if h > 0 then
                            --m.attach_valid = MailTimeToStringHours(h)
                            m.attach_valid = h
                        end
                    end
                end
                table.insert(minfo.BP_ARRAY_MailAttachList, m);
            end
            if #minfo.BP_ARRAY_MailAttachList > 0 then
                minfo.mail_withattach = true;
            end
            if minfo.mail_attachtag then
                minfo.mail_readtag = true;
            end
        end
        if minfo.mail_top then
            minfo.mail_sort = minfo.mail_sort + addtm_top;
        end
        if not minfo.mail_readtag then
            if minfo.mail_withattach then
                minfo.mail_sort = minfo.mail_sort + addtm_att;
            else
                minfo.mail_sort = minfo.mail_sort + addtm_nor;
            end
        end
		
		if isInBlackList == false then
			MailSystem.MailInfoList[k] = minfo;
		end
		
	end
    MailSystem.CheckNotRead()

	--log_tree("MailInfoList", MailSystem.MailInfoList);
	--更新邮件数据
	EventSystem:postEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_LIST);
	--黑名单好友的邮件直接删除
	if #blackmaillist > 0 then
		MailSystem.delete_mail_list_notify(blackmaillist)
	end
	
end

--获取邮件附件响应
function MailSystem.on_fetch_attach_res(state, mailid)
	--log("on_fetch_attach_res: " .. state)
	--log("mailid: "..mailid)
	if state == 0 then
        MailSystem.MailInfoList[mailid].mail_readtag = true
        MailSystem.set_mail_readflag(mailid, true)
		MailSystem.MailInfoList[mailid].mail_attachtag = true
		EventSystem:postEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_RECVITEM, mailid)
    else
        EventSystem:postEvent(EVENTTYPE_MAIL, EVENTID_MAIL_ERROR, state)
	end
end

--接收到新邮件
function MailSystem.on_new_mail_notify(mail_type, subtype, sender_uid)
	--log("on_new_mail_notify: ")
	if mail_type == 2 and subtype == 1 then
		if FriendSystem.IsPulBlack(sender_uid) == false and MailSystem.RecvCoinMailLeftCount > 0 then
			MailSystem.MailHasNotRead = true
			LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_MAIL, MailSystem.MailHasNotRead)
		end
	else
		MailSystem.MailHasNotRead = true
		LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_MAIL, MailSystem.MailHasNotRead)
	end

end


--拉取好友邮件收取剩余次数
function MailSystem.get_friend_misc_info_req()

	NetUtil.SendPkg("get_friend_misc_info_req")
end


function MailSystem.on_get_friend_misc_info_rsp(result)
	--log_tree("on_get_friend_misc_info_rsp", result);
	if result ~=nil and result.recvLeftGoldCnt ~= nil then
		MailSystem.RecvCoinMailLeftCount = result.recvLeftGoldCnt
		MailSystem.CheckNotRead();
		MailUI.Mail_CalcUnreadNum();
		MailUI.RefreshUI();
	end 
end




--批量收取好友邮件
function MailSystem.batch_fetch_friend_mail_req(list)
	--list: 邮件id列表, list={[1]=mail_id1, [2]=mail_id2, ...}  subtype: 好友邮件子类型 默认是1(赠送金币)，后面有问题找iphone
	NetUtil.SendPriorityPkg(false, "batch_fetch_friend_mail_rsp", "batch_fetch_friend_mail_req",list,1);
end




--批量收取好友邮件 ,List: 邮件id列表, list={[1]={id=mail_id1, res=res}, [2]={id=mail_id2, res=res}, ...},  
--res: 成功: "ok"; 次数限制: "limit"; 背包满: "full"; 临时锁: "locked"; 邮件不存在:  "no_mail"; 附件不存在: "no_attach"; 已经领取过: "already"; 不是好友邮件: "type_mismatch"
function MailSystem.on_batch_fetch_friend_mail_rsp(list,subtype)
	--处理赠送金币邮件
	
	--log_tree("on_batch_fetch_friend_mail_rsp", list);
	
	if subtype == 1 then
		local maillist = {};		--成功收取的邮件
		local mailpresentlist = {};		--返赠并且需要通知对方的平台好友
		local item =  {res_id = 0, count = 0}
		local res = "";
		
		
		local function isInPresentList( openid )
		
			for presentK, presentV in pairs(mailpresentlist) do
				if presentV == openid then
					return true;
				end
			end
			return false;
		end
		
		
		for k, v in pairs(list) do
			if v.res == "ok" then
				local mailinfo = MailSystem.GetMailInfoByID( v.id);
				if mailinfo then 
					table.insert(maillist, v.id)
					
					--叠加奖励一次显示
					for attachK, attachV in pairs(mailinfo.BP_ARRAY_MailAttachList) do
					
						if attachV.attach_id > 0 then
							item.res_id = attachV.attach_id
							item.count = item.count + attachV.attach_count
						end
					end
					
					--返赠对方金币
					if mailinfo.mail_sender_presentedcoin == 0 then
						--回赠金币
						FriendSystem.present_friend_gold_req(mailinfo.mail_sender_uid,1)
						--只有是平台好友，才需要分享(屏蔽重复好友)
						if FriendSystem.IsPlatFriend(mailinfo.mail_sender_uid) and isInPresentList(mailinfo.mail_sender) == false then
							table.insert(mailpresentlist, mailinfo.mail_sender)
						end
						
					end
				end
			else
				--取第一个错误码就OK了
				if res == "" then
					res = v.res ;
				end
			end
		end
		
		
		local function shareToFriend()
			log("MailSystem.on_batch_fetch_friend_mail_rsp.shareToFriend")
			if #mailpresentlist > 0 then
				for presentK, presentV in pairs(mailpresentlist) do
					local params = {openid = presentV,title = localText(200021),desc = localText(200022),adtag = GameCenterADTAG.heart,gameTag="MSG_HEART_SEND"}
					ShareMgr:shareToFriend(params)
				end
				DataMgr.ShowNoticeFastQueueByID(102031);
			end
		end
		
		--流程：弹出获取面板(同时删除邮件)-->关闭后弹出是否分享好友面板-->确定后分享到好友
		
		local function afterGetAttach()
			log("[HHF]MailSystem.on_batch_fetch_friend_mail_rsp.afterGetAttach")
			if #mailpresentlist > 0 then
				--log("MailSystem.on_batch_fetch_friend_mail_rsp.mailpresentlist.length >0")
				
				if GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_WX then
					CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102032), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
				elseif GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_QQ then 
					--CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102028), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
				end
				
			end
		end

		--如果至少领取了一封邮件
		if #maillist > 0 then
			--删除所有领取过的邮件
			--MailSystem.on_delete_mail_list(maillist)
			local items = {}
			table.insert(items, item)
			--弹获得对应物品面板
			CommonItemGetUI:ShowPanelWithCallback(items,afterGetAttach,true);
			--重新拉取邮件
			MailSystem.query_mail_summary_req();
		else
			--如果一份邮件都没有收取成功，提示错误
			if res == "full" then
				DataMgr.ShowNoticeByID(102010);
			elseif res == "limit" then
				DataMgr.ShowNoticeByID(102029);
			else
				---TODO ADD TOTHER ERROR CODE
				DataMgr.ShowNoticeByID(102030);
			end
			
		end
		
		MailSystem.get_friend_misc_info_req();
	end
end

--检查有没有未读邮件
function MailSystem.CheckNotRead()
    MailSystem.MailHasNotRead = false
    for k,v in pairs(MailSystem.MailInfoList) do
        if not v.mail_readtag then
			if v.mail_type == 2 and v.mail_subtype == 1 then
				--好友邮件子类型-金币赠送次数达到上限不需要显示小红点
				if MailSystem.RecvCoinMailLeftCount > 0 then
					MailSystem.MailHasNotRead = true
					break
				end
			else
				MailSystem.MailHasNotRead = true
				break
			end
            
        end
    end
    --log("MailSystem.CheckNotRead="..tostring(MailSystem.MailHasNotRead))
    LobbyUI:LobbyRedPointUpdate(BP_ENUM_LOBBY_MENU_MAIL, MailSystem.MailHasNotRead)
end


--获取邮件信息
function MailSystem.GetMailInfoByID( id)
    
    for k,v in pairs(MailSystem.MailInfoList) do
        if v.mail_id == id then
            return v ;
        end
    end
    return nil
end

--初始化请求红点
function MailSystem.QueryRedpoint()
	--log("MailSystem.QueryRedpoint")
	MailSystem.get_friend_misc_info_req();
    NetUtil.SendPkg("on_query_mail_summary");
end

--[[网络回调]]--
s2c["on_query_mail_summary_res"] = MailSystem.on_query_mail_summary_res
s2c["on_fetch_attach_res"] = MailSystem.on_fetch_attach_res
s2c["on_new_mail_notify"] = MailSystem.on_new_mail_notify
s2c["batch_fetch_friend_mail_rsp"] = MailSystem.on_batch_fetch_friend_mail_rsp

s2c["get_friend_misc_info_rsp"] = MailSystem.on_get_friend_misc_info_rsp

