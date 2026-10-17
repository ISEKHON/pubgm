ScrollNoticeSystem =  ScrollNoticeSystem or {

}

ScrollMsgRemainCount = {}
ScrollMsgSystemDataList = {}
ScrollMsg_NeedReroll = false

function ScrollNoticeSystem.Enter()
	--log("enter ScrollNoticeSystem");
	BP_ARRAY_ScrollNoticeMsgData = {}
    ScrollMsgSystemDataList = {}
    ScrollMsgRemainCount = {}
    BP_ScrollMsg_CurrentMsgId = 0
    BP_ScrollMsg_CurrentRound = 0
    
    NetUtil.SendPkg("get_active_cycle_roll")
end


function ScrollNoticeSystem.Leave()
	--log("leave ScrollNoticeSystem");
end

function ScrollNoticeSystem:ResetCurrentMsgCount()
    --log("ScrollNoticeSystem.ResetCurrentMsgCount")
    
    if next(BP_ARRAY_ScrollNoticeMsgData) ~= nil then
        for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do
            ScrollMsgRemainCount[BP_ARRAY_ScrollNoticeMsgData[k].msgID] = BP_ARRAY_ScrollNoticeMsgData[k].rollCnt
        end 
    end
    BP_ScrollMsg_CurrentMsgId = 0
    BP_ScrollMsg_CurrentRound = 0
    
    --log_tree("ScrollNoticeSystem.ResetCurrentMsgCount", ScrollMsgRemainCount)
end

function ScrollNoticeSystem:NextRound()
    --log("ScrollNoticeSystem.NextRound")
    if next(BP_ARRAY_ScrollNoticeMsgData) ~= nil then
        for k,v in pairs(ScrollMsgRemainCount) do
            ScrollMsgRemainCount[k] = ScrollMsgRemainCount[k] - 1
        end 
    end
    
    BP_ScrollMsg_CurrentRound = BP_ScrollMsg_CurrentRound + 1
    --log("ScrollNoticeSystem.NextRound"..BP_ScrollMsg_CurrentRound)
    --log_tree("ScrollNoticeSystem.NextRound", ScrollMsgRemainCount)
end

function ScrollNoticeSystem:ShowNextMsg()
    --log_tree("ScrollNoticeSystem.ShowNextMsg BP_ARRAY_ScrollNoticeMsgData", BP_ARRAY_ScrollNoticeMsgData)
    --log_tree("ScrollNoticeSystem.ShowNextMsg ScrollMsgRemainCount", ScrollMsgRemainCount)
    
    --- 系统灯 插队
    if next(ScrollMsgSystemDataList) ~= nil then
        --log_tree("ScrollNoticeSystem.ShowNextMsg system msg come", ScrollMsgSystemDataList)
        local nextSysData = {}
        
        for k,v in pairs(ScrollMsgSystemDataList) do
            nextSysData = v
            ScrollMsgSystemDataList[k] = nil
            break
        end
        --- 构造消息结构
        BP_STRUCT_CurrentScrollNoticeMsgData = 
        {
            msgId = nextSysData.msgID,
            content = nextSysData.content,
            rollSpeed = nextSysData.roll_speed
        }
        --- 显示跑马灯
        ScrollNoticeUI:Init()
        --log_tree("ScrollNoticeSystem.ShowNextMsg system msg end", ScrollMsgSystemDataList)
        return
    end
    
    --- check outdate msg
    ScrollNoticeSystem.DeleteOutdataMsg(list)
    
    --- idip 灯循环
    local hasFoundNext = false
    local hasNext = true
    local isNewRound = false
    local nextData = {}
    --- Find Next
    ------ Find this round
    local hasFoundMsgID = false
    for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do
        
        if not hasFoundMsgID then
            if v.msgID == BP_ScrollMsg_CurrentMsgId then
                hasFoundMsgID = true
            end
            
            if next(BP_ARRAY_ScrollNoticeMsgData, k) == nil then
                isNewRound = true
            end
        else 
            --log("aaaaaaaaaa" .. tostring(v.msgID) .. tostring(ScrollMsgRemainCount[v.msgID]))
            if ScrollMsgRemainCount[v.msgID] > 0 then
                BP_ScrollMsg_CurrentMsgId = v.msgID
                hasFoundNext = true
                nextData = v
                break
            else 
                local index, value = nil, nil
                index, value = next(BP_ARRAY_ScrollNoticeMsgData, k)
                
                if index ~= nil then
                    isNewRound = true
                end
            end
        end
    end
    
    ------ Find next round
    if isNewRound then
        ---log("next round aaaaaaaaaaaa")
        ScrollNoticeSystem:NextRound()
    
        for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do
            if ScrollMsgRemainCount[v.msgID] > 0 then
                BP_ScrollMsg_CurrentMsgId = v.msgID
                hasFoundNext = true
                nextData = v
                break
            end
            if next(BP_ARRAY_ScrollNoticeMsgData, k) == nil then
                hasNext = false
                break
            end
        end
        
    end

    if hasFoundNext then
        --- 构造消息结构
        BP_STRUCT_CurrentScrollNoticeMsgData = 
        {
            msgId = nextData.msgID,
            content = nextData.content,
            rollSpeed = nextData.roll_speed
        }
        --log_tree("ScrollNoticeSystem:ShowNextMsg ", BP_STRUCT_CurrentScrollNoticeMsgData)
        --- 显示跑马灯
        ScrollNoticeUI:Init()
    end
