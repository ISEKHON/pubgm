
FadeUI = FadeUI or 
{
}


function bp_fade_RegisterUI()
    
	LuaClassObj.SubUIWidgetList(bp_fade,
		{{Path="/Game/UMG/UI_BP/Lobby/Fade_UIBP.Fade_UIBP_C", Container="Default", ZOrder=5000}},
		{"Lobby","Login"},
		true,
		false
	);	
end

function EventFadeIn()
    log("EventFadeIn")
    
	LuaClassObj.HandleUIMessage(bp_fade, "UIShowFadeIn");
end

function EventFadeHide()
    log("EventFadeHide")
    
	LuaClassObj.HandleUIMessage(bp_fade, "UIHide");
end

