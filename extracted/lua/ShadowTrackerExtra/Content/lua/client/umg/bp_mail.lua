--邮件UI
MailUI = MailUI or
{
    --开始收取所以附件邮件
    BeginReceiveAll = false,
}

--筛选类型 sys friend
Mail_Filter_Type = "sys";
Mail_Select_ID = 0;
Mail_Sys_Unread_Count = 0;
Mail_Friend_Unread_Count = 0;
Mail_Notice_Unread_Count = 0;
Mail_Count = 0;
Mail_Max_Count = 60;

--邮件信息列表(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
BP_ARRAY_MailList = 
{
	BP_STRUCT_MailInfo =
    {
        mail_id = 0,
        mail_type = 0,      --opt.type:邮箱类型[1:系统 2:好友 3:消息中心]
		mail_subtype = 0,	--opt.subtype:邮箱字类型，0为默认值，1代表金币赠送邮件
        mail_top = false,   --opt.top:是否置顶
        mail_title = "",
        mail_content = "",
        mail_sender = "",   --发送者openid
		mail_sendername = "", --发送者名字
        mail_time = "",
        mail_lefttime = "",
        mail_readtag = false,
        mail_withattach = false,
        mail_attachtag = false,
        mail_sort = 0,
		
		--begin好友邮件-发送者相关信息
		mail_sender_uid = "",
		mail_sender_iconUrl= "",
		mail_sender_gender = 0 ,
		mail_sender_presentedcoin = 1, --是否赠送过金币，0为没有赠送，1代表赠送过
		--end好友邮件-发送者相关信息
		
        BP_ARRAY_MailAttachList = 
        {
            BP_STRUCT_MailAttach = {
                attach_id = 0,
                attach_count = 0,
                attach_valid = 0,
            },
        },
    },
};

--注册Widget
function bp_mail_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_mail,
		{{Path="/Game/UMG/UI_BP/Mail/Mail_BP.Mail_BP_C", Container="Default", ZOrder=BP_ENUM_UI_MAIL_ZORDER}},
		{"Lobby"},
		false,
		bp_mail_OnModeSwitched ~= nil,
		true
	);
end

--跳转到Lobby
function bp_mail_OnModeSwitched(gamestatus)
	--log("bp_mail_OnModeSwitched gamestatus = " .. gamestatus);
	if string.lower(gamestatus) == "lobby" then
        --拉取邮件请求红点
        MailSystem.QueryRedpoint()
	end
end

local function localText(id)
    local data = Client.GetTableData("LocalizeRes",id);
    if data then
        return data.TextValue
    end
    return ""
end

local function MailEventHandler(eventType, eventID, vars)
	if eventType ~= EVENTTYPE_MAIL then
		return;
	end
	--全列表更新
	if eventID == EVENTID_MAIL_UPDATE_LIST then
		--log("EVENTID_MAIL_UPDATE_LIST");
		MailUI.UnifyData();
		MailUI.RefreshUI();
	end
	--列表条目更新
	if eventID == EVENTID_MAIL_UPDATE_ITEM then
		MailUI.UnifyData();
		MailUI.UpdateMailItem();
	end
    --获取得附件
    if eventID == EVENTID_MAIL_UPDATE_RECVITEM then
		MailUI.UnifyData();
		MailUI.UpdateOneMailItem(vars);
        MailUI.ShowRecvAttach(vars);
	end
    --错误处理
    if eventID == EVENTID_MAIL_ERROR then
        --log("EVENTID_MAIL_ERROR")
        DataMgr.ShowMessageBoxByID(vars)
	end
end

function MailUI.Init()
	LuaClassObj.HandleDynamicCreation(bp_mail);
	--log("MailUI_Init");
    MailUI.EndMailReceiveAll();
	EventSystem:registEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_LIST, MailEventHandler);
	EventSystem:registEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_ITEM, MailEventHandler);
    EventSystem:registEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_RECVITEM, MailEventHandler);
    EventSystem:registEvent(EVENTTYPE_MAIL, EVENTID_MAIL_ERROR, MailEventHandler);
	LuaClassObj.HandleUIMessage(bp_mail, "ShowUI");
end

function MailUI.Release()
	EventSystem:unregistEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_LIST, MailEventHandler);
	EventSystem:unregistEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_ITEM, MailEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_MAIL, EVENTID_MAIL_UPDATE_RECVITEM, MailEventHandler);
    EventSystem:unregistEvent(EVENTTYPE_MAIL, EVENTID_MAIL_ERROR, MailEventHandler);
