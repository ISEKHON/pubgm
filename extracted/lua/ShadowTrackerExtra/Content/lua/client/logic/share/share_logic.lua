-- 分享类型
ShareType =
{
Friend = 0, -- 分享文字和图片到微信好友orQQ好友
Moment = 1, -- 分享截图到微信朋友圈orQQZone
};


-- 分享输入参数
ShareParam =
{
bShareBigPhoto = false,
iShareType = 0,
strMediaTag = "",
strTitle = "",
strDesc = "",
strImgPath = "",
strMessageExt = "",
strMessageAction = "",
};

-- 结构化消息来源
GameCenterADTAG =
{
["invite"] = "gameobj.msg_invite"; --邀请
["exceed"] = "gameobj.msg_exceed"; --超越
["heart"] = "gameobj.msg_heart"; --送心
["pvp"] = "gameobj.msg_pvp"; --挑战
["show"] = "gameobj.msg_show"; --炫耀
};


-- 分享管理
ShareMgr =
{
-- 分享功能开关
bEnableShare = true;

ShareInfo = {};

ShareLimitInfo = {};

shareDiffTime = 0, --请求CD时间，2秒内视为无效请求

CurShareType = 0;
CurShareItemResid = 0;


};


function ShareMgr:isShareEnable()
	return self.bEnableShare;
end

function ShareMgr:enableShare(bEnable)
	self.bEnableShare = bEnable;
end


