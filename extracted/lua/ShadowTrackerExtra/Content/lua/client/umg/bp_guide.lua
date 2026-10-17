GuideUI = GuideUI or 
{
}

--注册Widget
function bp_guide_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_guide,
    {{Path="/Game/UMG/UI_BP/Guide/CtrGuide_UIBP.CtrGuide_UIBP_C", Container="Default", ZOrder=200}},
    {"Lobby"},
	false,
	false,
	true	
  );
end

function GuideUI:Show()
	LuaClassObj.HandleDynamicCreation(bp_guide);
    LuaClassObj.HandleUIMessage(bp_guide, "UIShow");
end

function GuideUI:Hide()
    LuaClassObj.HandleUIMessage(bp_guide, "UIHide");
end