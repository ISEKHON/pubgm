_G.PacketCallbacks = PacketCallbacks or {};

PacketCallbacks.sync_game_param = function(params)
    sandbox.LogNormal(string.format("sync_game_param received"));
    log_tree("params", params);

    _G.GameID = params.game_id;

    local info = 
    { 
        GameID = params.game_id,
        DefaultTimeout = params.time_out, 
        ListeningPort = params.port, 
        bEnableClimbing = params.climb_switch 
    }
    Server.SyncGameInfo(DSUtils, info);

    local modeName = BP_ARRAY_BTMode[params.mode_id].GameModeName;
    local mapPath = BP_ARRAY_Map[params.map_id].MapPath;
    local url = mapPath;
    if string.len(modeName) > 0 then
        url = url .. '?game=' .. modeName;
    end
    url = url .. '?mapid=' .. params.map_id;

    sandbox.LogNormal(string.format("sync_game_param received TravelURL=%s", url));

    Server.Travel(url, params.port, params.encrypt_key, params.game_id);
end

PacketCallbacks.sync_player_info = function(uid, info)
    sandbox.LogNormal(string.format("sync_player_info received, uid=[%d] name=[%s]", uid, info.name));
    log_tree("info", info);

    local infoToDS = {};
    infoToDS.PlayerName = info.name;
    infoToDS.bIsGM = info.gm;
    infoToDS.TeamID = info.teamid;
    infoToDS.Gender = info.gender;
    infoToDS.bReconnect = false;
	infoToDS.DestinyValue = info.destiny;
	infoToDS.WarmScore = info.warm_score;

    if info.is_robot ~= nil then
        infoToDS.bAIPlayer = info.is_robot;
    end

    local itemList = {};
    for i, v in pairs(info.wear) do
        local item = { ItemTableID = v, Count = 1 };
        table.insert(itemList, item);
    end
    infoToDS.ItemList = itemList;

    local key = Server.SyncNewDSPlayer(DSUtils, uid, infoToDS);
    NetUtil.SendPacket(MsgToLobby.sync_login_key, uid, key);
end

PacketCallbacks.try_reconnect = function(uid)
    sandbox.LogNormal(string.format("try_reconnect received, uid=[%d]", uid));

    local infoToDS = { bReconnect = true };
    local key = Server.SyncNewDSPlayer(DSUtils, uid, infoToDS);
    NetUtil.SendPacket(MsgToLobby.try_reconnect_rsp, uid, key);
end

PacketCallbacks.player_exit = function(uid, reason)
    sandbox.LogNormal(string.format("player_exit received, uid=[%d] reason=[%s]", uid, reason));

    Server.SyncDSPlayerExit(DSUtils, uid);
end

PacketCallbacks.game_exit = function()
    sandbox.LogNormal("game_exit received");

    Server.SyncGameExit();
    Server.ShutdownProcess();
end



sandbox.LogNormal("PacketCallbacks.lua imported");
