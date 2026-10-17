RoomWaitingUI = RoomWaitingUI or
{
	IsRegister = false;
}

--注册Widget
function bp_room_waiting_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_room_waiting,
	{{Path="/Game/UMG/UI_BP/Room/RoomWaiting_BP.RoomWaiting_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ROOM_WAITING_ZORDER}},
    {"Lobby"},
	false,
	bp_room_waiting_OnModeSwitched ~= nil,
	true
  );
  
  RoomWaitingUI.InitRoomGroupTypeList();
  FuncUtil:InitConfigs(); --初始化临时放在这，等有好地方再挪
end

--进入Lobby请求房间界面
function bp_room_waiting_OnModeSwitched(gamestatus)
	log("bp_room_waiting_OnModeSwitched gamestatus = " .. gamestatus);
	-- RoomWaitingUI.IsRegister = true;
	-- if string.lower(gamestatus) == "lobby" then
		-- if RoomUI.IsRegister then
			-- log("bp_room_waiting room_info_request");
			-- NetUtil.SendPkg("room_info_request");
		-- end
	-- end
end

function bp_room_waiting_OnModeAboutToSwitched(gamestatus)
end

--房间内信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_RoomWaitingInfo =
{
	name="房间名",
	owner_name = "房主名", 
	owner_id="房主uid",
	map_id = 1,
	state = "房间状态",
	id = 1,
	player_count=1,	
	group_type = 1, --1：单人模式 2:双人模式 4：4人模式
	create_time = 0,	--房间创建时间
	game_start = 0,	--开局了多久时间，state为游戏中才有效
	lock_state = true,	--	密码锁
	version = "",
}

--房间成员信息
BP_STRUCT_RoomMemberInfo =
{
	openid="openid",
	name="角色名",
	level=1,
	svr=0,
	isRoomMaster=false,
	pos = 0,
	state = "",
	head_url = "",
	gender = 0,
	frame_level = 0,
};

--房间成员信息列表
BP_ARRAY_RoomMemberList = 
{
	BP_STRUCT_RoomMemberInfo=_G.BP_STRUCT_RoomMemberInfo,
};

--自己的信息
BP_STRUCT_RoomSelfInfo =
{
	openid="openid",
	name="角色名",
	level=1,
	svr=0,
	isRoomMaster=false,
	pos = 0,
	state = "",
	head_url = "",
	gender = 0,
	frame_level = 0,
};

--房间密码
BP_Room_Passwd = "";

--是否房主
BP_IsRoomOwner = false;

--选中的新的位置
BP_SelectNewPos = 0;

--被踢的位置
BP_KickedMemberPos = 0;

--自己的uid
BP_Room_SelfID = "";

--旧位置
BP_Room_SelfOldPos = 0;

--被点击玩家的ID
BP_Room_SelectedRoleID = "";

--修改的房间名
BP_Room_ChangeName = "";

--是否主动离开房间
BP_Room_InitiativeLeave = false;

--是否在房间
BP_Room_IsInRoom = false;

--二维码图片路径
BP_Room_QRIamgePath = "";

--模式信息
BP_STRUCT_RoomGroupType =
{
	Type = 0, --1,2,4
	GroupName = "",
};

--模式列表
BP_ARRAY_RoomGroupTypeList = 
{
	BP_STRUCT_RoomGroupType=_G.BP_STRUCT_RoomGroupType, 
};

--当前选择的Group
BP_SelectedGroupType= 0;

--当前选择的地图ID
BP_SelectedMapID = 0;

function RoomWaitingUI.InitRoomGroupTypeList()	
	BP_ARRAY_RoomGroupTypeList = {};
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 1, GroupName = "单人模式"});
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 2, GroupName = "双人模式"});
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 4, GroupName = "四人模式"});
	local groupNameString = Client.GetTableData("LocalizeRes", "110049").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 1, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110050").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 2, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110051").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 4, GroupName = groupNameString});
end

local function RoomWaitingEventHandler(eventType, eventID, vars)
    if eventType ~= EVENTTYPE_ROOM then
		return;
    end
    
    if eventID == EVENTID_UPDATE_BP_DATA then 
		RoomWaitingUI:UpdateBPData();
    end
end

function RoomWaitingUI:Init()
	log("RoomWaitingUI Init");
	LuaClassObj.HandleDynamicCreation(bp_room_waiting);
	
	BP_Room_SelfID = DataMgr.roleData.uid;
	BP_Room_InitiativeLeave = false;
	BP_Room_IsInRoom = false;
	
	LobbyChatEntranceUI.SetIsRoomMode(true);
	
	EventSystem:registEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA, RoomWaitingEventHandler);
end

function RoomWaitingUI:Release()
	log("RoomWaitingUI release");
	BP_Room_SelfID = "";
	BP_Room_InitiativeLeave = false;
	BP_Room_IsInRoom = false;
	
	EventSystem:unregistEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA, RoomWaitingEventHandler);
end

