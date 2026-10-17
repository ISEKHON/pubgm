--[[
  版本升级相关逻辑
]]--

VersionUpdater =  VersionUpdater or {
	
}

-- lua -> cpp
function VersionUpdater.StartUpdate()
    
end

function VersionUpdater.CancelUpdate()
    
end

--cpp -> lua
function VersionUpdater.OnVersionUpdate(verinfo)
    -- lua -> bp
    -- 提示更新
    -- 强制 或者 非强制
end

function VersionUpdater.OnUpdateEnd(Successful, needRestart)
    -- 更新成功
        -- 直接刷新界面的版本号
        -- 提示重启以进游戏
    -- 更新失败
        -- 提示重试
        -- 提示重启
end

function VersionUpdater.OnUpdateProcess(stage, percent, finished)
    -- 根据 stage 显示文字
    -- 根据 percent 显示进度条
    --finished表示更新完全结束
end

function VersionUpdater.GetStageString(curStage)
    local stageString = 
    {
        --GCloud::VS_FirstExtract
        [69] = "GetingVerInfo", 
        --GCloud::VS_Dolphin_Version
        [10] = "extract first resource", 
        --GCloud::VS_ApkUpdateDownConfig
        [71] = "download apk-update config", 
        --GCloud::VS_ApkUpdateDownDiffFile
        [72] = "download apk-update diff file",
        --GCloud::VS_ApkUpdateDownFullApk
        [73] = "Downloading",
        -- GCloud::VS_ApkUpdateCheckCompletedApk
        [74] = "CheckDownload",
        --GCloud::VS_ApkUpdateCheckLocalApk:
        [75] = "check local apk",
        --GCloud::VS_ApkUpdateCheckConfig:
        [76] = "check apk-update config",
        --GCloud::VS_ApkUpdateCheckDiff:
        [77] = "check apk-update diff file",
        --GCloud::VS_ApkUpdateMergeDiff:
        [78] = "create apk file",
        --GCloud::VS_ApkUpdateCheckFull:
        [79] = "check download apk file",
        --GCloud::VS_SourceUpdateDownloadList:
        [91] = "download src-update config",
        --GCloud::VS_SourcePrepareUpdate:
        [92] = "prepare src-update",
        --GCloud::VS_SourceAnalyseDiff:
        [93] = "src-update analyse diff",
        --GCloud::VS_SourceDownload:
        [94] = "download src-update file",
        --GCloud::VS_SourceExtract:
        [95] = "Extraing",
        --VS_Success
        [99] = "success",
        --VS_Fail
        [100] = "failed",
    };
    
    if stageString[curStage] ~= nil then
        return stageString[curStage];
    end
    return "updating";
end