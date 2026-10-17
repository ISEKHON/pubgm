FaceSlapSystem = FaceSlapSystem or
{
    Inited = false,
    IsFirstShow = true,
    CurrentModuleIdx = 0,
    ModuleInfoArray = {},
    HasBegin = false,

    IsDataReady = false,
};

function FaceSlapSystem.Init()
    FaceSlapSystem.Reset();

    if FaceSlapSystem.Inited then
    end

    FaceSlapSystem.Inited = true;

    ------------------这里添加拍脸模块和显示检测，相关模块需实现跳转EventJumpUrl
    table.insert(FaceSlapSystem.ModuleInfoArray, {id = BP_ENUM_MODULE_EIGHT_DAY, check = EightDayUI.ShouldSlap});
    --table.insert(FaceSlapSystem.ModuleInfoArray, {id = BP_ENUM_MODULE_WEEK_SIGNUP, check = WeekSignUpUI.ShouldSlap});
    -----------------------------------------------------------------------------

    EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, FaceSlapSystem.OnActivityChange);
    log_tree("FaceSlapSystem.Init", FaceSlapSystem.ModuleInfoArray);
end

function FaceSlapSystem.Reset()
    log("FaceSlapSystem.Reset");
    FaceSlapSystem.IsFirstShow = true;
    FaceSlapSystem.CurrentModuleIdx = 0;
    FaceSlapSystem.HasBegin = false;
    FaceSlapSystem.IsDataReady = false;
end

function FaceSlapSystem.OnActivityChange()
    log("FaceSlapSystem.OnActivityChange")
    FaceSlapSystem.IsDataReady = true;
    -- log("FaceSlapSystem.OnActivityChange hasData = "..tostring(DataMgr.GetActivityByType(ActivityType["NEW_PLAYER"]) ~= nil));
    FaceSlapSystem.ShowNext(0);
end

function FaceSlapSystem.BeginShow()
    log("FaceSlapSystem.BeginShow");
    if GlobalData:IsIOSCheck() then
        return;
    end

    if not FaceSlapSystem.IsFirstShow then
        return;
    end

    FaceSlapSystem.IsFirstShow = false;
    FaceSlapSystem.HasBegin = true;
    FaceSlapSystem.ShowNext(0);
end

function FaceSlapSystem.ShowNext(moduleID)
    log("FaceSlapSystem.ShowNext FaceSlapSystem.HasBegin "..tostring(FaceSlapSystem.HasBegin));
    log("FaceSlapSystem.ShowNext FaceSlapSystem.IsDataReady "..tostring(FaceSlapSystem.IsDataReady));
    if not FaceSlapSystem.HasBegin or not FaceSlapSystem.IsDataReady then
        return;
    end

    local currentData = FaceSlapSystem.ModuleInfoArray[FaceSlapSystem.CurrentModuleIdx];
    log_tree("FaceSlapSystem.ShowNext currentData");
    if currentData and currentData.id ~= moduleID then
        return;
    end

    -- log("FaceSlapSystem.ShowNext moduleID "..moduleID);

    local nextIndex = 0;
    for i=FaceSlapSystem.CurrentModuleIdx+1,#FaceSlapSystem.ModuleInfoArray do
        local info = FaceSlapSystem.ModuleInfoArray[i];
        if info and info.check and info.check() then
            nextIndex = i;
            break;
        end
    end

    if nextIndex == 0 then
        FaceSlapSystem.CurrentModuleIdx = #FaceSlapSystem.ModuleInfoArray + 1;
    else
        log("FaceSlapSystem.ShowNext");
        FaceSlapSystem.Show(nextIndex);
    end
end

function FaceSlapSystem.Show(index)
    if index <= 0 or index > #FaceSlapSystem.ModuleInfoArray then
        return;
    end

    local moduleInfo = FaceSlapSystem.ModuleInfoArray[index];
    if moduleInfo == nil then
        return;
    end

    FaceSlapSystem.CurrentModuleIdx = index;

    BP_Global_Url = string.format("game://?module=%d", moduleInfo.id);
    log("FaceSlapSystem.Show:"..BP_Global_Url);
    EventJumpUrl();
end