end

--通知UI刷新列表
function MailUI.RefreshUI()
	--log("RefreshUI");
	LuaClassObj.HandleUIMessage(bp_mail, "RefreshUI");
end

--通知UI刷新条目
function MailUI.UpdateMailItem()
	--log("UpdateMailItem");
	LuaClassObj.HandleUIMessage(bp_mail, "UpdateMailItem");
end

--通知UI刷新单个条目
Mail_UpdateOneMailItem = 0;
function MailUI.UpdateOneMailItem(mailid)
	--log("UpdateOneMailItem");
    Mail_UpdateOneMailItem = mailid;
	LuaClassObj.HandleUIMessage(bp_mail, "UpdateOneMailItem");
end

--通知获得物品
Mail_ShowRecvAttachMailId = 0;

function MailUI.ShowRecvAttach(mailid)
    --log("ShowRecvAttach");
    local mailInfo = MailSystem.MailInfoList[mailid];
    if mailInfo then
        Mail_ShowRecvAttachMailId = mailid;
        --LuaClassObj.HandleUIMessage(bp_mail, "ShowRecvAttach");
        --稀有道具分享
        local itms = {}
        for i,v in ipairs(mailInfo.BP_ARRAY_MailAttachList) do
            table.insert(itms, {res_id = v.attach_id, count = v.attach_count, valid_hours = v.attach_valid})
        end
		
		local function shareToFriend()
			local params = {openid = mailInfo.mail_sender,title = localText(200021),desc = localText(200022),adtag = GameCenterADTAG.heart,gameTag="MSG_HEART_SEND"}
			ShareMgr:shareToFriend(params)
			DataMgr.ShowNoticeFastQueueByID(102031);
		end
		
		local function afterGetAttach()
			log("[HHF]MailUI.ShowRecvAttach.afterGetAttach");
			if GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_WX then
				CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102032), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
			elseif GlobalData:GetPlatform() == BP_ENUM_PLAYFORM_QQ then 
				--CommonMessageBoxUI:ShowPanel(2, DataMgr.GetMsgByID(102012), DataMgr.GetMsgByID(102028), shareToFriend,nil,DataMgr.GetMsgByID(102027),DataMgr.GetMsgByID(102026));
			end
			
		end
		
        if #itms > 0 then
			--是否是赠送金币，并可以回赠
			if mailInfo.mail_type ~= nil and mailInfo.mail_type == 2 then
				
				
				--弹出获得物品
				if mailInfo.mail_sender_presentedcoin == 0 then
					--返赠金币
					FriendSystem.present_friend_gold_req(mailInfo.mail_sender_uid,1)
					MailSystem.get_friend_misc_info_req()
					if FriendSystem.IsPlatFriend(mailInfo.mail_sender_uid) then
						CommonItemGetUI:ShowPanelWithCallback(itms,afterGetAttach,true);
					else
						CommonItemGetUI:ShowPanel(itms);
					end
				else
					CommonItemGetUI:ShowPanel(itms);
				end
				
				
				MailSystem.delete_mail_list_notify({mailid});
				EventMailRequestList();
				LuaClassObj.HandleUIMessage(bp_mail, "HideMailDetail");
				
			else
                local function funcGoodItem()
                    GoodItemGetUI:ShowGetPanelWithCallback(itms, EventMailReceiveAllNext)
                    if GoodItemGetUI.isShow == false then
                        EventMailReceiveAllNext()
                    end
                end
                CommonItemGetUI:ShowPanelWithCallback(itms,funcGoodItem,true);
			end
        end
    end
end

--组织数据
function MailUI.UnifyData()
	--log("MailUI_UnifyData");
	BP_ARRAY_MailList = {};
	Mail_Count = 0;
    --log_tree("MailSystem.MailInfoList", MailSystem.MailInfoList);
	for k,v in pairs(MailSystem.MailInfoList) do
		--系统邮件
		if (v.mail_type == 1 and Mail_Filter_Type == "sys") then
			table.insert(BP_ARRAY_MailList, v);
			Mail_Count = Mail_Count + 1;
		end
		--好友邮件
		if (v.mail_type == 2 and Mail_Filter_Type == "friend") then
			table.insert(BP_ARRAY_MailList, v);
			Mail_Count = Mail_Count + 1;
		end
        --消息中心
		if (v.mail_type == 3 and Mail_Filter_Type == "notice") then
			table.insert(BP_ARRAY_MailList, v);
			Mail_Count = Mail_Count + 1;
		end
	end
	MailUI.Mail_CalcUnreadNum();
    local function comps(a1, a2)
        return a1.mail_sort > a2.mail_sort;
    end
    table.sort(BP_ARRAY_MailList, comps);
	--log_tree("BP_ARRAY_MailList", BP_ARRAY_MailList);
