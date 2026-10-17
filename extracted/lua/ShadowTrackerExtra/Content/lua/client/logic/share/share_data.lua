
--[[
	分享类型定义
--]]

MEDIA_TAG_SHARE_INVITE = "MSG_INVITE"; -- 邀请好友

-- 朋友圈 or QZone
MEDIA_TAG_SHARE_CHIJI = "MSG_SHARE_CHIJI"; -- 吃鸡分享

-- 微信好友 or QQ好友
MEDIA_TAG_SHARE_FRIEND_CHIJI = "MSG_SHARE_FRIEND_CHIJI";

--结算分享--
MEDIA_TAG_SHARE_RESULT = "MSG_SHARE_RESULT";

--邀请组队
MEDIA_TAG_SHARE_INVITE_JOINTEAM = "MEDIA_TAG_SHARE_INVITE_JOINTEAM";

--吃鸡红包分享
MEDIA_TAG_SHARE_CHIJI_HONGBAO = "MSG_SHARE_CHIJI_HONGBAO";

-- 刺激盛宴分享
MEDIA_TAG_SHARE_EXCITING_PARTY = "MEDIA_TAG_SHARE_EXCITING_PARTY"; 

--微信分享mediaId
MEDIA_ID = "dVTTMJKAQOuy2g81H0Vz1EtRMMUCMetCI6w-e03Xn4SWssMD5FBsL95Cqb9iq9rU";

-- 分享数据描述
ShareDataList =
{
	[MEDIA_TAG_SHARE_INVITE] =
	{
		strDesc = "小主一起来玩吧！", -- 描述字串，可能带参数
		strImgPath = "Arts/UI/LOGO/Share_Icon.png", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		iShareType = 0, -- 分享场景
	};

	[MEDIA_TAG_SHARE_CHIJI] =
	{
		strDesc = "我吃鸡了，就等你！",
		strImgPath = "Arts/UI/LOGO/Share_Icon.png", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		strExtraScene = "MESSAGE_ACTION_SNS_CANVAS#Honor=20",
		strMessageExt = "",
		iShareType = 0, --分享场景
	};

	[MEDIA_TAG_SHARE_FRIEND_CHIJI] =
	{
		strDesc = "鸡吃我了，就等你",
		strImgPath = "Arts/UI/LOGO/Share_Icon.png", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		strExtraScene = "MESSAGE_ACTION_SNS_CANVAS#Honor=20",
		strMessageExt = "",
		iShareType = 0, --分享场景
	};

	[MEDIA_TAG_SHARE_RESULT] =
	{
		strDesc = "鸡吃我了，就等你",
		strImgPath = "Arts/UI/LOGO/Share_Icon.png", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		strExtraScene = "MESSAGE_ACTION_SNS_CANVAS#Honor=20",
		strMessageExt = "",
		iShareType = 0, --分享场景
	};

	[MEDIA_TAG_SHARE_CHIJI_HONGBAO] =
	{
		strDesc = "鸡吃我了，就等你",
		strImgLocalPath = "Arts/UI/TableIcons/ShareBg/Share_Icon.jpg",
		mediaId = "dVTTMJKAQOuy2g81H0Vz1EtRMMUCMetCI6w-e03Xn4SWssMD5FBsL95Cqb9iq9rU",
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		iShareType = 0, --分享场景
	};

	[MEDIA_TAG_SHARE_INVITE_JOINTEAM] =
	{
		strDesc = "大吉大利，今晚刺激！", -- 描述字串，可能带参数
		strImgLocalPath = "Arts/UI/TableIcons/ShareBg/Share_Icon.jpg", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		iShareType = 0, -- 分享场景
	};

	[MEDIA_TAG_SHARE_EXCITING_PARTY] =
	{
		strDesc = "我吃鸡了，就等你！",
		strImgPath = "Arts/UI/LOGO/Share_Icon.png", -- 本地图片路径
		strImgUrl = "http://down.qq.com/jdqssy/Share_Icon.png", -- http图片路径
		strExtraScene = "MESSAGE_ACTION_SNS_CANVAS#Honor=20",
		strMessageExt = "",
		iShareType = 0, --分享场景
	};
};