-- 文字加默认的图片分享到QQ
function ShareMgr:shareQQ(strMediaTag, strDesc, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = false;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes",200021).TextValue;
	param.strDesc = strDesc;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	
	log("share to qq!");
	Client.QQShare(NetInterface, param.strDesc, param.strTitle, shareData.strImgPath, shareData.strImgUrl, "", param.iShareType);
end

-- QQ URL分享（可以带图）：用于红包
function ShareMgr:shareCJHBQQ(strMediaTag, strDesc, strUrl, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = false;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes", "200025").TextValue;
	param.strDesc = Client.GetTableData("LocalizeRes", "200027").TextValue;
	param.strUrl = strUrl;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	
	if (nil == param.strUrl or "" == param.strUrl) then
		param.strUrl = shareData.strImgUrl;
	end
	
	
	log("share to qq!");
	Client.QQShare(NetInterface, param.strDesc, param.strTitle, shareData.strImgLocalPath, shareData.strImgUrl, param.strUrl, param.iShareType);
end

--邀请测试
function ShareMgr:InviteJoinTeamQQ(teamid)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	local shareData = ShareDataList[MEDIA_TAG_SHARE_INVITE_JOINTEAM];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	local gamedata = {
	team_roleid = DataMgr.roleData.uid;
	team_teamid = teamid;
	}
	
	local str = json.encode(gamedata);
	local encodedstr = FuncUtil:EncodeURI(str);
	local strUrl = ShareMgr:constructQQGameCenterURL(encodedstr, GameCenterADTAG.invite);
	log(strUrl);
	log("InviteJoinTeamQQ!");
	log(shareData.strDesc);
	log(shareData.strImgLocalPath);
	Client.QQShare(NetInterface,
	Client.GetTableData("LocalizeRes", "110105").TextValue,
	Client.GetTableData("LocalizeRes", "110104").TextValue,
	shareData.strImgLocalPath, shareData.strImgUrl, strUrl, shareData.iShareType);
end

function ShareMgr:InviteJoinTeamWX(teamid, battleid)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	local shareData = ShareDataList[MEDIA_TAG_SHARE_INVITE_JOINTEAM];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	local gamedata = {
	team_roleid = DataMgr.roleData.uid;
	team_teamid = teamid;
	}
	
	local str = json.encode (gamedata);
	local encodedstr = FuncUtil:EncodeURI(str);
	log("InviteJoinTeamWX!");
	log(shareData.strDesc);
	log(shareData.strImgLocalPath);
	if (TeamUpSystem.WXPlatformInviteType == 0) then
		Client.WechatShare(NetInterface,
		Client.GetTableData("LocalizeRes", "110105").TextValue, --desc
		Client.GetTableData("LocalizeRes", "110104").TextValue, --title
		shareData.strImgLocalPath, MEDIA_TAG_SHARE_INVITE_JOINTEAM, encodedstr);
	else
		local platform = (string.lower(Client.GetDevicePlatformName()) == "android" and "1" or "0");
		ShareMgr:shareWechatWithMiniApp(
		Client.GetTableData("LocalizeRes", "110105").TextValue, --desc
		Client.GetTableData("LocalizeRes", "110104").TextValue, --title
		"Arts/UI/TableIcons/ShareBg/Share_Miniappinvite4.jpg",
		"https://game.weixin.qq.com/cgi-bin/h5/static/gamecenter/gamelauncher.html?appid=wxc4c0253df149f02d&join=1&message=" .. encodedstr .. "#wechat_redirect",
		"gh_38a40ad4305c",
		"pages/index/index?teamid=" .. tostring(teamid) .. "&platid=" .. platform .. "&battleid=" .. battleid .. "&message=" .. encodedstr,
		"",
		"",
		ShareType.Friend);
	end
	--
	
	
end

-- 带图分享到QQ
function ShareMgr:shareQQWithPhoto(strMediaTag, strDesc, strImgPath, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = true;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes",200021).TextValue;
	param.strDesc = strDesc;
	param.strImgPath = strImgPath;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	
	log("share photo to qq!");
	Client.QQShareWithPhoto(NetInterface, param.strDesc, param.strTitle, param.strImgPath, param.iShareType);
end


-- 带图分享到QQ
function ShareMgr:shareQQWithPhotoExtra(strMediaTag, strImgPath, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = true;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes",200021).TextValue;
	param.strImgPath = strImgPath;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	log("share photo to qq extra!");
	Client.QQShareWithPhotoExtra(NetInterface, param.strImgPath, shareData.strExtraScene, shareData.strMessageExt, param.iShareType);
end

--分享给指定QQ好友
--参数见http://apollo.oa.com/client/wiki/MSDK/index.html#!sns/sns.md#后端分享
function ShareMgr:shareToQQFriend(params)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	if params == nil then
		return;
	end
	
	local gameName = Client.GetTableData("LocalizeRes", "200021").TextValue;
	local inviteString = Client.GetTableData("LocalizeRes", "301283").TextValue;
	
	params.act = params.act or 1;
	params.openid = params.openid;
	params.title = params.title or gameName;
	params.desc = params.desc or inviteString;
	local adtag = params.adtag or GameCenterADTAG.invite;
	local gamedata = params.extendInfo or "";
	local targetUrl = ShareMgr:constructQQGameCenterURL(gamedata, adtag);
	params.targetUrl = params.targetUrl or targetUrl;
	params.imgUrl = params.imgUrl or "http://down.qq.com/jdqssy/Share_Icon.png";
	params.previewText = params.previewText or inviteString;
	params.gameTag = params.gameTag or "MSG_INVITE";
	params.msdkExtInfo = params.msdkExtInfo or "";
	log("share to qq friend!");
	Client.QQShareToFriend(NetInterface, params.act, params.openid, params.title, params.desc, params.targetUrl, params.imgUrl, params.previewText, params.gameTag, params.msdkExtInfo);
end

-- 生成手Q游戏中心URL
-- strGameData: 透传数据，通过quickLogin中的wakeupinfo拉起游戏传回
-- adTag:标识不同的结构化消息来源, 见GameCenterADTAG
function ShareMgr:constructQQGameCenterURL(strGameData, adTag)
	local platform = (string.lower(Client.GetDevicePlatformName()) == "android" and "androidqq" or "iphoneqq");
	local openid = DataMgr.roleData.openID;
	
	return "http://gamecenter.qq.com/gcjump?appid=1106467070&pf=invite&plat=qq&from="
	.. platform .. "&ADTAG=" .. adTag .."&originuin=" .. openid .. "&gamedata=" .. strGameData .. "&platformdata=" .. platform;
end

--添加QQ好友
--参数见http://apollo.oa.com/client/wiki/MSDK/index.html#!sns/sns.md#游戏内加QQ好友
function ShareMgr:addQQFriend(params)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	if params == nil then
		return;
	end
	
	local gameName = Client.GetTableData("LocalizeRes", "200021").TextValue;
	
	params.openid = params.openid;
	params.desc = params.desc or "";
	--params.message = params.message or "绝地求生";
	params.message = params.message or gameName;
	log("add qq friend!");
	Client.QQAddFriend(NetInterface, params.openid, params.desc, params.message);
end

-- 分享到微信
function ShareMgr:shareWechat(strMediaTag, strDesc, messageExt)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = false;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes",200021).TextValue;
	param.strDesc = strDesc;
	param.strMessageExt = messageExt;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	
	log("share to wx!");
	Client.WechatShare(NetInterface, param.strDesc, param.strTitle, shareData.strImgPath, param.strMediaTag, param.strMessageExt);
end


-- 带图片分享到微信
function ShareMgr:shareWechatWithPhoto(strMediaTag, imgPath, messageExt, messageAction,iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = false;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes",200021).TextValue;
	param.strDesc = strDesc;
	param.strImgPath = imgPath;
	param.strMessageExt = messageExt;
	param.strMessageAction = messageAction;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	
	log("share photo to wx!");
	Client.WechatShareWithPhoto(NetInterface, param.strImgPath, param.strMediaTag, param.strMessageExt, param.strMessageAction, param.iShareType);
end

function ShareMgr:shareWechatWithMiniApp(strDesc, strTitle, strImagePath, strWebUrl, strUserName, strPath, strMsgExt, strMsgAction, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	if strTitle == nil or strTitle == "" then
		--strTitle = "拼团领福袋，瓜分豪华礼包！";
		strTitle = Client.GetTableData("LocalizeRes", "301284").TextValue;
	end
	if strDesc == nil or strDesc == "" then
		--strDesc = "拼团领福袋，瓜分豪华礼包！";
		strDesc = Client.GetTableData("LocalizeRes", "301284").TextValue;
	end
	if strUserName == nil or strUserName == "" then
		strUserName = DataMgr.roleData.nickName;
	end
	if strImagePath == nil or strImagePath == "" then
		strImagePath = "Arts/UI/TableIcons/ShareBg/Share_MiniAppSpring.jpg";
	end
	if strPath == nil or strPath == "" then
		log("import msg-path is lost, share break");
		return;
	end
	if strWebUrl == nil or strWebUrl == "" then
		strWebUrl = "https://game.weixin.qq.com/cgi-bin/h5/static/gamecenter/gamelauncher.html?appid=wxc4c0253df149f02d#wechat_redirect"
	end
	
	log("share miniapp to wx");
	Client.WeChatShareWithMiniApp(NetInterface, strDesc, strTitle, strImagePath, strWebUrl, strUserName, strPath, strMsgExt, strMsgAction, iShareType);
end

-- 分享春节红包给好友
function ShareMgr:shareSpringPacketQQ(strDesc, strTitle, strImgPath, strImgUrl, strUrl, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	if strTitle == nil or strTitle == "" then
		--strTitle = 送你一个新春福袋";
		strTitle = Client.GetTableData("LocalizeRes", "301336").TextValue;
	end
	if strDesc == nil or strDesc == "" then
		--strDesc = "快来一起打开新春福袋，可拿到2018Q币和珍藏版春节服饰等奖励";
		strDesc = Client.GetTableData("LocalizeRes", "301337").TextValue;
	end
	if strImgPath == nil or strImgPath == "" then
		strImgPath = "Arts/UI/TableIcons/ShareBg/Share_Icon.jpg";
	end
	if strImgUrl == nil or strImgUrl == "" then
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png";
	end
	if strUrl == nil or strUrl == "" then
		log("import strUrl is lost, share break");
		return;
	end
	
	log("shareSpringPacket to qq!");
	Client.QQShare(NetInterface, strDesc, strTitle, strImgPath, strImgUrl, strUrl, iShareType);
end

--分享给指定微信好友
function ShareMgr:shareToWechatFriend(params)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	if params == nil then
		return;
	end
	
	
	local gameName = Client.GetTableData("LocalizeRes", "200021").TextValue;
	local inviteString = Client.GetTableData("LocalizeRes", "301283").TextValue;
	
	params.openid = params.openid;
	--params.title = params.title or "绝地求生";
	params.title = params.title or gameName;
	--params.desc = params.desc or "邀请上线";
	params.desc = params.desc or inviteString;
	params.mediaId = params.mediaId or MEDIA_ID;
	params.messageExt = params.extendInfo or "";
	params.meditaTagName = params.gameTag or "MSG_INVITE";
	params.msdkExtInfo = params.msdkExtInfo or "";
	log("share to wechat friend!");
	Client.WechatShareToFriend(NetInterface, params.openid, params.title, params.desc, params.mediaId, params.messageExt, params.meditaTagName, params.msdkExtInfo);
end

--[[
微信链接分享
--]]
function ShareMgr:shareWechatUrlInfo(strMediaTag, strDesc, strUrl, strImgPath, iShareType)
	if (not self:isShareEnable()) then
		log("the share system is not open!");
		return;
	end
	
	local param = ShareParam;
	param.bShareBigPhoto = false;
	param.iShareType = iShareType;
	param.strMediaTag = strMediaTag;
	--param.strTitle = "绝地求生";
	param.strTitle = Client.GetTableData("LocalizeRes", "200025").TextValue;
	param.strDesc = Client.GetTableData("LocalizeRes", "200026").TextValue;
	param.strUrl = strUrl;
	param.strImgLocalPath = strImgPath;
	
	local shareData = ShareDataList[param.strMediaTag];
	if (nil == shareData) then
		log(string.format("share: not exist share type(%s)", strMediaTag));
		return;
	end
	if (nil == param.strDesc or "" == param.strDesc) then
		param.strDesc = shareData.strDesc;
	end
	if (nil == param.strImgLocalPath or "" == param.strImgLocalPath) then
		param.strImgLocalPath = shareData.strImgLocalPath;
	end
	
	log("shareWechatUrlInfo to wx");
	Client.WechatShareWithUrlInfo(NetInterface, param.strDesc, param.strTitle, param.strImgLocalPath, param.strUrl, param.iShareType)
end

function ShareMgr:onShareResult(bSuccess, strDesc)
	local param = ShareParam;
	
	log(string.format("onShareResult ret=(%s), desc=(%s), meditaTag=(%s)"
	, tostring(bSuccess), strDesc, param.strMediaTag));
	if bSuccess == 1 then
		--同步给后台分享次数
		--ShareMgr.ShareSuccReq();
		
		--发送限制上报给后台
		ShareMgr.SendShareLimit();
	end
	
	-- 分享结果回调
	local vars = {};
	table.insert(vars,bSuccess);
	table.insert(vars,param.strMediaTag);
	EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL,vars);
	
end

function ShareMgr:shareToFriend(params)
	log_tree("shareToFriend params", params);
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		ShareMgr:shareToWechatFriend(params);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		ShareMgr:shareToQQFriend(params);
	end
end

--***************************************************后台交互逻辑相关******************

--取每日分享次数
function ShareMgr.GetShareNum()
	if ShareMgr.ShareInfo == nil then
		return 0;
	end
	log("ShareMgr.GetShareNum"..tostring(ShareMgr.ShareInfo.num));
	return ShareMgr.ShareInfo.num;
	
end

--取品质分享过的次数
function ShareMgr.GetTraitidNum(traitid)
	if ShareMgr.ShareInfo == nil then
		log("ShareMgr.GetTraitidNum_0");
		return 0;
	end
	
	if ShareMgr.ShareInfo.statics == nil then
		log("ShareMgr.GetTraitidNum_000");
		return 0;
	end
	local num = 0;
	for k,v in pairs(ShareMgr.ShareInfo.statics) do
		if k == traitid then
			num = ShareMgr.ShareInfo.statics[traitid];
			break;
		end
		
	end
	log("ShareMgr.GetTraitidNum"..tostring(num));
	return num;
end

--更新相关面板显示
function ShareMgr.UpdateRelatePanel()
	--TODO更新每日分享面板
	ShareDayUI.UpdateUI();
	ShareAwardUI.UpdateUI();
	RoleInfoUI.UpdateUI();
	LevelUpUI:UpdateUI()
end

--请求分享信息
function ShareMgr.GetShareInfoReq()
	log("ShareMgrGetShareInfoReq");
	NetUtil.SendPkg("get_share_info_request");
end

--分享成功后请求,同步给后台请求次数
--[[
1 获得物品分享
2 每日分享
3 个人战绩分享
4 游戏结算,游戏名次分享
5 游戏结算,游戏数据分享
--]]
function ShareMgr.ShareSuccReq(share_type)
	local timeDiff = os.time() - ShareMgr.shareDiffTime;
	log("ShareSuccReqtimeDiff: "..tostring(timeDiff));
	
	if (timeDiff >= 2) then
		log("ShareMgrShareSuccReq"..share_type);
		ShareMgr.shareDiffTime = os.time();
		NetUtil.SendPkg("share_succ_request",tonumber(share_type));
	end
	
end

--回包和notify一起的
function ShareMgr.onGetShareInfoRsp(data)
	log_tree("onGetShareInfoRsp",data)
	if data == nil then
		log("onGetShareInfoRsp data is none");
		return;
	end
	
	ShareMgr.ShareInfo = data;
	log_tree("ShareMgr.ShareInfo", ShareMgr.ShareInfo);
	
	--更新相关面板
	ShareMgr.UpdateRelatePanel();
	--[[
	data.share = {
	num=0, //每日分享次数，0表示首次
	lasttime=10, //每日首次分享时间
	statics={
	[traitid]=num, //品质id=数量
	}
	}
	--]]
end

--[[
1 获得物品分享
2 每日分享
3 个人战绩分享
4 游戏结算,游戏名次分享
5 游戏结算,游戏数据分享
6 军衔数据分享
7 段位数据分享
8 刺激盛典分享
]]

function ShareMgr.CanShareByType(shareType, itemresid)
--[[
LogNula: LuaLog: ├─ 1
LogNula: LuaLog: │  ├─ itemlist
LogNula: LuaLog: │  │  └─ 405009
LogNula: LuaLog: │  │     ├─ item_res_id: 405009
LogNula: LuaLog: │  │     └─ num: 1
LogNula: LuaLog: │  ├─ share_type: 1
LogNula: LuaLog: │  └─ num: 1
LogNula: LuaLog: └─ 3
LogNula: LuaLog:    ├─ num: 1
LogNula: LuaLog:    └─ share_type: 3
]]

	log("CanShare:"..tostring(shareType)..tostring(itemresid));
	
	local result = true;
	if shareType == 0 then
		return result;
	end
	
	local num = 0;
	if ShareMgr.ShareLimitInfo ~= nil then
		log_tree("CanShare",ShareMgr.ShareLimitInfo);
		local limitData = ShareMgr.ShareLimitInfo[shareType];
		log_tree("limitData aaaaaaa",limitData);
		if limitData == nil then			
			return result;
		end
		
		if shareType == 1 then
			if limitData.itemlist ~= nil then

				local itemData = limitData.itemlist[itemresid];			
				if itemData ~= nil then
					num = itemData.num;
				end
			end			
			
		else
			num = limitData.num;
		end
		
	end
	
	if num > 0 then
		--弹出提示 今天已经分享过了
		DataMgr.ShowNoticeByID(110129);
		--DataMgr.ShowNoticeByString("today has Shared");
		result = false;
	end

	log("limitData result"..tostring(result));
	
	return result;
end

--[[
1 获得物品分享
2 每日分享
3 个人战绩分享
4 游戏结算,游戏名次分享
5 游戏结算,游戏数据分享
6 军衔数据分享
7 段位数据分享
8 刺激盛典分享
]]
--设置上报类型，物品ID，预留字段
function ShareMgr.SetShareLimit(shareType, itemresid, preParam)
	log("ShareMgr.SetShareLimit:"..tostring(shareType)..tostring(itemresid));
	if shareType == nil then
		ShareMgr.CurShareType = 0;
		ShareMgr.CurShareItemResid = 0;
		return;
	end
	
	ShareMgr.CurShareType = shareType;
	if itemresid ~= nil then
		ShareMgr.CurShareItemResid = itemresid;
	else
		ShareMgr.CurShareItemResid = 0;
	end
end

--发送请求
function ShareMgr.SendShareLimit()
	log("ShareMgr.SendShareLimit:"..tostring(ShareMgr.CurShareType)..tostring(ShareMgr.CurShareItemResid));
	if tonumber(ShareMgr.CurShareType) == 0 then
		log("don't need send shareLimit");
		return;
	end
	NetUtil.SendPkg("share_succ_limit_req",tonumber(ShareMgr.CurShareType),tonumber(ShareMgr.CurShareItemResid));
end


function ShareMgr.share_succ_limit_res(res, share_limit_data)
	
	log("share_succ_limit_res:"..res);
	if res == "ok" then
		--重置下数据
		ShareMgr.CurShareType = 0;
		ShareMgr.CurShareItemResid = 0;
		
		if share_limit_data == nill then
			log("share_succ_limit_res data is none");
			return;
		end
		--登录成功后，后台会下发消息
		log_tree("share_succ_limit_res",share_limit_data);
		ShareMgr.ShareLimitInfo = share_limit_data;
	end
	
end


s2c["get_share_info_respond"] =  ShareMgr.onGetShareInfoRsp; --  响应：get_share_info_respond 结构
--3分享限制上报
--    参数：share_limit_data = {type={次数}}
--    			获得物品分享: type={次数,itemlist={itemresid=1,...}}
s2c["share_succ_limit_res"] = ShareMgr.share_succ_limit_res; --


