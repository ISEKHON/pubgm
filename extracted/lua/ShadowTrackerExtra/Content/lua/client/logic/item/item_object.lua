INVALID_ITEM_ID = -1;

ItemObject = 
{
	InstID = INVALID_ITEM_ID;
	Desc = nil;
}

function ItemObject:new(_itemObj)
	_itemObj = _itemObj or {};
	setmetatable(_itemObj, self);
	self.__index = self;
	return _itemObj;
end

function ItemObject:realse()
	self.Desc = nil;
end