end

--计算未读邮件数量
function MailUI.Mail_CalcUnreadNum()
	Mail_Sys_Unread_Count = 0;
	Mail_Friend_Unread_Count = 0;
    Mail_Notice_Unread_Count = 0;
	for k,v in pairs(MailSystem.MailInfoList) do
		--系统邮件
		if v.mail_type == 1 then
			-- 邮件未读或者有附件而未领取
			if not v.mail_readtag then
				Mail_Sys_Unread_Count = Mail_Sys_Unread_Count + 1;
			end
		end
		--好友邮件
		if v.mail_type == 2 then
			-- 邮件未读或者有附件而未领取,且好友赠送金币达到上限
			if not v.mail_readtag then
				if v.mail_subtype == 1 then
					--log("MailUI.Mail_CalcUnreadNum:" .. MailSystem.RecvCoinMailLeftCount);
					if MailSystem.RecvCoinMailLeftCount > 0 then
						Mail_Friend_Unread_Count = Mail_Friend_Unread_Count + 1;
					end
				else
					Mail_Friend_Unread_Count = Mail_Friend_Unread_Count + 1;
				end
				
			end
		end
        --消息中心
		if v.mail_type == 3 then
			-- 邮件未读或者有附件而未领取
			if not v.mail_readtag then
				Mail_Notice_Unread_Count = Mail_Notice_Unread_Count + 1;
			end
		end
	end
end

--开始收取全部附件
function MailUI.BeginMailReceiveAll()
    if MailUI.BeginReceiveAll then
        local mail_id = nil;
        --log_tree("BP_ARRAY_MailList", BP_ARRAY_MailList);
        for i,v in ipairs(BP_ARRAY_MailList) do
            if v.mail_withattach and not v.mail_attachtag then
                mail_id = v.mail_id;
                break;
            end
        end
        if mail_id then
            --log("MailUI.BeginMailReceiveAll:" .. mail_id);
            MailSystem.fetch_mail_attach(mail_id);
        else
            DataMgr.ShowNoticeByID(102015);
            MailUI.EndMailReceiveAll();
        end
    end
end

--结束收取全部附件
function MailUI.EndMailReceiveAll()
    MailUI.BeginReceiveAll = false;
end

--邮件超链接
Mail_OpenUrl = "";
function MailUI.OnHyperLinkClicked(MetaData)
    LuaClassObj.HandleUIMessage(bp_mail, "PlaySoundClick");
    --log_tree("MailUI.OnHyperLinkClicked", MetaData)
    if MetaData.id == "MailHyLink" and type(MetaData.url) == "string" then
        Mail_OpenUrl = MetaData.url
        --LuaClassObj.HandleUIMessage(bp_mail, "OpenUrl");
        GlobalData:JumpUrl(MetaData.url)
    end
end

function MailUI.TestData()
    Mail_Count = math.random(0,100);
    Mail_Sys_Unread_Count = 10;
    Mail_Friend_Unread_Count = 20;
    Mail_Notice_Unread_Count = 30;
    BP_ARRAY_MailList = {};
	for i=1,Mail_Count do
        local itm = {
            mail_id = i,
            mail_type = 1,      --opt.type:邮箱类型[1:系统 2:好友 3:消息中心]
            mail_top = false,   --opt.top:是否置顶
            mail_title = "aaaaaa",
            mail_content = "bbbbbbbbbbbbb"..i,
            mail_sender = "",
            mail_time = MailTimeToStringLost(os.time()-math.random(1,100000)),
            mail_lefttime = MailTimeToStringLeftDay(math.random(1,100000)),
            mail_readtag = false,
            mail_withattach = false,
            mail_attachtag = false,
            BP_ARRAY_MailAttachList = 
            {
                {attach_id = 3, attach_count = 1},
                {attach_id = 3, attach_count = 1},
            },
        }
		table.insert(BP_ARRAY_MailList, itm)
	end
    MailUI.RefreshUI()
end

