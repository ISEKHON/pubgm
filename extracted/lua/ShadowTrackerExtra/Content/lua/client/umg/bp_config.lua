ConfigUI = ConfigUI or 
{
}

-- 据李伟说这个已经不用了
--注册Widget
function bp_config_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_config,
		{
			{Path="/Game/UMG/UI_BP/Common/Common_TempConfig_UIBP.Common_TempConfig_UIBP_C", Container="Default", ZOrder=BP_ENUM_UI_NOTICE_ZORDER},
		},
		{"Lobby"},
		false,
		false,
		true
	);
end


function EventChangeAccount()
    
    local function changeAccount()
        log("changeAccount...");
		NetUtil.SendPkg("logout");
    end
	local msg1 = Client.GetTableData("LocalizeRes", "102012").TextValue;
	local msg2 = Client.GetTableData("LocalizeRes", "111019").TextValue;
    CommonMessageBoxUI:ShowPanel(2, msg1, msg2, changeAccount);
end
