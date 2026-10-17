VersionUpdate = VersionUpdate or {}

--注册Widget
function bp_versionupdate_RegisterUI()
    LuaClassObj.SubUIWidgetList(bp_versionupdate,
    {
    {Path="/Game/UMG/UI_BP/Login/Login_Update_UIBP.Login_Update_UIBP_C", Container="Default", ZOrder=2000}
    },
    {"Login"},
    false,
    false
    );
end

BP_CurStage = "updating";
BP_IsExamin = false;
BP_CurPercent = 100

BP_STRUCT_VersionUpdateInfo =
{
    isAppUpdating="1",
    isNeedUpdating="1",
    isForcedUpdating="1",
    versionString="0.1.0.0",
    needDownloadSize_f=0, --以M为单位
    versionDescrition="desc",
    userDefineStr="",
}

function EventFetchInfo()
	
end

function VersionUpdate.Init()
    if BP_VersionUpdateInfo then
        BP_VersionUpdateInfo.isForcedUpdating = "0"
    end
end

function VersionUpdate.OnNoticeUpdate(Info)
    BP_VersionUpdateInfo = Info
	BP_STRUCT_VersionUpdateInfo = Info
	
    BP_VersionUpdateInfo.needDownloadSize_f = tonumber(Info.needDownloadSize) / 1048576
	BP_STRUCT_VersionUpdateInfo.needDownloadSize_f = tonumber(Info.needDownloadSize) / 1048576
	
	log_tree("BP_VersionUpdateInfo",BP_VersionUpdateInfo)
	
	log("BP_VersionUpdateInfo isAppUpdating:"..tostring(BP_VersionUpdateInfo.isAppUpdating))
	log("BP_VersionUpdateInfo isNeedUpdating:"..tostring(BP_VersionUpdateInfo.isNeedUpdating))
	log("BP_VersionUpdateInfo isForcedUpdating:"..tostring(BP_VersionUpdateInfo.isForcedUpdating))
	log("BP_VersionUpdateInfo versionString:"..tostring(BP_VersionUpdateInfo.versionString))
	log("BP_VersionUpdateInfo needDownloadSize_f:"..tostring(BP_VersionUpdateInfo.needDownloadSize_f))
	log("BP_VersionUpdateInfo versionDescrition:"..tostring(BP_VersionUpdateInfo.versionDescrition))
	log("BP_VersionUpdateInfo userDefineStr:"..tostring(BP_VersionUpdateInfo.userDefineStr))
	
	local tips = ""
	-- 版本更新
	if (BP_VersionUpdateInfo.isAppUpdating == "1" and BP_VersionUpdateInfo.needDownloadSize_f > 0) or (BP_VersionUpdateInfo.isAppUpdating == "2" and BP_VersionUpdateInfo.needDownloadSize_f > 0)then
		-- android版本更新 or android and ios资源更新
		local msgConfig = Client.GetTableData("LocalizeRes",201004)
		if msgConfig then
			tips = string.format(msgConfig.TextValue, BP_VersionUpdateInfo.needDownloadSize_f)
		end
	elseif BP_VersionUpdateInfo.isAppUpdating == "1" and BP_VersionUpdateInfo.needDownloadSize_f <= 0 then
		-- ios版本更新
		local msgConfig = Client.GetTableData("LocalizeRes",201005)
		if msgConfig then
			tips = msgConfig.TextValue
		end
	end
	
    if not Client.HasActiveWifi() then
    	--资源更新，提示下载的大小
		local title = ""
		local msgConfig = Client.GetTableData("LocalizeRes",201001)
		if msgConfig then
			title = msgConfig.TextValue
		end
		
		local okLabel = ""
		local okConfig = Client.GetTableData("LocalizeRes",201003)
		if okConfig then
			okLabel = okConfig.TextValue
		end
		
		local cancelLabel = ""
		local cancelConfig = Client.GetTableData("LocalizeRes",110035)
		if cancelConfig then
			cancelLabel = cancelConfig.TextValue
		end
		
		local warning = ""
		if BP_VersionUpdateInfo ~= nil and BP_VersionUpdateInfo.isForcedUpdating == "1" then
			local warningConfig = Client.GetTableData("LocalizeRes",201022)
			if warningConfig then
				warning = warningConfig.TextValue
			end
		end
		
    	CommonMessageBoxUI:ShowPanel(2,title,tips..warning,
    	function()
		    --确认更新
		    LuaClassObj.HandleUIMessage(bp_versionupdate, "NoWifiStartUpdate");
		end,

		function()
			if BP_VersionUpdateInfo.isForcedUpdating == "1" then
				log("BP_VersionUpdateInfo.isForcedUpdating:1 click cancel quitGame")
				
				LuaClassObj.HandleUIMessage(bp_global, "quitGame");
			else
				log("BP_VersionUpdateInfo.isForcedUpdating:0 click cancel cancel update")
				VersionUpdate.CancelUpdate();
		    end
		end,
		okLabel,
		cancelLabel
		);
    end
	LuaClassObj.HandleUIMessage(bp_versionupdate, "ShowUpdateUI");
