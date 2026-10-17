FuncUtil = FuncUtil or {
    LastServerTime = 0,
    LocalTimeTick = 0,

    BitCount = 32,
    BitValues = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048},
}

function FuncUtil:getDefaultOpenID()
	return "";
end

--版本是否客户端一致
function FuncUtil:IsMatchVersion(sVersion)
    --只处理大版本号0.0.1
   --log("severVersion"..sVersion);
   local curVerion = Client.GetAppVersion(); --"0.0.5.1018";
   local clientVersion = FuncUtil:GetClientFormat(curVerion);
   local serverVersion = FuncUtil:GetClientFormat(sVersion);
   --log("clientVersion"..clientVersion);
   --log("serverVersion"..serverVersion);

   local serverStrArray = string.split(serverVersion, ".");
   local clientStrArray = string.split(clientVersion, ".");

   for i = 1, #serverStrArray do 
       if tonumber(serverStrArray[i]) ~= tonumber(clientStrArray[i]) then
            return false;
       end
   end

   return true;
end

--结构化版本字符串，和后台统一
function FuncUtil:GetClientFormat(newVesion)
    local  curVerion = newVesion;
    local iteratorFunc = string.gmatch(curVerion, "%w+");
    local count = 0;
    local len = 0;
    for subver in iteratorFunc do
        len = len+string.len(subver);
        count = count+1;
        if  count >= 3 then 
            break;
        end
    end
    if  count < 3 then
        
        return "0.0.0";
    end    
    return string.sub(curVerion, 1, len+2 );
end

function FuncUtil:getRandName()
    --local name = "吃鹅"
    local name = FuncUtil.GetLocalizeResStr("301125");    
    math.randomseed(os.time());
    for i=1,5 do
        name = name .. string.char(math.random(97,122));
    end
    return name;
end

function FuncUtil:err(msg)
	ScriptHelperClient.ShowScreenDebugMessage(msg)
end