function RoomWaitingUI:UpdateBPData()
	log("RoomWaitingUI UpdateBPData");
	
	--是否房主
	if not RoomSystem.isRoomOwner() then
		BP_IsRoomOwner = false;
	else
		BP_IsRoomOwner = true;
	end
	
	--更新房间信息
	BP_STRUCT_RoomWaitingInfo = RoomSystem.CurrentRoomInfo;
	if BP_STRUCT_RoomWaitingInfo ~= nil then
		log_tree("--roominfo--", BP_STRUCT_RoomWaitingInfo)
	end
	
	--更新玩家列表
	BP_ARRAY_RoomMemberList = {};
	BP_STRUCT_RoomSelfInfo = {};
	if RoomSystem.CurrentRoomInfo ~= nil and RoomSystem.CurrentRoomInfo.MemberInfoList ~= nil then
		for i=1, #RoomSystem.CurrentRoomInfo.MemberInfoList do
			local _memberInfo = RoomSystem.CurrentRoomInfo.MemberInfoList[i];
			if _memberInfo ~= nil then
				table.insert(BP_ARRAY_RoomMemberList, _memberInfo);
				if _memberInfo.openid == DataMgr.roleData.uid then
					BP_STRUCT_RoomSelfInfo = _memberInfo;
				end
			end
		end   
	end
	log_tree("--memberlist--", BP_ARRAY_RoomMemberList);
	log_tree("--selfinfo--", BP_STRUCT_RoomSelfInfo);
end

function RoomWaitingUI.OnClickBtnDisbandOK()
	RoomSystem.req_exit_room();
end

function RoomWaitingUI.IsInRoom()
	return BP_Room_IsInRoom;
end

function RoomWaitingUI.SetQRImagePath(QRImagePath)
	BP_Room_QRIamgePath = QRImagePath;
end





--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
end

function EventRoomWaitingRelease()
	log("EventRoomWaitingRelease");
	RoomWaitingUI:Release();
end

--请求更换位置
function EventRequestChangeRoomPos()
	log("EventRequestChangeRoomPos " .. BP_SelectNewPos);
	
	if BP_STRUCT_RoomWaitingInfo == nil then
		log("request change room: not found room info");
		return;		
	end
	
	BP_Room_SelfOldPos = BP_STRUCT_RoomSelfInfo.pos;
	
	RoomSystem.req_change_room_pos_request(BP_STRUCT_RoomWaitingInfo.id, BP_SelectNewPos+1)
end

--请求踢人
function EventRequestKickMember()
	log("EventRequestKickMember " .. BP_KickedMemberPos);
	
	if not RoomSystem.isRoomOwner() then
		log("kick member: not room owner");
		return;
	end
	
	if BP_STRUCT_RoomWaitingInfo == nil then
		log("kick member: not found room info");
		return;		
	end
	
	local findKickedMemberID = "";
	for memberIndex = 1, #BP_ARRAY_RoomMemberList do
		local memberInfo = BP_ARRAY_RoomMemberList[memberIndex];
		if memberInfo ~= nil and memberInfo.pos == BP_KickedMemberPos then
			findKickedMemberID = memberInfo.openid;
			break;
		end
	end
	
	if findKickedMemberID == "" then
		log("kick member: not find memberID");
		return;		
	end
	
	RoomSystem.req_room_kick_request(BP_STRUCT_RoomWaitingInfo.id,  tonumber(findKickedMemberID));
end

--退出房间
function EventExitRoom()
	RoomSystem.req_exit_room();
end

--开始游戏
function EventStarGame()
	if BP_STRUCT_RoomWaitingInfo.state == "gaming" then
		DataMgr.ShowNoticeByID(110130);
		return;
	end
	RoomSystem.req_start_game();
end

--房间内修改房间模式
function EventChangeRoomType()
	RoomSystem.req_change_room_group_type(BP_STRUCT_RoomWaitingInfo.id, BP_SelectedGroupType);
end

--房间内修改地图
function EventChangeMap()
	RoomSystem.req_change_room_map(BP_STRUCT_RoomWaitingInfo.id, BP_SelectedMapID);
end

--提示只能房主点击切换模式
function EventOnlyRoomMasterCanClick()
	DataMgr.ShowNoticeByID(110098);
end

--提示房主是否解散房间
function EventWhetherDisbandRoom()
	local title_data = Client.GetTableData("LocalizeRes", 101001);
	local title = tostring(title_data.TextValue);
	local msg_data = Client.GetTableData("LocalizeRes", 110099);
	local msg = tostring(msg_data.TextValue);
	CommonMessageBoxUI:ShowPanel(2, title, msg, RoomWaitingUI.OnClickBtnDisbandOK);
end

--打开个人信息
function EventOpenRoleInfo()
	RoleInfoSystem.Enter(BP_Room_SelectedRoleID);
    RoleInfoUI.Init();
end

--修改房间名
function EventChangeRoomName()
	RoomSystem.req_change_room_name(BP_STRUCT_RoomWaitingInfo.id, BP_Room_ChangeName);
end

--生成二维码
function EventCreateQRImage()
	RoomSystem.InviteJoinRoomQQ(BP_STRUCT_RoomWaitingInfo.id, BP_CreateRoom_Passwd);
end

--打开聊天框
function EventOpenRoomWaitingChatUI()
	LobbyChatEntranceUI.SetVisibility(true);
end

--关闭聊天框
function EventCloseRoomWaitingChatUI()
	LobbyChatEntranceUI.SetVisibility(false);
end

--保存本地成功
function EventSaveSuccess()
	DataMgr.ShowNoticeByID(110124);
end

--战斗中不能踢人
function EventKickRoleDisable()
	DataMgr.ShowNoticeByID(110130);
end

--战斗中不能点击按钮
function EventBtnDisableInGaming()
	DataMgr.ShowNoticeByID(110130);
end


