end

function VersionUpdate.StartGrayUpdate(funcCallBack)
    VersionUpdate.GrayUpdate = true;
    if funcCallBack ~= nil then
        VersionUpdate.CallBackOnUpdateEnd = funcCallBack;
    end
    --开始灰度更新，显示更新UI
    if Client.StartGrayUpdate(GameFrontendHUD) then
        LuaClassObj.HandleUIMessage(bp_versionupdate, "GrayShowWaiting");
    end
    
    VersionUpdate.AlreadyGrayUpdate = true;
end

function VersionUpdate.CancelUpdate()
    --调蓝图的CancelUpdate最终会调到下面的VersionUpdate.OnFinishUpdate()函数
    --就能执行到LuaClassObj.HandleUIMessage(bp_authorization, "doAuthorization");
	LuaClassObj.HandleUIMessage(bp_versionupdate, "CancelUpdate")
end

function VersionUpdate.OnFinishUpdate()
    --隐藏更新界面
    log("versionupdate onfinishupdate")
    LuaClassObj.HandleUIMessage(bp_versionupdate, "Hide");
    
    --正常更新结束,开始鉴权;灰度更新则不用
    if not (VersionUpdate.GrayUpdate) then
    	log("not gray update, doAuthorization")
        LuaClassObj.HandleUIMessage(bp_authorization, "doAuthorization");
    end
    
    --回调
    if (VersionUpdate.CallBackOnUpdateEnd) then
    	log("gray update, do CallBackOnUpdateEnd");
        VersionUpdate.CallBackOnUpdateEnd();
    end
    VersionUpdate.GrayUpdate = false;
    VersionUpdate.CallBackOnUpdateEnd = nil;
	
	--刷新界面里显示的版本号
	if not (VersionUpdate.GrayUpdate) then
		log("finishupdate refreshgameversion")
		LuaClassObj.HandleUIMessage(bp_authorization, "RefreshGameVersion")
	end

	Client.ReportEventLoadingCompleted();
end

