
--[[
 红包相关逻辑
]]--

RedPacketSystem = RedPacketSystem or
{
	--红包总列表
	RedPacketInfoList = {},
	SpringWxUrl = "";
	SpringQQUrl = "";
}

local function localText(id)
    local data = Client.GetTableData("LocalizeRes",id);
    if data then
        return data.TextValue
    end
    return ""
end

function RedPacketSystem.Enter()
	log("RedPacketSystem enter"); 
end

function RedPacketSystem.Release()
	log("RedPacketSystem release");
end

function RedPacketSystem.KickoutWhenTokenError(errCode)
	if errCode == 9920019 then
		local function LogOut()
			log("...log out from RedPacketSystem.KickoutWhenTokenError...");
			LoginSystem.sendLogout();
		end
		CommonMessageBoxUI:ShowPanel(1, Client.GetTableData("LocalizeRes", "102012").TextValue, Client.GetTableData("LocalizeRes", "200028").TextValue, LogOut);
	end
end

function RedPacketSystem.add_test_packets()

	log("add_test_packets exec ");
end

function RedPacketSystem.ResetShareUrl()
	RedPacketSystem.SpringWxUrl = "";
	RedPacketSystem.SpringQQUrl = "";
end

-- 判断某个活动是否在开启期内 
-- 传入参数 参考 ActivityType.GROUP_EXCITE
function RedPacketSystem.IsActivityInTime( Activity )
	local IsInTime = false;
	local actData = DataMgr.GetActivityByType(Activity)
    --log_tree("actData = ", actData )
    if actData == nil then
        return false;
    end

    local serverTime = FuncUtil.GetServerTimeInSec()

    if serverTime >= actData.StartTime and serverTime <= actData.EndTime then
        IsInTime = true 
    end
	--log("Activity type= "..Activity.. " isInTime = " .. tostring(IsInTime))
	return IsInTime;
end

function RedPacketSystem.SendHttpReq( roomid )
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		local appid = "wxc4c0253df149f02d";
		local acctype = "wx";
		local accessToken = Client.GetAccessToken(NetInterface);
		local baseUrl = "https://app.ingame.qq.com/php/ingame/jdqssy/create_luckybag.php";
		--local finalUrl = string.format( "%s?acctype=%s&openid=%s&appid=%s&platid=%d&AccessToken=%s", baseUrl, acctype, DataMgr.roleData.openID, appid, _G.BP_Platform, accessToken)
		local encodeUrl = Client.GetEncodeUrl(baseUrl);
		local i,j = string.find( encodeUrl, "https://app.ingame.qq.com/");
		local encodeUrlNoHead = string.sub( encodeUrl, j+1 )
		log("encodeUrlNoHead = "..encodeUrlNoHead);
		local finalUrl2Svr = string.format( "%s&battle_gid=%s", encodeUrlNoHead, tostring(roomid) );
		log("finalUrl2Svr = "..finalUrl2Svr);

		NetUtil.SendPkg("newyear_wx_createbox_req", roomid, finalUrl2Svr);
	end
end

function RedPacketSystem.ShareSpringPacketToFrd( battleGid )
	if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		if RedPacketSystem.SpringWxUrl == "" then
			RedPacketSystem.SendHttpReq(battleGid);
		else
			log("shareSpringPacketWX Old url = "..RedPacketSystem.SpringWxUrl)
			ShareMgr:shareWechatWithMiniApp("", "", "", "", "gh_24df6521808e", RedPacketSystem.SpringWxUrl, "", "",  ShareType.Friend);
		end
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		if RedPacketSystem.SpringQQUrl == "" then
			RedPacketSystem.QQCreateSpringPacket_req(battleGid);
		else 
			log("shareSpringPacketQQ Old url = "..RedPacketSystem.SpringQQUrl)
			ShareMgr:shareSpringPacketQQ("", "", "", "", RedPacketSystem.SpringQQUrl, ShareType.Friend);
		end
	end
end

function RedPacketSystem.WXCreateSpringHttp_Res( err_code, battle_gid, ret_data )
	log("wxcreatespringhttp_res errcode = "..err_code);
	log("wxcreatespringhttp_res ret_data = "..tostring(ret_data));

	if err_code ~= 0 then
		log("RedPacketSystem.QQCreateSpringPacket_res errcode : " .. err_code);
		ShowNotice(err_code)
		return;
	end
	if tostring(battle_gid) ~= tostring(BattleResult.battleNewyearGID) then
		log("RedPacketSystem.QQCreateSpringPacket_res not this battle!");
		return;
	end
	local strPath = string.format("pages/index/index?bagid=%s", tostring(battle_gid));
	RedPacketSystem.SpringWxUrl = strPath;
	ShareMgr:shareWechatWithMiniApp("", "", "", "", "gh_24df6521808e", strPath, "", "",  ShareType.Friend);
end

function RedPacketSystem.QQCreateSpringPacket_req( battleGid )
	NetUtil.SendPkg("newyear_qq_createbox_req", battleGid);
