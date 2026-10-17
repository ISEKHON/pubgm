TopicQuanSystem = TopicQuanSystem or {}

local function get_idtype()
	if BP_Platform == BP_ENUM_PLAYFORM_WX then
		return 2;
	elseif BP_Platform == BP_ENUM_PLAYFORM_QQ then
		return 1;
	else
		return 0;
	end
end

function TopicQuanSystem.OpenTopicQuanURL()
	local gameId = "com.tencent.tmgp.pubgmhd";--游戏包名
	local ch = "980000";--渠道号
	local pkgCh = "10023819";
	local tabName= "%E7%A4%BC%E5%8C%85";
	local idtype = get_idtype();
	local openid = DataMgr.roleData.openID;
	local appid = _G.BP_Platform == BP_ENUM_PLAYFORM_WX and "wxc4c0253df149f02d" or "1106467070";
	local accessToken = Client.GetAccessToken(NetInterface);
	local loginType = 3;
	
	local baseURL = "http://ag.qq.com/community/mergeDetailInGame?";
	
	local finalURL = string.format("%sgameId=%s&ch=%s&pkgCh=%s&tabName=%s&idtype=%d&openid=%s&appid=%s&accesstoken=%s&loginType=%d", 
							baseURL, gameId, ch, pkgCh, tabName, idtype, openid, appid, accessToken, loginType
						);
	

	log("TopicURL="..finalURL)
	local finalEncodeUrl = Client.GetEncodeUrl(finalURL);
	log("TopicEncodeURL="..finalEncodeUrl)
	Client.OpenURL(finalEncodeUrl);
end