function EventWifiNotifyIOSAppUpdate_Push()
    log("BP_VersionUpdateInfo isAppUpdating"..tostring(BP_VersionUpdateInfo.isAppUpdating))
    log("BP_VersionUpdateInfo isNeedUpdating"..tostring(BP_VersionUpdateInfo.isNeedUpdating))
	
	if BP_VersionUpdateInfo.isNeedUpdating == "1" then
		-- 版本更新
		if BP_VersionUpdateInfo.isAppUpdating == "1" then
			log("wifi ios app update")
			
			local title = ""
			local msgConfig = Client.GetTableData("LocalizeRes",201001)
			if msgConfig then
				title = msgConfig.TextValue
			end
			
			local okLabel = ""
			local okConfig = Client.GetTableData("LocalizeRes",201003)
			if okConfig then
				okLabel = okConfig.TextValue
			end
		
			local cancelLabel = ""
			local cancelConfig = Client.GetTableData("LocalizeRes",110035)
			if cancelConfig then
				cancelLabel = cancelConfig.TextValue
			end
			
			local contentStr1 = ""
			local contentStr1Config = Client.GetTableData("LocalizeRes",201005)
			if contentStr1Config then
				contentStr1 = contentStr1Config.TextValue
			end
			
			local contentStr2 = ""
			local contentStr2Config = Client.GetTableData("LocalizeRes",201006)
			if contentStr2Config then
				contentStr2 = contentStr2Config.TextValue
			end
			
			local warning = ""
			if BP_VersionUpdateInfo ~= nil and BP_VersionUpdateInfo.isForcedUpdating == "1" then
				local warningConfig = Client.GetTableData("LocalizeRes",201022)
				if warningConfig then
					warning = warningConfig.TextValue
				end
			end
		
			CommonMessageBoxUI:ShowPanel(2,title,contentStr1..warning,
			function()
                log("wifi ios app update confirm")
				
				GDolphinUpdater.Install(Dolphin);
				-- ios点击跳转后弹窗
				CommonMessageBoxUI:ShowPanel(1,title,contentStr2,
				function()
					VersionUpdate.OnClickJumpToAppStore()
				end);
			end,
			function()
                log("wifi ios app update cancel")
				
				if BP_VersionUpdateInfo.isForcedUpdating == "1" then
					log("BP_VersionUpdateInfo.isForcedUpdating:1 click cancel quitGame")
					
					LuaClassObj.HandleUIMessage(bp_global, "quitGame");
				else
					log("BP_VersionUpdateInfo.isForcedUpdating:0 click cancel cancel update")
					
					VersionUpdate.CancelUpdate();
				end
			end,
			okLabel,
			cancelLabel
		);
		elseif BP_VersionUpdateInfo.isAppUpdating == "2" then
			-- IOS端wifi环境资源更新,不需要弹窗
			log("wifi ios res update")
			
			LuaClassObj.HandleUIMessage(bp_versionupdate, "StartUpdate")
		end
	end
end

function EventWifiNotifyAndroidAppUpdate_Push()
	log("EventWifiNotifyAndroidAppUpdate_Push")
	
	if BP_VersionUpdateInfo.isNeedUpdating == "1" then
		local tips = ""
		if BP_VersionUpdateInfo.isAppUpdating == "1" then
			-- 版本更新
			log("wifi android app update")
			
			local title = ""
			local msgConfig = Client.GetTableData("LocalizeRes",201001)
			if msgConfig then
				title = msgConfig.TextValue
			end
			
			local okLabel = ""
			local okConfig = Client.GetTableData("LocalizeRes",201003)
			if okConfig then
				okLabel = okConfig.TextValue
			end
		
			local cancelLabel = ""
			local cancelConfig = Client.GetTableData("LocalizeRes",110035)
			if cancelConfig then
				cancelLabel = cancelConfig.TextValue
			end
			
			local contentConfig = Client.GetTableData("LocalizeRes",201005)
			if contentConfig then
				tips = contentConfig.TextValue
			end
			
            local contentStr2 = ""
			local contentStr2Config = Client.GetTableData("LocalizeRes",201030) --"请跳转至GooglePlay下载全新版本"
			if contentStr2Config then
				contentStr2 = contentStr2Config.TextValue
			end
            
			local warning = ""
			if BP_VersionUpdateInfo ~= nil and BP_VersionUpdateInfo.isForcedUpdating == "1" then
				local warningConfig = Client.GetTableData("LocalizeRes",201022)
				if warningConfig then
					warning = warningConfig.TextValue
				end
			end

			CommonMessageBoxUI:ShowPanel(2,title,tips..warning,
			--[[
            function()
				log("wifi android app update confirm")
				LuaClassObj.HandleUIMessage(bp_versionupdate, "StartUpdate")
			end,
            ]]
            
            function()
                log("wifi android app update confirm")
				
				GDolphinUpdater.Install(Dolphin);
				-- ios点击跳转后弹窗
				CommonMessageBoxUI:ShowPanel(1,title,contentStr2,
				function()
					VersionUpdate.OnClickJumpToGooglePlay()
				end);
			end,
            
			function()
				log("wifi android app update cancel")
				if BP_VersionUpdateInfo.isForcedUpdating == "1" then
					log("BP_VersionUpdateInfo.isForcedUpdating:1 click cancel quitGame")
					
					LuaClassObj.HandleUIMessage(bp_global, "quitGame");
				else
					log("BP_VersionUpdateInfo.isForcedUpdating:0 click cancel cancel update")
					VersionUpdate.CancelUpdate();
				end
			end,
			okLabel,
			cancelLabel
			);
		elseif BP_VersionUpdateInfo.isAppUpdating == "2" then
			-- android端wifi环境资源更新，不需要弹窗
			log("wifi android res update")
			
			LuaClassObj.HandleUIMessage(bp_versionupdate, "StartUpdate")
		end
	end
