_G.GameplayCallbacks = GameplayCallbacks or {};

local PlayerState = {};
PlayerState.PreLogin = "PreLogin";
PlayerState.Login = "Login";
PlayerState.Online = "Online";
PlayerState.Logout = "Logout";
PlayerState.ConnectionLost = "ConnectionLost";
PlayerState.ConnectionTimeout = "ConnectionTimeout";

local MatchState = {};
MatchState.WaitingToStart = "WaitingToStart";
MatchState.InProgress = "InProgress";



function GameplayCallbacks.OnPostLoadMap()
	sandbox.LogNormal(string.format("OnPostLoadMap"));

	NetUtil.SendPacket(MsgToLobby.load_player_info);
end 

function GameplayCallbacks.OnPlayerStateChanged(UID, InPlayerState)
	sandbox.LogNormal(string.format("OnPlayerStateChanged UID=[%d] PlayerState=[%s]", UID, InPlayerState));

	if string.lower(InPlayerState) == "cheatdetected" then
		NetUtil.SendPacket(MsgToLobby.report_unrealnet_exception, GameID, UID, "CheatDetected", "");
	end

	local reason = "";
	if string.lower(InPlayerState) == "logout" then
		reason = "exit";
	elseif string.lower(InPlayerState) == "connectionexception" or string.lower(InPlayerState) == "cheatdetected" then
		reason = "lost";
	elseif string.lower(InPlayerState) == "connectiontimeout" then
		reason = "timeout";
	end

	if string.len(reason) > 0 then
		sandbox.LogNormal(string.format("send player_exit UID=[%d] reason=[%s]", UID, reason));
		NetUtil.SendPacket(MsgToLobby.player_exit, UID, reason);
	end
end

function GameplayCallbacks.OnCharacterStateChanged(UID, InCharacterState)
	sandbox.LogNormal(string.format("OnCharacterStateChanged UID=[%d] CharacterState=[%s]", UID, InCharacterState));

	-- TODO

end

function GameplayCallbacks.OnGameModeStateChanged(InGameModeState)
	sandbox.LogNormal(string.format("OnGameModeStateChanged GameModeState=[%s]", InGameModeState));

	-- TODO

end

function GameplayCallbacks.PlayerNetConnectionClosed(GameID, UID, Reason, ErrorMessage)
	sandbox.LogNormal(string.format("PlayerNetConnectionClosed GameID=[%d] UID=[%d] Reason=[%s] ErrorMessage=[%s]", GameID, UID, Reason, ErrorMessage));

	NetUtil.SendPacket(MsgToLobby.report_unrealnet_exception, GameID, UID, Reason, ErrorMessage);
end



function GameplayCallbacks.SendGameOver()
	sandbox.LogNormal(string.format("SendGameOver"));
	local WeaponReport = Server.GetWeaponReport(DSUtils);
	
    log_tree("WeaponReport", WeaponReport);
    NetUtil.SendPacket("ReportHitFlow", WeaponReport);
    
	NetUtil.SendPacket("game_over");
end

function GameplayCallbacks.SendPlayerBattleResult(UID)
	sandbox.LogNormal(string.format("SendPlayerBattleResult UID=[%d]", UID));

	local result = Server.GetPlayerBattleResultData(DSUtils, UID);
	log_tree("PlayerBattleResult", result);

	NetUtil.SendPacket("game_result", UID, result);
end

function GameplayCallbacks.SendTeamBattleResult(TeamID)
	sandbox.LogNormal(string.format("SendTeamBattleResult TeamID=[%d]", TeamID));

	local UIDList = Server.GetUIDListByTeamID(DSUtils, TeamID);
	log_tree("UIDList", UIDList);

	local result = Server.GetTeamBattleResultData(DSUtils, TeamID);
	log_tree("TeamBattleResult", result);

	NetUtil.SendPacket("game_team_result", TeamID, UIDList, result);
end

function GameplayCallbacks.SendGameStopJoin()
	sandbox.LogNormal(string.format("SendGameStopJoin"));
	NetUtil.SendPacket("game_stop_join");
end

function GameplayCallbacks.SendGameStart()
	sandbox.LogNormal(string.format("SendGameStart"));
	NetUtil.SendPacket("game_start");
end

function GameplayCallbacks.SendHeartBeat(PlayerNum, RealAiNum)
	--sandbox.LogNormal(string.format("SendHeartBeat"));
	NetUtil.SendPacket("heartbeat", PlayerNum, RealAiNum);
end



-- 安全日志相关 start

function GameplayCallbacks.ReportGameStartFlow()
	local securyLog = Server.GetGameStartFlowCache(DSUtils);
	--log_tree("ReportGameStartFlow", securyLog);
	NetUtil.SendPacket("ReportGameStartFlow", securyLog);
end

function GameplayCallbacks.ReportCircleFlow()
	local securyLog = Server.GetCircleFlowCache(DSUtils);
	--log_tree("ReportCircleFlow", securyLog);
	NetUtil.SendPacket("ReportCircleFlow", securyLog);
end

function GameplayCallbacks.ReportGameEndFlow()
	local securyLog = Server.GetGameEndFlowCache(DSUtils);
	--log_tree("ReportGameEndFlow", securyLog);
	NetUtil.SendPacket("ReportGameEndFlow", securyLog);
end

function GameplayCallbacks.ReportAimFlow()
	local securyLog = Server.GetAimFlowCache(DSUtils);
	--log_tree("ReportAimFlow", securyLog);
	NetUtil.SendPacket("ReportAimFlow", securyLog);
end

function GameplayCallbacks.ReportAttackFlow()
	local securyLog = Server.GetAttackFlowCache(DSUtils);
	--log_tree("ReportAttackFlow", securyLog);
	NetUtil.SendPacket("ReportAttackFlow", securyLog);
end

function GameplayCallbacks.ReportHurtFlow()
	local securyLog = Server.GetHurtFlowCache(DSUtils);
	--log_tree("ReportHurtFlow", securyLog);
	NetUtil.SendPacket("ReportHurtFlow", securyLog);
end

function GameplayCallbacks.ReportCommonInfo(uid, tableName, content)
	sandbox.LogNormal(string.format("ReportCommonInfo, uid:%d tableName:%s, content:%s", uid, tableName, content));
	NetUtil.SendPacket("report_common_info", tableName, uid, content);
end

-- 安全日志相关 end

sandbox.LogNormal("GameplayCallbacks.lua imported");
