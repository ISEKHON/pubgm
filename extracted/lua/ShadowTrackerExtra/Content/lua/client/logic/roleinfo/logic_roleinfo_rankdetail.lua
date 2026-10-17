--[[
  个人信息军衔等级的相关逻辑
]]--

RankDetailSystem = RankDetailSystem or
{
	RoleRankDetailSingleList = {};
	RoleRankDetailTypeList = {};
}

function RankDetailSystem.Enter()
	log("RankDetailSystem Enter");
	RankDetailSystem.GetRankDetailData();
end

function RankDetailSystem.Release()
	log("RankDetailSystem Release");
	RankDetailSystem.RoleRankDetailSingleList = {};
	RankDetailSystem.RoleRankDetailTypeList = {};
end

function RankDetailSystem.GetRankDetailData()
	log("RankDetailSystem GetRankDetailData");
	
	RankDetailSystem.RoleRankDetailSingleList = {};
	RankDetailSystem.RoleRankDetailTypeList = {};
	local rank_type = "";
	local index = 1;
	local bExist = false;
	local data = Client.GetTable("MilitaryRankLevel");
	for k,v in pairs(data) do
		if rank_type ~= v.MilitaryRankType then
			for m,n in pairs(RankDetailSystem.RoleRankDetailTypeList) do
				if n.type_name == v.MilitaryRankType then
					bExist = true;
					break;
				end
			end
			if bExist == false then
				rank_type = v.MilitaryRankType;
				RankDetailSystem.RoleRankDetailTypeList[index] =
				{
					type_name = v.MilitaryRankType;
					level = v.Level;
				}
				index = index + 1;
			else
				bExist = false;
			end
		end
		
		RankDetailSystem.RoleRankDetailSingleList[v.Level] =
		{
			level = v.Level,
			name = v.MilitaryRankName,
			type_name = v.MilitaryRankType,
		}
	end
	
	sort_func = function(a,b) return a.level < b.level end;
	table.sort(RankDetailSystem.RoleRankDetailTypeList, sort_func);
	-- log_tree("RankDetailSystem.RoleRankDetailTypeList =", RankDetailSystem.RoleRankDetailTypeList);
	-- log_tree("RankDetailSystem.RoleRankDetailSingleList =", RankDetailSystem.RoleRankDetailSingleList);
end