end

function EventNoWifiNotifyIOSAppUpdate_Push()
	if BP_VersionUpdateInfo.isNeedUpdating == "1" then
		if BP_VersionUpdateInfo.isAppUpdating == "1" then
            log("no wifi ios app update jump to appstore")
			
			local title = ""
			local msgConfig = Client.GetTableData("LocalizeRes",201001)
			if msgConfig then
				title = msgConfig.TextValue
			end
			
			local contentStr = ""
			local contentConfig = Client.GetTableData("LocalizeRes",201006)
			if contentConfig then
				contentStr = contentConfig.TextValue
			end
			
			GDolphinUpdater.Install(Dolphin);
			CommonMessageBoxUI:ShowPanel(1,title,contentStr,
			function()
			    VersionUpdate.OnClickJumpToAppStore()
			end);
			
		elseif BP_VersionUpdateInfo.isAppUpdating == "2" then
            log("no wifi ios res update")
			
			LuaClassObj.HandleUIMessage(bp_versionupdate, "StartUpdate");
		end
	end
end

function VersionUpdate.OnClickJumpToAppStore()
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
			
	local contentStr = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201006)
	if contentConfig then
		contentStr = contentConfig.TextValue
	end

	GDolphinUpdater.Install(Dolphin)
	CommonMessageBoxUI:ShowPanel(1,title,contentStr,
	function()
		VersionUpdate.OnClickJumpToAppStore()
	end);
end

-- Android无wifi 更新app
function EventNoWifiNotifyAndroidAppUpdate_Push()
	if BP_VersionUpdateInfo.isNeedUpdating == "1" then
		if BP_VersionUpdateInfo.isAppUpdating == "1" then
            log("no wifi android app update jump to googleplay")
			
			local title = ""
			local msgConfig = Client.GetTableData("LocalizeRes",201001)
			if msgConfig then
				title = msgConfig.TextValue
			end
			
			local contentStr = ""
			local contentConfig = Client.GetTableData("LocalizeRes",201030)
			if contentConfig then
				contentStr = contentConfig.TextValue
			end
			
			GDolphinUpdater.Install(Dolphin);
			CommonMessageBoxUI:ShowPanel(1,title,contentStr,
			function()
			    VersionUpdate.OnClickJumpToGooglePlay()
			end);
			
		elseif BP_VersionUpdateInfo.isAppUpdating == "2" then
            log("no wifi android res update")
			
			LuaClassObj.HandleUIMessage(bp_versionupdate, "StartUpdate");
		end
	end
end

