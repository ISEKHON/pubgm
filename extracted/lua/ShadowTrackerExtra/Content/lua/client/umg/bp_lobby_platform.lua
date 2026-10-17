LobbyPlatformUI = LobbyPlatformUI  or {}

--注册Widget
function bp_lobby_platform_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_lobby_platform,
		{{Path="/Game/UMG/UI_BP/Lobby_Platform/WXPlatform_UIBP.WXPlatform_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_LOBBY_PLATFORM_ZORDER},
		 {Path="/Game/UMG/UI_BP/Lobby_Platform/QQPlatform_UIBP.QQPlatform_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_LOBBY_PLATFORM_ZORDER}},
		{"Lobby"},
		false,
		false,
		true
	);
end

function LobbyPlatformUI.ShowQQRightPanel()
	LuaClassObj.HandleDynamicCreation(bp_lobby_platform);
	LuaClassObj.HandleUIMessage(bp_lobby_platform, "OpenQQRightPanel");
end

function LobbyPlatformUI.ShowWXRightPanel()
	LuaClassObj.HandleDynamicCreation(bp_lobby_platform);
	LuaClassObj.HandleUIMessage(bp_lobby_platform, "OpenWXRightPanel");
end