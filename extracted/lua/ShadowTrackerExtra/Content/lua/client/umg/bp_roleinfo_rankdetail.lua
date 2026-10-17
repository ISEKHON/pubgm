--个人信息军衔等级UI
RankDetailUI = RankDetailUI or
{
}

BP_ItemMax = 0;




--单条军衔详情信息(定义结构体：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_RoleRankDetailSingleInfo =
{
	level = 0,
	name = "",
	type_name = "",
}

--同类型军衔详情信息
BP_STRUCT_RoleRankDetailTypeInfo =
{
	type_name = "",
	level = 0,			--用于排序
}

--单条军衔详情信息列表(定义结构体数组：当且仅当以BP_ARRAY_开头的table能作为数组给蓝图访问)
BP_ARRAY_RoleRankDetailSingleList =
{
	BP_STRUCT_RoleRankDetailSingleInfo = _G.BP_STRUCT_RoleRankDetailSingleInfo;
}

--同类型军衔详情信息列表
BP_ARRAY_RoleRankDetailTypeList =
{
	BP_STRUCT_RoleRankDetailTypeInfo = _G.BP_STRUCT_RoleRankDetailTypeInfo;
}



--注册Widget
function bp_roleinfo_rankdetail_RegisterUI()
	LuaClassObj.SubUIWidgetList(bp_roleinfo_rankdetail,
		{{Path="/Game/UMG/UI_Logic/RoleInfo/RoleInfo_RankDetail_BP.RoleInfo_RankDetail_BP_C", Container="Default", ZOrder=BP_ENUM_UI_ROLEINFO_ZORDER+1}},
		{"Lobby"},
		false,
		false,
		true
	);
end

function RankDetailUI.Init()
	log("RankDetailUI Init");
	BP_ItemMax = 0;
	
	RankDetailUI.UnifyAllData();
	RankDetailUI.UpdateRankDetail()
end

function RankDetailUI.Release()
	log("RankDetailUI Release");
	BP_ItemMax = 0;
end

function RankDetailUI.UnifyAllData()
	log("RankDetailUI UnifyAllData");
	
	for k,v in pairs(RankDetailSystem.RoleRankDetailSingleList) do
		BP_ARRAY_RoleRankDetailSingleList[k] = FuncUtil:CopyTable(v);
	end
	
	for k,v in pairs(RankDetailSystem.RoleRankDetailTypeList) do
		BP_ARRAY_RoleRankDetailTypeList[k] = FuncUtil:CopyTable(v);
	end
	
	BP_ItemMax = #BP_ARRAY_RoleRankDetailTypeList;
	
	-- log_tree("BP_ARRAY_RoleRankDetailSingleList =", BP_ARRAY_RoleRankDetailSingleList);
	-- log_tree("BP_ARRAY_RoleRankDetailTypeList =", BP_ARRAY_RoleRankDetailTypeList);
	-- log("BP_ItemMax: "..BP_ItemMax);
end

function RankDetailUI.UpdateRankDetail()
	LuaClassObj.HandleDynamicCreation(bp_roleinfo_rankdetail);
	log("RankDetailUI UpdateRankDetail");
	LuaClassObj.HandleUIMessage(bp_roleinfo_rankdetail, "UIShow");
	LuaClassObj.HandleUIMessage(bp_roleinfo_rankdetail, "UpdateRankDetail");
end




--(以Event开头的函数名就能暴露给蓝图调用)

function EventRankDetailRelease()
	log("EventRankDetailRelease");
	RankDetailUI.Release();
	RankDetailSystem.Release();
end





