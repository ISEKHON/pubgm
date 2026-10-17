RoomUI = RoomUI or
{
	IsRegister = false;
}

--注册Widget
function bp_room_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_room,
	{{Path="/Game/UMG/UI_BP/Room/RoomList_BP.RoomList_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ROOM_LIST_ZORDER}},
    {"Lobby"},
	false,
	bp_room_OnModeSwitched ~= nil,
	true
  );

  RoomUI.initGroupTypeList();
  FuncUtil:InitConfigs(); --初始化临时放在这，等有好地方再挪
end

--进入Lobby请求房间界面
function bp_room_OnModeSwitched(gamestatus)
	log("bp_room_OnModeSwitched gamestatus = " .. gamestatus);
	-- RoomUI.IsRegister = true;
	if string.lower(gamestatus) == "lobby" then
		-- if RoomWaitingUI.IsRegister then
			log("bp_room room_info_request");
			NetUtil.SendPkg("room_info_request");
		-- end
	end

	RoomUI.OnQuickJoinRoom(RoomSystem.QRCodeRoomInfo);
end

function bp_room_OnModeAboutToSwitched(gamestatus)
end


--房间信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_RoomInfo =
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
};

--房间信息列表
BP_ARRAY_RoomList =
{
	BP_STRUCT_RoomInfo=_G.BP_STRUCT_RoomInfo, --定义结构体数组，这种写法要作为规范规定下来
};

--创建房间参数列表
BP_CreateRoom_MapID = 0;
BP_CreateRoom_Name = "";
BP_CreateRoom_Passwd = "";
BP_CreateRoom_Mode = 1;

--进入房间参数列表
BP_EnterRoom_ID = "";
BP_EnterRoom_Passwd = "";

--进入房间的方式
BP_EnterRoom_Type = 0;	-- 1-输入ID进入房间 2-点击列表进入房间

--选中的房间ID(列表序列id)
BP_SelectRoomID = 0;

--自己的名字
BP_Room_SelfName = "";

--是否是主播
BP_Room_IsAnchor = false;

--客户端版本号(大版本号)
BP_Room_ClientVersion = "";

--模式信息
BP_STRUCT_GroupType =
{
	Type = 0, --1,2,4
	GroupName = "",
};


--模式列表
BP_ARRAY_GroupTypeList =
{
	BP_STRUCT_GroupType=_G.BP_STRUCT_GroupType,
};

function RoomUI.initGroupTypeList()
	BP_ARRAY_GroupTypeList = {};
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 1, GroupName = "单人模式"});
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 2, GroupName = "双人模式"});
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 4, GroupName = "四人模式"});
	local groupNameString = Client.GetTableData("LocalizeRes", "110049").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 1, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110050").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 2, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110051").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 4, GroupName = groupNameString});
end



local function roomEventHandler(eventType, eventID, vars)
    if eventType ~= EVENTTYPE_ROOM then
      return;
    end

    if eventID == EVENTID_UPDATE_BP_DATA then
      RoomUI:updateBPData();
    end
end


function RoomUI:Init()
	log("RoomUI init");
	LuaClassObj.HandleDynamicCreation(bp_room);

	BP_Room_SelfName = DataMgr.roleData.nickName;
	if DataMgr.anchor == 1 then
		BP_Room_IsAnchor = true;
	else
		BP_Room_IsAnchor = false;
	end
	BP_Room_ClientVersion = FuncUtil:GetClientFormat(Client.GetAppVersion());

	LobbyChatEntranceUI.SetIsRoomMode(true);

	EventSystem:registEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA, roomEventHandler);
end


function RoomUI:Release()
	log("RoomUI release");
	BP_Room_SelfName = "";
	BP_Room_IsAnchor = false;
	BP_Room_ClientVersion = "";

	EventSystem:unregistEvent(EVENTTYPE_ROOM, EVENTID_UPDATE_BP_DATA, roomEventHandler);
end

