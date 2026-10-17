----公告UI
IMSDKNoticeUI = IMSDKNoticeUI or
{
	--是否已显示过登录前普通公告
	hasShowCommonIMSDKNotice = false;
	--是否已显示过登录后打脸公告
	hasShowSlapIMSDKNotice = false;
	--是否已显示过登录前维护公告
	hasShowMaintenanceIMSDKNotice = false;
}

--公告栏类型
BP_Enum_IMSDKNotice_Type = 
{
	Alert = 0,
	Scroll = 1,
	All = 2,
};

--公告栏id
BP_Enum_IMSDKNotice_Scene = 
{
	MAINTENANCE_NOTICE_BEFORE_LOGIN = "2";	-- 强制更新（登录前弹窗）	
	COMMON_SCENE_BEFORE_LOGIN = "3",		-- 非强制更新（登录前弹窗）
	SLAP_SCENE_AFTER_LOGIN = "4";			-- 普通公告（登录后弹窗）
};

BP_IMSDKNotice_Type = BP_Enum_IMSDKNotice_Type.All;
BP_IMSDKNotice_Scene = BP_Enum_IMSDKNotice_Scene.COMMON_SCENE_BEFORE_LOGIN;

--公告索引
BP_IMSDKNotice_Index = 0;

--注册Widget
function bp_notice_intl_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_notice_intl,
		{{Path="/Game/UMG/UI_LOGIC/Common/Common_IMSDKNotice_Panel_BP.Common_IMSDKNotice_Panel_BP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICE_ZORDER},
		{Path="/Game/UMG/UI_LOGIC/Notice/Slap_IMSDKNotice_BP.Slap_IMSDKNotice_BP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICE_ZORDER}
		},
		{"Login", "Lobby"},
		false,
		false,
		false
	);
end

function EventTryShowMaintenanceIMSDKNotice()
    if GlobalData:IsIOSCheck() then
        return
    end
    
	IMSDKNoticeUI.hasShowMaintenanceIMSDKNotice = false;
	IMSDKNoticeUI.hasShowSlapIMSDKNotice = false;
    log("EventTryShowMaintenanceIMSDKNotice")
	if IMSDKNoticeUI.hasShowMaintenanceIMSDKNotice == true then
		return;
	end
	BP_IMSDKNotice_Index = 0;
	BP_IMSDKNotice_Type = BP_Enum_IMSDKNotice_Type.All;
	BP_IMSDKNotice_Scene = BP_Enum_IMSDKNotice_Scene.MAINTENANCE_NOTICE_BEFORE_LOGIN;
	local hasNotice = Client.HasNotice(BP_IMSDKNotice_Type, BP_IMSDKNotice_Scene);
	log("NoticeUI hasShowMaintenanceIMSDKNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowMaintenanceIMSDKNotice = true;
		EventMaintenanceIMSDKNotice();
    else
        EventTryShowCommonIMSDKNotice();
	end
end

function EventTryShowCommonIMSDKNotice()
    if GlobalData:IsIOSCheck() then
        return
    end
    
	if NoticeUI.hasShowCommonIMSDKNotice == true then
		return;
	end
	BP_IMSDKNotice_Index = 0;
	BP_IMSDKNotice_Type = BP_Enum_IMSDKNotice_Type.All;
	BP_IMSDKNotice_Scene = BP_Enum_IMSDKNotice_Scene.COMMON_SCENE_BEFORE_LOGIN;
	local hasNotice = Client.HasNotice(BP_IMSDKNotice_Type, BP_IMSDKNotice_Scene);
	log("NoticeUI hasShowCommonIMSDKNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowCommonIMSDKNotice = true;
		EventShowIMSDKNotice();
	end
end
function EventShowCommonIMSDKNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice_intl);
	
	LuaClassObj.HandleUIMessage(bp_notice_intl, "ShowCommonIMSDKNotice");
	BP_IMSDKNotice_Index = BP_IMSDKNotice_Index + 1;
end

function EventTryShowSlapIMSDKNotice()
	if NoticeUI.hasShowSlapIMSDKNotice == true then
		return;
	end
	BP_IMSDKNotice_Index = 0;
	BP_IMSDKNotice_Type = BP_Enum_IMSDKNotice_Type.All;
	BP_IMSDKNotice_Scene = BP_Enum_IMSDKNotice_Scene.SLAP_SCENE_AFTER_LOGIN;
	local hasNotice = Client.HasNotice(BP_IMSDKNotice_Type, BP_IMSDKNotice_Scene);
	log("NoticeUI hasShowSlapIMSDKNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowSlapIMSDKNotice = true;
		EventShowIMSDKNotice();
	else
		EventDoneIMSDKNotice();
	end
end
function EventShowSlapIMSDKNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice_intl);
	
	LuaClassObj.HandleUIMessage(bp_notice_intl, "ShowSlapIMSDKNotice");
	BP_IMSDKNotice_Index = BP_IMSDKNotice_Index + 1;
end

function EventShowIMSDKNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice_intl);
	
	LuaClassObj.HandleUIMessage(bp_notice_intl, "ShowIMSDKNotice");
end

function EventDoneIMSDKNotice()
	if BP_IMSDKNotice_Scene == BP_Enum_IMSDKNotice_Scene.SLAP_SCENE_AFTER_LOGIN then
		--打脸图结束，进行后续操作
		--签到打脸
		-- SignInSystem.Enter(true);
        FaceSlapSystem.BeginShow();
	elseif BP_IMSDKNotice_Scene == BP_Enum_IMSDKNotice_Scene.SLAP_SCENE_AFTER_LOGIN then
		--登录前公告结束，进行自动登录流程
		LuaClassObj.HandleUIMessage(bp_authorization, "doAutoLogin");
	end
end

function EventMaintenanceIMSDKNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice_intl);
    log("EventMaintenanceIMSDKNotice");
	LuaClassObj.HandleUIMessage(bp_notice_intl, "ShowMaintenanceIMSDKNotice");
end

function IMSDKNoticeUI.OnHyperLinkClicked(MetaData)
	local url = MetaData["url"];
	GlobalData:JumpUrl(url);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end

function IMSDKNoticeUI:Release()
	log("ShopUI_Release");
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end