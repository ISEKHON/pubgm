-- 
KefuSystem = KefuSystem or
{

}

local phoneSysName = {"苹果", "安卓"}
local phonePlatName = {"微信", "手Q"}

function KefuSystem.OpenLoginKefuURL()
	local baseUrl = "https://kf.qq.com/touch/scene_product.html?scene_id=kf5598";
	--KefuSystem.OpenUrlWithMsdkParam(baseUrl);
	Client.OpenURL(baseUrl)
end

function KefuSystem.OpenSettingKefuURL()
	local baseUrl = "https://kf.qq.com/touch/scene_product.html?scene_id=kf5579&";
	KefuSystem.OpenUrlWithMsdkParam(baseUrl);
end

function KefuSystem.OpenUrlWithMsdkParam( baseUrl )

	local qi = 0; 
	local wi = 0;
	if Client.IsInstallQQ(NetInterface) == true then 
		qi = 1;
	end
	if Client.IsInstallWX(NetInterface) == true then 
		wi = 1;
	end
    local appid = "1106467070";
    local z = 2;
    if _G.BP_Platform == BP_ENUM_PLAYFORM_WX then
        appid = "wxc4c0253df149f02d";
        z = 1;
	end
	local sys = 1;
	if string.lower(Client.GetDevicePlatformName()) == "android" then 
		sys = 2;
	end
	local zn = FuncUtil:EncodeURI(phonePlatName[z]..phoneSysName[sys].."服");
	local strUserName = nil;
	local strOpenid = nil;
	if DataMgr.roleData ~= nil  then 
		strUserName = FuncUtil:EncodeURI(DataMgr.roleData.nickName);
		strOpenid = DataMgr.roleData.openID;
	end
    --local accessToken = Client.GetAccessToken(NetInterface);
	local finalUrl = string.format("%sqi=%d&wi=%d&z=%d&zn=%s&platid=%d&role=%s", baseUrl, qi, wi, z, zn,  _G.BP_Platform, strUserName)
	log("finalUrl url = " .. finalUrl)
	local finalEncodeUrl = Client.GetEncodeUrl(finalUrl);
    log("finalEncodeUrl url = " .. finalEncodeUrl)
    Client.OpenURL(finalEncodeUrl);
end