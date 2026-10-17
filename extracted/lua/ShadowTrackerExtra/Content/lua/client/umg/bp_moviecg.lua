MovieCGUI = MovieCGUI or 
{

}

--注册Widget
function bp_moviecg_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_moviecg,
		{{Path="/Game/UMG/UI_BP/Login/Login_Movie_UIBP.Login_Movie_UIBP_C", Container="Default", ZOrder=0}},
		{"Login"},
		false,
		false
	);
end

function EventFetchInfo()
	
end

--展示cg
function EventShowMovieCG()
	log("EventShowMovieCG");
    LuaClassObj.HandleUIMessage(bp_moviecg, "UIShow");
end

--展示QQ,WX登录
function EventShowAuthorization()
	log("EventShowAuthorization");
    LuaClassObj.HandleUIMessage(bp_moviecg, "showAuthorization");
end

