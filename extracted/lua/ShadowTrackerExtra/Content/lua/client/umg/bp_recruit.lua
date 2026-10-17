--[[
	组队招募 2017-12-12
--]]

 RecruitUI = RecruitUI or {

}

--UI是否打开
BP_IsUIShow = false;

--世界招募
BP_WorldRecruit = true;

--好友招募
BP_FrientRecruit = true;

--频道招募
BP_ChannelRecruit = true;

--模式字符串
BP_ModelStr = "";

--队伍人数字符串1/2
BP_ModelPLayCountStr = "";

--文字信息
BP_SendMessage = "";

BP_ChatannelRoomID = 0;
BP_ChannelName = "";


--自己的UID
MySelfUID = "";

--是否满员
IsFull = false;

function bp_recruit_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_recruit,
		{
			{Path="/Game/UMG/UI_Logic/Recruit/RecruitLogic_BP.RecruitLogic_BP_C", Container="Default", ZOrder=BP_ENUM_UI_RECRUIT_ZORDER},
		},
		{"Lobby"},
		false,
		false,
		true
		--bp_recruit_OnModeSwitched ~= nil
	);
end	

--初始化
function RecruitUI.InitData()
	--取队伍信息，初始化 TeamUpSystem.TeamInfo
	local curPlayer = TeamUpSystem.TeamInfo.player_count;
	IsFull = false;
	local switch = 
	{
		[TEAMUP_TEAM_TYPE_SOLO] = function()		
			--BP_ModelStr = "四人模式";
			BP_ModelStr = Client.GetTableData("LocalizeRes", "110051").TextValue;
			BP_ModelPLayCountStr = tostring(curPlayer).."/4";
			IsFull = (curPlayer >= 4) or false;
		end,
		[TEAMUP_TEAM_TYPE_DOUBLE] = function()
			--BP_ModelStr = "四人模式";
			BP_ModelStr = Client.GetTableData("LocalizeRes", "110051").TextValue;
			BP_ModelPLayCountStr = tostring(curPlayer).."/4";
			IsFull = (curPlayer >= 4) or false;
		end,
		[TEAMUP_TEAM_TYPE_QUAD] = function()
			--BP_ModelStr = "四人模式";
			BP_ModelStr = Client.GetTableData("LocalizeRes", "110051").TextValue;
			BP_ModelPLayCountStr = tostring(curPlayer).."/4";
			IsFull = (curPlayer >= 4) or false;
		end,
		[1] = function()
			--Default	
			BP_ModelStr = "";
			BP_ModelPLayCountStr = "";		
		end,		
	}	
	local exculSwitch = switch[TeamUp_Team_Type];	
	if exculSwitch then
		exculSwitch();
	else
		switch[1]();
	end		
	MySelfUID = TeamUp_My_User_ID;	

	BP_ChatannelRoomID = BP_ChatRoom_MyRoomID;
	if tonumber(BP_ChatannelRoomID) > 0 then
		BP_ChannelName = tostring(BP_ChatRoom_MyRoomName);
	else
		BP_ChannelRecruit = false;
		BP_ChannelName = DataMgr.GetMsgByID(110018); -- "暂未进入聊天室";		
	end
	
end



--显示UI
function RecruitUI.ShowUI()
	LuaClassObj.HandleDynamicCreation(bp_recruit);
	local isroom = RoomWaitingUI.IsInRoom();
	if isroom == true then
		--DataMgr.ShowNoticeByString("房间中不能招募队员");
		DataMgr.ShowNoticeByString(Client.GetTableData("LocalizeRes", "301294").TextValue);
		return;
	end

	--TODO,组合数据
	RecruitUI.InitData();
	if TeamUp_Team_Type == TEAMUP_TEAM_TYPE_SOLO then
		--DataMgr.ShowNoticeByString("单人模式下不能招募队员");
		--DataMgr.ShowNoticeByID(110041);
		--return;
	end
	
	if IsFull == true then
		--DataMgr.ShowNoticeByString("您的队伍已满");
		DataMgr.ShowNoticeByID(110019);
		return;
	end
	
	BP_SendMessage = DataMgr.GetMsgByID(110040);--"车队发车，速来加入!";
	
	--蓝图层显示UI
	BP_IsUIShow = true;
	LuaClassObj.HandleUIMessage(bp_recruit, "UIShow");
end

function EventRecruit_Push()
	--蓝图变量同步给lua
end

function EventFetchInfo()
	--lua变量同步蓝图
end


--关闭UI
function EventHideUI()
	BP_IsUIShow = false;
end

--发送
function EventSendMessage()
	
	if BP_WorldRecruit == false and BP_ChannelRecruit == false then
		--至少选择一个招募对象	
		DataMgr.ShowNoticeByID(110043);
		return;
	end		
	-- send_world  世界招募  true or false
	-- send_friend  好友招募 true or false
	-- send_channel  频道招募  true or false
	--local contact = "["..BP_ModelStr.."][人数"..BP_ModelPLayCountStr.."]"..BP_SendMessage;
	local str = Client.GetTableData("LocalizeRes", "301170").TextValue;
	local contact = "【"..BP_ModelStr.."】【"..str..BP_ModelPLayCountStr.."】"..BP_SendMessage;
	log("EventSendMessage:"..tostring(contact)..tostring(BP_WorldRecruit)..tostring(BP_ChannelRecruit));
	TeamUpSystem.team_recruit(contact,BP_WorldRecruit,BP_FrientRecruit,BP_ChannelRecruit);
	LuaClassObj.HandleUIMessage(bp_recruit, "UIHide");
end