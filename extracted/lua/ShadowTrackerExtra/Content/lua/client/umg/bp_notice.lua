----公告UI
NoticeUI = NoticeUI or
{
	--是否已显示过登录前普通公告
	hasShowCommonNotice = false;
	--是否已显示过登录后打脸公告
	hasShowSlapNotice = false;
	--是否已显示过登录前维护公告
	hasShowMaintenanceNotice = false;
}

--公告栏类型
BP_Enum_Notice_Type = 
{
	Alert = 0,
	Scroll = 1,
	All = 2,
};

--公告栏id
BP_Enum_Notice_Scene = 
{
	COMMON_SCENE_BEFORE_LOGIN = "1",
	SLAP_SCENE_AFTER_LOGIN = "2";
	MAINTENANCE_NOTICE_BEFORE_LOGIN = "673";
};

BP_Notice_Type = BP_Enum_Notice_Type.All;
BP_Notice_Scene = BP_Enum_Notice_Scene.COMMON_SCENE_BEFORE_LOGIN;

--公告索引
BP_Notice_Index = 0;

--注册Widget
function bp_notice_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_notice,
		{{Path="/Game/UMG/UI_LOGIC/Common/Common_Notice_Panel_BP.Common_Notice_Panel_BP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICE_ZORDER},
		{Path="/Game/UMG/UI_LOGIC/Notice/Slap_Notice_BP.Slap_Notice_BP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICE_ZORDER}
		},
		{"Login", "Lobby"},
		false,
		false,
		false
	);
end

function EventTryShowMaintenanceNotice()
    if GlobalData:IsIOSCheck() then
        return
    end
    
	NoticeUI.hasShowMaintenanceNotice = false;
	NoticeUI.hasShowSlapNotice = false;
    log("EventTryShowMaintenanceNotice")
	if NoticeUI.hasShowMaintenanceNotice == true then
		return;
	end
	BP_Notice_Index = 0;
	BP_Notice_Type = BP_Enum_Notice_Type.All;
	BP_Notice_Scene = BP_Enum_Notice_Scene.MAINTENANCE_NOTICE_BEFORE_LOGIN;
	local hasNotice = Client.HasNotice(BP_Notice_Type, BP_Notice_Scene);
	log("NoticeUI hasShowMaintenanceNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowMaintenanceNotice = true;
		EventMaintenanceNotice();
    else
        EventTryShowCommonNotice();
	end
end

function EventTryShowCommonNotice()
    if GlobalData:IsIOSCheck() then
        return
    end
    
	if NoticeUI.hasShowCommonNotice == true then
		return;
	end
	BP_Notice_Index = 0;
	BP_Notice_Type = BP_Enum_Notice_Type.All;
	BP_Notice_Scene = BP_Enum_Notice_Scene.COMMON_SCENE_BEFORE_LOGIN;
	local hasNotice = Client.HasNotice(BP_Notice_Type, BP_Notice_Scene);
	log("NoticeUI hasShowCommonNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowCommonNotice = true;
		EventShowNotice();
	end
end
function EventShowCommonNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice);
	
	LuaClassObj.HandleUIMessage(bp_notice, "ShowCommonNotice");
	BP_Notice_Index = BP_Notice_Index + 1;
end

function EventTryShowSlapNotice()
	if NoticeUI.hasShowSlapNotice == true then
		return;
	end
	BP_Notice_Index = 0;
	BP_Notice_Type = BP_Enum_Notice_Type.All;
	BP_Notice_Scene = BP_Enum_Notice_Scene.SLAP_SCENE_AFTER_LOGIN;
	local hasNotice = Client.HasNotice(BP_Notice_Type, BP_Notice_Scene);
	log("NoticeUI hasShowSlapNotice" .. tostring(hasNotice));
	if hasNotice then
		NoticeUI.hasShowSlapNotice = true;
		EventShowNotice();
	else
		EventDoneNotice();
	end
end
function EventShowSlapNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice);
	
	LuaClassObj.HandleUIMessage(bp_notice, "ShowSlapNotice");
	BP_Notice_Index = BP_Notice_Index + 1;
end

function EventShowNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice);
	
	LuaClassObj.HandleUIMessage(bp_notice, "ShowNotice");
end

function EventDoneNotice()
	if BP_Notice_Scene == BP_Enum_Notice_Scene.SLAP_SCENE_AFTER_LOGIN then
		--打脸图结束，进行后续操作
		--签到打脸
		-- SignInSystem.Enter(true);
        FaceSlapSystem.BeginShow();
	elseif BP_Notice_Scene == BP_Enum_Notice_Scene.SLAP_SCENE_AFTER_LOGIN then
		--登录前公告结束，进行自动登录流程
		LuaClassObj.HandleUIMessage(bp_authorization, "doAutoLogin");
	end
end

function EventMaintenanceNotice()
	LuaClassObj.HandleDynamicCreation(bp_notice);
    log("EventMaintenanceNotice");
	LuaClassObj.HandleUIMessage(bp_notice, "ShowMaintenanceNotice");
end

function NoticeUI.OnHyperLinkClicked(MetaData)
	local url = MetaData["url"];
	GlobalData:JumpUrl(url);
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end

function NoticeUI:Release()
	log("ShopUI_Release");
end

function EventSetInfo_Push()
end

function EventFetchInfo()
end