ActivityGroupUI = ActivityGroupUI or {}

BP_STRUCT_ActivityGroupInfo = 
{
	["id"] = 1				,
	["type"] = 1			,
	["position"] = 1        ,
	["open_time"] = 1111111 ,
	["end_time"] = 1111111  ,
	["button_id"] = 1		,
	["activity_id"] = 0     ,
	["title"] = "ssss"      ,
	["description"] = "ssss",
	["icon"] = "ssss"       ,
	["jump_to"] = "ssss"    ,
}

BP_ARRAY_ActivityInfoSortList = 
{
	BP_STRUCT_ActivityGroupInfo = _G.BP_STRUCT_ActivityGroupInfo
}

BP_CurrentOperateActivityID = 0

BP_CurrentAcitvityTimeStr = ""

BP_CurrentAcitvityState = ""

BP_CurrentActivityRedPoint = false

local AcitvityState = 
{
	["NOTOPEN"] = "NOTOPEN",
	["PROGRESS"] = "PROGRESS",
	["END"] = "END",
}

--注册Widget
function bp_activity_group_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_activity_group,
		{{Path="/Game/UMG/UI_Logic/ActivityGroup/ActivityGroup_BP.ActivityGroup_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ACTIVITY_GROUP_ZORDER}},
		{"Lobby"},
		false,
		false
	);
	-- EventSystem:registEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE,ActivityGroupSystem.ActivityInfoRefresh) 
end

function ActivityGroupShowUI()
	BP_ARRAY_ActivityInfoSortList = DataMgr.activityGroupList
	LuaClassObj.HandleUIMessage(bp_activity_group, "UIShow")

end


function ActivityGroupCloseUI()
	LuaClassObj.HandleUIMessage(bp_activity_group, "UIClose")
end

local function GetItemTimeStr(data)
	BP_CurrentAcitvityTimeStr = os.date("%m.%d", data.open_time) .. "-" .. os.date("%m.%d", data.end_time)
end

local function GetItemState(data)
	local currentDate = FuncUtil.GetServerTimeInSec()
	if currentDate < data.open_time then
		BP_CurrentAcitvityState = AcitvityState["NOTOPEN"]
	elseif currentDate > data.end_time then
		BP_CurrentAcitvityState = AcitvityState["END"]
	elseif currentDate > data.open_time and currentDate < data.end_time then
		BP_CurrentAcitvityState = AcitvityState["PROGRESS"]
	else
		BP_CurrentAcitvityState = AcitvityState["NOTOPEN"]
	end
end

local function GetDataByID(id)
	for _,data in ipairs(BP_ARRAY_ActivityInfoSortList) do 
		if data.id == id then 
			return data
		end
	end
	return nil
end

local  function GetItemRedPoint(data)
	BP_CurrentActivityRedPoint = ActivitySystem.HasActivityRedDotByID(data.activity_id)
end 

function EventActivityGroupGetItemData_Push()
	local  curData = GetDataByID(BP_CurrentOperateActivityID)

	if curData == nil then
		return
	end

	GetItemState(curData)
	GetItemTimeStr(curData)
	GetItemRedPoint(curData)
end

function EventActivityGroupGoTo_Push()
	ActivityGroupCloseUI()
	local  curData = GetDataByID(BP_CurrentOperateActivityID)
	log("Searching id is :" .. curData.activity_id)
	GlobalData:JumpUrl(curData.jump_to)
	--数据收集
	ActivityGroupSystem.ReqButtonClickedEvent(curData.button_id)
end
