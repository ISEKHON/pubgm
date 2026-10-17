--设置头像框UI
RoleInfoAvatarFrameUI = RoleInfoAvatarFrameUI or
{
    bShow = false,
}

BP_STRUCT_RoleInfoAvatarFrame =
{
	id = 0,
    name = "",
    state = "",     --状态 use使用中,has拥有,none未拥有
    desc = "",      --描述
    desc_get = "",  --获得途径
    expire_time = "",  --限时
};

BP_ARRAY_RoleInfoAvatarFrameList =
{
    BP_STRUCT_RoleInfoAvatarFrame = _G.BP_STRUCT_RoleInfoAvatarFrame,
};

RoleInfoAvatarFrameSelfUid = ""
RoleInfoAvatarFrameSelfUrl = ""
RoleInfoAvatarFrameCurUseId = 0

--注册Widget
function bp_roleinfo_avatarframe_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_roleinfo_avatarframe,
		{{Path="/Game/UMG/UI_Logic/RoleInfo/RoleInfo_AvatarFrame_BP.RoleInfo_AvatarFrame_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ROLEINFO_ZORDER+1}},
		{"Lobby"},
		false,
		false,
		true
	);
end

function RoleInfoAvatarFrameUI.Init()
	--log("RoleInfoAvatarFrameUI.Init");
	LuaClassObj.HandleDynamicCreation(bp_roleinfo_avatarframe);
    RoleInfoAvatarFrameSelfUid = tostring(DataMgr.roleData.uid);
    RoleInfoAvatarFrameSelfUrl = DataMgr.roleData.headIconUrl;
    RoleInfoAvatarFrameCurUseId = RoleInfoAvatarFrameSystem.UsedId;
    LuaClassObj.HandleUIMessage(bp_roleinfo_avatarframe, "ShowUI");
    RoleInfoAvatarFrameUI.bShow = true
end

function RoleInfoAvatarFrameUI.Release()
	--log("RoleInfoAvatarFrameUI.Release");
end

local function TimeToString(tm)
    if type(tm) ~= "number" then
        return ""
    end
    --local pre_title = "使用期限:"
    local pre_title = Client.GetTableData("LocalizeRes", "301299").TextValue;
    log("pre_title: " .. pre_title);
    tm = math.modf(tm)
    if tm > 1 then
        local nowtime = NetUtil.GetCurServerTime()
        local last_tm = tm - nowtime
        if last_tm < 0 then
            last_tm = 0
        end
        local days = math.floor(last_tm / (24*60*60))
        if days >= 1 then
            days = math.ceil(last_tm / (24*60*60))
            --return pre_title..string.format("剩余%d天", days)
            return pre_title..string.format(Client.GetTableData("LocalizeRes", "301272").TextValue, days)
        end
        local hours = math.ceil(last_tm / (60*60))
        --return pre_title..string.format("剩余%d小时", hours)
        return pre_title..string.format(Client.GetTableData("LocalizeRes", "301271").TextValue, hours)
    else
        --return pre_title.."永久使用"
        return pre_title..Client.GetTableData("LocalizeRes", "301300").TextValue
    end
end

function RoleInfoAvatarFrameUI.Refresh()
	--log("RoleInfoAvatarFrameUI.Refresh");
    RoleInfoAvatarFrameCurUseId = RoleInfoAvatarFrameSystem.UsedId;
    BP_ARRAY_RoleInfoAvatarFrameList = {}
    local data = Client.GetTable("AvatarFrame");
	for k,v in pairs(data) do
        local dat = FuncUtil:CopyTable(BP_STRUCT_RoleInfoAvatarFrame)
        dat.id = v.ID
        dat.name = v.Name
        local itm = RoleInfoAvatarFrameSystem.AvatarFrameList[v.ID]
        if itm ~= nil then
            dat.expire_time = TimeToString(itm.expire_time)
            dat.state = "has"
        else
            dat.expire_time = v.DescTime
            dat.state = "none"
        end
        if RoleInfoAvatarFrameSystem.UsedId == v.ID then
            dat.state = "use"
        end
        dat.desc = v.Desc
        dat.desc_get = v.DescGet
        table.insert(BP_ARRAY_RoleInfoAvatarFrameList, dat)
    end
    local tmpSort = {
        use = 1,
        has = 1,
        none = 100,
    }
    --排序
    local function funcSort(a,b)
        return (a.id*tmpSort[a.state]) < (b.id*tmpSort[b.state])
    end
    table.sort(BP_ARRAY_RoleInfoAvatarFrameList, funcSort)
    --log_tree("BP_ARRAY_RoleInfoAvatarFrameList=", BP_ARRAY_RoleInfoAvatarFrameList)
    LuaClassObj.HandleUIMessage(bp_roleinfo_avatarframe, "RefreshUI");
end

function RoleInfoAvatarFrameUI.RefreshSelect()
	--log("RoleInfoAvatarFrameUI.RefreshSelect");
    local data = Client.GetTable("AvatarFrame");
	for i,v in ipairs(BP_ARRAY_RoleInfoAvatarFrameList) do
        local itm = RoleInfoAvatarFrameSystem.AvatarFrameList[v.id]
        if itm ~= nil then
            v.state = "has"
        else
            v.state = "none"
        end
        if RoleInfoAvatarFrameSystem.UsedId == v.id then
            v.state = "use"
        end
    end
    LuaClassObj.HandleUIMessage(bp_roleinfo_avatarframe, "RefreshSelect");
end

function RoleInfoAvatarFrameUI.IsShow()
    return RoleInfoAvatarFrameUI.bShow
end

--(以Event开头的函数名就能暴露给蓝图调用)

function EventRoleInfoAvatarFrameUIClose()
	--log("EventRoleInfoAvatarFrameUIClose");
    RoleInfoAvatarFrameUI.Release()
    RoleInfoAvatarFrameSystem.Release()
    RoleInfoAvatarFrameUI.bShow = false
end

function EventRoleInfoAvatarFrameUse()
	--log_tree("EventRoleInfoAvatarFrameUse=", RoleInfoAvatarFrameCurUseId);
    RoleInfoAvatarFrameSystem.change_avatar_box(RoleInfoAvatarFrameCurUseId);
end

function EventRoleInfoAvatarFrameFetchInfo()
end