end

function ScrollNoticeSystem:BeginRound()
    
    BP_ScrollMsg_CurrentRound = 0
    --log_tree("ScrollNoticeSystem.BeginRound BP_ARRAY_ScrollNoticeMsgData", BP_ARRAY_ScrollNoticeMsgData)
    --log_tree("ScrollNoticeSystem.BeginRound ScrollMsgRemainCount", ScrollMsgRemainCount)
    
    --- 系统灯 插队
    if next(ScrollMsgSystemDataList) ~= nil then
        --log_tree("ScrollNoticeSystem.ShowNextMsg system msg come", ScrollMsgSystemDataList)
        local nextSysData = {}
        
        for k,v in pairs(ScrollMsgSystemDataList) do
            nextSysData = v
            ScrollMsgSystemDataList[k] = nil
            break
        end
        --- 构造消息结构
        BP_STRUCT_CurrentScrollNoticeMsgData = 
        {
            msgId = nextSysData.msgID,
            content = nextSysData.content,
            rollSpeed = nextSysData.roll_speed
        }
        --- 显示跑马灯
        ScrollNoticeUI:Init()
        --log_tree("ScrollNoticeSystem.ShowNextMsg system msg end", ScrollMsgSystemDataList)
        return
    end
    
    if next(BP_ARRAY_ScrollNoticeMsgData) ~= nil then
        
        local data = {}
        for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do  
            data = v
            break
        end
        
        --- 构造消息结构
        BP_STRUCT_CurrentScrollNoticeMsgData = 
        {
            msgId = data.msgID,
            content = data.content,
            rollSpeed = data.rollSpeed
        }
        
        --log_tree("ScrollNoticeSystem.BeginRound BP_STRUCT_CurrentScrollNoticeMsgData", BP_STRUCT_CurrentScrollNoticeMsgData)
        BP_ScrollMsg_CurrentMsgId = data.msgID
        --- 显示跑马灯
        ScrollNoticeUI:Init()
    end

end

