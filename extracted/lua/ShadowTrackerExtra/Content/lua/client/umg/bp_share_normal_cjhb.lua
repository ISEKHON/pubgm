ShareNromalCJHBUI = {}

--红包类型(1,普通红包;2,黑金红包)
BP_CJHB_REDPACKTYPE = 0;
--总红包剩余金额
BP_CJHB_LEFT_MONEY = 0;
--总红包金额
BP_CJHB_TOTAL_MONEY = 0;
--自己获得红包金额
BP_CJHB_REDPACKMONEY = 0;

function bp_share_normal_cjhb_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_share_normal_cjhb,
		{				
			{Path="/Game/UMG/UI_Logic/Share/Share_Normal_CJ_LogicBP.Share_Normal_CJ_LogicBP_C", Container="Top", ZOrder=BP_ENUM_UI_SHare_normal_cjhb_ZORDER},
		},
		{"Fighting","Lobby"},
		false,
		false
	);
end

--[[
	显示红包UI
	@redPackType:红包类型(1,普通红包;2,黑金红包)
	@leftMoney:剩余金额
	@totalMoney:总金额
--]]
function ShareNromalCJHBUI.Show(redPackType, leftMoney, totalMoney)
	BP_CJHB_REDPACKTYPE = redPackType or 0;
	BP_CJHB_LEFT_MONEY = leftMoney or 0;
	BP_CJHB_TOTAL_MONEY = totalMoney or 0;
	if BP_CJHB_REDPACKTYPE > 0 then
		log("ShareNromalCJHBUI.Show : redPackType is " .. BP_CJHB_REDPACKTYPE)
		log("ShareNromalCJHBUI.Show : left money is " .. BP_CJHB_LEFT_MONEY)
		log("ShareNromalCJHBUI.Show : total Money is " .. BP_CJHB_TOTAL_MONEY)
		LuaClassObj.HandleUIMessage(bp_share_normal_cjhb, "ShowUI");
	else
		log("ShareNromalCJHBUI.Show : no hongbao!")
	end
end

--红包分享
function EventBtnCJHongbaoShared()
	RedPacketSystem.StartShareHongbao();
end

function ShareNromalCJHBUI.OnRecevieCJHongbaoSuccess(money, data)
	BP_CJHB_REDPACKMONEY = money or 0;
	LuaClassObj.HandleUIMessage(bp_share_normal_cjhb, "HongbaoRecevieSuccess");
end