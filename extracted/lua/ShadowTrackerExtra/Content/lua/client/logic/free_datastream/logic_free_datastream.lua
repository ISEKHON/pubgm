-- 大王卡，和免流量逻辑部分
local BASE_FREE_DATA_URL = "http://chong.qq.com/mobile/special_traffic/pg.shtml?"
local FREE_DATA_CHANNEL = "1248_CiJiZhanChangApp"

FreeDataStreamMgr = FreeDataStreamMgr or {
    isFreeState = false
} 

function FreeDataStreamMgr:ClearFreeDataStatus()
    log("FreeDataStreamMgr ")
    self.isFreeState = false
    LobbyUI:UpdateFreeDataState()
end

function FreeDataStreamMgr:OpenFreeDataUrl()
    -- https://chong.qq.com/mobile/special_traffic_king.shtml?OutUid=owanlsoHC2t-KkpJFqaI7O_bNDhw&OutUidType=1&Token=0fc6f86e42b0dfaf4c224aaafceca0b3&Timestamp=63649912937&AccessToken=&Channel=1100_WzryApp&from=singlemessage&isappinstalled=0
    -- 取token
    local svrTime = FuncUtil.GetServerTimeInSec()
    local accessToken = Client.GetAccessToken(NetInterface) 

    local finalUrl = string.format("%sOutUid=%s&OutUidType=%d&Timestamp=%d&Channel=%s&AccessToken=%s",BASE_FREE_DATA_URL, DataMgr.roleData.openID, _G.BP_Platform, svrTime, FREE_DATA_CHANNEL, accessToken)
    log("free data url = " .. finalUrl)
    Client.OpenURL(finalUrl) 
end

function FreeDataStreamMgr:SendGetFreeDatastreamState()
    NetUtil.SendPkg("get_free_flow_req") 
end

function FreeDataStreamMgr.on_get_free_datastream_state(res, free_flowc)
    log("free data get result = " .. res)
    log_tree("free data state = " ,free_flowc )

    if res == "ok" then
        FreeDataStreamMgr.isFreeState = (free_flowc.isfree == 1)
    end

    log("IsFreeState = " .. tostring(FreeDataStreamMgr.isFreeState))
    LobbyUI:UpdateFreeDataState() 
end

--[[
    网络回调
]]--
s2c["get_free_flow_rsp"] = FreeDataStreamMgr.on_get_free_datastream_state