function ScrollNoticeSystem.on_notify_cycleroll_msgs(list)
	--log_tree("ScrollNoticeSystem on_notify_cycleroll_msgs ", list);

    ScrollMsg_NeedReroll = false
    if next(BP_ARRAY_ScrollNoticeMsgData) == nil and 
    next(ScrollMsgSystemDataList) == nil then 
        ScrollMsg_NeedReroll = true
    end
    local ScrollMsg_Gonext = false
    
    if next(list) ~= nil then

        for k,v in pairs(list) do
            local hasDeal = false
            local msgData =  
            {
                msgID = k,
                prior = v.prior,
                content = v.content,
                msgType = v.type,
                rollCnt = v.roll_cnt,
                rollSpeed = v.roll_speed,
                endtime = v.end_time
            }

            -------- 系统内公告
            if v.from == 2 then
                table.insert(ScrollMsgSystemDataList, msgData)
                hasDeal = true
                ScrollMsg_Gonext = true
            end
            
            -------- 更新已有信息
            if not hasDeal and next(BP_ARRAY_ScrollNoticeMsgData) ~= nil then
                for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do  
                    if msgData.msgID == v.msgID then
                        BP_ARRAY_ScrollNoticeMsgData[k] = msgData
                        ScrollMsgRemainCount[BP_ARRAY_ScrollNoticeMsgData[k].msgID] = msgData.rollCnt
                        
                        hasDeal = true
                        --log("update msg .................".. tostring(msgData.msgID))
                        break
                    end     
                end
            end
            
            ------- 根据优先度插入
            if not hasDeal then
                local hasInsert = false
                
                for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do  
                    if msgData.prior < v.prior then
                        table.insert(BP_ARRAY_ScrollNoticeMsgData, k, msgData);
                        ScrollMsgRemainCount[msgData.msgID] = msgData.rollCnt
                        list[k] = nil
                        hasInsert = true
                        --log("hasInsert......................")
                        break
                    end
                end
                
                if not hasInsert then
                    table.insert(BP_ARRAY_ScrollNoticeMsgData, msgData)
                    ScrollMsgRemainCount[msgData.msgID] = msgData.rollCnt
                    --log("lowest msg...........................")
                end
                ScrollMsg_Gonext = true
            end
                 
            ------- 第一个节点
            if not hasDeal and next(BP_ARRAY_ScrollNoticeMsgData) == nil then
                table.insert(BP_ARRAY_ScrollNoticeMsgData, msgData);
                ScrollMsgRemainCount[msgData.msgID] = msgData.rollCnt
                --ScrollMsg_NeedReroll = true
                --log("first msg......................")
            end
            
        end
        
        if not BP_ScrollMsg_Cannotshow and not BP_ScrollMsg_IsRolling then
            if ScrollMsg_NeedReroll then
                --log("ScrollNoticeSystem.on_notify_cycleroll_msgs  ScrollMsg_NeedReroll")
                ScrollNoticeSystem.BeginRound()
            elseif ScrollMsg_Gonext then            
                --log("ScrollNoticeSystem.on_notify_cycleroll_msgs  ScrollMsg_Gonext")
                ScrollNoticeSystem:ShowNextMsg()
            end
        end
    end
    
    --log_tree("ScrollNoticeSystem on_notify_cycleroll_msgs BP_ARRAY_ScrollNoticeMsgData", BP_ARRAY_ScrollNoticeMsgData);
    --log_tree("ScrollNoticeSystem on_notify_cycleroll_msgs ScrollMsgRemainCount", ScrollMsgRemainCount);
    
end


function ScrollNoticeSystem.on_notify_del_cycleroll_msgs(list)
    --log_tree("ScrollNoticeSystem on_notify_del_cycleroll_msgs ", list);

    if next(list) ~= nil then
        for k,v in pairs(list) do
            
            for k1,v1 in pairs(BP_ARRAY_ScrollNoticeMsgData) do  
                if v1.msgID == v then
                    ScrollMsgRemainCount[v] = nil
                    BP_ARRAY_ScrollNoticeMsgData[k1] = nil
                    break
                end     
            end
            
        end
    end
    
    --log_tree("ScrollNoticeSystem on_notify_del_cycleroll_msgs BP_ARRAY_ScrollNoticeMsgData", BP_ARRAY_ScrollNoticeMsgData)
    --log_tree("ScrollNoticeSystem on_notify_del_cycleroll_msgs ScrollMsgRemainCount", ScrollMsgRemainCount)
end

function ScrollNoticeSystem.DeleteOutdataMsg(list)
    for k,v in pairs(BP_ARRAY_ScrollNoticeMsgData) do  
        --log("ScrollNoticeSystem.DeleteOutdataMsg v.endtime " .. tostring(v.endtime) .. " " .. tostring(HeartBeatServerTime)) 
        if v.endtime < HeartBeatServerTime then
            log("ScrollNoticeSystem.DeleteOutdataMsg del : ".. tostring(v.msgID))
            ScrollMsgRemainCount[v.msgID] = nil
            BP_ARRAY_ScrollNoticeMsgData[k] = nil
            break
        end     
    end
end

--[[网络回调]]--
s2c["notify_cycleroll_msgs"] = ScrollNoticeSystem.on_notify_cycleroll_msgs;
s2c["notify_del_cycleroll_msgs"] = ScrollNoticeSystem.on_notify_del_cycleroll_msgs;