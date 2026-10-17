--[[
	事件系统
]]--
EventSystem =
{
	mapEvents = {},
};

function EventSystem:postEvent(eventType, eventID, vars)
	local listEventID = self.mapEvents[eventType];
	if (nil == listEventID) then
		return false;
	end

	local listProcessor = listEventID[eventID];
	if (nil == listProcessor) then
		return false;
	end
	
	local listNeedRemove = {};
	
	for k, v in pairs(listProcessor) do
		if (v and type(v) == "function") then
			local bNeedRemove = v(eventType, eventID, vars);
			if (bNeedRemove) then
				table.insert(listNeedRemove, v);
			end
		end
	end

	local function findProcIdx(fnProc)
		for k, v in pairs(listProcessor) do
			if (v == fnProc) then
				return k;
			end
		end
		return 0;
	end

	for i = 1, #listNeedRemove do
		local iRemoveIdx = findProcIdx(listNeedRemove[i]);
		if (iRemoveIdx ~= 0) then
			table.remove(listProcessor, iRemoveIdx);
		end
	end
end

function EventSystem:registEvent(eventType, eventID, fnProcessor)
	if eventType == nil then
		log("EventSystem:registEvent Error: eventType is nil");
	end
	if eventID == nil then
		log("EventSystem:registEvent Error: eventID is nil");
	end
	if fnProcessor == nil then
		log("EventSystem:registEvent Error: fnProcessor is nil");
	end
  
	local listEventID = self.mapEvents[eventType];
	if (nil == listEventID) then
		self.mapEvents[eventType] = {};
		listEventID = self.mapEvents[eventType];
	end
	local listProcessor = listEventID[eventID];
	if (nil == listProcessor) then
		listEventID[eventID] = {};
		listProcessor = listEventID[eventID];
	end
    
	for k, v in pairs(listProcessor) do
		if (v == fnProcessor) then
			return false;
		end    
	end
	table.insert(listProcessor, fnProcessor);
    
	return true;
end

function EventSystem:unregistEvent(eventType, eventID, fnProcessor)
	local listEventID = self.mapEvents[eventType];
	if (nil == listEventID) then
		return false;
	end

	local listProcessor = listEventID[eventID];
	if (nil == listProcessor) then
		return false;
	end

	for k, v  in pairs(listProcessor) do
		if (v == fnProcessor) then
			--table.remove(listProcessor, k);
            listProcessor[k] = nil
			return true;
		end
	end

	return false;
end