end

function RedPacketSystem.QQCreateSpringPacket_res(err_code, battle_gid, ret_jason_result )
	if err_code ~= 0 then
		log("RedPacketSystem.QQCreateSpringPacket_res errcode : " .. err_code);
		ShowNotice(err_code)
		return;
	end
	if tostring(battle_gid) ~= tostring(BattleResult.battleNewyearGID) then
		log("RedPacketSystem.QQCreateSpringPacket_res not this battle!");
		return;
	end
	if not ret_jason_result then
		log("RedPacketSystem.QQCreateSpringPacket_res ret_jason_result is null");
		return;
	end
	log_tree("RedPacketSystem.QQCreateSpringPacket_res  :",  ret_jason_result);
	local resultTable = json.decode (ret_jason_result);
	log_tree("RedPacketSystem QQCreateSpringPacket_res table :", resultTable)
	if resultTable and resultTable.ret == 0 then
		if resultTable.data and resultTable.data.op then
			local op = resultTable.data.op
			local urlFormat = "https://youxi.vip.qq.com/m/act/201801/cjzc_254178/index.html?_wwv=4&_wv=1&ADTAG=adtag.inthegame&chest_id=%s&invite_uin=%d"
			local url = string.format(urlFormat, op.token, op.owner)
			log("shareSpringPacketQQ url = "..url);
			RedPacketSystem.SpringQQUrl = url;
			ShareMgr:shareSpringPacketQQ("", "", "", "", url, ShareType.Friend);
		end
	end
end

--请求玩家所有红包列表
function RedPacketSystem.roomlist_req()
	log("roomlist_req");
	NetUtil.SendPkg("roomlist_req");
end

--获取玩家所有红包列表
function RedPacketSystem.roomlist_res(ret_result, list)
	--刷新列表信息
	--log_tree("redpacketslist", list);
	--RedPacketSystem.RedPacketInfoList = {};
    AllRedPacketUI.SetPacketList(list);
end

--[[网络回调]]--
s2c["roomlist_res"] = RedPacketSystem.roomlist_res
s2c["newyear_qq_createbox_res"] = RedPacketSystem.QQCreateSpringPacket_res
s2c["newyear_wx_createbox_res"] = RedPacketSystem.WXCreateSpringHttp_Res



