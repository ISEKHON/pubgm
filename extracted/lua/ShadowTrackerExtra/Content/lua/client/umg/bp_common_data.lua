--commonItemdata：当且仅当以BP_STRUCT_开头的table能作为结构体给蓝图访问)
BP_STRUCT_CommonItemData =
{
	ins_id = "",
	res_id = 0,
	count = 0,
    quality = 0,
    isNew = false,
    isSelected = false,
    isUsing = false,
    isSourceBook = false,
	
	hasLock = false,
	hasLimitTime = false,
	needShowName = false,
	itemName = "",
	limitTimeStr = "",
    index = 0,
};

BP_ARRAY_CommonItemData = 
{
	BP_STRUCT_CommonItemData = _G.BP_STRUCT_CommonItemData, --定义结构体数组，这种写法要作为规范规定下来
};

function bp_common_data_RegisterUI()
	
end
