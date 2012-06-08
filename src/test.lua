redis = require 'hiredis'
require 'lglib'

local DB_HOST = '127.0.0.1'
local DB_PORT =  6379
local WHICH_DB = 0
local AUTH = nil
-- create a redis connection in this process
-- we will create one redis connection for every process
local db = redis.connect(DB_HOST, DB_PORT)
assert(db, '[Error] Database connection is failed.')
if AUTH then assert(db:command("auth",AUTH)); end
assert(db:command("select",WHICH_DB));


--脚本函数,对REDIS命令的简单封装
function hretrieve()--key
    return [[local function hretrieve(key)
        return redis.call("HGETALL",key);
    end ]];
end

function hsave()--key, tbl
    return [[local function hsave(key,tbl)
        if redis.call("EXISTS",key) then
            redis.call("DEL",key);
        end

        tbl = loadstring("return "..tbl)();
        for k,v in pairs(tbl) do
            redis.call("HSET",key,k,tostring(v));
        end
    end ]];
end

--hiredis command(eval,...)的再封装
function eval(db, script, ...)
    local ret = db:command("eval",script,0,...);
    if type(ret) == 'table' then
        local lret = {};
        for i=1,#ret,2 do 
            print(i,i+1);
            lret[ret[i]] = ret[i+1];
        end

        return lret;
    else
        return ret;
    end
end

--测试数据
local ac = {id = 10, method="get"}
local ac1 = {id = 20, method="get"}
local key = "Acess:" .. ac.id ;
local key1 = "Acess:" .. ac1.id ;

  
local str = "";
str = str .. hsave() .. hretrieve();--载入脚本函数
str = str .. [[
        hsave(ARGV[1],ARGV[2]);
        hsave(ARGV[3],ARGV[4]);

        local ac1 = hretrieve(ARGV[5]);
        local ac2 = hretrieve(ARGV[6]);

        return ac1
    ]] --应用逻辑


--执行eval
local s,k,e = eval(db,str,key,serialize(ac),key1,serialize(ac1),key,key1);

--打印
print(s,k,e);
ptable(s);

