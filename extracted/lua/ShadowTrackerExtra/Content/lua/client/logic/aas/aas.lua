AasSystem = AasSystem or {};

function AasSystem.sync_aas_update_user_info(accumTime, healthyGameFlag, forceExitRestTime)
    local debug = {accumTime=accumTime, healthyGameFlag=healthyGameFlag, forceExitRestTime=forceExitRestTime};
	log_tree("sync_aas_update_user_info: debug=", debug);
end

--[[网络回调]]--
s2c["sync_aas_update_user_info"] = AasSystem.sync_aas_update_user_info;
