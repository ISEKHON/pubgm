ItemSystem = ItemSystem or {
	ItemList = {
	};
}


function ItemSystem:on_init_login(_itemList)

	self.ItemList = {};
	
	if _itemList == nil then
		return;
	end
	
	for _index = 1, #_itemList do
		local _item = ItemObject:new();
		_item.InstID = _itemList[_index].InstID;
		_item.Desc = Item_Res_Desc[_itemList[_index].resID];
		self.ItemList[_item.InstID] = _item;
	end
	
end

function ItemSystem:AddItem(_itemInfo)
	local _item = ItemObject:new();
	_item.InstID = _itemInfo.InstID;
	_item.Desc = Item_Res_Desc[_itemInfo[_index].ID];
	self.ItemList[_item.InstID] = _item;
end

function ItemSystem:DelItem(_itemInstID)
	local _item  = self.ItemList[_itemInstID];
	if _item ~= nil then
		_item:release();
		self.ItemList[_itemInstID] = nil;
	end
end

function ItemSystem.on_add_item(_itemInfo)
	if _itemInfo == nil then
		return;
	end
	
	ItemSystem:AddItem(_itemInfo);
end

function ItemSystem.on_del_item(_iteminstID)
	if _iteminstID == INVALID_ITEM_ID then
		return;
	end
	ItemSystem:DelItem(_iteminstID);
end


s2c["on_add_item"] = ItemSystem.on_add_item;
s2c["on_del_item"] = ItemSystem.on_del_item;
















