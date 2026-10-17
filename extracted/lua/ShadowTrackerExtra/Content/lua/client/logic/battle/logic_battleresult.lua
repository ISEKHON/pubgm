
BattleResult = BattleResult or {}

function BattleResult.on_game_result(uid, result)
	--
	log_tree("on_game_result_uid", uid);
	log_tree("on_game_result", result);
	
	--BattleResultUI.OnBattleResult(uid, result);

	-- 春节红包
	if uid.battle_gid_newyear ~= nil and uid.battle_gid_newyear ~= 0 then
		RedPacketSystem.ResetShareUrl();
		BattleResult.battleNewyearGID = uid.battle_gid_newyear;
		--local IsCjhbInTime = RedPacketSystem.IsActivityInTime( ActivityType.SPRING_REDPACKET );
		--if IsCjhbInTime then
		local leftTime = 2;
		if uid.newyear_maxnum ~= nil and  uid.newyear_getnum ~= nil then
			leftTime = uid.newyear_maxnum - uid.newyear_getnum - 1 ;
		end
		ShareCJHBUI.SetRoomId(uid.battle_gid_newyear, leftTime);
		LuaClassObj.HandleUIMessage(bp_share_cjhb, "ShowUI");
		--end
	end

	--吃鸡红包
	if uid.battle_gid ~= nil and uid.battle_gid ~= 0 then
		BattleResult.battleGID = uid.battle_gid;
		log("on_test_game_result roomid = "..uid.battle_gid);
		local leftMoney = 0;
		local totalMoney = 0;
		if uid.redpacktype == 2 then
			--黑金
			leftMoney = uid.cj_redpack_remainnum;
			totalMoney = uid.cj_redpack_allnum;
		elseif uid.redpacktype == 1 then
			--普通
			leftMoney = uid.cj_n_redpack_remainnum;
			totalMoney = uid.cj_redpack_allnum_normal;
		end
		ShareNromalCJHBUI.Show(uid.redpacktype,  leftMoney, totalMoney);
	end

	BattleResultUI.OnBattleResult(0, uid);
	
	FriendSystem.getRecentTeammate()
end

function BattleResult.SendTestGetResult()
	log("SendTestGetResult")
	NetUtil.SendPkg("test_gameresult_req");
end

function BattleResult.on_test_game_result(result_gs)
	log("on_test_game_result")
	log_tree("on_test_game_result = ", result_gs);

	-- 春节红包
	if result_gs.battle_gid_newyear ~= nil and result_gs.battle_gid_newyear ~= 0 then
		RedPacketSystem.ResetShareUrl();
		BattleResult.battleNewyearGID = result_gs.battle_gid_newyear;
		--local IsCjhbInTime = RedPacketSystem.IsActivityInTime( ActivityType.SPRING_REDPACKET );
		--if IsCjhbInTime then
		local leftTime = 2;
		if result_gs.newyear_maxnum ~= nil and result_gs.newyear_getnum ~= nil then
			leftTime = result_gs.newyear_maxnum - result_gs.newyear_getnum - 1 ;
		end
		ShareCJHBUI.SetRoomId(result_gs.battle_gid_newyear, leftTime);
		LuaClassObj.HandleUIMessage(bp_share_cjhb, "ShowUI");
		--end
	end
	--吃鸡红包
	if result_gs.battle_gid ~= nil and result_gs.battle_gid ~= 0 then
		BattleResult.battleGID = result_gs.battle_gid;
		log("on_test_game_result roomid = "..result_gs.battle_gid);
		local leftMoney = 0;
		local totalMoney = 0;
		if result_gs.redpacktype == 2 then
			--黑金
			leftMoney = result_gs.cj_redpack_remainnum;
			totalMoney = result_gs.cj_redpack_allnum;
		elseif result_gs.redpacktype == 1 then
			--普通
			leftMoney = result_gs.cj_n_redpack_remainnum;
			totalMoney = result_gs.cj_redpack_allnum_normal;
		end
		ShareNromalCJHBUI.Show(result_gs.redpacktype,  leftMoney, totalMoney);
	end

end

--[[网络回调]]--
s2c["game_result"] = BattleResult.on_game_result;
s2c["test_gameresult_res"] = BattleResult.on_test_game_result;
