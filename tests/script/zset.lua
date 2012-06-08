#!/usr/bin/env lua  
redis = require 'hiredis'
zset = require 'bamboo.script.zset'
eval = require 'bamboo.script.eval'
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



--测试数据
local key = "zset1";

--clear 
function clear(key)
local str = "";
str = str .. zset.del();
str = str .. [[
    return zsdel(ARGV[1]);
    ]]
local rac = db:command("eval",str,0,key);
end

clear(key);
--add and retrieve
str = "";
str = str .. zset.add() ..zset.retrieve()..zset.del();--载入脚本函数
str = str .. [[
        zsadd(ARGV[1], ARGV[2],ARGV[3]);
        zsadd(ARGV[1], ARGV[4],ARGV[5]);
        zsadd(ARGV[1], ARGV[6],ARGV[7]);
        return zsretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"zset1",100,"zset2",50,"zset3",200);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    print(i,v);
    n = n +1;
end
assert(n == 3 ,"return lenth must equal len" .. n);
print("zset PUSH AND RETRIEVE PASS");




clear(key)
--save
str = "";
str = str .. zset.save() ..zset.retrieve()..zset.add();--载入脚本函数
str = str .. [[
        zssave(ARGV[1], ARGV[2],ARGV[3]);
        return zsretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"zset1","zset2","zset3"}),serialize({10,20,30}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    print(i,v);
    assert(v == "zset"..i,v);
    n = n +1;
end
assert(n == 3 ,"return lenth must equal len" .. n);
local rac = eval.eval(db,str,key,serialize({"zset1","zset2","zset3"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    print(i,v);
    assert(v == "zset"..i,v);
    n = n +1;
end
assert(n == 3 ,"return lenth must equal len" .. n);
print("zset SAVE PASS");


--update
str = "";
str = str .. zset.update() ..zset.retrieve()..zset.del();--载入脚本函数
str = str .. [[
        zsupdate(ARGV[1], ARGV[2]);
        return zsretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"zset4","zset5","zset6"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zset"..i,v);
    n = n +1;
end
assert(n == 6 ,"return lenth must equal len" .. n);
print("zset UPDATE PASS");


--remove
str = "";
str = str ..zset.add() .. zset.remove()..zset.del()..zset.retrieve();--载入脚本函数
str = str .. [[
        zsdel(ARGV[1]);
        zsadd(ARGV[1], ARGV[2]);
        zsadd(ARGV[1], ARGV[3]);
        zsadd(ARGV[1], ARGV[4]);
        zsremove(ARGV[1],ARGV[5]);
        zsremove(ARGV[1],ARGV[6]);
        return zsretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"zset2","zset1","zset3","zset2","zset3");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zset1",v);
    n = n +1;
end
assert(n == 1 ,"return lenth must equal len");
print("zset REMOVE PASS");



--num 
str = "";
str = str .. zset.num() ..zset.add()..zset.del();--载入脚本函数
str = str .. [[
        zsdel(ARGV[1]);
        zsadd(ARGV[1], ARGV[2]);
        zsadd(ARGV[1], ARGV[3]);
        return zsnum(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"zset1","zset2");
assert(type(rac) == 'number',type(rac));
assert(2 == rac ,"return lenth must equal len" );
print("zset NUM PASS");


--del
str = "";
str = str .. zset.add() ..zset.retrieve()..zset.del();--载入脚本函数
str = str .. [[
        zsadd(ARGV[1],ARGV[2]);
        zsdel(ARGV[1]);
        return zsretrieve(ARGV[1]);
    ]] --应用逻辑
--执行eval
local rac = eval.eval(db,str,key);
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zset1",v);
    n = n +1;
end
assert(n == 0 ,"return lenth must equal len");
print("zset DEL PASS");


--has 
str = "";
str = str ..zset.del().. zset.add()..zset.has();--载入脚本函数
str = str .. [[
        zsdel(ARGV[1]);
        zsadd(ARGV[1], ARGV[2]);
        zsadd(ARGV[1], ARGV[3]);
        return zshas(ARGV[1],ARGV[4]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"zset1","zset2","zset2");
assert(type(rac) == 'string',rac);
assert('true' == rac ,"return lenth must be true" );
local rac = eval.eval(db,str,key,"zset1","zset2","zset20");
assert(type(rac) == 'string',rac);
assert('false' == rac ,"return must be false" );
print("zset LEN PASS");