function RoomUI:updateBPData()
	log("RoomUI updateBPData");
	--更新房间列表
	BP_ARRAY_RoomList = RoomSystem.RoomInfoList;
end

function RoomUI.OnQuickJoinRoom(roominfo)
	if roominfo ~= nil and type(roominfo) == "table" then
		if roominfo.game_roomid ~= nil and roominfo.game_roompw ~= nil then
			log("roomid=" .. roominfo.game_roomid .. " game_roompw=" .. roominfo.game_roompw);
			RoomSystem.Enter();
			RoomUI:Init();
			RoomSystem.req_join_room(tonumber(roominfo.game_roomid), roominfo.game_roompw);
			RoomSystem.QRCodeRoomInfo = nil;
		end
	end
end




--不做任何事，蓝图里调这个函数将把lua变量的值同步给蓝图变量
function EventFetchInfo()
end

function EventRoomRelease()
	RoomSystem.Release();
	RoomUI:Release();
end


--创建房间请求(以Event开头的函数名就能暴露给蓝图调用)
function EventCreateRoom()
	log("create room clicked");

	local hasIllegalChar = false;
	local unitLen = 0;
	BP_CreateRoom_Name = FuncUtil:StrTrim(BP_CreateRoom_Name);
	hasIllegalChar, unitLen = FuncUtil:CheckName(BP_CreateRoom_Name, true, nil, true);

	if hasIllegalChar == true then
		DataMgr.ShowNoticeByID(110083);
		return;
	end

	if unitLen > 20 then
		DataMgr.ShowNoticeByID(110089);
		return;
	end

	RoomSystem.req_create_room(BP_CreateRoom_Name,
		BP_CreateRoom_MapID,
		BP_CreateRoom_Mode,
		BP_CreateRoom_Passwd);
end

function EventCreateRoomCheckNameEmpty()
	DataMgr.ShowNoticeByID(111020);
end

function EventCreateRoomCheckPSWEmpty()
	DataMgr.ShowNoticeByID(110080);
end

--请求房间列表
function EventRequestRoomList()
	RoomSystem.req_room_list();
end

--请求加入房间
function EventRequestJoinRoom()
	log("event_req_room_request " .. BP_SelectRoomID);

	if BP_EnterRoom_Type == 1 then
		RoomSystem.req_join_room(tonumber(BP_EnterRoom_ID), BP_EnterRoom_Passwd);
	elseif BP_EnterRoom_Type == 2 then
		if BP_ARRAY_RoomList[BP_SelectRoomID] ~= nil then
			RoomSystem.req_join_room(BP_ARRAY_RoomList[BP_SelectRoomID].id, BP_EnterRoom_Passwd);
		else
			log("request create room: not found room info");
		end
	else
		log("request create room: enter_room type error");
	end
end

--设置密码
function EventSetPSWOK()
	local psw = BP_CreateRoom_Passwd;
	local pswlen = string.len(BP_CreateRoom_Passwd);

	if type(psw) ~= "string" then
		BP_CreateRoom_Passwd = "";
		return;
	end

	if pswlen <= 0 then
		DataMgr.ShowNoticeByID(110084);
		BP_CreateRoom_Passwd = "";
		return;
	elseif pswlen > 6 then
		DataMgr.ShowNoticeByID(110086);
		BP_CreateRoom_Passwd = "";
		return;
	else
		for i=1,pswlen do
			local curByte = string.byte(psw, i)
			if curByte < 48 or (curByte > 57 and curByte < 65) or (curByte > 90 and curByte < 97) or curByte > 122 then
				DataMgr.ShowNoticeByID(110086);
				BP_CreateRoom_Passwd = "";
				return;
			end
		end
	end
	DataMgr.ShowNoticeByID(110079);
	LuaClassObj.HandleUIMessage(bp_room, "SetPSW");
end