--复制表格
function FuncUtil:CopyTable(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = FuncUtil:CopyTable(v)
        end
    end
    return tab
end

--求表长
function FuncUtil:CountTable(st)
    if type(st) ~= "table" then
        return 0;
    else
        local count = 0;
        for k, v in pairs(st) do
            count = count + 1
        end
        return count;
    end
end

function FuncUtil:InitConfigs()
    self:InitStyles();
    self:InitGameStatusMap();
end

function FuncUtil:InitStyles()
    local fontStyles = Client.GetTable("FontStyleRes");
    for k,v in pairs(fontStyles) do
        Client.SetFontStyle(v.StyleName, v.FontSize, v.FontPath, v.FontColor, v.FontShadow and v.FontShadow ~= 0);
    end
    local imgStyles = Client.GetTable("ImageStyleRes");
    for k,v in pairs(imgStyles) do
        Client.SetImageStyle(v.StyleName, v.ImageSize, v.ImagePath, v.ImageColor);
    end
    local linkStyles = Client.GetTable("LinkStyleRes");
    for k,v in pairs(linkStyles) do
        Client.SetLinkStyle(v.StyleName, v.FontSize, v.FontPath, v.FontColor, v.UnderLine);
    end
end

--游戏状态到地图的对应表
function FuncUtil:InitGameStatusMap()
    local StatusToMap = 
    {
        Login = "/Game/Maps/UImap/Editor_login",
        Lobby = "/Game/Maps/UImap/Lobby",
        CreateRole = "/Game/Maps/UImap/Createrole",
    };
    Client.SetGameStatusMap(GameFrontendHUD, StatusToMap);
end

function OnHyperLinkClicked(MetaData)
    log_tree("OnClickMeta", MetaData)
end

function string.split(str, sep)
    local result = {}
    if str == nil or sep == nil or type(str) ~= "string" or type(sep) ~= "string" then
        return result
    end
    if #sep == 0 then
        return result
    end
    local pattern = string.format("([^%s]*)", sep)
    string.gsub(str, pattern, function(c) result[#result+1] = c end)
    return result
end

function FuncUtil:FormatTime(t)
	if t == nil then
		return;
	end
	
	local diff = os.time() - t;
    local days = math.floor(diff/86400);
    local hours = math.fmod(math.floor(diff/3600), 24);
    local mins = math.fmod(math.floor(diff/60), 60);
    local seconds = math.fmod(diff, 60);


    if days >= 1 then
		if hours >= 1 then
		    --return days.."天"..hours.."小时前";
		    return FuncUtil.LocalizeResFormat( "301254", tostring(days), tostring(hours));
		elseif hours < 1 and hours >= 0 then
			--return  days.."天前";
		    return FuncUtil.LocalizeResFormat( "301255", tostring(days));
		end

    end
    if hours >= 1 then
		if mins >= 1 then
		    --return hours.."小时"..mins.."分钟前";
		    return FuncUtil.LocalizeResFormat( "301256", tostring(hours), tostring(mins));
		elseif mins < 1 and mins >= 0 then
			--return hours.."小时前";
		    return FuncUtil.LocalizeResFormat( "301257", tostring(hours));
		end
    end
    if mins >= 1 then
        --return mins.."分钟"..seconds.."秒前";
		return FuncUtil.LocalizeResFormat( "301258", tostring(mins), tostring(seconds));
    end
    --return seconds.."秒前";
	return FuncUtil.LocalizeResFormat( "301259", tostring(seconds));
end

function FuncUtil:FormatTime2(t)
	if t == nil then
		return;
	end
	
    local hours = math.fmod(math.floor(t/3600), 24);
    local mins = math.fmod(math.floor(t/60), 60);
    local seconds = math.fmod(t, 60);

    if hours >= 1 then
		if mins >= 1 then
		    --return "已开局"..hours.."小时"..mins.."分钟";
		    return FuncUtil.LocalizeResFormat( "301260", tostring(hours), tostring(mins));
		elseif mins < 1 and mins >= 0 then
			--return "已开局"..hours.."小时";
			return FuncUtil.LocalizeResFormat( "301261", tostring(hours));
		end
    end
    if mins >= 1 then
        --return "已开局"..mins.."分钟"..seconds.."秒";
		return FuncUtil.LocalizeResFormat( "301262", tostring(mins), tostring(seconds));
    end
    --return "已开局"..seconds.."秒";
	return FuncUtil.LocalizeResFormat( "301263", tostring(seconds));
end

function FuncUtil:StrTrim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))  
end

function FuncUtil:EncodeURI(s)
    if type(s) == "string" then
        s = string.gsub(s, "\n", "\r\n")
        s = string.gsub(s, "([^%w ])",
            function (c) return string.format("%%%02X", string.byte(c)) end)
        s = string.gsub(s, " ", "+")
    end
    return s
end

function FuncUtil:DecodeURI(s)
    if type(s) == "string" then
        s = string.gsub(s, '%%(%x%x)', 
            function (hex) return string.char(tonumber(hex,16)) end )
    end
    return s
end

function FuncUtil:DecodeXML(str)
    local map={ ["lt"]="<", ["gt"]=">", ["amp"]="&", ["quot"]='"', ["apos"]="'" }
    str = string.gsub( str, '(&(#?x?)([%d%a]+);)', function(orig,n,s)
    return (n=='' and map[s])
           or (n=="#x" and tonumber(s,16)) and string.char(tonumber(s,16))
           or (n=="#" and tonumber(s)) and string.char(s)
           or orig
  end )
  return str
end

function FuncUtil:GetGCloudErrorMsg(errorId)
	--local msg = "服务器连接状态异常，请重新登录："..errorId;
	local msg = FuncUtil.GetLocalizeResStr("301234")..tostring(errorId);
	if errorId == GCLOULD_ErrorNetworkException then
		--msg = "无法连接到服务器，请检查你的网络";
		msg = FuncUtil.GetLocalizeResStr("103015");
	elseif errorId == GCLOULD_ErrorTimeout then
		--msg = "服务器连接超时，请稍候再试";
		msg = FuncUtil.GetLocalizeResStr("301235");
	elseif errorId == GCLOULD_ErrorInvalidArgument then
		--msg = "网络通讯参数错误";
		msg = FuncUtil.GetLocalizeResStr("301236");
	elseif errorId == GCLOULD_ErrorLengthError then
		--msg = "网络通讯输出参数长度错误";
		msg = FuncUtil.GetLocalizeResStr("301237");
	elseif errorId == GCLOULD_ErrorEmpty then
		--msg = "帐号未登录，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301238");
	elseif errorId == GCLOULD_ErrorNotInitialized then
		--msg = "网络连接未初始化";
		msg = FuncUtil.GetLocalizeResStr("301239");
	elseif errorId == GCLOULD_ErrorNotSupported then
		--msg = "当前网络不支持";
		msg = FuncUtil.GetLocalizeResStr("301240");
	elseif errorId == GCLOULD_ErrorNotInstalled then
		--msg = "QQ或微信未安装";
		msg = FuncUtil.GetLocalizeResStr("301241");
	elseif errorId == GCLOULD_ErrorSystemError then
		--msg = "系统错误，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301242");
	elseif errorId == GCLOULD_ErrorNoPermission then
		--msg = "没有鉴权，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301243");
	elseif errorId == GCLOULD_ErrorInvalidGameId then
		--msg = "无效的游戏应用ID，请重新下载";
		msg = FuncUtil.GetLocalizeResStr("301244");
	elseif errorId == GCLOULD_ErrorChecking then
		--msg = "鉴权校验中，请稍候";
		msg = FuncUtil.GetLocalizeResStr("301245");
	elseif errorId == GCLOULD_ErrorConnectFailed then
		--msg = "连接服务器失败，请重试";		
		msg = FuncUtil.GetLocalizeResStr("301246");
	elseif errorId == GCLOULD_ErrorPeerCloseConnection then
		--msg = "服务器连接已断开，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301247");
	elseif errorId == GCLOULD_ErrorPeerStopSession then
		--msg = "服务器已断开，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301248");
	elseif errorId == GCLOULD_ErrorStayInQueue then
		--msg = "正在队列中，请稍后";
		msg = FuncUtil.GetLocalizeResStr("301249");
	elseif errorId == GCLOULD_ErrorSvrIsFull then
		--msg = "服务器已满，请稍后登录";
		msg = FuncUtil.GetLocalizeResStr("301250");
	elseif errorId == GCLOULD_ErrorTokenSvrError then
		--msg = "鉴权服务器错误，请稍候登录";
		msg = FuncUtil.GetLocalizeResStr("301251");
	elseif errorId == GCLOULD_ErrorAuthFailed then
		--msg = "鉴权失败，请重新登录";
		msg = FuncUtil.GetLocalizeResStr("301252");
	elseif errorId == GCLOULD_ErrorOverflow then
		--msg = "缓冲区溢出";
        msg = FuncUtil.GetLocalizeResStr("301253");
    elseif errorId == GCLOULD_ErrorInvalidToken then
        --token过期，提示如下
        --连接超时，请重新登录
        msg = FuncUtil.GetLocalizeResStr("4007");
	end
	
	return msg;