-- 国际化跳转googleplay
function VersionUpdate.OnClickJumpToGooglePlay()
    local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
			
	local contentStr = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201030)  -- "请跳转至GooglePlay下载全新版本"
	if contentConfig then
		contentStr = contentConfig.TextValue
	end

	GDolphinUpdater.Install(Dolphin)
	CommonMessageBoxUI:ShowPanel(1,title,contentStr,
	function()
		VersionUpdate.OnClickJumpToGooglePlay()
	end);
end


--windows端(默认全忽略)
function EventWindowsAppUpdate()
    if BP_VersionUpdateInfo.isNeedUpdating == "1" then
		local tips = ""
		if BP_VersionUpdateInfo.isAppUpdating == "1" then
			--忽略大版本更新
			VersionUpdate.CancelUpdate();
		elseif BP_VersionUpdateInfo.isAppUpdating == "2" then
			--忽略资源更新
			VersionUpdate.CancelUpdate();
		end
    else
        VersionUpdate.CancelUpdate();
	end
end

function VersionUpdate.OnRestartGame()
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201007)
	if msgConfig then
		title = msgConfig.TextValue
	end
	
	local content = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201008)
	if contentConfig then
		content = contentConfig.TextValue
	end
	
	LuaClassObj.HandleUIMessage(bp_versionupdate, "OnFinished");
    CommonMessageBoxUI:ShowPanel(1,title, content,
		function()
		    --退出游戏
		    LuaClassObj.HandleUIMessage(bp_global, "quitGame");
	end);
end

-- android拉起apk安装
function VersionUpdate.OnReadyToInstallApp()
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
	
	local content = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201009)
	if contentConfig then
		content = contentConfig.TextValue
	end
	
	LuaClassObj.HandleUIMessage(bp_versionupdate, "OnFinished");
	
	log("GDolphinUpdater.Install")
	GDolphinUpdater.Install(Dolphin)
	CommonMessageBoxUI:ShowPanel(1,title,content,
		function()
			log("GDolphinUpdater.Install2")
			
			VersionUpdate.OnClickInstallApp()
		end);
end

function VersionUpdate.OnClickInstallApp()
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
	
	local content = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201009)
	if contentConfig then
		content = contentConfig.TextValue
	end
	
	log("GDolphinUpdater.OnClickInstallApp")
	GDolphinUpdater.Install(Dolphin)
	CommonMessageBoxUI:ShowPanel(1,title,content,
		function()
			log("GDolphinUpdater.OnClickInstallApp2")
			
			VersionUpdate.OnClickInstallApp()
	end);
end

function VersionUpdate.OnUpdateProcess(curStage)
	log("onupdateprocess"..tostring(curStage))
    if 69 == curStage or 71 == curStage then
        BP_CurStage = "GetingVerInfo"
	elseif 70 == curStage then
		BP_CurStage = "StartUpdateApk"--开始更新安装包
	elseif 74 == curStage or 75 == curStage or 76 == curStage or 77 == curStage or 79== curStage then
		BP_CurStage = "CheckingValidity"--正在校验安装包合法性
    elseif 95 == curStage then
        BP_CurStage = "Extraing"
    elseif 78 == curStage then
		BP_CurStage = "ApkUpdateMergeDiff"
	elseif 91 == curStage then
		BP_CurStage = "SourceUpdateDownloadList"
	elseif 92 == curStage then
		BP_CurStage = "SourcePrepareUpdate"
	elseif 93 == curStage then
		BP_CurStage = "SourceAnalyseDiff"
	elseif 99 == curStage then
		BP_CurStage = "Success"
	else
        BP_CurStage = "Downloading"
    end
    --刷新进度条
    LuaClassObj.HandleUIMessage(bp_versionupdate, "RefreshProgress");
end

