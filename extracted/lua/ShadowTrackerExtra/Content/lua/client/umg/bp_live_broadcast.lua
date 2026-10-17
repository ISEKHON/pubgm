----直播UI
LiveBroadcastUI = LiveBroadcastUI or
{
	
}

BP_Live_Broadcast_Url = "http://dlied5.qq.com/aitoy/test/mytest.html";

--注册Widget
function bp_live_broadcast_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_live_broadcast,
		{{Path="/Game/UMG/UI_LOGIC/LiveBroadcast/LiveBroadcast_BP.LiveBroadcast_BP_C", Container="Default", ZOrder=BP_ENUM_UI_LIVE_BROADCAST_ZORDER}},
		{"Login", "Lobby"},
		false,
		false
	);
end

function EventGetUrl()
	local baseUrl = "https://apps.game.qq.com/uranus/entrance/cjm/main.php";
    local appid = "1106467070";
    local acctype = "qq";
	local areaid = 2;
	local partition = 0;
    if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
        appid = "wxc4c0253df149f02d";
        acctype = "wx";
		areaid = "1";
    end
    local accessToken = Client.GetAccessToken(NetInterface);
    BP_Live_Broadcast_Url = string.format("%s?acctype=%s&openid=%s&appid=%s&platid=%d&access_token=%s&areaid=%d&partition=%d&roleid=%s&entertime=%d&nickname=%s",
	baseUrl, acctype, DataMgr.roleData.openID, appid, _G.BP_Platform, accessToken, areaid, partition, DataMgr.roleData.uid, os.time(), DataMgr.roleData.nickName)
    log("live broadcast url = " .. BP_Live_Broadcast_Url)
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end