end

function FuncUtil:ParseURLParams(s)
	log(s);
	local params = {};
    for k, v in string.gmatch(s, "([^&=?]+)=([^&=?]+)") do
		params[k] = FuncUtil:DecodeURI(v);
	end
	return params;
end

--检查名字合法性
function FuncUtil:CheckName(inputstr, symbol, maxLen, support_space)
    local unitLen = 0
    local hasIllegalChar = false
    local lenInByte = #inputstr
    local retStr = ""
    local i = 1
    --汉字基本集 E4B880-E9BEBF
    local chinese1 = tonumber("E4B880", 16)
    local chinese2 = tonumber("E9BEBF", 16)
    local chineseSymbol = {"EFBC81","EFBFA5","E280A6","E280A6","EFBC88","EFBC89","E28094","EFBD9B","EFBD9D",
      "EFBC9A","E2809C","E2809D","E3808A","E3808B","EFBC9F","E38090","E38091","E38081","EFBC9B","E28098","EFBC8C","E38082","E38081","E28099"}
    --日文平假名
    local janpan1 = tonumber("E38180", 16)
    local janpan2 = tonumber("E3829F", 16)
    --日文片假名
    local janpan3 = tonumber("E382A0", 16)
    local janpan4 = tonumber("E383BF", 16)
    --韩文
    local korean1 = tonumber("EAB080", 16)
    local korean2 = tonumber("ED9EAF", 16)
    -- 俄文 西里尔字母
    local russia1 = tonumber("D080", 16)
    local russia2 = tonumber("D3Bf", 16)
    -- 俄文 西里尔字母扩充集
    local russia3 = tonumber("D480", 16)
    local russia4 = tonumber("D4AF", 16)
    -- 泰文
    local tai1 = tonumber("E0B880", 16)
    local tai2 = tonumber("E0B9BF", 16)
    -- EU special
    local EU_specail1 = tonumber("C2A1", 16)
    local EU_specail2 = tonumber("CAAf", 16)
    -- Vietnamese
    local Vietnamese1 = tonumber("E1B880", 16)
    local Vietnamese2 = tonumber("E1BBBF", 16)
    local Vietnamese3 = tonumber("CC80", 16)
    local Vietnamese4 = tonumber("CDBA", 16)
    
    while ( i <= lenInByte ) 
    do
        local a = string.byte(inputstr, i)
        local byteCount = 1;
        if a >= 0 and a < 192 then
            byteCount = 1                                               --1字节字符
            unitLen = unitLen + 1
            local isok = true
            if(symbol ~= nil) then
                if (a >= 0 and a<39) or (a > 39 and a < 48) or (a > 57 and a < 65) or (a > 90 and a < 97) or (a > 122) then
                -- if (a >= 0 and a < 48) or (a > 57 and a < 65) or (a > 90 and a < 97) or (a > 122) then
                -- make space and single quotes valid
                    isok = false
                end
            elseif (a >= 0 and a < 32) or (a > 126) then
                --elseif (a >= 0 and a < 33) or (a > 126) then
                -- make space valid
                isok = false
            end

            if(support_space ~= nil and a == 32) then
                isok = true
            end

            if( isok) then
                retStr = retStr .. string.char(a)
            else
                hasIllegalChar = true
            end
        elseif a >= 192 and a < 224 then                                --2节字符
            byteCount = 2                                               
            unitLen = unitLen + 2

            local b = string.byte(inputstr, i + 1)
            local str = string.format("%X",a)..string.format("%X",b);
            local value = tonumber(str, 16)
            if(value >= russia1 and value <= russia2) or (value >= russia3 and value <= russia4) then
                log("checkname is Russia")
                isok = true
            elseif ( value >= EU_specail1 and value <= EU_specail2) then
                log("checkname is EU special")
                isok = true
            elseif ( value >= Vietnamese3 and value <= Vietnamese4) then
                log("checkname is vietnamese")
                isok = true
            end

            if ( isok ) then
                retStr = retStr .. string.sub(inputstr, i, i + byteCount - 1)
            else
                hasIllegalChar = true
            end
        elseif a >= 224 and a < 240 then
            byteCount = 3                                               --3字节
            unitLen = unitLen + 2
            local b = string.byte(inputstr, i + 1)
            local c = string.byte(inputstr, i + 2)
            local str = string.format("%X",a)..string.format("%X",b)..string.format("%X",c);
            local value = tonumber(str, 16)
            local isok = false
            if ( value >= chinese1 and value <= chinese2) then
                log("checkname is chinese")
                isok = true
            elseif ( value >= janpan1 and value <= janpan2) then
                log("checkname is janpan1-2")
                isok = true
            elseif ( value >= janpan3 and value <= janpan4) then
                log("checkname is janpan3-4")
                isok = true
            elseif ( value >= tai1 and value <= tai2) then
                log("checkname is tai")
                isok = true
            elseif ( value >= Vietnamese1 and value <= Vietnamese2) then
                log("checkname is vietnamese")
                isok = true
            elseif ( value >= korean1 and value <= korean2) then
                log("checkname is korean")
                isok = true
            end
            if( not isok and symbol == nil) then
              for i,v in ipairs(chineseSymbol) do
                if(value == tonumber(v , 16)) then
                    isok = true
                    break;
                end
              end
            end
            if ( isok ) then
                retStr = retStr .. string.sub(inputstr, i, i + byteCount - 1)
            else
                hasIllegalChar = true
            end
        elseif a >= 240 and a < 248 then
            byteCount = 4                                               --4字节
            unitLen = unitLen + 2
            hasIllegalChar = true
        elseif a >= 248 and a < 252 then
            byteCount = 5                                               --5字节
            unitLen = unitLen + 2
            hasIllegalChar = true;
        elseif a >= 252  then
            byteCount = 6                                               --6字节
            unitLen = unitLen + 2
            hasIllegalChar = true;
        end
        i = i + byteCount

        if (maxLen ~= nil and unitLen >= maxLen) then
            break;
        end
    end
    return hasIllegalChar , unitLen , retStr
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function ShowNotice(noticeId)
    local noticeStr = FuncUtil.GetLocalizeResStr(noticeId)
    if noticeStr ~= "" then
        PopUpNoticeUI.ShowNewNotice(noticeStr)
    else
        PopUpNoticeUI.ShowNewNotice(noticeId)
    end