function VersionUpdate.OnNoticeUpdateError(errorCode)
	log("OnNoticeUpdateError"..tostring(errorCode))
	local code = tonumber(errorCode)
	local tips = ""
    local can_ignore=true;
	if code == 689045511 or code == 689045510 or code == 353501190 or code == 353435649 or code == 353501191 or code == 353502185 or code == 353501240 or code == 353501600 or code == 353501588 or code == 353501587 or code == 353501236 or
	code == 353501207 or code == 353502189 or code == 353501202 or code == 353502085 or code == 353501684 or code == 353501584 or code == 353501687 or code == 353501598 or code == 353501212 or
	code == 353501686 or code == 353501585 or code == 353501219 or code == 689045908 or code == 689045556 or code == 554827782 or code == 554827832 or code == 554827828 or code == 554828180 or
	code == 554762241 or code == 554828781 or code == 554827783 or code == 154140673 or code == 154140674 or code == 154140675 or (code >= 154140677 and code <= 154140697) or
	code == 154140711 or code == 154140712 or code == 87031824 or code == 420610452 or code == 154140706 or code == 353501185 or code == 154140711 then
		local msgConfig = Client.GetTableData("LocalizeRes",201010)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
        can_ignore = false
		
		VersionUpdate.ShowRetryDownloadPanel(tips)
	elseif code == 355471270 or code == 355467269 or code == 355469265 or code == 691011599 or code == 556793868 or code == 556793861 or code == 691011598 then
		local msgConfig = Client.GetTableData("LocalizeRes",201011)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
        can_ignore = false
		
		VersionUpdate.ShowRetryDownloadPanel(tips)
	elseif code == 353697820 or code == 555745297 or code == 689963036 or code == 689242140 then
		local msgConfig = Client.GetTableData("LocalizeRes",201012)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
        can_ignore = false
		
		VersionUpdate.ShowCofirmPanel(tips)
	elseif code == 688914441 or code == 556793859 or code == 288358404 or (code >= 422576129 and code <= 422576148) or (code >= 420478976 and code <= 421527551) or (code >= 489684993 and code <= 489685003) or 
	(code >= 487587840 and code <= 488636415) or (code >= 87031809 and code <= 87031821) or code == 87031823 or code == 691011591 or code == 691011585 then
		local msgConfig = Client.GetTableData("LocalizeRes",201012)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
        can_ignore = false
		
		VersionUpdate.ShowRetryDownloadPanel(tips)
	elseif code == 154140709 or code == 154140688 then
		local msgConfig = Client.GetTableData("LocalizeRes",201013)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
		
		--VersionUpdate.ShowCofirmPanel(tips)
	elseif code == 353697796 or code == 353697914 or code == 353697822 or code == 353697794 or code == 353697797 or code == 353697805 or code == 556793857 or code == 555745310 or code == 556793874 or code == 289407004 or 
	code == 289406980 or code == 289406993 or code == 289407098 or code == 289407085 or code == 288358406 or code == 289407006 or code == 289407071 or code == 691011585 then
		local msgConfig = Client.GetTableData("LocalizeRes",201014)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
		
		can_ignore = false
		VersionUpdate.ShowCofirmPanel(tips)
	else
		local msgConfig = Client.GetTableData("LocalizeRes",201015)
		if msgConfig then
			tips = string.format(msgConfig.TextValue,tostring(errorCode))
		end
		
		can_ignore = false
		VersionUpdate.ShowCofirmPanel(tips)
		--[[(code >=355467264 and code <= 356515839) or code == 288358400 or code == 288358401 or code == 288358402 or code == 288358403 or code == 288358405 or (code >= 287309824 and code <= 288358399) or code == 154140676 or 
	code == 87031822 or code == 556793868 or code == 691011591 or code == 694288387--]]
	end
	
    if can_ignore then
        ---对某些“错误码”宽容一点，仅仅更新流程的错误就阻止游戏对谁都没好处，蜂拥的来联系工作人员就更惨了。
        GDolphinUpdater.FinishUpdate(Dolphin);
        return;
    end
end

