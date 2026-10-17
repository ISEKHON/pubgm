sandbox = {};
sandbox.files = {};
sandbox.meta = {__index=function(t, k) return _G[k]; end};

-- log level
sandbox.LogVerbose = function(Log)
    sandbox.Log("Verbose", Log);
end

sandbox.LogNormal = function(InLog)
    sandbox.Log("Log", InLog);
end

sandbox.LogWarning = function(Log)
    sandbox.Log("Warning", Log);
end

sandbox.LogError = function(Log)
    sandbox.Log("Error", Log);
end

local try_load = function(node)
    local filename = node.filename;
    local filetext = sandbox.ReadFile(filename);
    if not filetext then
        sandbox.LogError(string.format("failed to read file: %s", filename));
        return;
    end

    local trunk, msg = load(filetext, filename, "bt", node.env);
    if not trunk then
        sandbox.LogError(string.format("load file: %s ... ... [failed]", node.filename));
        sandbox.LogError(msg);
        return;
    end

    local ok, err = pcall(trunk);
    if not ok then
        sandbox.LogError(string.format("exec file: %s ... ... [failed]", node.filename));
        sandbox.LogError(err);
        return;
    end

    sandbox.LogNormal(string.format("load file: %s ... ... [ok]", node.filename));
end

local get_filenode = function(filename)
    local node = sandbox.files[filename];
    if node then
        return node;
    end
    local env = {};
    setmetatable(env, sandbox.meta);
    node = {env=env, filename=filename};
    sandbox.files[filename] = node;
    return node;
end

sandbox.import = function(filename)
    sandbox.Log(Log, "import " .. filename)
    local node = get_filenode(filename);
    if node.time then
        return node.env;
    end
    node.time = sandbox.GetFileTime(filename);
    local filetext = sandbox.ReadFile(filename);
    
    if not filetext then
        sandbox.LogError(string.format("failed to read file: %s", filename));
        return node.env;
    end

    local trunk, code_err = load(filetext, filename, "bt", node.env);
    if not trunk then
        sandbox.Log(Error, code_err);
        error(code_err);
    end

    local ok, exec_err = pcall(trunk);
    if not ok then
        sandbox.Log(Error, code_err);
        error(exec_err);
    end

    return node.env;
end

sandbox.reload = function()
    local now = os.time();
    for path, node in pairs(sandbox.files) do
        local filetime = sandbox.GetFileTime(node.filename);
        if filetime ~= node.time and filetime ~= 0 and math.abs(now - filetime) > 1 then
            node.time = filetime;
            try_load(node);
        end
    end
end

function import(filename)
    local node = get_filenode(filename);
    if not node.time then
        node.time = sandbox.GetFileTime(filename);
        try_load(node);
    end
    return node.env;
end

--------------------------
print = sandbox.LogNormal;
--[[
函数: log_tree(desc, var)
功能: 打印变量,特别是对table类型做树形输出
desc: 变量描述
var: 要输出的变量,可以是任何类型table, bool, number, nil
注意: 不保证性能,仅供调试用;对table中的多个key不保证输出顺序.
示例:
local player = {name="bitch", level=10, id=123};
log_tree("player_data", player);
--]]
local function var2string(var)
	local text = tostring(var);
	text = string.gsub(text, "\r", "\\r");
	text = string.gsub(text, "\n", "\\n");
	text = string.gsub(text, "%c", "\\^");
	return text;
end

local function tab2string(visited, path, base, tab)
    local pre = visited[tab];
    if pre then
        return pre;
    end

	visited[tab] = path;

	local size = 0;
    for k, v in pairs(tab) do
        size = size + 1;
    end

    if size == 0 then
        return "{ }";
    end

    local lines = {};
    local idx = 1;
	for k, v in pairs(tab) do
        local vtype = type(v);
        local header = base..(idx < size and "├─ " or "└─ ")..var2string(k);
        if vtype == "table" then
        	local vpath = visited[v];
        	if vpath then
        		lines[#lines + 1] = header..": "..vpath;
        	else
                local out = tab2string(visited, path.."/"..var2string(k), base..(idx < size and "│  " or "   "), v);
                if type(out) == "string" then
                    lines[#lines + 1] = header..": "..out;
                else
                    lines[#lines + 1] = header;
                    for _, one in ipairs(out) do
                        table.insert(lines, one);
                    end
                end
            end
        else
            local txt = var2string(v);
            if vtype == "string" then
                txt = '\"'..txt..'\"';
            end
            lines[#lines + 1] = header..": "..txt;
        end
        idx = idx + 1;
	end

    return lines;
end

function _G.log_tree(desc, var)
    if var == nil then
        var = desc;
    end
    if type(var) ~= "table" then
        print(var2string(desc)..": "..var2string(var));
        return;
    end

    local visited = {};
    local out = tab2string(visited, "", "", var);

    if type(out) == "string" then
        print(var2string(desc)..": "..out);
        return;
    end

    print(var2string(desc));
    for i, line in ipairs(out) do
        print(line);
    end
end
-------------------------------------------------------------------------------
--[[
函数: DeepCopy(obj)
功能: 对table类型进行深拷贝
obj: 传入table
示例:
local player = {name="bitch", level=10, id=123};
local t = player; ---浅拷贝,t是player的引用
local t1 = DeepCopy(player); ---深拷贝
player.level = 11; 
print(t.level) --也是11, 
print(t1.level)--仍是10, 

--]]
function _G.DeepCopy( obj )      
    local InTable = {};  
    local function Func(obj)  
        if type(obj) ~= "table" then   --判断表中是否有表  
            return obj;  
        end  
        local NewTable = {};  --定义一个新表  
        InTable[obj] = NewTable;  --若表中有表，则先把表给InTable，再用NewTable去接收内嵌的表  
        for k,v in pairs(obj) do  --把旧表的key和Value赋给新表  
            NewTable[Func(k)] = Func(v);  
        end  
        return setmetatable(NewTable, getmetatable(obj))--赋值元表  
    end  
    return Func(obj) --若表中有表，则把内嵌的表也复制了  
end

function Function_Lua()
    local x=0
    for i=0,1000 do
        for j=0,100 do
            x = x + (i*i+j*2+i/1.5)
        end
    end
	sandbox.Log("Verbose", "Function_Lua");
end
