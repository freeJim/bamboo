#!/usr/bin/env lua  
redis = require 'hiredis'
set = require 'bamboo.script.set'
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
local key = "set1";

--clear 
local str = "";
str = str .. set.del();
str = str .. [[
    return sdel(ARGV[1]);
    ]]
rac = db:command("eval",str,0,key);


--add and retrieve
str = "";
str = str .. set.add() ..set.retrieve();--载入脚本函数
str = str .. [[
        sadd(ARGV[1], ARGV[2]);
        sadd(ARGV[1], ARGV[3]);
        return sretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"set1","set2");
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "set"..i,v);
    n = n +1;
end
assert(n == 2 ,"return lenth must equal len" .. n);
print("set PUSH AND RETRIEVE PASS");


--save
str = "";
str = str .. set.save() ..set.retrieve()..set.del();--载入脚本函数
str = str .. [[
        sdel(ARGV[1]);
        ssave(ARGV[1], ARGV[2]);
        return sretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"set1","set2"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "set"..i,v);
    n = n +1;
end
assert(n == 2 ,"return lenth must equal len" .. n);
print("set SAVE PASS");



--update
str = "";
str = str .. set.update() ..set.retrieve()..set.del();--载入脚本函数
str = str .. [[
        supdate(ARGV[1], ARGV[2]);
        return sretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"set1","set2","set3"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "set"..i,v);
    n = n +1;
end
assert(n == 3 ,"return lenth must equal len" .. n);
print("set UPDATE PASS");


--remove
str = "";
str = str ..set.add() .. set.remove()..set.del()..set.retrieve();--载入脚本函数
str = str .. [[
        sdel(ARGV[1]);
        sadd(ARGV[1], ARGV[2]);
        sadd(ARGV[1], ARGV[3]);
        sadd(ARGV[1], ARGV[4]);
        sremove(ARGV[1],ARGV[5]);
        sremove(ARGV[1],ARGV[6]);
        return sretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"set2","set1","set3","set2","set3");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "set1",v);
    n = n +1;
end
assert(n == 1 ,"return lenth must equal len");
print("set REMOVE PASS");



--num 
str = "";
str = str .. set.num() ..set.add()..set.del();--载入脚本函数
str = str .. [[
        sdel(ARGV[1]);
        sadd(ARGV[1], ARGV[2]);
        sadd(ARGV[1], ARGV[3]);
        return snum(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"set1","set2");
assert(type(rac) == 'number',type(rac));
assert(2 == rac ,"return lenth must equal len" );
print("set NUM PASS");


--del
str = "";
str = str .. set.add() ..set.retrieve()..set.del();--载入脚本函数
str = str .. [[
        sadd(ARGV[1],ARGV[2]);
        sdel(ARGV[1]);
        return sretrieve(ARGV[1]);
    ]] --应用逻辑
--执行eval
local rac = eval.eval(db,str,key);
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "set1",v);
    n = n +1;
end
assert(n == 0 ,"return lenth must equal len");
print("set DEL PASS");


--has 
str = "";
str = str ..set.del().. set.add()..set.has();--载入脚本函数
str = str .. [[
        sdel(ARGV[1]);
        sadd(ARGV[1], ARGV[2]);
        sadd(ARGV[1], ARGV[3]);
        return shas(ARGV[1],ARGV[4]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"set1","set2","set2");
assert(type(rac) == 'number',rac);
assert(1 == rac ,"return lenth must equal len" );
local rac = eval.eval(db,str,key,"set1","set2","set20");
assert(type(rac) == 'number',rac);
assert(0 == rac ,"return lenth must equal len" );
print("set LEN PASS");











