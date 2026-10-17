_G.MsgToLobby = MsgToLobby or {};
MsgToLobby.start_notify = "start_notify";
MsgToLobby.load_player_info = "load_player_info";
MsgToLobby.sync_login_key = "sync_login_key";
MsgToLobby.try_reconnect_rsp= "try_reconnect_rsp";
MsgToLobby.player_exit = "player_exit";
MsgToLobby.game_over = "game_over";
MsgToLobby.report_unrealnet_exception= "report_unrealnet_exception";



-- make tables exported from C++ easy to use
_G.Net = _G.ScriptHelperNetInterface;
_G.Server = _G.ScriptHelperServer;



_G.NetUtil = NetUtil or {};
_G.GameID = GameID or 0;

-- send packet via NetInterface 
NetUtil.SendPacket = function(Msg, ...)
	if not Msg then
		sandbox.LogError("SendPacket: nil msg");
		return;
	end

	Net.SendPacket(LuaStateWrapper, NetInterface, Msg, ...);
end

-- dispatch packet to corresponding callbacks
NetUtil.DispatchPacket = function(Msg, ...)
	local proc = PacketCallbacks[Msg];
	if not proc then
		sandbox.LogError(string.format("DispatchPacket: undefined msg: %s", Msg));
		return;
	end

	local ok, err = pcall(proc, ...);
	if not ok then
		sandbox.LogError(string.format("DispatchPacket: failed to call %s, error %s", Msg, err));
	end
end

NetUtil.OnConnected = function(bSuccessful, Reason)
	if bSuccessful then
		sandbox.LogNormal("Connection OK");

		local pid = Server.GetProcessID();
		NetUtil.SendPacket(MsgToLobby.start_notify, pid);
	else
		sandbox.LogError(string.format("Connection Failed Reason=%s", ErrorMessage));
	end
end

NetUtil.OnError = function(ErrorMessage)
	sandbox.LogError(string.format("OnError %s", ErrorMessage));
end

NetUtil.OnDisconnected = function(Reason)
	sandbox.LogNormal(string.format("OnDisconnected Reason=%d", Reason));
end



sandbox.LogNormal("Server.lua imported");