--[[
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////平常吃鸡红包///////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--]]
--[[
	吃鸡现金红包
	QQ:
	请求创建宝箱 createbox_req(battleGID)
	返回创建宝箱 给前端 createbox_res(battleGID, platResult)
	通知gamesvr分享完成 shareboxsucc_req(battleGID)
	返回现金红包成就数据 reportredpack_res(result,platResult)

	WX:
	分享REQ: share_req(battle_gid)
	分享RES: share_res(result, platResult)
	通知gamesvr分享完成 : shareboxsucc_req(battleGID)
	返回资源发放接口结果  sendresource_res(retResult, platResult, money)
--]]
function RedPacketSystem.StartShareHongbao()
	log("RedPacketSystem.StartShareHongbao");
	if _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		RedPacketSystem.QQCreateBoxReq(BattleResult.battleGID)
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		RedPacketSystem.WXShareReq(BattleResult.battleGID);
	end
end

--QQ分享或者微信分享成功后告诉后台
function RedPacketSystem.ShareBoxSuccReq(battleGID)
	if _G.BP_Platform == BP_ENUM_PLAYFORM_QQ then
		NetUtil.SendPkg("qq_shareboxsucc_req", battleGID);
	elseif _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
		NetUtil.SendPkg("shareboxsucc_req", battleGID);
	end
end

--QQ流程
function RedPacketSystem.QQCreateBoxReq(battleGID)
	NetUtil.SendPkg("createbox_req", battleGID);
end
function RedPacketSystem.QQCreateBoxRes(errcode,battleGID, platResult)
	if errcode ~= 0 then
		log("RedPacketSystem.QQCreateBoxRes errcode : " .. errcode);
		ShowNotice(errcode);
		RedPacketSystem.KickoutWhenTokenError(errcode);
		return;
	end
	if battleGID ~= BattleResult.battleGID then
		log("RedPacketSystem.QQCreateBoxRes not this battle!");
		return;
	end
	if not platResult then
		log("RedPacketSystem.QQCreateBoxRes platResult is null");
		return;
	end
	log("RedPacketSystem.QQCreateBoxRes platResult : " .. platResult);
	local resultTable = json.decode (platResult);
	log_tree("RedPacketSystem QQCreateBoxRes table :" ,resultTable)
	log(BP_CJHB_REDPACKTYPE)
	if resultTable and resultTable.ret == 0 then
		if resultTable.data and resultTable.data.op then
			local op = resultTable.data.op
			local urlFormat = ""
			if BP_CJHB_REDPACKTYPE == 1 then
				urlFormat = "https://youxi.vip.qq.com/m/act/e6b1bfa9bd_jdqsm_250834_detail.html?_wv=1&from=game&chest_id=%s&invite_uin=%d"
			elseif BP_CJHB_REDPACKTYPE == 2 then
				urlFormat = "https://youxi.vip.qq.com/m/act/e6ee580f62_jdqsm_250857_detail.html?_wv=1&from=game&chest_id=%s&invite_uin=%d"
			end
			local url = string.format(urlFormat, op.token, op.owner)
			ShareMgr:shareCJHBQQ(MEDIA_TAG_SHARE_CHIJI_HONGBAO, "", url, ShareType.Friend);
		end
	end
end
function RedPacketSystem.QQShareboxsuccRes(errcode)
	if errcode ~= 0 then
		log("RedPacketSystem.QQShareboxsuccRes errcode : " .. errcode);
		ShowNotice(errcode);
		RedPacketSystem.KickoutWhenTokenError(errcode);
	end
end
function RedPacketSystem.QQReportRedPacketRes(money,data)
	if money then 
		log("RedPacketSystem.QQReportRedPacketRes money : "..money); 
	end
	if data then
		log("RedPacketSystem.QQReportRedPacketRes data : "..data);
	end
	ShareNromalCJHBUI.OnRecevieCJHongbaoSuccess(money,data);
end

--微信流程
function RedPacketSystem.WXShareReq(battleGID)
	NetUtil.SendPkg("share_req", battleGID);
end
function RedPacketSystem.WXShareRes(errcode, battleGID, platResult)
	if errcode ~= 0 then
		log("BattleResult.WXShareRes errcode : ".. errcode)
		ShowNotice(errcode)
		RedPacketSystem.KickoutWhenTokenError(errcode);
		return
	end
	if battleGID ~= BattleResult.battleGID then
		log("RedPacketSystem.WXShareRes not this battle!");
		return;
	end
	if not platResult then
		log("RedPacketSystem.WXShareRes platResult is null");
		return;
	end
	log("RedPacketSystem.WXShareRes platResult : " .. platResult);
	local resultTable = json.decode (platResult);
	log_tree("RedPacketSystem WXShareRes table :" ,resultTable)
	--[[
		1111 入参错误
		1112 签名错误
		1113 生成福袋失败
	--]]
	if resultTable.ret ~= 0 then
		log("RedPacketSystem.WXShareRes resultTable ret is wrong! : " .. resultTable.ret);
		return;
	end
	ShareMgr:shareWechatUrlInfo(MEDIA_TAG_SHARE_CHIJI_HONGBAO,"",resultTable.data.url,"",ShareType.Friend);
end
function RedPacketSystem.WXShareboxsuccRes(errcode)
	if errcode ~= 0 then
		log("RedPacketSystem.WXShareboxsuccRes errcode : " .. errcode);
		ShowNotice(errcode)
		RedPacketSystem.KickoutWhenTokenError(errcode);
	end
end
function RedPacketSystem.WXSendResourceRes(money,data)
	if money then 
		log("RedPacketSystem.WXSendResourceRes money : "..money) 
	end
	if data then
		log("RedPacketSystem.WXSendResourceRes data : "..data)
	end
	ShareNromalCJHBUI.OnRecevieCJHongbaoSuccess(money,data);
end

s2c["createbox_res"] = RedPacketSystem.QQCreateBoxRes;
s2c["qq_shareboxsucc_res"] = RedPacketSystem.QQShareboxsuccRes;
s2c["qq_sendresource_res"] = RedPacketSystem.QQReportRedPacketRes;
s2c["share_res"] = RedPacketSystem.WXShareRes;
s2c["shareboxsucc_res"] = RedPacketSystem.WXShareboxsuccRes;
s2c["sendresource_res"] = RedPacketSystem.WXSendResourceRes;



--QQ分享或者微信分享成功后回调
function RedPacketSystem.OnMSDKShareHongbaoOK(eventType, eventID, vars)
	log("RedPacketSystem.OnMSDKShareHongbaoOK")
	if eventType == EVENTTYPE_SHARE and eventID == EVENTID_SHARE_SUCESSFUL then
		if vars and vars[1] == 1 and vars[2] == MEDIA_TAG_SHARE_CHIJI_HONGBAO then
			log("RedPacketSystem.OnMSDKShareHongbaoOK  success")
			RedPacketSystem.ShareBoxSuccReq(BattleResult.battleGID);
			--避免上次的mediaTag的缓存，对那个不需要回调的造成影响（如果不清除，例如吃鸡红包和春节红包一起出现，先吃鸡再春节，那么春节红包分享成功之后会误调至这里）
			ShareParam.strMediaTag = "";
		end
	end
end
--注册红包分享
--现在不需要分享回调了（后台已改为直接发钱，不需要客户端等回调成功后再触发，而且这里偶现的找不到eventSystem实例）
--EventSystem:registEvent(EVENTTYPE_SHARE, EVENTID_SHARE_SUCESSFUL, RedPacketSystem.OnMSDKShareHongbaoOK);