--检查输入ID
function EventCheckInputRoomID()
	local id = BP_EnterRoom_ID;
	local idlen = string.len(BP_EnterRoom_ID);

	if type(id) ~= "string" then
		BP_EnterRoom_ID = "";
		return;
	end

	if idlen <= 0 then
		DataMgr.ShowNoticeByID(110087);
		BP_EnterRoom_ID = "";
		return;
	end

	for i=1,idlen do
		local curByte = string.byte(id, i);
		if curByte < 48 or curByte > 57 then
			DataMgr.ShowNoticeByID(110088);
			return;
		end
	end

	RoomSystem.req_query_one_room(tonumber(id));
	-- LuaClassObj.HandleUIMessage(bp_room, "ShowEnterRoomPSWUI");
end

--进入房间
function EventEnterRoom()
	local psw = BP_EnterRoom_Passwd;
	local pswlen = string.len(BP_EnterRoom_Passwd);

	if type(psw) ~= "string" then
		BP_EnterRoom_Passwd = "";
		return;
	end

	if pswlen <= 0 then
		DataMgr.ShowNoticeByID(110084);
		BP_EnterRoom_Passwd = "";
		return;
	elseif pswlen > 6 then
		DataMgr.ShowNoticeByID(110086);
		BP_EnterRoom_Passwd = "";
		return;
	else
		for i=1,pswlen do
			local curByte = string.byte(psw, i)
			if curByte < 48 or (curByte > 57 and curByte < 65) or (curByte > 90 and curByte < 97) or curByte > 122 then
				DataMgr.ShowNoticeByID(110086);
				BP_EnterRoom_Passwd = "";
				return;
			end
		end
	end

	EventRequestJoinRoom();
end

--提示没有权限无法创建房间
function EventCannotCreateRoom()
	DataMgr.ShowNoticeByID(110082);
end

--进入房间后
function EventAfterEnterRoomList()
	LobbyChatEntranceUI.SetIsRoomMode(true);
end

--离开房间后
function EventAfterLeaveRoomList()
	LobbyChatEntranceUI.SetIsRoomMode(false);
end

--游戏中不能加入房间
function EventEnterGamingRoomNotice()
	DataMgr.ShowNoticeByID(110081);
end

--提示版本不一致
function EventVersionNotMatched()
	DataMgr.ShowMessageBoxByID(110091);
end

--打开聊天框
function EventOpenRoomChatUI()
	LobbyChatEntranceUI.SetVisibility(true);
end

--关闭聊天框
function EventCloseRoomChatUI()
	LobbyChatEntranceUI.SetVisibility(false);
end



function EventUpdateGroupTypeList()
	log("Here")
	BP_ARRAY_RoomGroupTypeList = {};
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 1, GroupName = "单人模式"});
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 2, GroupName = "双人模式"});
	--table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 4, GroupName = "四人模式"});
	local groupNameString = Client.GetTableData("LocalizeRes", "110049").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 1, GroupName = groupNameString});
	log("Here"..groupNameString)
	groupNameString = Client.GetTableData("LocalizeRes", "110050").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 2, GroupName = groupNameString});
	log("Here"..groupNameString)
	groupNameString = Client.GetTableData("LocalizeRes", "110051").TextValue;
	table.insert(BP_ARRAY_RoomGroupTypeList, {Type = 4, GroupName = groupNameString});
	log("Here"..groupNameString)
end

function EventRefreshGroupTypeList()
	BP_ARRAY_GroupTypeList = {};
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 1, GroupName = "单人模式"});
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 2, GroupName = "双人模式"});
	--table.insert(BP_ARRAY_GroupTypeList, {Type = 4, GroupName = "四人模式"});
	local groupNameString = Client.GetTableData("LocalizeRes", "110049").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 1, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110050").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 2, GroupName = groupNameString});
	groupNameString = Client.GetTableData("LocalizeRes", "110051").TextValue;
	table.insert(BP_ARRAY_GroupTypeList, {Type = 4, GroupName = groupNameString});
end
