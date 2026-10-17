
LogicComplaint = LogicComplaint or {}

function LogicComplaint:Submit(BeComplaintName, IsAI, StrOpenID, StrRoleID, ReportCamp, tSelectType, Text, RankType, Numbers)
	
	if tSelectType == nil then
		log("LogicComplaint Submit tSelectType == nil");
		return
	end
	log("LogicComplaint Submit g_game_id:"..g_game_id..", BeComplaintName:"..BeComplaintName..", RoleID:"..tonumber(StrRoleID)..", OpenID:"..StrOpenID..", ReportCamp:"..ReportCamp..", type1:"..tSelectType.type1..", type2:"..tSelectType.type2..", type3:"..tSelectType.type3..", Text:"..Text..", RankType:"..RankType..", Numbers:"..Numbers);
	-- local tSelectType = {
	-- 	type1 = Complaint_Type1,
	-- 	type2 = Complaint_Type2,
	-- 	type3 = Complaint_Type3,
	-- }
	-- tSelectType内容为type1, type2 type3 没有则是0
	local ReasonTypeSum = 0
	if tSelectType.type1 then
		ReasonTypeSum = ReasonTypeSum + tSelectType.type1
	end
	if tSelectType.type2 then
		ReasonTypeSum = ReasonTypeSum + tSelectType.type2
	end
	if tSelectType.type3 then
		ReasonTypeSum = ReasonTypeSum + tSelectType.type3
	end

	local securityLog = {
		ReportID = 0, --日志ID
		BattleID = g_game_id, -- 本局ID
		UserName = BeComplaintName,-- 被举报者名称
		IsAI = IsAI,
		ReportOpenID = StrOpenID,--举报者OpenID
		ReportRoleID = tonumber(StrRoleID),--举报者角色ID
		ReportCamp = ReportCamp,--被举报者阵营 1队友 2敌人
		
		ComplaintType = ReasonTypeSum,--1 挂机，2 言语辱骂，4 使用外挂，8 恶意利用bug，16 消极游戏，32 其它; 值为三个类型的和

		ComplaintType2 = 1,--举报地方 1战斗 2大厅聊天
		ComplaintContents = Text,--举报内容

		RankType = RankType,--举报模式 1单排 2双排 4四排
		BattlePlayerNumber = Numbers,--本局玩家数量
	}
	NetUtil.SendPkg("report_info", securityLog);
end
