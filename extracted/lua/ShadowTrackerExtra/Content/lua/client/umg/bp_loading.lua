--加载界面

LoadingUI = LoadingUI or 
{
	
}

--注册widget
function bp_loading_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_loading,
    {{Path="/Game/UMG/UI_BP/LoginLoading/Login_Loading_UIBP.Login_Loading_UIBP_C", Container="Default", ZOrder=5000}},
    {"Lobby"},
	true,
	true
  );
end

function bp_loading_OnModeSwitched(gamestatus)
	log("OnModeSwitched gamestatus = " .. gamestatus);
    -- 进入场景成功关闭loading(战斗场景不要依赖于UI的切换)，否则会导致场景并未加载完毕，loading却没了--
    if gamestatus ~= "Fighting" then
    	LoadingUI.RefreshLoadPercent(1);
    end
end

function bp_loading_OnModeAboutToSwitched()
    
end

BP_Percent_f = 1.0;
BP_InitPercent = 0;
BP_LoadingTo = 0

function EventFetchInfo()
	 
end

function LoadingUI.RefreshLoadPercent(p)
	log("---scene object loading finished, start loading progress bar----"..p);
    BP_Percent_f = p;
    LuaClassObj.HandleUIMessage(bp_loading, "RefreshLoading");
end

function LoadingUI:Init()
	LuaClassObj.HandleUIMessage(bp_loading, "UIShow");
end

function LoadingUI:Hide()
	LuaClassObj.HandleUIMessage(bp_loading, "UIHide");
end

function LoadingUI:Release()
end