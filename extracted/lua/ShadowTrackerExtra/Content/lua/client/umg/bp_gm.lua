GM_UI = GM_UI or 
{
    PathSave = "",
}

BP_gmMsg = "";

-- 注册面板
function bp_gm_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_gm,
        {{Path="/Game/UMG/UI_BP/GM/GM_BP.GM_BP_C", Container="Default", ZOrder=500}},
		{"Lobby","Login"},
		false,
		false,
		true
	);	
	
	BP_gmMsg = "";
end

function GM_UI:ShowPanel()
	LuaClassObj.HandleDynamicCreation(bp_gm);
	LuaClassObj.HandleUIMessage(bp_gm, "UIShow");
end

function TestUrl(url)
    GlobalData:JumpUrl(url);
end

function GM_UI.Test()
    log("GM_UI.Test"..debug.traceback());
end

function GM_UI.ReloadModule(module)
    GM_UI.InitPackagePath()
    DoReloadLua(module)
end

function GM_UI.ReloadLua()
    GM_UI.InitPackagePath()

    for i,v in ipairs(reload_cfg.modules) do
        DoReloadLua(v);
    end
end

function DoReloadLua(module)
    package.loaded[module] = nil;
    require(module);
    log("reload module:"..module);
end

function GM_UI.InitPackagePath()
    if GM_UI.PathSave == "" then
        GM_UI.PathSave = package.path;
    end

    -- 重新加载配置模块
    package.path = GM_UI.PathSave..";../../../../Survive/Source/Lua/client/config/?.lua";
    DoReloadLua("reload_cfg")

    -- 通过配置模块设置查找路径
    for i,v in ipairs(reload_cfg.dirs) do
        package.path = string.format("%s;%s", package.path, v);
    end

    package.path = package.path..";";
end


-- function EventGmSend_Push( ... )
--     -- body
--     log("SendGM:"..BP_gmMsg);
--     NetUtil.SendPkg("exec", BP_gmMsg);
-- end

function GM_UI.GetParams(targetS)
    local targetS = string.match( targetS, "%s*(.*)");
    if string.len(targetS) == 0 then
        return nil, nil;
    end

    local i, j = string.find(targetS, "(\"[^\"]+\")");
    if i ~= 1 then
        i, j = string.find(targetS, "[^ ]+");        
    end

    -- print( targetS )
    if i ~= 1 then
        sandbox.LogError("GM解析错误");
        return nil, nil;
    end

    return string.sub(targetS, i, j), string.sub(targetS, j+1);
end

function GM_UI.GetGMWordList(s)
    -- body
    local list = {};
    local result, deltaS = GM_UI.GetParams(s);
    while result ~= nil do
        table.insert( list, result );
        result, deltaS = GM_UI.GetParams(deltaS);
    end

    return list;
end

function GM_UI.TestPrint(s)
    log("GM_UI.TestPrint :"..package.cpath);
end

function GM_UI.CallString(s)
    log(string.format("call gm : %s", s))
    local func = load(s);
    local r, msg = pcall(func);
    if not r then
        sandbox.LogError(string.format("gm error :%s", msg));
    end
end

function EventGmSend_Push()
	-- local results = GM_UI:split(BP_gmMsg, " ");
    local c = string.sub(BP_gmMsg, 1, 2);
    if string.lower(c) == "c " then
        local cmd = string.match(string.sub(BP_gmMsg, 2), "%s*(.*)");
        GM_UI.CallString(cmd);
        return;
    end

    local results = GM_UI.GetGMWordList(BP_gmMsg);
		
	local msg = results[1].."(";
	if #results > 1 then
		msg = msg..results[2];
	end
	if #results > 2 then
		msg = msg..","..results[3];
	end
	if #results > 3 then
		msg = msg..","..results[4];
	end
	if #results > 4 then
		msg = msg..","..results[5];
	end
	if #results > 6 then
		msg = msg..","..results[7];
	end
	if #results > 7 then
		msg = msg..","..results[8];
	end
	if #results > 8 then
		msg = msg..","..results[9];
	end
	if #results > 9 then
		msg = msg..","..results[10];
	end	
	msg = msg..")";
	
	log("SendGM:"..msg);
	NetUtil.SendPkg("exec", msg);
end

function EventGmSendShowTeamUpUI()
	--打开UI
	--TeamUPFriendUI.CheckSwitch();
	--TeamUpUI.CheckSwitch();
	ShareUI.ShowUI();
end

function EventGmShowChatEntrance()
	LobbyChatSystem.canOpenChatWnd = true;	
	LobbyChatSystem.Entry();
end

function EventGmOpenPromotor()
	PromotionMgr.SendGetPromotionInfo() 
end

function GM_UI:split(str, d) --str是需要查分的对象 d是分界符  
    local lst = { }  
    local n = string.len(str)--长度  
    local start = 1  
    while start <= n do  
        local i = string.find(str, d, start) -- find 'next' 0  
        if i == nil then   
            table.insert(lst, string.sub(str, start, n))  
            break   
        end  
        table.insert(lst, string.sub(str, start, i-1))  
        if i == n then  
            table.insert(lst, "")  
            break  
        end  
        start = i + 1
    end  
    return lst  
end  