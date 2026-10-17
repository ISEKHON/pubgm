ScrollNoticeUI = ScrollNoticeUI or 
{
}

-- Notice Msg
BP_STRUCT_ScrollNoticeMsgData =
{
    msgID = 0,
    prior = 1,
    content = "",
    msgType = 1,
    rollCnt = 1,
    rollSpeed = 1,
    endtime = 111
}

BP_STRUCT_CurrentScrollNoticeMsgData = 
{
    msgId = 0,
    content = "<TaskFont>Passepartout</>& 3333<a id=\"ScrollNoticeHyLink\" url=\"www.baidu.com\" style=\"TaskLink\">Hyperlink</>",
    rollSpeed = 1
}

BP_ScrollMsg_IsRolling = false
BP_ScrollMsgUrl = ""
BP_ScrollMsg_CurrentMsgId = 0
BP_ScrollMsg_CurrentRound = 0
BP_ScrollMsg_ShowEnd = false
BP_ScrollMsg_CurrentRealMsg = ""
BP_ScrollMsg_Cannotshow = false

-- Notice Msg Array
BP_ARRAY_ScrollNoticeMsgData =
{
    BP_STRUCT_ScrollNoticeMsgData = _G.BP_STRUCT_ScrollNoticeMsgData, --定义结构体数组，这种写法要作为规范规定下来
}

--注册Widget
function bp_scrollnotice_RegisterUI()
  LuaClassObj.SubUIWidgetList(bp_scrollnotice,
    {{Path="/Game/UMG/UI_Logic/Lobby/Lobby_ScrollBar_Logic_BP.Lobby_ScrollBar_Logic_BP_C", Container="Default", ZOrder=BP_ENUM_UI_SCROLLMSG_ZORDER}},
    {"Lobby"},
	false,
	false,
	true
  );

end

function EventFetchInfo()
	
end

function ScrollNoticeUI:Init()
	LuaClassObj.HandleDynamicCreation(bp_scrollnotice);
    log("ScrollNoticeUI:Init")
    BP_ScrollMsg_CurrentRealMsg = string.gsub(BP_STRUCT_CurrentScrollNoticeMsgData.content, '<[^>]*>', '')

    log("ScrollNoticeUI:Init BP_ScrollMsg_CurrentRealMsg".. BP_ScrollMsg_CurrentRealMsg)
    BP_ScrollMsg_IsRolling = true
    LuaClassObj.HandleUIMessage(bp_scrollnotice, "UIShow");
end

function EventOneMsgRollEnd()
    log("EventOneMsgRollEnd_Push MSG id" .. BP_ScrollMsg_CurrentMsgId)
    log("EventOneMsgRollEnd_Push Round ID" .. BP_ScrollMsg_CurrentRound)
    BP_ScrollMsg_IsRolling = false
    
    if not BP_ScrollMsg_Cannotshow then
        ScrollNoticeSystem:ShowNextMsg()
    end
end

function EventShowNextMsg()
    
    local msgData =  
    {
        msgID = 1,
        prior = 1,
        content = "<ScrollMsgRed>红</><ScrollMsgYellow>黄</><ScrollMsgGreen>绿</><a id=\"ScrollNoticeHyLinkID\" style=\"ScrollNoticeHyLink\" url=\"www.baidu.com\">超链接</>",
        msgType = 1,
        rollCnt = 1,
        rollSpeed = 1,
        endtime = 0
    }
    table.insert(BP_ARRAY_ScrollNoticeMsgData, msgData);
    
    msgData =  
    {
        msgID = 2,
        prior = 2,
        content = "第二条消息",
        msgType = 1,
        rollCnt = 3,
        rollSpeed = 2,
        endtime = 0
    }
    table.insert(BP_ARRAY_ScrollNoticeMsgData, msgData);
    ScrollNoticeSystem:ResetCurrentMsgCount()
    --log_tree("EventShowNextMsg BP_ARRAY_ScrollNoticeMsgData", BP_ARRAY_ScrollNoticeMsgData)
    ScrollNoticeSystem:BeginRound()
end

--超链接点击
function ScrollNoticeUI.OnHyperLinkClicked(MetaData)
    log_tree("ScrollNoticeUI.OnHyperLinkClicked", MetaData)
    if MetaData.id == "ScrollNoticeHyLinkID" and type(MetaData.url) == "string" then
        BP_ScrollMsgUrl = MetaData.url
        LuaClassObj.HandleUIMessage(bp_scrollnotice, "OpenUrl");
    end
end

function ScrollNoticeUI:HideScrollNotice()
    log("ScrollNoticeUI:HideScrollNotice")
    BP_ScrollMsg_Cannotshow = true
    BP_ScrollMsg_IsRolling = false
    LuaClassObj.HandleUIMessage(bp_scrollnotice, "UIHide");
end

function ScrollNoticeUI:RerollScrollNotice()
    log("ScrollNoticeUI:RerollScrollNotice")
    BP_ScrollMsg_Cannotshow = false
    ScrollNoticeSystem:ResetCurrentMsgCount()
    ScrollNoticeSystem:BeginRound()
end

function ScrollNoticeUI:BackLoginReleaseData()
    log("ScrollNoticeUI:BackLoginReleaseData")
    ScrollMsgRemainCount = {}
    ScrollMsgSystemDataList = {}
    ScrollMsg_NeedReroll = false
    BP_ScrollMsg_Cannotshow = false
    BP_ScrollMsg_IsRolling = false
    BP_ARRAY_ScrollNoticeMsgData = {}
    BP_ScrollMsg_CurrentMsgId = 0
    BP_ScrollMsg_CurrentRound = 0
end

