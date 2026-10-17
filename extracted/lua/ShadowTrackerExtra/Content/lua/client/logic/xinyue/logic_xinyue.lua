-- 心悦
XinyueSystem = XinyueSystem or
{
    gid = "1279"; -- 内置面板id，心悦提供 
    pid = "23"; -- 内置面板id，心悦提供
    reg = "1"; -- 大区服（1:正式服；2:抢先服；3:体验服）
    part = "0"; --小区id
    secret = "Bui1tin#t@Clu8";
    url_prefix = "https://xinyue.qq.com/builtin.shtml?code=";
}

function XinyueSystem.OpenXinYueURL()
	local params = 
	{
	    gid = XinyueSystem.gid, 
	    pid = XinyueSystem.pid,
  		reg = XinyueSystem.reg,
 		  plat = (string.lower(Client.GetDevicePlatformName()) == "android" and "1" or "0"), -- 平台id（0: iOS；1: android），游戏传入
 		  ch = _G.BP_Platform == BP_ENUM_PLAYFORM_WX and "2" or "1", -- 账号类型（1:qq；2:wx），游戏传入
  		area = _G.BP_Platform == BP_ENUM_PLAYFORM_WX and "1" or "2", -- 渠道id 游戏侧透传 (1:wx; 2:qq; 90:其他)
  		part = XinyueSystem.part, 
  		openid = DataMgr.roleData.openID, -- QQ或微信分配给用户的唯一标识，游戏传入。例如： QQ平台下用户openid：421EE294BBA2CA69568EC879A0F3A199 微信平台下用户openid：oQ1yVw4AMaRSlqNkcKfCac2aBbqo
  		appid = _G.BP_Platform == BP_ENUM_PLAYFORM_WX and "wxc4c0253df149f02d" or "1106467070", -- QQ或微信分配给游戏的唯一标识，游戏传入。例如： QQ平台下的游戏appid：1105309683 微信平台下的游戏appid：wxfdab5af74990787a
  		role = tostring(DataMgr.roleData.uid), -- 角色id，游戏传入
  		msdkt = Client.GetAccessToken(NetInterface), -- 手Q登录返回的skey或者微信登录返回的access token，游戏传入
  		t = tostring(os.time()), -- 精确到秒的时间戳，游戏传入
  		r = tostring(math.random(1000, 10000)), -- 随机数，游戏传入。可用random取一个10000以内的随机整数
  		ava = DataMgr.roleData.headIconUrl, -- 头像http地址，游戏传入
  		nick = DataMgr.roleData.nickName -- 角色名，游戏传入
	} 

	local genCode = function()
        -- 1. 约定的参数构造为json串
  		local paramsJson = json.encode(params) -- json由接入方自行实现或导入第三方库
      log(paramsJson)
      -- 2. base64编码上面的json串
      local base64String = FuncUtil.EncodeBase64(paramsJson)  --base64encode由接入方自行实现或导入第三方库
      -- 3. 将上面base64串中+替换为-, /替换为_, 去掉=
      base64String = string.gsub(base64String, "+", "-")
      base64String = string.gsub(base64String, "/", "_")
  		base64String = string.gsub(base64String, "=", "")
        -- 4. 将约定密钥（由心悦提供）拼接在上面base64字符串后面再做md5得到32位消息摘要
  		local md5String = Client.MD5HashAnsiString(base64String .. XinyueSystem.secret) -- md5由接入方自行实现或导入第三方库
        -- 5. 从第9位开始（包含第9位）到24位（包含24位），截取上面md5字符串中间16位字符串得到签名码
  		local signString = string.sub(md5String, 9, 24)
        -- 6. 将签名码附加到上面的base64串后面得到code
  		local code = base64String .. signString  
  		return code
	end

	local finalURL = XinyueSystem.url_prefix .. genCode();
	log("finalURL:" .. finalURL);

	Client.OpenURL(finalURL);
end