end

--获得单个掉落方案id所有的物品信息（不去重）
function GetDropList(dropId)
    local result = {}
	--先读取掉落方案
    local dropTable = BP_ARRAY_Drop
    for _,dropInfo in pairs(dropTable) do
		local mapping = {}
        if dropInfo.DropID == dropId then
			--再去读掉落映射
			local dropMapping = Client.GetTableData("DropMapping", dropInfo.DropMappingID)
			if dropMapping ~= nil then
				local DropItemID
				if DataMgr.avatarData.gamegender == 2 then
					DropItemID = dropMapping.DropItemFemaleID
				else
					DropItemID = dropMapping.DropItemMaleID
				end
				local one = {}
				one.DropItemID = DropItemID
				one.DropItemNum = dropInfo.DropItemNum
				one.DropItemSort = dropInfo.DropItemSort
				one.DropItemTime = dropInfo.DropItemTime
                one.Desc = dropInfo.Desc;
				table.insert(mapping, one)
			end
        end
		for _,item in pairs(mapping) do
			table.insert(result, item)
		end
    end
    table.sort(result, function(a, b)
        return a.DropItemSort > b.DropItemSort
    end)
    return result
end

--获得多个掉落方案所有的物品信息（去重）
function GetDropsList(dropIds)
	local result = {}
	--先读取掉落方案
    local dropTable = BP_ARRAY_Drop
	for _,dropId in pairs(dropIds) do
		local mapping = {}
		for _,dropInfo in pairs(dropTable) do
			if dropInfo.DropID == dropId then
				--再去读掉落映射
				local dropMapping = Client.GetTableData("DropMapping", dropInfo.DropMappingID)
				if dropMapping ~= nil then
					local DropItemID
					if DataMgr.avatarData.gamegender == 2 then
						DropItemID = dropMapping.DropItemFemaleID
					else
						DropItemID = dropMapping.DropItemMaleID
					end
					local one = {}
					one.DropItemID = DropItemID
					one.DropItemNum = dropInfo.DropItemNum
					one.DropItemSort = dropInfo.DropItemSort
					one.DropItemTime = dropMapping.DropItemTime
                    one.DropItemWeight = dropInfo.Weight
					--考虑重复
					local add = true
					for _,item in pairs(result) do
						if one.DropItemID == item.DropItemID and one.DropItemNum == item.DropItemNum and one.DropItemTime == item.DropItemTime then
							add = false
							break
						end
					end
					if add then
						table.insert(mapping, one)
					end
				end
			end
		end
		for _,item in pairs(mapping) do
			table.insert(result, item)
		end
	end
    table.sort(result, function(a, b)
        return a.DropItemSort > b.DropItemSort
    end)
    return result
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            log(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        log(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        log(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        log(indent.."["..pos..'] => "'..val..'"')
                    else
                        log(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                log(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        log(tostring(t).." {")
        sub_print_r(t,"  ")
        log("}")
    else
        sub_print_r(t,"  ")
    end
    log()
end

function string.split(str, sep)
    local result = {}
    if str == nil or sep == nil or type(str) ~= "string" or type(sep) ~= "string" then
        return result
    end
    if #sep == 0 then
        return result
    end
    local pattern = string.format("([^%s]*)", sep)
    string.gsub(str, pattern, function(c) result[#result+1] = c end)
    return result
end

function FormatTime(seconds)
    local date = os.date("*t", seconds)
    local str = string.format("%d-%d-%d", date.year, date.month, date.day)
    return str
end

function FuncUtil.SetServerTimeInSec(serverTime)
    if serverTime == nil then
        return
    end
    -- log("FuncUtil.SetServerTimeInSec"..serverTime);
    FuncUtil.LocalTimeTick = 0;
    FuncUtil.LastServerTime = serverTime;
end

function FuncUtil.GetServerTimeInSec()
    if FuncUtil.LastServerTime == 0 then
        return os.time();
    end

    return FuncUtil.LastServerTime + math.ceil(FuncUtil.LocalTimeTick);
end

-- 1~7 == 周一~周天
function FuncUtil.GetWeekDay(day)
    if day == 1 then
        return 7;
    else
        return day - 1;
    end
end

function FuncUtil.GetServerWeekDay()
    local currentDate = os.date("*t", FuncUtil.GetServerTimeInSec());
    return FuncUtil.GetWeekDay(currentDate.wday);
end

-- 是否是同一天
function FuncUtil.IsSameDay(time1, time2)
    return math.floor((time1 - 57600) / 86400) == math.floor((time2 - 57600) / 86400);
end

function FuncUtil.IsInTime(beginTime, endTime)
	
	if beginTime == nil or endTime == nil then
		return false
	end
	log("time range = " .. beginTime .. "~" .. endTime)
	
	local begDate = {}
	for value in string.gmatch(beginTime, "%d+") do
		table.insert(begDate, tonumber(value))
	end
	
	local endDate = {}
	for value in string.gmatch(endTime, "%d+") do
		table.insert(endDate, tonumber(value))
	end
	
	if #begDate < 6 or #endDate < 6 then
		return false
	end
	
	local timeValBegin = os.time({year = begDate[1], month = begDate[2], day = begDate[3], hour = begDate[4], min = begDate[5], sec = begDate[6]})
	local timeValEnd = os.time({year = endDate[1], month = endDate[2], day = endDate[3], hour = endDate[4], min = endDate[5], sec = endDate[6]})
	local now = FuncUtil.GetServerTimeInSec()
	
	return now >= timeValBegin and now < timeValEnd
end

function FuncUtil.SecToDateString(sec)
    local DateFormat = FuncUtil.GetLocalizeResStr(110070);
    return os.date(DateFormat, sec);
end

function FuncUtil.EncodeBase64(source_str)  
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'  
    local s64 = ''  
    local str = source_str  
  
    while #str > 0 do  
        local bytes_num = 0  
        local buf = 0  
  
        for byte_cnt=1,3 do  
            buf = (buf * 256)  
            if #str > 0 then  
                buf = buf + string.byte(str, 1, 1)  
                str = string.sub(str, 2)  
                bytes_num = bytes_num + 1  
            end  
        end  
  
        for group_cnt=1,(bytes_num+1) do  
            local b64char = math.fmod(math.floor(buf/262144), 64) + 1  
            s64 = s64 .. string.sub(b64chars, b64char, b64char)  
            buf = buf * 64  
        end  
  
        for fill_cnt=1,(3-bytes_num) do  
            s64 = s64 .. '='  
        end  
    end  
  
    return s64  
end

function GetSafeNumber(value)
	if value == nil then
		return 0
	end
	
	return value;
end 

--翻译文字
function translate(value)
	return value;
end

function FuncUtil.GetLocalizeResStr(id)
    local localResCfg = Client.GetTableData("LocalizeRes", id);
    if localResCfg ~= nil then
        return localResCfg.TextValue;
    end
    sandbox.LogError("LocalizeRes not found id="..id);
    return "";
end

function FuncUtil.LocalizeResFormat(id, ...)
    local strFormat = FuncUtil.GetLocalizeResStr(id);
    if strFormat ~= "" then
        return string.format(strFormat, ...);
    end
    sandbox.LogError("LocalizeRes format is empty id="..id);
    return "";
end

function FuncUtil.TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


-- 位掩码
function FuncUtil.MarkBit(maskTable, index)
    if index <= 0 or index > FuncUtil.BitCount then
        sandbox.LogError("FuncUtil.MarkBit index invalid "..index);
        return;
    end

    maskTable[index] = true;
end

function FuncUtil.UnmarkBit(maskTable, index)
    if index <= 0 or index > FuncUtil.BitCount then
        sandbox.LogError("FuncUtil.UnmarkBit index invalid "..index);
        return;
    end

    maskTable[index] = false;
end

function FuncUtil.GetBitMaskValue(maskTable)
    local result = 0;
    local value = 0;
    for i=1,FuncUtil.BitCount do
        if maskTable[i] then
            value = FuncUtil.BitValues[i];
            if value == nil then
                value = 2 ^ (i-1);
                FuncUtil.BitValues[i] = value;
            end
            result = result + value;
        end
    end
    return result;
end

function FuncUtil.GetMaxSegement(allSegmentInfo)
   
        maxSegment_Solo = -1;
        maxSegment_duo  = -1;
        maxSegment_squad = -1;

        all_segment_info = allSegmentInfo;
        maxSegment = -1;
        for k,v in pairs(all_segment_info) do
            local segemnt_solo = all_segment_info[k][1];
            local segemnt_duo =  all_segment_info[k][2];
            local segemnt_squad =  all_segment_info[k][3];
            local tmpmax = math.max(segemnt_solo, segemnt_duo, segemnt_squad);
            if maxSegment < tmpmax then
                maxSegment = tmpmax;
                maxSegment_Solo = segemnt_solo;
                maxSegment_duo = segemnt_duo;
                maxSegment_squad = segemnt_squad;
            end
            --log("chatwaynedong:maxSegment_Solo = "..maxSegment_Solo..", maxSegment_duo = "..profileData.segment_info_duo..", maxSegment_squad = "..maxSegment_squad)
        end
        return maxSegment_Solo, maxSegment_duo, maxSegment_squad
end