--(以Event开头的函数名就能暴露给蓝图调用)

--添加测试邮件
function EventMailAddTestDatas()
	MailSystem.add_test_mails();
end


BP_MailClickHead_UID=""
function EventOnClickHead_Push()
	log("EventOnClickHead = " .. BP_MailClickHead_UID);
	RoleInfoSystem.Enter(BP_MailClickHead_UID);
	RoleInfoUI.Init();
	
end


--选择类型
function EventMailChangeFilterType()
	--设置新的筛选类型
	--log("Mail_Filter_Type = " .. Mail_Filter_Type);
	
	--重设被选中的邮件
	Mail_Select_ID = 0;
	--log("Mail_Select_ID = " .. Mail_Select_ID);
	
	MailUI.UnifyData();
	MailUI.RefreshUI();
    --MailUI.TestData();
end

--请求邮件列表
function EventMailRequestList()
	--log("EventMailRequestList");
	MailSystem.query_mail_summary_req();
end

--读邮件
function EventMailRead()
	--后台不返回信息，客户端直接改状态
	local mailid = math.tointeger(Mail_Select_ID);
    local mailInfo = MailSystem.MailInfoList[mailid];
    if mailInfo then
        if mailInfo.mail_type == 1 and mailInfo.mail_withattach and not mailInfo.mail_attachtag then
            return
        end
        for k,v in pairs(BP_ARRAY_MailList) do
            if (v.mail_id == mailid) then
                v.mail_readtag = true
                MailSystem.set_mail_readflag(mailid, true);
                MailUI.Mail_CalcUnreadNum();
                return
            end
        end
    end
end

--收取附件
function EventMailReceiveAttach()
	local mailid = math.tointeger(Mail_Select_ID);
    local mailInfo = MailSystem.MailInfoList[mailid];
	if mailInfo ~= nil and mailInfo.mail_type == 2 and mailInfo.mail_subtype == 1 then
		MailSystem.batch_fetch_friend_mail_req({mailid})
	else
		MailSystem.fetch_mail_attach(mailid);
	end
    Mail_Select_ID = 0;
    LuaClassObj.HandleUIMessage(bp_mail, "HideMailDetail");
end

--收取全部附件
function EventMailReceiveAll()
	if Mail_Filter_Type == "friend" then
		local mailidlist = {};
		for k, v in pairs(BP_ARRAY_MailList) do
			if v.mail_attachtag == false then
				table.insert(mailidlist, v.mail_id);
			end
		end
		if #mailidlist > 0 then
			MailSystem.batch_fetch_friend_mail_req(mailidlist);
		end
		
	else
		MailUI.BeginReceiveAll = true;
		MailUI.BeginMailReceiveAll();
	end
end
--继续收取全部附件
function EventMailReceiveAllNext()
    MailUI.BeginMailReceiveAll();
end

--删除邮件
function EventMailDelete()
    local mailid = math.tointeger(Mail_Select_ID);
    local function funcDel()
        MailSystem.delete_mail_list_notify({mailid});
        Mail_Select_ID = 0;
        EventMailRequestList();
        LuaClassObj.HandleUIMessage(bp_mail, "HideMailDetail");
        DataMgr.ShowNoticeByID(102011);
    end
    local mailInfo = MailSystem.MailInfoList[mailid];
    if mailInfo and mailInfo.mail_withattach and not mailInfo.mail_attachtag then
        --有附件没领取，提示
        CommonMessageBoxUI:ShowPanel(2, localText(102012), localText(102013), funcDel);
    else
        funcDel();
    end
end

--删除所有已读邮件
function EventMailDeleteAll()

	
	local mailidlist = {};
	for k, v in pairs(BP_ARRAY_MailList) do
		if v.mail_readtag then
			table.insert(mailidlist, v.mail_id);
		end
	end
    if #mailidlist > 0 then
        local function funcDel()
            MailSystem.delete_mail_list_notify(mailidlist);
            Mail_Select_ID = 0;
            EventMailRequestList();
            DataMgr.ShowNoticeByID(102007);
        end
        CommonMessageBoxUI:ShowPanel(2, localText(102012), localText(102002), funcDel);
    else
        DataMgr.ShowNoticeByID(102014);
    end
end

function EventMailClose()
    MailSystem.Release()
    MailUI.Release()
    LuaClassObj.HandleUIMessage(bp_mail, "HideUI");
end



function EventFetchMailInfo()
end