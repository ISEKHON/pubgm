Timer = Timer or {}

Timer._list = {}
Timer.CurrentTime = 0
function Timer.InsertTimer(timeOffset, callfunc, loop)
	-- insert time in order list
	local i = 1
	local j = #Timer._list
	local timePoint = Timer.CurrentTime + timeOffset
	while j >= i do
		local mid = math.ceil((j - i)/2) + i
		if Timer._list[mid].timePoint > timePoint then
			j = mid - 1
		else
			i = mid + 1
		end
	end
	local timer = {timePoint = timePoint, offset = timeOffset, func = callfunc, loop = loop}
	table.insert(Timer._list, i, timer)
	return timer
end

function Timer.RemoveTimer(timer)
	timer.timePoint = 0
	timer.func = nil
	timer.loop = false
end

function Timer.Tick(deltaTime)
	Timer.CurrentTime = Timer.CurrentTime + deltaTime
	local removeList = {}
	for index,timer in ipairs(Timer._list) do
		if timer.timePoint <= Timer.CurrentTime then
			if timer.func ~= nil and type(timer.func) == "function" then
				timer.func()
			end
			table.insert(removeList, index)
		end
	end
	-- 删除过期的timer
	local loopList = {}
	for _,removeIndex in ipairs(removeList) do
		local timer = Timer._list[removeIndex]
		table.remove(Timer._list, removeIndex)
		if timer.loop then
			table.insert(loopList, timer)
		end

	end
	-- 插入需要循环的timer
	for _,timer in ipairs(loopList) do
		Timer.InsertTimer(timer.offset, timer.func, timer.loop)
	end
end