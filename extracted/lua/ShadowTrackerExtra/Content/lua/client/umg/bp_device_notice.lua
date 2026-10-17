-- 设备提示UI
DeviceNotice = DeviceNotice or {}

--注册Widget
function bp_device_notice_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_device_notice,
    {
        {Path="/Game/UMG/UI_BP/PopupNotice/ScreenSettings_UIBP.ScreenSettings_UIBP_C", Container="Top", ZOrder=0},

    },
    {"Lobby"},
	false,
	true,
    true
  );
end

function bp_device_notice_OnModeSwitched(gamestatus)
    
	if string.lower(gamestatus) == "lobby" then
        
        LuaClassObj.HandleDynamicCreation(bp_device_notice);
        LuaClassObj.HandleUIMessage(bp_device_notice, "UIShow")
	end
end