function VersionUpdate.ShowRetryDownloadPanel(tips)
	log("showretrydownloadpanel"..tips)
	
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
	
	local okLabel = ""
	local okConfig = Client.GetTableData("LocalizeRes",201002)
	if okConfig then
		okLabel = okConfig.TextValue
	end
		
	local cancelLabel = ""
	local cancelConfig = Client.GetTableData("LocalizeRes",110035)
	if cancelConfig then
		cancelLabel = cancelConfig.TextValue
	end
	
	local warning = ""
	if (BP_VersionUpdateInfo ~= nil and BP_VersionUpdateInfo.isForcedUpdating == "1") or BP_VersionUpdateInfo == nil then
		local warningConfig = Client.GetTableData("LocalizeRes",201022)
		if warningConfig then
			warning = warningConfig.TextValue
		end
	end
	
	CommonMessageBoxUI:ShowPanel(2,title,tips..warning,
		function()
			log("showretrydownloadpanel retrydownload")
			
			LuaClassObj.HandleUIMessage(bp_versionupdate, "RetryDownload")
		end,	
		function()
			log("showretrydownloadpanel cancelupdate")
			if BP_VersionUpdateInfo ~= nil then
				if BP_VersionUpdateInfo.isForcedUpdating == "1" then
					log("BP_VersionUpdateInfo.isForcedUpdating:1 click cancel quitGame")
					
					LuaClassObj.HandleUIMessage(bp_global, "quitGame");
				else
					log("BP_VersionUpdateInfo.isForcedUpdating:0 click cancel cancel update")
					VersionUpdate.CancelUpdate();
				end
			else
				log("BP_VersionUpdateInfo is nil: click cancel quitGame")
				
				LuaClassObj.HandleUIMessage(bp_global, "quitGame");
			end
		end,
	okLabel,
	cancelLabel);
end

function VersionUpdate.ShowCofirmPanel(tips)
	log("showcofirmpanel"..tips)
	
	local title = ""
	local msgConfig = Client.GetTableData("LocalizeRes",201001)
	if msgConfig then
		title = msgConfig.TextValue
	end
	
	local warning = ""
	if (BP_VersionUpdateInfo ~= nil and BP_VersionUpdateInfo.isForcedUpdating == "1") or BP_VersionUpdateInfo == nil then
		local warningConfig = Client.GetTableData("LocalizeRes",201022)
		if warningConfig then
			warning = warningConfig.TextValue
		end
	end
	
	CommonMessageBoxUI:ShowPanel(1,title,tips..warning,
		function()
			log("showcofirmpanel cancelupdate")
			
			if BP_VersionUpdateInfo ~= nil then
				if BP_VersionUpdateInfo.isForcedUpdating == "1" then
					log("BP_VersionUpdateInfo.isForcedUpdating:1 click cancel quitGame")
					
					LuaClassObj.HandleUIMessage(bp_global, "quitGame");
				else
					log("BP_VersionUpdateInfo.isForcedUpdating:0 click cancel cancel update")
					VersionUpdate.CancelUpdate();
				end
			else
				log("BP_VersionUpdateInfo is nil: show cofirmpanel click cancel cancel update")
				LuaClassObj.HandleUIMessage(bp_global, "quitGame");
			end
		end);
end

-- 无网络环境下点击重试按钮
function VersionUpdate.RetryUpdateNoConnection()
	log("VersionUpdate.RetryUpdateNoConnection")
	
	local content = ""
	local contentConfig = Client.GetTableData("LocalizeRes",201016)
	if contentConfig then
		content = contentConfig.TextValue
	end
	
	VersionUpdate.ShowRetryDownloadPanel(content)
end

-- 无连接时点击开始更新，弹出提示框当前网络无连接
function EventNoConnectionStartUpdate_Push()
	log("EventNoConnectionStartUpdate_Push")
	
	VersionUpdate.RetryUpdateNoConnection()
end